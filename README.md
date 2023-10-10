# nupm - Nushell package manager

:warning: **This project is in an experimentation stage and not intended for serious use!** :warning:

## :recycle: installation
> **Important**
> `nupm` might use the latest Nushell language features that have not been released in the latest version yet.
> If that is the case, consider building Nushell from the `main` branch, or installing the [nightly build](https://github.com/nushell/nightly).

`nupm` is a module. Download the repository and treat the [`nupm`](https://github.com/nushell/nupm/tree/main/nupm`) directory as a module. For example:
* `use nupm/`
* `overlay use nupm/ --prefix`
Both of the above commands will make `nupm` and all its subcommands available in your current scope. `overlay use` will allow you to `overlay hide` the `nupm` overlay when you don't need it.

> **Note**
> `nupm` is able to install itself: from inside the root of your local copy of `nupm`, run
> ```nushell
> use nupm/
> nupm install --force --path .
> ```

## :gear: configuration
One can change the location of the Nupm directory with `$env.NUPM_HOME`, e.g.
```nushell
# env.nu

$env.NUPM_HOME = ($env.XDG_DATA_HOME | path join "nupm")
```

Because Nupm will install modules and scripts in `{{nupm-home}}/modules/` and `{{nupm-home}}/scripts/` respectively, it iis a good idea to add these paths to `$env.NU_LIB_DIRS` and `$env.PATH` respectively, e.g. if you have `$env.NUPM_HOME` defined:
```nushell
# env.nu

$env.NU_LIB_DIRS = [
    ...
    ($env.NUPM_HOME | path join "modules")
]

$env.PATH = (
    $env.PATH
        | split row (char esep)
        | ....
        | prepend ($env.NUPM_HOME | path join "scripts")
        | uniq
)
```

## :memo: design of `nupm`
please have a look at [the design document](docs/design/README.md)
