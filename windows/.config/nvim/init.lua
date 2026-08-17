--------------------------------------------------------------------------------
-- 진입점: 모듈 로드 및 lazy.nvim 부트스트랩
--------------------------------------------------------------------------------

-- 1. Core 모듈 로드 (기본 설정, 키매핑, 자동 명령)
require("core.options")
require("core.keymaps")
require("core.autocmds")

-- 2. lazy.nvim 부트스트랩
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    if vim.fn.executable("git") == 0 then
        vim.notify("Git이 설치되지 않았습니다.", vim.log.levels.ERROR)
        return
    end

    local clone_ok, clone_result = pcall(vim.fn.system, {
        "git", "clone", "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath,
    })

    if not clone_ok or vim.v.shell_error ~= 0 then
        vim.notify("lazy.nvim 클론 실패: " .. tostring(clone_result), vim.log.levels.ERROR)
        return
    end

    vim.notify("lazy.nvim이 설치되었습니다. Neovim을 재시작해주세요.", vim.log.levels.INFO)
    return
end

vim.opt.rtp:prepend(lazypath)

-- 3. Plugin Manager 로드
local lazy_ok, lazy = pcall(require, "lazy")
if not lazy_ok then
    vim.notify("lazy.nvim 로드 실패", vim.log.levels.ERROR)
    return
end

lazy.setup("plugins")
