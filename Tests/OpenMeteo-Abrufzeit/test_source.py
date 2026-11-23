"""Fokussierte Quelltextprüfung, kein HSC-Interpreter oder CCU-Laufzeittest."""
from pathlib import Path
import re
import unittest


SOURCE = Path("Skripte/HK-Außentemperatur-Open-Meteo.hsc").read_text()


def block_after(marker):
    """Blockgrenzen anhand der echten Quelle, Strings/Kommentare auslassen."""
    start = SOURCE.index("{", SOURCE.index(marker))
    depth = 0
    for token in re.finditer(r'"(?:\\.|[^"\\])*"|!//[^\n]*|[{}]', SOURCE[start:]):
        if token.group() == "{":
            depth += 1
        elif token.group() == "}":
            depth -= 1
            if depth == 0:
                return SOURCE[start:start + token.end()]
    raise AssertionError("Blockende nicht gefunden: " + marker)


class SourceContract(unittest.TestCase):
    def test_header(self):
        self.assertIn("!// Stand:    21.11.2026", SOURCE)
        self.assertEqual(SOURCE.count("!// TT: 2026-11-21"), 1)

    def test_success_write_order_and_optional_guard(self):
        success = block_after("if (n!=0)")
        guard = block_after("if (!svAT)")
        self.assertIn("break;", guard)
        self.assertNotIn(".State(temp)", guard)
        self.assertNotIn("svAbrufzeit", guard)
        self.assertLess(success.index("if (!svAT)"), success.index("svAT.State(temp);"))
        self.assertLess(success.index("svAT.State(temp);"), success.index("svAbrufzeit.State("))
        self.assertIn('dom.GetObject(vrp # "HK2-Aussentemperatur")', success)
        self.assertIn('dom.GetObject(vrp # "HK2-Aussentemperatur-Abrufzeit")', success)
        optional = block_after("if (svAbrufzeit)")
        self.assertIn("svAbrufzeit.State(system.Date().ToTime().ToInteger().ToString());", optional)
        self.assertEqual(SOURCE.count("svAbrufzeit.State("), 1)
        self.assertNotIn("Value()", success)
        self.assertNotIn("CreateObject", SOURCE)

    def test_failure_paths_exclude_timestamp(self):
        for marker in ('if (lat==""', "if (bError)"):
            failure = block_after(marker)
            self.assertNotIn("svAbrufzeit", failure)
        self.assertIn("continue;", block_after("if (bError)"))
        success_end = SOURCE.index("break;", SOURCE.index("if (svAkt)"))
        zero_values = SOURCE[success_end:]
        self.assertIn("Keine Werte für die Außentemperatur gefunden!", zero_values)
        self.assertNotIn("svAbrufzeit", zero_values)


if __name__ == "__main__":
    unittest.main()
