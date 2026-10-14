#!/bin/tclsh
# Heizkalender-Addon: Raumübersicht mit Schaltliste
# Zielplattform: CCU3, Tcl 8.2.3
#
# Verwendete Systemvariablen:
#   HK1-Schaltliste      - Alle Heiztermine (ResID;Ein;Aus;Kapazitaet;HSFlag;...)
#   HK1-R-Liste          - Ressourcen-Namenszuordnung (ID=Name;...), positionsbasiert
#   HK2-HKG-Liste        - Zuordnung Ressource -> HKG-Raum-Variablen, positionsbasiert
#   HK2-Aussentemperatur - Gleitender Aussentemperatur-Durchschnitt fuer Vorheizzeit
#   HKG-Raum-*           - Raumvariablen (Status;Modus;Heiztyp;Wohlfuehltemp[/Grundtemp];
#                          Vorheizzeit[*Faktor];VorzeitAus[;Sensorkanal])
#
# Ablauf:
# 1. HKG-Raum-* auslesen: Status, Modus, Wohlfuehltemperatur, opt. Sensor-Kanal.
# 2. HK2-HKG-Liste + HK1-R-Liste: positionsbasiertes Mapping Variablenname -> ResID.
#    Skript 1 verwendet ebenfalls dieses positionsbasierte Mapping (nicht Namensvergleich).
# 3. HK1-Schaltliste: mit der ResID den besten Termin ermitteln
#    (laufend > naechster zukuenftiger > letzter vergangener).
# 4. Sensor-Kanal (Feld 6 der Raumvariable, optional): Ist-Temperatur und
#    Luftfeuchtigkeit direkt aus dem HomeMatic-Geraet lesen.

load tclrega.so

proc htmlquote {s} {
    set s [string map {& &amp; < &lt; > &gt; \" &quot;} $s]
    return $s
}

# Unix-Timestamp -> "DD.MM.YYYY HH:MM"
proc format_ts {ts} {
    set t 0
    catch {set t [expr {int($ts)}]}
    if {$t <= 0} { return "" }
    return [clock format $t -format "%d.%m.%Y %H:%M"]
}

# "YYYY-MM-DD HH:MM:SS" -> Unix-Timestamp (Tcl 8.2 kompatibel)
proc parse_ts {s} {
    set s [string trim $s]
    if {[regexp {^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})$} $s _ y mo d h mi sec]} {
        set t 0
        catch {set t [clock scan "${mo}/${d}/${y} ${h}:${mi}:${sec}"]}
        return $t
    }
    return 0
}

proc format_cap {cap wtemp} {
    set deg "&deg;"
    set c [string trim $cap]
    if {[string equal $c "-2"]} { return "EIN (dauerhaft)" }
    if {[string equal $c "-1"]} { return "AUS (dauerhaft)" }
    if {[string equal $c "-3"]} { return "Reset" }
    if {[string equal $c "0"]} {
        if {![string equal $wtemp ""]} {
            set t 0.0
            catch {set t [expr {double($wtemp)}]}
            if {$t > 0} { return "[format "%.1f" $t] ${deg}C" }
        }
        return "Normaltemperatur"
    }
    set t 0.0
    catch {set t [expr {double($c)}]}
    if {$t > 0} { return "[format "%.1f" $t] ${deg}C" }
    return $c
}

proc format_hsflag {flag} {
    if {[string equal $flag "H"]}  { return "Heizen" }
    if {[string equal $flag "S"]}  { return "Schalten" }
    if {[string equal $flag "HS"]} { return "Heizen+Schalten" }
    return $flag
}

