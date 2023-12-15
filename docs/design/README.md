# Design of `nupm` :warning: Work In Progress :warning: 

This file collects design ideas and directions. The intention is iterate on this document by PRs with discussion.

> **Note**  
> in the following, until we settle down on precise names, we use the following placeholders:
> - `METADATA_FILE`: the file containing the metadata of a package,
> e.g. `project.nuon`, `metadata.json` or `nupm.nuon`
> (name inspired by Julia's `Project.toml` or Rust's `Cargo.toml`)
> - `NUPM_HOME`: the location of all the `nupm` files, overlays, scripts, libraries, ...,
> e.g. `~/.nupm/`, `$env.XDG_DATA_HOME/nupm/` or `~/.local/share/nupm/`

# Table of content
- [Project Structure](#project-structure-toc)
- [Separate virtual environments](#separate-virtual-environments-toc)
- [Installation, bootstraping](#installation-bootstraping-toc)
- [Dependency handling](#dependency-handling-toc)
- [Package repository](#package-repository-toc)
- [API / CLI Interface](#api--cli-interface-toc)
  - [Other CLI-related points](#other-cli-related-points-toc)
- [Other](#other-toc)

## Project Structure [[toc](#table-of-content)]

A `nupm` project is defined by `METADATA_FILE`.
This is where you define name of the project, version, dependencies, etc., and the type of the project.
> **Note**  
> see [`METADATA.md`](references/METADATA.md) for a more in-depth description of
> the `METADATA_FILE`

There are two types of Nushell projects (named `spam` for the example):
1. Simple script
```
spam
├── METADATA_FILE
└── test.nu
```
* meant as a runnable script, equivalent of Rust's binary project
* could use the `.nush` extension if we agree to support it
* installed under `NUPM_HOME/bin/`

2. Module
```
spam
├── METADATA_FILE
└── spam
    └── mod.nu
```
* meant as a library to be `use`d or `overlay use`d, equivalent of Rust's library project
* installed under `NUPM_HOME/modules/`

You can also install non-Nushell packages as well using a "custom" project type where you specify a `build.nu` installation script
(e.g., you can install Nushell itself with it).
Plugins should also be supported, preferably not requiring fully custom `build.nu`.
More "helper" types of projects could be made, e.g., installing from GitHub, etc. We could allow users to add new project types via "templates".

## Separate virtual environments [[toc](#table-of-content)]

> Inspiration: Python, [conda](https://docs.conda.io/en/latest), `cargo`

There are two different concepts how to handle virtual environments:
* Global virtual environments, Python-style. We have a working prototype at [`kubouch/nuun`] using overlays.
  * Installing a package will install it to the environment
  * Possible to switch between them, they are completely isolated from each other
* Per-project virtual environment, `cargo`-style
  * A project has its own universe (like Rust projects, for example)

Related to that is a lock file: It is intended to describe exactly the dependencies for a package so that it can be reproduced somewhere else.

The overlays could be used to achieve all three goals at the same time. When installing a dependency for a package
* `nupm` adds entry to a **lock file** (this should be the only file you need to 100% replicate the environment)
* A .nu file (module) is auto-generated from the lock file and contains export statements like `export module NUPM_HOME/cache/packages/spam-v16.4.0-124ptnpbf/spam`. Calling `overlay use` on the file will activate your virtual environment, now you have a per-project environment
* This file can be installed into a global location that's in your `NU_LIB_DIRS` (e.g., `NUPM_HOME/overlays`) -- now you have a global Python-like virtual environment
  * Each overlay under `NUPM_HOME/overlays` will mimic the main NUPM_HOME structure, e.g., for an overlay `spam` there will be `NUPM_HOME/overlays/spam/bin`, `NUPM_HOME/overlays/spam/modules` (`NUPM_HOME/overlays/spam/overlays`? It might not be the best idea to have it recursive)

Each package would basically have its own overlay. This overlay file (it's just a module) could be used to also handle dependencies. If your project depends on `foo` and `bar` which both depend on `spam` but different versions, they could both import the different verions privately in their own overlay files and in your project's overlay file would be just `export use path/to/foo` and `export use path/to/bar`. This should prevent name clashing of `spam`. The only problem that needs to be figured out is how to tell `foo` to be aware of its overlay.

## Installation, bootstraping [[toc](#table-of-content)]

Requires these actions from the user (this should be kept as minimal as possible):
* Add `NUPM_HOME/bin` to PATH (install location for binary projects)
* Add `NUPM_HOME/modules` to NU_LIB_DIRS
* Add `NUPM_HOME/overlays` to NU_LIB_DIRS
* Make the `nupm` command available somehow (e.g., `use` inside `config.nu`)

> :warning: **WIP**  
> The disadvantage of this is that the default install location is not an overlay. We could make `nupm` itself an overlay that adds itself as a command, so that you can activate/deactivate it. We might need a few attempts to get to the right solution.

There are several approaches:
* bootstrap using shell script sourced from web (like `rustup`)
* embedded inside Nushell's binary
  * The advantage of this is that it does not require user's config. The `PATH` and `NU_LIB_DIRS` could be pre-configured in Nushell
* (in the future maybe) as a compiled binary (using something like [`jntrnr/nu_app`])
  * This would allow us to reverse the installation steps: Instead of Nushell installing `nupm`, we could let user only install `nupm` which would in turn install Nushell

## Dependency handling [[toc](#table-of-content)]

In compiled programming languages, there are two kinds of dependencies: static and dynamic. Static are included statically and compiled when compiling the project,
dynamic are pre-compiled libraries linked to the project.

> **Note**  
> Nushell is [similar to compiled languages][Nushell compiled] rather than typical dynamic languages like Python, so these concepts are relevant for Nushell.

Static dependencies:
* :thumbsup:: reproducible, does not rely on system files at runtime (no more missing `random.so.2`), higher performance (allows joint optimization of dependencies and project itself)
* :thumbsdown:: increased compile time, binary size, can easily end up with multiple versions of the same library (hello Nushell dependencies)

Dynamic dependencies are the opposite basically.

Nushell currently supports only static dependencies, but we might be able to add the "linking" feature at some point which could unlock new interesting patterns regarding package management, like testing.

## Package repository [[toc](#table-of-content)]

Packages need to be stored somewhere. There should be one central "official" location (see https://github.com/NixOS/nixpkgs for inspiration). GitHub repository seems like a good starting point.

Additionally, user should be able to add 3rd party repositories as well as install local and other packages (e.g., from the web, just pointing at URL),
as long as it has `METADATA_FILE` telling `nupm` what to do.

## API / CLI Interface [[toc](#table-of-content)]

Nushell's module design conflates CLI interface with API -- they are the same. Not all of the below are of the same priority.

> **Note**  
> commands like `list`, `install`, `search`, `uninstall`, `update`, ..., i.e. should
> - print short descriptions by default
> - print long descriptions with `--long-description (-l)`

- `nupm new [--script] [--module]`
    - create a new local package with template files ([`kubouch/nuun`])
- `nupm list`
    - list currently installed packages and if they're out of date
- `nupm install`
    - install package into the currently active overlay (can override which overlay to install to)
    - `--reinstall (-r)`: reinstall package if installed
    - `--update (-u)`: update local packages if outdated
    - Both `-u` & `-r` flags might be specified, but updating has higher priority than reinstalling
    - `--yes (-y)`: do not ask for user confirmation, e.g. to use `nupm install` in scripts
- `nupm add`
    - add a dependency to the current project
    - it is different from `nupm install`: this one adds the dependency to the `METADATA_FILE`, `nupm install` does not
- `nupm uninstall`
    - uninstall a package from a currently active overlay (can override which overlay to install to)
    - `--yes (-y)`: do not ask for user confirmation, e.g. to use `nupm uninstall` in scripts
- `nupm update`
    - update all packages in a currently active overlay (can specify package and/or overlay name)
    - can be used to self-update: `nupm update nupm`, `nupm update --self` or `nupm update --all` (the last one would update every package installed by `nupm`, including `nupm` itself)
    - `--yes (-y)`: do not ask for user confirmation, e.g. to use `nupm update` in scripts
- `nupm search`
    - search package repository (only supported ones by default)
    - `--unsupported (-u)`: would also list packages that are not supported in the user's system, e.g. due to OS incompatibilities

- `nupm check`
    - parse the project to search for errors but do not run it
- `nupm test`
    - run unit and integration tests of local package
- `nupm bench`
    - run benchmarks
- `nupm doc`
    - generate documentation
- `nupm publish`
    - publish package to a repository
    - **NOT SUPPORTED FOR NOW**: the repository will be a *GitHub* repo with packages submitted by PRs to start with

The following are for Python-style global overlays, we might need to re-think this for local package overlays: 
- `nupm overlay new`
    - create a new global overlay (Python's virtual environment style)
    - `--local` flag could generate an overlay locally from the currently opened project
- `nupm overlay remove`
    - deletes the overlay
- `nupm overlay list`
    - list all overlays
    - `nupm overlay list <overlay-name>` lists all packages installed within the overlay
- `nupm overlay export`
    - dump all the installed package names, versions, etc. to a file
- `nupm overlay import`
    - create overlay from exported file

### Other CLI-related notes [[toc](#table-of-content)]

* We could later think about being able to extend `nupm`, like `cargo` has plugins.
* Mutable actions (like install) have by default Y/n prompt, but can be overriden with `--yes`
* By default, new projects are cross-platform:
    * Windows
    * MacOS
    * Linux
    * Android (if someone is willing to maintain it, we're not testing Nushell on Android, at least for now)

## Other [[toc](#table-of-content)]

* activations (not bringing all package's content but only parts of it)
* doc generation
* test running
* benchmark running
* configuration (do not add until we really need something to be configurable, keep it minimal, case study of a project with minimal configuration: [`psf/black`])

[Nushell compiled]: https://www.nushell.sh/book/thinking_in_nu.html#think-of-nushell-as-a-compiled-language

[`kubouch/nuun`]: https://github.com/kubouch/nuun
[`jntrnr/nu_app`]: https://github.com/jntrnr/nu_app
[`psf/black`]: https://github.com/psf/black
