# Directories and related utilities used in nupm

# Prompt to create $env.nupm.home if it does not exist and some sanity checks.
#
# returns true if the root directory exists or has been created, false otherwise
export def nupm-home-prompt [--no-confirm]: nothing -> bool {
    if 'home' not-in $env.nupm {
        error make --unspanned {
            msg: "Internal error: nupm.home environment variable is not set"
        }
    }

    if ($env.nupm.home | path exists) {
        if ($env.nupm.home | path type) != 'dir' {
            error make --unspanned {
                msg: ($"Root directory ($env.nupm.home) exists, but is not a"
                    + " directory. Make sure $env.nupm.home points at a valid"
                    + " directory and try again.")
            }
        }

        return true
    }

    if $no_confirm {
        mkdir $env.nupm.home
        return true
    }

    mut answer = ''

    while ($answer | str downcase) not-in [ y n ] {
        $answer = (input (
            $'Root directory "($env.nupm.home)" does not exist.'
            + ' Do you want to create it? [y/n] '))
    }

    if ($answer | str downcase) not-in [ y Y ] {
        return false
    }

    mkdir $env.nupm.home

    true
}

export def script-dir [--ensure]: nothing -> path {
    let d = $env.nupm.home | path join scripts

    if $ensure {
        mkdir $d
    }

    $d
}

export def module-dir [--ensure]: nothing -> path {
    let d = $env.nupm.home | path join modules

    if $ensure {
        mkdir $d
    }

    $d
}

export def cache-dir [--ensure]: nothing -> path {
    let d = $env.nupm.cache

    if $ensure {
        mkdir $d
    }

    $d
}

export def tmp-dir [subdir: string, --ensure]: nothing -> path {
    let d = $env.nupm.temp
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
