# Registry management for nupm

use utils/dirs.nu [nupm-home-prompt REGISTRY_FILENAME]
use utils/log.nu [throw-error UNIMPLEMENTED]
use utils/registry.nu registry-cache

# Manage nupm registires
@example "List all configured registries" { nupm registry }
export def main []: nothing -> table {
    list
}

# List all configured registries
@example "List all registries with details" { nupm registry list }
export def list []: nothing -> table {
    $env.NUPM_REGISTRIES | transpose name url | sort-by name
}


def registry-names [] { list | get name }
# Show detailed information about a specific registry
# returning a list of package names, type, and version
@example "Show registry information" { nupm registry describe nupm }
export def describe [
    registry: string@registry-names
]: nothing -> table {
    use utils/dirs.nu cache-dir

    if not ($registry in $env.NUPM_REGISTRIES) {
        throw-error $"Registry '($registry)' not found"
    }

    let registry_url = $env.NUPM_REGISTRIES | get $registry
    let cache = registry-cache $registry
    let cached_registry = $cache.dir | path join $REGISTRY_FILENAME

    # Always check cache first, only fall back to URL if cache doesn't exist
    let registry_data = if ($cache.file | path exists) {
        open $cache.file
    } else if ($registry_url | path exists) {
        # Local registry file
        open $registry_url
    } else {
        # Remote registry - fetch and cache
        let data = http get $registry_url
        mkdir $cache.dir
        $data | save $cache.file
        $data
    }

    $registry_data | each {|entry|
        let package_cache_path = $cache.dir | path join $"($entry.name).nuon"

        # Always check cache first for package data too
        let package_file_data = if ($package_cache_path | path exists) {
            open $package_cache_path
        } else if ($registry_url | path exists) {
            # Local package file
            let package_path = $registry_url | path dirname | path join $entry.path
            open $package_path
        } else {
            # Remote package - fetch and cache
            let base_url = $registry_url | url parse
            let package_url = $base_url | update path ($base_url.path | path dirname | path join $entry.path) | url join
            let data = http get $package_url
            $data | save $package_cache_path
            $data
        }

        # Package data is a table of versions for this package
        $package_file_data | each {|pkg|
            {
                name: $pkg.name,
                # TODO rename package metadata type field to source
                # to avoid confusion with custom|script|module type enumberable
                source: $pkg.type,
                version: $pkg.version,
                # description: ($pkg.description? | default "")
            }
        }
    } | flatten
}

# Add a new registry
@example "Add a new registry" { nupm registry add my-registry https://example.com/registry.nuon }
export def --env add [
    name: string,       # Name of the registry
    url: string,        # URL or path to the registry
    --save,             # Whether to commit the change to the registry index
] {
    if ($name in $env.NUPM_REGISTRIES) {
        throw-error $"Registry '($name)' already exists. Use 'nupm registry update' to modify it."
    }
    $env.NUPM_REGISTRIES = $env.NUPM_REGISTRIES | insert $name $url
    mut add_success_msg =  $"Registry '($name)' added successfully"

    if $save {
      $env.NUPM_REGISTRIES | save --force $env.NUPM_INDEX_PATH
      $add_success_msg = $add_success_msg | append $" and written to ($env.NUPM_INDEX_PATH)." | str join " "

    } else {
      $add_success_msg = $add_success_msg | append $". To commit the change to disk, use the `--save` flag." | str join " "
    }

    print $add_success_msg
}

# Remove a registry
@example "Remove a registry" { nupm registry remove my-registry }
export def --env remove [
    name: string        # Name of the registry to remove
    --save,             # Whether to commit the change to the registry index
] {
    $env.NUPM_REGISTRIES = $env.NUPM_REGISTRIES | reject $name

    if $save {
      $env.NUPM_REGISTRIES | save --force $env.NUPM_INDEX_PATH
    }

    print $"Registry '($name)' removed successfully."
}

# Update a given registry url
@example "Update registry URL" { nupm registry set-url my-registry https://new-url.com/registry.nuon }
export def --env set-url [
    name: string,   # Name of the registry to update
    url: string,
    --save,         # Whether to commit the change to the registry index
]: nothing -> nothing {
    $env.NUPM_REGISTRIES = $env.NUPM_REGISTRIES | update $name $url

    if $save {
      $env.NUPM_REGISTRIES | save --force $env.NUPM_INDEX_PATH
    }

    print $"Registry '($name)' URL updated successfully."
}

# https://www.nushell.sh/book/configuration.html#macos-keeping-usr-bin-open-as-open
alias nu-rename = rename
# Rename a registry
@example "Rename a registry" { nupm registry rename my-registry our-registry }
export def --env rename [
    name: string,   # Name of the registry to update
    new_name: string,
    --save,         # Whether to commit the change to the registry index
] {
    $env.NUPM_REGISTRIES = $env.NUPM_REGISTRIES | nu-rename --column { $name: $new_name }

    if $save {
      $env.NUPM_REGISTRIES | save --force $env.NUPM_INDEX_PATH
    }

    print $"Registry '($name)' renamed successfully."
}

def init-index [] {
    if not (nupm-home-prompt) {
        throw-error "Cannot create NUPM_HOME directory."
    }


    if ($env.NUPM_INDEX_PATH | path exists) {
        print $"Registry list already exists at ($env.NUPM_INDEX_PATH)"
        return
    }

    $env.NUPM_REGISTRIES | save $env.NUPM_INDEX_PATH

    print $"Registry index initialized at ($env.NUPM_INDEX_PATH)"
}


# Initialize a new nupm registry or a registry index if the `--index` flag is
# passed in
@example "Initialize registry index" { nupm registry init --index }
export def init [--index] {
    if $index {
        init-index
        return
    }
    # TODO initialize registry index here
    throw-error UNIMPLEMENTED "`nupm registry --index` is not implemented."
}

