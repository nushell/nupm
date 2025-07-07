# nupm - Nushell package manager

## Table of content
- [*installation*](#recycle-installation-toc)
- [*configuration*](#gear-configuration-toc)
- [*usage*](#rocket-usage-toc)
  - [*install a package*](#install-a-package-toc)
  - [*update a package*](#update-a-package-toc)
  - [*define a package*](#define-a-package-toc)
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
> `nupm` is able to install itself: from outside the root of your local copy of `nupm`, run
> ```nushell
> use nupm/nupm
> nupm install nupm --force --path
> ```

## :gear: configuration [[toc](#table-of-content)]
One can change the location of the Nupm directory with `$env.NUPM_HOME`, e.g.
```nushell
# env.nu

$env.NUPM_HOME = ($env.XDG_DATA_HOME | path join "nupm")
```

Because Nupm will install modules and scripts in `{{nupm-home}}/modules/` and `{{nupm-home}}/scripts/` respectively, it is a good idea to add these paths to `$env.NU_LIB_DIRS` and `$env.PATH` respectively, e.g. if you have `$env.NUPM_HOME` defined:
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

## :rocket: usage [[toc](#table-of-content)]

Nupm can install different types of packages, such as modules and scripts. It also provides a mechanism for a custom installation using a `build.nu` file.

As an illustrative example, the following demonstrates use of a fictional `foo` module-based package.

### install a package [[toc](#table-of-content)]

```nushell
git clone https://github.com/nushell/foo.git
nupm install foo --path
```

### update a package [[toc](#table-of-content)]

Assuming the repository is already cloned, you can update the module package with the following:

```nushell
do { cd foo; git pull }
nupm install foo --force --path
```
This usage will likely change once a dedicated `nupm update` command is added.

### define a package [[toc](#table-of-content)]

In order to use a module-based package with Nupm, a directory should be structured similar to the following `foo` module:

- `foo/`
    - `mod.nu`
    - (other scripts and modules)
- `nupm.nuon`

The `nupm.nuon` file is a metadata file that describes the package. It should contain the following fields:

```nushell
{
    name: "foo"
    description: "A package that demonstrates use of Nupm"
    type: "module"
    license: "MIT"
}
```

Nupm also supports other types of packages. See [Project Structure](https://github.com/nushell/nupm/blob/main/docs/design/README.md#project-structure-toc) for more details.

## :test_tube: running a test suite [[toc](#table-of-content)]
as it is done in Nupm, one can define tests in a project and run them with the `nupm test` command:
- create a Nushell package with a `nupm.nuon` file, let's call this example package `package`
- create a `tests/` directory next to the `package/` directory
- `tests/` is a regular Nushell directory module, put a `mod.nu` there and any structure you want
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
