use std/log

use utils/dirs.nu [ nupm-home-prompt ]

export module install.nu
export module publish.nu
export module registry.nu
export module search.nu
export module status.nu
export module test.nu

# Base values for nupm that are used as defaults if not present in `$env.nupm`
export const BASE_NUPM_CONFIG = {
  default-home: ($nu.default-config-dir | path join "nupm")
  default-cache: ($nu.default-config-dir | path join nupm cache)
  # default-temp: ($nu.temp-path | path join "nupm")
  default-registry: {
    nupm: 'https://raw.githubusercontent.com/nushell/nupm/main/registry/registry.nuon'
  }
}

export-env {
    # Ensure that $env.nupm is always set when running nupm. Any missing variaables are set by `$BASE_NUPM_CONFIG`
    $env.nupm = {
      home: ($env.nupm?.home? | default $BASE_NUPM_CONFIG.default-home)
      cache: ($env.nupm?.cache? | default $BASE_NUPM_CONFIG.default-cache)
      temp: ($env.nupm?.temp? | default ($nu.temp-path | path join "nupm"))
      registries: ($env.nupm?.registries? |  default $BASE_NUPM_CONFIG.default-registry)
    } | merge $BASE_NUPM_CONFIG
    # Should this filename be hardcoded for simplicity?
    $env.nupm.index-path = ($env.nupm.home | path join "registry_index.nuon")
    if ($env.nupm.index-path | path exists) {
      if not (($env.nupm.index-path | path type) == "file") {
          throw-error $"($env.nupm.index-path) is not a filepath"
      }
      # overwrite filevalues with those found in config
      $env.nupm.registries = open $env.nupm.index-path | merge $env.nupm.registries
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
    echo $env.nupm
}
