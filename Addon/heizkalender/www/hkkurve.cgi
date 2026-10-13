#!/bin/tclsh
# Heizkalender-Addon: Heizkurvenkontrolle-Auswertung
# Zielplattform: CCU3, Tcl 8.2.3

load tclrega.so

proc htmlquote {s} {
    return [string map {& &amp; < &lt; > &gt; \" &quot;} $s]
}

proc unique_sorted {lst} {
    set s [lsort $lst]
    set result {}
    set prev ""
    foreach x $s {
        if {![string equal $x $prev]} { lappend result $x; set prev $x }
    }
    return $result
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
    if {[string equal $ereignis "Heizbeginn"]} {
        set d 0
        catch {set d [expr {int($delta)}]}
        if {$d > 0} { return "hk-kurve-warn" }
        return "hk-kurve-heizbeginn"
    }
    if {[string equal $ereignis "Terminbeginn"]}   { return "hk-kurve-terminbeginn" }
    if {[string equal $ereignis "Zieltemperatur"]} { return "hk-kurve-ziel" }
    if {[string equal $ereignis "Terminende"]}     { return "hk-kurve-terminende" }
    if {[string equal $ereignis "Heizende"]}       { return "hk-kurve-heizende" }
    return ""
}

proc ascii_key {s} {
    regsub -all {[^ -~]} $s {} r
    return $r
}

# ---------------------------------------------------------------------------
# Query-Parameter
# ---------------------------------------------------------------------------
set filter_raum "alle"
set filter_tage "1"
set filter_ereignis "alle"
set submitted 0

set query_string ""
catch {set query_string $env(QUERY_STRING)}

foreach param [split $query_string "&"] {
    set eqpos [string first "=" $param]
    if {$eqpos < 0} { continue }
    set key [string range $param 0 [expr {$eqpos-1}]]
    set val [string range $param [expr {$eqpos+1}] end]
    set val [string map {+ { }} $val]
    regsub -all {%([0-9A-Fa-f]{2})} $val {[format %c 0x\1]} val
    set val [subst -nocommands -novariables $val]
    if {[string equal $key "raum"]} { set filter_raum [ascii_key $val] }
    if {[string equal $key "ereignis"]} { set filter_ereignis $val }
    if {[string equal $key "tage"]} {
        if {[string equal $val "1"] || [string equal $val "7"] || [string equal $val "30"] || [string equal $val "90"]} {
            set filter_tage $val
        }
    }
    if {[string equal $key "submitted"] && [string equal $val "1"]} { set submitted 1 }
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
# value im Dropdown = ASCII-bereinigter Raumname (ohne Sonderzeichen, URL-sicher)
# Anzeige im Dropdown = Originalname mit Umlauten aus HK1-R-Liste
# ---------------------------------------------------------------------------
set r_liste_raw [extract_stdout [rega_script {
    var sv = dom.GetObject("HK1-R-Liste");
    if (sv) { WriteLine(sv.Value()); } else { WriteLine(""); }
}]]

# alle_raeume_komplett: Liste von {ascii_key anzeige_name}, nach Anzeigename sortiert
# log_name_map: ASCII-Key -> Originalname mit Umlauten (für Tabellenanzeige)
set alle_raeume_komplett {}
array set log_name_map {}
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
    set akey [ascii_key $anzeige]
    lappend alle_raeume_komplett [list $akey $anzeige]
    set log_name_map($akey) $anzeige
}
set alle_raeume_komplett [lsort -index 1 $alle_raeume_komplett]

# ---------------------------------------------------------------------------
# Raumliste aus Log-Dateien ergänzen (Gruppenräume tauchen nur im Log auf)
# ---------------------------------------------------------------------------
set alle_raeume_log_keys {}
if {[llength $log_files] > 0} {
    set fpaths {}
    foreach lf $log_files { lappend fpaths "$usb_dir/$lf" }
    catch {
        set grep_out [eval exec grep -h [list $hkk_src] $fpaths]
        foreach line [split $grep_out "\n"] {
            set line [string trim $line]
            set parts [split $line "\t"]
            if {[llength $parts] < 3} { continue }
            set msg [join [lrange $parts 2 end] "\t"]
            set sp [string first " " $msg]
            set dp [string first ":" $msg]
            set rn ""
            if {$sp > 0 && ($dp < 0 || $sp < $dp)} {
                set rn [string range $msg 0 [expr {$sp-1}]]
            } elseif {$dp > 0} {
                set rn [string range $msg 0 [expr {$dp-1}]]
            }
            set pidx [string first "(" $rn]
            if {$pidx > 0} { set rn [string range $rn 0 [expr {$pidx-1}]] }
            set rn [string trim $rn]
            if {![string equal $rn ""]} { lappend alle_raeume_log_keys [ascii_key $rn] }
        }
    }
}
# Log-Räume ergänzen, die noch nicht in alle_raeume_komplett sind
set vorhandene_keys {}
foreach pair $alle_raeume_komplett { lappend vorhandene_keys [lindex $pair 0] }
foreach rn [unique_sorted $alle_raeume_log_keys] {
    if {[lsearch -exact $vorhandene_keys $rn] < 0} {
        lappend alle_raeume_komplett [list $rn $rn]
    }
}
set alle_raeume_komplett [lsort -index 1 $alle_raeume_komplett]

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

        set pidx [string first "(" $raumname]
        if {$pidx > 0} {
            set cidx [string first ")" $raumname $pidx]
            if {$cidx > 0} {
                set raumname [string range $raumname 0 [expr {$pidx-1}]][string range $raumname [expr {$cidx+1}] end]
            } else {
                set raumname [string range $raumname 0 [expr {$pidx-1}]]
            }
        }
        set raumname [string trim $raumname]
        if {[string equal $raumname ""]} { continue }

        if {![string equal $filter_raum "alle"]} {
            set rn_key [ascii_key $raumname]
            if {![string equal $rn_key $filter_raum] && \
                ![string equal [string range $rn_key 0 [expr {[string length $filter_raum]-1}]] $filter_raum]} { continue }
        }
        if {![string equal $filter_ereignis "alle"] && ![string equal $ereignis $filter_ereignis]} { continue }

        lappend alle_ereignisse [list $raumname $ts $ereignis $delta $ist $ziel $at_max $at_max_typ]
    }
}

