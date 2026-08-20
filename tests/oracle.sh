#!/usr/bin/env sh
# What the tools produce, compared with what the system produces.
#
#   oracle.sh <directory holding the built tools>
#
# Two kinds of comparison, and the difference matters.
#
#   Against the system's own tool. `wc', `sort', `cat' and `cksum' are specified
#   by POSIX down to their output, so the same input gives the same bytes on all
#   three systems, and the system's tool is a control this test does not write.
#   Where a tool's output is specified but its spelling differs between systems
#   --- `sha256sum' against `shasum -a 256' against `certutil' --- the control is
#   not portable and is not used.
#
#   Against a value written here. Everything else is compared with the answer
#   the standard requires, which is portable by construction and is what a
#   system's own tool would be compared against in any case.
#
# The assertion in both cases is that the answer is right, not that an answer
# was produced.
set -eu

bin="${1:?usage: oracle.sh <directory>}"
bin="$(cd "$bin" && pwd)"

# The same directory, spelled the way the tools themselves spell a path.
#
# The shell and the programs it starts do not always agree: on one of the three
# systems the shell says /d/a and a program's C library says D:/a, and the two
# are the same directory. Where a path is only used to start a program, the
# shell's spelling is right, because the shell is doing the starting. Where a
# path is handed to a program as an argument --- which is the whole point of the
# `env' case below --- it has to be in the program's spelling.
if command -v cygpath > /dev/null 2>&1; then
    native="$(cygpath -m "$bin")"
else
    # ORACLE_NATIVE_PREFIX is for running programs built for another system
    # under an implementation of that system's interfaces, where the shell is
    # this system's and the programs are not.
    native="${ORACLE_NATIVE_PREFIX:-}$bin"
fi
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
cd "$work"

held=0
failed=0

hold() {   # hold <what> <expected> <actual>
    if [ "$2" = "$3" ]; then
        held=$((held + 1))
        printf '  held    %s\n' "$1"
    else
        failed=$((failed + 1))
        printf '  FAILED  %s\n    expected: %s\n    produced: %s\n' "$1" "$2" "$3"
    fi
}


printf 'alpha beta gamma\ndelta epsilon\nzeta\n' > three.txt
printf 'c\na\nb\na\n'                            > letters.txt
printf 'one:1\ntwo:2\nthree:3\n'                 > fields.txt

echo "--- against the system's own tool ---"

# The counts, not the column widths: the two agree on what to count and differ
# on how much space to put in front of it, and the standard leaves that open.
squeeze() { tr -s ' ' | sed 's/^ //; s/ $//'; }
hold 'wc'    "$(wc < three.txt | squeeze)"          "$("$bin/wc" < three.txt | squeeze)"
hold 'wc -l' "$(wc -l < three.txt | tr -d ' ')"     "$("$bin/wc" -l < three.txt | tr -d ' ')"
hold 'wc -c' "$(wc -c < three.txt | tr -d ' ')"     "$("$bin/wc" -c < three.txt | tr -d ' ')"
hold 'cat'   "$(cat three.txt letters.txt)"         "$("$bin/cat" three.txt letters.txt)"
hold 'sort'  "$(sort letters.txt)"                  "$("$bin/sort" letters.txt)"
hold 'sort -u' "$(sort -u letters.txt)"             "$("$bin/sort" -u letters.txt)"
hold 'cksum' "$(cksum < three.txt | squeeze)"       "$("$bin/cksum" < three.txt | squeeze)"

echo "--- against the answer the standard requires ---"

hold 'basename' 'file.c'          "$("$bin/basename" /usr/src/file.c)"
hold 'basename suffix' 'file'     "$("$bin/basename" /usr/src/file.c .c)"
hold 'dirname'  '/usr/src'        "$("$bin/dirname" /usr/src/file.c)"
hold 'echo'     'a b c'           "$("$bin/echo" a b c)"
hold 'printf'   'x=7 y=abc'       "$("$bin/printf" 'x=%d y=%s' 7 abc)"
hold 'seq'      '1 2 3 4 5'       "$("$bin/seq" 1 5 | tr '\n' ' ' | sed 's/ $//')"
hold 'seq step' '0 5 10'          "$("$bin/seq" 0 5 10 | tr '\n' ' ' | sed 's/ $//')"
hold 'head -n2' 'alpha beta gamma
delta epsilon'                    "$("$bin/head" -n 2 three.txt)"
hold 'tail -n1' 'zeta'            "$("$bin/tail" -n 1 three.txt)"
hold 'uniq'     'c a b a'         "$("$bin/uniq" letters.txt | tr '\n' ' ' | sed 's/ $//')"
hold 'tr'       'ALPHA'           "$(printf 'alpha' | "$bin/tr" 'a-z' 'A-Z')"
hold 'cut -d -f' 'one two three'  "$("$bin/cut" -d: -f1 fields.txt | tr '\n' ' ' | sed 's/ $//')"
hold 'cut -f2'  '1 2 3'           "$("$bin/cut" -d: -f2 fields.txt | tr '\n' ' ' | sed 's/ $//')"
hold 'rev'      'ahpla'           "$(printf 'alpha\n' | "$bin/rev")"
hold 'nl'       '1'               "$("$bin/nl" three.txt | head -n 1 | tr -s ' \t' ' ' | sed 's/^ //' | cut -d' ' -f1)"
hold 'fold -w5' 'alpha
 beta'                            "$(printf 'alpha beta\n' | "$bin/fold" -w 5)"
