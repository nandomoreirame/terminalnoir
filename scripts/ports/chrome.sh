# shellcheck shell=bash
# Google Chrome / Chromium theme extension (MV3, dark). Chrome themes have no
# light variant. Output: ports/chrome/manifest.json

build_chrome() {
    jq '
        def rgb: ltrimstr("#") | [.[0:2], .[2:4], .[4:6]]
            | map(explode
                | map(if . >= 65 and . <= 70 then . - 55 elif . >= 97 then . - 87 else . - 48 end)
                | .[0] * 16 + .[1]);
        .variants.dark as $c
        | {
            manifest_version: 3,
            name: "Terminal Noir",
            version: .version,
            description: "Terminal Noir: cold near-black surfaces with an amber accent. https://terminalnoir.web.app",
            theme: { colors: {
                frame: ($c.surface.base | rgb),
                frame_inactive: ($c.surface.base | rgb),
                frame_incognito: ($c.surface.raised | rgb),
                frame_incognito_inactive: ($c.surface.raised | rgb),
                toolbar: ($c.surface.elevated | rgb),
                toolbar_text: ($c.text.primary | rgb),
                toolbar_button_icon: ($c.accent.primary | rgb),
                tab_text: ($c.text.primary | rgb),
                tab_background_text: ($c.text.muted | rgb),
                tab_background_text_inactive: ($c.text.muted | rgb),
                bookmark_text: ($c.text.primary | rgb),
                omnibox_background: ($c.surface.base | rgb),
                omnibox_text: ($c.text.primary | rgb),
                ntp_background: ($c.surface.base | rgb),
                ntp_text: ($c.text.primary | rgb),
                ntp_link: ($c.accent.primary | rgb)
            } }
        }' "$PALETTE" > "$OUT/ports/chrome/manifest.json"
}
