--------------------------------------------------------------------------------
-- OS 감지 및 크로스 플랫폼 유틸리티
--------------------------------------------------------------------------------
local M = {}

-- OS 감지
M.is_windows = vim.loop.os_uname().version:find("Windows") ~= nil
M.is_mac = vim.loop.os_uname().sysname == "Darwin"
M.is_linux = vim.loop.os_uname().sysname == "Linux"

-- 경로 구분자
M.path_sep = M.is_windows and "\\" or "/"

return M
