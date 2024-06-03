# Directories and related utilities used in nupm

# Default installation path for nupm packages
export const DEFAULT_NUPM_HOME = ($nu.default-config-dir | path join "nupm")

# Default path for installation cache
export const DEFAULT_NUPM_CACHE = ($nu.default-config-dir
    | path join nupm cache)

# Default temporary path for various nupm purposes
export const DEFAULT_NUPM_TEMP = ($nu.temp-path | path join "nupm")

# Default registry
export const DEFAULT_NUPM_REGISTRIES = {
    nupm_test: 'https://raw.githubusercontent.com/nushell/nupm/main/registry/registry.nuon'
}

# Prompt to create $env.NUPM_HOME if it does not exist and some sanity checks.
#
# returns true if the root directory exists or has been created, false otherwise
export def nupm-home-prompt [--no-confirm]: nothing -> bool {
    if 'NUPM_HOME' not-in $env {
        error make --unspanned {
            msg: "Internal error: NUPM_HOME environment variable is not set"
        }
    }

    if ($env.NUPM_HOME | path exists) {
        if ($env.NUPM_HOME | path type) != 'dir' {
            error make --unspanned {
                msg: ($"Root directory ($env.NUPM_HOME) exists, but is not a"
                    + " directory. Make sure $env.NUPM_HOME points at a valid"
                    + " directory and try again.")
            }
        }

        return true
    }

    if $no_confirm {
        mkdir $env.NUPM_HOME
        return true
    }

    mut answer = ''

    while ($answer | str downcase) not-in [ y n ] {
        $answer = (input (
            $'Root directory "($env.NUPM_HOME)" does not exist.'
            + ' Do you want to create it? [y/n] '))
    }

    if ($answer | str downcase) != 'y' {
        return false
    }

    mkdir $env.NUPM_HOME

    true
}

export def script-dir [--ensure]: nothing -> path {
    let d = $env.NUPM_HOME | path join scripts

    if $ensure {
        mkdir $d
    }

    $d
}

export def module-dir [--ensure]: nothing -> path {
    let d = $env.NUPM_HOME | path join modules

    if $ensure {
        mkdir $d
    }

    $d
}

export def cache-dir [--ensure]: nothing -> path {
    let d = $env.NUPM_CACHE

    if $ensure {
        mkdir $d
    }

    $d
}

export def tmp-dir [subdir: string, --ensure]: nothing -> path {
    let d = $env.NUPM_TEMP
        | path join $subdir
        | path join (random chars -l 8)

    if $ensure {
        mkdir $d
    }

    $d
}

# Try to find the package root directory by looking for nupm.nuon in parent
# directories.
export def find-root [dir: path]: [ nothing -> path, nothing -> nothing] {
    let root_candidate = 1..($dir | path split | length)
        | reduce -f $dir {|_, acc|
            if ($acc | path join nupm.nuon | path exists) {
                $acc
            } else {
                $acc | path dirname
            }
        }

    # We need to do the last check in case the reduce loop ran to the end
    # without finding nupm.nuon
    if ($root_candidate | path join nupm.nuon | path type) == 'file' {
        $root_candidate
    } else {
        null
    }
}
