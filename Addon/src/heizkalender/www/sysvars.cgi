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
set doc_base "https://xmri.github.io/Homematic-Heizungskalender"

set doc_skripte     "${doc_base}/skripte/readme/"
set doc_skripte_log "${doc_skripte}#hk-init-variablen-logginghsc"
set doc_skripte_sl  "${doc_skripte}#schaltskript"
set doc_skripte_cd  "${doc_skripte}#hk-init-skript-1_churchdeskhsc"
set doc_skripte_ct  "${doc_skripte}#hk-init-skript-1_churchtoolshsc"
set doc_skripte_gk  "${doc_skripte}#hk-init-skript-1_googlehsc"
set doc_skripte_ics "${doc_skripte}#hk-init-skript-1_icalhsc"
set doc_skripte_s2  "${doc_skripte}#hk-init-skript-2hsc"
set doc_awh         "${doc_base}/heizkalender/anwenderhandbuch/"
set doc_awh_global  "${doc_awh}#globale-einstellungen-systemvariablen-f%C3%BCr-skript-2"
set doc_awh_kurve   "${doc_awh}#die-heizkurve-hk2-kurve"
set doc_awh_nacht   "${doc_awh}#nachtschaltung"
set doc_dev         "${doc_base}/heizkalender/entwickler/"
set doc_dev_rliste  "${doc_dev}#hk1-r-liste"
set doc_dev_hkgl    "${doc_dev}#hk2-hkg-liste"
set doc_dev_sl      "${doc_dev}#hk1-schaltliste"
set doc_dev_vlz1    "${doc_dev}#hk1-vorlaufzeit"
set doc_dev_vlz2    "${doc_dev}#hk2-schaltzeiten"
set doc_dev_kurve   "${doc_dev}#hk2-kurve"
set doc_dev_raeume_hkk "${doc_dev}#hk-raumeheizkurvenkontrolle"

set doc_links [list \
    HK-Log                        $doc_skripte_log \
    HK-Logging                    $doc_skripte_log \
    HK-LogHeizkurvenkontrolle     $doc_skripte_log \
    HK-LoggingHeizkurvenkontrolle $doc_skripte_log \
    HK-RäumeHeizkurvenkontrolle   $doc_dev_raeume_hkk \
    HK1-CD-OrganisationsId        $doc_skripte_cd \
    HK1-CD-Token                  $doc_skripte_cd \
    HK1-CT-Gemeindename           $doc_skripte_ct \
    HK1-CT-Token                  $doc_skripte_ct \
    HK1-GK-API-Key                $doc_skripte_gk \
    HK1-GK-Kalender-ID            $doc_skripte_gk \
    HK1-ICS-Url                   $doc_skripte_ics \
    HK1-Log                       $doc_skripte_log \
    HK1-Logging                   $doc_skripte_log \
    HK1-R-Liste                   $doc_dev_rliste \
    HK1-Schaltliste               $doc_dev_sl \
    HK1-Vorlaufzeit               $doc_dev_vlz1 \
    HK2-Log                       $doc_skripte_log \
    HK2-Logging                   $doc_skripte_log \
    HK2-A.Temp.Grenze             $doc_skripte_s2 \
    HK2-Aussentemperatur          $doc_skripte_s2 \
    HK2-Grundtemperatur           $doc_skripte_s2 \
    HK2-Hand-Grundtemp            $doc_skripte_s2 \
    HK2-Hand-Temp                 $doc_skripte_s2 \
    HK2-HKG-Liste                 $doc_dev_hkgl \
    HK2-Kurve                     $doc_dev_kurve  \
    HK2-Kurvenversatz             $doc_skripte_s2 \
    HK2-VorzeitAus                $doc_skripte_s2 \
    HK2-Schaltzeiten               $doc_dev_vlz2 \
    HK2-HKK-Zieltemperatur         $doc_awh_kurve \
]

