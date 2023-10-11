use std assert

use ../nupm/utils/dirs.nu tmp-dir
use ../nupm


def with-nupm-home [closure: closure]: nothing -> nothing {
    let dir = tmp-dir test --ensure
    with-env { NUPM_HOME: $dir } $closure
    rm -r $dir
}

# Examples:
#     make sure `$env.NUPM_HOME/scripts/script.nu` exists
#     > assert (check-install [scripts script.nu])
def check-install [path_tokens: list<string>] {
    $path_tokens | prepend $env.NUPM_HOME | path join | path exists
}

export def install-script [] {
    with-nupm-home {
        nupm install --path tests/packages/spam_script

        assert (check-install [scripts spam_script.nu])
        assert (check-install [scripts spam_bar.nu])
    }
}

export def install-module [] {
    with-nupm-home {
        nupm install --path tests/packages/spam_module

        assert (check-install [scripts script.nu])
        assert (check-install [modules spam_module])
        assert (check-install [modules spam_module mod.nu])
    }
}

export def install-module-nodefault [] {
    with-nupm-home {
        nupm install --path tests/packages/spam_module_nodefault

        assert (check-install [modules nodefault ])
        assert (check-install [modules nodefault mod.nu])
    }
}

export def install-custom [] {
    with-nupm-home {
        nupm install --path tests/packages/spam_custom

        assert (check-install [plugins nu_plugin_test])
    }
}
