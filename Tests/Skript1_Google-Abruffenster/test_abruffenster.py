"""Begrenzte Quellprüfungen und Python-Referenzmodell, kein HSC-Interpreter."""
from datetime import datetime
from pathlib import Path
import re
import unittest
from zoneinfo import ZoneInfo


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "Skripte" / "HK-Skript 1_Google.hsc"


def abruffenster(now_text, vorlauf, raum_ausverschiebungen):
    """UTC-Sekundenarithmetik mit lokalen Tagesgrenzen wie im Quellalgorithmus."""
    zone = ZoneInfo("Europe/Berlin")
    now = datetime.fromisoformat(now_text).replace(tzinfo=zone)
    jetzt = int(now.timestamp())
    start = int(now.replace(hour=0, minute=0, second=0).timestamp())
    mittag = now.replace(hour=12, minute=0, second=0)
    endtag = datetime.fromtimestamp(mittag.timestamp() + (86400 * 2), zone)
    ende = int(endtag.replace(hour=0, minute=0, second=0).timestamp())
    nachlauf = 30 - min([0] + list(raum_ausverschiebungen))
    start = min(start, jetzt - (nachlauf * 60) - 1)
    ende = max(ende, jetzt + (vorlauf * 60) + 1)
    return datetime.fromtimestamp(start, zone), datetime.fromtimestamp(ende, zone)


