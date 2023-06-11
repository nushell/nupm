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
    --path: path = ""  # the path to the package (used with `--generate-metadata`)
] {
    if $generate_metadata {
        let PACKAGE_FILE = "package.nuon"
        let METADATA_FILE = "package.files.nuon"

        log info "generating package file metadata file"

        log debug "checking arguments to generate metadata"
        if $host == null {
            throw-error $"missing_argument(ansi reset): --host is required with --generate-metadata"
        }

        log debug "building the base download URL"
        let base_download_url = match ($host | str downcase) {
            "github.com" | "github" | "gh" => {
                scheme: "https"
                host: "raw.githubusercontent.com"
                path: /OWNER/REPO/REVISION  # FIXME: use the true repo and revision
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
                ($it.name != $PACKAGE_FILE) and ($it.name != $METADATA_FILE)
            }
        )

        log debug "building metadata for package files:"
        $package_files | each {|file|
            log debug $file.name
            {
                checksum: ($file.name | open --raw | hash sha256)
                name: ($file.name | str replace $path "" | str trim --left --char "/")
                raw-url: ($base_download_url | update path { path join $file.name } | url join)
                supported-os: ($nu.os-info | reject kernel_version)
            }
        }
        | save --force $METADATA_FILE

        log info $"package file metadata saved in `($METADATA_FILE)`"
        log warning $"do not forget to commit the `($METADATA_FILE)` metadata file!"

        return
    }

    throw-error "publishing packages is not supported"
}
