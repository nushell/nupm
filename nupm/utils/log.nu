# denotes an error msg that a section of code is yet to be implemented
export const UNIMPLEMENTED = "unimplemented"

export def throw-error [
    error: string
    text?: string
    --span: record<start: int, end: int>
] {
    let error = $"(ansi red_bold)($error)(ansi reset)"

    if $span == null {
        if $text == null {
            error make --unspanned { msg: $error }
        } else {
            error make --unspanned { msg: ($error + "\n" + $text) }
        }
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

export def assert [
    condition: bool
    error: string
    text?: string
    --span: record<start: int, end: int>
] {
    if not $condition {
        throw-error $error $text --span=$span
    }
}

# Append a formatted help line to mimic `error make` in core
export def append-help [help_msg: string]: string -> string {
  $in + $"\n  (ansi cyan)help:(ansi reset) " + $help_msg
}
