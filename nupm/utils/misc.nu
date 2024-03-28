# Misc unsorted helpers

# Make sure input has requested columns and no extra columns
export def check-cols [
    what: string,
    required_cols: list<string>
    --extra-ok
    --missing-ok
]: [ table -> table, record -> record ]  {
    let inp = $in

    if ($inp | is-empty) {
        return $inp
    }

    let cols = $inp | columns
    if not $missing_ok {
        let missing_cols = $required_cols | where {|req_col| $req_col not-in $cols }

        if not ($missing_cols | is-empty) {
            throw-error ($"Missing the following required columns in ($what):"
                + $" ($missing_cols | str join ', ')")
        }
    }

    if not $extra_ok {
        let extra_cols = $cols | where {|col| $col not-in $required_cols }

        if not ($extra_cols | is-empty) {
            throw-error ($"Got the following extra columns in ($what):"
                + $" ($extra_cols | str join ', ')")
        }
    }

    $inp
}

# Compute a hash of a string
export def hash-fn []: string -> string {
    let hash = $in | hash md5
    [ 'md5' $hash ] | str join '-'
}

# Compute a hash of file contents
export def hash-file []: path -> string {
    open --raw | hash-fn
}

# Extensions to the `url ...` commands
export module url {

    # Get the stem of a URL path
    export def stem []: string -> string {
        url parse | get path | path parse | get stem
    }

    # Update the last element of a URL path with a new name
    export def update-name [new_name: string]: string -> string {
        url parse
        | update path {|url|
            # skip the first '/' and replace last elemnt with the new name
            let parts = $url.path | path split | skip 1 | drop 1
            $parts | append $new_name | str join '/'
        }
        | url join
    }
}
