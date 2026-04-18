#!/usr/bin/env bats

setup() {
    load "${BATS_LIB_PATH}/bats-support/load.bash"
    load "${BATS_LIB_PATH}/bats-assert/load.bash"

    TMP="$BATS_TEST_TMPDIR"
}

@test "no args exits 0" {
    run lefthook-shellcheck
    assert_success
}

@test "non-existent file is skipped" {
    run lefthook-shellcheck /nonexistent/file.sh
    assert_success
}

@test "non-shell files are skipped" {
    echo 'hello' > "$TMP/readme.md"
    run lefthook-shellcheck "$TMP/readme.md"
    assert_success
}

@test "clean shell script passes" {
    cat > "$TMP/good.sh" <<'SH'
#!/usr/bin/env bash
echo "hello"
SH
    run lefthook-shellcheck "$TMP/good.sh"
    assert_success
}

@test "script with issues fails" {
    cat > "$TMP/bad.sh" <<'SH'
#!/usr/bin/env bash
echo $UNQUOTED_VAR
SH
    run lefthook-shellcheck "$TMP/bad.sh"
    assert_failure
}

@test ".bats files are accepted" {
    cat > "$TMP/test.bats" <<'BATS'
#!/usr/bin/env bats
@test "example" {
    true
}
BATS
    run lefthook-shellcheck "$TMP/test.bats"
    assert_success
}

@test "multiple files: bad one causes failure" {
    cat > "$TMP/good.sh" <<'SH'
#!/usr/bin/env bash
echo "hello"
SH
    cat > "$TMP/bad.sh" <<'SH'
#!/usr/bin/env bash
echo $UNQUOTED_VAR
SH
    run lefthook-shellcheck "$TMP/good.sh" "$TMP/bad.sh"
    assert_failure
}

@test "dev.sh contains conditional lefthook install" {
    run grep -q '\[ -f .git/hooks/pre-commit \] || lefthook install' dev.sh
    assert_success
}

@test "mixed shell and non-shell files: only shell checked" {
    cat > "$TMP/good.sh" <<'SH'
#!/usr/bin/env bash
echo "hello"
SH
    echo 'not shell' > "$TMP/data.txt"
    run lefthook-shellcheck "$TMP/good.sh" "$TMP/data.txt"
    assert_success
}
