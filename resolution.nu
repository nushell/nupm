const PACKAGE_FILE = "package.nuon"

# NOTE: just to wait for 0.88 and `std null-device`
def null-device []: nothing -> path {
    "/dev/null"
}

# TODO: just to wait for 0.88 and built-in `mktemp`
def mktemp [pattern: string, --tmpdir, --directory] {
    ^mktemp -t -d $pattern
}

export def build [package: path, --target-directory: path = "target/"] {
    let pkg_file = $package | path join $PACKAGE_FILE
    if not ($pkg_file | path exists) {
        error make {
            msg: $"(ansi red_bold)not_a_package(ansi reset)",
            label: {
                text: $"does not appear to be a package",
                span: (metadata $package).span,
            },
            help: $"does not contain a `($PACKAGE_FILE)` file",
        }
    }

    let pkg = open $pkg_file | get name
    let target_directory = $target_directory | path expand

    let head = mktemp --tmpdir --directory nupm_install_XXXXXXX
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
    let pkg_file = $package | path join $PACKAGE_FILE
    if not ($pkg_file | path exists) {
        error make {
            msg: $"(ansi red_bold)not_a_package(ansi reset)",
            label: {
                text: $"does not appear to be a package",
                span: (metadata $package).span,
            },
            help: $"does not contain a `($PACKAGE_FILE)` file",
        }
    }

    let pkg = open $pkg_file | get name
    let target_directory = $target_directory | path expand

    let config_file = $nu.temp-path | path join config.nu
    let env_file = $nu.temp-path | path join env.nu

    $"overlay use ($target_directory | path join $pkg (^git rev-parse HEAD) "activate.nu")"
        | save --force $env_file
    "$env.config.show_banner = false" | save --force $config_file

    nu [
        --config $config_file
        --env-config $env_file
        --execute $"
            $env.PROMPT_COMMAND = '($pkg)'
            use ($package | path join $pkg)
        "
    ]
}
