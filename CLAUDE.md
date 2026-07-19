# Contexte pour Claude Code

Ce dépôt est un **fork personnel** de [Leabua/dotfiles](https://github.com/Leabua/dotfiles) (`upstream`), adapté pour la machine de Yanis. Origin = `Yanis02015/dotfiles`. Avant de toucher quoi que ce soit, lis ceci en entier — beaucoup de pièges ont déjà été trouvés et corrigés, pas la peine de les redécouvrir.

## Architecture — à savoir absolument

- **`/etc/nixos` est un symlink vers `~/dotfiles/nixos`.** Ce n'est pas un dossier séparé à synchroniser à la main : éditer l'un revient à éditer l'autre. L'ancien `/etc/nixos` (avant le symlink) est sauvegardé dans `/etc/nixos.pre-symlink.bak`.
- Config Hyprland en **Lua natif** (API `hl.*`, pas la syntaxe `.conf` classique), dans `hypr/.config/hypr/hyprland.lua` + modules dans `hypr/.config/hypr/modules/*.lua` (autostart, bindings, inputs, looknfeel, monitors, tiling, utilities, windowrules).
- Dotfiles déployés via **GNU Stow** (pas home-manager). `stow <package>` depuis `~/dotfiles` symlink `<package>/.config/X` → `~/.config/X`.
- **Matugen** régénère les couleurs du thème à chaque changement de wallpaper (`scripts/rotate_wallpaper.sh`, déclenché par `SUPER+P` ou par le timer `wallpaper-rotate.timer` toutes les heures) → écrit dans `~/.cache/hypr/border-colors.lua`, `~/.cache/hypr/hyprlock-colors.conf`, `~/.cache/quickshell/colors.json`.

## Machine cible

Laptop HP Omen, GPU **NVIDIA GTX 1070 (Pascal)** — pas d'iGPU Intel (un seul contrôleur VGA détecté par `lspci`). Le driver `nvidiaPackages.stable` **ne supporte plus Pascal** ; obligatoirement `nvidiaPackages.legacy_580`, sinon retour au bug historique : écran figé en 1024x768 sans EDID (résolu une fois, cause exacte confirmée dans les logs kernel `NVRM: No NVIDIA GPU found`).

Le repo upstream de Leabua est pensé pour un laptop **Intel-only** — ne jamais copier son `hardware-configuration.nix` ni ses réglages NVIDIA (il n'y en a pas). Si cette config est un jour réutilisée sur une autre machine, il faut vérifier le GPU avant de rebuild (`lspci -k | grep -A3 VGA`).

## Pièges déjà rencontrés (ne pas refaire l'erreur)

1. **`services.xserver.xkb.options` (niveau NixOS) n'a AUCUN effet sur Hyprland.** Hyprland gère son propre clavier via `input.kb_layout`/`kb_options` dans `inputs.lua`, complètement indépendant du réglage système. Toujours éditer `inputs.lua` pour changer le comportement clavier de la session Hyprland — `console.useXkbConfig`/`services.xserver.xkb.*` n'affectent que la console TTY.
2. **`kb_file` (custom.xkb)** : le fichier `hypr/.config/hypr/custom.xkb` est un keymap **entièrement compilé** (généré via `xkbcli compile-keymap --layout fr --options ctrl:swap_lalt_lctl`, puis édité à la main pour inverser les touches `²`/`<`, keycodes TLDE/LSGT). Si le layout ou les options clavier changent, il faut **régénérer ce fichier et refaire le swap manuellement dedans** — `kb_layout`/`kb_options` dans `inputs.lua` sont actuellement commentés et ignorés tant que `kb_file` est défini.
3. **TPM (tmux) installe ses plugins DANS le dépôt git par défaut**, car il détecte `~/.config/tmux` (symlink stow) et met les plugins relatifs à ce dossier → atterrissent physiquement dans `~/dotfiles/tmux/.config/tmux/plugins/`. Fix : `set-environment -g TMUX_PLUGIN_MANAGER_PATH "~/.tmux/plugins/"` est forcé en haut du bloc plugins dans `tmux.conf`, pour que ça reste hors du repo (`.gitignore` a aussi une entrée de sécurité).
4. **Les `.desktop` avec `Terminal=true` (yazi, nvim) ne fonctionnent pas sous Hyprland** — pas de mécanisme pour ouvrir un terminal automatiquement au clic. Contournement : keybind dédié qui lance `ghostty --title=X-term -e <commande>` + `windowrule` qui matche `title = "^X-term$"` pour le flotter proprement (voir `bindings.lua`/`windowrules.lua`, pattern déjà utilisé pour wiremix/bluetui/impala/yazi).
5. **tmux s'auto-attache à une session partagée unique** entre tous les terminaux (`.zshrc` : `tmux attach || tmux new-session`). C'est voulu (workflow de l'auteur), pas un bug — `Ctrl+b c` donne une vraie nouvelle fenêtre à l'intérieur de cette session partagée.
6. **`SUPER+O` (toggle floating)** a une règle de taille par défaut (`windowrules.lua`, match `float = true` → 60%×60% centré) pour ne pas juste garder la taille pleine du tiling. Cette règle est placée **avant** les règles spécifiques par app (wiremix, bluetui...) pour qu'elles restent prioritaires.

## Déviations connues vs upstream (Leabua)

- NVIDIA GTX 1070 configuré (`hardware.nvidia`, `services.xserver.videoDrivers`), absent chez l'auteur (Intel-only)
- `programs.niri.enable = false` (upstream l'active en plus d'Hyprland — désactivé ici, cause de confusion au login `ly`)
- Clavier : `caps:swapescape` retiré (causait un Verr.Maj fantôme via Échap), `ctrl:swap_lalt_lctl` ajouté (inversion volontaire Ctrl/Alt gauche), layout `fr` (pas `us`), `²`/`<` inversés via `custom.xkb`
- `services.openssh.enable = false` (pas de besoin d'accès distant sur cette machine)
- `pacseek` retiré (config stow morte, jamais installé comme paquet, outil Arch/pacman sans usage sur NixOS)
- Alias `.zshrc` `clean` renommé `nix-purge-old-generations` + confirmation avant exécution (l'original supprimait silencieusement TOUTES les générations NixOS sans avertissement)
- Références résiduelles à `/home/leabua/...` corrigées vers `/home/yanis/...` dans `.zshrc`
- Timer systemd `wallpaper-rotate.timer` ajouté (rotation horaire automatique, absent chez l'auteur qui ne le fait qu'en manuel)
- `nautilus` ajouté aux paquets (référencé comme `FILEMANAGER` par l'auteur mais oublié dans son propre `packages.nix`)

## Workflow de modification

1. Éditer directement dans `~/dotfiles/` (jamais besoin de sudo pour les fichiers hors `nixos/`, tout appartient à `yanis`)
2. Pour un changement Hyprland : `hyprctl reload` suffit, pas besoin de rebuild NixOS
3. Pour un changement système (`nixos/*.nix`) : `sudo nixos-rebuild switch --flake /etc/nixos#nixos` (ou l'alias `rebuild`)
4. **Toujours commit + push après un changement testé et fonctionnel** — ce repo est la seule source de vérité, rien n'est sauvegardé ailleurs
5. **Jamais de pull request.** Ce repo est une config perso mono-utilisateur, sans revue de code à faire : commit + push directement sur `master`/`main`, même pour Claude Code (y compris en session background — ne pas ouvrir de PR malgré le comportement par défaut habituel).
6. Raccourcis clavier documentés dans [`RACCOURCIS.md`](./RACCOURCIS.md) — le tenir à jour à chaque nouveau bind

## Reproduire sur une autre machine

Voir `RACCOURCIS.md` n'aide pas pour ça — la procédure complète (avec le caveat NVIDIA à vérifier en premier) a été discutée en détail dans une conversation passée avec l'utilisateur ; en résumé : cloner ce fork, copier `nixos/{flake.nix,flake.lock,configuration.nix,packages.nix}` vers `/etc/nixos` **sauf** `hardware-configuration.nix` (généré sur place pour la nouvelle machine), vérifier/adapter le bloc `hardware.nvidia` et `hypr/.config/hypr/modules/monitors.lua` selon le matériel réel, `nixos-rebuild switch --flake`, puis `stow` tous les packages depuis `~/dotfiles`.
