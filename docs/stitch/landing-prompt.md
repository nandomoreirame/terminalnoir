# Stitch prompt: terminalnoir.dev landing page

Sent to Google Stitch to start the site design. Inspiration: [Dracula Theme](https://draculatheme.com/) and [Catppuccin](https://catppuccin.com/).

## Design system

- Mode: dark. Seed/primary `#F5A623`, neutral `#0B0B0C`, secondary `#34D399`, tertiary `#FACF9E`.
- Fonts: Newsreader (headlines), Inter (body), JetBrains Mono (labels, code).
- Roundness: 8px.

## Prompt

Landing page for **Terminal Noir** (terminalnoir.dev), an open-source color theme for developers' desktops, editors and terminals, in the tradition of Dracula Theme (draculatheme.com) and Catppuccin (catppuccin.com).

Take from Dracula: the confident single-page hero with the theme name front and center, a big searchable grid of supported apps where each card links to that app's install page, and a strong "made by the community, MIT licensed" footer. Take from Catppuccin: showing the palette itself as the hero of the story, with swatches labelled by role and hex, a dark/light variant switcher, and a calm, crafted tone. Keep it more restrained than both: Terminal Noir is a noir mood, not a pastel or neon one.

Visual language: cold near-black surfaces stepped by luminance, one warm amber accent used sparingly, an emerald status color. Editorial serif headlines (Newsreader), clean sans body (Inter), and monospace (JetBrains Mono) for anything a machine would say: labels, hex codes, commands, small eyebrows. Thin 1px hairline borders, generous negative space, no gradients, no glow, no glassmorphism. Amber appears only on the primary call to action, focus states, the cursor and small highlights.

Exact colors (dark): background #0B0B0C, raised surface #121214, elevated surface #18181B, hairline #222226, outline #3F3F46, selection #52525B, text #F4F4F5, muted text #A1A1AA, faint text #6B6B74, amber accent #F5A623 (text on it #0B0B0C), success #34D399, warning #FACF9E, error #FFB7B0, info #79C0FF.
Light variant: background #FBFAF7, surface #F1EFEA, elevated #E9E6DF, text #1C1A17, muted #5E5A53, accent #865700, success #047857, error #B42318.

Sections, in order:

1. **Header**: wordmark "terminal noir" in lowercase monospace with a blinking amber block cursor; links Ports, Palette, Contribute, GitHub; a small dark/light toggle.
2. **Hero**: serif headline "A noir theme for everything you type in." Subline: "Cold near-black surfaces, one amber accent. One palette, generated into every app you use." Primary button "Browse ports" (amber), secondary ghost button "View palette". To the right, a realistic mock of a terminal window themed in Terminal Noir showing a short shell session: a Powerlevel10k-style prompt with an amber OS icon and directory, an emerald git branch, then `bat` printing a few lines of syntax-highlighted code (amber keywords, emerald strings, blue functions, muted italic comments).
3. **Palette**: title "The palette". A row of large swatches for the surfaces (base, raised, elevated, outline) and a row for the accents (amber, emerald, warning, error, info), each with its role name and hex in monospace, click to copy. A dark/light segmented switch above it, like Catppuccin's flavor switcher. Below, a compact strip of the 16 ANSI colors.
4. **Ports grid**: title "Ports" with a search field and a count ("11 apps and growing"). Dracula-style grid of cards, each with the app icon, name and a small tag for variants ("dark · light" or "dark"): Noctalia, niri, Ghostty, VS Code, Cursor, GTK, Google Chrome, bat, btop, fzf, Powerlevel10k, Obsidian. The last card is a dashed "Request a port" card.
5. **How it works**: three short columns with a monospace step number: "01 One palette" (palette.json is the single source of truth), "02 Generated ports" (`make build` writes every app's theme from it), "03 Tested" (a check fails if any port drifts from the palette). Show `make build` in a small code block.
6. **Install example**: a tabbed code block (Ghostty, VS Code, bat) with the real install commands, copy buttons on each.
7. **Contribute**: short paragraph inviting new ports, with a GitHub button and a link to the contributing guide.
8. **Footer**: "Terminal Noir. MIT licensed. Born from the design of nandomoreira.dev." Links to GitHub and the palette JSON.

Desktop first, 1280px wide, responsive. Accessible contrast (AA or better), visible focus rings in amber.
