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


# TODO
# Show detailed information about a specific registry
# @example "Show registry information" { nupm registry describe nupm }
# export def describe [
#     name: string        # Name of the registry
# ]: nothing -> table {
# }

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

# Rename a registry
@example "Rename a registry" { nupm registry rename my-registry our-registry }
export def --env rename [
    name: string,   # Name of the registry to update
    new_name: string,
    --save,         # Whether to commit the change to the registry index
] {
    $env.nupm.registries = $env.nupm.registries | ^rename --column { $name: $new_name }

    if $save {
      $env.nupm.registries | save --force $env.nupm.index-path
    }

    print $"Registry '($name)' renamed successfully."
}


# Initialize registry_idx.nuon with default registries
@example "Initialize registry list" { nupm registry init-index }
export def init-index [

    registry?: record<name: string, url: string, enabled: bool>
] {
    if not (nupm-home-prompt) {
        throw-error "Cannot create nupm.home directory."
    }

    let registry_idx_path = $env.nupm.home | path join "registry_idx.nuon"

    if ($registry_idx_path | path exists) {
        print $"Registry list already exists at ($registry_idx_path)"
        return
    }

    # Initialize with the default nupm registry
    let default_registries = [
        {
            name: "nupm",
            url: "https://raw.githubusercontent.com/nushell/nupm/main/registry/registry.nuon",
            enabled: true
        }
    ]

    $default_registries | save $registry_idx_path

    print $"Registry list initialized at ($registry_idx_path)"
}
