# shellcheck shell=bash
# Noctalia shell color palette (Material-style roles), dark and light.
# Output: ports/noctalia/Terminal Noir.json

build_noctalia() {
    jq '
        def roles($c): {
            mPrimary: $c.accent.primary,
            mOnPrimary: $c.accent.onPrimary,
            mSecondary: $c.accent.success,
            mOnSecondary: $c.accent.onPrimary,
            mTertiary: $c.accent.warning,
            mOnTertiary: $c.accent.onPrimary,
            mError: $c.accent.error,
            mOnError: $c.accent.onPrimary,
            mSurface: $c.surface.base,
            mOnSurface: $c.text.primary,
            mHover: $c.accent.primary,
            mOnHover: $c.accent.onPrimary,
            mSurfaceVariant: $c.surface.elevated,
            mOnSurfaceVariant: $c.text.muted,
            mOutline: $c.surface.outline,
            mShadow: $c.surface.shadow,
            terminal: {
                background: $c.surface.base,
                foreground: $c.text.primary,
                cursor: $c.accent.primary,
                cursorText: $c.accent.onPrimary,
                selectionBg: $c.surface.selection,
                selectionFg: $c.text.primary,
                normal: $c.ansi.normal,
                bright: $c.ansi.bright
            }
        };
        { dark: roles(.variants.dark), light: roles(.variants.light) }
    ' "$PALETTE" > "$OUT/ports/noctalia/Terminal Noir.json"
}
