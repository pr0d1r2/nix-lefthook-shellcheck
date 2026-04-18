#!/usr/bin/env bats

setup() {
    load "${BATS_LIB_PATH}/bats-support/load.bash"
    load "${BATS_LIB_PATH}/bats-assert/load.bash"
}

@test "dev.sh sets BATS_LIB_PATH" {
    run grep -q 'export BATS_LIB_PATH=' dev.sh
    assert_success
}

@test "dev.sh contains conditional lefthook install" {
    run grep -q '\[ -f .git/hooks/pre-commit \] || lefthook install' dev.sh
    assert_success
}
