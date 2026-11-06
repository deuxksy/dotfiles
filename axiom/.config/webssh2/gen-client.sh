#!/usr/bin/env bash
# webssh2_client client.htm에 Hack Nerd Font 웹폰트 주입
# 이미지 업데이트 후 클라이언트가 바뀌면 재실행 (원본은 client.htm.orig로 보존)
# 실행 컨테이너에서 꺼내면 bind mount된 패치본을 재독하므로 docker create로
# 이미지 원본에서 직접 추출한다 — 컨테이너 기동 전(신규 기기)에도 동작
# usage: gen-client.sh [image=ghcr.io/billchurch/webssh2:latest]
set -euo pipefail

image=${1:-ghcr.io/billchurch/webssh2:latest}
src=/srv/webssh2/node_modules/webssh2_client/client/public/client.htm
outdir=$HOME/.local/share/webssh2
mkdir -p "$outdir"

cid=$(docker create "$image")
trap 'docker rm -f "$cid" >/dev/null 2>&1 || true' EXIT
docker cp "$cid:$src" "$outdir/client.htm.orig"
cp "$outdir/client.htm.orig" "$outdir/client.htm"

perl -0pi -e 's{(<head>)}{$1
<style id="hack-nerd-font">
  /* 태블릿 등 로컬 폰트 없는 기기용 웹폰트 — ttyd와 동일한 CDN 원본 */
  \@font-face {
    font-family: "Hack Nerd Font";
    src: url(https://cdn.jsdelivr.net/gh/ryanoasis/nerd-fonts\@v3.4.0/patched-fonts/Hack/Regular/HackNerdFont-Regular.ttf) format("truetype");
    font-display: swap;
  }
  .terminal, .xterm-screen, .xterm-rows, .terminal .xterm-rows > div {
    font-family: "Hack Nerd Font", monospace !important;
  }
</style>}' "$outdir/client.htm"

grep -q 'hack-nerd-font' "$outdir/client.htm" || { echo "injection failed" >&2; exit 1; }
echo "written: $outdir/client.htm"
