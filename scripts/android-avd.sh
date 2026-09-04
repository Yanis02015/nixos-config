#!/usr/bin/env bash
# Gère un unique AVD réutilisable entre projets (Expo, React Native natif,
# etc.) pour que le serveur MCP mobile-mcp ait toujours un émulateur
# disponible sans dépendre de la config d'un projet en particulier.
set -euo pipefail

# Ne pas compter sur ANDROID_HOME/ANDROID_SDK_ROOT déjà présents dans le
# shell interactif (peu fiable : un terminal ouvert avant un rebuild, ou
# lancé via un environnement tiers type FHS, ne les a pas forcément) — on les
# lit directement depuis la génération système active à chaque lancement.
if [ -z "${ANDROID_HOME:-}" ]; then
  eval "$(grep -h '^export ANDROID_HOME=\|^export ANDROID_SDK_ROOT=' /run/current-system/etc/set-environment)"
fi

AVD_NAME="mcp-dev"
PACKAGE="system-images;android-35;google_apis;x86_64"

# Détection par présence du .ini sur disque plutôt que via `avdmanager list
# avd` : ce dernier lève un NPE ("img is null") et tronque sa sortie dès
# qu'un AUTRE AVD du store a une system image manquante (ex. s9_api28 en API
# 28 non installée), ce qui faisait échouer la détection de mcp-dev de façon
# non-déterministe et déclenchait une recréation ("already exists").
AVD_HOME="${ANDROID_AVD_HOME:-$HOME/.android/avd}"

ensure_avd() {
  if [ ! -f "$AVD_HOME/$AVD_NAME.ini" ]; then
    echo "Création de l'AVD $AVD_NAME ($PACKAGE)..."
    echo "no" | avdmanager create avd -n "$AVD_NAME" -k "$PACKAGE" --device "pixel_7"
  fi
}

case "${1:-start}" in
  create)
    ensure_avd
    ;;
  start)
    ensure_avd
    # Mode GPU surchargeable via EMULATOR_GPU. Défaut swiftshader_indirect :
    # rendu logiciel, plus fiable que le passthrough GPU host avec le driver
    # NVIDIA legacy (Pascal) sur cette machine sous Wayland/Hyprland. Passer
    # EMULATOR_GPU=host si besoin de perf et que ça marche pour toi (c'est ce
    # que fait l'alias `emu` du .zshrc).
    exec emulator -avd "$AVD_NAME" -gpu "${EMULATOR_GPU:-swiftshader_indirect}" "${@:2}"
    ;;
  *)
    echo "Usage: $0 [create|start] [args émulateur supplémentaires]" >&2
    exit 1
    ;;
esac
