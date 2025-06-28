use std/log

use utils/dirs.nu [ nupm-home-prompt BASE_NUPM_CONFIG ]
use utils/registry.nu open-index

export module install.nu
export module publish.nu
export module registry.nu
export module search.nu
export module status.nu
export module test.nu


export-env {
    # Ensure that $env.nupm is always set when running nupm. Any missing variaables are set by `$BASE_NUPM_CONFIG`
    $env.nupm = $BASE_NUPM_CONFIG | merge deep ($env.nupm? | default {})
    # set missing values to default while
    # retaining defaults in $env.nupm.default
    $env.nupm.default = $BASE_NUPM_CONFIG
    # read from registry index but don't overwrite registires already present in $env.nupm.registries
    $env.nupm.registries = $env.nupm.index-path | open-index | merge $env.nupm.registries
    $env.ENV_CONVERSIONS.nupm = {
        from_string: { |s| $s | from nuon }
        to_string: { |v| $v | to nuon }
    }
    if $env.nupm.config.nu_search_path {
        let nupm_lib_dirs = [modules, scripts] | each {|s| $env.nupm.home | path join $s }
        $env.NU_LIB_DIRS = $env.NU_LIB_DIRS | prepend $nupm_lib_dirs | uniq

        let nupm_plugin_dir = $env.nupm.home| path join "plugins"
        $env.NU_PLUGIN_DIRS = $env.NU_PLUGIN_DIRS | prepend $nupm_plugin_dir | uniq
    }
    use std/log []
}

# Nushell Package Manager
#
# nupm is a package manager for Nushell that allows you to install, manage, and publish
# Nushell packages including modules, scripts, and custom packages.
#
# Configuration:
#   Set `nupm.home` environment variable to change installation directory
#   Set `nupm.registries` to configure package registries
@example "Install a package from a local directory" { nupm install my-package --path }
@example "Publish a package" { nupm publish my-registry.nuon --local --save }
@example "Search for specific version" { nupm search my-package --pkg-version 1.2.0 }
@example "Check status of specific package directory" { nupm status ./my-package }
@example "Run tests" { nupm test }
export def main [subcommand?]: nothing -> nothing {
    nupm-home-prompt --no-confirm=false

    let subcommands = help modules | where name == nupm | get submodules.0.name
    print $"(ansi green)Usage(ansi reset): nupm \(($subcommands | str join '|'))"

    print 'enjoy nupm!'
}
