# nupm - Nushell package manager

## Table of content
- [*installation*](#recycle-installation-toc)
- [*configuration*](#gear-configuration-toc)
- [*running a test suite*](#test_tube-running-a-test-suite-toc)
    - [*run the tests*](#run-the-tests-of-Nupm-toc)
- [*design*](#memo-design-of-nupm-toc)

:warning: **This project is in an experimentation stage and not intended for serious use!** :warning:

## :recycle: installation [[toc](#table-of-content)]
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

## :gear: configuration [[toc](#table-of-content)]
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

## :test_tube: running a test suite [[toc](#table-of-content)]
as it is done in Nupm, one can define tests in a project and run them with the `nupm test` command:
- create a Nushell package with a `package.nuon` file, let's call this example package `package`
- create a `tests/` directory next to the `package/` directory
- `tests/` is a regular Nushell directory package, put a `mod.nu` there and any structure you want
- import definitions from the package with something like
```nushell
use ../package/foo/bar.nu [baz, brr]
```
- all the commands defined in the `tests/` module and `export`ed will run as tests
- from the root of the repo, run `nupm test`

### run the tests of Nupm [[toc](#table-of-content)]
from the root of Nupm, run
```nushell
nupm test
```
you should see something like
```
Testing package /home/amtoine/documents/repos/github.com/amtoine/nupm
tests install-module ... SUCCESS
tests install-script ... SUCCESS
tests install-custom ... SUCCESS
Ran 3 tests. 3 succeeded, 0 failed.
```

## :memo: design of `nupm` [[toc](#table-of-content)]
please have a look at [the design document](docs/design/README.md)
