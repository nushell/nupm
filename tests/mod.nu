use std assert

use ../nupm/utils/dirs.nu tmp-dir
use ../nupm

const TEST_REGISTRY_PATH = ([tests packages registry registry.nuon] | path join)


def with-test-env [closure: closure]: nothing -> nothing {
    let home = tmp-dir nupm_test --ensure
    let cache = tmp-dir 'nupm_test/cache' --ensure
    let temp = tmp-dir 'nupm_test/temp' --ensure
    let reg = { test: $TEST_REGISTRY_PATH }

    with-env {
        NUPM_HOME: $home
        NUPM_CACHE: $cache
        NUPM_TEMP: $temp
        NUPM_REGISTRIES: $reg
    } $closure

    rm --recursive $temp
    rm --recursive $cache
    rm --recursive $home
}

# Examples:
#     make sure `$env.NUPM_HOME/scripts/script.nu` exists
#     > assert installed [scripts script.nu]
def "assert installed" [path_tokens: list<string>] {
    assert ($path_tokens | prepend $env.NUPM_HOME | path join | path exists)
}

def check-file-content [content: string] {
    let file_str = open ($env.NUPM_HOME | path join scripts spam_script.nu)
    assert ($file_str | str contains $content)
}


export def install-script [] {
    with-test-env {
        nupm install --path tests/packages/spam_script

        assert installed [scripts spam_script.nu]
        assert installed [scripts spam_bar.nu]
    }
}

export def install-module [] {
    with-test-env {
        nupm install --path tests/packages/spam_module

        assert installed [scripts script.nu]
        assert installed [modules spam_module]
        assert installed [modules spam_module mod.nu]
    }
}

export def install-custom [] {
    with-test-env {
        nupm install --path tests/packages/spam_custom

        assert installed [plugins nu_plugin_test]
    }
}

export def install-from-local-registry [] {
    with-test-env {
        $env.NUPM_REGISTRIES = {}
        nupm install --registry $TEST_REGISTRY_PATH spam_script
        check-file-content 0.2.0
    }

    with-test-env {
        nupm install --registry test spam_script
        check-file-content 0.2.0
    }

    with-test-env {
        nupm install spam_script
        check-file-content 0.2.0
    }
}

export def install-with-version [] {
    with-test-env {
        nupm install spam_script -v 0.1.0
        check-file-content 0.1.0
    }
}

export def install-multiple-registries-fail [] {
    with-test-env {
        $env.NUPM_REGISTRIES.test2 = $TEST_REGISTRY_PATH

        let out = try {
            nupm install spam_script
            "wrong value that shouldn't match the assert below"
        } catch {|err|
            $err.msg
        }

        assert ("Multiple registries contain package spam_script" in $out)
    }
}

export def install-package-not-found [] {
    with-test-env {
        let out = try {
            nupm install invalid-package
            "wrong value that shouldn't match the assert below"
        } catch {|err|
            $err.msg
        }

        assert ("Package invalid-package not found in any registry" in $out)
    }
}

export def search-registry [] {
    with-test-env {
        assert ((nupm search spam | length) == 4)
    }
}

export def nupm-status-module [] {
    with-test-env {
        let files = (nupm status tests/packages/spam_module).files
        assert ($files.0 ends-with (
            [tests packages spam_module spam_module mod.nu] | path join))
        assert ($files.1.0 ends-with (
            [tests packages spam_module script.nu] | path join))
    }
}

export def env-vars-are-set [] {
    $env.NUPM_HOME = null
    $env.NUPM_TEMP = null
    $env.NUPM_CACHE = null
    $env.NUPM_REGISTRIES = null

    use ../nupm/utils/dirs.nu
    use ../nupm

    assert equal $env.NUPM_HOME $dirs.DEFAULT_NUPM_HOME
    assert equal $env.NUPM_TEMP $dirs.DEFAULT_NUPM_TEMP
    assert equal $env.NUPM_CACHE $dirs.DEFAULT_NUPM_CACHE
    assert equal $env.NUPM_REGISTRIES $dirs.DEFAULT_NUPM_REGISTRIES
}

export def generate-local-registry [] {
    with-test-env {
        mkdir ($env.NUPM_TEMP | path join packages registry)

        let reg_file = [tests packages registry registry.nuon] | path join
        let tmp_reg_file = [
            $env.NUPM_TEMP packages registry test_registry.nuon
        ]
        | path join

        touch $tmp_reg_file

        [spam_script spam_script_old spam_custom spam_module] | each {|pkg|
            cd ([tests packages $pkg] | path join)
            nupm publish $tmp_reg_file --local --save --path (".." | path join $pkg)
        }

        let actual = open $tmp_reg_file | to nuon
        let expected = open $reg_file | to nuon

        assert equal $actual $expected
    }
}
