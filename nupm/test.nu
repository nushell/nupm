use utils/dirs.nu [ tmp-dir find-root ]
use utils/log.nu throw-error

# Experimental test runner
export def main [
    filter?: string  = ''  # Run only tests containing this substring
    --dir: path  # Directory where to run tests (default: $env.PWD)
    --show-stdout  # Show standard output of each test
]: nothing -> nothing {
    let dir = ($dir | default $env.PWD | path expand -s)
    let pkg_root = find-root $dir

    if $pkg_root == null {
        throw-error ($'Could not find "package.nuon" in ($dir)'
            + ' or any parent directory.')
    }

    print $'Testing package ($pkg_root)'
    cd $pkg_root

    let tests = glob ($pkg_root | path join tests/test-*.nu)
        | each {|test_file|
            let tests_nuon = nu [
                --no-config-file
                --commands
                $'use ($test_file)

                scope modules
                | where name == ($test_file | path parse | get stem)
                | get -i 0.commands.name
                | to nuon'
            ]

            {
                file: $test_file
                name: ($tests_nuon | from nuon)
            }
        }
        | flatten

    let out = $tests
        | where ($filter in $it.name)
        | par-each {|test|
            let res = do {
                nu [
                    --no-config-file
                    --commands
                    $'use ($test.file) ($test.name); ($test.name)'
                ]
            }
            | complete

            if $res.exit_code == 0 {
                print $'($test.file): ($test.name) ... (ansi gb)SUCCESS(ansi reset)'
            } else {
                print $'($test.file): ($test.name) ... (ansi rb)FAILURE(ansi reset)'
            }

            if $show_stdout {
                print 'stdout:'
                print $res.stdout
            }

            {
                file: $test.file
                name: $test.name
                stdout: $res.stdout
                stderr: $res.stderr
                exit_code: $res.exit_code
            }
        }

    let successes = $out | where exit_code == 0
    let failures = $out | where exit_code != 0

    $failures | each {|fail|
        print ((char nl)
            + $'Test "($fail.name)" in file ($fail.file) failed with exit code'
            + $' ($fail.exit_code):(char nl)'
            + ($fail.stderr | str trim))
    }

    if ($failures | length) != 0 {
        print ''
    }

    print ($'Ran ($out | length) tests.'
        + $' ($successes | length) succeeded,'
        + $' ($failures | length) failed.')
}
