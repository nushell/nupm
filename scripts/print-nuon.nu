#!/usr/bin/env nu

def main [file: path]: [ nothing -> string ] {
    if not ($file | path exists) {
        error make {
            msg: $"(ansi red_bold)file_not_found(ansi reset)",
            label: {
                text: "no such file",
                span: (metadata $file).span,
            },
            help: $"`($file)` does not exist",
        }
    }

    let content = open --raw $file

    let data = try {
        $content | from nuon
    } catch {
        error make {
            msg: $"(ansi red_bold)invalid_nuon(ansi reset)",
            label: {
                text: "could not parse NUON",
                span: (metadata $file).span,
            },
            help: $"`($file)` does not appear to be valid NUON",
        }
    }

    $data | to nuon -i 4
}