# ---------------------------------------------------------------------------
# Daten via ReGa laden: HK1-Schaltliste + HK1-R-Liste + HK2-HKG-Liste + HKG-Raum-Variablen
# ---------------------------------------------------------------------------
proc extract_stdout {rega_raw} {
    set raw ""
    set stdout_start [string first "STDOUT " $rega_raw]
    if {$stdout_start < 0} { return $raw }
    set brace_start [expr {$stdout_start + 7}]
    set ob [format "%c" 123]
    set cb [format "%c" 125]
    set ch0 [string index $rega_raw $brace_start]
    if {![string equal $ch0 $ob]} { return $raw }
    set depth 0
    set brace_end -1
    set rlen [string length $rega_raw]
    set j $brace_start
    while {$j < $rlen} {
        set ch [string index $rega_raw $j]
        if {[string equal $ch $ob]} {
            incr depth
        } elseif {[string equal $ch $cb]} {
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
    return $raw
}

set rega_script {
    string result = "";
    var sv1 = dom.GetObject("HK1-Schaltliste");
    var sv2 = dom.GetObject("HK1-R-Liste");
    var sv3 = dom.GetObject("HK2-Aussentemperatur");
    var sv4 = dom.GetObject("HK2-HKG-Liste");
    string sl = "";
    string rl = "";
    string at = "";
    string hkgl = "";
    if (sv1) { sl = sv1.Value(); }
    if (sv2) { rl = sv2.Value(); }
    if (sv3) { at = sv3.Value(); }
    if (sv4) { hkgl = sv4.Value(); }
    result = sl # "\n===SL===\n" # rl # "\n===RL===\n" # at # "\n===AT===\n" # hkgl # "\n===HKG===\n";
    string id;
    foreach(id, dom.GetObject(ID_SYSTEM_VARIABLES).EnumUsedIDs()) {
        var sv = dom.GetObject(id);
        if (!sv) { continue; }
        string name = sv.Name();
        if (name.StartsWith("HKG-Raum-")) {
            result = result # name # "\t" # sv.Value() # "\n";
        }
    }
    result = result # "===TEMPS===\n";
    foreach(id, dom.GetObject(ID_SYSTEM_VARIABLES).EnumUsedIDs()) {
        var sv = dom.GetObject(id);
        if (!sv) { continue; }
        string name = sv.Name();
        if (name.StartsWith("HKG-Raum-")) {
            string val = sv.Value();
            string sensor = val.StrValueByIndex(";", 6);
            if (sensor != "") {
                var ch = dom.GetObject(sensor);
                if (ch) {
                    string dpid2;
                    foreach(dpid2, ch.DPs().EnumUsedIDs()) {
                        var dp = dom.GetObject(dpid2);
                        if (dp) {
                            string dpname = dp.Name();
                            if (dpname.EndsWith(".TEMPERATURE")) {
                                result = result # name # "\tT\t" # dp.Value() # "\n";
                            }
                            if (dpname.EndsWith(".ACTUAL_TEMPERATURE")) {
                                result = result # name # "\tT\t" # dp.Value() # "\n";
                            }
                            if (dpname.EndsWith(".HUMIDITY")) {
                                result = result # name # "\tH\t" # dp.Value() # "\n";
                            }
                        }
                    }
                }
            }
        }
    }
    WriteLine(result);
}

set raw [extract_stdout [rega_script $rega_script]]

# Sechs Abschnitte trennen
set sl_sep    "\n===SL===\n"
set rl_sep    "\n===RL===\n"
set at_sep    "\n===AT===\n"
set hkg_sep   "\n===HKG===\n"
set temp_sep  "\n===TEMPS===\n"
set schaltliste_raw ""
set rliste_raw ""
set aussentemp_raw ""
set hkgliste_raw ""
set raumvars_raw ""
set temps_raw ""

set p1 [string first $sl_sep $raw]
if {$p1 >= 0} {
    set schaltliste_raw [string range $raw 0 [expr {$p1 - 1}]]
    set rest [string range $raw [expr {$p1 + [string length $sl_sep]}] end]
    set p2 [string first $rl_sep $rest]
    if {$p2 >= 0} {
        set rliste_raw [string range $rest 0 [expr {$p2 - 1}]]
        set rest2 [string range $rest [expr {$p2 + [string length $rl_sep]}] end]
        set p3 [string first $at_sep $rest2]
        if {$p3 >= 0} {
            set aussentemp_raw [string trim [string range $rest2 0 [expr {$p3 - 1}]]]
            set rest3 [string range $rest2 [expr {$p3 + [string length $at_sep]}] end]
            set p4 [string first $hkg_sep $rest3]
            if {$p4 >= 0} {
                set hkgliste_raw [string trim [string range $rest3 0 [expr {$p4 - 1}]]]
                set rest4 [string range $rest3 [expr {$p4 + [string length $hkg_sep]}] end]
                set p5 [string first $temp_sep $rest4]
                if {$p5 >= 0} {
                    set raumvars_raw [string range $rest4 0 [expr {$p5 - 1}]]
                    set temps_raw    [string range $rest4 [expr {$p5 + [string length $temp_sep]}] end]
                } else {
                    set raumvars_raw $rest4
                }
            } else {
                set p5 [string first $temp_sep $rest3]
                if {$p5 >= 0} {
                    set raumvars_raw [string range $rest3 0 [expr {$p5 - 1}]]
                    set temps_raw    [string range $rest3 [expr {$p5 + [string length $temp_sep]}] end]
                } else {
                    set raumvars_raw $rest3
                }
            }
        }
    }
}

# ---------------------------------------------------------------------------
# Positionsbasiertes Mapping: HKG-Raum-Variablenname -> ResID
#
# HK2-HKG-Liste und HK1-R-Liste sind positionsbasiert gekoppelt (wie in Skript 1).
# Erster Durchlauf: Hauptraeume (erster Variablenname vor "+") eintragen.
# Zweiter Durchlauf: Gruppenraeume ("+"-Teil) nur eintragen, wenn sie noch
# nicht als Hauptraum eingetragen sind -- so bekommt z.B. UG-Buero seinen
# eigenen Termin (als Hauptraum), und zeigt zusaetzlich den Termin des
# Hauptraums wenn er nur als Gruppenraum gebucht wird.
# ---------------------------------------------------------------------------

# HK1-R-Liste -> geordnete Liste der ResIDs (ohne Namen)
set rid_list {}
foreach entry [split $rliste_raw ";"] {
    set entry [string trim $entry]
    if {[string equal $entry ""]} { continue }
    set eqpos [string first "=" $entry]
    if {$eqpos >= 0} {
        lappend rid_list [string range $entry 0 [expr {$eqpos-1}]]
    } else {
        lappend rid_list $entry
    }
}

# Erster Durchlauf: nur Hauptraeume eintragen
set varname2rid {}
set pos 0
foreach hkgeintrag [split $hkgliste_raw ";"] {
    set hkgeintrag [string trim $hkgeintrag]
    if {![string equal $hkgeintrag ""]} {
        set rid [lindex $rid_list $pos]
        if {![string equal $rid ""]} {
            set hauptraum [string trim [lindex [split $hkgeintrag "+"] 0]]
            if {![string equal $hauptraum ""]} {
                lappend varname2rid $hauptraum $rid
            }
        }
    }
    incr pos
}

# Zweiter Durchlauf: Gruppenraeume eintragen, sofern noch nicht als Hauptraum vorhanden
set pos 0
foreach hkgeintrag [split $hkgliste_raw ";"] {
    set hkgeintrag [string trim $hkgeintrag]
    if {![string equal $hkgeintrag ""]} {
        set rid [lindex $rid_list $pos]
        if {![string equal $rid ""]} {
            foreach gruppenraum [lrange [split $hkgeintrag "+"] 1 end] {
                set gruppenraum [string trim $gruppenraum]
                if {[string equal $gruppenraum ""]} { continue }
                set already [lsearch $varname2rid $gruppenraum]
                if {$already < 0} {
                    lappend varname2rid $gruppenraum $rid
                }
            }
        }
    }
    incr pos
}

proc lookup_rid_by_varname {varname varname2rid_var} {
    upvar $varname2rid_var vr
    set idx [lsearch $vr $varname]
    if {$idx >= 0 && ($idx % 2) == 0} { return [lindex $vr [expr {$idx + 1}]] }
    return ""
}

# ---------------------------------------------------------------------------
# Schaltliste parsen: ResID -> Liste von Eintraegen {ein aus cap aktiv}
# Format: RId;Ein;Aus;cap;HSFlag; (Eintraege direkt aneinandergehaengt, 5 Felder)
# ---------------------------------------------------------------------------
set now [clock seconds]
set sl_by_rid {}

set sl_fields [split $schaltliste_raw ";"]
set sl_len [llength $sl_fields]
set i 0
while {[expr {$i + 4}] < $sl_len} {
    set resid [string trim [lindex $sl_fields $i]]
    set ein   [string trim [lindex $sl_fields [expr {$i + 1}]]]
    set aus   [string trim [lindex $sl_fields [expr {$i + 2}]]]
    set cap   [string trim [lindex $sl_fields [expr {$i + 3}]]]
    incr i 5
    if {[string equal $resid ""]} { continue }
    set ein_i 0
    set aus_i 0
    catch {set ein_i [parse_ts $ein]}
    catch {set aus_i [parse_ts $aus]}
    set aktiv 0
    if {$ein_i <= $now && $aus_i >= $now} { set aktiv 1 }
    set existing {}
    set eidx [lsearch $sl_by_rid $resid]
    if {$eidx >= 0 && ($eidx % 2) == 0} {
        set existing [lindex $sl_by_rid [expr {$eidx + 1}]]
        lset sl_by_rid [expr {$eidx + 1}] [linsert $existing end [list $ein_i $aus_i $cap $aktiv]]
    } else {
        lappend sl_by_rid $resid [list [list $ein_i $aus_i $cap $aktiv]]
    }
}

# Besten Eintrag fuer einen Raum ermitteln: aktiv > naechster zukuenftiger > letzter vergangener
proc best_entry {rid sl_by_rid_var} {
    upvar $sl_by_rid_var sb
    set idx [lsearch $sb $rid]
    if {$idx < 0 || ($idx % 2) != 0} { return {} }
    set entries [lindex $sb [expr {$idx + 1}]]
    set best_aktiv {}
    set best_next  {}
    set best_next_ein -1
    set best_past  {}
    set best_past_aus -1
    foreach e $entries {
        set ein_i  [lindex $e 0]
        set aus_i  [lindex $e 1]
        set aktiv  [lindex $e 3]
        if {$aktiv} {
            set best_aktiv $e
        } elseif {$ein_i > [clock seconds]} {
            if {$best_next_ein < 0 || $ein_i < $best_next_ein} {
                set best_next $e
                set best_next_ein $ein_i
            }
        } else {
            if {$aus_i > $best_past_aus} {
                set best_past $e
                set best_past_aus $aus_i
            }
        }
    }
    if {[llength $best_aktiv] > 0} { return $best_aktiv }
    if {[llength $best_next]  > 0} { return $best_next  }
    return $best_past
}

# ---------------------------------------------------------------------------
# Ist-Temperaturen und Luftfeuchtigkeit parsen
# Format: HKG-Raum-XYZ \t T|H \t Wert
# ---------------------------------------------------------------------------
set ist_temps {}
set ist_humi  {}
foreach line [split $temps_raw "\n"] {
    set line [string trim $line]
    if {[string equal $line ""]} { continue }
    set parts [split $line "\t"]
    if {[llength $parts] < 3} { continue }
    set varname [lindex $parts 0]
    set typ     [lindex $parts 1]
    set tval    [lindex $parts 2]
    if {[string equal $typ "T"]} { lappend ist_temps $varname $tval }
    if {[string equal $typ "H"]} { lappend ist_humi  $varname $tval }
}

proc lookup_isttemp {rname ist_temps_var} {
    upvar $ist_temps_var it
    set idx [lsearch $it $rname]
    if {$idx >= 0 && ($idx % 2) == 0} { return [lindex $it [expr {$idx + 1}]] }
    return ""
}

# ---------------------------------------------------------------------------
# HKG-Raum-Variablen parsen
# ---------------------------------------------------------------------------
set raeume {}
foreach line [split $raumvars_raw "\n"] {
    set line [string trim $line]
    if {[string equal $line ""]} { continue }
    set parts [split $line "\t"]
    if {[llength $parts] < 2} { continue }
    set varname [lindex $parts 0]
    set val     [lindex $parts 1]
    set fields [split $val ";"]
    set status  [string trim [lindex $fields 0]]
    set modus   [string trim [lindex $fields 1]]
    set tempfeld [string trim [lindex $fields 3]]
    set wtemp $tempfeld
    set slashpos [string first "/" $tempfeld]
    if {$slashpos >= 0} { set wtemp [string range $tempfeld 0 [expr {$slashpos - 1}]] }
    lappend raeume [list $varname $status $modus $wtemp]
}
set raeume [lsort -index 0 $raeume]

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
puts "Content-Type: text/html; charset=iso-8859-1\nContent-Language: de\n"
puts {<!DOCTYPE html>
<html lang="de">
<head>
  <meta charset="iso-8859-1">
  <meta name="viewport" content="width=device-width, initial-scale=1">}
puts "  <title>Heizkalender ${hk_version}: Raum&uuml;bersicht</title>"
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
    <h1>Heizkalender: Raum&uuml;bersicht</h1>
  </div>
  <nav class="hk-nav">
    <a href="index.cgi">Raum&uuml;bersicht</a>
    <a href="hkkurve.cgi">Heizkurve</a>
    <a href="hkconfig.cgi">Einstellungen</a>
    <a href="hklog.cgi">HK-Log</a>
    <a href="syslog.cgi">Systemlog</a>
    <a href="sysvars.cgi">Systemvariablen</a>
  </nav>}

set deg "&deg;"
set aussentemp_str ""
if {![string equal $aussentemp_raw ""]} {
    set at 0.0
    catch {set at [expr {double($aussentemp_raw)}]}
    set aussentemp_str "[format "%.1f" $at] ${deg}C"
}

if {![string equal $aussentemp_str ""]} {
    puts "  <p class=\"hk-hint\">Au&szlig;entemperatur f&uuml;r Vorheizzeit-Berechnung (gleitender Durchschnitt): <strong>$aussentemp_str</strong></p>"
}

if {[llength $raeume] == 0} {
    puts {  <p class="hk-empty">Keine Raum-Systemvariablen (HKG-Raum-*) gefunden.</p>}
} else {
    puts {  <div class="hk-table-scroll"><table class="hk-table hk-schaltliste-table">}
    puts {    <colgroup>
      <col class="col-sl-status">
      <col class="col-sl-raum">
      <col class="col-sl-modus">
      <col class="col-sl-isttemp">
      <col class="col-sl-humi">
      <col class="col-sl-ein">
      <col class="col-sl-aus">
      <col class="col-sl-temp">
    </colgroup>}
    puts {    <tr><th>Status</th><th>Raum</th><th>Modus</th><th>Ist-Temp.</th><th>Luftfeuchte</th><th>Termin ab</th><th>Termin bis</th><th>Wohlf&uuml;hltemperatur</th></tr>}

    foreach r $raeume {
        set varname [lindex $r 0]
        set status  [lindex $r 1]
        set modus   [lindex $r 2]
        set wtemp   [lindex $r 3]
        set rname   [string range $varname 9 end]

        set rid [lookup_rid_by_varname $varname varname2rid]
        set entry {}
        if {![string equal $rid ""]} {
            set entry [best_entry $rid sl_by_rid]
        }

        set rowclass ""
        if {[string equal $status "1"]} {
            set rowclass " class=\"hk-sl-aktiv\""
            set status_cell {<span class="hk-sl-status-aktiv" title="wird gerade geheizt">&#9632;</span>}
        } else {
            set status_cell {<span class="hk-sl-status-keintermin" title="nicht heizend">&#8212;</span>}
        }
        set ein_str ""
        set aus_str ""
        set cap_str ""

        if {[llength $entry] > 0} {
            set ein_i [lindex $entry 0]
            set aus_i [lindex $entry 1]
            set cap   [lindex $entry 2]
            set ein_str [format_ts $ein_i]
            set aus_str [format_ts $aus_i]
            set cap_str [format_cap $cap $wtemp]
        }

        set isttemp_raw [lookup_isttemp $varname ist_temps]
        set isttemp_str ""
        if {![string equal $isttemp_raw ""]} {
            set t 0.0
            catch {set t [expr {double($isttemp_raw)}]}
            set isttemp_str "[format "%.1f" $t] ${deg}C"
        }
        set isttemp_raw2 [lookup_isttemp $varname ist_humi]
        set humi_str ""
        if {![string equal $isttemp_raw2 ""]} {
            set h 0.0
            catch {set h [expr {double($isttemp_raw2)}]}
            if {$h > 0} { set humi_str "[format "%.0f" $h] %" }
        }
        set wtemp_str ""
        if {![string equal $wtemp ""]} {
            set wt 0.0
            catch {set wt [expr {double($wtemp)}]}
            if {$wt > 0} { set wtemp_str "[format "%.1f" $wt] ${deg}C" }
        }

        set modus_str [format_hsflag $modus]
        puts "    <tr${rowclass}><td class=\"hk-sl-status-cell\">$status_cell</td><td>[htmlquote $rname]</td><td>[htmlquote $modus_str]</td><td>$isttemp_str</td><td>[htmlquote $humi_str]</td><td>[htmlquote $ein_str]</td><td>[htmlquote $aus_str]</td><td>$wtemp_str</td></tr>"
    }
    puts {  </table></div>}
    puts {  <fieldset class="hk-legende-fieldset">}
    puts {    <p class="hk-sl-legende"><span class="hk-sl-status-aktiv">&#9632;</span> wird gerade geheizt &nbsp;&nbsp; <span class="hk-sl-status-keintermin">&#8212;</span> nicht heizend</p>}
    puts {  </fieldset>}
}

puts {</div>
</body>
</html>}
