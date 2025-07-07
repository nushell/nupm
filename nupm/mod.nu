use std/log

use utils/dirs.nu [
    DEFAULT_NUPM_HOME DEFAULT_NUPM_TEMP DEFAULT_NUPM_CACHE
    DEFAULT_NUPM_REGISTRIES DEFAULT_NUPM_INDEX_PATH nupm-home-prompt
]

use utils/registry.nu open-index

export module install.nu
export module publish.nu
export module registry.nu
export module search.nu
export module status.nu
export module test.nu


export-env {
    # Ensure that $env.NUPM_HOME is always set when running nupm. Any missing
    # $env.NUPM_HOME during nupm execution is a bug.
    $env.NUPM_HOME = ($env.NUPM_HOME? | default $DEFAULT_NUPM_HOME)

    # Ensure temporary path is set.
    $env.NUPM_TEMP = ($env.NUPM_TEMP? | default $DEFAULT_NUPM_TEMP)

    # Ensure install cache is set
    $env.NUPM_CACHE = ($env.NUPM_CACHE? | default $DEFAULT_NUPM_CACHE)

    # check for the index path
    $env.NUPM_INDEX_PATH = ($env.NUPM_INDEX_PATH? | default $DEFAULT_NUPM_INDEX_PATH)

    # read from registry index but don't overwrite registires already present in $env.NUPM_REGISTRIES
    $env.NUPM_REGISTRIES = ($env.NUPM_INDEX_PATH | open-index
        | merge ($env.NUPM_REGISTRIES? | default $DEFAULT_NUPM_REGISTRIES))

    use std/log []
}

# Nushell Package Manager
#
# nupm is a package manager for Nushell that allows you to install, manage, and publish
# Nushell packages including modules, scripts, and custom packages.
#
# Configuration:
#   Set `NUPM_HOME` environment variable to change installation directory
#   Set `NUPM_REGISTRIES` to configure package registries
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
