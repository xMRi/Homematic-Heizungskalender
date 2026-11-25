"""Enger Quelltext-Mock ausschließlich für die zwei markierten HSC-Blöcke."""
import itertools
import hashlib
import os
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[2]
PATH = "Skripte/HK-Heizkurvenkontrolle.hsc"
SOURCE = Path(os.environ["HEIZPHASEN_SOURCE"]).read_text() if os.environ.get("HEIZPHASEN_SOURCE") else (ROOT / PATH).read_text()
# SHA256 der Vergleichsregionen aus bd8a91f, ohne nachgestellte Leerzeichen/Tabulatoren.
AUSWAHL_HASH = "0275843c8a312869d8dfa22ad1d2fee4526fec3b2f92eb288e15112ff580b624"
TEMPERATUR_HASH = "e4c74bb9b44fb862f45ba5b5c586e6635bfb696203a477133ab9c33bbc06c81a"


def source_hash(text):
    normalized = '\n'.join(line.rstrip(' \t') for line in text.split('\n'))
    return hashlib.sha256(normalized.encode()).hexdigest()


def block(source, name):
    if "!// Beginn " + name not in source or "!// Ende " + name not in source:
        raise AssertionError("Markierter Quellblock fehlt: " + name)
    return source.split("!// Beginn " + name, 1)[1].split("!// Ende " + name, 1)[0]


def expression(text):
    text = re.sub(r'(\w+)\.StrValueByIndex\(";",(\d)\)\.ToTime\(\)\.ToInteger\(\)', r'int(\1.split(";")[\2])', text)
    text = re.sub(r'(\w+)\.Max\((\w+)\)', r'max(\1, \2)', text)
    text = text.replace('phasenEintraege.Split("#")', 'phasenEintraege.split("#")')
    return text.replace("&&", " and ").replace("true", "True").replace("false", "False")


def run(name, env):
    """Zeilenübersetzung, kein allgemeiner HSC-Interpreter oder Zeitparser."""
    lines, indent = [], 0
    for raw in block(SOURCE, name).splitlines():
        line = raw.strip()
        if not line or line.startswith("!"):
            continue
        if line == "}":
            indent -= 1
            continue
        line = re.sub(r'^(integer|boolean|string) ', '', line)
        if line.endswith("{"):
            line = line[:-1].strip()
            if line.startswith("foreach("):
                var, seq = line[8:-1].split(",", 1)
                line = "for " + var + " in " + expression(seq) + ":"
            else:
                kind, condition = line.split("(", 1)
                if kind.strip() not in ("if", "while"):
                    raise ValueError(line)
                line = kind.strip() + " " + expression(condition[:-1]) + ":"
            lines.append("    " * indent + line)
            indent += 1
        else:
            line = line.rstrip(";")
            if re.fullmatch(r'\w+', line) and line != "continue":
                line += " = None"
            lines.append("    " * indent + expression(line))
    exec("\n".join(lines), {}, env)
    return env


def entry(start, end, room="R", flag=20, termin=None):
    return f"{room};0;{end if termin is None else termin};{flag};{start};{end}"


def phase(selected, entries):
    fields = selected.split(";")
    # Sammeln als enges Referenzmodell; die realen Sammelstellen werden separat geprüft.
    collected = [e for e in entries if e.split(";")[0] == fields[0] and int(e.split(";")[3]) >= 0]
    return run("Heizphasen-Zusammenfassung", dict(EIN=int(fields[4]), AUS=int(fields[5]), AUS_Termin=int(fields[2]), phasenEintraege="#".join(collected) + "#"))


def transition(p, status=1, last=0, current=1, now=9):
    env = dict(p, status=status, letzteHeizphaseAus=last, aktuellerSchaltZustand=current, NOW=now, maxTemperatur=23.5, letzterTemperaturLog=8, ausTerminMax=99)
    return run("Heizphasen-Statuswechsel", env)


