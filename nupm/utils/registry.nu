# Utilities related to nupm registries

use dirs.nu cache-dir
use misc.nu [check-cols url]

# Search for a package in a registry
export def search-package [
    package: string  # Name of the package
    --registry: string  # Which registry to use (name or path)
    --exact-match  # Searched package name must match exactly
] -> table {
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
                    let reg = http get $url_or_path

                    let reg_file = cache-dir --ensure
                        | path join registry $'($name).nuon'

                    mkdir ($reg_file | path dirname)
                    $reg | save --force $reg_file

                    {
                        reg: $reg
                        path: $reg_file
                        is_url: true
                    }
                } catch {
                    throw-error $"Cannot open '($url_or_path)' as a file or URL."
                }
            }

            $registry.reg | check-cols "registry" [ name path ] | ignore

            # Find all packages matching $package in the registry
            let pkg_files = $registry.reg | filter $name_matcher

            let pkgs = $pkg_files | each {|row|
                let pkg_file_path = $registry.path
                    | path dirname
                    | path join $row.path

                if $registry.is_url {
                    let url = $url_or_path | url update-name $row.path
                    # TODO: Add file hashing
                    http get $url | save --force $pkg_file_path
                }

                open $pkg_file_path
            }
            | flatten

            {
                registry_name: $name
                registry_path: $registry.path
                pkgs: $pkgs
            }
        }
        | compact

    $regs | where not ($it.pkgs | is-empty)
}
