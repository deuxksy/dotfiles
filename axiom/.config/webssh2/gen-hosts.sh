#!/usr/bin/env bash
# WebSSH2 호스트 config 생성 — PEM 개인키의 JSON escape를 jq에 위임
# usage: gen-hosts.sh <alias> <host> <user> [keypath=~/.ssh/id_ed25519]
set -euo pipefail

usage() {
  echo "usage: $0 <alias> <host> <user> [keypath=~/.ssh/id_ed25519]" >&2
  exit 1
}

[ $# -ge 3 ] && [ $# -le 4 ] || usage
alias_name=$1
host=$2
user=$3
keypath=${4:-$HOME/.ssh/id_ed25519}

[ -f "$keypath" ] || { echo "key not found: $keypath" >&2; exit 1; }

outdir=$HOME/.local/share/webssh2/hosts
mkdir -p "$outdir"

jq -n --arg h "$host" --arg u "$user" --arg k "$(cat "$keypath")" \
  '{ssh:{host:$h}, user:{name:$u, privateKey:$k}}' > "$outdir/$alias_name.json"

echo "written: $outdir/$alias_name.json"
