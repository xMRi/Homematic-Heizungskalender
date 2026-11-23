#!/usr/bin/env python3
"""Lokale Addon-Installationsprüfung. Alle Installationsziele und Befehle sind isoliert."""
import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import tarfile
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
WORK = ROOT / 'build'
COMMANDS = ('mkdir', 'mount', 'cp', 'chmod', 'ln', 'readlink', 'logger', 'rm', 'rmdir', 'sync')


class InstallationTests(unittest.TestCase):
    def setUp(self):
        WORK.mkdir(exist_ok=True)
        self.area = Path(tempfile.mkdtemp(prefix='addon-installation-test-', dir=WORK))
        self.addCleanup(self.cleanup)

    def cleanup(self):
        # Ausschliesslich den selbst erzeugten relativen Testbereich entfernen.
        assert self.area.parent == WORK and self.area.name.startswith('addon-installation-test-')
        assert not self.area.is_symlink()
        shutil.rmtree(self.area)

    def install(self, fail='', wrong=False, web='symlink', unmounted=False, update=True):
        case = self.area / ('case-' + str(len(list(self.area.iterdir()))))
        case.mkdir()
        source = case / 'source'
        shutil.copytree(ROOT / 'Addon/src', source, symlinks=True)
        live = case / 'live'
        addon = live / 'addons/heizkalender'
        addon.mkdir(parents=True)
        (addon / 'www').mkdir()
        (addon / 'www/stale.txt').write_text('veraltet')
        www = live / 'config/addons/www/heizkalender'
        www.parent.mkdir(parents=True)
        if update:
            old_rc = live / 'config/rc.d/heizkalender'
            old_rc.parent.mkdir()
            old_rc.write_text('#!/bin/sh\nexit 1\n')
            old_rc.chmod(0o755)
        if web == 'symlink':
            www.symlink_to(addon / 'www', target_is_directory=True)
        else:
            www.mkdir()
            if web == 'nonempty':
                (www / 'user.txt').write_text('bewahren')
        text = (source / 'update_script').read_text()
        text = text.replace('ADDONS_DIR=/usr/local/addons', f'ADDONS_DIR="{live}/addons"')
        text = text.replace('CONF_DIR=/usr/local/etc/config', f'CONF_DIR="{live}/config"')
        (source / 'update_script').write_text(text)
        mocks = case / 'bin'
        mocks.mkdir()
        recording = case / 'commands.log'
        # PATH-Mocks lassen nur gepruefte, isolierte lokale Dateibefehle durch.
        for cmd in COMMANDS:
            real = shutil.which(cmd)
            self.assertIsNotNone(real)
            script = f'''#!/bin/sh
cmd={cmd}
printf '%s' "$cmd" >> "$RECORD"
printf ' <%s>' "$@" >> "$RECORD"
printf '\\n' >> "$RECORD"
countfile="$STATE/$cmd.count"
n=0
[ ! -f "$countfile" ] || n=$(cat "$countfile")
n=$((n + 1))
printf '%s' "$n" > "$countfile"
[ "$FAIL" != "$cmd:$n" ] || exit 23
case "$cmd" in
  logger) exit 0 ;;
  mount) [ "$UNMOUNTED" = 1 ] || printf '/dev/mock on /usr/local\\n'; exit 0 ;;
  sync) exit 0 ;;
esac
if [ "$cmd" = ln ] && [ "$WRONG" = 1 ]; then
    "{real}" -sfn "$STATE/wrong" "$3"
    exit $?
fi
exec "{real}" "$@"
'''
            (mocks / cmd).write_text(script)
            (mocks / cmd).chmod(0o755)
        env = dict(os.environ, PATH=str(mocks) + os.pathsep + os.environ['PATH'],
                   RECORD=str(recording), STATE=str(case), FAIL=fail,
                   WRONG=str(int(wrong)), UNMOUNTED=str(int(unmounted)))
        result = subprocess.run(['sh', 'update_script'], cwd=source, env=env,
                                capture_output=True, text=True)
        return result, recording.read_text(), addon, www

    def test_success(self):
        for web, update in (('symlink', True), ('empty', True), ('empty', False)):
            with self.subTest(web=web, update=update):
                result, log, addon, www = self.install(web=web, update=update)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout, '')
                self.assertNotIn('logger', log)
                self.assertFalse((addon / 'www/stale.txt').exists())
                self.assertEqual((addon / 'VERSION').read_bytes(), (ROOT / 'Addon/src/VERSION').read_bytes())
                for original in (ROOT / 'Addon/src/heizkalender/www').rglob('*'):
                    if original.is_file():
                        self.assertEqual((addon / 'www' / original.relative_to(ROOT / 'Addon/src/heizkalender/www')).read_bytes(), original.read_bytes())
                self.assertTrue(www.is_symlink())
                self.assertEqual(os.readlink(www), str(addon / 'www'))
                rc = addon.parent.parent / 'config/rc.d/heizkalender'
                self.assertEqual(rc.read_bytes(), (ROOT / 'Addon/src/rc.d/heizkalender').read_bytes())
                self.assertEqual(rc.stat().st_mode & 0o777, 0o755)

    def test_command_failures(self):
        failures = [f'{cmd}:{n}' for cmd, count in
                    [('mkdir', 4), ('chmod', 3), ('cp', 3), ('rm', 1),
                     ('ln', 1), ('readlink', 1), ('sync', 1), ('mount', 1)]
                    for n in range(1, count + 1)]
        for fail in failures + ['mount:2']:
            with self.subTest(fail=fail):
                result, log, addon, _ = self.install(fail=fail, unmounted=fail == 'mount:2')
                self.assertEqual(result.returncode, 1, (fail, result.stderr, log))
                self.assertIn('logger <-t> <heizkalender-addon> <Installation fehlgeschlagen:', log)
                self.assertEqual(result.stdout, '')
                if fail == 'cp:2':
                    self.assertFalse((addon / 'www').exists(), 'Bewusst kein Rollback')
                    self.assertIn('manuelle Reparatur erforderlich', log)
                print(f'{fail}: Exit 1, Fehlermeldung mit Addon-Logtag')

    def test_wrong_link_and_foreign_directory(self):
        for options in ({'wrong': True}, {'web': 'nonempty'}, {'web': 'empty', 'fail': 'rmdir:1'}):
            with self.subTest(options=options):
                result, log, _, www = self.install(**options)
                self.assertEqual(result.returncode, 1)
                self.assertIn('logger <-t> <heizkalender-addon> <Installation fehlgeschlagen:', log)
                if options.get('web') == 'nonempty':
                    self.assertEqual((www / 'user.txt').read_text(), 'bewahren')
                    self.assertNotIn('ln <', log)

    def verify_package(self, addon, env=None):
        result = subprocess.run(['sh', 'build.sh'], cwd=addon, env=env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('Gebaut:', result.stdout)
        version = (addon / 'src/VERSION').read_text().strip()
        archive = addon / 'build' / f'heizkalender-addon-{version}.tar.gz'
        unpack = self.area / ('unpack-' + str(len(list(self.area.iterdir()))))
        unpack.mkdir()
        with tarfile.open(archive) as tar:
            members = tar.getmembers()
            files = {m.name for m in members if m.isfile()}
            self.assertFalse(any(Path(m.name).name == '.DS_Store' or Path(m.name).name.startswith('._') for m in members))
            # Kein Verfolgen fremder Symlink-Baeume beim Packen.
            self.assertNotIn('heizkalender/www/outside/secret', files)
            for member in members:
                if member.isfile():
                    dest = unpack / member.name
                    dest.parent.mkdir(parents=True, exist_ok=True)
                    dest.write_bytes(tar.extractfile(member).read())
        manifest = unpack / 'heizkalender-addon.sha256'
        entries = {}
        for line in manifest.read_text().splitlines():
            digest, filename = line.split('  ', 1)
            entries[filename] = digest
            self.assertEqual(hashlib.sha256((unpack / filename).read_bytes()).hexdigest(), digest)
        self.assertEqual(set(entries), files - {'heizkalender-addon.sha256'})
        self.assertEqual(list(entries), sorted(entries))
        # macOS sha256sum hat teils kein -s, shasum bietet die gleiche Statuspruefung.
        sha_help = subprocess.run(['sha256sum', '--help'], capture_output=True, text=True) if shutil.which('sha256sum') else None
        checker = ['sha256sum', '-sc'] if sha_help and '--status' in sha_help.stdout else ['shasum', '-a', '256', '-sc']
        def check():
            return subprocess.run(checker + [manifest.name], cwd=unpack, capture_output=True, text=True)
        valid = check()
        self.assertEqual(valid.returncode, 0, valid.stderr)
        self.assertEqual(valid.stdout, '')
        versionfile = unpack / 'VERSION'
        original = versionfile.read_bytes()
        versionfile.write_bytes(original + b'manipuliert')
        self.assertNotEqual(check().returncode, 0)
        versionfile.write_bytes(original)
        versionfile.unlink()
        self.assertNotEqual(check().returncode, 0)
        self.assertFalse((addon / 'src/heizkalender-addon.sha256').exists())
        self.assertFalse(list((addon / 'build').glob('staging.*')))
        print(f'{archive.relative_to(ROOT)}: {len(entries)} Dateien, Hashpruefung OK; manipuliert/fehlend abgewiesen')

    def test_real_build_and_metadata(self):
        self.verify_package(ROOT / 'Addon')
        fixture = self.area / 'Addon'
        fixture.mkdir()
        shutil.copy2(ROOT / 'Addon/build.sh', fixture / 'build.sh')
        shutil.copytree(ROOT / 'Addon/src', fixture / 'src', symlinks=True)
        for folder in (fixture / 'src', fixture / 'src/heizkalender/www', fixture / 'src/rc.d'):
            (folder / '.DS_Store').write_text('metadata')
            (folder / '._hidden').write_text('metadata')
        outside = self.area / 'outside'
        outside.mkdir()
        (outside / 'secret').write_text('nicht packen')
        (fixture / 'src/heizkalender/www/outside').symlink_to(outside, target_is_directory=True)
        # Zweiter echter Bau mit shasum-Fallback, ohne sha256sum im PATH.
        tools = self.area / 'build-bin'
        tools.mkdir()
        for cmd in ('sh', 'dirname', 'cat', 'mkdir', 'mktemp', 'rm', 'tar', 'find', 'sort', 'shasum', 'du', 'cut'):
            tools.joinpath(cmd).symlink_to(shutil.which(cmd))
        self.verify_package(fixture, dict(os.environ, PATH=str(tools)))


if __name__ == '__main__':
    unittest.main(verbosity=2)
