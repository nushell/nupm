use utils/dirs.nu [ DEFAULT_NUPM_HOME nupm-home-prompt ]

export-env {
    # Ensure that $env.NUPM_HOME is always set when running nupm. Any missing
    # $env.NUPM_HOME during nupm execution is a bug.
    if 'NUPM_HOME' not-in $env {
        $env.'NUPM_HOME' = $DEFAULT_NUPM_HOME
    }
}

# Nushell Package Manager
export def main [] {
    nupm-home-prompt

    print 'enjoy nupm!'
}
