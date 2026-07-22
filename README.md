# Yanis's dots for Nixos (Hyprland)

![Quickshell minimalBar on the blue train wallpaper - bar, app menu, clipboard history and the reminders panel](assets/screenshot-1.png)

![The same shell on a pixel-art wallpaper - clipboard, app menu and notification toasts, all matugen-themed off the wallpaper](assets/screenshot-2.png)

![Ghostty running tmux with the Neovim dashboard and fastfetch side by side](assets/screenshot-3.png)

Personal NixOS + Hyprland setup, originally forked from [Leabua/dotfiles](https://github.com/Leabua/dotfiles) and since heavily customized: NVIDIA support, a different keyboard layout, dead/duplicate configs removed, and everything reorganized under `dots/`. See [`CLAUDE.md`](./CLAUDE.md) for the full list of deviations from upstream and the pitfalls already found and fixed.

## Required packages 
- stow  
- git
- hyprland

## Getting Nixos up

The whole system is declared in [`nixos/`](https://github.com/Yanis02015/nixos-config/tree/master/nixos) as a flake. It is *not* stowed and does *not* live in `/etc/nixos` - you build straight out of the repo (`/etc/nixos` is a symlink pointing into it).

1. Install Nixos from the ISO as normal, then clone this repo to `~/nixos-config`.
2. Enable flakes if the installer hasn't, by adding to `/etc/nixos/configuration.nix`:
   `nix.settings.experimental-features = [ "nix-command" "flakes" ];` then `sudo nixos-rebuild switch`.
3. Copy your machine's real hardware config over the one in the repo - this file is specific to the machine that generated it and will not work on yours as-is:
```
cp /etc/nixos/hardware-configuration.nix ~/nixos-config/nixos/
```
4. Build it. The flake target is `#nixos`, which matches the hostname set in `configuration.nix` - change both if you want a different hostname.
```
sudo nixos-rebuild switch --flake ~/nixos-config/nixos#nixos
```
5. Stow whatever configs you want from the table below.

Day to day there are aliases in [`zsh`](https://github.com/Yanis02015/nixos-config/tree/master/dots/zsh) for this: `rebuild` to apply changes, `upgrade` to bump the flake inputs and rebuild, `nix-purge-old-generations` to garbage collect old generations.

Packages go in [`nixos/packages.nix`](https://github.com/Yanis02015/nixos-config/blob/master/nixos/packages.nix), not into an imperative `nix-env` install.

## Usage
1. Flash Nixos onto the system. Once internet is connected and operational install a window manager of your choice. 
2. Install the required packages above. 
3. Clone this repo down. 
You may need to setup git if you haven't yet.
```
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

```
Then: `git clone https://github.com/Yanis02015/nixos-config.git`. <- Now you have all the files on your system.

4. Stow usage 
All stowable packages live under `dots/`, with a `.stowrc` there pinning the target to your home directory, so no flags are needed.
Symlinking your configs
Recommended: from `dots/`, `stow <folderName> `. I.e. `stow hypr` or for multiple files `stow hypr nvim tmux ghostty`.
Fastest and not recommended: `stow .` -> symlinks it all. Not recommeneded since thats just a mess since some packages do the same role.

Unstowing a directory
Go into `dots/`. 
`stow -D <folderName>` <- removes the symlink (capital D; lowercase `-d` sets the stow directory instead)

You will be able to change the contents of anything either in the repo or in the actual place the files link to (likely ~/.config/ in most circumstances).

## Stowable packages

Every package below is stowed the same way -`stow <package>` from inside `~/nixos-config/dots`, no flags (a `.stowrc` there pins the target to your home directory) — except `wallpapers`, which lives at the repo root instead of `dots/` and stows with plain `stow wallpapers` from `~/nixos-config`. Pick only what you need, they're all independent.

Almost everything lands in `~/.config/<package>`. The only two exceptions are `zsh` (which drops `.zshrc` and `.p10k.zsh` straight into your home directory, since that's where zsh looks for them) and `wallpapers` (which lands at `~/Wallpapers`, since that's where `rotate_wallpaper.sh` looks).
NB: quickshell is the bar, launcher, notification daemon and power menu, so the standalone alternatives that used to live here (`alacritty`, `mako`, `rofi`, `walker`, `waybar`, `niri`, `pacseek`) have been removed from this fork — nothing stows or runs them anymore.

### What I actually run

If you want the setup in the screenshots above, this is the whole thing:

```
stow hypr quickshell matugen wallpapers ghostty tmux zsh nvim btop fastfetch gtk satty (recommend you get `kitty` as well initially since hyprland depends on it as the default terminal on a fresh install)
```

`bluetui`, `impala`, `wiremix` and `yazi` are standalone TUIs - I still use some of them, just on their defaults, so their configs here are take-it-or-leave-it.

| Package | What it does | Files |
| --- | --- | --- |
| `bluetui` | TUI for bluetooth | [bluetui](https://github.com/Yanis02015/nixos-config/tree/master/dots/bluetui/.config/bluetui) |
| `btop` | Resource monitor | [btop](https://github.com/Yanis02015/nixos-config/tree/master/dots/btop/.config/btop) |
| `fastfetch` | System info on shell start | [fastfetch](https://github.com/Yanis02015/nixos-config/tree/master/dots/fastfetch/.config/fastfetch) |
| `ghostty` | Terminal emulator - the daily driver | [ghostty](https://github.com/Yanis02015/nixos-config/tree/master/dots/ghostty/.config/ghostty) |
| `gtk` | GTK 3 and GTK 4 theme settings, so GTK apps match the rest | [gtk](https://github.com/Yanis02015/nixos-config/tree/master/dots/gtk/.config) |
| `hypr` | Hyprland compositor: Lua modules for bindings, monitors, tiling and window rules, plus hyprlock / hypridle / hyprpaper / hyprsunset | [hypr](https://github.com/Yanis02015/nixos-config/tree/master/dots/hypr/.config/hypr) |
| `impala` | TUI for wifi (iwd) | [impala](https://github.com/Yanis02015/nixos-config/tree/master/dots/impala/.config/impala) |
| `matugen` | Generates the Material You colour palette from the current wallpaper; everything else reads its output | [matugen](https://github.com/Yanis02015/nixos-config/tree/master/dots/matugen/.config/matugen) |
| `nvim` | Neovim: LSP, plugins and colours | [nvim](https://github.com/Yanis02015/nixos-config/tree/master/dots/nvim/.config/nvim) |
| `quickshell` | Custom QtQuick desktop shell: bar, menus, OSDs and launcher. Two bars live here, `minimalBar` and `onebarV2`. Setup requires matugen for dynamic color switching. | [quickshell](https://github.com/Yanis02015/nixos-config/tree/master/dots/quickshell/.config/quickshell) |
| `satty` | Screenshot annotation tool | [satty](https://github.com/Yanis02015/nixos-config/tree/master/dots/satty/.config/satty) |
| `tmux` | Terminal multiplexer | [tmux](https://github.com/Yanis02015/nixos-config/tree/master/dots/tmux/.config/tmux) |
| `wallpapers` | The wallpaper collection - lands at `~/Wallpapers`, which is where `rotate_wallpaper.sh` looks | [wallpapers](https://github.com/Yanis02015/nixos-config/tree/master/wallpapers/Wallpapers) |
| `wiremix` | TUI mixer for PipeWire audio | [wiremix](https://github.com/Yanis02015/nixos-config/tree/master/dots/wiremix/.config/wiremix) |
| `yazi` | Terminal file manager | [yazi](https://github.com/Yanis02015/nixos-config/tree/master/dots/yazi/.config/yazi) |
| `zsh` | Shell config with the powerlevel10k prompt (`.zshrc`, `.p10k.zsh`) | [zsh](https://github.com/Yanis02015/nixos-config/tree/master/dots/zsh) |

## Not stow packages

Three directories are in here but are not meant to be symlinked:

- [`nixos`](https://github.com/Yanis02015/nixos-config/tree/master/nixos) - the system config (`flake.nix`, `configuration.nix`, `packages.nix`). Rebuild straight from the repo, don't stow it.
- [`scripts`](https://github.com/Yanis02015/nixos-config/tree/master/scripts) - helper scripts. The configs call them by their repo path (`~/nixos-config/scripts/rotate_wallpaper.sh`), so they run in place.
- [`assets`](https://github.com/Yanis02015/nixos-config/tree/master/assets) - the screenshot at the top of this README. Nothing reads it at runtime.

## Credits

This repo is a fork of [Leabua/dotfiles](https://github.com/Leabua/dotfiles). The overall structure, the Hyprland/quickshell/matugen setup and most of the original dotfiles are their work - full credit to them. See [`CLAUDE.md`](./CLAUDE.md) for the detailed list of what's been changed since forking.
