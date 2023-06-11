use std log

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

def nupm-home [] {
    $env.NUPM_HOME? | default (
        $env.XDG_DATA_HOME?
        | default ($nu.home-path | path join ".local" "share")
        | path join "nupm"
    )
}

# install a Nushell package
export def main [
    --path: path  # the path to the local source of the package (defaults to the current directory)
] {
    let path = ($path | default . | path expand)

    let package = ($path | path join "package.nuon" | open)

    let destination = (nupm-home | path join $package.name)
    if not ($destination | path exists) {
        log info $"installing package ($package.name)"
        log debug $"source: ($path)"
        log debug $"destination: ($destination)"
        cp --recursive $path $destination

        if ($destination | path join ".git" | path exists) {
            log debug $"removing .git directory from ($destination)"
            rm --recursive ($destination | path join ".git")
        }
    } else {
        # TODO: add support for updating / reinstalling a package in that case
        throw-error $"package ($package.name) is already installed"
    }
}
