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

def query-github-api [
    url_tokens: record<scheme: string, host: string, path: string>
    end_point?: list<string> = []
    params?: record
] {
    try {
        http get (
            $url_tokens
            | update host "api.github.com"
            | update path {
                path split
                | skip 1
                | prepend "repos"
                | append $end_point
                | str join "/"
            }
            | if $params != null { insert params $params } else {}
            | url join
        )
    } catch {|e|
        if ($e.msg == "Network failure") and ($e.debug | str contains "Access forbidden (403)") {
            throw-error "github_api_limit_reached: could not reach GitHub (you might have reached the API limit, please try again later)"
        }
        return $e.raw
    }
}

# install a Nushell package
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
    log debug $"parsing URL ($url)"
    let url_tokens = (try {
        $url | url parse | select scheme host path
    } catch {
        throw-error "invalid_url" "not a valid URL" --span (metadata $url | get span)
    })

    if $url_tokens.host != "github.com" {
        throw-error "invalid_host" $"($url_tokens.host) is not a supported host" --span (metadata $url | get span)
    }

    log info "checking integrity of the remote package"
    let default_branch = (query-github-api $url_tokens | get default_branch)

    let package_url = (
        $url_tokens
        | update host "raw.githubusercontent.com"
        | update path {
            append [$default_branch $path "package.nuon"] | str join "/"
        }
        | url join
    )

    log debug $"pulling down package file from ($package_url)"
    let package = (try {
        http get $package_url
    } catch {
        let text = [
            "could not find package file"
            ""
            $"      (ansi cyan)help:(ansi reset) the ('package.nuon' | nu-highlight) file or the repository does not exist"
        ]
        throw-error "package_file_not_found" ($text | str join "\n") --span (metadata $url | get span)
    })

    log debug "checking package file for missing required keys"
    let missing_keys = (
        [
            [key required];

            [$. true]
            [$.name true]
            [$.version true]
            [$.description true]
            [$.license true]
        ] | each {|key|
            if ($package | get --ignore-errors $key.key) == null {
                $key
            }
        }
        | where required
        | get key
    )

    if not ($missing_keys | is-empty) {
        throw-error "invalid_package_file" $"package file is missing the following required keys: ($missing_keys | str join ', ')" --span (metadata $url | get span)
    }

    log info $"installing package ($package.name)"
    log debug "pulling down the list of files"
    let tree = (
        query-github-api $url_tokens ["git" "trees" $default_branch] {recursive: 1} | get tree
    )

    # TODO: pull down the files into the local `nupm` store
}
