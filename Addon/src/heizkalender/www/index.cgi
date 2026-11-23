#!/bin/tclsh
# Heizkalender-Addon: Raumübersicht mit Schaltliste
# Zielplattform: CCU3, Tcl 8.2.3
#
# Verwendete Systemvariablen:
#   HK1-Schaltliste      - Alle Heiztermine (ResID;Ein;Aus;Kapazitaet;HSFlag;...)
#   HK1-R-Liste          - Ressourcen-Namenszuordnung (ID=Name;...), positionsbasiert
#   HK2-HKG-Liste        - Zuordnung Ressource -> HKG-Raum-Variablen, positionsbasiert
#   HK2-Aussentemperatur - Gleitender Aussentemperatur-Durchschnitt fuer Vorheizzeit
#   HK2-Schaltzeiten     - Berechnete Vorlauf- und Schaltzeiten je Ressource (optional,
#                          geschrieben von Skript 2; Spalten "Vorlauf" und "Heizen ab")
#   HKG-Raum-*           - Raumvariablen (Status;Modus;Heiztyp;Wohlfuehltemp[/Grundtemp];
#                          Vorheizzeit[*Faktor];VorzeitAus[;Sensorkanal])
#
# Ablauf:
# 1. HKG-Raum-* auslesen: Status, Modus, Wohlfuehltemperatur, opt. Sensor-Kanal.
# 2. HK2-HKG-Liste + HK1-R-Liste: positionsbasiertes Mapping Variablenname -> ResID.
#    Skript 1 verwendet ebenfalls dieses positionsbasierte Mapping (nicht Namensvergleich).
# 3. HK1-Schaltliste: mit der ResID den besten Termin ermitteln
#    (laufend > naechster zukuenftiger > letzter vergangener).
# 4. HK2-Schaltzeiten (optional): falls vorhanden, Vorlaufzeit und Einschaltzeitpunkt
#    je Raumvariablenname nachschlagen und in den Spalten "Vorlauf" und "Heizen ab" anzeigen.
#    Pro Raum koennen mehrere Eintraege vorkommen (Gruppenraeume); es wird der Eintrag
#    mit dem kleinsten HeizenAb gewaehlt. Ist die Variable nicht vorhanden, entfallen
#    diese beiden Spalten komplett.
# 5. Sensor-Kanal (Feld 6 der Raumvariable, optional): Ist-Temperatur und
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

proc format_termin {ein_str aus_str} {
    if {[string equal $ein_str ""] && [string equal $aus_str ""]} { return "" }
    if {[string equal $aus_str ""]} { return [htmlquote $ein_str] }
    return "[htmlquote $ein_str] &ndash; [htmlquote $aus_str]"
}

