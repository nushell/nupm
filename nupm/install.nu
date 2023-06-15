use std log

def nupm-home [] {
    $env.NUPM_HOME? | default (
        $env.XDG_DATA_HOME?
        | default ($nu.home-path | path join ".local" "share")
        | path join "nupm"
    )
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
        log debug ($it.name | str replace $source "" | str trim --left --char "/")
        cp --recursive $it.name $destination
    }
}

# install a Nushell package
export def main [
    --path: path  # the path to the local source of the package (defaults to the current directory)
] {
    let path = ($path | default . | path expand)

    # NOTE: here, we suppose that the package file exists and is valid
    let package = ($path | path join "package.nuon" | open)
    log info $"installing package ($package.name)"

    let destination = (nupm-home | path join $package.name)

    prepare-directory $destination
    $path | copy-directory-to $destination
}
