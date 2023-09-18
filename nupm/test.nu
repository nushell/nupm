use utils/dirs.nu tmp-dir

# Experimental test runner
export def main [] {
    let tests = ls tests/test*nu
    | get name
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
        print ($'Test ($fail.name) in file ($fail.file) failed with exit code'
            + $' ($fail.exit_code):(char nl)'
            + $fail.stderr)
    }

    print ($'Ran ($out | length) tests.'
        + $' ($successes | length) succeeded,'
        + $' ($failures | length) failed.')
}
