#!/bin/tclsh
# Heizkalender-Addon: Vorheizzeit-Rechner
# Zielplattform: CCU3, Tcl 8.2.3
#
# Laedt Systemvariablen von der CCU als Vorbelegung:
#   HK2-Kurve            - 8 AT-Stuetzwerte (semikolongetrennt)
#   HK2-Kurvenversatz    - Globaler Einschalt-Versatz in Minuten
#   HK2-Aussentemperatur - Aktueller AT-Durchschnitt
#   HK2-HKG-Liste        - Raumliste fuer Dropdown
#   HKG-Raum-*           - Raumvariablen (Wohlfuehltemp, Grundtemp, VHZ, Faktor, Mindest)
#
# Die Berechnung laeuft clientseitig in hkrechner.js (kein Reload).

load tclrega.so

proc htmlquote {s} {
    return [string map {& &amp; < &lt; > &gt; \" &quot;} $s]
}

proc jsquote {s} {
    return [string map {\\ \\\\ \" \\\" ' \\' \n \\n \r {}} $s]
}

proc extract_stdout {rega_raw} {
    set ob [format "%c" 123]
    set cb [format "%c" 125]
    set stdout_start [string first "STDOUT " $rega_raw]
    if {$stdout_start < 0} { return "" }
    set brace_start [expr {$stdout_start + 7}]
    if {![string equal [string index $rega_raw $brace_start] $ob]} { return "" }
    set depth 0
    set brace_end -1
    set rlen [string length $rega_raw]
    set j $brace_start
    while {$j < $rlen} {
        set ch [string index $rega_raw $j]
        if {[string equal $ch $ob]} { incr depth } \
        elseif {[string equal $ch $cb]} {
            incr depth -1
            if {$depth == 0} { set brace_end $j; break }
        }
        incr j
    }
    if {$brace_end > $brace_start} {
        return [string range $rega_raw [expr {$brace_start+1}] [expr {$brace_end-1}]]
    }
    return ""
}

# ---------------------------------------------------------------------------
# Globale Systemvariablen laden
# ---------------------------------------------------------------------------
set ccu_kurve ""
set ccu_kv ""
set ccu_at ""
set ccu_ka "0.8"

catch {
    set raw [extract_stdout [rega_script {
        var sv;
        sv = dom.GetObject("HK2-Kurve");
        if (sv) { WriteLine("KURVE:" # sv.Value()); }
        sv = dom.GetObject("HK2-Kurvenversatz");
        if (sv) { WriteLine("KV:" # sv.Value()); }
        sv = dom.GetObject("HK2-Aussentemperatur");
        if (sv) { WriteLine("AT:" # sv.Value()); }
        sv = dom.GetObject("HK2-Kurvenanpassung");
        if (sv) { WriteLine("KA:" # sv.Value()); }
    }]]
    foreach line [split $raw "\n"] {
        set line [string trim $line]
        if {[string match "KURVE:*" $line]} { set ccu_kurve [string range $line 6 end] }
        if {[string match "KV:*"    $line]} {
            catch { set ccu_kv [format "%g" [string range $line 3 end]] } \
                  { set ccu_kv [string range $line 3 end] }
        }
        if {[string match "AT:*"    $line]} {
            catch { set ccu_at [format "%.1f" [string range $line 3 end]] } \
                  { set ccu_at [string range $line 3 end] }
        }
        if {[string match "KA:*"    $line]} {
            catch { set ccu_ka [format "%g" [string range $line 3 end]] } \
                  { set ccu_ka [string range $line 3 end] }
        }
    }
}

# ---------------------------------------------------------------------------
# Raumvariablen laden
# ---------------------------------------------------------------------------
# raeume_namen  - geordnete Liste der Raumnamen
# raeume_werte  - Array: Name -> Rohwert der Raumvariable
set raeume_namen {}
array set raeume_werte {}

catch {
    set raw [extract_stdout [rega_script {
        string eintrag;
        string raum;
        var sv;
        var liste = dom.GetObject("HK2-HKG-Liste");
        if (liste) {
            foreach(eintrag, liste.Value().Split(";")) {
                ! Gruppeneintraege: "HKG-Raum-A+HKG-Raum-B" -> nur ersten Raum verwenden
                raum = eintrag.StrValueByIndex("+", 0);
                sv = dom.GetObject(raum);
                if (sv) { WriteLine(raum # "=" # sv.Value()); }
            }
        }
    }]]
    foreach line [split $raw "\n"] {
        set line [string trim $line]
        set eq [string first "=" $line]
        if {$eq > 0} {
            set rname [string range $line 0 [expr {$eq - 1}]]
            set rval  [string range $line [expr {$eq + 1}] end]
            # Nur Raeume mit Modus H, HS oder S (nicht V = Variable setzen)
            set fields [split $rval ";"]
            set modus [lindex $fields 1]
            if {[string equal $modus "H"] || [string equal $modus "HS"] || [string equal $modus "S"]} {
                lappend raeume_namen $rname
                set raeume_werte($rname) $rval
            }
        }
    }
}

# Anzeigenamen alphabetisch sortieren
set raeume_namen [lsort $raeume_namen]

# Anzeigenamen: "HKG-Raum-EG-Saal" -> "EG-Saal"
proc raum_label {name} {
    if {[string match "HKG-Raum-*" $name]} {
        return [string range $name 9 end]
    }
    return $name
}

# Ersten Raum als Vorbelegung fuer die Einzelfelder verwenden
set erster_raum_ziel  "20"
set erster_raum_gt    "10"
set erster_raum_vhz   "0"
set erster_raum_f1    "1.0"
set erster_raum_mindest "15"

if {[llength $raeume_namen] > 0} {
    set rname [lindex $raeume_namen 0]
    set rval  $raeume_werte($rname)
    set fields [split $rval ";"]
    # Feld 3: Wohlfuehltemp[/Grundtemp]
    set feld3 [lindex $fields 3]
    set slash [string first "/" $feld3]
    if {$slash >= 0} {
        catch { set erster_raum_ziel [format "%.1f" [string range $feld3 0 [expr {$slash-1}]]] }
        catch { set erster_raum_gt   [format "%.1f" [string range $feld3 [expr {$slash+1}] end]] }
    } else {
        catch { set erster_raum_ziel [format "%.1f" $feld3] }
    }
    # Feld 4: Vorheizzeit[*Faktor[*MindestMin]]
    set feld4 [lindex $fields 4]
    set parts [split $feld4 "*"]
    catch { set erster_raum_vhz [format "%g" [lindex $parts 0]] }
    if {[llength $parts] >= 2} {
        catch { set erster_raum_f1 [format "%g" [lindex $parts 1]] }
    }
    if {[llength $parts] >= 3} {
        catch { set erster_raum_mindest [format "%g" [lindex $parts 2]] }
    }
}

# ---------------------------------------------------------------------------
# Versionsnummer
# ---------------------------------------------------------------------------
set hk_version "?"
catch {
    set vfh [open "/usr/local/addons/heizkalender/VERSION" r]
    gets $vfh hk_version
    close $vfh
    set hk_version [string trim $hk_version]
}

# ---------------------------------------------------------------------------
# HTML
# ---------------------------------------------------------------------------
puts "Content-Type: text/html; charset=iso-8859-1\nContent-Language: de\nCache-Control: no-cache, no-store\n"
puts {<!DOCTYPE html>
<html lang="de">
<head>
  <meta charset="iso-8859-1">
  <meta name="viewport" content="width=device-width, initial-scale=1">}
puts "  <title>Vorheizzeit-Rechner | Heizkalender ${hk_version}</title>"
puts {  <link rel="stylesheet" href="heizkalender.css">
  <link rel="stylesheet" href="hkrechner.css">
  <link rel="apple-touch-icon" sizes="180x180" href="apple-touch-icon.png">
  <link rel="icon" type="image/png" sizes="32x32" href="favicon-32x32.png">
  <link rel="icon" type="image/png" sizes="16x16" href="favicon-16x16.png">
  <link rel="manifest" href="site.webmanifest">}

# Raumdaten als JS-Variable ausgeben
puts {  <script>}
puts "  var HKR_RAEUME = \["
set first 1
foreach rname $raeume_namen {
    set rval $raeume_werte($rname)
    set fields [split $rval ";"]
    set feld3 [lindex $fields 3]
    set slash [string first "/" $feld3]
    set ziel "20"; set gt ""
    if {$slash >= 0} {
        catch { set ziel [format "%.1f" [string range $feld3 0 [expr {$slash-1}]]] }
        catch { set gt   [format "%.1f" [string range $feld3 [expr {$slash+1}] end]] }
    } else {
        catch { set ziel [format "%.1f" $feld3] }
    }
    set feld4 [lindex $fields 4]
    set parts [split $feld4 "*"]
    set vhz "0"; set f1 "1.0"; set mindest "15"
    catch { set vhz [format "%g" [lindex $parts 0]] }
    if {[llength $parts] >= 2} { catch { set f1 [format "%g" [lindex $parts 1]] } }
    if {[llength $parts] >= 3} { catch { set mindest [format "%g" [lindex $parts 2]] } }
    set label [raum_label $rname]
    if {!$first} { puts "," }
    set first 0
    puts -nonewline "    \{\"name\":\"[jsquote $label]\",\"ziel\":\"[jsquote $ziel]\",\"gt\":\"[jsquote $gt]\",\"vhz\":\"[jsquote $vhz]\",\"f1\":\"[jsquote $f1]\",\"mindest\":\"[jsquote $mindest]\"\}"
}
puts ""
puts "  \];"
puts {  </script>
</head>
<body>
<div id="content">
  <div class="hk-header">
    <img src="hk-logo-200.png" height="50" alt="Heizkalender-Logo" class="hk-header-logo">
    <h1>Heizkalender</h1>
  </div>
  <nav class="hk-nav">
    <a href="index.cgi">Raum&uuml;bersicht</a>
    <a href="hkkurve.cgi">Heizkurve</a>
    <a href="hkrechner.cgi" class="active">Rechner</a>
    <a href="hkconfig.cgi">Einstellungen</a>
    <a href="hklog.cgi">HK-Log</a>
    <a href="syslog.cgi">Syslog</a>
    <a href="sysvars.cgi">Systemvariablen</a>
  </nav>

  <div class="hkr-page">

    <p class="hk-hint">Simuliert die Vorheizzeit-Berechnung aus HK-Skript&nbsp;2.
    Die Vorbelegung stammt aus den Systemvariablen der CCU. &Auml;nderungen wirken sofort ohne Seiten-Reload.</p>

    <div class="hkr-gruppen">

      <!-- Gruppe 1: Eingabe-Parameter -->
      <div class="hkr-gruppe hkr-gruppe-eingabe">
        <fieldset>
          <legend>Globale Parameter</legend>
          <div class="hkr-grid hkr-grid-7">

            <div class="hkr-field">
              <label for="hkr-at">Au&szlig;entemperatur (&deg;C)</label>}
puts "              <input type=\"number\" id=\"hkr-at\" step=\"0.1\" maxlength=\"6\""
puts "                     value=\"[htmlquote $ccu_at]\" placeholder=\"z.B. 5\">"
puts {              <span class="hkr-err" id="hkr-at-err"></span>
            </div>

            <div class="hkr-field">
              <label for="hkr-kv">Vorz. Heizbeginn (min)</label>}
puts "              <input type=\"number\" id=\"hkr-kv\" step=\"1\" maxlength=\"3\""
puts "                     value=\"[htmlquote $ccu_kv]\" placeholder=\"0\">"
puts {              <span class="hkr-err" id="hkr-kv-err"></span>
            </div>

            <div class="hkr-field">
              <label for="hkr-ka">Kurvenanpassung K</label>}
puts "              <input type=\"number\" id=\"hkr-ka\" step=\"0.1\" maxlength=\"4\""
puts "                     value=\"[htmlquote $ccu_ka]\" placeholder=\"0.8\">"
puts {              <span class="hkr-err" id="hkr-ka-err"></span>
            </div>

            <div class="hkr-field hkr-field-wide2">
              <label for="hkr-kurve">HK2-Kurve (8 Werte, semikolongetrennt)</label>}
puts "              <input type=\"text\" id=\"hkr-kurve\" maxlength=\"60\""
puts "                     pattern=\"\\d+(\\.\\d+)?(;\\d+(\\.\\d+)?){7}\""
puts "                     value=\"[htmlquote $ccu_kurve]\" placeholder=\"8 Werte, semikolongetrennt\">"
puts {              <span class="hkr-err" id="hkr-kurve-err"></span>
            </div>

          </div>
        </fieldset>

        <fieldset>
          <legend>Raum-Parameter</legend>
          <div class="hkr-grid hkr-grid-7">

            <div class="hkr-field">
              <label for="hkr-raum">Raum laden</label>
              <select id="hkr-raum">}
foreach rname $raeume_namen {
    set label [raum_label $rname]
    puts "                <option value=\"[htmlquote $label]\">[htmlquote $label]</option>"
}
puts {              </select>
            </div>

            <div class="hkr-field">
              <label for="hkr-ist">Ist-Temperatur (&deg;C)</label>
              <input type="number" id="hkr-ist" step="0.1" maxlength="5"
                     value="18" placeholder="z.B. 18">
              <span class="hkr-err" id="hkr-ist-err"></span>
            </div>

            <div class="hkr-field">
              <label for="hkr-ziel">Wohlf&uuml;hltemp. (&deg;C)</label>}
puts "              <input type=\"number\" id=\"hkr-ziel\" step=\"0.1\" maxlength=\"5\""
puts "                     value=\"[htmlquote $erster_raum_ziel]\" placeholder=\"z.B. 20\">"
puts {              <span class="hkr-err" id="hkr-ziel-err"></span>
            </div>

            <div class="hkr-field">
              <label for="hkr-gt">Abw. Grundtemp. (&deg;C)</label>}
puts "              <input type=\"number\" id=\"hkr-gt\" step=\"0.1\" maxlength=\"5\""
puts "                     value=\"[htmlquote $erster_raum_gt]\" placeholder=\"z.B. 16\">"
puts {              <span class="hkr-err" id="hkr-gt-err"></span>
            </div>

            <div class="hkr-field">
              <label for="hkr-vhz">Vorz. Heizbeginn (min)</label>}
puts "              <input type=\"number\" id=\"hkr-vhz\" step=\"1\" maxlength=\"3\""
puts "                     value=\"[htmlquote $erster_raum_vhz]\" placeholder=\"0\">"
puts {              <span class="hkr-err" id="hkr-vhz-err"></span>
            </div>

            <div class="hkr-field">
              <label for="hkr-faktor1">Faktor Heizkurve</label>}
puts "              <input type=\"number\" id=\"hkr-faktor1\" step=\"0.1\" maxlength=\"4\""
puts "                     value=\"[htmlquote $erster_raum_f1]\" placeholder=\"1.0\">"
puts {              <span class="hkr-err" id="hkr-faktor1-err"></span>
            </div>

            <div class="hkr-field">
              <label for="hkr-mindest">Mindest-Vorlauf (min)</label>}
puts "              <input type=\"number\" id=\"hkr-mindest\" step=\"1\" maxlength=\"3\""
puts "                     value=\"[htmlquote $erster_raum_mindest]\" placeholder=\"15\">"
puts {              <span class="hkr-err" id="hkr-mindest-err"></span>
            </div>

          </div>
        </fieldset>
      </div><!-- hkr-gruppe-eingabe -->

      <!-- Gruppe 4: Zeitanteile + Heizbedarf-Kurve (2 gleiche Spalten) -->
      <div class="hkr-gruppe hkr-gruppe-zeitanteile" id="hkr-gruppe-zeitanteile" style="display:none">

        <fieldset id="hkr-fs-zeit">
          <legend>Zeitanteile</legend>
          <canvas id="hkr-canvas-zeit" width="560" height="133"></canvas>
          <p class="hkr-canvas-legende">
            Zeile 1 (Rohwerte, vor <i>f</i><sub>2</sub>):
            <span class="hkr-cl-vhz">&#x25A0;</span> V<sub>raum</sub> + V<sub>global</sub> (Vorz. Heizbeginn)
            &nbsp;
            <span class="hkr-cl-at">&#x25A0;</span> <i>f</i><sub>1</sub> &middot; HK2(T<sub>at</sub>)<br>
            Zeile 2 (skaliert, nach <i>f</i><sub>2</sub>):
            <span style="color:#7ab8df">&#x25A0;</span> V<sub>raum</sub> + V<sub>global</sub> &middot; <i>f</i><sub>2</sub>
            &nbsp;
            <span style="color:#f0a855">&#x25A0;</span> <i>f</i><sub>1</sub> &middot; HK2(T<sub>at</sub>) &middot; <i>f</i><sub>2</sub><br>
            Zeile 3: <span style="color:#5cb85c">&#x25A0;</span> VLZ<sub>eff</sub> (Gesamtvorheizzeit effektiv)
          </p>
        </fieldset>

        <fieldset id="hkr-fs-kurve">
          <legend>Heizbedarf-Kurve</legend>
          <canvas id="hkr-canvas-f2" width="560" height="224"></canvas>
        </fieldset>

      </div><!-- hkr-gruppe-zeitanteile -->

      <!-- Gruppe 3: Ergebnis + Legende + Formeln -->
      <div class="hkr-gruppe hkr-gruppe-ergebnis" id="hkr-gruppe-ergebnis" style="display:none">

        <fieldset id="hkr-fs-ergebnis">
          <legend>Ergebnis</legend>
          <table class="hk-table hkr-table hkr-table-vertikal">
            <tr><th><i>V</i><sub>raum</sub></th>     <td id="hkr-r-vhz-roh"></td>    <td class="hkr-einheit">min</td></tr>
            <tr><th><i>V</i><sub>global</sub></th>   <td id="hkr-r-kv"></td>          <td class="hkr-einheit">min</td></tr>
            <tr><th>HK2</th>                          <td id="hkr-r-at-roh"></td>      <td class="hkr-einheit">min</td></tr>
            <tr><th><i>f</i><sub>1</sub></th>         <td id="hkr-r-f1"></td>          <td class="hkr-einheit"></td></tr>
            <tr><th><i>f</i><sub>2</sub></th>         <td id="hkr-r-f2"></td>          <td class="hkr-einheit"></td></tr>
            <tr><th><i>V</i> &middot; <i>f</i><sub>2</sub></th>                          <td id="hkr-r-vhz-skal"></td>    <td class="hkr-einheit">min</td></tr>
            <tr><th>HK2 &middot; <i>f</i><sub>1</sub> &middot; <i>f</i><sub>2</sub></th>  <td id="hkr-r-at-skal"></td>     <td class="hkr-einheit">min</td></tr>
            <tr><th>VLZ</th>                          <td id="hkr-r-gesamt-roh"></td>  <td class="hkr-einheit">min</td></tr>
            <tr><th><i>T</i><sub>Mindest</sub></th>  <td id="hkr-r-mindest"></td>     <td class="hkr-einheit">min</td></tr>
            <tr class="hkr-row-effektiv-tr"><th><strong>VLZ<sub>eff</sub></strong></th> <td id="hkr-r-effektiv"></td>  <td class="hkr-einheit">min</td></tr>
            <tr><th>&#x25b3;T/h</th>                 <td id="hkr-r-quotient"></td>    <td class="hkr-einheit">&deg;C/h</td></tr>
          </table>
        </fieldset>

        <fieldset id="hkr-fs-legende">
          <legend>Legende</legend>
          <table class="hkr-legende">
          <tr><td>VLZ</td><td>Vorlaufzeit in Minuten</td></tr>
          <tr><td>VLZ<sub>eff</sub></td><td>Gesamtvorheizzeit effektiv</td></tr>
          <tr><td><i>V</i><sub>raum</sub></td><td>Vorz. Heizbeginn (Raum)</td></tr>
          <tr><td><i>V</i><sub>global</sub></td><td>Vorz. Heizbeginn (Global, HK2-Kurvenversatz)</td></tr>
          <tr><td><i>f</i><sub>1</sub></td><td>Faktor Heizkurve (<code>faktor1HK2Kurve</code>)</td></tr>
          <tr><td><i>f</i><sub>2</sub></td><td>Heizbedarf-Faktor (<code>faktor2HeizBedarf</code>)</td></tr>
          <tr><td><i>T</i><sub>ist</sub></td><td>Aktuelle Raumtemperatur</td></tr>
          <tr><td><i>T</i><sub>at</sub></td><td>Aktuelle Au&szlig;entemperatur</td></tr>
          <tr><td><i>T</i><sub>G</sub></td><td>Abweichende Grundtemperatur (Raum)</td></tr>
          <tr><td><i>T</i><sub>W</sub></td><td>Wohlf&uuml;hltemperatur (Raum)</td></tr>
          <tr><td><i>T</i><sub>Mindest</sub></td><td>Mindest-Vorlauf (untere Grenze)</td></tr>
          <tr><td><i>M</i></td><td>Mittelpunkt zwischen T<sub>G</sub> und T<sub>W</sub>;<br>Knickpunkt der f<sub>2</sub>-Kurve</td></tr>
          <tr><td><i>K</i></td><td>Kurvenanpassung (<code>HK2-Kurvenanpassung</code>)</td></tr>
          <tr><td>HK2</td><td>Vorheizzeit aus Heizkurve</td></tr>
          </table>
        </fieldset>

        <fieldset id="hkr-fs-formeln">
          <legend>Formeln</legend>
          <math xmlns="http://www.w3.org/1998/Math/MathML" display="block" style="text-align:left">
            <mtable columnalign="right center left" rowspacing="1.2em">
              <mtr>
                <mtd><mtext>VLZ</mtext></mtd>
                <mtd><mo>=</mo></mtd>
                <mtd>
                  <mfenced open="(" close=")">
                    <mrow>
                      <msub><mi>V</mi><mtext>raum</mtext></msub>
                      <mo>+</mo>
                      <msub><mi>V</mi><mtext>global</mtext></msub>
                      <mo>+</mo>
                      <msub><mi>f</mi><mn>1</mn></msub>
                      <mo>&#x22C5;</mo>
                      <mtext>HK2</mtext>
                      <mo stretchy="false">(</mo><msub><mi>T</mi><mtext>at</mtext></msub><mo stretchy="false">)</mo>
                    </mrow>
                  </mfenced>
                  <mo>&#x22C5;</mo>
                  <msub><mi>f</mi><mn>2</mn></msub>
                  <mo stretchy="false">(</mo><msub><mi>T</mi><mtext>ist</mtext></msub><mo stretchy="false">)</mo>
                </mtd>
              </mtr>
              <mtr>
                <mtd><msub><mtext>VLZ</mtext><mtext>eff</mtext></msub></mtd>
                <mtd><mo>=</mo></mtd>
                <mtd>
                  <mo>max</mo>
                  <mo stretchy="false">(</mo>
                  <mtext>VLZ</mtext>
                  <mo>,</mo>
                  <msub><mi>T</mi><mi>Mindest</mi></msub>
                  <mo stretchy="false">)</mo>
                </mtd>
              </mtr>
            </mtable>
          </math>
          <math xmlns="http://www.w3.org/1998/Math/MathML" display="block" style="margin-top:1.2em; text-align:left">
            <mtable columnalign="right center left" rowspacing="1.4em">
              <mtr>
                <mtd><msub><mi>f</mi><mn>1</mn></msub></mtd>
                <mtd><mo>=</mo></mtd>
                <mtd><mtext>Faktor Heizkurve (raumspezifisch)</mtext></mtd>
              </mtr>
              <mtr>
                <mtd>
                  <msub><mi>f</mi><mn>2</mn></msub>
                  <mo stretchy="false">(</mo><msub><mi>T</mi><mtext>ist</mtext></msub><mo stretchy="false">)</mo>
                </mtd>
                <mtd><mo>=</mo></mtd>
                <mtd>
                  <mfenced open="&#x7B;" close="">
                    <mtable columnalign="left left" rowspacing="0.3em">
                      <mtr>
                        <mtd><mn>1</mn><mo>,</mo><mn>0</mn></mtd>
                        <mtd><mtext>wenn&#x00A0;</mtext><msub><mi>T</mi><mtext>ist</mtext></msub><mo>&#x2264;</mo><msub><mi>T</mi><mi>G</mi></msub></mtd>
                      </mtr>
                      <mtr>
                        <mtd>
                          <mn>1</mn><mo>-</mo><mi>K</mi><mo>&#x22C5;</mo>
                          <mfrac>
                            <mrow><msub><mi>T</mi><mtext>ist</mtext></msub><mo>-</mo><msub><mi>T</mi><mi>G</mi></msub></mrow>
                            <mrow><msub><mi>T</mi><mi>W</mi></msub><mo>-</mo><msub><mi>T</mi><mi>G</mi></msub></mrow>
                          </mfrac>
                        </mtd>
                        <mtd><mtext>wenn&#x00A0;</mtext><msub><mi>T</mi><mi>G</mi></msub><mo>&lt;</mo><msub><mi>T</mi><mtext>ist</mtext></msub><mo>&#x2264;</mo><mi>M</mi></mtd>
                      </mtr>
                      <mtr>
                        <mtd>
                          <mo stretchy="false">(</mo><mn>2</mn><mo>-</mo><mi>K</mi><mo stretchy="false">)</mo>
                          <mo>&#x22C5;</mo>
                          <mfenced open="(" close=")">
                            <mrow>
                              <mn>1</mn><mo>-</mo>
                              <mfrac>
                                <mrow><msub><mi>T</mi><mtext>ist</mtext></msub><mo>-</mo><msub><mi>T</mi><mi>G</mi></msub></mrow>
                                <mrow><msub><mi>T</mi><mi>W</mi></msub><mo>-</mo><msub><mi>T</mi><mi>G</mi></msub></mrow>
                              </mfrac>
                            </mrow>
                          </mfenced>
                        </mtd>
                        <mtd><mtext>wenn&#x00A0;</mtext><mi>M</mi><mo>&lt;</mo><msub><mi>T</mi><mtext>ist</mtext></msub><mo>&lt;</mo><msub><mi>T</mi><mi>W</mi></msub></mtd>
                      </mtr>
                      <mtr>
                        <mtd><mn>0</mn><mo>,</mo><mn>0</mn></mtd>
                        <mtd><mtext>wenn&#x00A0;</mtext><msub><mi>T</mi><mtext>ist</mtext></msub><mo>&#x2265;</mo><msub><mi>T</mi><mi>W</mi></msub></mtd>
                      </mtr>
                    </mtable>
                  </mfenced>
                </mtd>
              </mtr>
            </mtable>
          </math>
          <math xmlns="http://www.w3.org/1998/Math/MathML" display="block" style="margin-top:1.2em; text-align:left">
            <mtable columnalign="right center left" rowspacing="1.2em">
              <mtr>
                <mtd><mi>M</mi></mtd>
                <mtd><mo>=</mo></mtd>
                <mtd>
                  <msub><mi>T</mi><mi>G</mi></msub>
                  <mo>+</mo>
                  <mfrac>
                    <mrow><msub><mi>T</mi><mi>W</mi></msub><mo>&#x2212;</mo><msub><mi>T</mi><mi>G</mi></msub></mrow>
                    <mn>2</mn>
                  </mfrac>
                </mtd>
              </mtr>
              <mtr>
                <mtd>
                  <mtext>HK2</mtext><mo stretchy="false">(</mo><msub><mi>T</mi><mtext>at</mtext></msub><mo stretchy="false">)</mo>
                </mtd>
                <mtd><mo>=</mo></mtd>
                <mtd>
                  <msub><mi>k</mi><mi>i</mi></msub>
                  <mo>+</mo>
                  <mfrac>
                    <mrow><msub><mi>k</mi><mrow><mi>i</mi><mo>+</mo><mn>1</mn></mrow></msub><mo>&#x2212;</mo><msub><mi>k</mi><mi>i</mi></msub></mrow>
                    <mrow><msub><mi>a</mi><mrow><mi>i</mi><mo>+</mo><mn>1</mn></mrow></msub><mo>&#x2212;</mo><msub><mi>a</mi><mi>i</mi></msub></mrow>
                  </mfrac>
                  <mo>&#x22C5;</mo>
                  <mo stretchy="false">(</mo><msub><mi>T</mi><mtext>at</mtext></msub><mo>&#x2212;</mo><msub><mi>a</mi><mi>i</mi></msub><mo stretchy="false">)</mo>
                </mtd>
              </mtr>
            </mtable>
          </math>
        </fieldset>

      </div><!-- hkr-gruppe-ergebnis -->

      <!-- Gruppe Verlauf: Temperaturverlauf -->
      <div class="hkr-gruppe hkr-gruppe-verlauf" id="hkr-gruppe-verlauf" style="display:none">
        <fieldset id="hkr-fs-verlauf">
          <legend>Temperaturverlauf</legend>
          <canvas id="hkr-canvas-verlauf" width="1146" height="319"></canvas>
          <p class="hkr-canvas-legende">
            <span style="color:#cc2200;font-weight:bold">&#x2014;</span> Temperaturanstieg (Zwei-Geraden-Modell) &nbsp;&nbsp;
            <span style="color:#aaa">- -</span> Wohlf&uuml;hltemperatur T<sub>W</sub> &nbsp;&nbsp;
            <span style="color:#88b;font-weight:bold">&#x2014;</span> Grundtemperatur T<sub>G</sub> &nbsp;&nbsp;
            <span style="color:#cc2200">&#x25CF;</span> T<sub>ist</sub> Aktuelle Raumtemperatur
          </p>
        </fieldset>
      </div><!-- hkr-gruppe-verlauf -->

      <!-- Gruppe 2: Heizkurven-Verlauf (volle Breite) -->
      <div class="hkr-gruppe hkr-gruppe-kurve" id="hkr-gruppe-kurve" style="display:none">
        <fieldset id="hkr-fs-kurven">
          <legend>Heizkurven-Verlauf</legend>
          <canvas id="hkr-canvas-kurven" width="1146" height="399"></canvas>
          <p class="hkr-canvas-legende">
            <span style="color:#2e86c1">&#x25A0;</span> HK2-St&uuml;tzwerte &nbsp;&nbsp;
            <span style="color:#e67e22">&#x25A0;</span> <i>f</i><sub>1</sub> &middot; HK2-St&uuml;tzwerte &nbsp;&nbsp;
            <span class="hkr-cl-vhz" style="font-weight:bold">&#x2014;</span> HK2(T<sub>at</sub>) &nbsp;&nbsp;
            <span class="hkr-cl-at" style="font-weight:bold">&#x2014;</span> <i>f</i><sub>1</sub> &middot; HK2(T<sub>at</sub>) &nbsp;&nbsp;
            <span style="color:#cc2200;font-weight:bold">&#x2014;</span> VLZ<sub>eff</sub> = <i>f</i><sub>1</sub> &middot; <i>f</i><sub>2</sub> &middot; HK2(T<sub>at</sub>) &nbsp;&nbsp;
            <span style="color:#1a7a3a;font-weight:bold">- -</span> aktuelle AT
          </p>
        </fieldset>
      </div><!-- hkr-gruppe-kurve -->

    </div><!-- hkr-gruppen -->


  </div>

</div>
<script src="hkrechner.js"></script>
</body>
</html>}
