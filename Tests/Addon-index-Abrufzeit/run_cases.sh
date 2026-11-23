#!/bin/sh
# Fokussierte Fallpruefung der Index-Abrufzeitzeile (lokal, ohne CCU).
cd "$(dirname "$0")" || exit 2
CGI=../../Addon/src/heizkalender/www/index.cgi
NOW='2027-01-15 08:00:00'   # Kontrollierte lokale Testzeit, TZ=UTC
fail=0
RAW=""
run() { # at az -> Ausgabe in $RAW, Rueckgabe: echter tclsh-Exitcode
  RAW=$(TZ=UTC tclsh run_index_case.tcl "$CGI" "$NOW" "$1" "$2" 2>&1)
}
t() { # name at az expected-regex
  run "$2" "$3"; rc=$?
  out=$(printf '%s\n' "$RAW" | grep 'hk-hint')
  if [ $rc -ne 0 ]; then echo "FAIL $1: tclsh exit $rc"; fail=1
  elif printf '%s' "$out" | grep -Eq "style=|&ndash;|&mdash;"; then echo "FAIL $1: Inline-Style oder Gedankenstrich: $out"; fail=1
  elif printf '%s' "$out" | grep -Eq "$4"; then echo "OK   $1: $out"; else echo "FAIL $1: $out"; fail=1; fi
}
t frisch      "5.0"          '2027-01-15 07:59:00' 'Letzter Wetterabruf: <strong>15.01.2027 07:59</strong></p>$'
t genau3h     "5.0"          '2027-01-15 05:00:00' 'Wetterabruf: <strong>15.01.2027 05:00</strong></p>$'
t veraltet    "5.0"          '2027-01-15 04:59:59' '04:59</strong>: <strong class="hk-warn">Wetterabruf veraltet</strong></p>$'
t fehlt       "5.0"          -absent        'Abrufzeit unbekannt'
t leer        "5.0"          ""             'Abrufzeit unbekannt'
t null        "5.0"          0              'Abrufzeit ung&uuml;ltig'
t text        "5.0"          abc            'Abrufzeit ung&uuml;ltig'
t negativ     "5.0"          -5             'Abrufzeit ung&uuml;ltig'
t dezimal     "5.0"          12.5           'Abrufzeit ung&uuml;ltig'
t zukunft     "5.0"          '2027-01-15 08:00:01' 'Abrufzeit ung&uuml;ltig'
t falsches_format "5.0"      '15.01.2027 07:59:00' 'Abrufzeit ung&uuml;ltig'
t invaliddate "5.0"          '2027-02-30 07:59:00' 'Abrufzeit ung&uuml;ltig'
t invalid_leapday "5.0"      '2025-02-29 07:59:00' 'Abrufzeit ung&uuml;ltig'
t leapday     "5.0"          '2024-02-29 07:59:00' 'Wetterabruf: <strong>29.02.2024 07:59</strong>.*Wetterabruf veraltet'
t epoch_null  "5.0"          '1970-01-01 00:00:00' 'Abrufzeit ung&uuml;ltig'
t epoch_negativ "5.0"        '1969-12-31 23:59:59' 'Abrufzeit ung&uuml;ltig'
t unixsekunden "5.0"         1799999940     'Abrufzeit ung&uuml;ltig'
t ueber2038   "5.0"          2147483648     'Abrufzeit ung&uuml;ltig'
t sehrlang    "5.0"          99999999999999 'Abrufzeit ung&uuml;ltig'
t html        "5.0"          '<b>&x'        'Abrufzeit ung&uuml;ltig'
t fuehrnull   "5.0"          0001799999000  'Abrufzeit ung&uuml;ltig'
t alle3       "5.0	-1.2	-3.4" '2027-01-15 07:59:00' 'Aktuell: <strong>-1.2.*Prognose 12h: <strong>-3.4.*07:59'
t nur2        "5.0	-1.2"  '2027-01-15 07:59:00' 'Aktuell: <strong>-1.2.*07:59'
t keineTemp_mitAbruf "-"     '2027-01-15 02:26:40' 'nicht verf&uuml;gbar.*: <strong class="hk-warn">Wetterabruf veraltet</strong>'
run - ""; rc=$?
if [ $rc -ne 0 ]; then echo "FAIL keineTemp_ohneAbruf: tclsh exit $rc"; fail=1
elif printf '%s\n' "$RAW" | grep -q hk-hint; then echo "FAIL keineTemp_ohneAbruf (Zeile sichtbar)"; fail=1
else echo "OK   keineTemp_ohneAbruf: keine Zeile"; fi
exit $fail