proc lookup_doc_url {name doc_links_var} {
    upvar $doc_links_var dl
    set idx [lsearch $dl $name]
    if {$idx >= 0 && ($idx % 2) == 0} { return [lindex $dl [expr {$idx+1}]] }
    if {[string match "HK-R*umeHeizkurvenkontrolle" $name]} {
        set idx [lsearch $dl "HK-RäumeHeizkurvenkontrolle"]
        if {$idx >= 0 && ($idx % 2) == 0} { return [lindex $dl [expr {$idx+1}]] }
    }
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
    V  "Variable (V)"
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

proc render_schaltliste {val} {
    if {[string equal $val ""]} {
        return "<em>(leer)</em>"
    }
    # Format je Eintrag: ResID;Start;Ende;Steuerung;Modus;
    # Einträge folgen direkt hintereinander, jeder endet mit ;
    # Split liefert am Ende leere Elemente -> filtern
    set fields [split $val ";"]
    set clean {}
    foreach f $fields {
        if {![string equal $f ""]} { lappend clean $f }
    }
    set n [llength $clean]
    if {$n == 0 || ($n % 5) != 0} {
        return [htmlquote $val]
    }
    set html "<table class=\"hk-table hk-table-inline\">\n"
    append html "  <tr><th>ID</th><th>Start</th><th>Ende</th><th>Steuerung</th><th>Modus</th></tr>\n"
    set i 0
    while {$i < $n} {
        set rid   [lindex $clean $i]
        set start [lindex $clean [expr {$i+1}]]
        set ende  [lindex $clean [expr {$i+2}]]
        set steu  [lindex $clean [expr {$i+3}]]
        set modus [lindex $clean [expr {$i+4}]]

        append html "  <tr>"
        append html "<td>[htmlquote $rid]</td>"
        append html "<td>[htmlquote $start]</td>"
        append html "<td>[htmlquote $ende]</td>"
        append html "<td>[htmlquote $steu]</td>"
        append html "<td>[htmlquote $modus]</td>"
        append html "</tr>\n"
        set i [expr {$i+5}]
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
    append html "  <tr><th>Raum-Systemvariable(n)</th></tr>\n"
    foreach entry $entries {
        if {[string equal $entry ""]} { continue }
        append html "  <tr><td>[htmlquote $entry]</td></tr>\n"
    }
    append html "</table>\n"
    return $html
}

proc render_vlzliste {val} {
    set val [string trim $val]
    if {[string equal $val ""] || [string equal $val "???"]} {
        return "<em>(leer)</em>"
    }
    set entries [split $val "~"]
    set clean {}
    foreach e $entries {
        if {![string equal $e ""]} { lappend clean $e }
    }
    if {[llength $clean] == 0} { return "<em>(leer)</em>" }
    set html "<table class=\"hk-table hk-table-inline\">\n"
    append html "  <tr><th>Raum</th><th>Vorlauf (min)</th><th>Heizen ab</th><th>Termin ab</th><th>Termin bis</th><th>Nachlauf (min)</th></tr>\n"
    foreach entry $clean {
        set fields [split $entry ";"]
        set rvar   [lindex $fields 0]
        set vmin   [lindex $fields 1]
        set heiab  [lindex $fields 2]
        set tab    [lindex $fields 3]
        set tbis   [lindex $fields 4]
        set nlmin  [lindex $fields 5]
        append html "  <tr>"
        append html "<td>[htmlquote $rvar]</td>"
        append html "<td>[htmlquote $vmin]</td>"
        append html "<td>[htmlquote $heiab]</td>"
        append html "<td>[htmlquote $tab]</td>"
        append html "<td>[htmlquote $tbis]</td>"
        append html "<td>[htmlquote $nlmin]</td>"
        append html "</tr>\n"
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
    if {[string equal $name "HK2-VorzeitAus"]}     { return 1 }
    if {[string equal $name "HK2-Kurvenversatz"]}  { return 1 }
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
        if {[string equal $name "HK1-Schaltliste"]} {
            set cell [render_schaltliste $display_val]
        } elseif {[string equal $name "HK1-R-Liste"]} {
            set cell [render_rliste $display_val]
        } elseif {[string equal $name "HK2-HKG-Liste"]} {
            set cell [render_hkgliste $display_val]
        } elseif {[string equal $name "HK2-Schaltzeiten"]} {
            set cell [render_vlzliste $display_val]
        } elseif {[string match "HK-R*umeHeizkurvenkontrolle" $name]} {
            set cell [render_hk_raeume_hkk $display_val]
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

proc decode_hkk_status {s} {
    return $s
}

proc render_hk_raeume_hkk {val} {
    if {[string equal $val ""]} { return "<em>(leer)</em>" }
    set entries [split $val "#"]
    set clean {}
    foreach e $entries {
        if {![string equal $e ""]} { lappend clean $e }
    }
    if {[llength $clean] == 0} { return "<em>(leer)</em>" }
    set tooltip "Bit 0=Heizung an, Bit 1=Zieltemperatur erreicht, Bit 2=Heizung aus, Bit 3=kein Sensor (geloggt)"
    set html "<table class=\"hk-table hk-table-inline\">\n"
    append html "  <tr><th>Raumvariable</th><th title=\"[htmlquote $tooltip]\">Status &#x24D8;</th><th>Ist-Temperatur (&deg;C)</th></tr>\n"
    foreach entry $clean {
        set parts [split $entry ";"]
        set rvar  [lindex $parts 0]
        set cnt   [lindex $parts 1]
        set temp  [lindex $parts 2]
        catch {set temp [format "%.1f" $temp]}
        set status_text [decode_hkk_status $cnt]
        append html "  <tr><td>[htmlquote $rvar]</td><td>[htmlquote $status_text]</td><td>[htmlquote $temp]</td></tr>\n"
    }
    append html "</table>\n"
    return $html
}

proc render_room_table {varlist {gt_default ""}} {
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
    append html "<th>Systemvariable</th>"
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
        append html "<td>[htmlquote $name]</td>"
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
            if {![string equal $gt_default ""]} {
                catch {set gt_fmt [format "%.1f" $gt_default]}
                append html "<td><i>[htmlquote $gt_fmt]</i> &deg;C</td>"
            } else {
                append html "<td></td>"
            }
        } else {
            catch {set gtemp [format "%.1f" $gtemp]}
            append html "<td>[htmlquote $gtemp] &deg;C</td>"
        }
        if {[string equal $vzeit ""]} {
            append html "<td></td>"
        } else {
            append html "<td>[htmlquote $vzeit] min</td>"
        }
        if {[string equal $faktor ""]} {
            append html "<td><i>1.0</i></td>"
        } else {
            append html "<td>[htmlquote $faktor]</td>"
        }
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
set hk_version "?"
catch {
    set vfh [open "/usr/local/addons/heizkalender/VERSION" r]
    gets $vfh hk_version
    close $vfh
    set hk_version [string trim $hk_version]
}
puts "Content-Type: text/html; charset=iso-8859-1\nContent-Language: de\nCache-Control: no-cache, no-store\n"
puts {<!DOCTYPE html>
<html lang="de">
<head>
  <meta charset="iso-8859-1">
  <meta name="viewport" content="width=device-width, initial-scale=1">}
puts "  <title>Systemvariablen | Heizkalender ${hk_version}</title>"
puts {  <link rel="stylesheet" href="heizkalender.css">
  <link rel="apple-touch-icon" sizes="180x180" href="apple-touch-icon.png">
  <link rel="icon" type="image/png" sizes="32x32" href="favicon-32x32.png">
  <link rel="icon" type="image/png" sizes="16x16" href="favicon-16x16.png">
  <link rel="manifest" href="site.webmanifest">
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
    <a href="hkconfig.cgi">Einstellungen</a>
    <a href="hklog.cgi">HK-Log</a>
    <a href="syslog.cgi">Syslog</a>
    <a href="sysvars.cgi" class="active">Systemvariablen</a>
  </nav>
}

puts {<fieldset><legend>Allgemein (HK-*)</legend>}
puts [render_table $vars_hk]
puts {</fieldset>}

puts {<fieldset><legend>Kalender (HK1-*)</legend>}
puts [render_table $vars_hk1]
puts {</fieldset>}

puts {<fieldset><legend>Schalten (HK2-*)</legend>}
puts [render_table $vars_hk2]
puts {</fieldset>}

puts "<fieldset><legend>R&auml;ume (HKG-Raum-*) <a href=\"${doc_dev}#hkg-raum-\" target=\"_blank\" class=\"hk-doc-link\" title=\"Dokumentation\">&#x24D8;</a></legend>"
# HK2-Grundtemperatur aus den HK2-Variablen extrahieren
set gt_default ""
set gi 0
while {$gi < [llength $vars_hk2]} {
    if {[string equal [lindex $vars_hk2 $gi] "HK2-Grundtemperatur"]} {
        set gt_default [lindex $vars_hk2 [expr {$gi+1}]]
        break
    }
    incr gi 3
}
puts [render_room_table $vars_hkg $gt_default]
puts {</fieldset>}

puts {</div>
</body>
</html>}
