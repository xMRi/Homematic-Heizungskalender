#!/bin/tclsh
# Heizkalender-Addon: Heizkurvenkontrolle-Auswertung
# Zielplattform: CCU3, Tcl 8.2.3

load tclrega.so

proc htmlquote {s} {
    return [string map {& &amp; < &lt; > &gt; \" &quot;} $s]
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

proc ereignis_class {ereignis delta} {
    if {[string equal $ereignis "Fehler"]}         { return "hk-kurve-fehler" }
    if {[string equal $ereignis "Heizbeginn"]} { return "hk-kurve-heizbeginn" }
    if {[string equal $ereignis "Terminbeginn"]}   { return "hk-kurve-terminbeginn" }
    if {[string equal $ereignis "Zieltemperatur"]} { return "hk-kurve-ziel" }
    if {[string equal $ereignis "Terminende"]}     { return "hk-kurve-terminende" }
    if {[string equal $ereignis "Heizende"]}       { return "hk-kurve-heizende" }
    return ""
}

proc url_decode {s} {
    # Umlaute werden entfernt statt dekodiert. Grund: exec-Strings (Log-Daten
    # via grep) und Skript-Literale (\xfc) haben in Tcl 8.2 unterschiedliche
    # interne Repräsentationen, obwohl binary scan dasselbe Byte zeigt.
    # string first schlägt dann fehl. Lösung: Beide Seiten (filter_raum und
    # raumname) auf ASCII normalisieren via to_ascii; Vergleich ist dann
    # encoding-neutral.
    set s [string map {+ { }} $s]
    set s [string map {%FC {} %fc {} %E4 {} %e4 {} %F6 {} %f6 {}
                       %DC {} %dc {} %C4 {} %c4 {} %D6 {} %d6 {}
                       %DF {} %df {}} $s]
    regsub -all {%[0-9A-Fa-f]{2}} $s {} s
    return $s
}

proc to_ascii {s} {
    # Gegenstück zu url_decode: entfernt Non-ASCII aus exec-Strings damit
    # string first mit url_decode-Ergebnissen funktioniert.
    regsub -all {[^\x00-\x7f]} $s {} r
    return $r
}

# ---------------------------------------------------------------------------
# Query-Parameter
# ---------------------------------------------------------------------------
set filter_raum "alle"
set filter_tage "1"
set filter_ereignis "alle"
set submitted 1

set query_string ""
catch {set query_string $env(QUERY_STRING)}

foreach param [split $query_string "&"] {
    set eqpos [string first "=" $param]
    if {$eqpos < 0} { continue }
    set key [string range $param 0 [expr {$eqpos-1}]]
    set val [string range $param [expr {$eqpos+1}] end]
    set val [url_decode $val]
    if {[string equal $key "raum"]} { set filter_raum $val }
    if {[string equal $key "ereignis"]} { set filter_ereignis $val }
    if {[string equal $key "tage"]} {
        if {[string equal $val "1"] || [string equal $val "7"] || [string equal $val "30"] || [string equal $val "90"]} {
            set filter_tage $val
        }
    }
}

# ---------------------------------------------------------------------------
# Datums-Untergrenze
# ---------------------------------------------------------------------------
# Bei tage=1 ("Heute"): ab Mitternacht des heutigen Tages, nicht "jetzt minus 24h"
if {[string equal $filter_tage "1"]} {
    set datum_ab [clock format [clock seconds] -format "%Y-%m-%d"]
} else {
    set tage_secs [expr {int($filter_tage) * 86400}]
    set datum_ab [clock format [expr {[clock seconds] - $tage_secs}] -format "%Y-%m-%d"]
}

# ---------------------------------------------------------------------------
# USB-Stick: alle Log-Dateien im Zeitraum (neueste zuerst)
# ---------------------------------------------------------------------------
# Datei einschließen wenn Dateiname >= datum_ab minus 7 Tage. Wochendateien
# (Dateiname = Startdatum der Woche) können bis zu 7 Tage jüngere Einträge
# enthalten als der Dateiname andeutet. Die Zeilenebene filtert dann genau.
set usb_dir "/media/usb1"
set log_files {}
if {[file isdirectory $usb_dir]} {
    set datei_filter_ab [clock format [expr {[clock seconds] - ($filter_tage + 7) * 86400}] -format "%Y-%m-%d"]
    foreach f [lsort -decreasing [glob -nocomplain "$usb_dir/HK-Log_*.log"]] {
        set fname [file tail $f]
        set fdate [string range $fname 7 16]
        if {$fdate >= $datei_filter_ab} {
            lappend log_files $fname
        }
    }
}

set hkk_src "HK-LogHeizkurvenkontrolle"

# ---------------------------------------------------------------------------
# Raumliste aus HK1-R-Liste via ReGa
# value und Anzeige im Dropdown = Originalname (mit Umlauten, URL-kodiert übergeben)
# ---------------------------------------------------------------------------
set r_liste_raw [extract_stdout [rega_script {
    var sv = dom.GetObject("HK1-R-Liste");
    if (sv) { WriteLine(sv.Value()); } else { WriteLine(""); }
}]]

# alle_raeume: Liste von {name name} aus HK1-R-Liste, nach Name sortiert
set alle_raeume {}
foreach entry [split $r_liste_raw ";"] {
    set entry [string trim $entry]
    if {[string equal $entry ""]} { continue }
    set eqpos [string first "=" $entry]
    if {$eqpos >= 0} {
        set anzeige [string trim [string range $entry [expr {$eqpos+1}] end]]
    } else {
        set anzeige [string trim $entry]
    }
    if {[string equal $anzeige ""]} { continue }
    lappend alle_raeume [list $anzeige $anzeige]
}
set alle_raeume [lsort -index 1 $alle_raeume]

# ---------------------------------------------------------------------------
# Ereignisse einlesen (nur nach Submit, via grep)
# ---------------------------------------------------------------------------
set alle_ereignisse {}

if {$submitted && [llength $log_files] > 0} {
    # grep liefert nur die relevanten Zeilen; das spart 99% der Laufzeit
    set fpaths {}
    foreach lf $log_files { lappend fpaths "$usb_dir/$lf" }
    set grep_lines {}
    catch {
        set grep_out [eval exec grep -h [list $hkk_src] $fpaths]
        set grep_lines [split $grep_out "\n"]
    }

    foreach line $grep_lines {
        set line [string trim $line]
        set parts [split $line "\t"]
        if {[llength $parts] < 3} { continue }
        set ts   [lindex $parts 0]
        set qsrc [lindex $parts 1]
        if {![string equal $qsrc $hkk_src]} { continue }
        set msg  [join [lrange $parts 2 end] "\t"]

        # Datum-Feinfilter
        set datum [string range $ts 0 9]
        if {![string equal $datum_ab ""] && $datum < $datum_ab} { continue }

        set raumname   ""
        set ereignis   ""
        set delta      ""
        set ist        ""
        set ziel       ""
        set at_max     ""
        set at_max_typ ""

        set sp [string first " " $msg]
        set dp [string first ":" $msg]

        if {$sp > 0 && ($dp < 0 || $sp < $dp)} {
            set raumname [string range $msg 0 [expr {$sp-1}]]
            set rest     [string range $msg [expr {$sp+1}] end]
            set cdp [string first ":" $rest]
            if {$cdp > 0} {
                set ereignis [string trim [string range $rest 0 [expr {$cdp-1}]]]
                set detail   [string trim [string range $rest [expr {$cdp+1}] end]]
                set c1 [string first "," $detail]
                if {$c1 > 0} {
                    set delta [string trim [string range $detail 0 [expr {$c1-1}]]]
                    set rest2 [string trim [string range $detail [expr {$c1+1}] end]]
                    set ip [string first "Ist:" $rest2]
                    if {$ip >= 0} {
                        set after [string trim [string range $rest2 [expr {$ip+4}] end]]
                        set sp2 [string first " " $after]
                        if {$sp2 > 0} { set ist [string range $after 0 [expr {$sp2-1}]] } else { set ist $after }
                        set ist [string trimright $ist ","]
                    }
                    set zp [string first "Ziel:" $rest2]
                    if {$zp >= 0} {
                        set after [string trim [string range $rest2 [expr {$zp+5}] end]]
                        set c2 [string first "," $after]
                        if {$c2 > 0} { set ziel [string range $after 0 [expr {$c2-1}]] } else { set ziel $after }
                    }
                    set ap [string first "AT:" $rest2]
                    if {$ap >= 0} {
                        set at_max_typ "AT"
                        set after [string trim [string range $rest2 [expr {$ap+3}] end]]
                        set sp3 [string first " " $after]
                        if {$sp3 > 0} { set at_max [string range $after 0 [expr {$sp3-1}]] } else { set at_max $after }
                    } else {
                        set mp [string first "Max.:" $rest2]
                        if {$mp >= 0} {
                            set at_max_typ "Max"
                            set after [string trim [string range $rest2 [expr {$mp+5}] end]]
                            set sp4 [string first " " $after]
                            if {$sp4 > 0} { set at_max [string range $after 0 [expr {$sp4-1}]] } else { set at_max $after }
                        }
                    }
                }
            }
        } elseif {$dp > 0} {
            set raumname [string range $msg 0 [expr {$dp-1}]]
            set ereignis "Fehler"
            set delta    [string trim [string range $msg [expr {$dp+1}] end]]
        } else {
            continue
        }

        set raumname [string trim $raumname]
        if {[string equal $raumname ""]} { continue }

        if {![string equal $filter_raum "alle"]} {
            if {[string first $filter_raum [to_ascii $raumname]] < 0} { continue }
        }
        if {![string equal $filter_ereignis "alle"] && ![string equal $ereignis $filter_ereignis]} { continue }

        lappend alle_ereignisse [list $raumname $ts $ereignis $delta $ist $ziel $at_max $at_max_typ]
    }
}

set alle_ereignisse [lsort -index 1 $alle_ereignisse]

# ---------------------------------------------------------------------------
# HTML
# ---------------------------------------------------------------------------
set hk_version "?"
catch {
    set vfh [open "/usr/local/addons/heizkalender/VERSION" r]
    gets $vfh hk_version
    close $vfh
    set hk_version [string trim $hk_version]
}
puts "Content-Type: text/html; charset=iso-8859-1\nContent-Language: de\n"
puts {<!DOCTYPE html>
<html lang="de">
<head>
  <meta charset="iso-8859-1">
  <meta name="viewport" content="width=device-width, initial-scale=1">}
puts "  <title>Heizkalender ${hk_version}: Heizkurvenkontrolle</title>"
puts {  <link rel="stylesheet" href="heizkalender.css">
  <link rel="apple-touch-icon" sizes="180x180" href="apple-touch-icon.png">
  <link rel="icon" type="image/png" sizes="32x32" href="favicon-32x32.png">
  <link rel="icon" type="image/png" sizes="16x16" href="favicon-16x16.png">
  <link rel="manifest" href="site.webmanifest">
</head>
<body>
<div id="content">
  <div class="hk-header">
    <img src="hk-logo-300.png" height="64" alt="Heizkalender-Logo" class="hk-header-logo">
    <h1>Heizkalender: Heizkurvenkontrolle</h1>
  </div>
  <nav class="hk-nav">
    <a href="index.cgi">Raum&uuml;bersicht</a>
    <a href="hkkurve.cgi">Heizkurve</a>
    <a href="hkconfig.cgi">Einstellungen</a>
    <a href="hklog.cgi">HK-Log</a>
    <a href="syslog.cgi">Systemlog</a>
    <a href="sysvars.cgi">Systemvariablen</a>
  </nav>}

puts {  <div class="hk-log-controls">}
puts "    <form method=\"get\" action=\"hkkurve.cgi\">"
puts {      <fieldset>}
puts {        <legend>Filter</legend>}
puts "        <label>Zeitraum: <select name=\"tage\">"
foreach {tval tlabel} {1 "Heute" 7 "Letzte 7 Tage" 30 "Letzte 30 Tage" 90 "Letzte 90 Tage"} {
    set sel [expr {[string equal $tval $filter_tage] ? " selected" : ""}]
    puts "          <option value=\"$tval\"${sel}>$tlabel</option>"
}
puts "        </select></label> &nbsp;"
puts "        <label>Raum: <select name=\"raum\">"
set sel [expr {[string equal $filter_raum "alle"] ? " selected" : ""}]
puts "          <option value=\"alle\"${sel}>Alle R&auml;ume</option>"
foreach pair $alle_raeume {
    set name [lindex $pair 0]
    set sel [expr {[string equal [to_ascii $name] $filter_raum] ? " selected" : ""}]
    puts "          <option value=\"[htmlquote $name]\"${sel}>[htmlquote $name]</option>"
}
puts "        </select></label> &nbsp;"
puts "        <label>Ereignis: <select name=\"ereignis\">"
foreach {eval elabel} {
    alle        "Alle Ereignisse"
    Heizbeginn  "Heizbeginn"
    Terminbeginn "Terminbeginn"
    Zieltemperatur "Zieltemperatur"
    Heizende    "Heizende"
    Terminende  "Terminende"
    Fehler      "Fehler"
} {
    set sel [expr {[string equal $eval $filter_ereignis] ? " selected" : ""}]
    puts "          <option value=\"[htmlquote $eval]\"${sel}>[htmlquote $elabel]</option>"
}
puts "        </select></label> &nbsp;"
puts "        <button type=\"submit\">Anzeigen</button>"
puts {      </fieldset>}
puts "    </form>"
puts {  </div>}

if {$submitted} {

if {[llength $log_files] == 0} {
    puts {  <p class="hk-empty">Kein USB-Stick gefunden oder keine HK-Log-Dateien vorhanden.</p>}
} elseif {[llength $alle_ereignisse] == 0} {
    puts {  <p class="hk-empty">Keine Eintr&auml;ge f&uuml;r den gew&auml;hlten Zeitraum.</p>}
} else {
    set deg "&deg;"
    set n_dateien [llength $log_files]
    puts "  <p class=\"hk-log-info\">[llength $alle_ereignisse] Eintr&auml;ge aus $n_dateien Datei(en) im gew&auml;hlten Zeitraum</p>"
    puts {  <div class="hk-table-scroll"><table class="hk-table hk-kurve-table">}
    puts {    <colgroup>
      <col class="col-kurve-raum">
      <col class="col-kurve-ts">
      <col class="col-kurve-ereignis">
      <col class="col-kurve-delta">
      <col class="col-kurve-ist">
      <col class="col-kurve-ziel">
      <col class="col-kurve-at">
    </colgroup>}
    puts {    <tr><th>Raum</th><th>Zeitpunkt</th><th>Ereignis</th><th>&Delta; min (Terminbeginn)</th><th>Ist-Temperatur</th><th>Ziel-Temperatur</th><th>Au&szlig;entemp. / Max.-Temperatur</th></tr>}

    foreach ev $alle_ereignisse {
        set raumname   [lindex $ev 0]
        set ts         [lindex $ev 1]
        set ereignis   [lindex $ev 2]
        set delta      [lindex $ev 3]
        set ist        [lindex $ev 4]
        set ziel       [lindex $ev 5]
        set at_max     [lindex $ev 6]
        set at_max_typ [lindex $ev 7]

        set eclass [ereignis_class $ereignis $delta]
        set rowcls [expr {![string equal $eclass ""] ? " class=\"$eclass\"" : ""}]

        set ist_str  [expr {![string equal $ist  ""] ? "$ist ${deg}C" : ""}]
        set ziel_str [expr {![string equal $ziel ""] ? "$ziel ${deg}C" : ""}]
        set at_str   [expr {![string equal $at_max ""] ? "$at_max ${deg}C ($at_max_typ)" : ""}]
        set delta_str $delta
        if {[string equal $ereignis "Fehler"]} {
            set delta_str ""
            set at_str    $delta
        }

        # Indikator: Dreieck in der Ist-Temperatur-Spalte
        set indikator ""
        if {([string equal $ereignis "Terminbeginn"] || [string equal $ereignis "Terminende"]) \
                && ![string equal $ist ""] && ![string equal $ziel ""]} {
            set ist_num  0
            set ziel_num 0
            catch {set ist_num  [expr {double($ist)}]}
            catch {set ziel_num [expr {double($ziel)}]}
            if {$ist_num < $ziel_num} {
                set indikator { <span class="hk-ind-err">&#9660;</span>}
            } else {
                set indikator { <span class="hk-ind-ok">&#9650;</span>}
            }
        }

        puts "    <tr${rowcls}>"
        puts "      <td>[htmlquote $raumname]</td>"
        puts "      <td>[htmlquote $ts]</td>"
        puts "      <td>[htmlquote $ereignis]</td>"
        puts "      <td>[htmlquote $delta_str]</td>"
        puts "      <td>${ist_str}${indikator}</td>"
        puts "      <td>${ziel_str}</td>"
        puts "      <td>${at_str}</td>"
        puts "    </tr>"
    }
    puts {  </table></div>}
    puts {  <p class="hk-hint"><strong>&Delta; min (Terminbeginn):</strong> Minuten relativ zum Terminbeginn: negativ = p&uuml;nktlich (vor Terminbeginn), positiv = versp&auml;tet (nach Terminbeginn).<br>Beispiel: Terminbeginn -15min bedeutet, der Raum war 15 Minuten vor dem Termin auf Temperatur.<br>Beispiel: Heizende +90min bedeutet, die Heizung schaltete 90 Minuten nach Terminbeginn ab (nicht die Termindauer, da VorzeitAus abgezogen wird).</p>}
    puts {  <fieldset class="hk-legende-fieldset">}
    puts {    <legend>Legende</legend>}
    puts {    <p class="hk-sl-legende">
      <span class="hk-kurve-heizbeginn hk-kurve-badge">Heizbeginn</span>
      <span class="hk-kurve-terminbeginn hk-kurve-badge">Terminbeginn</span>
      <span class="hk-kurve-ziel hk-kurve-badge">Zieltemperatur</span>
      <span class="hk-kurve-terminende hk-kurve-badge">Terminende</span>
      <span class="hk-kurve-heizende hk-kurve-badge">Heizende</span>
      <span class="hk-kurve-fehler hk-kurve-badge">Fehler</span>
    </p>}
    puts {  </fieldset>}
}
}

puts {</div>
</body>
</html>}
