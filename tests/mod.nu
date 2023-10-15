use std assert

use ../nupm/utils/dirs.nu tmp-dir
use ../nupm


def with-nupm-home [closure: closure]: nothing -> nothing {
    let dir = tmp-dir test --ensure
    with-env { NUPM_HOME: $dir } $closure
    rm -r $dir
}

export def install-script [] {
    with-nupm-home {
        cd tests/packages/spam_script

        nupm install --path .
        assert ([$env.NUPM_HOME scripts spam_script.nu]
            | path join
            | path exists)
        assert ([$env.NUPM_HOME scripts spam_bar.nu]
            | path join
            | path exists)
    }
}

export def install-module [] {
    with-nupm-home {
        cd tests/packages/spam_module

        nupm install --path .
        assert ([$env.NUPM_HOME scripts script.nu] | path join | path exists)
        assert ([$env.NUPM_HOME modules spam_module] | path join | path exists)
        assert ([$env.NUPM_HOME modules spam_module mod.nu]
            | path join
            | path exists)
    }
}

export def install-module-nodefault [] {
    with-nupm-home {
        cd tests/packages/spam_module_nodefault

        nupm install --path .
        assert ([$env.NUPM_HOME modules nodefault ] | path join | path exists)
        assert ([$env.NUPM_HOME modules nodefault mod.nu]
            | path join
            | path exists)
    }
}

export def install-custom [] {
    with-nupm-home {
        cd tests/packages/spam_custom

        nupm install --path .
        assert ([$env.NUPM_HOME plugins nu_plugin_test]
            | path join
            | path exists)
    }
}
