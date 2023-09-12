use utils/dirs.nu [ DEFAULT_NUPM_HOME DEFAULT_NUPM_TEMP nupm-home-prompt ]

export-env {
    # Ensure that $env.NUPM_HOME is always set when running nupm. Any missing
    # $env.NUPM_HOME during nupm execution is a bug.
    $env.NUPM_HOME = ($env.NUPM_HOME? | default $DEFAULT_NUPM_HOME)

    # Ensure temporary path is set.
    $env.NUPM_TEMP = ($env.NUPM_TEMP? | default $DEFAULT_NUPM_TEMP)
}

# Nushell Package Manager
export def main [] {
    nupm-home-prompt

    print 'enjoy nupm!'
}
