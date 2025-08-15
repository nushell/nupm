# Utilities related to nupm registries

use dirs.nu [ cache-dir REGISTRY_FILENAME ]
use log.nu throw-error
use misc.nu [check-cols url hash-file hash-fn]

# Columns of a registry file
export const REG_COLS = [ name path hash ]

# Columns of a registry package file
export const REG_PKG_COLS = [ name version path type info ]


# return the respective registry cache directory and package index
export def registry-cache [name: string]: nothing -> record<dir: path, file: path> {
    let dir = cache-dir --ensure | path join "registry" $name
    { dir: $dir, file: ($dir | path join $REGISTRY_FILENAME) }
}

# Search for a package in a registry
export def search-package [
    package: string  # Name of the package
    --registry: string  # Which registry to use (name or path)
    --exact-match  # Searched package name must match exactly
]: nothing -> table {
    let registries = if (not ($registry | is-empty)) and ($registry in $env.NUPM_REGISTRIES) {
        # If $registry is a valid column in $env.NUPM_REGISTRIES, use that
        { $registry : ($env.NUPM_REGISTRIES | get $registry) }
    } else if (not ($registry | is-empty)) and ($registry | path exists) {
        # If $registry is a path, use that
        let reg_name = $registry | path parse | get stem
        { $reg_name: $registry }
    } else {
        # Otherwise use $env.NUPM_REGISTRIES as-is
        $env.NUPM_REGISTRIES
    }

    let name_matcher: closure = if $exact_match {
        {|row| $package == $row.name }
    } else {
        {|row| $package in $row.name }
    }

    # Collect all registries matching the package and all matching packages
    let regs = $registries
        | items {|name, url_or_path|
            # Open registry (online or offline)
            let registry = if ($url_or_path | path type) == file {
                {
                    reg: (open $url_or_path)
                    path: $url_or_path
                    is_url: false
                }

            } else {
                try {
                    let cache = registry-cache $name

                    let reg = if ($cache.file | path exists) {
                        open $cache.file
                    } else {
                        let data = http get $url_or_path
                        mkdir $cache.dir
                        $data | save --force $cache.file
                        $data
                    }

                    {
                        reg: $reg
                        path: $cache.file
                        is_url: true
                        cache_dir: $cache.dir
                    }
                } catch {
                    throw-error $"Cannot open '($url_or_path)' as a file or URL."
                }
            }

            $registry.reg | check-cols "registry" $REG_COLS | ignore

            # Find all packages matching $package in the registry
            let pkg_files = $registry.reg | where $name_matcher

            let pkgs = $pkg_files | each {|row|
                let pkg_file_path = if $registry.is_url {
                    $registry.cache_dir | path join $"($row.name).nuon"
                } else {
                    $registry.path | path dirname | path join $row.path
                }

                let hash = if ($pkg_file_path | path type) == file {
                    $pkg_file_path | hash-file
                }

                if $registry.is_url and (not ($pkg_file_path | path exists) or $hash != $row.hash) {
                    let url = $url_or_path | url update-name $row.path
                    http get $url | save --force $pkg_file_path
                }

                let new_hash = open $pkg_file_path | to nuon | hash-fn

                open $pkg_file_path | insert hash_mismatch ($new_hash != $row.hash)
            }
            | compact
            | flatten

            {
                registry_name: $name
                registry_path: $registry.path
                pkgs: $pkgs,
            }
        }
        | compact

    $regs | where not ($it.pkgs | is-empty)
}


export def open-index []: path -> record {
    let index_file = $in
    if ($index_file | path exists) {
      if not (($index_file | path type) == "file") {
          throw-error $"($index_file) is not a filepath"
      }
      return (open $index_file)
    }

    {}
}
