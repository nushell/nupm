use std log

def nupm-home [] {
    $env.NUPM_HOME? | default (
        $env.XDG_DATA_HOME?
        | default ($nu.home-path | path join ".local" "share")
        | path join "nupm"
    )
}

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

def open-package-file [path: path] {
    let package_file = ($path | path join "package.nuon")

    if not ($package_file | path exists) {
        throw-error $"package_file_not_found(ansi reset):\nno 'package.nuon' found in ($path)"
    }

    let package = (open $package_file)

    log debug "checking package file for missing required keys"
    let missing_keys = (
        [
            [key required];

            [$. true]
            [$.name true]
            [$.version true]
            [$.description true]
            [$.license true]
        ] | each {|key|
            if ($package | get --ignore-errors $key.key) == null {
                $key
            }
        }
        | where required
        | get key
    )

    if not ($missing_keys | is-empty) {
        throw-error $"invalid_package_file(ansi reset):\n($package_file) is missing the following required keys: ($missing_keys | str join ', ')"
    }

    $package
}

def prepare-directory [directory: path] {
    rm --recursive --force $directory
    mkdir $directory
}

def copy-directory-to [destination: path] {
    let source = $in

    log info "copying directory"
    log debug $"source: ($source)"
    log debug $"destination: ($destination)"

    ls --all $source | where name != ".git" | each {|it|
        log debug ($it.name | str replace $source "" | str trim --left --char (char path_sep))
        cp --recursive $it.name $destination
    }
}

# install a Nushell package
export def main [
    --path: path  # the path to the local source of the package (defaults to the current directory)
] {
    let path = ($path | default . | path expand)
    let package = (open-package-file $path)

    log info $"installing package ($package.name)"

    let destination = (nupm-home | path join $package.name)

    prepare-directory $destination
    $path | copy-directory-to $destination
}
