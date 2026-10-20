# Terminal Noir for Powerlevel10k

Color overrides for [Powerlevel10k](https://github.com/romkatv/powerlevel10k), built for the classic and rainbow styles.

![Terminal Noir for Powerlevel10k](../../assets/screenshots/p10k.png)

## Install

In `.zshrc`, source the overrides right after your p10k config:

```zsh
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
source /path/to/terminalnoir/ports/p10k/terminal-noir.p10k.zsh
```

Open a new shell (or `exec zsh`).

The git status details (`!3 ?1`) are colored inside `my_git_formatter` in `~/.p10k.zsh`, where an outside file cannot reach. For full coverage, change its `meta`, `clean`, `modified`, `untracked` and `conflicted` colors to `%F{#A1A1AA}`, `%F{#34D399}`, `%F{#FACF9E}`, `%F{#79C0FF}` and `%F{#FFB7B0}`.
