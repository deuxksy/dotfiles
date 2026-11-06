#!/bin/sh
# ttyd 시작 시 TTYD tmux 세션에 자동 attach — 세션이 없으면 tmuxp로 생성
tmux has-session -t TTYD 2>/dev/null || tmuxp load -d ttyd
exec tmux attach -t TTYD
