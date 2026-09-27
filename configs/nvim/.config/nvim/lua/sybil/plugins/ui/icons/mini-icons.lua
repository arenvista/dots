-- File/filetype icons. which-key uses mini.icons as its icon provider when it
-- is available (arrow.nvim does too); setup() adds its highlight groups and
-- caching. Loaded on first require.
--
-- This used to install all of mini.nvim -- never set up, but loaded at startup
-- -- whose copies of mini.ai / mini.pairs / mini.indentscope shadowed the
-- standalone plugins of the same name: those configs ran against mini.nvim's
-- modules, not the repos (and lazy-lock pins) they declare.
return {
    "echasnovski/mini.icons",
    lazy = true,
    opts = {},
}
