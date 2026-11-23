#!/bin/sh
# Baut das Heizkalender-Addon-Paket (heizkalender-addon-<version>.tar.gz)
# Aufruf: ./Addon/build.sh  (vom Projektverzeichnis aus)
# Ablage: Addon/build/heizkalender-addon-<version>.tar.gz

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VERSION="$(cat "${SCRIPT_DIR}/src/VERSION")"
FILENAME="heizkalender-addon-${VERSION}.tar.gz"
OUT="${SCRIPT_DIR}/build/${FILENAME}"

mkdir -p "${SCRIPT_DIR}/build"
# Nur diesen frisch angelegten Arbeitsbereich aufraeumen, niemals src veraendern.
STAGE="$(mktemp -d "${SCRIPT_DIR}/build/staging.XXXXXX")"
trap 'rm -rf "$STAGE"' 0
trap 'exit 1' 1 2 15
mkdir "${STAGE}/package"
export COPYFILE_DISABLE=1
tar -cf "${STAGE}/payload.tar" -C "${SCRIPT_DIR}/src" \
  --exclude='.DS_Store' --exclude='._*' \
  VERSION update_script heizkalender/www rc.d
tar -xf "${STAGE}/payload.tar" -C "${STAGE}/package"
cd "${STAGE}/package"

# find folgt keinen fremden Symlink-Baeumen. Manifest nicht selbst hashen.
LC_ALL=C find VERSION update_script heizkalender rc.d -type f > "${STAGE}/files.unsorted"
LC_ALL=C sort "${STAGE}/files.unsorted" > "${STAGE}/files"
if command -v sha256sum >/dev/null 2>&1; then
    HASH=sha256sum
else
    HASH=shasum
fi
while IFS= read -r file; do
    if [ "$HASH" = sha256sum ]; then
        sha256sum "$file"
    else
        shasum -a 256 "$file"
    fi
done < "${STAGE}/files" > heizkalender-addon.sha256

# macOS liefert bsdtar, Linux ueblicherweise GNU tar.
case "$(tar --version)" in
    *bsdtar*) set -- --uid=0 --gid=0 ;;
    *) set -- --owner=0 --group=0 ;;
esac
tar -czf "${OUT}" "$@" \
  VERSION update_script heizkalender rc.d heizkalender-addon.sha256

echo "Gebaut: ${OUT} ($(du -sh "${OUT}" | cut -f1))"
