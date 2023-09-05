use utils/dirs.nu [ DEFAULT_NUPM_HOME nupm-home-prompt ]

export-env {
    if 'NUPM_HOME' not-in $env {
        $env.'NUPM_HOME' = $DEFAULT_NUPM_HOME
    }
}

export def main [] {
    nupm-home-prompt

    print 'enjoy nupm!'
}
