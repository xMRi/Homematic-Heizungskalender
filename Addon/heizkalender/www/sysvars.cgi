#!/bin/tclsh
# Heizkalender-Addon: Systemvariablen-Übersicht
# Zielplattform: CCU3, Tcl 8.2.3
# Kein dict, kein eq/ne -> string equal für String-Vergleiche

load tclrega.so

# ---------------------------------------------------------------------------
# ReGa-Script: alle Systemvariablen mit HK-Präfix abfragen
# ---------------------------------------------------------------------------
set rega_script {
  string result = "";
  string id;
  foreach(id, dom.GetObject(ID_SYSTEM_VARIABLES).EnumUsedIDs()) {
    var sv = dom.GetObject(id);
    if (!sv) { continue; }
    string name = sv.Name();
    if (name.StartsWith("HK-") || name.StartsWith("HK1-") || name.StartsWith("HK2-") || name.StartsWith("HKG-Raum-")) {
      string val = sv.Value();
      string desc = sv.DPInfo();
      result = result # name # "\t" # val # "\t" # desc # "\n";
    }
  }
  WriteLine(result);
}

# STDOUT-Block aus dem rega_script-Ergebnis herausschneiden.
# rega_script gibt einen String der Form
#   STDOUT {<inhalt>} sessionId {} httpUserAgent {} result {<inhalt>}
# zurück. Enthält <inhalt> geschweifte Klammern oder Sonderzeichen, schlägt
# array set fehl. Daher manuell: alles zwischen dem ersten "{" nach "STDOUT "
# und dem zugehörigen abschließenden "}" extrahieren.
set rega_raw [rega_script $rega_script]
set raw ""
set stdout_start [string first "STDOUT {" $rega_raw]
if {$stdout_start >= 0} {
    set brace_start [expr {$stdout_start + 7}]
    set depth 0
    set brace_end -1
    set rlen [string length $rega_raw]
    set j $brace_start
    set open_brace "{"
    set close_brace "}"
    while {$j < $rlen} {
        set ch [string index $rega_raw $j]
        if {[string equal $ch $open_brace]} {
            incr depth
        } elseif {[string equal $ch $close_brace]} {
            incr depth -1
            if {$depth == 0} {
                set brace_end $j
                break
            }
        }
        incr j
    }
    if {$brace_end > $brace_start} {
        set raw [string range $rega_raw [expr {$brace_start+1}] [expr {$brace_end-1}]]
    }
}

# ---------------------------------------------------------------------------
# Ergebnis in vier Listen aufteilen
# Jede Liste enthält Tripel: {name val desc name val desc ...}
# ---------------------------------------------------------------------------
set vars_hk  {}
set vars_hk1 {}
set vars_hk2 {}
set vars_hkg  {}

foreach line [split $raw "\n"] {
    if {[string equal $line ""]} { continue }
    set parts [split $line "\t"]
    if {[llength $parts] < 3} { continue }
    set name [lindex $parts 0]
    set val  [lindex $parts 1]
    set desc [lindex $parts 2]

    if {[string match "HKG-Raum-*" $name]} {
        lappend vars_hkg $name $val $desc
    } elseif {[string match "HK2-*" $name]} {
        lappend vars_hk2 $name $val $desc
    } elseif {[string match "HK1-*" $name]} {
        lappend vars_hk1 $name $val $desc
    } else {
        lappend vars_hk $name $val $desc
    }
}

# ---------------------------------------------------------------------------
# Dokumentationslinks: Variablenname -> URL
# ---------------------------------------------------------------------------
set doc_base_xmri   "https://github.com/xMRi/Homematic-Heizungskalender/blob/main"

set doc_skripte     "${doc_base_xmri}/Skripte/Dokumentation/Readme.md"
set doc_skripte_log "${doc_skripte}#hk-init-variablen-logginghsc"
set doc_skripte_sl  "${doc_skripte}#schaltskript"
set doc_awh         "${doc_base_xmri}/Dokumentation/Anwenderhandbuch.md"
set doc_awh_global  "${doc_awh}#globale-einstellungen-systemvariablen-fuer-skript-2"
set doc_awh_kurve   "${doc_awh}#die-heizkurve-hk2-kurve"
set doc_awh_nacht   "${doc_awh}#nachtschaltung"
set doc_dev         "${doc_base_xmri}/Dokumentation/Entwickler.md"
set doc_dev_rliste  "${doc_dev}#hk1-r-liste"
set doc_dev_hkgl    "${doc_dev}#hk2-hkg-liste"
set doc_dev_sl      "${doc_dev}#hk1-schaltliste"

