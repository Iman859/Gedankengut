#!/usr/bin/env bash
# =============================================================================
# App-Icon erzeugen – aus den SVG-Quellen in icon/quelle/ bis in die App
# =============================================================================
#
# Aufruf (im Projektordner):   bash icon/erzeugen.sh
#
# Was passiert:
#   1. Die SVG-Quellen werden in PNG-Bilder (1024 × 1024 px) umgewandelt
#      → icon/png/hintergrund.png, vordergrund.png, monochrom.png
#   2. Daraus wird das Komplett-Icon für alte Android-Versionen (< 8) gebaut:
#      Hintergrund + Vordergrund übereinander, sichtbaren Bereich ausschneiden,
#      rund maskieren → icon/png/komplett.png
#   3. Das Paket flutter_launcher_icons verteilt alles in die Android-Ordner
#      (android/app/src/main/res/mipmap-*, drawable-*, mipmap-anydpi-v26).
#      Die Einstellungen dafür stehen in flutter_launcher_icons.yaml.
#
# Benötigte Werkzeuge (einmalig per Homebrew installieren):
#   brew install librsvg imagemagick
#   - rsvg-convert (aus librsvg): zeichnet SVGs inklusive Filter (Leuchten)
#   - magick (ImageMagick): setzt Bilder zusammen und schneidet sie zu
#
# Nach Änderungen an den SVGs einfach erneut ausführen.
# =============================================================================

# Bei jedem Fehler sofort abbrechen (-e), unbekannte Variablen als Fehler
# werten (-u) und Fehler in Befehlsketten nicht verschlucken (-o pipefail).
set -euo pipefail

# Immer vom Projektordner aus arbeiten, egal von wo das Skript gestartet wird.
cd "$(dirname "$0")/.."

QUELLE="icon/quelle"
ZIEL="icon/png"
GROESSE=1024
mkdir -p "$ZIEL"

# --- Prüfen, ob die Werkzeuge da sind ---------------------------------------
for werkzeug in rsvg-convert magick; do
  if ! command -v "$werkzeug" >/dev/null 2>&1; then
    echo "Fehlt: $werkzeug  →  brew install librsvg imagemagick" >&2
    exit 1
  fi
done

# --- 1. SVG → PNG -------------------------------------------------------------
for ebene in hintergrund vordergrund monochrom; do
  rsvg-convert -w "$GROESSE" -h "$GROESSE" "$QUELLE/$ebene.svg" -o "$ZIEL/$ebene.png"
  echo "✓ $ZIEL/$ebene.png"
done

# --- 2. Komplett-Icon zusammensetzen ------------------------------------------
# Die Ebenen sind 108 dp groß, sichtbar sind davon nur die mittleren 72 dp
# (= 2/3). Diesen Ausschnitt nehmen wir, vergrößern ihn auf 1024 px und
# legen eine Kreismaske darüber (außerhalb durchsichtig).
AUSSCHNITT=$(( GROESSE * 72 / 108 ))          # 682 px
RAND=$(( (GROESSE - AUSSCHNITT) / 2 ))         # 171 px
HALB=$(( GROESSE / 2 ))

magick "$ZIEL/hintergrund.png" "$ZIEL/vordergrund.png" -composite \
  -crop "${AUSSCHNITT}x${AUSSCHNITT}+${RAND}+${RAND}" +repage \
  -resize "${GROESSE}x${GROESSE}" \
  \( -size "${GROESSE}x${GROESSE}" xc:black -fill white \
     -draw "circle ${HALB},${HALB} ${HALB},0" \) \
  -alpha off -compose CopyOpacity -composite \
  "$ZIEL/komplett.png"
echo "✓ $ZIEL/komplett.png"

# --- 3. In die Android-Ordner verteilen ---------------------------------------
dart run flutter_launcher_icons
echo "Fertig. App neu installieren, um das Icon auf dem Gerät zu sehen."
