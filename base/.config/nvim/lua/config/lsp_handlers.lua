--------------------------------------------------------------------------------
-- LSP 공통 핸들러 (모든 LSP 서버에 적용)
--------------------------------------------------------------------------------
local M = {}

-- LSP 키매핑 설정 (on_attach에서 호출)
function M.on_attach(client, bufnr)
    local bufopts = { noremap = true, silent = true, buffer = bufnr }

    -- 네비게이션
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
    vim.keymap.set('n', 'gt', vim.lsp.buf.type_definition, bufopts)

    -- 정보 표시
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
    vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, bufopts)

    -- 코드 액션
    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, bufopts)
    vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, bufopts)
    vim.keymap.set('n', '<leader>fm', function()
        vim.lsp.buf.format({ async = true })
    end, bufopts)

    -- 진단 정보
    vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, bufopts)
    vim.keymap.set('n', ']d', vim.diagnostic.goto_next, bufopts)
    vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, bufopts)
    vim.keymap.set('n', '<leader>dq', vim.diagnostic.setloclist, bufopts)
end

-- LSP capabilities 설정 (nvim-cmp 연동)
function M.get_capabilities()
    local capabilities = vim.lsp.protocol.make_client_capabilities()

    -- nvim-cmp 연동 (선택적 의존성)
    local ok, cmp_lsp = pcall(require, 'cmp_nvim_lsp')
    if ok then
        capabilities = cmp_lsp.default_capabilities(capabilities)
    end

    return capabilities
end

return M
