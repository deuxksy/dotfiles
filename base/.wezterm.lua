local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- ============================================================================
-- Font
-- ============================================================================
config.font = wezterm.font('Hack Nerd Font', { weight = 'Regular' })
config.font_size = 13.0
config.line_height = 1.1

-- ============================================================================
-- Color Scheme
-- ============================================================================
config.color_scheme = 'Catppuccin Mocha'

-- ============================================================================
-- Window
-- ============================================================================
config.window_decorations = 'RESIZE'
config.window_background_opacity = 0.92
config.macos_window_background_blur = 20
config.window_padding = {
  left = 8,
  right = 8,
  top = 4,
  bottom = 4,
}
config.initial_cols = 120
config.initial_rows = 36
config.enable_scroll_bar = false

-- ============================================================================
-- Tab Bar — tmux가 관리하므로 숨김
-- ============================================================================
config.hide_tab_bar_if_only_one_tab = true

-- ============================================================================
-- macOS
-- ============================================================================
config.macos_forward_to_ime_modifier_mask = 'SHIFT|CTRL'
config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = true

-- ============================================================================
-- Cursor
-- ============================================================================
config.default_cursor_style = 'BlinkingBlock'
config.cursor_blink_rate = 500
config.cursor_blink_ease_in = 'Constant'
config.cursor_blink_ease_out = 'Constant'

-- ============================================================================
-- tmux 최적화
-- ============================================================================
-- TERM — nix에서 terminfo 호환성 (wezterm terminfo 미설치 대응)
config.term = 'xterm-256color'

-- OSC 52 클립보드 — tmux/vim에서 시스템 클립보드 사용
config.enable_kitty_graphics = true

-- ============================================================================
-- ETC
-- ============================================================================
config.scrollback_lines = 10000
config.check_for_updates = false
config.audible_bell = 'Disabled'

return config
