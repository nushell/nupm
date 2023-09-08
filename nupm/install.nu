use std log

use utils/dirs.nu [ nupm-home-prompt script-dir module-dir ]

def throw-error [
    error: string
    text?: string
    --span: record<start: int, end: int>
] {
    let error = $"(ansi red_bold)($error)(ansi reset)"

    if $span == null {
        error make --unspanned { msg: $error }
    }

    error make {
        msg: $error
        label: {
            text: ($text | default "this caused an internal error")
            start: $span.start
            end: $span.end
        }
    }
}

def open-package-file [dir: path] {
    let package_file = $dir | path join "package.nuon"

    if not ($package_file | path exists) {
        throw-error $"package_file_not_found(ansi reset):\nno 'package.nuon' found in ($dir)"
    }

    let package = open $package_file

    log debug "checking package file for missing required keys"
    let required_keys = [$. $.name $.version $.type]
    let missing_keys = $required_keys | where {|key| ($package | get -i $key) == null}
    if not ($missing_keys | is-empty) {
        throw-error $"invalid_package_file(ansi reset):\n($package_file) is missing the following required keys: ($missing_keys | str join ', ')"
    }

    $package
}

# Install list of scripts into a directory
#
# Input: Scripts taken from 'package.nuon'
def install-scripts [
    pkg_dir: path        # Package directory
    scripts_dir: path    # Target directory where to install
    --force(-f)          # Overwrite already installed scripts
] {
    each {|script|
        let src_path = $pkg_dir | path join $script
        let tgt_path = $scripts_dir | path join $script

        if ($src_path | path type) != file {
            throw-error $"Script ($src_path) does not exist"
        }

        if ($tgt_path | path type) == file and (not $force) {
            throw-error ($"Script ($src_path) is already installed as"
                + $" ($tgt_path)")
        }

        log debug $"installing script `($src_path)` to `($scripts_dir)`"
        cp $src_path $scripts_dir
    }
}

# Install package from a directory containing 'project.nuon'
def install-path [
    pkg_dir: path  # Directory (hopefully) containing 'package.nuon'
    --force(-f)    # Overwrite already installed package
] {
    let pkg_dir = $pkg_dir | path expand --strict

    let package = open-package-file $pkg_dir

    log info $"installing package ($package.name)"

    match $package.type {
        "module" => {
            let mod_dir = $pkg_dir | path join $package.name

            if ($mod_dir | path type) != dir {
                throw-error ($"Module package '($package.name)' does not"
                    + $" contain directory '($package.name)'")
            }

            let module_dir = module-dir --ensure
            let destination = $module_dir | path join $package.name

            if $force {
                rm --recursive --force $destination
            }

            if ($destination | path type) == dir {
                throw-error $"Package ($package.name) is already installed"
            }

            cp --recursive $mod_dir $module_dir

            if $package.scripts? != null {
                log debug $"installing scripts for package ($package.name)"
                $package.scripts | if $force {
                    install-scripts --force $pkg_dir (script-dir --ensure)
                } else {
                    install-scripts $pkg_dir (script-dir --ensure)
                }
            }
        },
        "script" => {
            log debug $"installing scripts for package ($package.name)"

            $package.scripts?
            | default [ ($pkg_dir | path join $"($package.name).nu") ]
            | if $force {
                install-scripts --force $pkg_dir (script-dir --ensure)
            } else {
                install-scripts $pkg_dir (script-dir --ensure)
            }
        },
        "custom" => {
            if not ($pkg_dir | path join "build.nu" | path exists) {
                let text = $"package uses a custom install but no `build.nu` has been found"
                throw-error "invalid_package_file" $text --span (metadata $pkg_dir | get span)
            }

            nu ($pkg_dir | path join 'build.nu')
        },
        _ => {
            let text = $"expected `$.type` to be one of [module, script, custom], got ($package.type)"
            throw-error "invalid_package_file" $text --span (metadata $pkg_dir | get span)
        },
    }
}

# Install a nupm package
export def main [
    name    # Name, path, or link to the package
    --path  # Install package from a directory with package.nuon given by 'name'
    --force(-f)  # Overwrite already installed package
] {
    nupm-home-prompt

    if not $path {
        throw-error "`nupm install` currently requires a `--path` flag"
    }

    if $force {
        install-path --force $name
    } else {
        install-path $name
    }
}
