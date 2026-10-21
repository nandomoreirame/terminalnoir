# Changelog

All notable changes to this project are documented in this file.

This project adheres to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) and follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Add an iTerm2 port, `Terminal Noir.itermcolors` and `Terminal Noir Paper.itermcolors`, with both variants as color presets.
- Add a zsh port, `terminal-noir.zsh` and `terminal-noir-paper.zsh`, with zsh-syntax-highlighting and zsh-autosuggestions styles.
- Add a fish port, `terminal-noir.theme`, with light and dark sections that fish picks to match the terminal background.
- Add Alacritty, kitty, Hyper, Neovim and Vim, micro and Telegram Desktop ports, each with dark and light variants. The Telegram themes bring the noir and paper wallpapers.

## [0.1.0-beta] - 2026-10-20

### Added

- Add the Terminal Noir palette: a dark variant (Noir) of cold near-black surfaces stepped by luminance with one amber accent and an emerald status color, a light variant (Paper) on warm paper tones, 16 ANSI colors per variant, and syntax roles that point at palette names instead of raw hex.
- Add 12 generated ports: Noctalia and Ghostty (dark and light), niri, VS Code and Cursor, GTK 4 and libadwaita, Google Chrome, bat and delta, btop, fzf, Powerlevel10k, Obsidian and Shiki (dark and light), each with an install guide in English and Brazilian Portuguese and a screenshot.
- Add a Shiki port, `terminal-noir.json` and `terminal-noir-paper.json`, for highlighting code on websites with both variants.
- Add a contrast gate to the test suite: text, accents, syntax roles and ANSI colors must reach 4.5:1 and `text.faint` and `surface.outline` 3:1 on every surface of both variants, computed with a WCAG 2.1 library in jq.
- Add `scripts/build` to regenerate every port from `palette/palette.json`, with tests that fail when a committed port drifts from a fresh build.
- Add the VS Code installer and the GTK icon builder that recolors Adwaita folder icons to amber.
- Add the bilingual terminalnoir.web.app website, built from the palette, the port registry and each port's README, with port screenshots in a lightbox and a deploy to Firebase Hosting on every push to main.
- Add the noir and paper city wallpapers.

### Changed

- Darken 13 Paper colors and lighten the Noir bright black and outline, keeping each hue, so every readable role passes WCAG AA on every surface.
- Ship the Chrome theme with a numeric `version` and the full release label in `version_name`, since Chrome accepts only dot-separated integers.
