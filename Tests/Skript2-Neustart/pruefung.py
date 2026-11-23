#!/usr/bin/env python3
"""Statische Pruefung und explizites Referenzmodell, kein HSC-Interpreter."""
import math
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "Skripte/HK-Skript 2.hsc"


def source_parts():
    source = SOURCE.read_text()
    declarations = "boolean kernelLaufzeitGelesen=false;\n"
    assert source.count(declarations.rstrip()) == 1
    branch = source.split("        if (ISTTemperatur==0){", 1)[1].split(
        "        !// Luftfeuchte optional", 1)[0]
    return source, declarations, "        if (ISTTemperatur==0){" + branch


class Model:
    """Nur Entscheidungsmodell, unabhaengig von der HomeMatic-Laufzeit."""

    def __init__(self, stdout="3600.00 123.45\n", stderr=""):
        self.stdout, self.stderr = stdout, stderr
        self.reads = 0
        self.seconds = None

    def decide(self, measured=0, old="", gt=12, at=5, atg=18, begun=False):
        if old and begun:
            return "alt", old
        if measured == 0:
            if old:
                return "alt", old
            if not self.reads:
                self.reads += 1
                token = self.stdout.split(" ")[0]
                if not self.stderr and re.fullmatch(r"[0-9]+(?:\.[0-9]+)?", token):
                    value = float(token)
                    if math.isfinite(value) and value > 0:
                        self.seconds = value
            if self.seconds is None or self.seconds < 3600:
                return "warten", None
            measured = max(gt, at)
        if at >= atg:
            return "ATG", None
        return "berechnen", measured


class Decisions(unittest.TestCase):
    def test_grenze(self):
        for seconds, action in [(3599, "warten"), (3599.99, "warten"),
                                (3600, "berechnen"), (3600.01, "berechnen")]:
            with self.subTest(seconds=seconds):
                self.assertEqual(Model(str(seconds) + " 0\n").decide()[0], action)

    def test_alt_vor_und_nach_startstunde(self):
        for seconds in (3599, 3600):
            model = Model(str(seconds) + " 0\n")
            self.assertEqual(model.decide(old="unveraendert"), ("alt", "unveraendert"))
            self.assertEqual(model.reads, 0)

    def test_messwert_sofort_auch_negativ(self):
        for measured in (0.1, 17, -2):
            model = Model("ungueltig")
            self.assertEqual(model.decide(measured=measured), ("berechnen", measured))
            self.assertEqual(model.reads, 0)

    def test_ungueltige_laufzeit(self):
        for stdout, stderr in [("", ""), (" 3600", ""), ("abc 0", ""),
                               ("-3600 0", ""), ("+3600 0", ""), ("0 0", ""),
                               (".3600 0", ""), ("3600. 0", ""), ("36.00.0 0", ""),
                               ("3e4 0", ""), ("NaN 0", ""), ("3600 0", "Fehler")]:
            with self.subTest(stdout=stdout, stderr=stderr):
                self.assertEqual(Model(stdout, stderr).decide(), ("warten", None))

    def test_einmal_je_lauf_auch_bei_fehler(self):
        for stdout in ("3600.5 0\n", "ungueltig"):
            model = Model(stdout)
            for _ in range(4):
                model.decide()
            self.assertEqual(model.reads, 1)
        model = Model("3600.5 0\n")
        self.assertEqual(model.decide(gt=12, at=5), ("berechnen", 12))
        model.stdout = "ungueltig"
        self.assertEqual(model.decide(gt=10, at=15), ("berechnen", 15))
        self.assertEqual(model.reads, 1)

    def test_schaetzwert_und_atg(self):
        for gt, at, expected in [(12, 5, 12), (12, 15, 15), (0, 0, 0), (-5, -2, -2)]:
            with self.subTest(gt=gt, at=at):
                self.assertEqual(Model().decide(gt=gt, at=at), ("berechnen", expected))
        self.assertEqual(Model().decide(at=18), ("ATG", None))

    def test_erholung_nur_vor_beginn(self):
        model = Model()
        self.assertEqual(model.decide(), ("berechnen", 12))
        self.assertEqual(model.decide(measured=16, old="geschaetzt"), ("berechnen", 16))
        self.assertEqual(model.decide(measured=16, old="geschaetzt", begun=True),
                         ("alt", "geschaetzt"))