set alle_ereignisse [lsort -index 1 $alle_ereignisse]

# ---------------------------------------------------------------------------
# HTML
# ---------------------------------------------------------------------------
puts "Content-Type: text/html; charset=iso-8859-1\nContent-Language: de\n"
puts {<!DOCTYPE html>
<html lang="de">
<head>
  <meta charset="iso-8859-1">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Heizkalender: Heizkurvenkontrolle</title>
  <link rel="stylesheet" href="heizkalender.css">
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
    <a href="hklog.cgi">HK-Log</a>
    <a href="syslog.cgi">Systemlog</a>
    <a href="sysvars.cgi">Systemvariablen</a>
    <a href="hkconfig.cgi">Einstellungen</a>
  </nav>}

puts {  <div class="hk-log-controls">}
puts "    <form method=\"get\" action=\"hkkurve.cgi\">"
puts "      <input type=\"hidden\" name=\"submitted\" value=\"1\">"
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
foreach pair $alle_raeume_komplett {
    set logkey  [lindex $pair 0]
    set anzeige [lindex $pair 1]
    set sel [expr {[string equal $logkey $filter_raum] ? " selected" : ""}]
    puts "          <option value=\"[htmlquote $logkey]\"${sel}>[htmlquote $anzeige]</option>"
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

        # Indikator: grüner/roter Kreis in der Ereignis-Spalte
        set indikator ""
        if {[string equal $ereignis "Zieltemperatur"] && ![string equal $delta ""]} {
            set d 0
            catch {set d [expr {int($delta)}]}
            if {$d <= 0} {
                set indikator { <span class="hk-ind-ok">&#9650;</span>}
            } else {
                set indikator { <span class="hk-ind-err">&#9660;</span>}
            }
        }
        if {[string equal $ereignis "Terminbeginn"] && ![string equal $ist ""] && ![string equal $ziel ""]} {
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
        set raumanzeige [expr {[info exists log_name_map($raumname)] ? $log_name_map($raumname) : $raumname}]
        puts "      <td>[htmlquote $raumanzeige]</td>"
        puts "      <td>[htmlquote $ts]</td>"
        puts "      <td>[htmlquote $ereignis]</td>"
        puts "      <td>[htmlquote $delta_str]</td>"
        puts "      <td>${ist_str}${indikator}</td>"
        puts "      <td>${ziel_str}</td>"
        puts "      <td>${at_str}</td>"
        puts "    </tr>"
    }
    puts {  </table></div>}
    puts {  <p class="hk-hint"><strong>&Delta; min (Terminbeginn):</strong> Minuten relativ zum Terminbeginn: negativ = vor Terminbeginn, positiv = nach Terminbeginn.<br>Beispiel: Heizende +90min bedeutet, die Heizung schaltete 90 Minuten nach Terminbeginn ab (nicht die Termindauer, da VorzeitAus abgezogen wird).</p>}
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
