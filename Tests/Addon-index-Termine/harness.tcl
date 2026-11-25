# Lokaler CGI-Test, keine ReGa-Verbindung. Eingabebody kommt über stdin.
set cgi [lindex $argv 0]
set body [read stdin]
set fixed_now [clock scan "11/25/2026 12:00:00"]
proc load {args} {}
rename clock real_clock
proc clock {args} {
    global fixed_now
    if {[string equal [lindex $args 0] "seconds"]} { return $fixed_now }
    return [uplevel 1 [concat real_clock $args]]
}
proc rega_script {script} {
    global body
    return "STDOUT \{$body\} sessionId {}"
}
source $cgi
