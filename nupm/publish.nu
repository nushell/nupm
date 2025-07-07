use utils/log.nu throw-error
use utils/misc.nu hash-fn
use utils/package.nu open-package-file
use utils/registry.nu [ search-package REG_COLS REG_PKG_COLS ]
use utils/version.nu sort-by-version

# Publish package to registry
#
# Publishes the package in the current working directory to a registry.
# The package must have a nupm.nuon metadata file.
#
# By default, changes are only previewed. To apply them, use the `--save` flag.
# Needs to run from package root, i.e., where nupm.nuon is.
#
# The `--path` flag defines the `path` field of the registry package file. Its
# meaning depends on the package type:
# * git packages   : Path to the package relative to git repo root
# * local packages : Path to the package relative to registry file
#
# NOTE: `\` inside the `path` field are  replaced with `/` to avoid
# conflicts between Windows and non-Windows platforms.
@example "Publish with additional package info" {
  nupm publish my-registry.nuon --git --info {url: "https://github.com/user/repo", revision: "main"}
}
@example "Publish git package with custom path" {
  nupm publish my-registry.nuon --git --path packages/my-package
}
@example "Publish and save to local registry" {
  nupm publish my-registry.nuon --local --save
}
export def main [
    registry: string  # Registry file to publish to (local file or name pointing
                      # at a local registry)
    --git             # Publish package as a git package
    --local           # Publish package as a local package
    --info: record    # Package info based on package type (e.g., `url` and
                      # `revision` for a git package)
    --path: string    # `path` field of the registry entry file
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
        throw-error $'Registry path ($reg_path) must be a path to a local file.'
    }

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
            throw-error ($"Cannot guess package type because package"
                + $" ($pkg.name) was not found in registry ($registry). Specify"
                + " the type manually with --git or --local flag.")
        }

        $res | last | get type
    }

    # Preparation
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

    let path = if $path != null { $path | str replace --all '\' '/' } else { "." }

    let pkg_entry = {
        name: $pkg.name
        version: $pkg.version
        path: $path
        type: $pkg_type
        info: $info
    }

    let pkg_file_path_full = $reg_path
        | path dirname
        | path join $pkg_file_path
        | path expand

    print ""
    print ("New entry to package file"
        + $" (ansi cyan_bold)($pkg_file_path_full)(ansi reset):")
    print ($pkg_entry | table --expand)

    # add the entry to the package file
    let pkg_file_content = $pkg_file_path_full | open-reg-pkg-file

    if $pkg.version in $pkg_file_content.version {
        throw-error ($"Version ($pkg.version) of package ($pkg.name) is already"
            + $" published in registry ($registry)")
    }

    let pkg_file_nuon = $pkg_file_content
        | append $pkg_entry
        | sort-by-version
        | to nuon

    if $save {
        print $"(ansi yellow)=> SAVED!(ansi reset)"
        $pkg_file_nuon | save --raw --force $pkg_file_path_full
    }

    # Create entry to the registry file
    let hash = $pkg_file_nuon | hash-fn

    let reg_entry = {
        name: $pkg.name
        path: $pkg_file_path
        hash: $hash
    }

    print ""
    print $"New entry to registry file (ansi cyan_bold)($reg_path)(ansi reset):"
    print ($reg_entry | table --expand)

    # add the entry to the registry file
    let reg_nuon = $reg_content
        | where name != $pkg.name
        | append $reg_entry
        | sort-by name
        | to nuon

    if $save {
        print $"(ansi yellow)=> SAVED!(ansi reset)"
        $reg_nuon | save --raw --force $reg_path
    } else {
        print ""
        print $"(ansi yellow)If the changes look good, re-run with --save to apply them.(ansi reset)"
    }
}

def guess-url []: nothing -> string {
    mut url = (do -i { ^git remote get-url origin | complete } | get stdout)

    if ($url | is-empty) {
        let first_remote = do -i { ^git remote | lines | first } | get stdout

        if not ($first_remote | is-empty) {
            $url = (do -i { ^git remote get-url $first_remote | complete }
                | get stdout)
        }
    }

    let url = if ($url | str contains "git@github") {
        let parsed = $url | str trim | parse "git@github.com:{user}/{repo}.git"
        $'https://github.com/($parsed.user.0)/($parsed.repo.0)'
     } else {
        $url
    }

    $url | str trim
}

def guess-revision []: nothing -> string {
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
    let exp_cols = $REG_COLS

    if (($reg_content | is-not-empty)
        and ($reg_content | columns) != $exp_cols) {
        throw-error ($"Unexpected columns of registry ($reg_path)."
            + $" Got ($reg_content | columns), needs ($exp_cols).")
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
    let exp_cols = $REG_PKG_COLS

    if (($pkg_content | is-not-empty)
        and ($pkg_content | columns) != $exp_cols) {
        throw-error ($"Unexpected columns of package file ($pkg_path)."
            + $" Got ($pkg_content | columns), needs ($exp_cols).")
    }

    $pkg_content | default []
}
