# Entwicklertest R06: fuehrt index.cgi lokal mit Stubs fuer load/rega_script aus.
# Aufruf: tclsh run_index_case.tcl <index.cgi> <jetzt-unixsekunden> <at-feld|-> <abruf-feld|-absent>
# Kein CCU-Zugriff. Lokales Tcl (8.5+) ist KEIN Nachweis fuer Tcl 8.2.3.
set cgi [lindex $argv 0]
set now [lindex $argv 1]
set at  [lindex $argv 2]
set az  [lindex $argv 3]
if {[string equal $at "-"]} { set at "" }
proc load {args} {}
rename clock _real_clock
proc clock {args} {
    global now
    if {[string equal [lindex $args 0] "seconds"]} { return $now }
    return [uplevel 1 [concat _real_clock $args]]
}
proc rega_script {s} {
    global at az
    set body "\n===SL===\n\n===RL===\n$at\n===AT===\n\n===HKG===\n\n===TEMPS===\n"
    if {![string equal $az "-absent"]} { append body "\n===ABRUF===\n$az" }
    return "xx STDOUT \{$body\n\} yy"
}
source $cgi
