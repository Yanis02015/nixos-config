{ pkgs, inputs, ... }:

{
  environment.systemPackages = with pkgs; [
    adwaita-qt
      adwaita-qt6
      ansible
      awww
      bibata-cursors
      brave
      brightnessctl
      btop
      bun
      claude-code
      cliphist
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
      kitty
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
