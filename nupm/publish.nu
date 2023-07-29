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

# publish a package
#
# > **Warning**  
# > this command is in a very early stage, it is only meant to generate the
# > metadata of all the files in the package with the `--generate-metadata`
# > option.
export def main [
    --generate-metadata: bool  # only generate the package metadata file
    --host: string  # where the package is hosted (used with `--generate-metadata`)
    --path: string = ""  # the path to the package (used with `--generate-metadata`)
    --repo: string  # the name of the repo holding the package (used with `--generate-metadata`)
    --revision: string  # the revision of the repo holding the package (used with `--generate-metadata`)
    --supported-os: list<record<name: string, arch: string, family>>  # the list of all supported OSes
] {
    if $generate_metadata {
        # TODO: add support for a `.nupmignore` file in the root of a package
        # to not add files into the package.

        let PACKAGE_FILE = "package.nuon"
        let METADATA_FILE = "package.files.nuon"

        log info "generating package metadata"

        log debug "checking arguments to generate metadata"
        for option in [
            [name value]; [host $host] [repo $repo] [revision $revision]
        ] {
            if $option.value == null {
                throw-error $"missing_argument(ansi reset): --($option.name) is required with --generate-metadata"
            }
        }

        log debug "building the base download URL"
        let base_download_url = match ($host | str downcase) {
            "github.com" | "github" | "gh" => {
                scheme: "https"
                host: "raw.githubusercontent.com"
                path: $"/($repo)/($revision)"
            },
            _ => (
                throw-error
                    "host_not_supported"
                    "not a supported host"
                    --span (metadata $host | get span)
            ),
        }

        log debug "listing all files in the package"
        let package_files = (
            ls ($path | path join "**" "*") | where type == "file"
        )
        log debug $"excluding `($PACKAGE_FILE)` and `($METADATA_FILE)`"
        let package_files = (
            $package_files | where {|it|
                let filename = ($it.name | path basename)
                ($filename != $PACKAGE_FILE) and ($filename != $METADATA_FILE)
            }
        )

        log debug "building metadata for package files:"
        $package_files | each {|file|
            log debug $"processing `($file.name)`"
            {
                checksum: ($file.name | open --raw | hash sha256)
                name: ($file.name | if $path != "." { str replace $path "" } else {} | str trim --left --char "/")
                raw-url: ($base_download_url | update path { path join $file.name } | url join)
                supported-os: ($supported_os | default [($nu.os-info | select name arch family)])
            }
        }
        | save --force $METADATA_FILE

        log info $"package file metadata saved in `($METADATA_FILE)`"
        log info $"(ansi yellow)do not forget to commit the `($METADATA_FILE)` metadata file!(ansi reset)"

        return
    }

    throw-error "publishing packages is not supported"
}
