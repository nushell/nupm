export def --env set-nupm-env [--clear] {
    if ($env.PWD | path basename) != 'nupm' {
        print 'Run from nupm repo root'
        return
    }

    if $clear {
        rm -rf _nupm_dev
    }

    $env.nupm.home =  ($env.PWD | path join _nupm_dev)
    $env.nupm.cache = ($env.PWD | path join _nupm_dev cache)
    $env.nupm.temp =  ($env.PWD | path join _nupm_dev tmp)
    $env.nupm.registries = { nupm_dev: ($env.PWD | path join registry registry.nuon) }

    if $nu.os-info.family == 'windows' and 'Path' in $env {
        $env.Path = ($env.Path | prepend ($env.PWD | path join _nupm_dev scripts))
    } else if 'PATH' in $env {
        $env.PATH = ($env.PATH | prepend ($env.PWD | path join _nupm_dev scripts))
    }
    $env.NU_LIB_DIRS = ($env.NU_LIB_DIRS | prepend ($env.PWD | path join _nupm_dev modules))

    print-nupm-env
}

export def print-nupm-env [] {
    print $'nupm.home:  ($env.nupm.home?)'
    print $'nupm.cache: ($env.nupm.cache?)'
    print $'nupm.temp:  ($env.nupm.temp?)'
    print $"PATH: ($env.PATH? | default $env.Path? | default [])"
    print $'NU_LIB_DIRS: ($env.NU_LIB_DIRS?)'
    print $'nupm.registires: ($env.nupm.registries?)'
}

# turn on pretty diffs for NUON data files
export def set-nuon-diff [] {
    git config diff.nuon.textconv (pwd | path join scripts print-nuon.nu)
}
