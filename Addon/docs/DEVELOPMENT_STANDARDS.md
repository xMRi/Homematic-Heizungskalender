# Heizkalender Addon: Development Standards

## Inhalt

- [Laufzeitumgebung](#laufzeitumgebung)
- [Tcl-8.2-Einschränkungen](#tcl-82-einschränkungen)
- [Zeichenkodierung](#zeichenkodierung)
- [HTML-Ausgabe](#html-ausgabe)
- [ReGa-API](#rega-api)
- [CSS-Konventionen](#css-konventionen)
- [Deployment](#deployment)
- [Entschiedene Design-Fragen](#entschiedene-design-fragen)

---

## Laufzeitumgebung

- CCU3-Originalfirmware: Tcl 8.2.3, Linux
- Shebang: `#!/bin/tclsh`
- Tcl-Bibliothek: `load tclrega.so` für ReGa-Zugriff
- Webserver: eingebetteter CCU-Webserver, CGI-Ausführung
- Pfad auf der CCU: `/usr/local/addons/heizkalender/www/`
- URL im Browser: `http://<CCU-IP>/addons/heizkalender/`

---

## Tcl-8.2-Einschränkungen

Folgende Sprachfeatures sind in Tcl 8.2 nicht verfügbar und dürfen nicht verwendet werden:

| Nicht verfügbar | Workaround |
| --------------- | ---------- |
| `dict` | Flat-Listen als Key-Value-Paare (`lsearch`, `lindex`) |
| `lreverse` | Manuelle While-Schleife mit Index |
| `{*}` (Argument-Expansion) | `eval` oder umstrukturieren |
| `clock scan` mit ISO-Format | Regex-Extraktion + Rekonstruktion als `MM/DD/JJJJ HH:MM:SS` |
| `encoding convertfrom iso8859-1` | Nicht nötig, da CCU bereits ISO-8859-1 liefert (siehe [Zeichenkodierung](#zeichenkodierung)) |
| `file tempfile` | Temporäre Dateien vermeiden |
| `string equal -nocase` | `string tolower` + `string equal` |

Geschweifte Klammern in ReGa-Rückgaben erfordern eine manuelle Tiefenzählung, da reguläre Ausdrücke dafür ungeeignet sind. Die Prozedur `extract_stdout` (in `index.cgi`, `hkkurve.cgi`) implementiert dieses Muster.

---

## Zeichenkodierung

**Grundregel:** Alle CGI-Dateien senden `Content-Type: text/html; charset=iso-8859-1` und deklarieren dasselbe im `<meta charset>`-Tag.

**Warum ISO-8859-1:** Tcl 8.2 unterstützt kein UTF-8-Encoding. Die verfügbaren Encodings beschränken sich auf `utf-8`, `identity` und `unicode`; `encoding convertfrom iso8859-1` schlägt fehl. Die CCU liefert Systemvariablen, Logdateien und alle ReGa-Daten in ISO-8859-1. Tcl gibt diese Bytes unverändert aus. Der Browser interpretiert sie korrekt, wenn `charset=iso-8859-1` deklariert ist.

**lighttpd und W3C-Validator:** Der CCU-Webserver (lighttpd) leitet den `charset`-Parameter aus dem CGI-`Content-Type`-Header nicht weiter und schickt nur `Content-Type: text/html` ohne Charset. Damit fehlt dem Browser und dem W3C-Validator der Charset-Hinweis im HTTP-Header; sie verlassen sich allein auf den `<meta charset>`-Tag. Das ist kein Fehler in den CGI-Skripten, sondern ein lighttpd-Konfigurationsdetail der CCU. Browsers werten den `<meta charset>`-Tag korrekt aus. Der W3C-Validator meldet einen Widerspruch, wenn er die Seite über die CCU-URL validiert; bei direkter HTML-Eingabe im Validator tritt der Fehler nicht auf.

**RaspberryMatic/openCCU:** Auch unter RaspberryMatic bleibt die Situation dieselbe. Tcl 8.2.3 mit denselben eingeschränkten Encodings ist fest eingebaut, weil `tclrega.so` gegen diese Version gebunden ist. Eine Umstellung auf UTF-8 wäre erst möglich, wenn eine neue `tclrega.so` mit Tcl 8.6 verfügbar ist.

**Sonderzeichen im Quellcode:** Die CGI-Dateien sind als UTF-8 auf dem Entwicklungsrechner gespeichert. Sonderzeichen, die direkt im Tcl-Quellcode stehen (z.B. `°`, `ü`, `ä`), liegen als UTF-8-Mehrbyte-Sequenzen vor und werden von Tcl 8.2 nicht korrekt verarbeitet. Regel:

- Alle Sonderzeichen in HTML-Ausgaben als HTML-Entities schreiben: `&deg;`, `&uuml;`, `&auml;`, `&ouml;` usw.
- `format "%c" 176` erzeugt kein zuverlässiges ISO-8859-1-Byte auf der CCU; stattdessen `&deg;` verwenden.
- Kommentare im Tcl-Quellcode dürfen Umlaute enthalten (sie werden nicht ausgegeben).

**String-Vergleiche mit Nicht-ASCII-Zeichen (Tcl-8.2-Encoding-Bug):** `string first`, `string equal` und ähnliche String-Operationen liefern falsche Ergebnisse, wenn eine Seite des Vergleichs aus einem `exec`-Aufruf (z.B. `grep`) stammt und die andere aus einem Skript-Literal (`\xfc`) oder einer URL-dekodierten Zeichenkette. Obwohl `binary scan` für beide Quellen dasselbe Byte zeigt (z.B. `fc` für `ü`), unterscheiden sich die internen Repräsentationen in Tcl 8.2; der Vergleich schlägt dann fehl.

Workaround: Beide Seiten vor dem Vergleich auf reines ASCII normalisieren. Die Prozedur `to_ascii` (in `hkkurve.cgi`) entfernt alle Non-ASCII-Bytes via `regsub`:

```tcl
proc to_ascii {s} {
    regsub -all {[^\x00-\x7f]} $s {} r
    return $r
}
```

URL-Parameter mit Umlauten (z.B. `UG-B%FCro`) werden über `url_decode` dekodiert, wobei Umlaut-Percent-Sequences einfach entfernt statt in Bytes umgewandelt werden. Damit liefern sowohl `url_decode` als auch `to_ascii` reine ASCII-Strings, und `string first` funktioniert zuverlässig:

```tcl
# filter_raum kommt aus URL-Parameter (via url_decode, Umlaute entfernt)
# raumname kommt aus exec/grep (ISO-8859-1-Bytes, via to_ascii normalisiert)
if {[string first $filter_raum [to_ascii $raumname]] < 0} { continue }
```

Konsequenz: Sucht der Nutzer nach `UG-Büro`, wird der Filter intern zu `UG-Bro` (Umlaut entfernt). Der Log-Raumname `UG-Büro(22)` wird via `to_ascii` ebenfalls zu `UG-Bro(22)`. Der Substring-Match findet dann `UG-Bro` in `UG-Bro(22)` und gibt den Eintrag korrekt zurück. Namen mit Umlauten können dadurch theoretisch falsche Treffer erzeugen (z.B. `UG-Bro` würde auch `EG-Brose` treffen); in der Praxis sind die Raumnamen ausreichend eindeutig.

---

## HTML-Ausgabe

**`htmlquote`:** Alle Werte, die aus externen Quellen stammen (ReGa, Logdateien, URL-Parameter), müssen durch `htmlquote` laufen, bevor sie in HTML eingefügt werden. Ausnahme: Strings, die bereits ausschließlich HTML-Entities und sichere numerische Werte enthalten (z.B. Temperaturstrings aus `format_temp`), dürfen nicht nochmals durch `htmlquote` laufen, da `&` sonst zu `&amp;` escapt wird.

**Temperaturanzeige:** Die Prozedur `format_temp` in `sysvars.cgi` gibt fertige HTML-Strings zurück (`"$t &deg;C"`). Diese nicht durch `htmlquote` leiten.

**Keine Inline-Styles in CGI-Dateien.** Alle Stile gehören in `heizkalender.css`.

---

## ReGa-API

ReGa-Scripte werden mit `rega_script {... HomeMatic-Script ...}` ausgeführt. Die Rückgabe hat die Form:

```txt
STDOUT {<inhalt>} sessionId {} httpUserAgent {} result {<inhalt>}
```

Enthält `<inhalt>` geschweifte Klammern, schlägt `array set` fehl. Deshalb wird der STDOUT-Block immer manuell mit Tiefenzählung extrahiert (`extract_stdout`-Prozedur oder inline).

**Daten aus der ReGa immer als ISO-8859-1 behandeln**, kein Encoding-Umbau nötig.

---

## CSS-Konventionen

- Alle Stile in `heizkalender.css`; Inline-Styles in CGI-Dateien vermeiden.
- Keine globale `body`- oder `html`-`font-size` gesetzt; Browser-Default wird verwendet.
- Keine externe Schriftart, kein CDN.
- Klassen-Präfix: immer `hk-` (z.B. `.hk-table`, `.hk-nav`, `.hk-hint`).
- `font-size`-Regeln in Klassen nur setzen, wenn eine bewusste Abweichung vom Fließtext gewünscht ist (z.B. Navigationsleiste `1.05em`). Nicht zur Normalisierung verwenden.
- Log-Tabellen verwenden `font-family: monospace` ohne explizite `font-size` (erbt Browser-Default).
- Eingebettete Tabellen (`.hk-table-inline`) erhalten keine abweichende `font-size` (gleiche Größe wie die umgebende Tabelle).

---

## Deployment

**Einzelne Datei auf CCU übertragen:**

```bash
scp Addon/src/heizkalender/www/<datei>.cgi root@<CCU-IP>:/usr/local/addons/heizkalender/www/
```

Pfade immer relativ ab dem Projektverzeichnis angeben (nicht absolut).

**Mehrere Dateien gleichzeitig:**

```bash
scp Addon/src/heizkalender/www/index.cgi Addon/src/heizkalender/www/heizkalender.css \
    root@<CCU-IP>:/usr/local/addons/heizkalender/www/
```

**Vollständiges Paket für ein Release:**

```bash
./Addon/build.sh
```

Das Paket landet in `Addon/build/heizkalender-addon-<Version>.tar.gz` und wird als GitHub-Release-Asset angehängt.

**CCU-IP:** siehe lokale Konfiguration, SSH-Benutzer: `root`.

---

## Entschiedene Design-Fragen

Diese Entscheidungen sind getroffen und sollen nicht ohne neuen Grund wieder aufgegriffen werden.

| Thema | Entscheidung | Begründung |
| ----- | ------------ | ---------- |
| Zeichenkodierung | ISO-8859-1 durchgehend, keine UTF-8-Konvertierung | Tcl 8.2 hat kein funktionierendes UTF-8-Encoding; CCU liefert ohnehin ISO-8859-1 |
| Sonderzeichen im Quellcode | HTML-Entities (`&deg;`, `&uuml;` usw.) | CGI-Dateien sind als UTF-8 gespeichert; Tcl 8.2 verarbeitet UTF-8-Mehrbyte-Sequenzen nicht korrekt |
| JavaScript | Kein JavaScript auf den Seiten | Alle Seiten müssen ohne JS funktionieren; Filterlogik läuft serverseitig |
| Schreiben auf die CCU | Keine Schreiboperationen | Das Addon ist ein reines Beobachtungswerkzeug |
| Gemeinsames Stylesheet | Alle Seiten teilen `heizkalender.css` | Einheitliches Erscheinungsbild, keine CSS-Duplikation |
| Kein `source`/`package` | Jede CGI-Datei ist standalone | CCU hat keine Tcl-Package-Infrastruktur; Deployment-Einfachheit |
| Favicon | `hk-logo-50.png` auf allen Seiten | Wiedererkennbarkeit im Browser-Tab |
| Temperaturtyp in Heizkurvenkontrolle | Format `16.3 °C (AT)` statt `AT: 16.3 °C` | Lesbarkeit: Wert zuerst, Typ als Ergänzung in Klammern |
