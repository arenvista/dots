return{
    'RaafatTurki/hex.nvim',
    cmd = { "HexToggle", "HexDump", "HexAssemble" },
    config = function()
        require'hex'.setup({})
    end,
}
