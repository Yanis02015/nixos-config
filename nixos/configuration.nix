{ config, lib, pkgs, inputs, ... }:

{
    imports =
        [
        ./hardware-configuration.nix
        ./packages.nix
        ];

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.kernelPackages = pkgs.linuxPackages_latest;

    services.xserver.xkb.layout = "fr";
    services.xserver.xkb.options = "ctrl:swap_lalt_lctl";
    console.useXkbConfig = true;

    zramSwap.enable = true;

    networking.hostName = "nixos"; # Define your hostname.
    networking.networkmanager.enable = true;

    time.timeZone = "America/Toronto";

    i18n.defaultLocale = "en_US.UTF-8";
    i18n.extraLocaleSettings = {
        LC_ADDRESS = "en_US.UTF-8";
        LC_IDENTIFICATION = "en_US.UTF-8";
        LC_MEASUREMENT = "en_US.UTF-8";
        LC_MONETARY = "en_US.UTF-8";
        LC_NAME = "en_US.UTF-8";
        LC_NUMERIC = "en_US.UTF-8";
        LC_PAPER = "en_US.UTF-8";
        LC_TELEPHONE = "en_US.UTF-8";
        LC_TIME = "en_US.UTF-8";
    };

    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
#jack.enable = true;
    };

    services.libinput.enable = true;

    # ---------------------------------------------------------------------------
    # Pilote NVIDIA (GTX 1070 - architecture Pascal).
    # Adaptation obligatoire : le repo Leabua/dotfiles est pensé pour un laptop
    # Intel-only (intel-media-driver). Cette machine a une GTX 1070 dédiée, sans
    # GPU Intel du tout (lspci ne montre qu'un seul contrôleur VGA : NVIDIA).
    # legacy_580 est nécessaire : le pilote "stable" a abandonné le support
    # Pascal, ce qui causait un écran figé en 1024x768 sans EDID.
    # ---------------------------------------------------------------------------
    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.graphics.enable = true;

    hardware.nvidia = {
        modesetting.enable = true;
        powerManagement.enable = false;
        open = false;
        nvidiaSettings = true;
        package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
    };

# Note : fileSystems."/mnt/hdd" du repo original est omis — c'est un disque
# secondaire propre à la machine de l'auteur, absent ici.

# backend services for the quickshell bar widgets
    services.upower.enable = true;                 # battery
    services.power-profiles-daemon.enable = true;  # power profiles
    hardware.bluetooth.enable = true;              # bluetooth
    services.logind.powerKey = "ignore";           # stop logind powering off; let hyprland's XF86PowerOff bind open the quickshell powerMenu (long-press still forces off)

    users.users.yanis = {
        isNormalUser = true;
        description = "yanis";
        extraGroups = [ "wheel" "networkmanager" "docker" ];
        shell = pkgs.zsh;
    };

    # Docker Compose est inclus dans le paquet docker (plugin `docker compose`),
    # pas besoin de l'ajouter séparément dans packages.nix.
    virtualisation.docker.enable = true;

    security.sudo.wheelNeedsPassword = false;

# List services that you want to enable:
    services.displayManager.ly.enable = true;
    programs.hyprland = {
        enable = true;
        xwayland.enable = true;
    };
    programs.niri.enable = false;

    security.polkit.enable = true;
    systemd.packages = with pkgs; [ hyprpolkitagent ];
    systemd.user.services.hyprpolkitagent.wantedBy = [ "graphical-session.target" ];

    systemd.user.services.trash-cleanup.serviceConfig.ExecStart = "${pkgs.trash-cli}/bin/trash-empty 20";
    systemd.user.timers.trash-cleanup = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
            OnCalendar = "daily";
            Persistent = true;
        };
    };

    # Change de wallpaper (+ régénère les couleurs Matugen) toutes les heures.
    systemd.user.services.wallpaper-rotate.serviceConfig.ExecStart = "%h/dotfiles/scripts/rotate_wallpaper.sh";
    systemd.user.timers.wallpaper-rotate = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
            OnStartupSec = "5m"; # première rotation 5 min après connexion
            OnUnitActiveSec = "1h";
        };
    };

    programs.firefox.enable = true;
    services.openssh.enable = false; # désactivé, pas de besoin d'accès distant
    services.printing.enable = true;

    programs.zsh.enable = true;
    environment.pathsToLink = [
        "/share/fzf"
        "/share/zsh-powerlevel10k"
        "/share/zsh-autosuggestions"
        "/share/zsh-syntax-highlighting"
        "/share/zsh-history-substring-search"
    ];

    # file manager backends (USB/udisks2 mounting, phone/MTP via gvfs)
    services.gvfs.enable = true;
    services.udisks2.enable = true;

    # Forcing dark mode via session variables (better for Wayland/Hyprland)
    # LIBVA_DRIVER_NAME, GBM_BACKEND, __GLX_VENDOR_LIBRARY_NAME, NVD_BACKEND,
    # NIXOS_OZONE_WL : adaptation obligatoire pour la GTX 1070 (le repo original
    # utilise LIBVA_DRIVER_NAME=iHD, spécifique aux GPU Intel).
    environment.sessionVariables = {
        GTK_THEME = "Adwaita:dark";
        QT_QPA_PLATFORM = "wayland;xcb";
        LIBVA_DRIVER_NAME = "nvidia";
        GBM_BACKEND = "nvidia-drm";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        NVD_BACKEND = "direct";
        NIXOS_OZONE_WL = "1";
        EDITOR = "nvim";
        VISUAL = "nvim";
        BROWSER = "zen-beta";
    };

    programs.dconf.enable = true;

    qt = {
        enable = true;
        platformTheme = "gnome";
        style = "adwaita-dark";
    };

    programs.dconf.profiles.user.databases = [{
        settings = {
            "org/gnome/desktop/interface" = {
                color-scheme = "prefer-dark";
                # Papirus has full, crisp MIME-type icons. Adwaita 50 dropped its
                # colour file icons, leaving jagged fallbacks in GTK apps.
                icon-theme = "Papirus-Dark";
            };
        };
    }];

    xdg.portal = {
        enable = true;
        extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
        config.common.default = "*";
    };

    # System-wide default apps (writes /etc/xdg/mimeapps.list). A per-user
    # ~/.config/mimeapps.list still overrides these for whatever it lists
    # (currently the browser/html handlers, already set to zen-beta).
    # nvim-terminal.desktop (defined in packages.nix) opens text in nvim inside
    # ghostty, since the stock nvim.desktop is Terminal=true and won't launch on Hyprland.
    xdg.mime.defaultApplications = {
        "text/plain"        = "nvim-terminal.desktop";
        "text/markdown"     = "nvim-terminal.desktop";
        "text/x-python"     = "nvim-terminal.desktop";
        "text/x-lua"        = "nvim-terminal.desktop";
        "text/javascript"   = "nvim-terminal.desktop";
        "application/json"  = "nvim-terminal.desktop";
        # browser — declarative source of truth (mirrors the per-user file)
        "text/html"                = "zen-beta.desktop";
        "x-scheme-handler/http"    = "zen-beta.desktop";
        "x-scheme-handler/https"   = "zen-beta.desktop";
    };

    nix.settings.experimental-features = ["nix-command" "flakes"];
    nixpkgs.config.allowUnfree = true;
    system.stateVersion = "26.05";
}