hold 'paste'    'a	b'            "$(printf 'a\n' > l; printf 'b\n' > r; "$bin/paste" l r)"
hold 'comm -12' 'a'               "$(printf 'a\nb\n' > x; printf 'a\nc\n' > y; "$bin/comm" -12 x y)"
hold 'tsort'    'a b c'           "$(printf 'a b\nb c\n' | "$bin/tsort" | tr '\n' ' ' | sed 's/ $//')"
hold 'expr'     '12'              "$("$bin/expr" 3 '*' 4)"
hold 'grep -c'  '1'               "$("$bin/grep" -c delta three.txt)"
hold 'grep -E'  'delta epsilon'   "$("$bin/grep" -E '^d.*n$' three.txt)"
hold 'sed'      'ALPHA beta gamma' "$("$bin/sed" 's/alpha/ALPHA/' three.txt | head -n 1)"
hold 'strings'  'alpha'           "$(printf 'alpha\000' > b.bin; "$bin/strings" b.bin)"
hold 'md5sum'   'd41d8cd98f00b204e9800998ecf8427e' \
                                  "$(: > empty; "$bin/md5sum" < empty | cut -d' ' -f1)"
hold 'sha1sum'  'da39a3ee5e6b4b0d3255bfef95601890afd80709' \
                                  "$("$bin/sha1sum" < empty | cut -d' ' -f1)"
hold 'sha256sum' 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855' \
                                  "$("$bin/sha256sum" < empty | cut -d' ' -f1)"
hold 'sha512sum' 'cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e' \
                                  "$("$bin/sha512sum" < empty | cut -d' ' -f1)"
hold 'true'     '0'               "$("$bin/true"; echo $?)"
hold 'false'    '1'               "$("$bin/false" || echo $?)"
hold 'test'     '0'               "$("$bin/test" 1 -lt 2; echo $?)"
hold 'printenv' 'the value'       "$(ORACLE_VARIABLE='the value' "$bin/printenv" ORACLE_VARIABLE)"
hold 'env'      'the value'       "$("$bin/env" ORACLE_VARIABLE='the value' "$native/printenv" ORACLE_VARIABLE)"

echo "--- the file system ---"

hold 'mkdir + ls' 'made'          "$("$bin/mkdir" -p made/deeper && "$bin/ls" | grep '^made$')"
hold 'ls -1'      'deeper'        "$("$bin/ls" -1 made)"
hold 'cp'         'alpha beta gamma' "$("$bin/cp" three.txt copy.txt && "$bin/head" -n 1 copy.txt)"
hold 'mv'         'moved.txt'     "$("$bin/mv" copy.txt moved.txt && "$bin/ls" | grep '^moved.txt$')"
hold 'rm'         ''              "$("$bin/rm" moved.txt && "$bin/ls" | grep '^moved.txt$' || true)"
hold 'rmdir'      ''              "$("$bin/rmdir" made/deeper && "$bin/ls" -1 made)"
hold 'touch'      '0'             "$("$bin/touch" fresh.txt && "$bin/wc" -c < fresh.txt | tr -d ' ')"
hold 'tee'        'through'       "$(printf 'through\n' | "$bin/tee" teed.txt > /dev/null; "$bin/cat" teed.txt)"
hold 'split + cat' 'alpha beta gamma
delta epsilon
zeta'                             "$("$bin/split" -l 1 three.txt part. && "$bin/cat" part.*)"
# The last component, not the whole name. The three systems agree on where the
# working directory is and not on how it is spelled: one of them names a volume
# in front of it, and the shell running this script may name the same directory
# a third way again. What the tool is being asked is whether it reports the
# directory it is in.
hold 'pwd'        "$(basename "$(pwd)")" "$(basename "$("$bin/pwd")")"

printf '\n%d held, %d did not hold\n' "$held" "$failed"
[ "$failed" -eq 0 ]
