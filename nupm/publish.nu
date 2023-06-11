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
    --path: path = .
] {
    let path = ($path | path expand)

    if $generate_metadata {
        if $host == null {
            throw-error $"missing_argument(ansi reset): --host is required with --generate-metadata"
        }

        log debug $"host: ($host)"
        log debug $"path: ($path)"
        return
    }

    throw-error "publishing packages is not supported"
}
