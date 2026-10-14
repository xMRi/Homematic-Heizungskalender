#!/bin/tclsh
# Heizkalender-Addon: Download einer HK-Log-Datei vom USB-Stick
# Zielplattform: CCU3, Tcl 8.2.3

set usb_dir "/media/usb1"
set file_param ""

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
}

if {[string equal $file_param ""]} {
    puts "Content-Type: text/plain; charset=utf-8\n"
    puts "Fehler: Kein gueltiger Dateiname angegeben."
} else {
    set fpath "$usb_dir/$file_param"
    if {![file exists $fpath]} {
        puts "Content-Type: text/plain; charset=utf-8\n"
        puts "Fehler: Datei nicht gefunden: $file_param"
    } else {
        puts "Content-Type: text/plain; charset=iso-8859-1"
        puts "Content-Disposition: attachment; filename=\"$file_param\""
        puts ""
        set fh [open $fpath r]
        while {[gets $fh line] >= 0} {
            puts $line
        }
        close $fh
    }
}
