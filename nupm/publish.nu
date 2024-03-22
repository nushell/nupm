use utils/log.nu throw-error
use utils/package.nu open-package-file
use utils/version.nu sort-by-version

# Generate package metadata and optionally add them to a registry
#
# Needs to run from package root, i.e., where nupm.nuon is.
export def main [] { }

export def git [
    registry?: string
    --url(-u): string
    --path(-p): string
    --revision(-r): string
    --save
]: [nothing -> nothing, nothing -> record] {
    let pkg = open-package-file $env.PWD
    let url = $url | default (guess-url)
    let revision = $revision | default (guess-revision)

    let result = {
        name: $pkg.name
        version: $pkg.version
        url: $url
        revision: $revision
        path: $path
    }

    if $registry == null {
        $result
    } else {
        let reg_path = $registry | get-registry-path
        let reg_content = $reg_path | open-registry-file
        let updated = $reg_content | update-registry $result $registry "git"

        if $save {
            $updated | save --force $reg_path
        } else {
            $updated
        }
    }
}

export def local [
    registry?: string
    --path(-p): string
    --save
]: [nothing -> nothing, nothing -> record] {
    let pkg = open-package-file $env.PWD

    let result = {
        name: $pkg.name
        version: $pkg.version
        path: $path
    }

    if $registry == null {
        $result
    } else {
        let reg_path = $registry | get-registry-path

        let path = try {
            $env.PWD | path relative-to ($reg_path | path dirname)
        } catch {
            $env.PWD
        }

        let $path = if ($path | is-empty) { null } else { $path }
        let result = $result | update path $path

        let reg_content = $reg_path | open-registry-file
        let updated = $reg_content | update-registry $result $registry "local"

        if $save {
            $updated | save --force $reg_path
        } else {
            $updated
        }
    }
}

def guess-url [] -> string {
    mut url = ^git remote get-url origin | complete | get stdout

    if ($url | is-empty) {
        let first_remote = ^git remote | lines | first
        $url = (^git remote get-url $first_remote | complete | get stdout)
    }

    $url | str trim
}

def guess-revision [] -> string {
    mut revision = ^git describe --tags --abbrev=0 | complete | get stdout

    if ($revision | is-empty) {
        $revision = (^git rev-parse HEAD | complete | get stdout)
    }

    $revision | str trim
}

def get-registry-path []: string -> path {
    let registry = $in
    $env.NUPM_REGISTRIES | get -i $registry | default ($registry | path expand)
}

def open-registry-file []: path -> record {
    let reg_path = $in

    let reg_content = try { open $reg_path }

    if ($reg_content | is-not-empty) and ($reg_content | describe -d | get type) != 'record' {
        throw-error ($"Unexpected content of registry ($reg_path)."
            + " Needs a record.")
    }

    $reg_content | default {}
}

def update-registry [pkg_entry: record, registry: string, type: string]: record -> record {
    let reg_content = $in

    let pkgs_local = $reg_content | get -i local | default []
    let pkgs_git = $reg_content | get -i git | default []
    let pkgs_all = $pkgs_local | append $pkgs_git

    if ($pkg_entry.name in $pkgs_all.name
        and $pkg_entry.version in $pkgs_all.version) {
        throw-error ($"Package ($pkg_entry.name) version ($pkg_entry.version)"
            + $" is already present in registry ($registry)")
    }

    let pkgs_out = match $type {
        "git" => $pkgs_git,
        "local" => $pkgs_local,
        _ => { throw-error $"Internal error: wrong registry type ($type)" }
    }

    $reg_content | upsert $type ($pkgs_out
        | append $pkg_entry
        | sort-by name
        | sort-by-version)
}
