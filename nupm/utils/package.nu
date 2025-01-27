# Open nupm.nuon
export def open-package-file [dir: path] {
    if not ($dir | path exists) {
        throw-error "package_dir_does_not_exist" (
            $"Package directory ($dir) does not exist"
        )
    }

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

    # TODO: Verify types of each field

    $package
}

# Lists files of a package
#
# This will be useful for file integrity checks
export def list-package-files [pkg_dir: path, pkg: record]: nothing -> list<path> {
    let activation = match $pkg.type {
        'module' => $'use ($pkg.name)'
        'script' => {
            # we'd have to call `source script.nu` which would run the script
            throw-error 'Checking status of script package is not supported'
        }
        _ => null
    }

    let src = $"
        ($activation)
        view files
        | where \($it.filename | str starts-with ($pkg_dir)\)
        | get filename
        | to nuon"

    mut files = []

    if $activation != null {
        cd $pkg_dir
        let out = nu -c $src | complete
        if $out.exit_code == 0 {
            $files ++= ($out.stdout | from nuon)
        }
    }

    $files ++= [($pkg.scripts?
        | default []
        | each {|script| $pkg_dir | path join $script})]

    $files
}
