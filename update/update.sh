#!/usr/bin/env bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GAME_DIR="${ROOT}/game"
ASSETS_DIR="${GAME_DIR}/assets"
JS_LIST="${ROOT}/update/jslist.txt"

cd "$GAME_DIR"

rm -rf "${ASSETS_DIR}/images" "${ASSETS_DIR}/sounds" locales
mkdir -p "${ASSETS_DIR}/images" "${ASSETS_DIR}/sounds" locales components

while IFS= read -r f; do
  [[ -n "$f" ]] && rm -f "$GAME_DIR/$f"
done < "$JS_LIST"

cd "${ASSETS_DIR}/images"
wget --convert-links -O index.html http://orteil.dashnet.org/cookieclicker/img/
grep -v PARENTDIR index.html | grep '\[IMG' | grep -Po 'a href="\K.*?(?=")' | sed 's/\?.*//' > _imglist.txt
wget -N -i _imglist.txt -B http://orteil.dashnet.org/cookieclicker/img/
cd ../sounds/
wget --convert-links -O index.html http://orteil.dashnet.org/cookieclicker/snd/
grep -v PARENTDIR index.html | grep '\[SND' | grep -Po 'a href="\K.*?(?=")' | sed 's/\?.*//' > _sndlist.txt
wget -N -i _sndlist.txt -B http://orteil.dashnet.org/cookieclicker/snd/
cd "${GAME_DIR}/locales"
wget --convert-links -O index.html http://orteil.dashnet.org/cookieclicker/loc/
grep -v PARENTDIR index.html | grep '\[TXT' | grep -Po 'a href="\K.*?(?=")' | sed 's/\?.*//' > _loclist.txt
wget -N -i _loclist.txt -B http://orteil.dashnet.org/cookieclicker/loc/
cd ../
wget -O index.html http://orteil.dashnet.org/cookieclicker/
wget -O style.css http://orteil.dashnet.org/cookieclicker/style.css
wget -N -i "$JS_LIST" -B http://orteil.dashnet.org/cookieclicker/
