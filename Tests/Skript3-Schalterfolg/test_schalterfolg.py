"""Lokaler Mock des echten Normal-EIN-Quellblocks, kein ReGa-/CCU-Test.

Nur die hier benoetigte HSC-Teilmenge wird nach Python uebersetzt.
Keine Funkbestaetigung und keine produktiven Schreibzugriffe.
"""
import re
import unittest
from pathlib import Path


SOURCE = Path("Skripte/HK-Skript 3.hsc").read_text()
BLOCK = SOURCE.split("  !//Einschalten (Status ==> 1)", 1)[1].split(
    "\n}\n!// Ende äußere Schleife", 1
)[0]


class Text(str):
    def Split(self, sep):
        return [Text(x) for x in self.split(sep)]

    def Find(self, value):
        return self.find(value)

    def Length(self):
        return len(self)

    def Substr(self, start, length):
        return Text(self[start:start + length])


class SkipEntry(Exception):
    pass


def compile_block(block):
    """Zerlegt ausserhalb von Strings; foreach bleibt eine komplette Kopfzeile."""
    block = "\n".join(line.split("!//", 1)[0] for line in block.splitlines())
    tokens, current, quoted, escaped, depth = [], "", False, False, 0
    for char in block:
        if char == '"' and not escaped:
            quoted = not quoted
        if not quoted:
            if char == "(":
                depth += 1
            elif char == ")":
                depth -= 1
            if char in "{};" and depth == 0:
                if current.strip():
                    tokens.append(current.strip())
                if char != ";":
                    tokens.append(char)
                current = ""
                continue
        current += char
        escaped = char == "\\" and not escaped
    lines, indent = [], 0
    for token in tokens:
        if token == "}":
            indent -= 1
            continue
        if token == "{":
            indent += 1
            continue
        token = re.sub(r"\b(true|false)\b", lambda m: m[0].title(), token)
        token = token.replace("&&", " and ").replace("||", " or ")
        token = re.sub(r"!(?!=)(?=\w)", "not ", token)
        # '#' kommt in diesem Block nur als Verkettungsoperator vor.
        token = re.sub(r"\s*#\s*", " + ", token)
        token = re.sub(r"(\w+)\.ToString\(1\)", r'format(\1, ".1f")', token)
        token = re.sub(r"^(real|boolean|string|integer|object)\s+", "", token)
        if token.startswith("foreach("):
            name, values = token[8:-1].split(",", 1)
            token = f"for {name} in {values}:"
        elif token.startswith("elseif"):
            token = "elif " + token[6:] + ":"
        elif token.startswith("if"):
            token = "if " + token[2:] + ":"
        elif token == "else":
            token = "else:"
        elif token == "continue":
            token = "raise SkipEntry()"
        lines.append("    " * indent + token)
    return compile("\n".join(lines), "<Normal-EIN HSC-Mock>", "exec")


CODE = compile_block(BLOCK)


class DP:
    def __init__(self, writes, name, value=12):
        self.writes, self.name, self.value = writes, name, value

    def State(self, *args):
        if args:
            self.writes.append((self.name, args[0]))
            self.value = args[0]
        return self.value


class Channel:
    def __init__(self, points):
        self.points = points

    def DPByHssDP(self, param):
        return self.points.get(param)


class Dom:
    def __init__(self, objects):
        self.objects, self.lookups = objects, []

    def GetObject(self, name):
        self.lookups.append(name)
        return self.objects.get(name)


def run(mode, actors, missing=(), missing_dp=(), manual=False, value=12,
        param="SET_POINT_TEMPERATURE", status=0, logging=False):
    writes = []
    room = Text("HKG-Raum-Test")
    # Spiegel des unveraenderten AktorenListe-Aufbaus: sechs Pflichtfelder,
    # in HS zusaetzlich die erste Temperaturquelle ueberspringen.
    fields = [str(status), mode, "IP", "20/12", "60", "0"] + actors
    rvi = Text(";".join(fields))
    actor_list = Text(";".join(fields[7 if mode == "HS" else 6:]))
    parameter = param if mode == "H" else "STATE"
    objects = {room: DP(writes, room, rvi)}
    for name in actors:
        if name and name not in missing:
            dp = DP(writes, name, value)
            objects[name] = dp if mode == "V" else Channel(
                {} if name in missing_dp else {parameter: dp})
    dom = Dom(objects)
    env = dict(SDFlag=0, EIN=0, AUS=1200, NOW=600, RVNListeAn=Text(""),
               RVN=room, aktuellerSchaltZustand=status, HSFlag=mode,
               AktorenListe=actor_list, Param=parameter, dom=dom, RVI=rvi,
               GT=12, RTemp=20, Flag_Hand_Temp=manual, log=logging, DEBUG=logging,
               logObj=DP([], "Log"), WriteLine=lambda message: None,
               RaumLogName=Text("Test"), SkipEntry=SkipEntry)
    try:
        exec(CODE, env)
    except SkipEntry:
        pass
    return writes, env, dom


