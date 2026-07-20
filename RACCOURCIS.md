# Raccourcis — Hyprland (Leabua theme) & tmux

Vérifiés directement dans `~/nixos-config/dots/hypr/.config/hypr/modules/*.lua` et `~/nixos-config/dots/tmux/.config/tmux/tmux.conf`.

## Navigation générale (Hyprland)

| Raccourci | Action |
|---|---|
| `SUPER + Entrée` | Ouvrir un terminal (ghostty) |
| `SUPER + B` | Ouvrir le navigateur (zen-beta) |
| `SUPER + Shift + F` | Gestionnaire de fichiers (nautilus) |
| `SUPER + Shift + E` | Yazi (gestionnaire de fichiers en TUI) dans une fenêtre flottante |
| `SUPER + Shift + O` | Ouvrir Obsidian |
| `SUPER + Espace` | Launcher Quickshell (recherche d'applis) |
| `SUPER + Alt + Espace` | Basculer le panneau de droite (Quickshell) |
| `SUPER + N` | Panneau de notifications |
| `SUPER + C` | Panneau presse-papier |
| `SUPER + R` | Panneau rappels/reminders |
| `SUPER + Shift + Espace` | Cacher/afficher la barre Quickshell |
| `SUPER + P` | Changer de wallpaper manuellement (régénère les couleurs Matugen) |
| `SUPER + Ctrl + L` | Verrouiller l'écran (hyprlock) |

**Rotation automatique** : le wallpaper change aussi tout seul, **toutes les heures**, via le timer systemd `wallpaper-rotate.timer` (première rotation 5 min après connexion). `SUPER + P` reste dispo pour forcer un changement à tout moment. Pour vérifier/gérer le timer :
```
systemctl --user list-timers wallpaper-rotate.timer
systemctl --user status wallpaper-rotate.timer
```

## Fenêtres

| Raccourci | Action |
|---|---|
| `SUPER + W` | Fermer la fenêtre active |
| `SUPER + O` | Basculer flottant/tuilé (flottant = 60%×60%, centré par défaut) |
| `SUPER + F` | Plein écran |
| `SUPER + H / J / K / L` | Naviguer entre fenêtres (gauche/bas/haut/droite, façon vim) |
| `SUPER + Tab` | Passer à la fenêtre ouverte suivante (cycle, sans aperçu visuel) |
| `SUPER + Shift + H/J/K/L` | Déplacer/échanger la fenêtre |
| `SUPER + glisser` (clic gauche, avec SUPER) | Déplacer une fenêtre flottante |
| `SUPER + Shift + S` | Réduire la fenêtre active (l'envoie dans le workspace spécial, sans la fermer) |
| `SUPER + S` | Afficher/cacher le workspace spécial (fait réapparaître les fenêtres réduites) |

## Workspaces

| Raccourci | Action |
|---|---|
| `SUPER + 1..0` | Aller au workspace 1 à 10 |
| `SUPER + ←` / `SUPER + →` | Aller au workspace précédent / suivant |
| `SUPER + Shift + 1..0` | Déplacer la fenêtre vers ce workspace (et la suivre) |
| `SUPER + Shift + Ctrl + 1..0` | Déplacer la fenêtre vers ce workspace (sans la suivre) |
| `SUPER + Shift + ←/→` | Déplacer la fenêtre active vers le workspace précédent/suivant (et la suivre) |
| `SUPER + Shift + Ctrl + ←/→` | Déplacer la fenêtre active vers le workspace précédent/suivant (sans la suivre) |
| `SUPER + Shift + N` | Déplacer la fenêtre active vers le prochain workspace vide |

Pas de "suppression" de workspace à proprement parler : un workspace disparaît tout seul dès qu'il n'a plus aucune fenêtre et n'est plus affiché.

## Barre Quickshell — icônes d'apps épinglées

Juste à gauche de l'île de droite (CPU/RAM/volume/batterie/wifi), sans background propre (posées nues à côté du pill), quelques icônes cliquables lancent directement une app — pas besoin de passer par le launcher (`SUPER + Espace`).

Actuellement épinglées : **Discord**, **Zed**.

Pour ajouter/retirer une app : éditer la liste `pins` dans [`dots/quickshell/.config/quickshell/minimalBar/barModules/PinnedApps.qml`](./dots/quickshell/.config/quickshell/minimalBar/barModules/PinnedApps.qml), format `{ icon: "<nom Icon= du .desktop de l'app>", command: ["binaire", "args"...] }`. L'icône est résolue depuis le thème d'icônes système (`Quickshell.iconPath`), donc `icon` doit correspondre au champ `Icon=` du fichier `.desktop` de l'app (`grep Icon= /run/current-system/sw/share/applications/<app>.desktop`), pas à un glyphe Nerd Font.

Aucun rebuild NixOS nécessaire. Pour voir le changement, il faut relancer quickshell (il ne fait pas de hot-reload) :
```
qs kill -p ~/.config/quickshell/minimalBar && qs -p ~/.config/quickshell/minimalBar &
```
(`qs -p` seul sans `kill` d'abord lance une 2ᵉ instance en double au lieu de remplacer la première.)

## Captures d'écran

| Raccourci | Action |
|---|---|
| `Print` | Capture d'une zone (sélection à la souris) → presse-papier |
| `SUPER + Print` | Capture de l'écran actif entier → presse-papier |

## Médias / système (touches spéciales du clavier)

| Touche | Action |
|---|---|
| Volume +/- | Régler le son |
| Mute / Micro mute | Couper le son / micro |
| Luminosité +/- | Régler la luminosité |
| Lecture/Pause/Suivant/Précédent | Contrôle média (playerctl) |
| Bouton Power | Ouvre le menu power de Quickshell |

---

## tmux (préfixe = `Ctrl + b`)

Souris activée — tu peux aussi cliquer sur les onglets/panneaux directement.

| Raccourci | Action |
|---|---|
| `Ctrl+b` puis `c` | Nouvelle fenêtre tmux |
| `Alt + 0..9` | Basculer directement vers la fenêtre N (sans préfixe) |
| `Ctrl+b` puis `v` | Scinder le panneau côte à côte |
| `Ctrl+b` puis `-` | Scinder le panneau en haut/bas |
| `Alt + H/J/K/L` | Naviguer entre panneaux (vim-style) |
| `Ctrl+b` puis `d` | Se détacher (la session continue en arrière-plan) |

### Sidebar (plugin tmux-pane-tree)

Arbre vertical sessions/fenêtres/panneaux sur le côté gauche.

| Raccourci | Action |
|---|---|
| `Ctrl+b` puis `t` | Afficher/cacher la sidebar |
| `Ctrl+b` puis `T` | Donner le focus à la sidebar |

Une fois le focus dans la sidebar :

| Touche | Action |
|---|---|
| `j` / `↓` | Descendre |
| `k` / `↑` | Monter |
| `gg` | Aller tout en haut |
| `G` | Aller tout en bas |
| `Entrée` | Sélectionner (aller à ce panneau/fenêtre) |
| `aw` | Ajouter une fenêtre |
| `as` | Ajouter une session |
| `x` | Fermer le panneau |
| `f` | Basculer le filtre |
| `p` | Cacher/afficher les panneaux |
| `q` | Quitter la sidebar |

**Important** : chaque nouveau terminal (`SUPER+Entrée`) se rattache automatiquement à la **même session tmux partagée** (configuré dans `.zshrc`). Ce n'est pas un bug — c'est voulu. Utilise `Ctrl+b c` pour une vraie nouvelle fenêtre de travail indépendante à l'intérieur de cette session.

---

## Clavier — inversion Ctrl/Alt gauche

Ctrl et Alt **gauche** sont inversés (`ctrl:swap_lalt_lctl` dans `inputs.lua`) : la touche physique "Ctrl gauche" envoie Alt, et "Alt gauche" envoie Ctrl. Ctrl/Alt droite sont normaux.

Conséquence directe : pour déclencher le préfixe tmux (`Ctrl+b`), il faut appuyer sur la touche physique **Alt gauche + b** (puisque le Ctrl gauche physique envoie maintenant Alt). Idem pour tout autre raccourci `Ctrl+...` habituel (copier/coller, etc.) tant que tu utilises la main gauche — utilise Ctrl/Alt **droite** si tu veux le comportement classique sans réfléchir.

(Échap et Verr. Maj, eux, sont redevenus normaux — l'inversion `caps:swapescape` du setup original a été retirée.)
