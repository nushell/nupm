use std log

use utils/dirs.nu [ nupm-home-prompt script-dir module-dir tmp-dir ]
use utils/log.nu throw-error
use utils/utils.nu open-package-file

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
            let source_mod_dir = $pkg_dir | path join $package.name

            if ($source_mod_dir | path type) != dir {
                throw-error "invalid_module_package" (
                    $"Module package '($package.name)' does not"
                    + $" contain directory '($package.name)'"
                )
            }

            let target_mod_dir = module-dir --ensure
            let destination = $target_mod_dir | path join $package.name

            if $force {
                rm --recursive --force $destination
            }

            if ($destination | path type) == dir {
                throw-error "package_already_installed" (
                    $"Package ($package.name) is already installed."
                    + "Use `--force` to override the package"
                )
            }

            cp --recursive $source_mod_dir $target_mod_dir

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

# Install a nupm package
export def main [
    package # Name, path, or link to the package
    --path  # Install package from a directory with nupm.nuon given by 'name'
    --force(-f)  # Overwrite already installed package
    --no-confirm # Allows to bypass the interactive confirmation, useful for scripting
]: nothing -> nothing {
    if not (nupm-home-prompt --no-confirm=$no_confirm) {
        return
    }

    if not $path {
        throw-error "missing_required_option" "`nupm install` currently requires a `--path` flag"
    }

    install-path $package --force=$force
}
