use utils/log.nu throw-error
use utils/package.nu open-package-file
use utils/registry.nu search-package
use utils/version.nu sort-by-version

# Publish package to registry
#
# By default, changes are only previewed. To apply them, use the --save flag.
# Needs to run from package root, i.e., where nupm.nuon is.
export def main [
    registry: string  # Registry file to publish to (name or path)
    --git             # Publish package as a git package
    --local           # Publish package as a local package
    --info: record    # Package info based on package type (e.g., url and
                      # revision for a git package)
    --path: string    # Path to the package root relative to the registry file
    # --pkg-file-url: string    # URL of a package registry file
    --save            # Write changes to registry instead of printing changes
] {
    if $git and $local {
        throw-error ("Cannot have more than one package type. Choose one of"
            + " --git or --local or neither, not both.")
    }

    let pkg = open-package-file $env.PWD

    # Registry must point to a local path
    let reg_path = $registry | get-registry-path

    if ($reg_path | path type) != 'file' {
        throw-error $'Registry path ($reg_path) must be a path.'
    }

    print $'Registry path: (ansi cyan_bold)($reg_path)(ansi reset)'

    # Guess package type
    let pkg_type = if $git {
        "git"
    } else if $local {
        "local"
    } else {
        let res = search-package $pkg.name --registry $reg_path --exact-match
            | first # there will be only one result because we passed local path
            | get pkgs
            | sort-by-version

        if ($res | is-empty) {
            throw-error ($"Cannot guess package type because pacakge"
                + $" ($pkg.name) was not found in registry ($registry). Specify"
                + " the type manually with --git or --local flag.")
        }

        $res | last | get type
    }

    # Create entry to the registry file
    mut reg_content = $reg_path | open-registry-file

    let name_matches = if ($reg_content | length) > 0 {
        $reg_content | where name == $pkg.name
    } else {
        []
    }

    mut existing_entry = null

    if ($name_matches | length) == 1 {
        $existing_entry = ($name_matches | first)
    } else if ($name_matches | length) > 1 {
        throw-error ($"Registry ($registry) contains multiple packages named"
            + $" ($pkg.name). This shouldn't happen.")
    }

    let pkg_file_path = if $existing_entry == null {
        $'($pkg.name).nuon'
    } else {
        $existing_entry.path
    }

    if $existing_entry == null {
        # let pkg_file_url = if $pkg_file_url != null {
        #     $pkg_file_url
        # }

        let reg_entry = {
            name: $pkg.name
            path: $pkg_file_path
            # url: $pkg_file_url
        }

        print ""
        print $"New entry to registry file (ansi cyan_bold)($reg_path)(ansi reset):"
        print ($reg_entry | table --expand)

        # Add the entry to the registry file
        $reg_content = ($reg_content | append $reg_entry | sort-by name)

        if $save {
            print $"(ansi yellow)=> SAVED!(ansi reset)"
            $reg_content | save --force $reg_path
        }
    } else {
        print $"Registry file (ansi cyan_bold)($reg_path)(ansi reset) unchanged"
    }

    # Create entry to the package file
    mut info = $info

    if $pkg_type == 'git' {
        $info = ($info | default {
            url: (guess-url)
            revision: (guess-revision)
        })
    }

    match $pkg_type {
        'git' => {
            if $info == null or ($info | columns) != [url revision] {
                throw-error ("Package type 'git' requires info with url and"
                    + " revision fields.")
            }
        }
        'local' => {
            if $info != null {
                throw-error "Package type 'local' must have null info."
            }
        }
    }

    let pkg_entry = {
        name: $pkg.name
        version: $pkg.version
        path: $path
        type: $pkg_type
        info: $info
    }

    let pkg_file_path = $reg_path | path dirname | path join $pkg_file_path

    print ""
    print ("New entry to package file"
        + $" (ansi cyan_bold)($pkg_file_path)(ansi reset):")
    print ($pkg_entry | table --expand)

    # Add the entry to the package file
    let pkg_file_content = $pkg_file_path | open-reg-pkg-file

    if $pkg.version in $pkg_file_content.version {
        throw-error ($"Version ($pkg.version) of package ($pkg.name) is already"
            + $" published in registry ($registry)")
    }

    let pkg_file_content = $pkg_file_content
        | append $pkg_entry
        | sort-by-version

    if $save {
        print $"(ansi yellow)=> SAVED!(ansi reset)"
        $pkg_file_content | save --force $pkg_file_path
    } else {
        print ""
        print $"(ansi yellow)If the changes look good, re-run with --save to apply them.(ansi reset)"
    }
}

def guess-url [] -> string {
    mut url = (do -i { ^git remote get-url origin | complete } | get stdout)

    if ($url | is-empty) {
        let first_remote = do -i { ^git remote | lines | first } | get stdout

        if not ($first_remote | is-empty) {
            $url = (do -i { ^git remote get-url $first_remote | complete }
                | get stdout)
        }
    }

    $url | str trim
}

def guess-revision [] -> string {
    mut revision = (do -i { ^git describe --tags --abbrev=0 | complete }
        | get stdout)

    if ($revision | is-empty) {
        $revision = (do -i { ^git rev-parse HEAD | complete } | get stdout)
    }

    $revision | str trim
}

def get-registry-path []: string -> path {
    let registry = $in
    $env.NUPM_REGISTRIES | get -i $registry | default ($registry | path expand)
}

def open-registry-file []: path -> table<name: string, path: string, url: string> {
    let reg_path = $in

    let reg_content = try { open $reg_path }
    let exp_cols = [name path]

    if (($reg_content | is-not-empty)
        and ($reg_content | columns) != $exp_cols) {
        throw-error ($"Unexpected columns of registry ($reg_path)."
            + $" Needs ($exp_cols).")
    }

    $reg_content | default []
}

def open-reg-pkg-file []: [ path -> table<
        name: string
        version: string
        path: string
        type: string
        info: record<url: string, revision: string>> ] {
    let pkg_path = $in

    let pkg_content = try { open $pkg_path }
    let exp_cols = [name version path type info]

    if (($pkg_content | is-not-empty)
        and ($pkg_content | columns) != $exp_cols) {
        throw-error ($"Unexpected columns of package file ($pkg_path)."
            + $" Needs ($exp_cols).")
    }

    $pkg_content | default []
}
