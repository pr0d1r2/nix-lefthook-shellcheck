# shellcheck shell=bash
# Lefthook-compatible shellcheck wrapper.
# Usage: lefthook-shellcheck file1.sh [file2.bats ...]
# Non-.sh/.bats files are skipped silently.
# NOTE: sourced by writeShellApplication — no shebang or set needed.

if [ $# -eq 0 ]; then
    exit 0
fi

files=()
for f in "$@"; do
    [ -f "$f" ] || continue
    case "$f" in
        *.sh | *.bats) files+=("$f") ;;
    esac
done

if [ ${#files[@]} -eq 0 ]; then
    exit 0
fi

exec shellcheck "${files[@]}"