class StaticSource(unittest.TestCase):
    def test_header_und_deklarationen(self):
        source, declarations, branch = source_parts()
        self.assertIn("!// Stand:    22.11.2026", source)
        self.assertNotIn("!// TT:  2026-11-23", source)
        self.assertEqual(source.count("!// TT:  2026-11-22"), 1)
        self.assertEqual(source.count("!// TT:  2026-11-21"), 1)
        self.assertIn("!// MRi: 2026-11-19 HK1-Vorlaufzeit automatisch erhöhen", source)
        self.assertLess(source.index("!// TT:  2026-11-22"), source.index("!// TT:  2026-11-21"))
        self.assertLess(source.index("!// TT:  2026-11-21"), source.index("!// MRi: 2026-11-19"))
        names = re.findall(r"(?:boolean|string|integer|real) (kernelLaufzeit\w+)", declarations + branch)
        self.assertEqual(len(names), 10)
        self.assertEqual(len(names), len(set(names)))
        for name in names:
            self.assertEqual(len(re.findall(r"(?:boolean|string|integer|real) " + name + r"\b", source)), 1)
        before_read, read = branch.split("if (!kernelLaufzeitGelesen){", 1)
        read_prefix = read.split("kernelLaufzeitGelesen=true;", 1)[0]
        helper_names = re.findall(r"(?:boolean|string|integer|real) (kernelLaufzeit\w+)", read_prefix)
        self.assertEqual(len(helper_names), 9)
        for name in helper_names:
            self.assertNotIn(name, before_read)
            self.assertNotIn(name, source.split("if (ISTTemperatur==0){", 1)[0])
            self.assertNotIn(name, source.split("!// Luftfeuchte optional", 1)[1])
        self.assertIn("boolean kernelLaufzeitDezimalpunkt=false;", read_prefix)
        self.assertEqual(source.count("kernelLaufzeitDezimalpunkt=false;"), 1)
        self.assertLess(source.index(declarations.rstrip()), source.index("foreach(TLEintrag,TerminListe)"))

    def test_zweig_reihenfolge_und_fortsetzung(self):
        source, _, branch = source_parts()
        self.assertEqual(source.count('system.Exec("cat /proc/uptime"'), 1)
        old, rest = branch.split("if (!kernelLaufzeitGelesen)", 1)
        self.assertIn('SchaltListeNeu = SchaltListeNeu # strAlterListenEintrag # "#";', old)
        self.assertIn("continue;", old)
        self.assertIn("kernelLaufzeitGelesen=true;", rest)
        self.assertIn('kernelLaufzeitAusgabe.StrValueByIndex(" ",0)', rest)
        self.assertIn('(kernelLaufzeitFehler=="")', rest)
        self.assertIn('kernelLaufzeitZiffern.Find(kernelLaufzeitZeichen)<0', rest)
        self.assertIn("if (kernelLaufzeitGueltig){\n              kernelLaufzeitSekunden=kernelLaufzeitText.ToFloat();", rest)
        self.assertIn("kernelLaufzeitSekunden<=0.0", rest)
        self.assertIn("if (kernelLaufzeitSekunden<3600.0)", rest)
        estimate = rest.split("ISTTemperatur=GT.Max(AT);", 1)[1]
        self.assertNotIn("continue;", estimate)
        self.assertNotIn("dom.GetObject", branch)
        self.assertLess(source.index("if ((EIN<NOW) && (SDFlag>=0))"),
                        source.index("if (ISTTemperatur==0)"))
        self.assertLess(source.index("ISTTemperatur=GT.Max(AT);"), source.index("if(AT>=ATG)"))


if __name__ == "__main__":
    unittest.main(verbosity=2)
