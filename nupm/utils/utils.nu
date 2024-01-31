use log.nu throw-error

export def open-package-file [dir: path] {
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
