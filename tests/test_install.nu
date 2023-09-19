use std assert

use ../nupm/utils/dirs.nu tmp-dir
use ../nupm


def-env set-nupm-home []: nothing -> path {
    let dir = tmp-dir test --ensure
    $env.NUPM_HOME = $dir
    $dir
}

export def install-script [] {
    let tmp_nupm_home = set-nupm-home
    cd tests/packages/spam_script

    nupm install --path .
    assert ([$env.NUPM_HOME scripts spam_script.nu] | path join | path exists)
    rm -r $tmp_nupm_home
}

export def install-module [] {
    let tmp_nupm_home = set-nupm-home
    cd tests/packages/spam_module

    nupm install --path .
    assert ([$env.NUPM_HOME scripts script.nu] | path join | path exists)
    assert ([$env.NUPM_HOME modules spam_module] | path join | path exists)
    assert ([$env.NUPM_HOME modules spam_module mod.nu]
        | path join
        | path exists)
    rm -r $tmp_nupm_home
}

export def install-custom [] {
    let tmp_nupm_home = set-nupm-home
    cd tests/packages/spam_custom

    nupm install --path .
    assert ([$env.NUPM_HOME plugins nu_plugin_test] | path join | path exists)
    rm -r $tmp_nupm_home
}
