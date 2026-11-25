"""Echte CGI-Ausgabe mit lokalem Tcl und kontrollierten ReGa-Daten."""
import os
import re
import subprocess
import unittest
from html.parser import HTMLParser


class Node:
    def __init__(self, tag, attrs=()):
        self.tag, self.attrs, self.children = tag, dict(attrs), []

    def text(self):
        return "".join(c.text() if isinstance(c, Node) else c for c in self.children)

    def find(self, tag=None, id=None):
        found = []
        if (tag is None or self.tag == tag) and (id is None or self.attrs.get("id") == id):
            found.append(self)
        for child in self.children:
            if isinstance(child, Node):
                found.extend(child.find(tag, id))
        return found


class HTML(HTMLParser):
    def __init__(self, source):
        super().__init__(convert_charrefs=True)
        self.root = Node("root")
        self.stack = [self.root]
        self.feed(source)

    def handle_starttag(self, tag, attrs):
        node = Node(tag, attrs)
        self.stack[-1].children.append(node)
        if tag not in {"meta", "link", "img", "col", "input", "br", "hr"}:
            self.stack.append(node)

    def handle_endtag(self, tag):
        for i in range(len(self.stack) - 1, 0, -1):
            if self.stack[i].tag == tag:
                del self.stack[i:]
                break

    def handle_data(self, text):
        self.stack[-1].children.append(text)


