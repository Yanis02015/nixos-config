# macOS : le Terminal d'Apple (/etc/zshrc_Apple_Terminal) tient sinon un historique par
# fenêtre (~/.zsh_sessions) fusionné dans ~/.zsh_history, alors que .zshrc utilise
# ~/.histfile → l'historique semblait perdu à chaque fermeture. Doit être dans .zshenv,
# lu avant /etc/zshrc. Sans effet sous Linux.
export SHELL_SESSIONS_DISABLE=1
