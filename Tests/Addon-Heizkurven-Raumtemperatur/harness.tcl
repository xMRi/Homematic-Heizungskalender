# Lokaler CGI-Harness: keine CCU-Bibliotheken, Betriebssystembefehle oder CCU-Dateien.
set source_path [lindex $argv 0]
set fixture_path [lindex $argv 1]
set env(QUERY_STRING) [lindex $argv 2]
set env(TZ) UTC
set fh [open $fixture_path r]
set synthetic_log [read $fh]
close $fh
# Lokale Tcl-Standardbibliothek vor den Sicherheitsmocks lazy initialisieren.
# Beide tatsächlich verwendeten Formatmuster benötigen danach keine Dateizugriffe.
clock format 1795435200 -format "%Y-%m-%d" -gmt 1
clock format 1795435200 -format "%Y-%m-%d %H:%M:%S" -gmt 1

rename load original_load
proc load {args} {
    if {![string equal $args "tclrega.so"]} { error "Unerwartetes load: $args" }
}
proc rega_script {script} {
    return {STDOUT {HKG-Raum-Saal
HKG-Raum-Nebenraum
HKG-Raum-Alt
HKG-Raum-A<&"
ZS:-45;-20;5;15
} result {}}
}
proc rega_exec {args} { error "Unerwartetes rega_exec" }
rename exec original_exec
proc exec {args} {
    if {![string equal $args {grep -h HK-LogHeizkurvenkontrolle /media/usb0/HK-Log_2026-11-23.log}]} {
        error "Unerwartetes exec: $args"
    }
    return $::synthetic_log
}
rename file original_file
proc file {subcommand args} {
    if {[string equal $subcommand "isdirectory"] && [string equal $args "/media/usb0"]} { return 1 }
    if {[string equal $subcommand "tail"]} { return [eval original_file tail $args] }
    error "Dateizugriff gesperrt: $subcommand $args"
}
rename glob original_glob
proc glob {args} {
    if {![string equal $args {-nocomplain /media/usb0/HK-Log_*.log}]} { error "Unerwartetes glob: $args" }
    return {/media/usb0/HK-Log_2026-11-23.log}
}
rename open original_open
proc open {args} { error "Dateizugriff gesperrt: $args" }
rename clock original_clock
proc clock {subcommand args} {
    if {[string equal $subcommand "seconds"]} { return 1795435200 }
    if {[string equal $subcommand "format"]} { return [eval original_clock format $args -gmt 1] }
    error "Unerwartetes clock: $subcommand"
}
# Die echte CGI-Quelle unverändert und vollständig ausführen.
source $source_path
