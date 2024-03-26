use utils/completions.nu complete-registries
use utils/registry.nu search-package
use utils/version.nu filter-by-version

# Search for a package
export def main [
    package  # Name, path, or link to the package
    --registry: string@complete-registries  # Which registry to use (either a name
                                            # in $env.NUPM_REGISTRIES or a path)
    --pkg-version(-v): string  # Package version to install
    --exact-match(-e)  # Match package name exactly
]: nothing -> table {
    search-package $package --registry $registry --exact-match=$exact_match
    | flatten
    | each {|row|
        {
            registry_name: $row.registry_name
            registry_path: $row.registry_path
            name: $row.pkgs.name
            version: $row.pkgs.version
            path: $row.pkgs.path
            type: $row.pkgs.type
            info: $row.pkgs.info
        }
    }
    | filter-by-version $pkg_version
}
