# Paquet local pour Claude Desktop, repackagé depuis le .deb OFFICIEL Anthropic
# (bêta Linux) servi par le dépôt apt maison :
#   https://downloads.claude.ai/claude-desktop/apt/stable/pool/main/c/claude-desktop/
# Voir https://code.claude.com/docs/en/desktop-linux.
#
# Pourquoi un paquet local plutôt que le flake communautaire aaddrick/
# claude-desktop-debian (utilisé ici jusqu'au 2026-09-22) : ce flake wrappe
# lui aussi le .deb officiel, mais épingle une version en retard de quelques
# builds sur le pool apt. Or Anthropic gate les tout derniers modèles (ex.
# Opus 5.5) sur une version minimale de client — d'où le message "Upgrade
# Claude to use this model on this computer" tant qu'on traîne derrière. En
# packageant le .deb officiel nous-mêmes on contrôle la version (bump
# version + hash, comme chatgpt-desktop.nix) sans dépendre du rythme de
# release d'un tiers.
#
# Même approche que chatgpt-desktop.nix : dpkg-deb --fsys-tarfile +
# autoPatchelfHook. buildInputs dérivés du `patchelf --print-needed` sur le
# binaire Electron + du champ Depends du control du .deb.
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
  libcap_ng,
  libGL,
  libgbm,
  libnotify,
  libseccomp,
  libsecret,
  libuuid,
  libx11,
  libxcb,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxkbcommon,
  libxrandr,
  libxtst,
  nspr,
  nss,
  openssl,
  pango,
  systemd,
  xz,
}:
let
  version = "2.2553.13";
  src = fetchurl {
    url = "https://downloads.claude.ai/claude-desktop/apt/stable/pool/main/c/claude-desktop/claude-desktop_${version}_amd64.deb";
    hash = "sha256-AqlanRM0csG3c8jp297lZoG4FkUAF4CDvYtTudEdEJ8=";
  };
in
stdenv.mkDerivation {
  pname = "claude-desktop";
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
    libcap_ng # libcap_ng.so.0 — virtiofsd bundlé (Cowork)
    libdrm
    libGL
    libgbm
    libnotify
    libseccomp # libseccomp.so.2 — virtiofsd bundlé (Cowork)
    libsecret # trousseau système (org.freedesktop.secrets) — login Claude, cf. Depends libsecret-1-0
    libuuid # libuuid.so.1 (Depends libuuid1)
    libx11
    libxcb
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxkbcommon
    libxrandr
    libxtst # Depends libxtst6
    nspr
    nss
    openssl
    pango
    stdenv.cc.cc.lib # libstdc++/libgcc_s (Electron + addons node embarqués)
    systemd # libudev.so.1
    xz # liblzma
  ];

  # Variantes musl de certains addons natifs node embarqués : glibc est celle
  # qui charge réellement sur NixOS, la variante musl reste un fichier mort.
  autoPatchelfIgnoreMissingDeps = [
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

    # Le .deb livre usr/bin/claude-desktop en symlink relatif vers
    # ../lib/claude-desktop/claude-desktop ; on le remplace par un wrapper
    # propre (le vrai PATH est fixé par autoPatchelf + la search path ci-dessous).
    makeWrapper $out/lib/claude-desktop/claude-desktop $out/bin/claude-desktop

    runHook postInstall
  '';

  preFixup = ''
    addAutoPatchelfSearchPath "$out/lib/claude-desktop"
  '';

  meta = {
    description = "Claude Desktop (Anthropic), repackagé depuis le .deb officiel bêta Linux";
    homepage = "https://code.claude.com/docs/en/desktop-linux";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "claude-desktop";
  };
}