class HeizphasenTests(unittest.TestCase):
    def setUp(self):
        self.a, self.b = entry(7, 10), entry(8, 12)
        self.p = phase(self.a, [self.a, self.b])

    def test_overlap_terminende(self):
        self.assertEqual(self.p["heizphaseTerminEnde"], 12)
        self.assertFalse(transition(self.p, now=10)["ausTerminMax"] <= 10)
        self.assertTrue(transition(self.p, now=12)["ausTerminMax"] <= 12)

    def test_overlap_keine_ruecksetzung_1005(self):
        t = transition(phase(self.b, [self.b]), last=12, status=33, now=10.0833)
        self.assertEqual(t["status"], 33)
        self.assertEqual(t["status"] & 16, 0)
        self.assertTrue((t["status"] & 1) != 0 and (t["status"] & 2) == 0 and (t["status"] & 16) == 0)
        self.assertIn('if (((status & 1)!=0) && ((status & 2)==0) && ((status & 16)==0) && (istTemperatur>=RTemp)) {', SOURCE)

    def test_originales_terminende_getrennt_vom_heizende(self):
        a = entry(7 * 60, 9 * 60 + 30, termin=10 * 60)
        b = entry(8 * 60, 11 * 60 + 30, termin=12 * 60)
        p = phase(a, [a, b])
        self.assertEqual(p["heizphaseTerminEnde"], 12 * 60)
        self.assertEqual(p["heizphaseAus"], 11 * 60 + 30)

    def test_neue_phase_status55(self):
        t = transition(phase(entry(14, 18), [entry(14, 18)]), status=55, last=12, now=14)
        self.assertEqual((t["status"], t["maxTemperatur"], t["letzterTemperaturLog"]), (0, 0, 0))
        self.assertEqual(1 | (t["status"] & 32), 1)

    def test_disjunkt_ohne_auslauf(self):
        self.assertEqual(transition(phase(entry(14, 18), []), status=49, last=12, now=14)["status"], 0)

    def test_altformat_aus_ein(self):
        self.assertEqual(transition(self.p, status=55)["status"], 0)

    def test_altformat_aktiv(self):
        self.assertEqual(transition(self.p, status=1)["status"], 1)

    def test_zukuenftige_phase(self):
        self.assertEqual(phase(self.a, [self.a, entry(14, 18)])["heizphaseTerminEnde"], 10)

    def test_transitive_reihenfolgen(self):
        entries = [entry(7, 9), entry(8, 11), entry(10, 12)]
        for order in itertools.permutations(entries):
            p = phase(entries[0], order)
            self.assertEqual((p["heizphaseEin"], p["heizphaseAus"], p["heizphaseTerminEnde"]), (7, 12, 12))

    def test_beruehren(self):
        self.assertEqual(phase(self.a, [entry(10, 12)])["heizphaseAus"], 12)

    def test_positive_luecke(self):
        self.assertEqual(phase(self.a, [entry(11, 12)])["heizphaseAus"], 10)

    def test_raum_sonderbefehl(self):
        self.assertEqual(phase(self.a, [entry(8, 18, "X"), entry(8, 19, flag=-1)])["heizphaseAus"], 10)
        self.assertIn('Find("#" # RVN # ";")', SOURCE)
        self.assertIn('if (SDFlag>=0){\n        phasenEintraege = phasenEintraege # SLEintrag2 # "#";', SOURCE)
        self.assertIn('string phasenEintraege = "";', SOURCE)

    def test_absage_entfernt_altes_maximum(self):
        t = transition(phase(self.a, [self.a]), last=12)
        self.assertEqual(t["ausTerminMax"], 10)
        self.assertFalse(t["neueHeizphase"])

    def test_software_aus_ein_gemeinsame_phase(self):
        self.assertEqual(transition(self.p, status=5, last=12, now=11)["status"], 0)

    def test_auszustand_kein_fortlaufender_reset(self):
        self.assertEqual(transition(self.p, status=5, last=12, current=0, now=11)["status"], 5)

    def test_vergangene_phase_kein_reset(self):
        self.assertEqual(transition(self.p, status=55, last=12, now=13)["status"], 55)

    def test_speicherpfade_und_migration(self):
        self.assertEqual(SOURCE.count('letzterTemperaturLog.ToTime() # ";" # heizphaseAus;'), 2)
        self.assertIn('RaumParameter.StrValueByIndex(";",5).ToInteger()', SOURCE)

    def test_deklarationen_header(self):
        for name in ("phasenEintraege", "heizphaseEin", "heizphaseAus", "heizphaseTerminEnde", "heizphaseErweitert", "phasenEintrag", "phasenEin", "phasenAus", "phasenTerminEnde", "letzteHeizphaseAus", "neueHeizphase"):
            self.assertEqual(len(re.findall(r'\b(?:integer|string|boolean)\s+' + name + r'\b', SOURCE)), 1, name)
        self.assertIn("!// Stand:    25.11.2026", SOURCE)
        self.assertEqual(SOURCE.count("!// TT:  2026-11-25"), 1)

    def test_stuendlicher_block_unveraendert(self):
        start = "  !// Auf einen Temperaturlog prüfen."
        end = "  !// Wir speichern einen Raum nur,"
        actual = SOURCE.split(start)[1].split(end)[0]
        self.assertEqual(source_hash(actual), TEMPERATUR_HASH)

    def test_hash_ignoriert_nur_nachgestellte_leerzeichen_tabulatoren(self):
        text = '  status = 1;\n  !// Kommentar\n'
        self.assertEqual(source_hash(text), source_hash('  status = 1; \t\n  !// Kommentar\t \n'))
        self.assertNotEqual(source_hash(text), source_hash(' status = 1;\n  !// Kommentar\n'))
        self.assertNotEqual(source_hash(text), source_hash('  status = 2;\n  !// Kommentar\n'))

    def test_auswahl_unveraendert_bis_auf_sammlung(self):
        start, end = 'while(SListe!=""){', '  !// Diesen Eintrag nun bearbeiten,'
        actual = SOURCE.split(start)[1].split(end)[0]
        actual = actual.replace('  string phasenEintraege = "";\n', '')
        actual = actual.replace('      if (SDFlag>=0){\n        phasenEintraege = phasenEintraege # SLEintrag2 # "#";\n      }\n', '')
        self.assertEqual(source_hash(actual), AUSWAHL_HASH)


if __name__ == "__main__":
    unittest.main()
