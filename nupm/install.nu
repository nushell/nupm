use std log

use utils/dirs.nu [ nupm-home-prompt script-dir module-dir tmp-dir ]
use utils/log.nu throw-error
use utils/version.nu sort-pkgs
use utils/misc.nu check-cols

def open-package-file [dir: path] {
    let package_file = $dir | path join "nupm.nuon"

    if not ($package_file | path exists) {
        throw-error "package_file_not_found" (
            $'Could not find "nupm.nuon" in ($dir) or any parent directory.'
        )
    }

    let package = open $package_file

    log debug "checking package file for missing required keys"
    let required_keys = [$. $.name $.version $.type]
    let missing_keys = $required_keys
        | where {|key| ($package | get -i $key) == null}
    if not ($missing_keys | is-empty) {
        throw-error "invalid_package_file" (
            $"($package_file) is missing the following required keys:"
            + $" ($missing_keys | str join ', ')"
        )
    }

    $package
}

# Install list of scripts into a directory
#
# Input: Scripts taken from 'nupm.nuon'
def install-scripts [
    pkg_dir: path        # Package directory
    scripts_dir: path    # Target directory where to install
    --force(-f)          # Overwrite already installed scripts
]: list<path> -> nothing {
    each {|script|
        let src_path = $pkg_dir | path join $script

        if ($src_path | path type) != file {
            throw-error "script_not_found" $"Script ($src_path) does not exist"
        }

        if (($scripts_dir
                | path join ($script | path basename)
                | path type) == file
            and (not $force)
        ) {
            throw-error "package_already_installed" (
                $"Script ($src_path) is already installed in"
                + $" ($scripts_dir). Use `--force` to override the package."
            )
        }

        log debug $"installing script `($src_path)` to `($scripts_dir)`"
        cp $src_path $scripts_dir
    }

    null
}

# Install package from a directory containing 'project.nuon'
def install-path [
    pkg_dir: path      # Directory (hopefully) containing 'nupm.nuon'
    --force(-f)        # Overwrite already installed package
] {
    let pkg_dir = $pkg_dir | path expand

    let package = open-package-file $pkg_dir

    log info $"installing package ($package.name)"

    match $package.type {
        "module" => {
            let mod_dir = $pkg_dir | path join $package.name

            if ($mod_dir | path type) != dir {
                throw-error "invalid_module_package" (
                    $"Module package '($package.name)' does not"
                    + $" contain directory '($package.name)'"
                )
            }

            let module_dir = module-dir --ensure
            let destination = $module_dir | path join $package.name

            if $force {
                if ($destination | path exists) {
                    rm --recursive --force $destination
                }
            }

            if ($destination | path type) == dir {
                throw-error "package_already_installed" (
                    $"Package ($package.name) is already installed."
                    + "Use `--force` to override the package"
                )
            }

            cp --recursive $mod_dir $module_dir

            if $package.scripts? != null {
                log debug $"installing scripts for package ($package.name)"

                $package.scripts
                | install-scripts $pkg_dir (script-dir --ensure) --force=$force
            }
        },
        "script" => {
            log debug $"installing scripts for package ($package.name)"

            [ ($pkg_dir | path join $"($package.name).nu") ]
            | append ($package.scripts? | default [])
            | install-scripts $pkg_dir (script-dir --ensure) --force=$force
        },
        "custom" => {
            let build_file = $pkg_dir | path join "build.nu"
            if not ($build_file | path exists) {
                let text = "package uses a custom install but no `build.nu` has"
                        + " been found"
                (throw-error
                    "invalid_package_file"
                    $text
                    --span (metadata $pkg_dir | get span))
            }

            let tmp_dir = tmp-dir build --ensure

            do {
                cd $tmp_dir
                ^$nu.current-exe $build_file ($pkg_dir | path join 'nupm.nuon')
            }

            rm -rf $tmp_dir
        },
        _ => {
            let text = $"expected `$.type` to be one of [module, script,"
                + " custom], got ($package.type)"
            (throw-error
                "invalid_package_file"
                $text
                --span (metadata $pkg_dir | get span))
        },
    }
}

def fetch-package [
    package: string  # Name of the package
    --registry: string  # Which registry to use
] {
    # Collect all registries matching the package and all matching packages
    let regs = $env.NUPM_REGISTRIES 
        | items {|name, path|
            if ($registry | is-empty) or ($name == $registry) or ($path == $registry) {
                print $path

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
                    | where name == $package

                let pkgs_git = $registry.git? 
                    | default [] 
                    | check-cols "git packages" [ name version url revision path ]
                    | where name == $package

                # Detect duplicate versions
                let all_versions = $pkgs_local.version? 
                    | default []
                    | append ($pkgs_git.version? | default [])

                if ($all_versions | uniq | length) != ($all_versions | length) {
                    throw-error ($'Duplicate versions of package ($package) detected'
                        + $' in registry ($name).')
                }

                let pkgs = $pkgs_local
                    | insert type local
                    | insert url null
                    | insert revision null
                    | append ($pkgs_git | insert type git)

                {
                    name: $name
                    pkgs: $pkgs
                }
            }
        }
        | compact

    if ($regs | is-empty) {
        throw-error 'No registries found'
    } else if ($regs | length) > 1 {
        # TODO: Here could be interactive prompt
        throw-error 'Multiple registries contain the same package'
    }

    # Now, only one registry contains the package
    $regs | first | get pkgs | sort-pkgs | last
}

# Install a nupm package
#
# Installation consists of two parts:
# 1. Fetching the package (if the package is online)
# 2. Installing the package (build action, if any; copy files to install location)
export def main [
    package # Name, path, or link to the package
    --registry: string # Which registry to use
    --path  # Install package from a directory with nupm.nuon given by 'name'
    --force(-f)  # Overwrite already installed package
    --no-confirm # Allows to bypass the interactive confirmation, useful for scripting
]: nothing -> nothing {
    if not (nupm-home-prompt --no-confirm=$no_confirm) {
        return
    }

    if not $path {
        fetch-package $package --registry $registry
    }

    # install-path $package --force=$force
}
