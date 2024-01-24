use std repeat
use utils/utils.nu open-package-file

# Runs a nu command in a shell without configs.
def run-nu [code: string]: nothing -> any {
    ^$nu.current-exe --no-config-file --commands ($code ++ " | to nuon") | from nuon
}

# Gets the module's metadata using the `scope` command.
# TODO Plugins
def get-module-metadata [
    basic_module_metadata: record<name: string, path: path>
]: nothing -> record<name: string, commands: list<string>, submodules: list<record>, path: path, parent_names: list<string>> {
    run-nu $"
        use ($basic_module_metadata.path)
        scope modules | where name == ($basic_module_metadata.name) | into record | reject env_block
    " | insert path $basic_module_metadata.path | insert parent_names []
}

# Generates the documentation for a given command.
def document-command [
    module_name: string,
    full_module_name: string,
    full_module_name_with_leading_path: string
]: string -> string {
    let command = $in

    let command_file = $command
        | str replace --all ' ' '-'
        | path parse
        | update extension md
        | path join

    let imported_command = if ($command == $module_name) { "" } else { $"'($command)'" }

    let help = run-nu $"
        use ($full_module_name_with_leading_path) ($imported_command)
        scope commands | where name == '($command)' | into record
    "

    let signatures = $help.signatures | transpose | get column1

    let page = [
        $"# `($command)` \(`($full_module_name)`\)",
        $help.usage,
        "",
        $help.extra_usage,
        "",
        "## Parameters",
        (
            $signatures.0
                | where parameter_type not-in ["input", "output"]
                | each {
                    transpose
                        | where not ($it.column1 | is-empty)
                        | transpose --header-row
                        | into record
                        | to text
                        | lines
                        | str replace --regex '^' '- '
                        | str join "\n"
                }
                | str join "\n---\n"
        ),
        "",
        $"## Signatures",
        (
            $signatures
                | each {
                    where parameter_type in ["input", "output"]
                        | select parameter_type syntax_shape
                        | transpose --header-row
                }
                | flatten
                | update input { $"`($in)`" }
                | update output { $"`($in)`" }
                | to md --pretty
        ),
    ]

    $page | flatten | str join "\n" | save --force --append $command_file

    $command_file
}

# /!\ will save each command encountered to the main index file as a side effect
def document-module [
    main_index: path,
    documentation_dir: path,
    module: record<name: string, commands: list<string>, submodules: list<record>, path: path, parent_names: list<string>>
    depth?: int = 0,
]: nothing -> nothing {

    mkdir ($module.name | path basename)
    cd ($module.name | path basename)

    let full_module_name = $module.name + ' ' + ($module.parent_names | str join ' ')

    let commands = if ($module.commands.name | is-empty) {
        "no commands"
    } else {
        $module.commands.name | each {|command|
            let command_file = ($command
            | document-command $module.name $full_module_name $module.path)

            let full_command_file = (
                $full_module_name | str replace --all ' ' '/' | path join $command_file
            )
            $"- [`($command)`]\(($full_command_file)\)\n" | save --force --append $main_index

            $"- [`($command)`]\(($command_file)\)"
        }
    }

    let submodules = $module.submodules | each {|submodule|
        $"- [`($submodule.name)`]\(($submodule.name)/README.md\)"
    }

    let submodules_section = match $submodules {
        null => [],
        $sub => (["", "## Submodules", $submodules]),
    }

    let page = [
        $"# Module `($full_module_name | str trim)`",
        "## Description",
        $module.usage,
        "",
        "## Commands",
        $commands,
        ...$submodules_section,
    ]

    $page | flatten | str join "\n" | save --force README.md

    for submodule in $module.submodules {
        let submodule_path = ($module.path + ' ' + $submodule.name)
        let parent_names = $module.parent_names | append $module.name
        let modified_submodule = $submodule | insert path $submodule_path | insert parent_names $parent_names
        document-module $main_index $documentation_dir $modified_submodule ($depth + 1)
    }
}

const metadata_filename = 'nupm.nuon'

# Generates markdown documentation of the current or provided nushell modules.
#
# ## Examples
# Basic usage
# ```nushell
# nupm doc
# ```
export def main [
    --documentation-dir: path # The directory to put generated documentation in.
    --library-paths: list<path> = [] # A list of paths to nushell modules to generate documentation for.
    --plugin-paths: list<path> = [] # NOT IMPLEMENTED YET
    --not-local # Tells the command not to generate documentation for the current directory if the current directory has a nupm.nuon file in it.
]: nothing -> nothing {

    let package_metadata = try {
        let all_package_metadata = open-package-file (pwd)
        
        let local_module = if (not $not_local) and (not ($all_package_metadata == null)) {
            match $all_package_metadata.type {
                'module' => ((pwd) | path join $all_package_metadata.name),
                'script' => { print 'Script package type doc generation not implemented yet.' },
                'custom' => { print 'Custom package type doc generation not implemented yet.' },
            }
        } else {
            []
        }

        {
            local_module: $local_module,
            doc_dir: ($all_package_metadata | get -i documentation-dir),
        }
    } catch {

        {
            local_module: [],
            doc_dir: null,
        }
    }

    let modules = $library_paths ++ $package_metadata.local_module | each {{ name: ($in | path basename), path: $in }}

    let documentation_dir = if $documentation_dir != null {
        $documentation_dir
    } else if ($package_metadata | get -i doc_dir) != null {
        $package_metadata.doc_dir
    } else {
        "./docs/"
    }

    let documentation_dir = $documentation_dir | path expand

    rm --force --recursive $documentation_dir
    mkdir $documentation_dir
    cd $documentation_dir

    "## Modules\n" | save --force --append README.md
    for module in ($modules | get name) {
        $"- [`($module)`]\(./($module)/README.md\)\n" | save --force --append README.md
    }

    "\n" | save --force --append README.md
    "## Commands\n" | save --force --append README.md

    let root = pwd | path dirname
    let main_index = $root | path join $documentation_dir "README.md"

    for module in $modules {
        let module_metadata = get-module-metadata $module
        document-module $main_index $documentation_dir $module_metadata
    }
}
