#!/usr/bin/env zsh

emulate -L zsh
setopt pipe_fail

usage() {
  print -u2 -r -- "usage: ${0:t} [--smoke] [--] file.zsh ..."
  print -u2 -r -- "       parse with zsh -n by default; --smoke also executes under zsh -df"
}

integer smoke=0
while (( $# )); do
  case $1 in
    --smoke) smoke=1; shift ;;
    --) shift; break ;;
    -h|--help) usage; return 0 2>/dev/null || exit 0 ;;
    -*) print -u2 -r -- "${0:t}: unknown option: $1"; usage; return 2 2>/dev/null || exit 2 ;;
    *) break ;;
  esac
done

(( $# )) || {
  usage
  return 2 2>/dev/null || exit 2
}

integer failed=0
local file scratch
for file in "$@"; do
  if [[ ! -f $file ]]; then
    print -u2 -r -- "${0:t}: not a file: $file"
    failed=1
    continue
  fi

  if command zsh -f -n -- "$file"; then
    print -r -- "parse ok: $file"
  else
    failed=1
    continue
  fi

  if (( smoke )); then
    scratch=$(mktemp -d "${TMPDIR:-/tmp}/zsh-expert-smoke.XXXXXXXX") || {
      print -u2 -r -- "${0:t}: cannot create temporary ZDOTDIR"
      failed=1
      continue
    }
    {
      if command env ZDOTDIR="$scratch" zsh -df -- "$file"; then
        print -r -- "smoke ok: $file"
      else
        failed=1
      fi
    } always {
      command rm -rf -- "$scratch"
    }
  fi
done

return $failed 2>/dev/null || exit $failed