class SchalterfolgTests(unittest.TestCase):
    def test_failure_logging(self):
        for mode, prefix, param in (("H", [], "SET_POINT_TEMPERATURE"),
                                    ("HS", ["Sensor"], "STATE")):
            for kwargs, expected in (
                    ({"missing": ["A"]}, "Test: A Objekt existiert nicht!"),
                    ({"missing_dp": ["A"]}, f"Datenpunkt {param} nicht vorhanden!")):
                with self.subTest(mode=mode, kwargs=kwargs):
                    writes, env, _ = run(mode, prefix + ["A"], logging=True, **kwargs)
                    self.assertEqual(len(writes), 1)  # Nur Softwarestatus, kein Steuerbefehl.
                    self.assertTrue(writes[0][1].startswith("1;"))
                    self.assertEqual(env["logObj"].value, expected)

    def test_missing_objects_and_dp(self):
        for mode, actors in (("H", ["Regler"]), ("HS", ["Sensor", "Schalter"])):
            for error in ("missing", "missing_dp"):
                with self.subTest(mode=mode, error=error):
                    writes, env, _ = run(mode, actors, **{error: [actors[-1]]})
                    self.assertEqual(len(writes), 1)
                    self.assertEqual(writes[0][0], "HKG-Raum-Test")
                    self.assertTrue(writes[0][1].startswith("1;"))
                    self.assertEqual(env["RVNListeAn"], "HKG-Raum-Test;")

    def test_all_present(self):
        for mode, actors, expected in (("H", ["Regler"], 20),
                                      ("HS", ["Sensor", "Schalter"], 1)):
            writes, _, _ = run(mode, actors)
            self.assertEqual(writes[0], (actors[-1], expected))
            self.assertTrue(writes[-1][1].startswith("1;"))

    def test_empty(self):
        for mode, actors in (("H", []), ("HS", ["Sensor"]),
                             ("H", ["Regler", ""]), ("HS", ["Sensor", ""])):
            writes = run(mode, actors)[0]
            self.assertEqual(writes[-1][0], "HKG-Raum-Test")
            self.assertTrue(writes[-1][1].startswith("1;"))
            self.assertEqual([name for name, _ in writes[:-1]],
                             [name for name in actors if name and name != "Sensor"])

    def test_hs_sensor_not_required_or_written(self):
        writes, _, dom = run("HS", ["Sensor", "Schalter"], missing=["Sensor"])
        self.assertNotIn("Sensor", dom.lookups)
        self.assertEqual(writes[0], ("Schalter", 1))
        writes, _, dom = run("HS", ["Sensor", "Schalter"])
        self.assertNotIn("Sensor", dom.lookups)
        self.assertNotIn("Sensor", [name for name, _ in writes])

    def test_group_and_parameter_variants(self):
        for param in ("SET_POINT_TEMPERATURE", "SET_TEMPERATURE", "SETPOINT"):
            writes, _, _ = run("H", ["Heizgruppe:1"], param=param)
            self.assertEqual(writes[0], ("Heizgruppe:1", 20))

    def test_manual_priority(self):
        writes, _, _ = run("H", ["Regler"], manual=True, value=17)
        self.assertEqual(len(writes), 1)  # Nur Status, bewusst kein Reglerbefehl.
        self.assertTrue(writes[0][1].startswith("1;"))
        self.assertEqual(run("H", ["Regler"], manual=True)[0][0], ("Regler", 20))

    def test_multiple_actors_independent_in_both_orders(self):
        for mode, prefix in (("H", []), ("HS", ["Sensor"])):
            for error in ("missing", "missing_dp"):
                for actors in (["A", "B"], ["B", "A"]):
                    with self.subTest(mode=mode, error=error, actors=actors):
                        writes, _, _ = run(mode, prefix + actors, **{error: ["B"]})
                        self.assertEqual([name for name, _ in writes],
                                         ["A", "HKG-Raum-Test"])
                        self.assertEqual(writes[0][1], 20 if mode == "H" else 1)
                        self.assertTrue(writes[-1][1].startswith("1;"))
            writes, _, _ = run(mode, prefix + ["A", "B"])
            self.assertEqual([name for name, _ in writes], ["A", "B", "HKG-Raum-Test"])

    def test_existing_status_and_sv_unchanged(self):
        for status in (1, 2, 3):
            self.assertEqual(run("H", ["Fehlt"], missing=["Fehlt"], status=status)[0], [])
        for mode in ("S", "V"):
            self.assertEqual(run(mode, ["A"])[0][0], ("A", 1))
            self.assertTrue(run(mode, ["Fehlt"], missing=["Fehlt"])[0][-1][1].startswith("1;"))


if __name__ == "__main__":
    unittest.main()
