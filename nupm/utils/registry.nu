# Utilities related to nupm registries

# Search for a package in a registry
export def search-package [
    package: string  # Name of the package
    --registry: string  # Which registry to use
    --version: any  # Package version to install (string or null)
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
        # Otherwise use $env.NUPM_REGISTRIES
        $env.NUPM_REGISTRIES
    }

    let name_matcher: closure = if $exact_match {
        {|row| $package == $row.name }
    } else {
        {|row| $package in $row.name }
    }

    # Collect all registries matching the package and all matching packages
    let regs = $registries
        | items {|name, path|
            # Open registry (online or offline)
            let registry = if ($path | path type) == file {
                open $path
            } else {
                try {
                    let reg = http get $path

                    if local in $reg {
                        throw-error ("Can't have local packages in online registry"
                            + $" '($path)'.")
                    }

                    $reg
                } catch {
                    throw-error $"Cannot open '($path)' as a file or URL."
                }
            }

            $registry | check-cols --missing-ok "registry" [ git local ] | ignore

            # Find all packages matching $package in the registry
            let pkgs_local = $registry.local?
                | default []
                | check-cols "local packages" [ name version path ]
                | filter $name_matcher

            let pkgs_git = $registry.git?
                | default []
                | check-cols "git packages" [ name version url revision path ]
                | filter $name_matcher

            let pkgs = $pkgs_local
                | insert type local
                | insert url null
                | insert revision null
                | append ($pkgs_git | insert type git)

            {
                name: $name
                path: $path
                pkgs: $pkgs
            }
        }
        | compact

    $regs | where not ($it.pkgs | is-empty)
}