proc format_hsflag {flag} {
    if {[string equal $flag "H"]}  { return "Heizen" }
    if {[string equal $flag "S"]}  { return "Schalten" }
    if {[string equal $flag "HS"]} { return "Heizen+Schalten" }
    if {[string equal $flag "V"]}  { return "Variable" }
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
    var sv3a = dom.GetObject("HK2-Aussentemperatur-Aktuell");
    var sv3m = dom.GetObject("HK2-Aussentemperatur-Prognose-Min");
    var sv4 = dom.GetObject("HK2-HKG-Liste");
    var sv5 = dom.GetObject("HK2-Schaltzeiten");
    string sl = "";
    string rl = "";
    string at = "";
    string hkgl = "";
    string vlz = "";
    if (sv1) { sl = sv1.Value(); }
    if (sv2) { rl = sv2.Value(); }
    if (sv3) { at = sv3.Value(); }
    if (sv3a) { at = at # "\t" # sv3a.Value(); }
    if (sv3m) { at = at # "\t" # sv3m.Value(); }
    if (sv4) { hkgl = sv4.Value(); }
    if (sv5) { vlz = sv5.Value(); }
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
            string hsFlag = val.StrValueByIndex(";", 1);
            if ((hsFlag == "H") || (hsFlag == "HS")) {
                string sensor = val.StrValueByIndex(";", 6);
                if (sensor != "") {
                    var ch = dom.GetObject(sensor);
                    if (ch) {
                        var dpTemp = ch.DPByHssDP("ACTUAL_TEMPERATURE");
                        if (!dpTemp) { dpTemp = ch.DPByHssDP("TEMPERATURE"); }
                        if (dpTemp) { result = result # name # "\tT\t" # dpTemp.State() # "\n"; }
                        var dpHum = ch.DPByHssDP("HUMIDITY");
                        if (dpHum) { result = result # name # "\tH\t" # dpHum.State() # "\n"; }
                    }
                }
            }
        }
    }
    if (sv5) { result = result # "\n===VLZ===\n" # vlz; }
    var sv6 = dom.GetObject("HK2-Aussentemperatur-Abrufzeit");
    string abruf = "";
    if (sv6) { abruf = sv6.Value(); }
    result = result # "\n===ABRUF===\n" # abruf;
    WriteLine(result);
}

set rega_raw ""
if {[catch {set rega_raw [rega_script $rega_script]} err]} {
    puts "Content-Type: text/html; charset=utf-8\r\n\r\n"
    puts "<html><body><p>Fehler: ReGa nicht erreichbar. ($err)</p></body></html>"
    return
}
set raw [extract_stdout $rega_raw]

# Abrufzeit der Aussentemperatur (optional) als letzten, eigenen Abschnitt abtrennen,
# damit die uebrigen Abschnitte unveraendert ausgewertet werden.
set abruf_sep "\n===ABRUF===\n"
set abruf_raw ""
set pa [string first $abruf_sep $raw]
if {$pa >= 0} {
    set abruf_raw [string trim [string range $raw [expr {$pa + [string length $abruf_sep]}] end]]
    set raw [string range $raw 0 [expr {$pa - 1}]]
}

# Sechs Abschnitte trennen
set sl_sep    "\n===SL===\n"
set rl_sep    "\n===RL===\n"
set at_sep    "\n===AT===\n"
set hkg_sep   "\n===HKG===\n"
set temp_sep  "\n===TEMPS===\n"
set vlz_sep   "\n===VLZ===\n"
set schaltliste_raw ""
set rliste_raw ""
set aussentemp_raw ""
set hkgliste_raw ""
set raumvars_raw ""
set temps_raw ""
set vlz_raw ""
set vlz_present 0

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
                    set rest5 [string range $rest4 [expr {$p5 + [string length $temp_sep]}] end]
                    set p6 [string first $vlz_sep $rest5]
                    if {$p6 >= 0} {
                        set temps_raw [string range $rest5 0 [expr {$p6 - 1}]]
                        set vlz_raw   [string range $rest5 [expr {$p6 + [string length $vlz_sep]}] end]
                        set vlz_present 1
                    } else {
                        set temps_raw $rest5
                    }
                } else {
                    set raumvars_raw $rest4
                }
            } else {
                set p5 [string first $temp_sep $rest3]
                if {$p5 >= 0} {
                    set raumvars_raw [string range $rest3 0 [expr {$p5 - 1}]]
                    set rest5 [string range $rest3 [expr {$p5 + [string length $temp_sep]}] end]
                    set p6 [string first $vlz_sep $rest5]
                    if {$p6 >= 0} {
                        set temps_raw [string range $rest5 0 [expr {$p6 - 1}]]
                        set vlz_raw   [string range $rest5 [expr {$p6 + [string length $vlz_sep]}] end]
                        set vlz_present 1
                    } else {
                        set temps_raw $rest5
                    }
                } else {
                    set raumvars_raw $rest3
                }
            }
        }
    }
}

# ---------------------------------------------------------------------------
# Positionsbasiertes Mapping: HKG-Raum-Variablenname -> Liste von ResIDs
#
# HK2-HKG-Liste und HK1-R-Liste sind positionsbasiert gekoppelt (wie in Skript 1).
# Ein Raum kann mehrere ResIDs haben: als Hauptraum (eigene Position) und
# zusaetzlich als Gruppenraum anderer Positionen. Alle ResIDs werden gesammelt,
# damit saemtliche Termine (eigen + Gruppe) in der Uebersicht erscheinen.
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

# Mapping aufbauen: Variablenname -> Liste aller zugehoerigen ResIDs
set varname2rids {}

proc add_rid_for_varname {varname rid varname2rids_var} {
    upvar $varname2rids_var vr
    set idx [lsearch $vr $varname]
    if {$idx >= 0 && ($idx % 2) == 0} {
        set existing [lindex $vr [expr {$idx + 1}]]
        if {[lsearch $existing $rid] < 0} {
            set vr [lreplace $vr [expr {$idx + 1}] [expr {$idx + 1}] [linsert $existing end $rid]]
        }
    } else {
        lappend vr $varname [list $rid]
    }
}

