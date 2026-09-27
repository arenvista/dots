return {
    "let-def/texpresso.vim",
    -- It attaches from after/ftplugin/tex.lua, so it only needs to be on the
    -- runtimepath once a .tex buffer opens (was loaded at startup).
    ft = "tex",
    cmd = "TeXpresso",
}
