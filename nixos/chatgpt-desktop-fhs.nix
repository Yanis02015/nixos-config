# Environnement FHS pour l'app ChatGPT/Codex desktop (voir chatgpt-desktop.nix) :
# NixOS n'étant pas FHS, certains outils externes que l'app spawn (xdg-open,
# git pour les fonctions Codex, gio pour la corbeille) doivent être trouvables
# sur un PATH standard plutôt que patchés dans le binaire. Même pattern que
# nix/fhs.nix de claude-desktop-debian.
{
  buildFHSEnv,
  chatgpt-desktop,
  git,
  glib,
  pipewire,
  xdg-utils,
}:
buildFHSEnv {
  name = "chatgpt";

  targetPkgs = _: [
    chatgpt-desktop
    git
    glib # gio (déplacer vers la corbeille)
    pipewire # compat pulseaudio pour l'audio
    xdg-utils
  ];

  runScript = "${chatgpt-desktop}/bin/chatgpt";

  extraInstallCommands = ''
    mkdir -p $out/share/applications
    cp ${chatgpt-desktop}/share/applications/* $out/share/applications/

    mkdir -p $out/share/pixmaps
    cp -r ${chatgpt-desktop}/share/pixmaps/* $out/share/pixmaps/
  '';

  meta = chatgpt-desktop.meta // {
    description = "ChatGPT desktop (OpenAI/Codex) dans un environnement FHS";
  };
}
