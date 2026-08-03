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

ensure_avd() {
  if ! avdmanager list avd | grep -q "Name: $AVD_NAME\$"; then
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
    # swiftshader_indirect : rendu logiciel, plus fiable que le passthrough
    # GPU host avec le driver NVIDIA legacy (Pascal) que sur cette machine
    # sous Wayland/Hyprland. Essayer `-gpu host` si besoin de perf et que ça
    # marche pour toi.
    exec emulator -avd "$AVD_NAME" -gpu swiftshader_indirect "${@:2}"
    ;;
  *)
    echo "Usage: $0 [create|start] [args émulateur supplémentaires]" >&2
    exit 1
    ;;
esac