class Quellstruktur(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        # Vollzeilige HSC-Kommentare entfernen, Strings nicht als Code interpretieren.
        source = SOURCE.read_text(encoding="utf-8")
        cls.code = "\n".join(line for line in source.splitlines()
                             if not line.lstrip().startswith("!"))
        cls.compact = re.sub(r"\s+", "", cls.code)

    def test_deklarationen_und_initialisierung_vor_verwendung(self):
        names = ("HKGListe", "RaumVar", "zeitVorlauf", "objVorlaufzeit",
                 "minRaumNachlauf", "raumNachlauf", "objRaumNachlauf", "zeitNachlauf")
        for name in names:
            with self.subTest(variable=name):
                declarations = list(re.finditer(
                    r"\b(?:string|integer|object)\s+" + name + r"\b", self.code))
                self.assertEqual(len(declarations), 1)
                first = re.search(r"\b" + name + r"\b", self.code)
                self.assertRegex(self.code[:first.start()], r"\b(?:string|integer|object)\s+$")
        c = self.compact
        self.assertIn('stringHKGListe=dom.GetObject(vrp#"HK2-HKG-Liste").State();', c)
        self.assertLess(c.index('stringHKGListe='), c.index('foreach(RaumVar,HKGListe'))
        for declaration, use in (
            ('integerzeitVorlauf=12*60;', 'zeitVorlauf=objVorlaufzeit.State().ToInteger();'),
            ('integerminRaumNachlauf=0;', 'if(raumNachlauf<minRaumNachlauf)'),
            ('integerzeitNachlauf=30-minRaumNachlauf;', 'integerauswahlStart='),
        ):
            self.assertIn(declaration, c)
            self.assertLess(c.index(declaration), c.index(use))
        self.assertLess(c.index('objRaumNachlauf=dom.GetObject(RaumVar);'),
                        c.index('raumNachlauf=objRaumNachlauf.State()'))
        self.assertLess(c.index('raumNachlauf=objRaumNachlauf.State()'),
                        c.index('if(raumNachlauf<minRaumNachlauf)'))

    def test_negative_ausschaltverschiebung_im_raumverbund(self):
        c = self.compact
        self.assertIn('foreach(RaumVar,HKGListe.Replace("+",";").Split(";"))', c)
        self.assertIn('raumNachlauf=objRaumNachlauf.State().StrValueByIndex(";",5).ToInteger();', c)
        self.assertIn('if(raumNachlauf<minRaumNachlauf){minRaumNachlauf=raumNachlauf;}', c)
        self.assertIn('integerzeitNachlauf=30-minRaumNachlauf;', c)

    def test_lokale_tagesgrenzen_und_exklusive_api_grenzen(self):
        c = self.compact
        for statement in (
            'integerabfrageStart=(JETZT.ToTime().Format("%F")#"00:00:00").ToTime().ToInteger();',
            'integerabfrageMittag=(JETZT.ToTime().Format("%F")#"12:00:00").ToTime().ToInteger();',
            'integerabfrageEnde=(((abfrageMittag+(86400*2)).ToTime().Format("%F"))#"00:00:00").ToTime().ToInteger();',
            'integerauswahlStart=(JETZT-(zeitNachlauf*60))-1;',
            'integerauswahlEnde=(JETZT+(zeitVorlauf*60))+1;',
            'if(auswahlStart<abfrageStart){abfrageStart=auswahlStart;}',
            'if(auswahlEnde>abfrageEnde){abfrageEnde=auswahlEnde;}',
            'if((startDatum.ToInteger()-(zeitVorlauf*60))>JETZT)',
            'if((endDatum.ToInteger()+(zeitNachlauf*60))<JETZT)',
        ):
            with self.subTest(statement=statement):
                self.assertIn(statement, c)

    def test_offset_pro_grenze_und_url_kodierung(self):
        c = self.compact
        for datum, zone, grenze in (('startDatum', 'startZone', 'abfrageStart'),
                                    ('endDatum', 'endeZone', 'abfrageEnde')):
            with self.subTest(grenze=grenze):
                self.assertIn(f'string{zone}={grenze}.ToTime().Format("%z");', c)
                self.assertIn(f'string{datum}={grenze}.ToTime().Format("%FT%T")#'
                              f'{zone}.Substr(0,3)#":"#{zone}.Substr(3,2);', c)
                self.assertIn(f'{datum}={datum}.Replace("+","%2B");', c)
        self.assertIn('"&timeMin="#startDatum', c)
        self.assertIn('"&timeMax="#endDatum', c)

    def test_pagination_meldet_teilseite_ohne_abbruch(self):
        self.assertIn('maxResults=2500', self.code)
        marker = 'if (stdout.Contains("\\"nextPageToken\\":"))'
        start = self.code.index(marker)
        end = self.code.index('integer iPos;', start)
        warning = self.code[start:end]
        self.assertIn('WriteLine(', warning)
        self.assertIn('logObj.State(', warning)
        self.assertIn('nur die gelieferte Ergebnisseite wird verarbeitet', warning)
        self.assertNotRegex(warning, r'\b(?:quit|break|continue|return)\b')
        self.assertNotRegex(warning, r'\b(?:foreach|while|system\.Exec)\b')
        self.assertNotRegex(warning, r'\b(?:SLT|stdout)\s*=')
        self.assertIn('foreach(termin,termine)', self.compact)
        self.assertIn('dom.GetObject(vrp+"HK1-Schaltliste").State(SLT);', self.compact)
        self.assertLess(end, self.code.index('foreach(termin,termine)'))


class ZeitfensterReferenzen(unittest.TestCase):
    def check_window(self, now, vorlauf, raumwerte, start, ende):
        actual_start, actual_end = abruffenster(now, vorlauf, raumwerte)
        self.assertEqual(actual_start.isoformat(), start)
        self.assertEqual(actual_end.isoformat(), ende)

    def test_normal(self):
        self.check_window('2026-11-22T12:00:00', 720, [30],
                          '2026-11-22T00:00:00+01:00', '2026-11-24T00:00:00+01:00')

    def test_nachlauf_90_minuten_ueber_mitternacht(self):
        self.check_window('2026-11-22T00:10:00', 720, [-60, 30],
                          '2026-11-21T22:39:59+01:00', '2026-11-24T00:00:00+01:00')

    def test_langer_vorlauf(self):
        self.check_window('2026-11-22T12:00:00', 4320, [],
                          '2026-11-22T00:00:00+01:00', '2026-11-25T12:00:01+01:00')

    def test_sommerzeitbeginn(self):
        self.check_window('2026-03-28T12:00:00', 720, [],
                          '2026-03-28T00:00:00+01:00', '2026-03-30T00:00:00+02:00')

    def test_sommerzeitende(self):
        self.check_window('2026-10-24T12:00:00', 720, [],
                          '2026-10-24T00:00:00+02:00', '2026-10-26T00:00:00+01:00')


if __name__ == '__main__':
    unittest.main(verbosity=2)
