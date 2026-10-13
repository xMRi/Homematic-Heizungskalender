#!/bin/tclsh
# Heizkalender-Addon: Systemlog-Anzeige (letzte N Zeilen)
# Zielplattform: CCU3, Tcl 8.2.3

proc htmlquote {s} {
    set s [string map {& &amp; < &lt; > &gt; \" &quot;} $s]
    return $s
}

# ---------------------------------------------------------------------------
# Query-Parameter auslesen (GET)
# ---------------------------------------------------------------------------
set lines_to_show 50
set filter_hk 0

set query_string ""
catch {set query_string $env(QUERY_STRING)}

foreach param [split $query_string "&"] {
    set eqpos [string first "=" $param]
    if {$eqpos < 0} { continue }
    set key [string range $param 0 [expr {$eqpos-1}]]
    set val [string range $param [expr {$eqpos+1}] end]
    if {[string equal $key "n"]} {
        set n 0
        catch {set n [expr {int($val)}]}
        if {$n > 0 && $n <= 2000} { set lines_to_show $n }
    }
    if {[string equal $key "filter"] && [string equal $val "hk"]} {
        set filter_hk 1
    }
}

# ---------------------------------------------------------------------------
# Log-Datei einlesen
# ---------------------------------------------------------------------------
set logfile "/var/log/messages"
set all_lines {}

if {[file exists $logfile]} {
    set fh [open $logfile r]
    while {[gets $fh line] >= 0} {
        lappend all_lines $line
    }
    close $fh
}

# Letzte N Zeilen
set total [llength $all_lines]
set start [expr {$total - $lines_to_show}]
if {$start < 0} { set start 0 }
set tail_lines [lrange $all_lines $start end]

# Optional: nur HK-relevante Zeilen
if {$filter_hk} {
    set filtered {}
    foreach line $tail_lines {
        if {[string match "*HK-*" $line] || [string match "*HK1-*" $line] ||
            [string match "*HK2-*" $line] || [string match "*HKG-*" $line] ||
            [string match "*Heizkalender*" $line] || [string match "*heizkalender*" $line] ||
            [string match "*Heizung*" $line]} {
            lappend filtered $line
        }
    }
    set tail_lines $filtered
}

# ---------------------------------------------------------------------------
# HTML ausgeben
# ---------------------------------------------------------------------------
puts "Content-Type: text/html; charset=iso-8859-1\nContent-Language: de\n"

set filter_label "Alle Eintr&auml;ge"
if {$filter_hk} { set filter_label "Nur Heizkalender" }

puts "<!DOCTYPE html>"
puts {<html lang="de">
<head>
  <meta charset="iso-8859-1">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Heizkalender: Systemlog</title>
  <link rel="stylesheet" href="heizkalender.css">
  <link rel="apple-touch-icon" sizes="180x180" href="apple-touch-icon.png">
  <link rel="icon" type="image/png" sizes="32x32" href="favicon-32x32.png">
  <link rel="icon" type="image/png" sizes="16x16" href="favicon-16x16.png">
  <link rel="manifest" href="site.webmanifest">
</head>
<body>
<div id="content">}

puts {  <div class="hk-header">
    <img src="hk-logo-300.png" height="64" alt="Heizkalender-Logo" class="hk-header-logo">
    <h1>Heizkalender: Systemlog</h1>
  </div>}
puts {  <nav class="hk-nav">
    <a href="index.cgi">Raum&uuml;bersicht</a>
    <a href="hkkurve.cgi">Heizkurve</a>
    <a href="hklog.cgi">HK-Log</a>
    <a href="syslog.cgi">Systemlog</a>
    <a href="sysvars.cgi">Systemvariablen</a>
    <a href="hkconfig.cgi">Einstellungen</a>
  </nav>}

puts "  <div class=\"hk-log-controls\">"
puts "    <form method=\"get\" action=\"syslog.cgi\">"
puts {      <fieldset>}
puts {        <legend>Filter</legend>}
puts "        <label>Zeilen: <select name=\"n\">"
foreach opt {50 100 200 500} {
    if {$opt == $lines_to_show} {
        puts "          <option value=\"$opt\" selected>$opt</option>"
    } else {
        puts "          <option value=\"$opt\">$opt</option>"
    }
}
puts "        </select></label>"
puts "        &nbsp;"
if {$filter_hk} {
    puts "        <label><input type=\"checkbox\" name=\"filter\" value=\"hk\" checked> Nur Heizkalender-Eintr&auml;ge</label>"
} else {
    puts "        <label><input type=\"checkbox\" name=\"filter\" value=\"hk\"> Nur Heizkalender-Eintr&auml;ge</label>"
}
puts "        &nbsp;"
puts "        <button type=\"submit\">Aktualisieren</button>"
puts {      </fieldset>}
puts "    </form>"
puts "  </div>"

set count [llength $tail_lines]
puts "  <p class=\"hk-log-info\">$count Eintr&auml;ge ($filter_label, letzte $lines_to_show Zeilen von $total gelesen)</p>"

if {$count == 0} {
    puts "  <p class=\"hk-empty\">Keine Eintr&auml;ge gefunden.</p>"
} else {
    puts "  <div class=\"hk-table-scroll\">"
    puts "    <table class=\"hk-table hk-log-table\">"
    puts "      <colgroup><col class=\"col-log-ts\"><col class=\"col-log-src\"><col class=\"col-log-msg\"></colgroup>"
    puts "      <tr><th>Zeitstempel</th><th>Quelle</th><th>Meldung</th></tr>"
    foreach line $tail_lines {
        set uline $line
        # Format: "Mmm DD HH:MM:SS hostname facility.level process[pid]: message"
        # oder einfacher: alles bis zum 4. Leerzeichen = Zeitstempel+Host, danach Quelle+Meldung
        # Wir teilen auf: erste 3 Felder = Datum+Zeit, 4. = Host, 5. = facility.prio, rest = Meldung
        set parts [split $uline " "]
        set nparts [llength $parts]
        if {$nparts >= 6} {
            # "Oct  4 23:33:33" — bei einstelligem Tag steht ein Leerzeichen extra
            set mon  [lindex $parts 0]
            set day  [lindex $parts 1]
            set time [lindex $parts 2]
            # Tag kann leer sein (doppeltes Leerzeichen -> leeres Element)
            if {[string equal $day ""]} {
                set day  [lindex $parts 2]
                set time [lindex $parts 3]
                set src  [lindex $parts 5]
                set msg  [join [lrange $parts 6 end] " "]
            } else {
                set src  [lindex $parts 4]
                set msg  [join [lrange $parts 5 end] " "]
            }
            set ts "$mon $day $time"
        } else {
            set ts  ""
            set src ""
            set msg $uline
        }
        # Zeilenklasse für HK-Einträge
        set rowclass ""
        if {[string match "*HK-*" $msg] || [string match "*HK1-*" $msg] ||
            [string match "*HK2-*" $msg] || [string match "*HKG-*" $msg] ||
            [string match "*Heizkalender*" $msg] || [string match "*heizkalender*" $msg]} {
            set rowclass " class=\"hk-log-hk\""
        }
        puts "      <tr${rowclass}><td>[htmlquote $ts]</td><td>[htmlquote $src]</td><td>[htmlquote $msg]</td></tr>"
    }
    puts "    </table>"
    puts "  </div>"
}

puts {</div>
</body>
</html>}
