use utils/dirs.nu [ tmp-dir find-root ]
use utils/log.nu throw-error

# Run tests for a nupm package
#
# Discovers and runs all exported test functions from the tests/ directory.
# Tests are Nushell functions that should throw errors on failure.
# The test runner provides isolated environments and reports results.
@example "Run all tests in current package" {
  nupm test
}
@example "Run tests matching a filter" {
  nupm test install
}
@example "Run tests from specific directory" {
  nupm test --dir ./my-package
}
@example "Show test output for debugging" {
  nupm test --show-stdout
}
export def main [
    filter?: string  = ''  # Run only tests containing this substring
    --dir: path  # Directory where to run tests (default: $env.PWD)
    --show-stdout  # Show standard output of each test
]: nothing -> nothing {
    let dir = ($dir | default $env.PWD | path expand -s)
    let pkg_root = find-root $dir

    if $pkg_root == null {
        throw-error "package_file_not_found" (
            $'Could not find "nupm.nuon" in ($dir) or any parent directory.'
        )
    }

    if ($pkg_root | path join "tests" | path type) != "dir" {
        throw-error "test_directory_not_found" (
            $"tests/ directory module not found for in ($pkg_root)"
        )
    }

    if ($pkg_root | path join "tests" "mod.nu" | path type) != "file" {
        throw-error "invalid_test_directory" (
            $"tests/ directory module in ($pkg_root) is missing a `mod.nu`"
        )
    }

    print $'Testing package ($pkg_root)'
    cd $pkg_root

    let tests = ^$nu.current-exe ...[
        --no-config-file
        --commands
        'use tests/

        scope commands
        | where ($it.name | str starts-with tests)
        | get name
        | to nuon'
    ]
    | from nuon

    let out = $tests
        | where ($filter in $it)
        | par-each {|test|
            let res = do {
                ^$nu.current-exe ...[
                    --no-config-file
                    --commands
                    $'use tests/; ($test)'
                ]
            }
            | complete

            if $res.exit_code == 0 {
                print $'($test) ... (ansi gb)SUCCESS(ansi reset)'
            } else {
                print $'($test) ... (ansi rb)FAILURE(ansi reset)'
            }

            if $show_stdout {
                print 'stdout:'
                print $res.stdout
            }

            {
                name: $test
                stdout: $res.stdout
                stderr: $res.stderr
                exit_code: $res.exit_code
            }
        }

    let successes = $out | where exit_code == 0
    let failures = $out | where exit_code != 0

    $failures | each {|fail|
        print ($'(char nl)Test "($fail.name)" failed with exit code'
            + $' ($fail.exit_code):(char nl)'
            + ($fail.stderr | str trim))
    }

    if ($failures | length) != 0 {
        print ''
    }

    print ($'Ran ($out | length) tests.'
        + $' ($successes | length) succeeded,'
        + $' ($failures | length) failed.')

    if ($failures | length) != 0 {
        error make --unspanned {msg: "some tests failed"}
    }
}