class Termine(unittest.TestCase):
    def render(self, counts, vlz, weather=True, abruf=True):
        # Absichtlich Zukunft, Vergangenheit, aktiver Termin statt Sortierreihenfolge.
        starts = ["18:00", "08:00", "11:00"]
        ends = ["19:00", "10:00", "13:00"]
        sl = "".join(
            f"{rid};2026-11-25 {starts[i]}:00;2026-11-25 {ends[i]}:00;20;H;"
            for rid, count in enumerate(counts, 1) for i in range(count)
        )
        names = [f"HKG-Raum-Test{rid}" for rid in range(1, len(counts) + 1)]
        body = (sl + "\n===SL===\n" + ";".join(f"{i}=Test{i}" for i in range(1, len(counts)+1))
                + "\n===RL===\n" + ("5" if weather else "") + "\n===AT===\n" + ";".join(names)
                + "\n===HKG===\n" + "".join(n + "\t1;H;IP;20/12;60;0\n" for n in names)
                + "\n===TEMPS===\n")
        if vlz:
            body += "\n===VLZ===\n" + "~".join(
                n + ";60;2026-11-25 07:00:00;2026-11-25 08:00:00;2026-11-25 10:00:00;0"
                for n in names)
        body += "\n===ABRUF===\n" + ("2026-11-25 12:00:00" if abruf else "")
        result = subprocess.run(
            ["tclsh", "Tests/Addon-index-Termine/harness.tcl", "Addon/src/heizkalender/www/index.cgi"],
            input=body, text=True, capture_output=True, env={**os.environ, "TZ": "UTC"}, check=True)
        self.assertEqual(result.stderr, "")
        return HTML(result.stdout).root

    def assert_layout(self, root, counts, hint, vlz):
        self.assertEqual(root.find(id="hk-index-controls"), [])
        tables = root.find("table", "hk-termine-tabelle")
        self.assertEqual(len(tables), int(bool(counts)))
        empty = [p for p in root.find("p") if "hk-empty" in p.attrs.get("class", "").split()]
        self.assertEqual(len(empty), int(not counts))
        self.assertEqual(root.find(id="hk-termine-filter"), [])
        self.assertEqual(root.find("fieldset"), [])
        temperatures = [p for p in root.find("p") if "hk-hint" in p.attrs.get("class", "").split()]
        self.assertEqual(len(temperatures), int(hint))
        explanations = [div for div in root.find("div")
                        if "hk-hint" in div.attrs.get("class", "").split()]
        self.assertEqual(len(explanations), int(bool(counts) and vlz))
        # Tiefensuche bewahrt Dokumentreihenfolge trotz Scrollhülle der Tabelle.
        document_nodes = root.find()
        preceding = (tables or empty)[0]
        for block in temperatures + explanations:
            self.assertEqual(block.find("table"), [])
        for block in explanations:
            self.assertGreater(document_nodes.index(block), document_nodes.index(preceding))
        if temperatures:
            self.assertLess(document_nodes.index(temperatures[0]), document_nodes.index(preceding))
            self.assertIn("Außentemperatur", temperatures[0].text())
            self.assertNotIn("Die Spalten", temperatures[0].text())
            self.assertEqual(temperatures[0].find("div"), [])
        if explanations:
            self.assertIn("Die Spalten", explanations[0].text())
            self.assertIn("Vorlauf", explanations[0].text())
            self.assertIn("Heizen ab", explanations[0].text())
            self.assertNotIn("Außentemperatur", explanations[0].text())
            self.assertEqual(explanations[0].find("p"), [])
            if temperatures:
                self.assertGreater(document_nodes.index(explanations[0]), document_nodes.index(temperatures[0]))

    def test_layout_variants(self):
        for counts, weather, abruf in [
            ((), False, False), ((0,), False, False), ((3, 2), False, False),
            ((1,), True, True), ((), True, True), ((1,), False, True),
        ]:
            with self.subTest(counts=counts, weather=weather, abruf=abruf):
                root = self.render(counts, False, weather=weather, abruf=abruf)
                self.assert_layout(root, counts, weather or abruf, False)

    def test_cgi_matrix(self):
        for counts in [(0,), (1,), (3,), (3, 2), (1, 1), ()]:
            for vlz in [False, True]:
                with self.subTest(counts=counts, schaltzeiten=vlz):
                    root = self.render(counts, vlz)
                    self.assert_layout(root, counts, True, vlz)
                    scripts = root.find("script")
                    self.assertEqual(len(scripts), 1)
                    self.assertEqual(scripts[0].attrs.get("src"), "index.js")
                    self.assertIn("defer", scripts[0].attrs)
                    tables = root.find("table", "hk-termine-tabelle")
                    self.assertEqual(len(tables), int(bool(counts)))
                    details = tables[0].find("details") if tables else []
                    self.assertEqual(len(details), sum(c > 1 for c in counts))
                    for detail, count in zip(details, [c for c in counts if c > 1]):
                        self.assertIn("hk-termin-details", detail.attrs.get("class", "").split())
                        self.assertIn("open", detail.attrs)
                        times = re.findall(r"25\.11\.2026 (\d\d:\d\d)", detail.text())[::2]
                        self.assertEqual(times, ["08:00", "18:00"] if count == 2 else ["08:00", "11:00", "18:00"])
                    controls = root.find(id="hk-termine-control")
                    inputs = root.find("input", "hk-termine-toggle")
                    self.assertEqual(len(controls), int(bool(details)))
                    self.assertEqual(len(inputs), int(bool(details)))
                    if tables:
                        termin_headers = [th for th in tables[0].find("th")
                                          if "col-sl-termin" in th.attrs.get("class", "").split()]
                        self.assertEqual(len(termin_headers), 1)
                        self.assertIn("Termin", termin_headers[0].text())
                        self.assertEqual(termin_headers[0].find(id="hk-termine-control"), controls)
                        self.assertEqual(termin_headers[0].find("input"), inputs)
                        for row in tables[0].find("tr")[1:]:
                            self.assertEqual(row.find("input"), [])
                    if controls:
                        self.assertEqual(controls[0].tag, "label")
                        self.assertIn("hidden", controls[0].attrs)
                        self.assertEqual(controls[0].find("button"), [])
                        self.assertEqual(controls[0].find("input"), inputs)
                        attrs = inputs[0].attrs
                        self.assertEqual(attrs["type"], "checkbox")
                        self.assertIn("checked", attrs)
                        self.assertEqual(attrs["aria-controls"], "hk-termine-tabelle")
                        labels = [label for label in controls[0].find("label")
                                  if label.attrs.get("for") == "hk-termine-toggle"
                                  or inputs[0] in label.find("input")]
                        self.assertEqual(len(labels), 1)
                        self.assertEqual(labels[0].text().strip(), "Alle aufklappen")
                        self.assertNotIn("data-label-open", attrs)
                        self.assertNotIn("data-label-close", attrs)
                        self.assertNotIn("data-state", attrs)
                    if tables:
                        headers = [n.text() for n in tables[0].find("th")]
                        self.assertEqual("Vorlauf" in headers, vlz)
                        self.assertEqual("Heizen ab" in headers, vlz)
                        self.assertEqual(len(tables[0].find("tr")), len(counts) + 1)
                        if counts == (1,):
                            self.assertIn("25.11.2026 18:00", tables[0].text())


if __name__ == "__main__":
    unittest.main(verbosity=2)