set doc_links [list \
    HK-Log                        $doc_skripte_log \
    HK-Logging                    $doc_skripte_log \
    HK-LogHeizkurvenkontrolle     $doc_skripte_log \
    HK-LoggingHeizkurvenkontrolle $doc_skripte_log \
    HK-RäumeHeizkurvenkontrolle   $doc_skripte_log \
    HK1-CD-OrganisationsId        $doc_skripte \
    HK1-CD-Token                  $doc_skripte \
    HK1-CT-Gemeindename           $doc_skripte \
    HK1-CT-Token                  $doc_skripte \
    HK1-GK-API-Key                $doc_skripte \
    HK1-GK-Kalender-ID            $doc_skripte \
    HK1-ICS-Url                   $doc_skripte \
    HK1-Log                       $doc_skripte_log \
    HK1-Logging                   $doc_skripte_log \
    HK1-R-Liste                   $doc_dev_rliste \
    HK1-Schaltliste               $doc_dev_sl \
    HK2-Log                       $doc_skripte_log \
    HK2-Logging                   $doc_skripte_log \
    HK2-A.Temp.Grenze             $doc_awh_global \
    HK2-Aussentemperatur          $doc_awh_global \
    HK2-Grundtemperatur           $doc_awh_global \
    HK2-Hand-Grundtemp            $doc_awh_global \
    HK2-Hand-Temp                 $doc_awh_global \
    HK2-HKG-Liste                 $doc_dev_hkgl \
    HK2-Kurve                     $doc_awh_kurve  \
    HK2-Kurvenversatz             $doc_awh_global \
    HK2-VorzeitAus                $doc_awh_global \
]

proc lookup_doc_url {name doc_links_var} {
    upvar $doc_links_var dl
    set idx [lsearch $dl $name]
    if {$idx >= 0 && ($idx % 2) == 0} { return [lindex $dl [expr {$idx+1}]] }
    return ""
}

# ---------------------------------------------------------------------------
# Abkürzungs-Übersetzungstabellen
# ---------------------------------------------------------------------------

# Modus-Kürzel -> Langtext
set modus_map {
    H  "Heizen (H)"
    S  "Schalten (S)"
    HS "Heizen+Schalten (HS)"
}

# Heiztyp-Kürzel -> Langtext
set heiztyp_map {
    IP  "Homematic IP (IP)"
    SW  "Schaltaktor (SW)"
    RT  "Thermostat RT (RT)"
    TC  "Thermostat TC (TC)"
    IT  "Thermostat IT (IT)"
}

# Status-Kürzel -> Langtext
set status_map {
    0  "Aus (0)"
    1  "Ein (1)"
}

proc translate {val mapvar} {
    upvar $mapvar map
    set idx [lsearch $map $val]
    if {$idx >= 0 && $idx+1 < [llength $map]} {
        return [lindex $map [expr {$idx+1}]]
    }
    return $val
}

# ---------------------------------------------------------------------------
# Hilfsprozeduren
# ---------------------------------------------------------------------------

