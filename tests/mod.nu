use std assert

use ../nupm/utils/dirs.nu tmp-dir
use ../nupm

const TEST_REGISTRY_PATH = ([tests packages registry.nuon] | path join)


def with-nupm-home [closure: closure]: nothing -> nothing {
    let dir = tmp-dir test --ensure
    with-env { NUPM_HOME: $dir } $closure
    rm --recursive $dir
}

# Examples:
#     make sure `$env.NUPM_HOME/scripts/script.nu` exists
#     > assert installed [scripts script.nu]
def "assert installed" [path_tokens: list<string>] {
    assert ($path_tokens | prepend $env.NUPM_HOME | path join | path exists)
}

export def install-script [] {
    with-nupm-home {
        nupm install --path tests/packages/spam_script

        assert installed [scripts spam_script.nu]
        assert installed [scripts spam_bar.nu]
    }
}

export def install-module [] {
    with-nupm-home {
        nupm install --path tests/packages/spam_module

        assert installed [scripts script.nu]
        assert installed [modules spam_module]
        assert installed [modules spam_module mod.nu]
    }
}

export def install-custom [] {
    with-nupm-home {
        nupm install --path tests/packages/spam_custom

        assert installed [plugins nu_plugin_test]
    }
}

export def install-from-registry-with-flag [] {
    with-nupm-home {
        nupm install --registry $TEST_REGISTRY_PATH spam_script

        let contents = open ($env.NUPM_HOME | path join scripts spam_script.nu)
        assert ($contents | str contains '0.2.0')
    }
}

export def install-from-registry-without-flag [] {
    with-nupm-home {
        $env.NUPM_REGISTRIES = { test: $TEST_REGISTRY_PATH }
        nupm install spam_script

        let contents = open ($env.NUPM_HOME | path join scripts spam_script.nu)
        assert ($contents | str contains '0.2.0')
    }
}
