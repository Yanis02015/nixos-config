{ pkgs, inputs, ... }:

let
  # SDK Android global (émulateur + une image système API 35 x86_64) pour
  # piloter un émulateur via un serveur MCP (mobile-mcp) depuis n'importe
  # quel projet — pas seulement minimonde-mobile, qui a son propre
  # flake.nix dédié au build Gradle et exclut exprès l'émulateur
  # (includeEmulator = false) pour ce cas d'usage différent. google_apis
  # (pas playstore) : pas besoin de compte Google pour de l'automatisation.
  # `androidsdk` symlinke adb/emulator/sdkmanager/avdmanager dans son bin/,
  # donc l'ajouter à systemPackages suffit à les rendre disponibles — pas
  # besoin de bidouiller le PATH comme dans le flake.nix de minimonde-mobile.
  androidComposition = pkgs.androidenv.composeAndroidPackages {
    platformVersions = [ "35" ];
    buildToolsVersions = [ "35.0.0" ];
    cmdLineToolsVersion = "latest";
    platformToolsVersion = "latest";
    includeSystemImages = true;
    systemImageTypes = [ "google_apis" ];
    abiVersions = [ "x86_64" ];
    includeEmulator = true;
  };
  androidSdk = androidComposition.androidsdk;

  # ChatGPT desktop (OpenAI), embarque l'agent Codex — repackagé depuis le
  # .deb officiel Linux (sorti le 2026-08-11, pas encore dans nixpkgs ni
  # dans une flake communautaire mûre). Voir chatgpt-desktop.nix /
  # chatgpt-desktop-fhs.nix pour le détail du wrapping FHS.
  chatgptDesktop = pkgs.callPackage ./chatgpt-desktop-fhs.nix {
    chatgpt-desktop = pkgs.callPackage ./chatgpt-desktop.nix { };
  };