set pos 0
foreach hkgeintrag [split $hkgliste_raw ";"] {
    set hkgeintrag [string trim $hkgeintrag]
    if {![string equal $hkgeintrag ""]} {
        set rid [lindex $rid_list $pos]
        if {![string equal $rid ""]} {
            foreach teil [split $hkgeintrag "+"] {
                set teil [string trim $teil]
                if {![string equal $teil ""]} {
                    add_rid_for_varname $teil $rid varname2rids
                }
            }
        }
    }
    incr pos
}

proc lookup_rids_by_varname {varname varname2rids_var} {
    upvar $varname2rids_var vr
    set idx [lsearch $vr $varname]
    if {$idx >= 0 && ($idx % 2) == 0} { return [lindex $vr [expr {$idx + 1}]] }
    return {}
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
        set sl_by_rid [lreplace $sl_by_rid [expr {$eidx + 1}] [expr {$eidx + 1}] [linsert $existing end [list $ein_i $aus_i $cap $aktiv]]]
    } else {
        lappend sl_by_rid $resid [list [list $ein_i $aus_i $cap $aktiv]]
    }
}

proc all_entries_for_rids {rids sl_by_rid_var} {
    upvar $sl_by_rid_var sb
    set result {}
    foreach rid $rids {
        set idx [lsearch $sb $rid]
        if {$idx >= 0 && ($idx % 2) == 0} {
            foreach e [lindex $sb [expr {$idx + 1}]] {
                lappend result $e
            }
        }
    }
    return [lsort -index 0 -integer $result]
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
# HK2-Schaltzeiten parsen: RaumVarName -> Liste aller {VorlaufMin HeizenAb}-Einträge
# Format: RaumVarName;VorlaufMin;HeizenAb;TerminAb;TerminBis;VorlaufzeitAusMin~...
# Pro Raum können mehrere Einträge vorkommen; lookup_vlz wählt den nächsten.
# ---------------------------------------------------------------------------
set vlz_raw [string trim $vlz_raw]
if {[string equal $vlz_raw "???"] || [string equal $vlz_raw ""]} { set vlz_raw "" }
set has_vlz $vlz_present
array set vlz_by_room_arr {}
foreach entry [split $vlz_raw "~"] {
    set entry [string trim $entry]
    if {[string equal $entry ""]} { continue }
    set fields [split $entry ";"]
    set rvar   [string trim [lindex $fields 0]]
    set vmin   [string trim [lindex $fields 1]]
    set heiab  [string trim [lindex $fields 2]]
    if {![string equal $rvar ""]} {
        lappend vlz_by_room_arr($rvar) [list $vmin $heiab]
    }
}

# Gibt den Eintrag mit dem kleinsten HeizenAb für einen Raum zurück.
# Die Reihenfolge in HK2-Schaltzeiten ist nicht garantiert chronologisch
# (Skript 2 schreibt pro Termin alle Gruppenräume, nicht pro Raum alle Termine).
proc lookup_vlz {varname vlz_by_room_var} {
    upvar $vlz_by_room_var arr
    if {![info exists arr($varname)]} { return {} }
    set best {}
    set best_t -1
    foreach e $arr($varname) {
        set t 0
        catch {set t [parse_ts [lindex $e 1]]}
        if {$t > 0 && ($best_t < 0 || $t < $best_t)} {
            set best $e
            set best_t $t
        }
    }
    return $best
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
puts "Content-Type: text/html; charset=iso-8859-1\nContent-Language: de\nCache-Control: no-cache, no-store\n"
puts {<!DOCTYPE html>
<html lang="de">
<head>
  <meta charset="iso-8859-1">
  <meta name="viewport" content="width=device-width, initial-scale=1">}
puts "  <title>Raum&uuml;bersicht | Heizkalender ${hk_version}</title>"
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
    <a href="index.cgi" class="active">Raum&uuml;bersicht</a>
    <a href="hkkurve.cgi">Heizkurve</a>
    <a href="hkrechner.cgi">Rechner</a>
    <a href="hkconfig.cgi">Einstellungen</a>
    <a href="hklog.cgi">HK-Log</a>
    <a href="syslog.cgi">Syslog</a>
    <a href="sysvars.cgi">Systemvariablen</a>
  </nav>}

set deg "&deg;"
set aussentemp_str ""
set at_akt_str ""
set at_min_str ""
if {![string equal $aussentemp_raw ""]} {
    # Tab-separiert: Durchschnitt[\tAktuell[\tMin12h]]
    set at_parts [split $aussentemp_raw "\t"]
    set at_avg 0.0
    catch {set at_avg [expr {double([lindex $at_parts 0])}]}
    set aussentemp_str "[format "%.1f" $at_avg] ${deg}C"
    if {[llength $at_parts] >= 2 && ![string equal [lindex $at_parts 1] ""]} {
        set at_a 0.0
        catch {set at_a [expr {double([lindex $at_parts 1])}]}
        set at_akt_str "[format "%.1f" $at_a] ${deg}C"
    }
    if {[llength $at_parts] >= 3 && ![string equal [lindex $at_parts 2] ""]} {
        set at_m 0.0
        catch {set at_m [expr {double([lindex $at_parts 2])}]}
        set at_min_str "[format "%.1f" $at_m] ${deg}C"
    }
}

# Letzter erfolgreicher Wetterabruf (nur Anzeige, keine Auswirkung auf die Heizung).
# Ergebnis: Text (HTML-sicher, feste Entities) und Warnkennzeichen.
set abruf_text ""
set abruf_warn 0
set abruf_ts_max 2147483647
set abruf_digits $abruf_raw
if {![regexp {^[0-9]+$} $abruf_digits]} {
    set abruf_digits ""
}
set abruf_digits [string trimleft $abruf_digits 0]
if {[string equal $abruf_raw ""] || [string equal $abruf_digits ""]} {
    # fehlend, leer oder 0
    if {[string equal $abruf_raw ""] || [regexp {^0+$} $abruf_raw]} {
        set abruf_text "Abrufzeit unbekannt"
    } else {
        set abruf_text "Abrufzeit ung&uuml;ltig"
    }
    set abruf_warn 1
} elseif {[string length $abruf_digits] > 10 || ([string length $abruf_digits] == 10 && [string compare $abruf_digits $abruf_ts_max] > 0)} {
    set abruf_text "Abrufzeit ung&uuml;ltig"
    set abruf_warn 1
} else {
    set abruf_now 0
    catch {set abruf_now [clock seconds]}
    set abruf_age [expr {$abruf_now - $abruf_digits}]
    if {$abruf_age < 0} {
        set abruf_text "Abrufzeit ung&uuml;ltig"
        set abruf_warn 1
    } else {
        set abruf_text "Letzter Wetterabruf: <strong>[format_ts $abruf_digits]</strong>"
        if {$abruf_age > 10800} {
            append abruf_text ": <strong class=\"hk-warn\">Wetterabruf veraltet</strong>"
            set abruf_warn 1
        }
    }
}

if {![string equal $aussentemp_str ""]} {
    set at_line "Au&szlig;entemperatur (gleitender Durchschnitt): <strong>$aussentemp_str</strong>"
    if {![string equal $at_akt_str ""]} {
        append at_line " / Aktuell: <strong>$at_akt_str</strong>"
    }
    if {![string equal $at_min_str ""]} {
        append at_line " / Min. Prognose 12h: <strong>$at_min_str</strong>"
    }
    append at_line " / $abruf_text"
    puts "  <p class=\"hk-hint\">${at_line}</p>"
} elseif {![string equal $abruf_raw ""]} {
    # Keine Temperatur, aber ein Abrufwert ist gesetzt: Diagnose trotzdem zeigen
    puts "  <p class=\"hk-hint\">Au&szlig;entemperatur: nicht verf&uuml;gbar / $abruf_text</p>"
}

if {[llength $raeume] == 0} {
    puts {  <p class="hk-empty">Keine Raum-Systemvariablen (HKG-Raum-*) gefunden.</p>}
} else {
    puts {  <div class="hk-table-scroll"><table class="hk-table hk-schaltliste-table hk-has-header">}
    if {$has_vlz} {
        puts {    <colgroup>
      <col class="col-sl-status">
      <col class="col-sl-raum">
      <col class="col-sl-isttemp">
      <col class="col-sl-humi">
      <col class="col-sl-vorlauf">
      <col class="col-sl-heizenab">
      <col class="col-sl-termin">
      <col class="col-sl-temp">
      <col class="col-sl-modus">
    </colgroup>}
        puts {    <tr><th>Status</th><th>Raum</th><th>Ist-Temp.</th><th>Luftfeuchte</th><th>Vorlauf</th><th>Heizen ab</th><th class="col-sl-termin">Termin</th><th>Wohlf&uuml;hltemperatur</th><th>Modus</th></tr>}
    } else {
        puts {    <colgroup>
      <col class="col-sl-status">
      <col class="col-sl-raum">
      <col class="col-sl-isttemp">
      <col class="col-sl-humi">
      <col class="col-sl-termin">
      <col class="col-sl-temp">
      <col class="col-sl-modus">
    </colgroup>}
        puts {    <tr><th>Status</th><th>Raum</th><th>Ist-Temp.</th><th>Luftfeuchte</th><th class="col-sl-termin">Termin</th><th>Wohlf&uuml;hltemperatur</th><th>Modus</th></tr>}
    }

    foreach r $raeume {
        set varname [lindex $r 0]
        set status  [lindex $r 1]
        set modus   [lindex $r 2]
        set wtemp   [lindex $r 3]
        set rname   [string range $varname 9 end]

        set rids    [lookup_rids_by_varname $varname varname2rids]
        set entries [all_entries_for_rids $rids sl_by_rid]
        set entry   {}
        if {[llength $entries] > 0} {
            set entry [lindex $entries 0]
        }

        switch -- $status {
            0 { set status_label "Aus" }
            1 { set status_label "Ein" }
            2 { set status_label "Dauer-Aus" }
            3 { set status_label "Dauer-Ein" }
            default { set status_label "Unbekannt" }
        }

        set rowclass ""
        if {[string equal $status "1"] || [string equal $status "3"]} {
            set rowclass " class=\"hk-sl-aktiv\""
            set status_cell "<td class=\"hk-sl-status-aktiv\"><span>&#9632;</span> $status_label"
        } else {
            set status_cell "<td class=\"hk-sl-status-inaktiv\"><span>&#9675;</span> $status_label"
        }
        set ein_str ""
        set aus_str ""

        if {[llength $entry] > 0} {
            set ein_i [lindex $entry 0]
            set aus_i [lindex $entry 1]
            set ein_str [format_ts $ein_i]
            set aus_str [format_ts $aus_i]
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

        # Termin-Spalte: ein - aus, bei mehreren Eintraegen als <details> aufklappbar
        if {[llength $entries] > 1} {
            set first_termin [format_termin \
                [format_ts [lindex [lindex $entries 0] 0]] \
                [format_ts [lindex [lindex $entries 0] 1]]]
            set termin_cell "<details><summary>$first_termin</summary>"
            foreach e [lrange $entries 1 end] {
                set t [format_termin [format_ts [lindex $e 0]] [format_ts [lindex $e 1]]]
                append termin_cell "<div>$t</div>"
            }
            append termin_cell "</details>"
        } elseif {[llength $entries] == 1} {
            set termin_cell [format_termin $ein_str $aus_str]
        } else {
            set termin_cell ""
        }

        set modus_str [format_hsflag $modus]
        if {$has_vlz} {
            set vlz_info [lookup_vlz $varname vlz_by_room_arr]
            set vorlauf_str ""
            set heiab_str ""
            if {[llength $vlz_info] >= 2} {
                set vmin  [lindex $vlz_info 0]
                set heiab [lindex $vlz_info 1]
                if {![string equal $vmin ""] && ![string equal $vmin "0"]} {
                    set vorlauf_str "[htmlquote $vmin]&nbsp;min"
                }
                if {![string equal $heiab ""]} {
                    set heiab_t 0
                    catch {set heiab_t [parse_ts $heiab]}
                    if {$heiab_t > 0} {
                        set heiab_str [htmlquote [format_ts $heiab_t]]
                    }
                }
            }
            puts "    <tr${rowclass}>$status_cell</td><td>[htmlquote $rname]</td><td>$isttemp_str</td><td>[htmlquote $humi_str]</td><td>$vorlauf_str</td><td>$heiab_str</td><td class=\"col-sl-termin\">$termin_cell</td><td>$wtemp_str</td><td>[htmlquote $modus_str]</td></tr>"
        } else {
            puts "    <tr${rowclass}>$status_cell</td><td>[htmlquote $rname]</td><td>$isttemp_str</td><td>[htmlquote $humi_str]</td><td class=\"col-sl-termin\">$termin_cell</td><td>$wtemp_str</td><td>[htmlquote $modus_str]</td></tr>"
        }
    }
    puts {  </table></div>}
    if {$has_vlz} {
        puts {  <div class="hk-hint">}
        puts {    <strong>Hinweis:</strong> Die Spalten &bdquo;Vorlauf&ldquo; und &bdquo;Heizen ab&ldquo;}
        puts {    werden alle 5&nbsp;Minuten neu berechnet, bis die Heizphase beginnt. Ab}
        puts {    Heizbeginn bleiben die Werte eingefroren und zeigen den tats&auml;chlichen Heizbeginn.}
        puts {  </div>}
    }
}

puts {</div>
</body>
</html>}
