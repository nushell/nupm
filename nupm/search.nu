use utils/completions.nu complete-registries
use utils/registry.nu search-package

# Search for a package
export def main [
    package  # Name, path, or link to the package
    --registry: string@complete-registries  # Which registry to use (either a name
                                            # in $env.NUPM_REGISTRIES or a path)
    --pkg-version(-v): string  # Package version to install
]: nothing -> table {
    search-package $package --registry $registry --version $pkg_version
}
