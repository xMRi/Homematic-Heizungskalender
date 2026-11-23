"""Kleine Monats-/Wochenkorrektur: Referenzwerte und Quellvergleich, kein HSC."""
import calendar
import difflib
import re
import subprocess
import unittest
from datetime import datetime, timedelta, timezone
from pathlib import Path
from zoneinfo import ZoneInfo

ROOT = Path(__file__).resolve().parents[2]
ZONE = ZoneInfo('Europe/Berlin')
DAYS = ['MO','TU','WE','TH','FR','SA','SU']


def local(text):
    return datetime.fromisoformat(text).replace(tzinfo=ZONE)


def position(year, month, ordinal, weekday):
    maximum = calendar.monthrange(year, month)[1]
    first = (datetime(year, month, 1).weekday() + 1) % 7
    target = (weekday + 1) % 7
    if ordinal > 0:
        day = 1 + (target - first + 7) % 7 + (ordinal - 1) * 7
    else:
        last = (first + maximum - 1) % 7
        day = maximum - (last - target + 7) % 7 + (ordinal + 1) * 7
    return day if 1 <= day <= maximum else None


def monthly_candidates(start, ordinal, weekday, until, count=9999):
    # Nur gezielt betroffener BYDAY-Zweig. Keine RFC-Gesamtengine.
    year, month = start.year, start.month
    found = []
    while len(found) < count and year <= until.year:
        day = position(year, month, ordinal, weekday)
        if day:
            candidate = start.replace(year=year, month=month, day=day)
            if candidate.timestamp() > until.timestamp():
                break
            found.append(candidate)
        month += 1
        if month > 12:
            month = 1
            year += 1
    return found


def stepped(start, days, tzid):
    if tzid:
        noon = start.replace(hour=12, minute=0, second=0)
        date = datetime.fromtimestamp(noon.timestamp() + days * 86400, ZONE)
        return date.replace(hour=start.hour, minute=start.minute, second=start.second)
    return datetime.fromtimestamp(start.timestamp() + days * 86400, ZONE)


