# Registry management for nupm

use utils/dirs.nu [nupm-home-prompt]
use utils/log.nu throw-error

# Show information about configured registries
@example "List all configured registries" { nupm registry }
export def main []: nothing -> table {
    list
}

# List all configured registries
@example "List all registries with details" { nupm registry list }
export def list []: nothing -> table {
    $env.nupm.registries | transpose name url | sort-by name
}

def describe-comp [] {
    list | get name
}

# Show detailed information about a specific registry
# returning a list of package names, type, and version
@example "Show registry information" { nupm registry describe nupm }
export def describe [
    registry: string@describe-comp # Name of the registry
]: nothing -> table {
    use utils/dirs.nu cache-dir

    if not ($registry in $env.nupm.registries) {
        throw-error $"Registry '($registry)' not found"
    }

    let registry_url = $env.nupm.registries | get $registry
    let registry_cache_dir = cache-dir --ensure | path join $registry
    let cached_registry = $registry_cache_dir | path join "registry.nuon"

    try {
        # Always check cache first, only fall back to URL if cache doesn't exist
        let registry_data = if ($cached_registry | path exists) {
            open $cached_registry
        } else if ($registry_url | path exists) {
            # Local registry file
            open $registry_url
        } else {
            # Remote registry - fetch and cache
            let data = http get $registry_url
            mkdir $registry_cache_dir
            $data | save $cached_registry
            $data
        }

        $registry_data | each {|entry|
            let package_cache_path = $registry_cache_dir | path join $"($entry.name).nuon"

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
                    # to avoid confustion with custom|script|module type enumberable
                    source: $pkg.type,
                    version: $pkg.version,
                    # description: ($pkg.description? | default "")
                }
            }
        } | flatten
    } catch {|err|
        throw-error $"Failed to fetch registry data from '($registry_url)': ($err.msg)"
    }
}

# Add a new registry
@example "Add a new registry" { nupm registry add my-registry https://example.com/registry.nuon }
export def --env add [
    name: string,       # Name of the registry
    url: string,        # URL or path to the registry
    --save,             # Whether to commit the change to the registry index
] {
    if ($name in $env.nupm.registries) {
        throw-error $"Registry '($name)' already exists. Use 'nupm registry update' to modify it."
    }
    $env.nupm.registries = $env.nupm.registries | insert $name $url

    if $save {
      $env.nupm.registries | save --force $env.nupm.index-path
    }

    print $"Registry '($name)' added successfully."
}

# Remove a registry
@example "Remove a registry" { nupm registry remove my-registry }
export def --env remove [
    name: string        # Name of the registry to remove
    --save,             # Whether to commit the change to the registry index
] {
    $env.nupm.registries = $env.nupm.registries | reject $name

    if $save {
      $env.nupm.registries | save --force $env.nupm.index-path
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
    $env.nupm.registries = $env.nupm.registries | update $name $url

    if $save {
      $env.nupm.registries | save --force $env.nupm.index-path
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
    $env.nupm.registries = $env.nupm.registries | nu-rename --column { $name: $new_name }

    if $save {
      $env.nupm.registries | save --force $env.nupm.index-path
    }

    print $"Registry '($name)' renamed successfully."
}

# Fetch and cache registry data locally
@example "Fetch a specific registry" { nupm registry fetch nupm }
@example "Fetch all registries" { nupm registry fetch --all }
export def fetch [
    name?: string,  # Name of the registry to fetch (optional if --all is used)
    --all,          # Fetch all configured registries
] {
    use utils/dirs.nu cache-dir

    if $all {
        # Fetch all registries
        let registries = $env.nupm.registries | transpose name url
        print $"Fetching ($registries | length) registries..."

        $registries | each {|reg|
            fetch-registry $reg.name $reg.url
        }

        print "All registries fetched successfully."
    } else if ($name | is-empty) {
        throw-error "Please specify a registry name or use --all flag"
    } else {
        if not ($name in $env.nupm.registries) {
            throw-error $"Registry '($name)' not found"
        }

        let registry_url = $env.nupm.registries | get $name
        fetch-registry $name $registry_url

        print $"Registry '($name)' fetched successfully."
    }
}

# Helper function to fetch a single registry
def fetch-registry [name: string, url: string] {
    use utils/dirs.nu cache-dir

    let registry_cache_dir = cache-dir --ensure | path join $name
    mkdir $registry_cache_dir

    if ($url | path exists) {
        print $"Registry '($name)' is local, copying to cache..."
        cp $url ($registry_cache_dir | path join "registry.nuon")

        # Copy package files if they exist locally
        let registry_data = open $url
        $registry_data | each {|entry|
            let package_path = $url | path dirname | path join $entry.path
            if ($package_path | path exists) {
                cp $package_path ($registry_cache_dir | path join $"($entry.name).nuon")
            }
        }
    } else {
        print $"Fetching registry '($name)' from ($url)..."

        # Fetch registry index
        let registry_data = http get $url
        $registry_data | save --force ($registry_cache_dir | path join "registry.nuon")

        # Fetch all package metadata files
        $registry_data | each {|entry|
            print $"  Fetching package ($entry.name)..."
            let base_url = $url | url parse
            let package_url = $base_url | update path ($base_url.path | path dirname | path join $entry.path) | url join
            let package_data = http get $package_url
            $package_data | save --force ($registry_cache_dir | path join $"($entry.name).nuon")
        }
    }
}


# Initialize registry_idx.nuon with default registries
@example "Initialize registry list" { nupm registry init-index }
export def init-index [

    registry?: record<name: string, url: string, enabled: bool>
] {
    if not (nupm-home-prompt) {
        throw-error "Cannot create nupm.home directory."
    }


    if ($env.nupm.registries | path exists) {
        print $"Registry list already exists at ($env.nupm.index-path)"
        return
    }

    $env.nupm.registries | save $env.nupm.index-path

    print $"Registry list initialized at ($env.nupm.index-path)"
}

# Initialize nupm.registries value
export def open-index []: nothing -> record {
    if ($env.nupm.index-path | path exists) {
      if not (($env.nupm.index-path | path type) == "file") {
          throw-error $"($env.nupm.index-path) is not a filepath"
      }
      open $env.nupm.index-path | return
    }

    {}
}
