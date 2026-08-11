# Paquet local pour "ChatGPT" (app desktop OpenAI qui embarque Codex),
# repackagé depuis le .deb officiel Linux sorti le 2026-08-11
# (persistent.oaistatic.com/codex-app-prod/linux/deb/latest/chatgpt_amd64.deb).
# Pas encore dans nixpkgs : le paquet `chatgpt` de nixpkgs ne couvre que
# macOS pour l'instant (sourcé depuis un .dmg). Même approche que
# claude-desktop-debian (aaddrick) utilisé pour Claude Desktop dans ce
# repo : dpkg-deb --fsys-tarfile + autoPatchelfHook. Liste de buildInputs
# dérivée d'objdump -p sur le binaire ChatGPT principal + du champ
# Depends du control du .deb (voir commentaires).
{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  dbus,
  expat,
  gdk-pixbuf,
  glib,
  graphite2,
  gtk3,
  libdrm,
  libGL,
  libgbm,
  libnotify,
  libusb1,
  libx11,
  libxcb,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxkbcommon,
  libxrandr,
  nspr,
  nss,
  openssl,
  pango,
  systemd,
  xz,
}:
let
  version = "26.803.81509";
  src = fetchurl {
    url = "https://persistent.oaistatic.com/codex-app-prod/linux/deb/latest/chatgpt_amd64.deb";
    hash = "sha256-qb+Ro2j598Tuo4CCqfuPtGuNAFtxmm13FdLloZgsOOs=";
  };
in
stdenv.mkDerivation {
  pname = "chatgpt-desktop";
  inherit version src;

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    gdk-pixbuf
    glib
    graphite2
    gtk3
    libdrm
    libGL
    libgbm
    libnotify
    libusb1 # node-hid / device-kit-oai (fonctions "computer use")
    libx11
    libxcb
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxkbcommon
    libxrandr
    nspr
    nss
    openssl
    pango
    stdenv.cc.cc.lib # libstdc++/libgcc_s (Electron + node embarqué)
    systemd # libudev.so.1
    xz # liblzma
  ];

  # libqt5_shim.so/libqt6_shim.so sont des helpers optionnels colocalisés
  # (tray/menu natif sur certains DE) — pas dans le Depends du .deb, pas
  # essentiels pour l'usage chat/coding de base. Éviter de tirer Qt5+Qt6
  # entiers dans la closure tant que rien ne prouve qu'ils sont utilisés.
  # libc.musl-x86_64.so.1 : plusieurs addons natifs (node-hid, serialport,
  # classic-level) embarquent une variante musl en plus de la variante
  # glibc — glibc est celle qui charge réellement sur NixOS, la variante
  # musl reste un fichier mort dans le paquet.
  autoPatchelfIgnoreMissingDeps = [
    "libQt5Core.so.5"
    "libQt5Gui.so.5"
    "libQt5Widgets.so.5"
    "libQt6Core.so.6"
    "libQt6Gui.so.6"
    "libQt6Widgets.so.6"
    "libc.musl-x86_64.so.1"
  ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb --fsys-tarfile "$src" | tar -x --no-same-owner --no-same-permissions
    runHook postUnpack
  '';

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -a usr/lib usr/share $out/

    makeWrapper $out/lib/chatgpt/ChatGPT $out/bin/chatgpt

    runHook postInstall
  '';

  preFixup = ''
    addAutoPatchelfSearchPath "$out/lib/chatgpt"
  '';

  meta = {
    description = "ChatGPT desktop (OpenAI), embarque l'agent de codage Codex (repackagé depuis le .deb officiel Linux)";
    homepage = "https://developers.openai.com/codex/app";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "chatgpt";
  };
}
