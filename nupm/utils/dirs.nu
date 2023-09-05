# Directories and related utilities used in nupm

# Decault installation path for nupm packages
export const DEFAULT_NUPM_HOME = ($nu.default-config-dir | path join "nupm")

# Prompt to create $env.NUPM_HOME if it does not exist and some sanity checks.
export def nupm-home-prompt [] {
    if 'NUPM_HOME' not-in $env {
        error make {
            msg: "Internal error: NUPM_HOME environment variable is not set"
        }
    }

    if ($env.NUPM_HOME | path exists) {
        if ($env.NUPM_HOME | path type) != 'dir' {
            error make {
                msg: ($"Root directory ($env.NUPM_HOME) exists, but is not a"
                    + "directory. Make sure $env.NUPM_HOME points at a valid"
                    + "directory and try again.")
            }
        }

        return
    }

    mut answer = ''

    while ($answer | str downcase) not-in [ y n ] {
        $answer = (input (
            $'Root directory "($env.NUPM_HOME)" does not exist.'
            + ' Do you want to create it? [y/n] '))
    }

    if ($answer | str downcase) != 'y' {
        return
    }

    mkdir $env.NUPM_HOME
}
