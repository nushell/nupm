export-env {
    $env.NUPM_HOME = ($env.FILE_PWD | path join _nupm_dev)
    $env.NUPM_CACHE = ($env.FILE_PWD | path join _nupm_dev cache)
    $env.NUPM_TEMP = ($env.FILE_PWD | path join _nupm_dev tmp)

    print $'NUPM_HOME:  ($env.NUPM_HOME)'
    print $'NUPM_CACHE: ($env.NUPM_CACHE)'
    print $'NUPM_TEMP:  ($env.NUPM_TEMP)'
}
