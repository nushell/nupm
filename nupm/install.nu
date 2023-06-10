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

# install a Nuhshell package
#
# > **Warning**  
# > - only supports GitHub packages
# > - a package needs to have a `package.nuon` file at its root with some keys
#
# # Examples
#     install a repo package
#     > nupm install https://github.com/amtoine/nu-git-manager
#
#     install a subpath package
#     > nupm install https://github.com/amtoine/zellij-layouts --path nu-zellij
export def main [
    url: string  # the URL to the root of the repo holding the package
    --path: string  # if the package is not the repo itself, gives the path to it
] {
}
