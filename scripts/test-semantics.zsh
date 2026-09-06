#!/usr/bin/env zsh
# Behavioral checks for the skill's native Zsh claims, not tests of user files.
# Execute under each supported Zsh. Optional modules report explicit skips.
emulate -LR zsh
setopt extendedglob

integer _ztest_checks=0 _ztest_failures=0 _ztest_skips=0

_ztest_equal() {
  emulate -L zsh
  (( ++_ztest_checks ))
  if [[ $2 != "$3" ]]; then
    print -u2 -r -- "FAIL $1: got ${(qqqq)2}, expected ${(qqqq)3}"
    (( ++_ztest_failures ))
  fi
  return 0
}

_ztest_array() {
  emulate -L zsh
  local label=$1 actual_name=$2 expected_name=$3
  local -a actual=("${(@P)actual_name}") expected=("${(@P)expected_name}")
  local -i i
  _ztest_equal "$label: cardinality" "$#actual" "$#expected"
  for (( i=1; i <= $#expected; ++i )); do
    _ztest_equal "$label: element $i" "${actual[i]}" "${expected[i]}"
  done
}

_ztest_skip() {
  print -r -- "SKIP $1"
  (( ++_ztest_skips ))
  return 0
}

local scratch
scratch=$(mktemp -d "${TMPDIR:-/tmp}/zsh-semantics.XXXXXXXX") || exit 1
{
  local -a items=('a b' '' '*' $'line\nbreak' 'a b') actual expected
  actual=($items)
  expected=('a b' '*' $'line\nbreak' 'a b')
  _ztest_array 'native unsubscripted expansion' actual expected
  actual=("${items[@]}")
  _ztest_array 'quoted array preserves empties' actual items
  _ztest_equal 'quoted unsubscripted array joins' "$items" "a b  * line
break a b"

  local -a drop=('*') pending common
  pending=("${(@)items:|drop}")
  expected=('a b' '' $'line\nbreak' 'a b')
  _ztest_array 'literal difference preserves order and duplicates' pending expected
  common=("${(@)items:*drop}")
  _ztest_array 'literal intersection' common drop
  _ztest_equal 'first literal reverse subscript' "${items[(ie)*]}" 3
  _ztest_equal 'forward miss sentinel' "${items[(ie)absent]}" 6
  _ztest_equal 'backward miss sentinel' "${items[(Ie)absent]}" 0

  local -a labels=(first second) values=('a b' '') pairs
  pairs=("${(@)labels:^values}")
  expected=(first 'a b' second '')
  _ztest_array 'zip preserves empty values' pairs expected
  local -A record=("${pairs[@]}")
  _ztest_equal 'association empty value exists' "${+record[second]}" 1
  _ztest_equal 'association value boundary' "$record[first]" 'a b'

  local literal='a b[*]' pattern
  pattern="*${(b)literal}*"
  [[ "before${literal}after" = ${~pattern} ]]
  _ztest_equal 'literal fragment in active pattern' "$?" 0
  [[ 'beforea bXafter' = ${~pattern} ]]
  _ztest_equal 'pattern does not reinterpret literal wildcard' "$?" 1

  local -a parts=(alpha beta) prefixed
  _ztest_equal 'inner array shape' "${${(@)parts}[1]}" alpha
  _ztest_equal 'inner scalar shape' "${(@)${parts}[1]}" a
  prefixed=("${(@)parts/#/src/}")
  expected=(src/alpha src/beta)
  _ztest_array 'elementwise replacement prefix' prefixed expected
  prefixed=(src/"${(@)^parts}".zsh)
  expected=(src/alpha.zsh src/beta.zsh)
  _ztest_array 'distributed surrounding text' prefixed expected
  local -a empty=()
  actual=(pre"${(@)^empty}"post)
  _ztest_equal 'empty product' "$#actual" 0

  local encoded=${(j: :)${(@q)items}}
  actual=("${(@Q)${(z)encoded}}")
  _ztest_array 'shell word serialization' actual items
  local split_input=':a::'
  actual=("${(@s.:.)split_input}")
  expected=('' a '' '')
  _ztest_array 'literal splitting retains all empty fields' actual expected

  local bytes=$'a\0b\n\n' readback
  builtin print -rn -- "$bytes" > "$scratch/bytes"
  zmodload zsh/system || exit 1
  local -i fd read_rc
  exec {fd}<"$scratch/bytes" || exit 1
  {
    sysread -i $fd -s 32 readback
    _ztest_equal 'sysread status' "$?" 0
    _ztest_equal 'NUL and final newlines survive builtin I/O' "$readback" "$bytes"
  } always {
    exec {fd}<&-
  }
  readback=$(<"$scratch/bytes")
  _ztest_equal 'command substitution trims only trailing newlines' "$readback" $'a\0b'
  actual=("${(@0)bytes}")
  expected=(a $'b\n\n')
  _ztest_array 'NUL splitting' actual expected

  # An open writer with an incomplete frame must not make a timed read wait.
  command mkfifo "$scratch/channel" || exit 1
  sysopen -rw -o nonblock -u fd "$scratch/channel" || exit 1
  {
    builtin print -rn -u $fd -- partial
    sysread -i $fd -t 0 -s 32 readback
    _ztest_equal 'read available partial frame' "$readback" partial
    sysread -i $fd -t 0 -s 32 readback
    read_rc=$?
    _ztest_equal 'open writer without available bytes gives timeout' "$read_rc" 4
  } always {
    exec {fd}>&-
  }

  local pipeline_line
  builtin print -r -- retained | read -r pipeline_line
  _ztest_equal 'foreground pipeline final read retains state' "$pipeline_line" retained
  local -a outcome
  false | true
  outcome=( "$?" "${pipestatus[@]}" )
  expected=(0 1 0)
  _ztest_array 'simultaneous pipeline statuses' outcome expected

  local cleanup_seen=0
  _ztest_cleanup() {
    { return 17 } always { cleanup_seen=1 }
  }
  _ztest_cleanup
  _ztest_equal 'always retains early return status' "$?" 17
  _ztest_equal 'always performs cleanup on return' "$cleanup_seen" 1

  _ztest_equal 'native shift precedence' "$((1 + 2 << 1))" 5
  _ztest_equal 'unary minus before exponentiation' "$((-3**2))" 9
  _ztest_equal 'integer division precedes float assignment' "$((3 / 8))" 0
  _ztest_equal 'floating operand preserves fraction' "$((3 / (1.0 * 8)))" 0.375
  _ztest_math() { (( $1 * $1 )); true }
  functions -M ztest_square 1 1 _ztest_math
  _ztest_equal 'math function zero result' "$((ztest_square(0)))" 0
  _ztest_equal 'math function nonzero result' "$((ztest_square(3)))" 9
  functions +M ztest_square

  _ztest_native() {
    emulate -L zsh
    local -a data=('one two' three)
    reply=("${data[@]}")
  }
  _ztest_foreign_caller() {
    emulate -L zsh
    setopt sh_word_split ksh_arrays glob_subst
    local -a reply
    _ztest_native
    [[ -o sh_word_split && -o ksh_arrays && -o glob_subst ]] || return 1
    [[ ${#reply[@]} == 2 && ${reply[0]} == 'one two' && ${reply[1]} == three ]]
  }
  _ztest_foreign_caller
  _ztest_equal 'native helper and caller options restored' "$?" 0

  local _ztest_secret=outer REPLY
  _ztest_private_child() { REPLY=${_ztest_secret-unset} }
  _ztest_private_parent() {
    local -P _ztest_secret=(inner private)
    _ztest_private_child
    _ztest_equal 'callee sees outer non-private value' "$REPLY" outer
    _ztest_equal 'parent retains private array' "$#_ztest_secret" 2
  }
  if zmodload zsh/param/private 2>/dev/null; then
    _ztest_private_parent
  else
    _ztest_skip 'zsh/param/private'
  fi

  command mkdir -p "$scratch/tree/sub" "$scratch/autoload" || exit 1
  local filename root="$scratch/tree"
  for filename in a.c b.c b.o .hidden.log old.log new.log sub/nested.c; do
    : > "$root/$filename"
  done
  command touch -t 202001010000 "$root/old.log" || exit 1
  command touch -t 202101010000 "$root/new.log" || exit 1
  actual=( "$root"/**/*.log(N.om[1]) )
  expected=( "$root/new.log" )
  _ztest_array 'glob newest selection excludes hidden names' actual expected
  actual=( "$root"/**/*.missing(N.) )
  _ztest_equal 'optional glob has no arguments on miss' "$#actual" 0
  _ztest_needs_peer() { [[ ! -e ${REPLY:r}.o ]] }
  actual=( "$root"/**/*.c(N.+_ztest_needs_peer) )
  expected=( "$root/a.c" "$root/sub/nested.c" )
  _ztest_array 'glob predicate receives each candidate' actual expected

  # Suppress an alias which exists before the autoload file is parsed.
  builtin print -r -- 'builtin print -r -- ztest_clean' > "$scratch/autoload/_ztest_loaded"
  fpath=("$scratch/autoload" "${fpath[@]}")
  alias -g ztest_clean=ztest_corrupt
  autoload -Uz _ztest_loaded
  readback=$(_ztest_loaded)
  unalias 'ztest_clean'
  _ztest_equal 'autoload -U defeats parse-time global alias' "$readback" ztest_clean

  local -a psvar=('%F{red}literal $(false)')
  builtin print -v readback -rP -- '%1v'
  _ztest_equal 'psvar does not recursively expand prompt syntax' "$readback" "$psvar[1]"

  if zmodload zsh/db/gdbm 2>/dev/null; then
    local -A db
    ztie -d db/gdbm -f "$scratch/cache.gdbm" db || exit 1
    db+=(key 'a b' empty '')
    zuntie db || exit 1
    local -A db
    ztie -r -d db/gdbm -f "$scratch/cache.gdbm" db || exit 1
    {
      _ztest_equal 'GDBM persists value boundaries' "$db[key]" 'a b'
      _ztest_equal 'GDBM distinguishes absent and empty' "${+db[empty]}:${+db[absent]}" 1:0
    } always {
      zuntie db
    }
  else
    _ztest_skip 'zsh/db/gdbm'
  fi
} always {
  command rm -rf -- "$scratch"
}

print -r -- "Zsh $ZSH_VERSION: $_ztest_checks checks, $_ztest_failures failures, $_ztest_skips module skips"
(( _ztest_failures == 0 ))
