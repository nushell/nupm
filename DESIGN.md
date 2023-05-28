# Design of nupm :warning: Work In Progress :warning: 

This file collects design ideas and directions. The intention is iterate on this document by PRs with discussion.

> **Note**  
> in the following, until we settle down on precise names, we use the following placeholders:
> - `METADATA_FILE`: the file containing the metadata of a package, e.g. `project.nuon`, `metadata.json` or `package.nuon`
> - `NUPM_HOME`: the location of all the `nupm` files, overlays, scripts, libraries, ..., e.g. `~/.nupm/`, `$env.XDG_DATA_HOME/nupm/` or `~/.local/share/nupm/`

## Project Structure

A `nupm` project is defined by `METADATA_FILE` (name inspired by Julia's `Project.toml` or Rust's `Cargo.toml`). This is where you define name of the project, version, dependencies, etc., and the type of the project. There are two types of Nushell projects (named `spam` for the example):
1. Simple script
```
spam
├── METADATA_FILE
└── test.nu
```
* meant as a runnable script, equivalent of Rust's binary project (could use the `.nush` extension if we agree to support it)
* installed under `NUPM_CURRENT_OVERLAY/bin/`
2. Module
```
spam
├── METADATA_FILE
└── spam
    └── mod.nu
```
* meant as a library to be `use`d or `overlay use`d, equivalent of Rust's library project
* installed under `NUPM_CURRENT_OVERLAY/lib/`

You can also install non-Nushell packages as well using a "custom" project type where you specify a `build.nu` installation script (e.g., you can install Nushell itself with it). Plugins should also be supported, preferably not requiring fully custom `build.nu`.

## Separate virtual environments

Inspiration: Python, [conda](https://docs.conda.io/en/latest), `cargo`

There are two different concepts in how to handle virtual environments:
* Having global virtual environments, Python-style. We have a working prototype at https://github.com/kubouch/nuun using overlays.
  * Installing a package will install it to the environment
  * Possible to switch between them, they are completely isolated from each other
* Per-project virtual environment, cargo-style
  * A project has its own universe (like Rust projects, for example)

The global environments are installed as overlays in a location added by user to `NU_LIB_DIRS` (`NUPM_HOME/overlays`). For example project `spam` would create `NUPM_HOME/overlays/spam.nu`). The features of the file:
* automatically generated, managed by `nupm`
* `overlay use spam.nu` brings in all the definitions in the virtual environment, no other action needed
* `overlay hide` will restore the environment to the previous one

Per-project environments use _identical_ framework with one difference: Instead of installing the overlay file to a global location, it is somewhere within the project. This also makes it opt-in. While `cargo` forces you to have all dependencies installed

## Installation, bootstraping

Requires these actions from the user (this should be kept as minimal as possible):
* Add `NUPM_HOME/bin` to PATH (install location for binary projects)
* Add `NUPM_HOME/lib` to NU_LIB_DIRS
* Add `NUPM_HOME/overlays` to NU_LIB_DIRS
* Make the `nupm` command available somehow (e.g., `use` inside `config.nu`)

WIP: I have another idea in mind, need to think about it. The disadvantage of this is that the default install location is not an overlay. We could make `nupm` itself an overlay that adds itself as a command.

There are several approaches:
* bootstrap using shell script sourced from web (like rustup)
* embedded inside Nushell's binary
  * The advantage of this is that it does not require user's config. The PATH and NU_LIB_DIRS could be pre-configured in Nushel
* (in the future maybe) as a compiled binary (using something like https://github.com/jntrnr/nu_app)
  * This would allow us to reverse the installation steps: Instead of Nushell installing nupm, we could let user only install nupm which would in turn install Nushell

## Dependency handling

In compiled programming languages, there are two kinds of dependencies: static and dynamic. Static are included statically and compiled when compiling the project, dynamic are pre-compiled libraries linked to the project. Note that Nushell is [similar to compiled languages](https://www.nushell.sh/book/thinking_in_nu.html#think-of-nushell-as-a-compiled-language) rather than typical dynamic languages like Python, so these concepts are relevan for Nushell.

Static dependencies:
* Advantages: reproducible, does not rely on system files (no more missing random.so.2), higher performance (allows joint optimization of dependencies and project itself)
* Disadvatage: increased compile time, binary size, can easily end up with multiple versions of the same library (hello Nushell dependencies)

Dynamic dependencies are the opposite basically. Note that Nushell currently supports only static dependencies, but we might be able to add the "linking" feature at some point.

We might want `nupm`support both types of dependencies.

## Package repository 

Packages need to be stored somewhere. There should be one central "official" location (see https://github.com/NixOS/nixpkgs for inspiration).

Additionally, user should be able to add 3rd party repositories as well as install local and other packages (e.g., from the web, just pointing at URL), as long as it has `METADATA_FILE` telling `nupm` what to do.

## API / CLI Interface

Nushell's module design conflates CLI interface with API -- they are the same.

WIP

## Other

* activations
* doc generation
* test running
* benchmark running
* configuration (do not add until we really need something to be configurable, keep it minimal, case study of a project with minimal configuration: https://github.com/psf/black)
