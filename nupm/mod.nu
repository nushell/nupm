use utils/dirs.nu [ 
    DEFAULT_NUPM_HOME DEFAULT_NUPM_TEMP DEFAULT_NUPM_CACHE  nupm-home-prompt
]

export module install.nu
export module test.nu

export-env {
    # Ensure that $env.NUPM_HOME is always set when running nupm. Any missing
    # $env.NUPM_HOME during nupm execution is a bug.
    $env.NUPM_HOME = ($env.NUPM_HOME? | default $DEFAULT_NUPM_HOME)

    # Ensure temporary path is set.
    $env.NUPM_TEMP = ($env.NUPM_TEMP? | default $DEFAULT_NUPM_TEMP)

        # Ensure install cache is set
    $env.NUPM_CACHE = ($env.NUPM_CACHE? | default $DEFAULT_NUPM_CACHE)

    # TODO: Maybe this is not the best way to store registries, but should be 
    #       good enough for now.
    # TODO: Remove local and kubouch which are just for testing
    # TODO: Move setting this to config file
    # TODO: Add `nupm registry` for showing info about registries
    # TODO: Add `nupm registry add/remove` to add/remove registry from config
    #       file (requires nuon formatting).
    $env.NUPM_REGISTRIES = {
        # nupm: ($env.NUPM_HOME | path join registry.nuon)
        kubouch:'https://git.sr.ht/~kubouch/nupkgs/blob/main/registry.nuon'
        local_test: ($env.FILE_PWD | path join tests packages registry.nuon)
        # remote_test: 'https://raw.githubusercontent.com/nushell/nupm/main/tests/packages/registry.nuon'
    }
}

# Nushell Package Manager
export def main []: nothing -> nothing {
    nupm-home-prompt --no-confirm=false

    print 'enjoy nupm!'
}
