# MCP Neovim Integration Rollback Procedure

## 설정 롤백

```bash
cd ~/git/env
git checkout base/.config/nvim/lua/plugins/mcp.lua
stow -t ~ base
```

## 플러그인 제거

```vim
:Lazy
# mcphub.nvim, codecompanion.nvim 선택 후 X로 삭제
```

## 환경변수 제거 (선택사항)

```bash
# ~/.key에서 관련 행 주석 처리
vim ~/.key
source ~/.key
```

## 완전 제거

```bash
cd ~/git/env
rm base/.config/nvim/lua/plugins/mcp.lua
stow -t ~ base
```
