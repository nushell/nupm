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
            )
        }
    }

    if not $extra_ok {
        let extra_cols = $cols | where {|col| $col not-in $required_cols }

        if not ($extra_cols | is-empty) {
            throw-error ($"Got the following extra columns in ($what):"
                + $" ($extra_cols | str join ', ')")
            )
        }
    }

    $inp
}