in
{
  # ANDROID_HOME/ANDROID_SDK_ROOT : requis par les tools du SDK (avdmanager,
  # emulator, et les builds Gradle des projets comme minimonde-mobile qui ne
  # définissent pas leur propre variante dans un flake.nix de projet).
  environment.variables = {
    ANDROID_HOME = "${androidSdk}/libexec/android-sdk";
    ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
  };

  environment.systemPackages = with pkgs; [
    androidSdk
      adwaita-qt
      adwaita-qt6
      android-tools
      ansible
      awscli2
      awww
      bibata-cursors
      brave
      brightnessctl
      btop
      bun
      claude-code
      cliphist
      direnv
      discord
      fastfetch
      fd
      fzf
      gcc
      gh
      git
      ghostty
      glib
      gnome-themes-extra
      google-chrome
      grim
      hypridle
      hyprlock
      hyprpolkitagent
      hyprsunset
      jdk
      jq
      k9s
      kamal
      kitty
      kubectl
      lazydocker
      lazygit
      libnotify
      matugen
      maven
      # nautilus : ajouté (le repo source déclare FILEMANAGER = "nautilus"
      # dans hyprland.lua mais oublie de l'installer dans packages.nix)
      nautilus
      nix-output-monitor # give me some visual for the nix rebuilds and upgrades
      neovim
      obs-studio
      obsidian
      papirus-icon-theme
      pavucontrol
      playerctl
      pnpm
      podman-desktop
      qt6.qtdeclarative   # ships the `qmlls` QML language server (for Quickshell/QML in nvim)
      quickshell
      ripgrep
      satty
      sesh # sélecteur/créateur de session tmux fuzzy (SUPER+T / tmux prefix+s)
      slurp
      stow
      tmux
      trash-cli
      tree-sitter
      vscode
      wget
      wireguard-tools
      wl-clipboard
      yazi
      zed-editor
      zoxide
      zsh-powerlevel10k
      zsh-autosuggestions
      zsh-syntax-highlighting
      zsh-history-substring-search

# languages and runtimes
      go
      nodejs
      python3

# lsp
      basedpyright
      gnumake
      gopls
      jdt-language-server
      lua-language-server
      tailwindcss-language-server
      typescript-language-server
      vscode-langservers-extracted


# conform -> formatters
      black
      prettier
      shfmt
      stylua

# flakes
      inputs.zen-browser.packages."${pkgs.stdenv.hostPlatform.system}".default
      # claude-desktop-fhs (default de ce flake) : wrappe le .deb officiel Anthropic
      # (bêta Linux depuis le 2026-06-30) + support MCP via npx/uvx/docker (FHS env)
      inputs.claude-desktop.packages."${pkgs.stdenv.hostPlatform.system}".default
      # chatgptDesktop : wrappe le .deb officiel OpenAI (ChatGPT + Codex,
      # sorti le 2026-08-11) en environnement FHS, voir plus haut
      chatgptDesktop

# desktop entry so GUI apps open text files in nvim inside
# ghostty. Named nvim-terminal to avoid colliding with neovim's own nvim.desktop.
      (makeDesktopItem {
        name = "nvim-terminal";
        desktopName = "Neovim (Terminal)";
        genericName = "Text Editor";
        exec = "ghostty -e nvim %F";
        terminal = false;
        icon = "nvim";
        categories = [ "Utility" "TextEditor" ];
        mimeTypes = [ "text/plain" "text/markdown" "text/x-python" "text/x-lua" "text/javascript" "application/json" ];
        startupNotify = false;
      })

# desktop entry pour lancer nmtui (gestion wifi/VPN NetworkManager) depuis
# le launcher quickshell, même contournement Terminal=true que nvim-terminal.
      (makeDesktopItem {
        name = "nmtui";
        desktopName = "Network Connections (nmtui)";
        genericName = "Network Manager";
        exec = "ghostty --title=nmtui-term -e nmtui";
        terminal = false;
        icon = "network-wired";
        categories = [ "Utility" "Network" ];
        startupNotify = false;
      })

# handler de x-scheme-handler/claude (liens claude://, ex. OAuth MCP) :
# deux apps Claude coexistent sur cette machine (standard + compte Team
# "1of10", voir ~/.local/share/applications/claude-1of10.desktop, pas géré
# par ce repo car propre à l'app elle-même). Le bon compte dépend du
# contexte au moment du clic, donc pas de défaut fixe : cette entrée ouvre
# un picker fzf (scripts/claude-account-picker.sh) dans ghostty flottant
# (même contournement Terminal=true que nvim-terminal/nmtui), qui relance
# claude-desktop avec le bon --user-data-dir. Doit être fait défaut pour
# x-scheme-handler/claude via ~/.config/mimeapps.list (prioritaire sur ce
# que ce fichier déclare, voir xdg.mime.defaultApplications plus bas).
# ATTENTION : claude-desktop (standard) se ré-enregistre lui-même comme
# handler par défaut à chaque lancement (Electron app.setAsDefaultProtocolClient,
# confirmé dans son app.asar), donc ce réglage ne "tient" pas seul — un path
# unit systemd --user (claude-mimeapps-guard, configuration.nix) surveille
# mimeapps.list et réaffirme claude-account-picker.desktop dès qu'il change.
      (makeDesktopItem {
        name = "claude-account-picker";
        desktopName = "Claude (choix du compte)";
        genericName = "AI Assistant";
        exec = "ghostty --title=claude-picker-term -e /home/yanis/nixos-config/scripts/claude-account-picker.sh %u";
        terminal = false;
        icon = "claude-desktop";
        categories = [ "Utility" "Development" ];
        mimeTypes = [ "x-scheme-handler/claude" ];
        startupNotify = false;
      })
      ];

# fonts (system-wide, via fonts.packages not systemPackages)
# noto-fonts / noto-fonts-color-emoji : ajoutés en plus du set du repo, pour
# éviter les glyphes manquants (tofu boxes) hors terminal — le repo ne
# déclare que des polices monospace/nerd-font.
  fonts.packages = with pkgs; [
    departure-mono
    maple-mono.NF
      nerd-fonts.departure-mono
      nerd-fonts.iosevka
      noto-fonts
      noto-fonts-color-emoji
  ];
}
