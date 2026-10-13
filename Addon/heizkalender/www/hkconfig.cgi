#!/bin/tclsh
# Heizkalender-Addon: Grundeinstellungen (read-only)
# Zielplattform: CCU3, Tcl 8.2.3

load tclrega.so

proc htmlquote {s} {
    set s [string map {& &amp; < &lt; > &gt; \" &quot;} $s]
    return $s
}

proc bool_label {val} {
    set checked ""
    if {[string equal $val "1"] || [string equal $val "true"]} { set checked " checked" }
    return "<input type=\"checkbox\"${checked} disabled>"
}

proc format_num {val {decimals 1}} {
    set n 0.0
    if {[catch {set n [expr {double($val)}]}]} { return [htmlquote $val] }
    return [format "%.${decimals}f" $n]
}

proc format_modus {m} {
    if {[string equal $m "H"]}  { return "Heizen" }
    if {[string equal $m "S"]}  { return "Schalten" }
    if {[string equal $m "HS"]} { return "Heizen+Schalten" }
    return [htmlquote $m]
}

proc format_heiztyp {t} {
    if {[string equal $t "IP"]} { return "Homematic IP" }
    if {[string equal $t "SW"]} { return "Schalt-Aktor" }
    if {[string equal $t "RT"]} { return "Thermostat RT" }
    if {[string equal $t "TC"]} { return "Thermostat TC" }
    if {[string equal $t "IT"]} { return "Thermostat IT" }
    return [htmlquote $t]
}

# ---------------------------------------------------------------------------
# ReGaHss-Abfrage
# ---------------------------------------------------------------------------
set rega_script {
    string result = "";

    string kv;
    foreach(kv, "HK1-CT-Gemeindename;HK1-CT-Token;HK1-CD-OrganisationsId;HK1-CD-Token;HK1-ICS-Url;HK1-GK-API-Key;HK1-GK-Kalender-ID".Split(";")) {
        var o = dom.GetObject(kv);
        if (o) { result = result # "KAL\t" # kv # "\t" # o.Value() # "\n"; }
    }
    result = result # "===KAL===\n";

    string ev;
    foreach(ev, "HK-Logging;HK1-Logging;HK2-Logging;HK-LoggingHeizkurvenkontrolle;HK2-Hand-Grundtemp;HK2-Hand-Temp;HK2-Grundtemperatur;HK2-A.Temp.Grenze;HK2-VorzeitAus;HK2-Kurvenversatz;HK2-Kurve".Split(";")) {
        var o = dom.GetObject(ev);
        if (o) { result = result # "EINST\t" # ev # "\t" # o.Value() # "\n"; }
    }
    result = result # "===EINST===\n";

    string pid;
    foreach(pid, dom.GetObject(ID_PROGRAMS).EnumUsedIDs()) {
        var prog = dom.GetObject(pid);
        if (!prog) { continue; }
        string pname = prog.Name();
        if (pname.StartsWith("HK") || pname.StartsWith("Tool-")) {
            result = result # "PROG\t" # pname # "\t" # prog.Active() # "\n";
        }
    }
    result = result # "===PROG===\n";

    string rid;
    foreach(rid, dom.GetObject(ID_SYSTEM_VARIABLES).EnumUsedIDs()) {
        var sv = dom.GetObject(rid);
        if (!sv) { continue; }
        string name = sv.Name();
        if (name.StartsWith("HKG-Raum-")) {
            result = result # "RAUM\t" # name # "\t" # sv.Value() # "\n";
        }
    }
    result = result # "===RAUM===\n";

    var orl  = dom.GetObject("HK1-R-Liste");
    var ohkg = dom.GetObject("HK2-HKG-Liste");
    if (orl)  { result = result # "RLISTE\t"   # orl.Value()  # "\n"; }
    if (ohkg) { result = result # "HKGLISTE\t" # ohkg.Value() # "\n"; }
    result = result # "===KALZUO===\n";

    WriteLine(result);
}

set rega_result [rega_script $rega_script]
# "result"-Key direkt aus dem Dict lesen — robuster als Brace-Zaehlung
set raw ""
set rpos [string first "result " $rega_result]
if {$rpos >= 0} {
    set after [string range $rega_result [expr {$rpos + 7}] end]
    # Wert steht in geschweiften Klammern: result {inhalt}
    if {[string equal [string index $after 0] "\{"]} {
        set depth 1
        set j 1
        set rlen [string length $after]
        while {$j < $rlen && $depth > 0} {
            set ch [string index $after $j]
            if {[string equal $ch "\{"]} { incr depth }
            if {[string equal $ch "\}"]} { incr depth -1 }
            incr j
        }
        set raw [string range $after 1 [expr {$j-2}]]
    }
}

# ---------------------------------------------------------------------------
# Abschnitte trennen (ohne lassign)
# ---------------------------------------------------------------------------
proc split_section {raw marker} {
    set pos [string first $marker $raw]
    if {$pos < 0} { return [list $raw ""] }
    set before [string range $raw 0 [expr {$pos - 1}]]
    set after  [string range $raw [expr {$pos + [string length $marker]}] end]
    return [list $before $after]
}

set parts [split_section $raw "===KAL===\n"]
set kal_raw  [lindex $parts 0]
set rest     [lindex $parts 1]

set parts [split_section $rest "===EINST===\n"]
set einst_raw [lindex $parts 0]
set rest      [lindex $parts 1]

set parts [split_section $rest "===PROG===\n"]
set prog_raw [lindex $parts 0]
set rest     [lindex $parts 1]

set parts [split_section $rest "===RAUM===\n"]
set raum_raw [lindex $parts 0]
set rest     [lindex $parts 1]

set parts [split_section $rest "===KALZUO===\n"]
set kalzuo_raw [lindex $parts 0]

# ---------------------------------------------------------------------------
# Parsen
# ---------------------------------------------------------------------------
array set kalval {}
foreach line [split $kal_raw "\n"] {
    set line [string trim $line]
    if {[string equal $line ""]} { continue }
    set parts [split $line "\t"]
    if {[llength $parts] >= 3 && [string equal [lindex $parts 0] "KAL"]} {
        set kalval([lindex $parts 1]) [join [lrange $parts 2 end] "\t"]
    }
}

array set einstval {}
foreach line [split $einst_raw "\n"] {
    set line [string trim $line]
    if {[string equal $line ""]} { continue }
    set parts [split $line "\t"]
    if {[llength $parts] >= 3 && [string equal [lindex $parts 0] "EINST"]} {
        set einstval([lindex $parts 1]) [join [lrange $parts 2 end] "\t"]
    }
}

set programme {}
foreach line [split $prog_raw "\n"] {
    set line [string trim $line]
    if {[string equal $line ""]} { continue }
    set parts [split $line "\t"]
    if {[llength $parts] >= 2 && [string equal [lindex $parts 0] "PROG"]} {
        lappend programme [list [lindex $parts 1] [join [lrange $parts 2 end] "\t"]]
    }
}
set programme [lsort -index 0 $programme]

set raeume {}
foreach line [split $raum_raw "\n"] {
    set line [string trim $line]
    if {[string equal $line ""]} { continue }
    set parts [split $line "\t"]
    if {[llength $parts] >= 3 && [string equal [lindex $parts 0] "RAUM"]} {
        lappend raeume [list [lindex $parts 1] [join [lrange $parts 2 end] "\t"]]
    }
}
set raeume [lsort -index 0 $raeume]

set rliste_raw ""
set hkgliste_raw ""
foreach line [split $kalzuo_raw "\n"] {
    set line [string trim $line]
    if {[string equal $line ""]} { continue }
    set parts [split $line "\t"]
    if {[string equal [lindex $parts 0] "RLISTE"]}   { set rliste_raw  [join [lrange $parts 1 end] "\t"] }
    if {[string equal [lindex $parts 0] "HKGLISTE"]} { set hkgliste_raw [join [lrange $parts 1 end] "\t"] }
}

# Ressourcen + Raumzuordnungen kombinieren
set zuordnungen {}
set hkgeintraege [split $hkgliste_raw ";"]
set idx 0
foreach re [split $rliste_raw ";"] {
    set re [string trim $re]
    if {[string equal $re ""]} { incr idx; continue }
    set eqpos [string first "=" $re]
    if {$eqpos >= 0} {
        set rid   [string range $re 0 [expr {$eqpos-1}]]
        set rname [string range $re [expr {$eqpos+1}] end]
    } else {
        set rid   $re
        set rname $re
    }
    set raumzuo ""
    if {$idx < [llength $hkgeintraege]} {
        set hkgraw [string trim [lindex $hkgeintraege $idx]]
        set raumteile {}
        foreach teil [split $hkgraw "+"] {
            set teil [string trim $teil]
            if {[string equal $teil ""]} { continue }
            # HKG-Raum-Prefix entfernen
            if {[string equal [string range $teil 0 8] "HKG-Raum-"]} {
                set teil [string range $teil 9 end]
            }
            lappend raumteile $teil
        }
        set raumzuo [join $raumteile ", "]
    }
    lappend zuordnungen [list $rid $rname $raumzuo]
    incr idx
}
set zuordnungen [lsort -integer -index 0 $zuordnungen]

# ---------------------------------------------------------------------------
# HTTP-Header + HTML
# ---------------------------------------------------------------------------
puts "Content-Type: text/html; charset=iso-8859-1\nContent-Language: de\n"
puts {<!DOCTYPE html>
<html lang="de">
<head>
  <meta charset="iso-8859-1">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Heizkalender: Grundeinstellungen</title>
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
    <h1>Heizkalender: Grundeinstellungen</h1>
  </div>
  <nav class="hk-nav">
    <a href="index.cgi">Raum&uuml;bersicht</a>
    <a href="hkkurve.cgi">Heizkurve</a>
    <a href="hklog.cgi">HK-Log</a>
    <a href="syslog.cgi">Systemlog</a>
    <a href="sysvars.cgi">Systemvariablen</a>
    <a href="hkconfig.cgi">Einstellungen</a>
  </nav>}

puts {<p class="hk-hint">Alle Werte werden direkt von der CCU gelesen und k&ouml;nnen hier nicht ge&auml;ndert werden.</p>}

# ===========================================================================
# Kalender
# ===========================================================================

# Variante erkennen anhand vorhandener Systemvariablen
set kalvariante "Unbekannt"
if {[info exists kalval(HK1-CT-Gemeindename)] || [info exists kalval(HK1-CT-Token)]} {
    set kalvariante "ChurchTools"
} elseif {[info exists kalval(HK1-CD-OrganisationsId)] || [info exists kalval(HK1-CD-Token)]} {
    set kalvariante "ChurchDesk"
} elseif {[info exists kalval(HK1-ICS-Url)]} {
    set kalvariante "iCal"
} elseif {[info exists kalval(HK1-GK-API-Key)] || [info exists kalval(HK1-GK-Kalender-ID)]} {
    set kalvariante "Google Calendar"
}

puts {<fieldset><legend>Kalender</legend>}
puts "  <p><strong>Erkannte Kalender-Integration:</strong> [htmlquote $kalvariante]</p>"
puts {<div class="hk-table-scroll"><table class="hk-config-table-auto">}

# ChurchTools
foreach {var label} {
    HK1-CT-Gemeindename "Gemeindename"
    HK1-CT-Token        "Login-Token"
} {
    if {[info exists kalval($var)]} {
        set val [htmlquote $kalval($var)]
        if {[string match "*Token*" $var] && [string length $val] > 20} {
            set val "[string range $val 0 19]&hellip;"
        }
        puts "  <tr><th>ChurchTools: $label</th><td class=\"hk-code\">$val</td></tr>"
    }
}

# ChurchDesk
foreach {var label} {
    HK1-CD-OrganisationsId "Organisations-ID"
    HK1-CD-Token           "API-Token"
} {
    if {[info exists kalval($var)]} {
        set val [htmlquote $kalval($var)]
        if {[string match "*Token*" $var] && [string length $val] > 20} {
            set val "[string range $val 0 19]&hellip;"
        }
        puts "  <tr><th>ChurchDesk: $label</th><td class=\"hk-code\">$val</td></tr>"
    }
}

# iCal
if {[info exists kalval(HK1-ICS-Url)]} {
    puts "  <tr><th>iCal: Kalender-URL</th><td class=\"hk-code\">[htmlquote $kalval(HK1-ICS-Url)]</td></tr>"
}

# Google Calendar
foreach {var label} {
    HK1-GK-API-Key      "API-Key"
    HK1-GK-Kalender-ID  "Kalender-ID"
} {
    if {[info exists kalval($var)]} {
        set val [htmlquote $kalval($var)]
        if {[string match "*Key*" $var] && [string length $val] > 20} {
            set val "[string range $val 0 19]&hellip;"
        }
        puts "  <tr><th>Google Calendar: $label</th><td class=\"hk-code\">$val</td></tr>"
    }
}

puts {</table></div>}
puts {</fieldset>}

# ===========================================================================
# Programme
# ===========================================================================
puts {<fieldset><legend>Programme</legend>}
puts {<div class="hk-table-scroll"><table class="hk-config-table-auto">}
puts {  <tr><th>Programm</th><th>Aktiv</th></tr>}
foreach prog $programme {
    puts "  <tr><td>[htmlquote [lindex $prog 0]]</td><td>[bool_label [lindex $prog 1]]</td></tr>"
}
puts {</table></div>}
puts {</fieldset>}

# ===========================================================================
# Einstellungen
# ===========================================================================
puts {<fieldset><legend>Einstellungen</legend>}

puts {<fieldset><legend>Protokollierung</legend>}
puts {<div class="hk-table-scroll"><table class="hk-config-table-auto">}
foreach {var label} {
    HK-Logging                    "Allgemeine Protokollierung"
    HK1-Logging                   "Skript 1 (Termindaten einlesen)"
    HK2-Logging                   "Skript 2 (Heizung schalten)"
    HK-LoggingHeizkurvenkontrolle "Heizkurvenkontrolle"
} {
    if {[info exists einstval($var)]} {
        puts "  <tr><th>[htmlquote $label]</th><td>[bool_label $einstval($var)]</td></tr>"
    }
}
puts {</table></div>}
puts {</fieldset>}

puts {<fieldset><legend>R&uuml;ckstellungsverhalten</legend>}
puts {<div class="hk-table-scroll"><table class="hk-config-table-auto">}
foreach {var label} {
    HK2-Hand-Grundtemp "N&auml;chtliche R&uuml;ckstellung auf Grundtemperatur (01:00 Uhr)"
    HK2-Hand-Temp      "Manuell eingestellte Temperatur am Terminende beibehalten"
} {
    if {[info exists einstval($var)]} {
        puts "  <tr><th>$label</th><td>[bool_label $einstval($var)]</td></tr>"
    }
}
puts {</table></div>}
puts {</fieldset>}

puts {<fieldset><legend>Temperaturen und Zeitversatz</legend>}
puts {<div class="hk-table-scroll"><table class="hk-config-table-auto">}
foreach {var label unit} {
    HK2-Grundtemperatur "Grundtemperatur"              "&deg;C"
    HK2-A.Temp.Grenze   "Au&szlig;entemperatur-Grenze" "&deg;C"
    HK2-VorzeitAus      "Globaler Ausschalt-Versatz"   "min"
    HK2-Kurvenversatz   "Globaler Einschalt-Versatz"   "min"
} {
    if {[info exists einstval($var)]} {
        set decimals [expr {[string match "*Temp*" $var] || [string match "*Grenze*" $var] ? 1 : 0}]
        puts "  <tr><th>$label</th><td>[format_num $einstval($var) $decimals]&nbsp;$unit</td></tr>"
    }
}
puts {</table></div>}
puts {</fieldset>}

puts {<fieldset><legend>Heizkurve (HK2-Kurve)</legend>}
if {[info exists einstval(HK2-Kurve)]} {
    set kurve_werte [split $einstval(HK2-Kurve) ";"]
    # Stützpunkte: Außentemperatur und Farbton (0=blau, 240; 17.5=rot, 0) — linear interpoliert
    # Farbwerte als HTML-Hex: kalt blau (#4472c4) über grün (#70b040) nach warm rot (#c44444)
    set kurve_at_vals {-10 -5 0 8 10 12 15 17.5}
    set kurve_at_labels {-10 -5 0 8 10 12 15 {17,5}}
    # Farben für jeden Stützpunkt (kalt -> warm): 8 Werte
    set kurve_colors {
        {68 114 196}
        {80 140 190}
        {100 160 160}
        {120 170 80}
        {160 180 60}
        {200 170 40}
        {210 120 40}
        {196 68 68}
    }
    puts {<div class="hk-kurve-grid">}
    set i 0
    foreach at $kurve_at_labels {
        set min ""
        catch { set min [lindex $kurve_werte $i] }
        set rgb [lindex $kurve_colors $i]
        set r [lindex $rgb 0]
        set g [lindex $rgb 1]
        set b [lindex $rgb 2]
        set bg [format "#%02x%02x%02x" $r $g $b]
        # Textfarbe: hell bei dunklem Hintergrund (Helligkeit < 128), sonst dunkel
        set lum [expr {($r*299 + $g*587 + $b*114) / 1000}]
        set fg [expr {$lum < 140 ? "#ffffff" : "#222222"}]
        puts "  <div class=\"hk-kurve-cell\" style=\"background:${bg};color:${fg}\">"
        puts "    <div class=\"hk-at\">${at}&nbsp;&deg;C</div>"
        puts "    <div class=\"hk-min\">[format_num $min 0]</div>"
        puts "    <div class=\"hk-at\">min</div>"
        puts "  </div>"
        incr i
    }
    puts {</div>}
}
puts {</fieldset>}

puts {</fieldset>}

# ===========================================================================
# Kalenderzuordnung
# ===========================================================================
puts {<fieldset><legend>Kalenderzuordnung</legend>}
puts {<div class="hk-table-scroll"><table class="hk-config-table-auto">}
puts {  <tr><th>Id</th><th>Ressource</th><th>Zugeordnete R&auml;ume</th></tr>}
foreach z $zuordnungen {
    set rid     [htmlquote [lindex $z 0]]
    set rname   [htmlquote [lindex $z 1]]
    set raumzuo [htmlquote [lindex $z 2]]
    puts "  <tr><td class=\"hk-id\">$rid</td><td>$rname</td><td class=\"hk-val\">$raumzuo</td></tr>"
}
puts {</table></div>}
puts {</fieldset>}

# ===========================================================================
# Räume
# ===========================================================================
set deg "&deg;"
puts {<fieldset><legend>R&auml;ume</legend>}
puts {<div class="hk-table-scroll"><table class="hk-config-table-auto">}
puts "  <tr><th>Raum</th><th>Modus</th><th>Wohlf&uuml;hltemp.</th><th>Abw. Grundtemp.</th><th>Vorzeitiger Heizbeginn</th><th>Vorzeitiges Heizende</th><th>Faktor Heizkurve</th><th>Thermostat / Sensor</th><th>Schaltaktor</th><th>Ger&auml;tetyp</th></tr>"
foreach raum $raeume {
    set rname [string range [lindex $raum 0] 9 end]
    set felder [split [lindex $raum 1] ";"]
    set modus    [lindex $felder 1]
    set heiztyp  [lindex $felder 2]
    set tempfeld [lindex $felder 3]
    set vorlauf  [lindex $felder 4]
    set vorzaus  [lindex $felder 5]
    set thermostat [lindex $felder 6]
    set schaltaktor [join [lrange $felder 7 end] ";"]
    set slashpos [string first "/" $tempfeld]
    if {$slashpos >= 0} {
        set wtemp  [string range $tempfeld 0 [expr {$slashpos-1}]]
        set gtemp  [string range $tempfeld [expr {$slashpos+1}] end]
    } else {
        set wtemp  $tempfeld
        set gtemp  ""
    }
    set gtemp_str [expr {[string equal $gtemp ""] ? "&ndash;" : "[format_num $gtemp]&nbsp;${deg}C"}]
    set stern [string first "*" $vorlauf]
    if {$stern >= 0} {
        set faktor  [string range $vorlauf [expr {$stern+1}] end]
        set vorlauf [string range $vorlauf 0 [expr {$stern-1}]]
    } else {
        set faktor "1.0"
    }
    puts "  <tr><td>[htmlquote $rname]</td><td>[format_modus $modus]</td><td>[format_num $wtemp]&nbsp;${deg}C</td><td>$gtemp_str</td><td>[format_num $vorlauf 0]&nbsp;min</td><td>[format_num $vorzaus 0]&nbsp;min</td><td>[format_num $faktor]</td><td>[htmlquote $thermostat]</td><td>[htmlquote $schaltaktor]</td><td>[format_heiztyp $heiztyp]</td></tr>"
}
puts {</table></div>}
puts {</fieldset>}

puts {</div>
</body>
</html>}
