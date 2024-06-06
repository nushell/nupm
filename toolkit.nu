export def --env set-nupm-env [--clear] {
    if ($env.PWD | path basename) != 'nupm' {
        print 'Run from nupm repo root'
        return
    }

    if $clear {
        rm -rf _nupm_dev
    }

    $env.NUPM_HOME =  ($env.PWD | path join _nupm_dev)
    $env.NUPM_CACHE = ($env.PWD | path join _nupm_dev cache)
    $env.NUPM_TEMP =  ($env.PWD | path join _nupm_dev tmp)
    $env.NUPM_REGISTRIES = { nupm_dev: ($env.PWD | path join registry registry.nuon) }

    if $nu.os-info.family == 'windows' and 'Path' in $env {
        $env.Path = ($env.Path | prepend ($env.PWD | path join _nupm_dev scripts))
    } else if 'PATH' in $env {
        $env.PATH = ($env.PATH | prepend ($env.PWD | path join _nupm_dev scripts))
    }
    $env.NU_LIB_DIRS = ($env.NU_LIB_DIRS | prepend ($env.PWD | path join _nupm_dev modules))

    print-nupm-env
}

export def print-nupm-env [] {
    print $'NUPM_HOME:  ($env.NUPM_HOME?)'
    print $'NUPM_CACHE: ($env.NUPM_CACHE?)'
    print $'NUPM_TEMP:  ($env.NUPM_TEMP?)'
    print $"PATH: ($env.PATH? | default $env.Path? | default [])"
    print $'NU_LIB_DIRS: ($env.NU_LIB_DIRS?)'
    print $'NUPM_REGISTRIES: ($env.NUPM_REGISTRIES?)'
}

# turn on pretty diffs for NUON data files
export def set-nuon-diff [] {
    git config diff.nuon.textconv (pwd | path join scripts print-nuon.nu)
}
