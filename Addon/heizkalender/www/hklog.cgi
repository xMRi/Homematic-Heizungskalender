#!/bin/tclsh
# Heizkalender-Addon: HK-Log-Anzeige
# Zielplattform: CCU3, Tcl 8.2.3

proc htmlquote {s} {
    set s [string map {& &amp; < &lt; > &gt; \" &quot;} $s]
    return $s
}

# ---------------------------------------------------------------------------
# Query-Parameter
# ---------------------------------------------------------------------------
set file_param ""
set lines_to_show 50
set filter "alle"

set query_string ""
catch {set query_string $env(QUERY_STRING)}

foreach param [split $query_string "&"] {
    set eqpos [string first "=" $param]
    if {$eqpos < 0} { continue }
    set key [string range $param 0 [expr {$eqpos-1}]]
    set val [string range $param [expr {$eqpos+1}] end]
    if {[string equal $key "file"]} {
        set basename [file tail $val]
        set pat "HK-Log_*.log"
        if {[string match $pat $basename]} {
            set file_param $basename
        }
    }
    if {[string equal $key "n"]} {
        set n 0
        catch {set n [expr {int($val)}]}
        if {$n > 0 && $n <= 5000} { set lines_to_show $n }
    }
    if {[string equal $key "filter"]} {
        if {[string equal $val "hk1"]}   { set filter "hk1" }
        if {[string equal $val "hk2"]}   { set filter "hk2" }
        if {[string equal $val "hkl"]}   { set filter "hkl" }
        if {[string equal $val "hkk"]}   { set filter "hkk" }
        if {[string equal $val "nacht"]} { set filter "nacht" }
    }
}

# ---------------------------------------------------------------------------
# USB-Stick: verfügbare Log-Dateien (neueste zuerst, max. 30 Tage)
# ---------------------------------------------------------------------------
set usb_dir "/media/usb1"
set log_files {}
if {[file isdirectory $usb_dir]} {
    set cutoff_secs [expr {[clock seconds] - 60 * 86400}]
    set cutoff_date [clock format $cutoff_secs -format "%Y-%m-%d"]
    foreach f [lsort -decreasing [glob -nocomplain "$usb_dir/HK-Log_*.log"]] {
        set fname [file tail $f]
        # Datum aus Dateiname extrahieren: HK-Log_YYYY-MM-DD.log
        set fdate [string range $fname 7 16]
        if {$fdate >= $cutoff_date} {
            lappend log_files $fname
        }
    }
}

# ---------------------------------------------------------------------------
# Inhalt laden (nur USB-Stick)
# ---------------------------------------------------------------------------
set log_lines {}
set source_label ""

set has_file_param 0
if {![string equal $file_param ""]} { set has_file_param 1 }

if {!$has_file_param && [llength $log_files] > 0} {
    set file_param [lindex $log_files 0]
    set has_file_param 1
}

if {$has_file_param} {
    set fpath "$usb_dir/$file_param"
    set source_label "USB-Stick: $file_param"
    if {[file exists $fpath]} {
        set fh [open $fpath r]
        set all {}
        while {[gets $fh line] >= 0} {
            lappend all $line
        }
        close $fh
        if {[string equal $filter "nacht"]} {
            set log_lines $all
        } else {
            set total [llength $all]
            set start [expr {$total - $lines_to_show}]
            if {$start < 0} { set start 0 }
            set log_lines [lrange $all $start end]
        }
    }
}

# ---------------------------------------------------------------------------
# Filter anwenden
# ---------------------------------------------------------------------------
set filter_is_hk1   0
set filter_is_hk2   0
set filter_is_hkl   0
set filter_is_hkk   0
set filter_is_nacht 0
if {[string equal $filter "hk1"]}   { set filter_is_hk1   1 }
if {[string equal $filter "hk2"]}   { set filter_is_hk2   1 }
if {[string equal $filter "hkl"]}   { set filter_is_hkl   1 }
if {[string equal $filter "hkk"]}   { set filter_is_hkk   1 }
if {[string equal $filter "nacht"]} { set filter_is_nacht 1 }

if {$filter_is_hk1 || $filter_is_hk2 || $filter_is_hkl || $filter_is_hkk || $filter_is_nacht} {
    set filtered {}
    set nacht_block 0
    set pat_hk1 "*HK1-Log*"
    set pat_hk2 "*HK2-Log*"
    set pat_hkl "HK-Log"
    set pat_hkk "HK-LogHeizkurvenkontrolle"
    foreach line $log_lines {
        set parts [split $line "\t"]
        set src ""
        set msg ""
        if {[llength $parts] >= 2} { set src [lindex $parts 1] }
        if {[llength $parts] >= 3} { set msg [lindex $parts 2] }
        if {$filter_is_hk1} {
            if {[string match $pat_hk1 $src]} { lappend filtered $line }
        } elseif {$filter_is_hk2} {
            if {[string match $pat_hk2 $src]} { lappend filtered $line }
        } elseif {$filter_is_hkk} {
            if {[string equal $src $pat_hkk]} { lappend filtered $line }
        } elseif {$filter_is_hkl} {
            if {[string equal $src $pat_hkl]} { lappend filtered $line }
        } elseif {$filter_is_nacht} {
            if {[string match "*HK2-Log*" $src] && [string match "Beginn Nachtabschaltung*" $msg]} {
                set nacht_block 1
            }
            if {$nacht_block} { lappend filtered $line }
            if {[string match "*HK2-Log*" $src] && [string match "Ende Nachtabschaltung*" $msg]} {
                set nacht_block 0
            }
        }
    }
    set log_lines $filtered
}

# ---------------------------------------------------------------------------
# HTML ausgeben
# ---------------------------------------------------------------------------
puts "Content-Type: text/html; charset=iso-8859-1\nContent-Language: de\n"
puts "<!DOCTYPE html>"
puts {<html lang="de">
<head>
  <meta charset="iso-8859-1">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Heizkalender: HK-Log</title>
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
    <h1>Heizkalender: HK-Log</h1>
  </div>
  <nav class="hk-nav">
    <a href="index.cgi">Raum&uuml;bersicht</a>
    <a href="hkkurve.cgi">Heizkurve</a>
    <a href="hklog.cgi">HK-Log</a>
    <a href="syslog.cgi">Systemlog</a>
    <a href="sysvars.cgi">Systemvariablen</a>
    <a href="hkconfig.cgi">Einstellungen</a>
  </nav>
  <p class="hk-hint">Die Logdateien werden auf einem USB-Stick gespeichert, der an der CCU angeschlossen ist (<code>/media/usb1/HK-Log_JJJJ-MM-TT.log</code>). Es werden die Eintr&auml;ge der letzten 60 Tage angezeigt.</p>}

# Filterleiste
puts {  <div class="hk-log-controls">}
puts "    <form method=\"get\" action=\"hklog.cgi\">"
puts {      <fieldset>}
puts {        <legend>Filter</legend>}
puts "        <label>Filter: <select name=\"filter\">"
foreach fopt {alle hk1 hk2 hkk hkl nacht} {
    set flabel "Alle"
    if {[string equal $fopt "hk1"]}   { set flabel "Nur HK1 (Kalender)" }
    if {[string equal $fopt "hk2"]}   { set flabel "Nur HK2 (Schalten)" }
    if {[string equal $fopt "hkk"]}   { set flabel "Nur Heizkurvenkontrolle" }
    if {[string equal $fopt "hkl"]}   { set flabel "Nur HK-Log (System)" }
    if {[string equal $fopt "nacht"]} { set flabel "Nur Nachtabschaltung" }
    if {[string equal $filter $fopt]} {
        puts "          <option value=\"$fopt\" selected>$flabel</option>"
    } else {
        puts "          <option value=\"$fopt\">$flabel</option>"
    }
}
puts "        </select></label> &nbsp;"
puts "        <label>Log-Datei: <select name=\"file\">"
foreach lf $log_files {
    if {[string equal $lf $file_param]} {
        puts "          <option value=\"[htmlquote $lf]\" selected>[htmlquote $lf]</option>"
    } else {
        puts "          <option value=\"[htmlquote $lf]\">[htmlquote $lf]</option>"
    }
}
puts "        </select></label> &nbsp;"
puts "        <label>letzte Zeilen: <select name=\"n\">"
foreach opt {50 100 200 500 1000 2000} {
    if {$opt == $lines_to_show} {
        puts "          <option value=\"$opt\" selected>$opt</option>"
    } else {
        puts "          <option value=\"$opt\">$opt</option>"
    }
}
puts "        </select></label> &nbsp;"
puts "        <button type=\"submit\">Anzeigen</button>"
if {$has_file_param} {
    puts "        &nbsp;&nbsp;"
    puts "        <a href=\"hklogdownload.cgi?file=[htmlquote $file_param]\" class=\"hk-download-link\">&#8595; Download $file_param</a>"
}
puts {      </fieldset>}
puts "    </form>"
puts {  </div>}

if {[llength $log_files] == 0} {
    puts {  <p class="hk-empty">Kein USB-Stick gefunden oder keine HK-Log-Dateien vorhanden.</p>}
}

# Log-Tabelle
set count [llength $log_lines]
if {$count == 0} {
    if {$has_file_param} {
        puts {  <p class="hk-empty">Datei ist leer oder nicht vorhanden.</p>}
    }
} else {
    puts "  <p class=\"hk-log-info\">[htmlquote $source_label] &mdash; $count Eintr&auml;ge</p>"
    puts {  <div class="hk-table-scroll"><table class="hk-table hk-log-table">}
    puts {    <colgroup><col class="col-log-ts"><col class="col-log-src"><col class="col-log-msg"></colgroup>}
    puts {    <tr><th>Zeitstempel</th><th>Quelle</th><th>Meldung</th></tr>}
    set pat_err "*ERROR*"
    set pat_hk1 "*HK1-Log*"
    set pat_hk2 "*HK2-Log*"
    set pat_hkl "*HK-Log*"
    foreach line $log_lines {
        set uline $line
        set parts [split $uline "\t"]
        if {[llength $parts] >= 3} {
            set ts  [lindex $parts 0]
            set src [lindex $parts 1]
            set msg [join [lrange $parts 2 end] "\t"]
        } elseif {[llength $parts] == 2} {
            set ts  [lindex $parts 0]
            set src ""
            set msg [lindex $parts 1]
        } else {
            set ts  ""
            set src ""
            set msg $uline
        }
        set rowclass ""
        if {[string match $pat_err $src]} {
            set rowclass " class=\"hk-log-error\""
        } elseif {[string match $pat_hk1 $src]} {
            set rowclass " class=\"hk-log-hk1\""
        } elseif {[string match $pat_hk2 $src]} {
            set rowclass " class=\"hk-log-hk2\""
        } elseif {[string match $pat_hkl $src]} {
            set rowclass " class=\"hk-log-hk\""
        }
        puts "    <tr${rowclass}><td>[htmlquote $ts]</td><td>[htmlquote $src]</td><td>[htmlquote $msg]</td></tr>"
    }
    puts {  </table></div>}
}

puts {</div>
</body>
</html>}
