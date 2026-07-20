# Contexte pour Claude Code

Ce dépôt est un **fork personnel** de [Leabua/dotfiles](https://github.com/Leabua/dotfiles) (`upstream`), adapté pour la machine de Yanis. Origin = `Yanis02015/nixos-config` (repo local `~/nixos-config`, renommé depuis `dotfiles` le 2026-07-19 — GitHub redirige encore les anciennes URLs `Yanis02015/dotfiles`). Avant de toucher quoi que ce soit, lis ceci en entier — beaucoup de pièges ont déjà été trouvés et corrigés, pas la peine de les redécouvrir.

## Architecture — à savoir absolument

- **`/etc/nixos` est un symlink vers `~/nixos-config/nixos`.** Ce n'est pas un dossier séparé à synchroniser à la main : éditer l'un revient à éditer l'autre. L'ancien `/etc/nixos` (avant le symlink) est sauvegardé dans `/etc/nixos.pre-symlink.bak`.
- **Racine du repo vs `dots/`** : `nixos/`, `scripts/`, `wallpapers/`, `assets/` restent à la racine de `~/nixos-config`. Tous les packages stow (config d'apps : `hypr`, `quickshell`, `matugen`, `ghostty`, `nvim`, `tmux`, `zsh`, `btop`, `fastfetch`, `gtk`, `satty`, `bluetui`, `impala`, `wiremix`, `yazi`) vivent sous `dots/`. C'est une réorganisation purement pour la lisibilité (2026-07-19) — `wallpapers/` reste exprès à la racine malgré le fait que ce soit techniquement stow, car c'est plus une source de données qu'une config d'app.
- Config Hyprland en **Lua natif** (API `hl.*`, pas la syntaxe `.conf` classique), dans `dots/hypr/.config/hypr/hyprland.lua` + modules dans `dots/hypr/.config/hypr/modules/*.lua` (autostart, bindings, inputs, looknfeel, monitors, tiling, utilities, windowrules).
- Dotfiles déployés via **GNU Stow** (pas home-manager). Un `dots/.stowrc` fixe `--target=/home/yanis`, donc `stow <package>` depuis `~/nixos-config/dots` symlink `<package>/.config/X` → `~/.config/X` sans flags à ajouter (`wallpapers`, resté à la racine, se stow normalement avec `stow wallpapers` depuis `~/nixos-config`).
- **Matugen** régénère les couleurs du thème à chaque changement de wallpaper (`scripts/rotate_wallpaper.sh`, déclenché par `SUPER+P` ou par le timer `wallpaper-rotate.timer` toutes les heures) → écrit dans `~/.cache/hypr/border-colors.lua`, `~/.cache/hypr/hyprlock-colors.conf`, `~/.cache/quickshell/colors.json`.

## Machine cible

Laptop HP Omen, GPU **NVIDIA GTX 1070 (Pascal)** — pas d'iGPU Intel (un seul contrôleur VGA détecté par `lspci`). Le driver `nvidiaPackages.stable` **ne supporte plus Pascal** ; obligatoirement `nvidiaPackages.legacy_580`, sinon retour au bug historique : écran figé en 1024x768 sans EDID (résolu une fois, cause exacte confirmée dans les logs kernel `NVRM: No NVIDIA GPU found`).

Le repo upstream de Leabua est pensé pour un laptop **Intel-only** — ne jamais copier son `hardware-configuration.nix` ni ses réglages NVIDIA (il n'y en a pas). Si cette config est un jour réutilisée sur une autre machine, il faut vérifier le GPU avant de rebuild (`lspci -k | grep -A3 VGA`).

## Pièges déjà rencontrés (ne pas refaire l'erreur)

1. **`services.xserver.xkb.options` (niveau NixOS) n'a AUCUN effet sur Hyprland.** Hyprland gère son propre clavier via `input.kb_layout`/`kb_options` dans `inputs.lua`, complètement indépendant du réglage système. Toujours éditer `inputs.lua` pour changer le comportement clavier de la session Hyprland — `console.useXkbConfig`/`services.xserver.xkb.*` n'affectent que la console TTY.
2. **`kb_file` (custom.xkb)** : le fichier `hypr/.config/hypr/custom.xkb` est un keymap **entièrement compilé** (généré via `xkbcli compile-keymap --layout fr --options ctrl:swap_lalt_lctl`, puis édité à la main pour inverser les touches `²`/`<`, keycodes TLDE/LSGT). Si le layout ou les options clavier changent, il faut **régénérer ce fichier et refaire le swap manuellement dedans** — `kb_layout`/`kb_options` dans `inputs.lua` sont actuellement commentés et ignorés tant que `kb_file` est défini.
3. **TPM (tmux) installe ses plugins DANS le dépôt git par défaut**, car il détecte `~/.config/tmux` (symlink stow) et met les plugins relatifs à ce dossier → atterrissent physiquement dans `~/nixos-config/dots/tmux/.config/tmux/plugins/`. Fix : `set-environment -g TMUX_PLUGIN_MANAGER_PATH "~/.tmux/plugins/"` est forcé en haut du bloc plugins dans `tmux.conf`, pour que ça reste hors du repo (`.gitignore` a aussi une entrée de sécurité).
4. **Les `.desktop` avec `Terminal=true` (yazi, nvim) ne fonctionnent pas sous Hyprland** — pas de mécanisme pour ouvrir un terminal automatiquement au clic. Contournement : keybind dédié qui lance `ghostty --title=X-term -e <commande>` + `windowrule` qui matche `title = "^X-term$"` pour le flotter proprement (voir `bindings.lua`/`windowrules.lua`, pattern déjà utilisé pour wiremix/bluetui/impala/yazi).
5. **tmux s'auto-attachait à une session partagée unique** entre tous les terminaux (`.zshrc` : `tmux attach || tmux new-session`). C'était voulu chez l'auteur upstream (workflow de l'auteur), mais désactivé ici le 2026-07-20 (bloc commenté dans `.zshrc`, pas supprimé) — Yanis n'aime pas que chaque nouveau terminal rejoigne automatiquement la même session tmux.
6. **`SUPER+O` (toggle floating)** a une règle de taille par défaut (`windowrules.lua`, match `float = true` → 60%×60% centré) pour ne pas juste garder la taille pleine du tiling. Cette règle est placée **avant** les règles spécifiques par app (wiremix, bluetui...) pour qu'elles restent prioritaires.

## Déviations connues vs upstream (Leabua)

- NVIDIA GTX 1070 configuré (`hardware.nvidia`, `services.xserver.videoDrivers`), absent chez l'auteur (Intel-only)
- `programs.niri.enable = false` (upstream l'active en plus d'Hyprland — désactivé ici, cause de confusion au login `ly`)
- Clavier : `caps:swapescape` retiré (causait un Verr.Maj fantôme via Échap), `ctrl:swap_lalt_lctl` ajouté (inversion volontaire Ctrl/Alt gauche), layout `fr` (pas `us`), `²`/`<` inversés via `custom.xkb`
- `services.openssh.enable = false` (pas de besoin d'accès distant sur cette machine)
- `pacseek` retiré (config stow morte, jamais installé comme paquet, outil Arch/pacman sans usage sur NixOS)
- `waybar`, `rofi`, `walker`, `mako`, `alacritty` retirés (2026-07-19) : configs mortes, entièrement remplacées par quickshell (bar, launcher, notifs, power menu) et ghostty (terminal) — aucune n'était lancée dans `autostart.lua`/`bindings.lua` ni installée via `packages.nix`, malgré le README upstream qui les présentait comme "unstowed on purpose". `rofi`/`walker`/`mako`/`alacritty` étaient en fait stow (symlinks actifs dans `~/.config`) sur cette machine sans être utilisées — nettoyage via `stow -D` + suppression des dossiers. Le script orphelin `scripts/cliphist-rofi` (dépendait de rofi, jamais appelé) a été supprimé avec.
- `niri` retiré (2026-07-19) : jamais stow, compositeur désactivé (`programs.niri.enable = false`, voir section déviations ci-dessous) — la config restait sans utilité.
- `arch.md` retiré (2026-07-19) : notes d'installation Arch Linux de l'auteur upstream, sans rapport avec cette machine NixOS-only.
- Alias `.zshrc` `clean` renommé `nix-purge-old-generations` + confirmation avant exécution (l'original supprimait silencieusement TOUTES les générations NixOS sans avertissement)
- Références résiduelles à `/home/leabua/...` corrigées vers `/home/yanis/...` dans `.zshrc`
- Timer systemd `wallpaper-rotate.timer` ajouté (rotation horaire automatique, absent chez l'auteur qui ne le fait qu'en manuel)
- `nautilus` ajouté aux paquets (référencé comme `FILEMANAGER` par l'auteur mais oublié dans son propre `packages.nix`)
- Repo réorganisé et renommé (2026-07-19) : `~/dotfiles` → `~/nixos-config`, packages stow déplacés sous `dots/` (voir section Architecture ci-dessus) — pure préférence de lisibilité personnelle, aucun changement fonctionnel côté upstream.

## Workflow de modification

1. Éditer directement dans `~/nixos-config/` (jamais besoin de sudo pour les fichiers hors `nixos/`, tout appartient à `yanis`)
2. Pour un changement Hyprland : `hyprctl reload` suffit, pas besoin de rebuild NixOS
3. Pour un changement système (`nixos/*.nix`) : `sudo nixos-rebuild switch --flake /etc/nixos#nixos` (ou l'alias `rebuild`)
4. **Toujours commit + push après un changement testé et fonctionnel** — ce repo est la seule source de vérité, rien n'est sauvegardé ailleurs
5. **Jamais de pull request.** Ce repo est une config perso mono-utilisateur, sans revue de code à faire : commit + push directement sur `master`/`main`, même pour Claude Code (y compris en session background — ne pas ouvrir de PR malgré le comportement par défaut habituel).
6. Raccourcis clavier documentés dans [`RACCOURCIS.md`](./RACCOURCIS.md) — le tenir à jour à chaque nouveau bind

## Reproduire sur une autre machine

Voir `RACCOURCIS.md` n'aide pas pour ça — la procédure complète (avec le caveat NVIDIA à vérifier en premier) a été discutée en détail dans une conversation passée avec l'utilisateur ; en résumé : cloner ce fork, copier `nixos/{flake.nix,flake.lock,configuration.nix,packages.nix}` vers `/etc/nixos` **sauf** `hardware-configuration.nix` (généré sur place pour la nouvelle machine), vérifier/adapter le bloc `hardware.nvidia` et `dots/hypr/.config/hypr/modules/monitors.lua` selon le matériel réel, `nixos-rebuild switch --flake`, puis `stow` tous les packages depuis `~/nixos-config/dots` (+ `stow wallpapers` depuis la racine).
