

# nupm - Nushell package manager

⚠️ **This project is in an experimentation stage and not intended for serious use!**  ⚠️

This is a prototype of Nushell's package manager.

## 💾 Installation

> 💡 `nupm` might use the latest Nushell language features that have not been released in the latest version yet. If that is the case, consider building Nushell from the `main` branch, or installing the [nightly build](https://github.com/nushell/nightly).

`nupm` is a module. Download the repository and treat the [`nupm`](https://github.com/nushell/nupm/tree/main/nupm`) directory as a module. For example:
* `use nupm/`
* `overlay use nupm/ --prefix`
Both of the above commands will make `nupm` and all its subcommands available in your current scope. `overlay use` will allow you to `overlay hide` the `nupm` overlay when you don't need it.

## :memo: design of `nupm`
please have a look at [the design document](docs/design/README.md)
