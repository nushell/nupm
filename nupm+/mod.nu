use std/log

use utils/dirs.nu [
  DEFAULT_NUPM_HOME
  DEFAULT_NUPM_TEMP
  DEFAULT_NUPM_CACHE
  DEFAULT_NUPM_REGISTRIES
  DEFAULT_NUPM_INDEX_PATH
  nupm-home-prompt
]

use utils/registry.nu open-index

export use install.nu
export use publish.nu
export use registry.nu
export use search.nu
export use status.nu
export use test.nu

export-env {
  # Ensure that $env.NUPM_HOME is always set when running nupm. Any missing
  # $env.NUPM_HOME during nupm execution is a bug.
  # load-env applies its record only after every field has evaluated, so the
  # registries field cannot read the index path through $env — resolve it once.
  let index_path: path = $env.NUPM_INDEX_PATH? | default $DEFAULT_NUPM_INDEX_PATH
  load-env {
    NUPM_HOME: ($env.NUPM_HOME? | default $DEFAULT_NUPM_HOME)
    NUPM_TEMP: ($env.NUPM_TEMP? | default $DEFAULT_NUPM_TEMP)
    NUPM_CACHE: ($env.NUPM_CACHE? | default $DEFAULT_NUPM_CACHE)
    NUPM_INDEX_PATH: $index_path
    NUPM_REGISTRIES: (
      $index_path | open-index
      | merge ($env.NUPM_REGISTRIES? | default $DEFAULT_NUPM_REGISTRIES)
    )
  }

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
export def main [
  # topiary: disable
  _subcommand # nu-lint-ignore: add_type_hints_arguments
] {
  nupm-home-prompt --no-confirm=false

  let subcommands = help modules | where name == 'nupm+' | get --optional submodules.0.name
  print $"(ansi green)Usage(ansi reset): nupm+ \(($subcommands | str join '|'))"

  print 'enjoy nupm!'
}
