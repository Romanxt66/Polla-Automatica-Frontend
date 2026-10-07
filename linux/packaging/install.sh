#!/bin/sh
# Instala Polla Automática para el usuario actual (sin root).
# Uso: ./install.sh      (desde la carpeta que contiene bundle/ y este script)
#      ./install.sh --uninstall
set -e
APP="$HOME/.local/share/polla-automatica"
DESK="$HOME/.local/share/applications"
ICON="$HOME/.local/share/icons/hicolor/512x512/apps"
HERE="$(cd "$(dirname "$0")" && pwd)"

if [ "$1" = "--uninstall" ]; then
  rm -rf "$APP" "$DESK/com.polla.polla_app.desktop" "$ICON/polla-automatica.png"
  update-desktop-database "$DESK" 2>/dev/null || true
  echo "Polla Automática desinstalada."
  exit 0
fi

[ -x "$HERE/bundle/polla_app" ] || { echo "No encuentro bundle/polla_app junto a install.sh" >&2; exit 1; }

mkdir -p "$APP" "$DESK" "$ICON"
rm -rf "$APP/bundle"
cp -r "$HERE/bundle" "$APP/bundle"
cp "$HERE/polla_automatica.png" "$ICON/polla-automatica.png"
sed "s|@EXEC@|$APP/bundle/polla_app|" "$HERE/com.polla.polla_app.desktop" > "$DESK/com.polla.polla_app.desktop"
chmod +x "$DESK/com.polla.polla_app.desktop"
update-desktop-database "$DESK" 2>/dev/null || true
gtk-update-icon-cache -q "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
echo "Instalada. Búscala como 'Polla Automática' en el menú de aplicaciones."
