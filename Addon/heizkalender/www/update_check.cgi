#!/bin/tclsh
# Heizkalender-Addon: Update-Check-CGI
# Zielplattform: CCU3, Tcl 8.2.3
#
# Protokoll (CCU WebUI):
#   ?cmd=check_version&version=<installiert>  -> neueste Version oder "n/a"
#   ?cmd=download&version=<installiert>       -> Redirect zur Releases-Seite

set checkURL    "https://raw.githubusercontent.com/xMRi/Homematic-Heizungskalender/main/Addon/VERSION"
set downloadURL "https://github.com/xMRi/Homematic-Heizungskalender/releases"

set cmd ""
catch {
    set pairs [split $env(QUERY_STRING) &]
    foreach pair $pairs {
        if {[string equal $pair "cmd=download"]}       { set cmd "download" }
        if {[string equal $pair "cmd=check_version"]}  { set cmd "check_version" }
    }
}

if {[string equal $cmd "download"]} {
    puts -nonewline "Content-Type: text/html; charset=utf-8\r\n\r\n"
    puts -nonewline "<html><head><meta http-equiv='refresh' content='0; url=$downloadURL' /></head><body></body></html>"
} else {
    puts -nonewline "Content-Type: text/plain; charset=utf-8\r\n\r\n"
    catch {
        set newversion [exec /usr/bin/wget -qO- --no-check-certificate $checkURL]
    }
    if {[info exists newversion]} {
        puts $newversion
    } else {
        puts "n/a"
    }
}
