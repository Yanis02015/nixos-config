# Paquet local pour "Pen" (pen.dev), canvas de design agentique (Electron),
# repackagé depuis l'AppImage officiel Linux. Pas dans nixpkgs ni dans une
# flake communautaire (vérifié le 2026-09-15).
#
# Source : le dépôt GitHub `highagency/pen-desktop-releases` (celui que
# l'auto-updater electron-builder de l'app interroge, cf. resources/
# app-update.yml dans l'AppImage) — contrairement à pen.dev/downloads qui
# ne sert qu'une URL non versionnée ("latest", hash instable), les assets
# GitHub sont versionnés et stables. Le sha512 publié dans latest-linux.yml
# correspond bit à bit au fichier servi par pen.dev.
#
# appimageTools.wrapType2 (buildFHSEnv) plutôt qu'autoPatchelfHook comme
# pour chatgpt-desktop.nix : en plus d'Electron, l'AppImage embarque des
# helpers précompilés non patchables proprement (serveur MCP
# out/mcp-server-linux-x64, binaire `claude` de @anthropic-ai/
# claude-agent-sdk, `codex` musl statique + son propre bwrap, esbuild) qui
# s'attendent à un loader /lib64/ld-linux-x86-64.so.2 standard — l'env FHS
# le fournit à tout l'arbre de processus, nix-ld seul ne couvrirait pas les
# process enfants lancés avec un environnement nettoyé.
{
  lib,
  appimageTools,
  fetchurl,
}:
let
  pname = "pen";
  version = "1.2.10";

  src = fetchurl {
    url = "https://github.com/highagency/pen-desktop-releases/releases/download/v${version}/Pen-${version}-linux-x86_64.AppImage";
    hash = "sha256-EYgN4lmfys1bb8iJVyE3OS3O7HdD1Y2YZxbiukpi/9k=";
  };

  appimageContents = appimageTools.extractType2 { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  # Le .desktop de l'AppImage appelle `AppRun --no-sandbox %U` : on pointe
  # sur le wrapper $out/bin/pen (le sandbox Chromium marche avec les user
  # namespaces de NixOS, pas besoin de le désactiver). Le MimeType
  # x-scheme-handler/pencil est conservé : c'est le deep-link `pencil://`
  # utilisé par le site / les extensions VS Code-Cursor pour ouvrir l'app.
  extraInstallCommands = ''
    install -Dm444 ${appimageContents}/pen.desktop $out/share/applications/pen.desktop
    substituteInPlace $out/share/applications/pen.desktop \
      --replace-fail 'Exec=AppRun --no-sandbox %U' 'Exec=pen %U'

    install -Dm444 ${appimageContents}/usr/share/icons/hicolor/512x512/apps/pen.png \
      $out/share/icons/hicolor/512x512/apps/pen.png
  '';

  meta = {
    description = "Pen (pen.dev), canvas de design agentique piloté par des agents IA via MCP (repackagé depuis l'AppImage officiel)";
    homepage = "https://www.pen.dev/";
    changelog = "https://github.com/highagency/pen-desktop-releases/releases/tag/v${version}";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "pen";
  };
}
