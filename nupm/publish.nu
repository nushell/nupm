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

export def main [
    --generate-metadata: bool
    --host: string
    --path: path = ""
] {
    if $generate_metadata {
        if $host == null {
            throw-error $"missing_argument(ansi reset): --host is required with --generate-metadata"
        }

        let base_download_url = match ($host | str downcase) {
            "github.com" | "github" | "gh" => {
                scheme: "https"
                host: "raw.githubusercontent.com"
                path: /OWNER/REPO/REVISION
            },
            _ => (
                throw-error
                    "host_not_supported"
                    "not a supported host"
                    --span (metadata $host | get span)
            ),
        }

        ls ($path | path join "**" "*")
        | where type == "file"
        | where {|it| ($it.name != "package.nuon") and ($it.name != "package.files.nuon")}
        | each {|file| {
            checksum: ($file.name | open --raw | hash sha256)
            name: $file.name
            raw-url: ($base_download_url | update path { path join $file.name } | url join)
            supported-os: ($nu.os-info | reject kernel_version)
        }}
        | save --force package.files.nuon

        return
    }

    throw-error "publishing packages is not supported"
}