proc htmlquote {s} {
    set s [string map {& &amp; < &lt; > &gt; \" &quot;} $s]
    return $s
}

# Variablennamen, die sensible Zugangsdaten enthalten, werden maskiert.
# Betrifft: *-Token, *-Key, *-Password, *-Passwort
proc mask_if_sensitive {name val} {
    if {[string match "*-Token" $name] ||
        [string match "*-Key"   $name] ||
        [string match "*-Password" $name] ||
        [string match "*-Passwort" $name]} {
        return "***"
    }
    return $val
}

proc render_rliste {val} {
    set entries [split $val ";"]
    if {[llength $entries] == 0 || [string equal $val ""]} {
        return "<em>(leer)</em>"
    }
    set html "<table class=\"hk-table hk-table-inline\">\n"
    append html "  <tr><th>ID</th><th>Name</th></tr>\n"
    foreach entry $entries {
        if {[string equal $entry ""]} { continue }
        set eqpos [string first "=" $entry]
        if {$eqpos >= 0} {
            set rid  [string range $entry 0 [expr {$eqpos-1}]]
            set rnam [string range $entry [expr {$eqpos+1}] end]
        } else {
            set rid  $entry
            set rnam ""
        }
        append html "  <tr><td>[htmlquote $rid]</td><td>[htmlquote $rnam]</td></tr>\n"
    }
    append html "</table>\n"
    return $html
}

proc render_hkgliste {val} {
    set entries [split $val ";"]
    if {[llength $entries] == 0 || [string equal $val ""]} {
        return "<em>(leer)</em>"
    }
    set html "<table class=\"hk-table hk-table-inline\">\n"
    append html "  <tr><th>Raum-Systemvariable</th><th>Gruppe</th></tr>\n"
    foreach entry $entries {
        if {[string equal $entry ""]} { continue }
        set pluspos [string first "+" $entry]
        if {$pluspos >= 0} {
            set raum    [string range $entry 0 [expr {$pluspos-1}]]
            set gruppe  [string range $entry [expr {$pluspos+1}] end]
        } else {
            set raum   $entry
            set gruppe ""
        }
        append html "  <tr><td>[htmlquote $raum]</td><td>[htmlquote $gruppe]</td></tr>\n"
    }
    append html "</table>\n"
    return $html
}

proc format_temp {val} {
    set t $val
    catch {set t [format "%.1f" $val]}
    return "$t &deg;C"
}

proc is_temp_var {name} {
    if {[string equal $name "HK2-A.Temp.Grenze"]}   { return 1 }
    if {[string equal $name "HK2-Aussentemperatur"]} { return 1 }
    if {[string equal $name "HK2-Grundtemperatur"]}  { return 1 }
    return 0
}

proc is_time_min_var {name} {
    if {[string equal $name "HK2-VorzeitAus"]} { return 1 }
    return 0
}

proc render_table {varlist} {
    global doc_links
    if {[llength $varlist] == 0} {
        return "<p class=\"hk-empty\">Keine Variablen gefunden.</p>"
    }
    set html "<div class=\"hk-table-scroll\"><table class=\"hk-table\">\n"
    append html "  <colgroup><col class=\"col-name\"><col class=\"col-val\"><col class=\"col-desc\"></colgroup>\n"
    append html "  <tr><th>Variable</th><th>Wert</th><th>Beschreibung</th></tr>\n"
    set i 0
    while {$i < [llength $varlist]} {
        set name [lindex $varlist $i]
        set val  [lindex $varlist [expr {$i+1}]]
        set desc [lindex $varlist [expr {$i+2}]]
        set display_val [mask_if_sensitive $name $val]
        if {[string equal $name "HK1-R-Liste"]} {
            set cell [render_rliste $display_val]
        } elseif {[string equal $name "HK2-HKG-Liste"]} {
            set cell [render_hkgliste $display_val]
        } elseif {[is_temp_var $name]} {
            set cell [format_temp $display_val]
        } elseif {[is_time_min_var $name]} {
            set cell "[htmlquote $display_val] min"
        } else {
            set cell [htmlquote $display_val]
        }
        set url [lookup_doc_url $name doc_links]
        if {![string equal $url ""]} {
            set name_cell "[htmlquote $name] <a href=\"[htmlquote $url]\" target=\"_blank\" class=\"hk-doc-link\" title=\"Dokumentation\">&#x24D8;</a>"
        } else {
            set name_cell [htmlquote $name]
        }
        append html "  <tr><td>$name_cell</td><td>$cell</td><td>[htmlquote $desc]</td></tr>\n"
        set i [expr {$i+3}]
    }
    append html "</table></div>\n"
    return $html
}

proc render_room_table {varlist} {
    global modus_map heiztyp_map status_map
    if {[llength $varlist] == 0} {
        return "<p class=\"hk-empty\">Keine Raum-Systemvariablen gefunden.</p>"
    }
    set html "<div class=\"hk-table-scroll\"><table class=\"hk-table hk-table-rooms\">\n"
    append html "  <colgroup>\n"
    append html "    <col class=\"col-room\"><col class=\"col-status\"><col class=\"col-modus\">\n"
    append html "    <col class=\"col-heiztyp\"><col class=\"col-wtemp\"><col class=\"col-gtemp\">\n"
    append html "    <col class=\"col-vzeit\"><col class=\"col-faktor\"><col class=\"col-vaus\">\n"
    append html "    <col class=\"col-thermostat\"><col class=\"col-schaltaktor\">\n"
    append html "  </colgroup>\n"
    append html "  <tr>"
    append html "<th>Raum</th>"
    append html "<th>Status</th>"
    append html "<th>Modus</th>"
    append html "<th>Heiztyp</th>"
    append html "<th>Wohlf&uuml;hltemp (&deg;C)</th>"
    append html "<th>Grundtemp (&deg;C)</th>"
    append html "<th>Vorheizzeit (min)</th>"
    append html "<th>Faktor</th>"
    append html "<th>Vorlaufzeit Aus (min)</th>"
    append html "<th>Thermostat / Sensor</th>"
    append html "<th>Schaltaktor(en)</th>"
    append html "</tr>\n"

    set i 0
    while {$i < [llength $varlist]} {
        set name [lindex $varlist $i]
        set val  [lindex $varlist [expr {$i+1}]]
        # Raumname: HKG-Raum-XYZ -> XYZ
        set roomname [string range $name 9 end]

        set fields [split $val ";"]
        set status     [lindex $fields 0]
        set modus      [lindex $fields 1]
        set heiztyp    [lindex $fields 2]
        set tempfeld   [lindex $fields 3]
        set vorheiz    [lindex $fields 4]
        set vorzeitaus [lindex $fields 5]
        set thermostat  [lindex $fields 6]
        set schaltaktor [join [lrange $fields 7 end] ";"]

        # Wohlfühltemp / Grundtemp trennen
        set wtemp $tempfeld
        set gtemp ""
        if {[string first "/" $tempfeld] >= 0} {
            set tparts [split $tempfeld "/"]
            set wtemp [lindex $tparts 0]
            set gtemp [lindex $tparts 1]
        }

        # Vorheizzeit / Faktor trennen
        set vzeit $vorheiz
        set faktor ""
        if {[string first "*" $vorheiz] >= 0} {
            set vparts [split $vorheiz "*"]
            set vzeit  [lindex $vparts 0]
            set faktor [lindex $vparts 1]
        }

        # Abkürzungen übersetzen
        set status_txt  [translate $status  status_map]
        set modus_txt   [translate $modus   modus_map]
        set heiztyp_txt [translate $heiztyp heiztyp_map]

        append html "  <tr>"
        append html "<td>[htmlquote $roomname]</td>"
        append html "<td>[htmlquote $status_txt]</td>"
        append html "<td>[htmlquote $modus_txt]</td>"
        append html "<td>[htmlquote $heiztyp_txt]</td>"
        if {[string equal $wtemp ""]} {
            append html "<td></td>"
        } else {
            catch {set wtemp [format "%.1f" $wtemp]}
            append html "<td>[htmlquote $wtemp] &deg;C</td>"
        }
        if {[string equal $gtemp ""]} {
            append html "<td></td>"
        } else {
            catch {set gtemp [format "%.1f" $gtemp]}
            append html "<td>[htmlquote $gtemp] &deg;C</td>"
        }
        if {[string equal $vzeit ""]} {
            append html "<td></td>"
        } else {
            append html "<td>[htmlquote $vzeit] min</td>"
        }
        append html "<td>[htmlquote $faktor]</td>"
        if {[string equal $vorzeitaus ""]} {
            append html "<td></td>"
        } else {
            append html "<td>[htmlquote $vorzeitaus] min</td>"
        }
        append html "<td>[htmlquote $thermostat]</td>"
        append html "<td>[htmlquote $schaltaktor]</td>"
        append html "</tr>\n"

        set i [expr {$i+3}]
    }
    append html "</table></div>\n"
    return $html
}

# ---------------------------------------------------------------------------
# HTML ausgeben
# ---------------------------------------------------------------------------
puts "Content-Type: text/html; charset=iso-8859-1\nContent-Language: de\n"
puts {<!DOCTYPE html>
<html lang="de">
<head>
  <meta charset="iso-8859-1">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Heizkalender: Systemvariablen</title>
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
    <h1>Heizkalender: Systemvariablen</h1>
  </div>
  <nav class="hk-nav">
    <a href="index.cgi">Raum&uuml;bersicht</a>
    <a href="hkkurve.cgi">Heizkurve</a>
    <a href="hklog.cgi">HK-Log</a>
    <a href="syslog.cgi">Systemlog</a>
    <a href="sysvars.cgi">Systemvariablen</a>
    <a href="hkconfig.cgi">Einstellungen</a>
  </nav>
}

puts "<h2 id=\"hk\">Allgemein (HK-*)</h2>"
puts [render_table $vars_hk]

puts "<h2 id=\"hk1\">Kalender (HK1-*)</h2>"
puts [render_table $vars_hk1]

puts "<h2 id=\"hk2\">Schalten (HK2-*)</h2>"
puts [render_table $vars_hk2]

puts "<h2 id=\"raeume\">R&auml;ume (HKG-Raum-*)</h2>"
puts [render_room_table $vars_hkg]

puts {</div>
</body>
</html>}
