# NOTE: just to wait for 0.88 and `std null-device`
def null-device []: nothing -> path {
    "/dev/null"
}

export def build [package: path, --target-directory: path = "target/"] {
    let pkg = open ($package | path join "package.nuon") | get name
    let target_directory = $target_directory | path expand

    # TODO: use `mktemp` from `0.88`
    let head = ^mktemp -t -d nupm_install_XXXXXXX
    ^git worktree add --detach $head HEAD out+err> (null-device)
    rm --recursive ($head | path join ".git")
    ^git worktree prune out+err> (null-device)

    let target = $target_directory | path join $pkg (^git rev-parse HEAD)
    if ($target | path exists) {
        rm --recursive $target
    }
    mkdir $target

    let package_files = $head | path join $package $pkg
    cp --recursive $package_files ($target | path join "pkg")

    let activation = $"export-env {
        $env.NU_LIB_DIRS = \($env.NU_LIB_DIRS? | default [] | prepend ($target)\)
    }"
    $activation | save --force ($target | path join "activate.nu")
}

export def run [package: path, --target-directory: path = "target/"] {
    let pkg = open ($package | path join "package.nuon") | get name
    let target_directory = $target_directory | path expand

    nu --execute $"
        overlay use ($target_directory | path join $pkg (^git rev-parse HEAD) "activate.nu")
        const PKG = ($package | path join $pkg)
    "
}
