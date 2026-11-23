#!/usr/bin/env python3
"""Erzeugt einen isolierten echten HSC-Zweig mit ausschließlich Fake-Eingaben."""
from pathlib import Path
from pruefung import source_parts, ROOT

_, declarations, branch = source_parts()
branch = branch.replace("logObj.State(", "WriteLine(")
branch = branch.replace('system.Exec("cat /proc/uptime", &kernelLaufzeitAusgabe, &kernelLaufzeitFehler);',
                        'kernelLaufzeitAusgabe=FakeUptime; kernelLaufzeitFehler=FakeErr; FakeReads=FakeReads+1;')
assert "system.Exec" not in branch and "dom." not in branch and ".State(" not in branch
cases = [
    ("3599", 0, "", 12, 5, "3599 0", ""),
    ("3600", 0, "", 12, 5, "3600 0", ""),
    ("alt-frueh", 0, "ALTER-EINTRAG", 12, 5, "3599 0", ""),
    ("alt-spaet", 0, "ALTER-EINTRAG", 12, 5, "3600 0", ""),
    ("messwert", 16, "", 12, 5, "ungueltig", ""),
    ("leer", 0, "", 12, 5, "", ""),
    ("negativ", 0, "", 12, 5, "-3600 0", ""),
    ("ungueltig", 0, "", 12, 5, "abc 0", ""),
    ("stderr", 0, "", 12, 5, "3600 0", "Fehler"),
    ("AT-ueber-GT", 0, "", 12, 15, "3600.25 0", ""),
    ("schaetzung-null", 0, "", 0, 0, "3600 0", ""),
    ("schaetzung-negativ", 0, "", -5, -2, "3600 0", ""),
]
text = '''!// Isolierter Neustarttest, nicht das produktive Skript ausfuehren.
!// Kein Zugriff auf Objekte, Sensoren, Aktoren oder Betriebssystem.
boolean log=true;
boolean DEBUG=false;
string RaumLogName="Neustart-Test";
string AktAktor="FAKE";
string SchaltListeNeu="";
string strAlterListenEintrag="";
string FakeUptime="";
string FakeErr="";
integer FakeReads=0;
real ISTTemperatur=0.0;
real GT=12.0;
real AT=5.0;
string TestWiederholung;
''' + declarations
for name, measured, old, gt, at, stdout, stderr in cases:
    text += f'''\nWriteLine("FALL {name}");
kernelLaufzeitGelesen=false; FakeReads=0; SchaltListeNeu="";
FakeUptime="{stdout}"; FakeErr="{stderr}";
strAlterListenEintrag="{old}"; GT={gt}.0; AT={at}.0;
foreach(TestWiederholung,"1;2".Split(";")){{
ISTTemperatur={measured}.0;
''' + branch + '''WriteLine("NORMALE-FORTSETZUNG IST=" # ISTTemperatur);
}
WriteLine("LISTE=" # SchaltListeNeu # " LESEZAHL=" # FakeReads);
'''
destination = ROOT / "build/neustart-isoliert.hsc"
destination.parent.mkdir(parents=True, exist_ok=True)
destination.write_text(text)
print(destination.relative_to(ROOT))