class Minimal(unittest.TestCase):
    def test_month_positions_all_weekdays(self):
        for weekday in range(7):
            for ordinal in (1,2,5,-1,-2,-5):
                days = [d for d in range(1,29) if datetime(2026,2,d).weekday() == weekday]
                expected = days[ordinal - 1] if 0 < ordinal <= len(days) else (days[ordinal] if -len(days) <= ordinal < 0 else None)
                self.assertEqual(position(2026,2,ordinal,weekday), expected)
        self.assertEqual(position(2026,2,2,0),9)
        self.assertEqual(position(2026,2,-1,0),23)
        self.assertEqual(position(2026,2,2,1),10)

    def test_missing_fifth_count_and_year_change(self):
        got = monthly_candidates(local('2025-12-01T10:00:00'),2,0,local('2026-03-31T23:59:00'),3)
        self.assertEqual([x.strftime('%Y-%m-%d') for x in got],['2025-12-08','2026-01-12','2026-02-09'])
        got = monthly_candidates(local('2026-02-01T10:00:00'),5,0,local('2026-06-30T23:59:00'),2)
        self.assertEqual([x.strftime('%Y-%m-%d') for x in got],['2026-03-30','2026-06-29'])
        got = monthly_candidates(local('2026-02-01T10:00:00'),-5,0,local('2026-03-31T23:59:00'),1)
        self.assertEqual(got[0].strftime('%Y-%m-%d'),'2026-03-02')

    def test_until_candidate_adjustment_inclusive(self):
        start = local('2026-02-01T10:00:00')
        exact = local('2026-02-09T10:00:00')
        self.assertEqual(monthly_candidates(start,2,0,exact),[exact])
        self.assertEqual(monthly_candidates(start,2,0,exact-timedelta(seconds=1)),[])

    def test_weekly_intervals_with_and_without_byday(self):
        start = local('2026-10-18T10:00:00')  # Sonntag, Montag als Wochenbeginn.
        matches = []
        for days in range(16):
            date = start + timedelta(days=days)
            week = (start.weekday() + days) // 7
            if date.weekday() in (6,0) and week % 2 == 0:
                matches.append(date.strftime('%Y-%m-%d'))
        self.assertEqual(matches,['2026-10-18','2026-10-26','2026-11-01'])
        self.assertEqual(stepped(start,14,True).strftime('%Y-%m-%d %H:%M'),'2026-11-01 10:00')

    def test_tzid_daily_weekly_both_dst_changes(self):
        for start in (local('2026-10-18T10:00:00'),local('2027-03-21T10:00:00')):
            for days in (7,14):
                result = stepped(start,days,True)
                self.assertEqual(result.hour,10)
                self.assertEqual(result.date(),(start+timedelta(days=days)).date())
            # DAILY ueber die Umstellungsnacht.
            before = start + timedelta(days=6)
            self.assertEqual(stepped(before,1,True).hour,10)

    def test_unchanged_non_tzid_known_limit_not_rfc_oracle(self):
        # Bekannte Restgrenze: feste Sekunden verschieben lokale Uhrzeit.
        # Das ist KEIN fachlicher UTC-/Floating-Sollwert, nur Upstream-Regressionsschutz.
        for start in (local('2026-10-24T10:00:00'),local('2027-03-27T10:00:00')):
            self.assertEqual(stepped(start,1,False).timestamp(),start.timestamp()+86400)
            self.assertNotEqual(stepped(start,1,False).hour,10)

    def test_source_baseline_preservation_and_small_scope(self):
        source = (ROOT/'Skripte/HK-Skript 1_iCal.hsc').read_text()
        baseline = subprocess.check_output(['git','show','183a7a40a9565661a3394c49d5f1b6b395576407:Skripte/HK-Skript 1_iCal.hsc'],cwd=ROOT,text=True)
        # Exakter urspruenglicher DTSTART-/DTEND-Parser ausser dem einzelnen TZID-Flag.
        def dateblock(s):
            return s[s.index('    !// Start und Enddatum holen.'):s.index('    !// Mit der Dauer')]
        cleaned = dateblock(source).replace('    bTzidLokal = false;\n','').replace('      if (iPos >= 0) { bTzidLokal = true; }\n','')
        self.assertEqual(cleaned,dateblock(baseline))
        # UNTIL und alte Key-/BYDAY-Auswertung wortgleich, keine neue Matrix/WKST.
        a='      integer iInterval = 1;'
        b='      !// Schleife um die Daten zu erzeugen.'
        self.assertEqual(source[source.index(a):source.index(b)],baseline[baseline.index(a):baseline.index(b)])
        a='      !// Auf nicht erlaubte Schlüsselwörter prüfen.'
        b='    !// Termine nur übernehmen wenn sie im Zeitrahmen liegen'
        self.assertEqual(source[source.index(a):source.index(b)],baseline[baseline.index(a):baseline.index(b)])
        self.assertIn('if (bTzidLokal)',source)
        self.assertIn('else { testDatum = testDatum + (86400 * tagesSchritt); }',source)
        self.assertIn('tagesSchritt = 7 * iInterval;',source)
        self.assertLess(source.index('if (testDatum > timeUntil) { break; }'),source.index('iCount = iCount + 1;'))
        for feature in ('rBad','rCivil','rCountMax','Kandidatenlimit','WKST=','TZID=Europe/Berlin','DURATION nicht'):
            self.assertNotIn(feature,source)
        self.assertEqual(source.count('!// TT:  2026-11-22'),1)
        helpers=('bTzidLokal','tageSeitStart','startWochenTag','serienWoche','tagesSchritt','kalenderMittag','monatsText','tagesText')
        for name in helpers:
            self.assertEqual(len(re.findall(r'\b(?:integer|string|boolean)\s+'+name+r'\b',source)),1)
            self.assertLess(source.index(name+';'),source.index('foreach(RIdEintrag'))
        # Alle nicht beauftragten Bereiche bytegetreu zum Upstream.
        sm=difflib.SequenceMatcher(None,baseline.splitlines(),source.splitlines(),autojunk=False)
        allowed=((2,3),(24,24),(178,178),(259,259),(267,267),(387,387),(429,429),(436,477),(482,482),(492,498),(502,502))
        for tag,i,j,k,l in sm.get_opcodes():
            if tag != 'equal':
                self.assertTrue(any(lo <= i+1 and j <= hi for lo,hi in allowed),(tag,i+1,j,source.splitlines()[k:l]))

    def test_brackets_and_original_loop_harness(self):
        source=(ROOT/'Skripte/HK-Skript 1_iCal.hsc').read_text()
        stack=[]
        for line in source.splitlines():
            line=re.sub(r'"[^"]*"','""',line.split('!//')[0])
            for char in line:
                if char in '({': stack.append(char)
                elif char in ')}': self.assertEqual(stack.pop(),{')':'(', '}':'{'}[char])
        self.assertEqual(stack,[])
        block=source[source.index('      !// Schleife um die Daten zu erzeugen.'):source.index('      startDatum = testDatum;')]
        helpers=source[source.index('boolean bTzidLokal;'):source.index('string RIdEintrag;')]
        harness='''!// Isolierter Test, keine CCU-Ausfuehrung erfolgt. Nur konstante Eingaben.
boolean DEBUG=false;
boolean bMatch=false;
integer versatzGMT=3600;
integer startDatum=("2026-02-01 10:00:00").ToTime().ToInteger();
integer dauer=3600;
integer minDatum=("2026-02-09 09:00:00").ToTime().ToInteger();
integer maxDatum=("2026-02-09 12:00:00").ToTime().ToInteger();
integer timeUntil=maxDatum;
integer iInterval=1;
integer iMaxCount=3;
string strFreq="MONTHLY";
string strBYDAY="BYDAY=2MO";
string strTemp;
'''+helpers+'bTzidLokal=true;\n'+block+'WriteLine("MATCH=" # bMatch # " START=" # testDatum # " COUNT=" # iCount);\n'
        for forbidden in ('dom.','system.Exec','logObj.State'):
            self.assertNotIn(forbidden,harness)
        (ROOT/'build').mkdir(exist_ok=True)
        (ROOT/'build/isolated-parser.hsc').write_text(harness)


if __name__=='__main__': unittest.main(verbosity=2)
