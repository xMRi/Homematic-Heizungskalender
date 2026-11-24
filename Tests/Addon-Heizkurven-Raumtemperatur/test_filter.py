"""Fokussierte Ausgabeprüfungen der vollständigen CGI mit synthetischen Daten."""
from html.parser import HTMLParser
from pathlib import Path
import os
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
CGI = ROOT / "Addon/src/heizkalender/www/hkkurve.cgi"


def log(ts, message, source="HK-LogHeizkurvenkontrolle"):
    return f"{ts}\t{source}\t{message}"


DATA = "\n".join([
    log("2026-11-23 08:00:00", "Saal - Heizbeginn: -90min, Ist: 17, Ziel: 20, AT: 5"),
    log("2026-11-23 09:00:00", "Saal - Zieltemperatur: -20min, Ist: 20, Ziel: 20, AT: 5"),
    log("2026-11-23 09:10:00", "Saal - Raumtemperatur: -10min, Ist: 20, Ziel: 20, AT: 5"),
    log("2026-11-23 10:00:00", "Saal - Heizende: +40min, Ist: 20, Ziel: 20, AT: 5"),
    log("2026-11-23 10:10:00", "Nebenraum - Raumtemperatur: +50min, Ist: 19, Ziel: 20, AT: 5"),
    log("2026-11-23 10:20:00", "Alt(42) Raumtemperatur: +60min, Ist: 19, Ziel: 20, AT: 5"),
    log("2026-11-23 10:30:00", "Alt(42) Heizende: +70min, Ist: 19, Ziel: 20, AT: 5"),
    log("2026-11-23 10:40:00", "Saal - Raumtemperatur Zusatz: behalten"),
    log("2026-11-23 10:50:00", 'A<&" - Fehler: <script>alert("x")</script> & Detail'),
    log("2026-11-22 11:59:59", "Saal - Raumtemperatur: zu alt fuer 24h"),
    log("2026-11-22 12:00:00", "Saal - Raumtemperatur: Grenze 24h"),
    log("2026-11-22 18:00:00", "Saal - Heizbeginn: gestern"),
    log("2026-11-15 12:00:00", "Saal - Raumtemperatur: ausserhalb 7 Tage"),
    log("2026-11-23 09:11:00", "Saal - Raumtemperatur: falsche Quelle", "AndereQuelle"),
])


class Page(HTMLParser):
    def __init__(self, text):
        super().__init__(convert_charrefs=True)
        self.rows, self.controls, self.options = [], [], []
        self.row = self.cell = self.select = None
        self.feed(text)

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag in ("select", "input", "button"):
            self.controls.append((tag, attrs))
        if tag == "select":
            self.select = attrs.get("name")
        if tag == "option":
            self.options.append((self.select, attrs))
        if tag == "tr":
            self.row = []
        if tag == "td":
            self.cell = ""

    def handle_data(self, data):
        if self.cell is not None:
            self.cell += data

    def handle_endtag(self, tag):
        if tag == "select":
            self.select = None
        if tag == "td":
            self.row.append(self.cell.strip())
            self.cell = None
        if tag == "tr" and self.row:
            self.rows.append(self.row)


class FilterTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tcl = shutil.which("tclsh")
        if not cls.tcl:
            raise RuntimeError("tclsh fehlt, lokales Tcl ist erforderlich")
        build = ROOT / "build"
        build.mkdir(exist_ok=True)
        cls.temp = tempfile.TemporaryDirectory(prefix="hkkurve-test-", dir=build)
        cls.fixture = Path(cls.temp.name) / "synthetisch.txt"
        cls.fixture.write_text(DATA, encoding="utf-8")

    @classmethod
    def tearDownClass(cls):
        cls.temp.cleanup()

    def run_cgi(self, query="", data=None):
        self.fixture.write_text(DATA if data is None else data, encoding="utf-8")
        result = subprocess.run(
            [self.tcl, str(HERE / "harness.tcl"), str(CGI), str(self.fixture), query],
            cwd=self.temp.name, env={"PATH": os.defpath, "TZ": "UTC", "HOME": self.temp.name},
            capture_output=True, text=True, encoding="utf-8", timeout=10,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stderr, "", "Tcl kann Fehler trotz Status 0 melden")
        self.assertIn("Content-Type: text/html", result.stdout)
        return Page(result.stdout), result.stdout

    def test_default_and_invalid_flags(self):
        for query in ("", "anzeigen=1", "raumtemperatur=0", "raumtemperatur=nonsense", "raumtemperatur="):
            with self.subTest(query=query):
                page, _ = self.run_cgi(query)
                self.assertEqual([r[2] for r in page.rows], [
                    "Heizbeginn", "Zieltemperatur", "Heizende", "Heizende",
                    "Raumtemperatur Zusatz", "Fehler",
                ])
                checkbox = [a for t, a in page.controls if a.get("name") == "raumtemperatur"]
                self.assertEqual(len(checkbox), 1)
                self.assertNotIn("checked", checkbox[0])

    def test_enabled_form_and_old_format(self):
        page, text = self.run_cgi("anzeigen=1&raumtemperatur=1")
        self.assertEqual(len(page.rows), 9)
        self.assertEqual(sum(r[2] == "Raumtemperatur" for r in page.rows), 3)
        self.assertTrue(any(r[0] == "Alt(42)" and r[2] == "Raumtemperatur" for r in page.rows))
        controls = page.controls
        event_index = next(i for i, (_, a) in enumerate(controls) if a.get("name") == "ereignis")
        tag, attrs = controls[event_index + 1]
        self.assertEqual((tag, attrs.get("type"), attrs.get("name"), attrs.get("value")),
                         ("input", "checkbox", "raumtemperatur", "1"))
        self.assertIn("checked", attrs)
        self.assertIn("Raumtemperatur anzeigen", text)
        self.assertTrue(any(t == "button" and a.get("type") == "submit" for t, a in controls))
        self.assertNotIn("onchange", text.lower())
        self.assertNotIn("<script", text.lower())

    def test_room_day_event_combinations(self):
        cases = [
            ("raum=Saal&tage=1&raumtemperatur=1", 5, None),
            ("raum=Alt&tage=1&raumtemperatur=1", 2, None),
            ("raum=Saal&tage=0&raumtemperatur=1", 3, None),
            ("raum=Saal&tage=24&raumtemperatur=1", 7, None),
            ("raum=Saal&tage=7&raumtemperatur=1&ereignis=Raumtemperatur", 3, "Raumtemperatur"),
            ("raum=Saal&tage=1&raumtemperatur=1&ereignis=Heizende", 1, "Heizende"),
            ("raum=Saal&tage=1&ereignis=Raumtemperatur", 0, None),
            ("raum=Saal&tage=1&raumtemperatur=0&ereignis=Heizbeginn", 1, "Heizbeginn"),
        ]
        for query, count, event in cases:
            with self.subTest(query=query):
                page, _ = self.run_cgi("anzeigen=1&" + query)
                self.assertEqual(len(page.rows), count)
                if event:
                    self.assertTrue(all(r[2] == event for r in page.rows))
                if "tage=24" in query:
                    self.assertTrue(all(r[1] >= "2026-11-22 12:00:00" for r in page.rows))

    def test_no_measurement_rows_other_events_unchanged(self):
        data = "\n".join(line for line in DATA.splitlines() if "Raumtemperatur" not in line)
        hidden, _ = self.run_cgi("anzeigen=1", data)
        shown, _ = self.run_cgi("anzeigen=1&raumtemperatur=1", data)
        self.assertEqual(hidden.rows, shown.rows)
        self.assertEqual(len(hidden.rows), 5)

    def test_existing_escaping_and_selected_filters(self):
        page, text = self.run_cgi("raum=Saal&tage=7&ereignis=Heizbeginn&raumtemperatur=1")
        for name, value in (("raum", "Saal"), ("tage", "7"), ("ereignis", "Heizbeginn")):
            self.assertTrue(any(n == name and a.get("value") == value and "selected" in a
                                for n, a in page.options))
        self.assertIn('value="A&lt;&amp;&quot;"', text)
        page, text = self.run_cgi()
        self.assertIn('&lt;script&gt;alert(&quot;x&quot;)&lt;/script&gt; &amp; Detail', text)
        self.assertTrue(any(r[0] == 'A<&"' for r in page.rows))


if __name__ == "__main__":
    unittest.main(verbosity=2)
