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
  default-temp: ($nu.temp-path | path join "nupm")
  default-registry: {
    nupm: 'https://raw.githubusercontent.com/nushell/nupm/main/registry/registry.nuon'
  }
}

export-env {
    # Ensure that $env.nupm is always set when running nupm. Any missing variaables
    $env.nupm = {
      home: ($env.nupm.home? | default $BASE_NUPM_CONFIG.default-home)
      cache: ($env.nupm.cache? | default $BASE_NUPM_CONFIG.default-cache)
      temp: ($env.nupm.temp? | default $BASE_NUPM_CONFIG.default-temp)
      registries: ($env.nupm.registires? |  default $BASE_NUPM_CONFIG.default-registry)
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
export def main []: nothing -> nothing {
    nupm-home-prompt --no-confirm=false

    print 'enjoy nupm!'
}
