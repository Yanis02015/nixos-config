# Environnement FHS pour Claude Desktop (voir claude-desktop.nix) : NixOS
# n'étant pas FHS, les outils externes que l'app spawn doivent être trouvables
# sur un PATH standard plutôt que patchés dans le binaire. En particulier
# l'app lance des serveurs MCP via `npx` (node) / `uvx` (uv), ouvre des liens
# via xdg-open, et se sert de git. Même pattern que chatgpt-desktop-fhs.nix.
#
# Le wrapper garde le nom `claude-desktop` : l'entrée .desktop officielle fait
# `Exec=claude-desktop %U`, le picker de compte claude:// (scripts/
# claude-account-picker.sh) relance `claude-desktop`, et l'alias/PATH système
# s'attendent à ce nom.
{
  buildFHSEnv,
  claude-desktop,
  git,
  glib,
  nodejs,
  pipewire,
  uv,
  xdg-utils,
}:
buildFHSEnv {
  name = "claude-desktop";

  targetPkgs = _: [
    claude-desktop
    git # opérations git (fonctions Claude Code)
    glib # gio (déplacer vers la corbeille)
    nodejs # npx → serveurs MCP node
    pipewire # compat pulseaudio pour l'audio
    uv # uvx → serveurs MCP python
    xdg-utils # xdg-open (ouverture de liens)
  ];

  runScript = "${claude-desktop}/bin/claude-desktop";

  extraInstallCommands = ''
    mkdir -p $out/share/applications
    cp ${claude-desktop}/share/applications/* $out/share/applications/

    mkdir -p $out/share/icons
    cp -r ${claude-desktop}/share/icons/* $out/share/icons/
  '';

  meta = claude-desktop.meta // {
    description = "Claude Desktop (Anthropic) dans un environnement FHS";
  };
}
