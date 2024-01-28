use std assert

use ../nupm/utils/dirs.nu tmp-dir
use ../nupm

const TEST_REGISTRY_PATH = ([tests packages registry.nuon] | path join)


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
    def check-file [] {
        let contents = open ($env.NUPM_HOME | path join scripts spam_script.nu)
        assert ($contents | str contains '0.2.0')
    }

    with-test-env {
        $env.NUPM_REGISTRIES = {}
        nupm install --registry $TEST_REGISTRY_PATH spam_script
        check-file
    }

    with-test-env {
        nupm install --registry test spam_script
        check-file
    }

    with-test-env {
        nupm install spam_script
        check-file
    }
}

export def search-registry [] {
    with-test-env {
        assert ((nupm search spam | get pkgs.0 | length) == 4)
    }
}
