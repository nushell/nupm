use std log

# install a Nushell package
export def main [
    --path: path  # the path to the local source of the package (defaults to the current directory)
] {
    let path = ($path | default . | path expand)

    log debug $"path: ($path)"

    throw-error "installing packages is not supported"
}
