use utils/completions.nu complete-registries
use utils/dirs.nu [ nupm-home-prompt cache-dir module-dir script-dir tmp-dir ]
use utils/log.nu throw-error
use utils/misc.nu [check-cols hash-fn url]
use utils/package.nu open-package-file
use utils/registry.nu search-package
use utils/version.nu filter-by-version

# Install list of scripts into a directory
#
# Input: Scripts taken from 'nupm.nuon'
def install-scripts [
    pkg_dir: path        # Package directory
    scripts_dir: path    # Target directory where to install
    --force(-f)          # Overwrite already installed scripts
]: [list<path> -> nothing] {
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
                rm --recursive --force $destination
            }

            if ($destination | path type) == dir {
                throw-error "package_already_installed" (
                    $"Package ($package.name) is already installed in"
                    + $" ($destination). Use `--force` to override the package"
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


# Downloads a package and returns its downloaded path
def download-pkg [
    pkg: record<
        name: string,
        version: string,
        path: string,
        type: string,
        info: any,
    >
]: nothing -> path {
    # TODO: Add some kind of hashing to check that files really match

    if ($pkg.type != 'git') {
        throw-error 'Downloading non-git packages is not supported yet'
    }

    let cache_dir = cache-dir --ensure
    cd $cache_dir

    let git_dir = $cache_dir | path join git
    mkdir $git_dir
    cd $git_dir

    let repo_name = $pkg.info.url | url stem
    let url_hash = $pkg.info.url | hash-fn # in case of git repo name collision
    let clone_dir = $'($repo_name)-($url_hash)-($pkg.info.revision)'

    let pkg_dir = if $pkg.path == null {
        $env.PWD | path join $clone_dir
    } else {
        $env.PWD | path join $clone_dir $pkg.path
    }

    if ($pkg_dir | path exists) {
        print $'Package ($pkg.name) found in cache'
        return $pkg_dir
    }

    try {
        git clone $pkg.info.url $clone_dir
    } catch {
        throw-error $'Error cloning repository ($pkg.info.url)'
    }

    cd $clone_dir

    try {
        git checkout $pkg.info.revision
    } catch {
        throw-error $'Error checking out revision ($pkg.info.revision)'
    }

    if not ($pkg_dir | path exists) {
        throw-error $'Path ($pkg_dir) does not exist'
    }

    $pkg_dir
}

# Fetch a package from a registry
def fetch-package [
    package: string  # Name of the package
    --registry: string  # Which registry to use
    --version: string  # Package version to install (string or null)
]: nothing -> path {
    let regs = search-package $package --registry $registry --exact-match

    if ($regs | is-empty) {
        throw-error $'Package ($package) not found in any registry'
    } else if ($regs | length) > 1 {
        # TODO: Here could be interactive prompt
        throw-error $'Multiple registries contain package ($package)'
    }

    # Now, only one registry contains the package
    let reg = $regs | first
    let pkgs = $reg.pkgs | filter-by-version $version

    let pkg = try {
        $pkgs | last
    } catch {
        throw-error $'No package matching version `($version)`'
    }

    if $pkg.hash_mismatch == true {
      throw-error ($'Content of package file ($pkg.path)'
                        + $' does not match expected hash')
    }

    print $pkg

    if $pkg.type == 'git' {
        download-pkg $pkg
    } else {
        # local package path is relative to the registry file (absolute paths
        # are discouraged but work)
        if $pkg.path == null {
            $reg.registry_path | path dirname
        } else {
            $reg.registry_path | path dirname | path join (if $pkg.path == "." { "" } else { $pkg.path })
        }
    }
}

# Install a nupm package
#
# Installation consists of two parts:
# 1. Fetching the package (if the package is online)
# 2. Installing the package (build action, if any; copy files to install location)
export def main [
    package  # Name, path, or link to the package
    --registry: string@complete-registries  # Which registry to use (either a name
                                            # in $env.NUPM_REGISTRIES or a path)
    --pkg-version(-v): string  # Package version to install
    --path  # Install package from a directory with nupm.nuon given by 'name'
    --force(-f)  # Overwrite already installed package
    --no-confirm  # Allows to bypass the interactive confirmation, useful for scripting
]: nothing -> nothing {
    if not (nupm-home-prompt --no-confirm=$no_confirm) {
        return
    }

    let pkg: path = if not $path {
        fetch-package $package --registry $registry --version $pkg_version
    } else {
        if $pkg_version != null {
            throw-error "Use only --path or --pkg-version, not both"
        }

        $package
    }

    install-path $pkg --force=$force
}
