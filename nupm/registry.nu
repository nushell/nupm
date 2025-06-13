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
    let registry_list_path = $env.NUPM_HOME | path join "registry_list.nuon"
    
    if not ($registry_list_path | path exists) {
        init
    }
    
    let registries = open $registry_list_path
    
    $registries | select name url enabled | sort-by name
}

# Add a new registry
@example "Add a new registry" { nupm registry add my-registry https://example.com/registry.nuon }
@example "Add a disabled registry" { nupm registry add test-registry ./local-registry.nuon --enabled=false }
export def add [
    name: string,       # Name of the registry
    url: string,        # URL or path to the registry
    --enabled=true      # Whether the registry should be enabled
]: nothing -> nothing {
    let registry_list_path = $env.NUPM_HOME | path join "registry_list.nuon"
    
    if not ($registry_list_path | path exists) {
        init
    }
    
    mut registries = open $registry_list_path
    
    # Check if registry already exists
    if ($registries | where name == $name | length) > 0 {
        throw-error $"Registry '($name)' already exists. Use 'nupm registry update' to modify it."
    }
    
    # Add new registry
    $registries = ($registries | append {
        name: $name,
        url: $url,
        enabled: $enabled
    })
    
    $registries | save --force $registry_list_path
    
    print $"Registry '($name)' added successfully."
}

# Remove a registry
@example "Remove a registry" { nupm registry remove my-registry }
export def remove [
    name: string        # Name of the registry to remove
]: nothing -> nothing {
    let registry_list_path = $env.NUPM_HOME | path join "registry_list.nuon"
    
    if not ($registry_list_path | path exists) {
        throw-error "No registry list found. Run 'nupm registry init' first."
    }
    
    let registries = open $registry_list_path
    
    # Check if registry exists
    if ($registries | where name == $name | length) == 0 {
        throw-error $"Registry '($name)' not found."
    }
    
    # Remove registry
    let updated_registries = $registries | where name != $name
    $updated_registries | save --force $registry_list_path
    
    print $"Registry '($name)' removed successfully."
}

# Update registry URL or enable/disable status
@example "Update registry URL" { nupm registry update my-registry --url https://new-url.com/registry.nuon }
@example "Enable a registry" { nupm registry update my-registry --enable }
@example "Disable a registry" { nupm registry update my-registry --disable }
export def update [
    name: string,       # Name of the registry to update
    --url: string,      # New URL for the registry
    --enable,           # Enable the registry
    --disable           # Disable the registry
]: nothing -> nothing {
    let registry_list_path = $env.NUPM_HOME | path join "registry_list.nuon"
    
    if not ($registry_list_path | path exists) {
        throw-error "No registry list found. Run 'nupm registry init' first."
    }
    
    mut registries = open $registry_list_path
    
    # Check if registry exists
    if ($registries | where name == $name | length) == 0 {
        throw-error $"Registry '($name)' not found."
    }
    
    # Update registry
    $registries = ($registries | each {|reg|
        if $reg.name == $name {
            let updated_url = if ($url | is-empty) { $reg.url } else { $url }
            let updated_enabled = if $enable {
                true
            } else if $disable {
                false
            } else {
                $reg.enabled
            }
            
            {
                name: $reg.name,
                url: $updated_url,
                enabled: $updated_enabled
            }
        } else {
            $reg
        }
    })
    
    $registries | save --force $registry_list_path
    
    print $"Registry '($name)' updated successfully."
}

# Initialize registry_list.nuon with default registries
@example "Initialize registry list" { nupm registry init }
export def init []: nothing -> nothing {
    if not (nupm-home-prompt) {
        throw-error "Cannot create NUPM_HOME directory."
    }
    
    let registry_list_path = $env.NUPM_HOME | path join "registry_list.nuon"
    
    if ($registry_list_path | path exists) {
        print $"Registry list already exists at ($registry_list_path)"
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
    
    $default_registries | save $registry_list_path
    
    print $"Registry list initialized at ($registry_list_path)"
}

# Show detailed information about a specific registry
@example "Show registry information" { nupm registry info nupm }
export def info [
    name: string        # Name of the registry
]: nothing -> table {
    let registry_list_path = $env.NUPM_HOME | path join "registry_list.nuon"
    
    if not ($registry_list_path | path exists) {
        throw-error "No registry list found. Run 'nupm registry init' first."
    }
    
    let registries = open $registry_list_path
    let registry = $registries | where name == $name
    
    if ($registry | length) == 0 {
        throw-error $"Registry '($name)' not found."
    }
    
    $registry | first
}