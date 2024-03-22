export def --env set-nupm-env [] {
    if ($env.PWD | path basename) != 'nupm' {
        print 'Run from nupm repo root'
        return
    }

    $env.NUPM_HOME =  ($env.PWD | path join '_nupm_dev')
    $env.NUPM_CACHE = ($env.PWD | path join '_nupm_dev/cache')
    $env.NUPM_TEMP =  ($env.PWD | path join '_nupm_dev/tmp')

    $env.PATH = ($env.PATH | prepend ($env.PWD | path join '_nupm_dev/scripts'))
    $env.NU_LIB_DIRS = ($env.NU_LIB_DIRS | prepend ($env.PWD | path join '_nupm_dev/modules'))

    print-nupm-env
}

export def print-nupm-env [] {
    print $'NUPM_HOME:  ($env.NUPM_HOME?)'
    print $'NUPM_CACHE: ($env.NUPM_CACHE?)'
    print $'NUPM_TEMP:  ($env.NUPM_TEMP?)'
    print $'PATH: ($env.PATH?)'
    print $'NU_LIB_DIRS: ($env.NU_LIB_DIRS?)'
}
