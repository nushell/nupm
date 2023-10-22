use std log

use utils/dirs.nu [ nupm-home-prompt script-dir module-dir tmp-dir ]
use utils/log.nu throw-error

def open-package-file [dir: path] {
    let package_file = $dir | path join "package.nuon"

    if not ($package_file | path exists) {
        throw-error "package_file_not_found" (
            $'Could not find "package.nuon" in ($dir) or any parent directory.'
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
# Input: Scripts taken from 'package.nuon'
def install-scripts [
    pkg_dir: path        # Package directory
    scripts_dir: path    # Target directory where to install
    --force(-f): bool    # Overwrite already installed scripts
]: list<path> -> nothing {
    each {|script|
        let src_path = $pkg_dir | path join $script
        let dst_path = $scripts_dir | path join $script

        if ($src_path | path type) != file {
            throw-error "script_not_found" $"Script ($src_path) does not exist"
        }

        if $force {
            rm --recursive --force $dst_path
        }

        if ($dst_path | path type) == file and (not $force) {
            throw-error "script_already_installed" (
                $"Script ($src_path) is already installed in"
                + $" ($scripts_dir). Use `--force` to override it."
            )
        }

        log debug $"installing script `($src_path)` to `($scripts_dir)`"
        cp $src_path $scripts_dir
    }

    null
}

# Install list of modules into a directory
#
# Input: Modules taken from 'package.nuon'
def install-modules [
    pkg_dir: path        # Package directory
    modules_dir: path    # Target directory where to install
    --force(-f): bool    # Overwrite already installed modules
]: list<path> -> nothing {
    each {|module|
        let src_path = $pkg_dir | path join $module
        let dst_path = $modules_dir | path join ($module | path split | last)

        if not ($src_path | path exists) {
            throw-error "module_not_found" $"Module ($src_path) does not exist"
        }

        if $force {
            rm --recursive --force $dst_path
        }

        if ($dst_path | path exists) == file and (not $force) {
            throw-error "module_already_installed" (
                $"Module  ($src_path) is already installed in"
                + $" ($modules_dir). Use `--force` to override it."
            )
        }

        log debug $"installing module `($src_path)` to `($modules_dir)`"
        cp -r $src_path $modules_dir
    }

    null
}


# Install package from a directory containing 'project.nuon'
def install-path [
    pkg_dir: path      # Directory (hopefully) containing 'package.nuon'
    --force(-f): bool  # Overwrite already installed package
] {
    let pkg_dir = $pkg_dir | path expand --strict

    let package = open-package-file $pkg_dir

    log info $"installing package ($package.name)"

    match $package.type {
        "module" => {
            let default_name = $package.name

            if ($pkg_dir | path join $default_name | path exists) {
                [ $default_name ]
            } else {
                []
            }
            | append ($package.modules? | default [])
            | install-modules $pkg_dir (module-dir --ensure) --force $force

            $package.scripts?
            | default []
            | install-scripts $pkg_dir (script-dir --ensure) --force $force
        },
        "script" => {
            let default_name = $"($package.name).nu"

            if ($pkg_dir | path join $default_name | path exists) {
                [ $default_name ]
            } else {
                []
            }
            | append ($package.scripts? | default [])
            | install-scripts $pkg_dir (script-dir --ensure) --force $force

            $package.modules? 
            | default []
            | install-modules $pkg_dir (module-dir --ensure) --force $force
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
                ^$nu.current-exe $build_file ($pkg_dir | path join 'package.nuon')
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

# Install a nupm package
export def main [
    package # Name, path, or link to the package
    --path  # Install package from a directory with package.nuon given by 'name'
    --force(-f)  # Overwrite already installed package
]: nothing -> nothing {
    nupm-home-prompt

    if not $path {
        throw-error "missing_required_option" "`nupm install` currently requires a `--path` flag"
    }

    install-path $package --force $force
}
