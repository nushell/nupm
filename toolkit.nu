export def --env set-nupm-env [] {
    $env.NUPM_HOME =  ('./_nupm_dev' | path expand)
    $env.NUPM_CACHE = ('./_nupm_dev/cache' | path expand)
    $env.NUPM_TEMP =  ('./_nupm_dev/tmp' | path expand)

    $env.PATH ++= [('./_nupm_dev/scripts' | path expand)]
    $env.NU_LIB_DIRS ++= [('./_nupm_dev/modules' | path expand)]

    print-nupm-env
}

export def print-nupm-env [] {
    print $'NUPM_HOME:  ($env.NUPM_HOME?)'
    print $'NUPM_CACHE: ($env.NUPM_CACHE?)'
    print $'NUPM_TEMP:  ($env.NUPM_TEMP?)'
    print $'PATH: ($env.PATH?)'
    print $'NU_LIB_DIRS: ($env.NU_LIB_DIRS?)'
}
