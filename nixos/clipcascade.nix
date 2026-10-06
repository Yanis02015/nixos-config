# Paquet local pour le client Linux de ClipCascade (synchro du presse-papier
# NixOS <-> macOS). Pas dans nixpkgs (vérifié le 2026-10-06). Le serveur tourne
# sur le homelab (docker compose dans /mnt/data/clipcascade), http://192.168.2.15:8080.
#
# Le client Linux est du Python brut (pas de binaire PyInstaller comme sur
# Windows/macOS) : l'archive de la release contient les sources + un
# pyproject.toml, donc buildPythonApplication suffit.
#
# Modes (flags propres au client Linux, lus dans core/constants.py) :
#   --xmode false : clipboard via wl-clipboard (`wl-paste --watch`), pas xclip.
#     Sous Hyprland avec XWayland, l'auto-détection choisit sinon xclip.
#   --gui true    : fenêtre de login Tk + icône pystray. Le mode CLI (défaut
#     quand xmode=false) boucle sur input() et plante sans terminal, donc
#     inutilisable depuis autostart.lua. Pas de systray dans la barre
#     quickshell : l'icône est invisible, comme nm-applet/kdeconnect-indicator.
#
# Mise à jour : changer `version`, puis `nix-prefetch-url` sur la nouvelle URL
# de ClipCascade_Linux.tar.xz (et vérifier que le patch s'applique encore).
{
  lib,
  python3Packages,
  fetchurl,
  wrapGAppsHook3,
  gobject-introspection,
  gtk3,
  libayatana-appindicator,
  wl-clipboard,
  xclip,
  xrandr,
  libnotify,
}:
python3Packages.buildPythonApplication rec {
  pname = "clipcascade";
  version = "3.2.0";
  pyproject = true;

  src = fetchurl {
    url = "https://github.com/Sathvik-Rao/ClipCascade/releases/download/${version}/ClipCascade_Linux.tar.xz";
    hash = "sha256-LF2u6aTYQ9DFZO12pdw13mLFy4t+Sk1OX2ziRgS43hc=";
  };
  sourceRoot = "ClipCascade";

  # Le client écrit DATA (session/login), son log et son lockfile à côté de
  # son code, donc dans le store en lecture seule : redirigé vers
  # ~/.local/state/clipcascade.
  patches = [ ./clipcascade-state-dir.patch ];

  build-system = [ python3Packages.setuptools ];

  dependencies = with python3Packages; [
    pillow
    plyer
    pycryptodome
    pystray
    requests
    websocket-client
    xxhash
    pyfiglet
    beautifulsoup4
    aiortc
    tkinter
    pygobject3
  ];

  # pyproject.toml épingle des versions exactes (==), nixpkgs a plus récent.
  pythonRelaxDeps = true;

  nativeBuildInputs = [
    wrapGAppsHook3
    gobject-introspection
  ];
  # Typelibs Gtk + AyatanaAppIndicator3 : backend appindicator de pystray.
  buildInputs = [
    gtk3
    libayatana-appindicator
  ];

  dontWrapGApps = true;
  makeWrapperArgs = [
    "\${gappsWrapperArgs[@]}"
    # xrandr : centrage de la fenêtre de login (warning sinon, fallback OK).
    "--prefix PATH : ${lib.makeBinPath [ wl-clipboard xclip xrandr libnotify ]}"
    "--add-flags '--xmode false --gui true'"
  ];

  # Pas de tests upstream.
  doCheck = false;
  pythonImportsCheck = [ "core.config" ];

  meta = {
    description = "Clipboard sync across devices (Linux client)";
    homepage = "https://github.com/Sathvik-Rao/ClipCascade";
    license = lib.licenses.gpl3Only;
    mainProgram = "clipcascade";
    platforms = lib.platforms.linux;
  };
}
