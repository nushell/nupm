# Registry

Registry is a collection of .nuon files that tell nupm where to look for packages when doing tasks like `nupm search` or `nupm install`.

Two types of files compose a registry:
* The "main" registry file containing the list of "registry package files"
* Registry package files containing the details of each package.

These files **should not** be edited manually. They are intended to be auto-generated and updated with `nupm publish` only. They also shouldn't contain any newlines to avoid potential problems with file hashes between Windows and non-Windows platforms.

## "Main" registry file

Table with one package per row and the following columns:
* `name`: Name of the package
* `path`: Path to the "registry package file", relative* to the main registry file. When looking up a package, nupm joins this path to the path/URL of the "main" registry file and fetches it. Both local paths and URLs are handled the same way.
* `hash`: Hash of the "registry package file" to avoid re-downloading them all the time.

The file is sorted by `name`. No duplicate package names allowed.

## "Registry package file"

These files contain the actual information about the package that is used do fetch and install the package. Multiple versions of the same package are supported. It has exactly the following columns:
* `name`: Name of the package
* `version`: Version of the package
* `path`: Path where to look for nupm.nuon (relative to the package root*, in the case of git packages, or the main registry file, if local package)
* `type`: Type of the package. Currently only "git" and "local"
* `info`: Package-specific info based on `type`. It can be one of the following:
  * `null` if `type` is "local"
  * `record<url: string, revision: string>` if `type` is "git"

This file is sorted by `version`. No duplicate versions allowed.

_*absolute paths work, but are discouraged, only to be used for local testing etc._

## Example registry structure

_See the new `registry/` directory, the following example slightly differs from it._

```
./registry
  +-- registry.nuon
  +-- amtoine
      +-- nu-git-manager.nuon
      +-- nu-git-manager-sugar.nuon
```

```nushell
> open registry/registry.nuon
 #           name                         path                     hash
───────────────────────────────────────────────────────────────────────────
 0   nu-git-manager         amtoine/nu-git-manager.nuon         md5-4aaae15412fb84233fcb19716f6b7e89
 1   nu-git-manager-sugar   amtoine/nu-git-manager-sugar.nuon   md5-d0c7641c0b369e7c944cc668741734d9

> open amtoine/nu-git-manager.nuon | table -e
 #        name        version          path           type                            info
────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
 0   nu-git-manager   0.1.0     pkgs/nu-git-manager   git     url        https://github.com/amtoine/nu-git-manager
                                                              revision   0.1.0
 1   nu-git-manager   0.2.0     pkgs/nu-git-manager   git     url        https://github.com/amtoine/nu-git-manager
                                                              revision   0.2.0
 2   nu-git-manager   0.3.0     pkgs/nu-git-manager   git     url        https://github.com/amtoine/nu-git-manager
                                                              revision   0.3.0
 3   nu-git-manager   0.4.0     pkgs/nu-git-manager   git     url        https://github.com/amtoine/nu-git-manager
                                                              revision   0.4.0
 4   nu-git-manager   0.5.0     pkgs/nu-git-manager   git     url        https://github.com/amtoine/nu-git-manager
                                                              revision   0.5.0
 5   nu-git-manager   0.6.0     pkgs/nu-git-manager   git     url        https://github.com/amtoine/nu-git-manager
                                                              revision   0.6.0
 6   nu-git-manager   0.7.0     pkgs/nu-git-manager   git     url        https://github.com/amtoine/nu-git-manager
                                                              revision   0.7.0

> open amtoine/nu-git-manager-sugar.nuon | table -e
 #           name           version             path              type                            info
────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
 0   nu-git-manager-sugar   0.1.0     pkgs/nu-git-manager-sugar   git     url        https://github.com/amtoine/nu-git-manager
                                                                          revision   0.1.0
 1   nu-git-manager-sugar   0.2.0     pkgs/nu-git-manager-sugar   git     url        https://github.com/amtoine/nu-git-manager
                                                                          revision   0.2.0
 2   nu-git-manager-sugar   0.3.0     pkgs/nu-git-manager-sugar   git     url        https://github.com/amtoine/nu-git-manager
                                                                          revision   0.3.0
 3   nu-git-manager-sugar   0.4.0     pkgs/nu-git-manager-sugar   git     url        https://github.com/amtoine/nu-git-manager
                                                                          revision   0.4.0
 4   nu-git-manager-sugar   0.5.0     pkgs/nu-git-manager-sugar   git     url        https://github.com/amtoine/nu-git-manager
                                                                          revision   0.5.0
 5   nu-git-manager-sugar   0.6.0     pkgs/nu-git-manager-sugar   git     url        https://github.com/amtoine/nu-git-manager
                                                                          revision   0.6.0
 6   nu-git-manager-sugar   0.7.0     pkgs/nu-git-manager-sugar   git     url        https://github.com/amtoine/nu-git-manager
                                                                          revision   0.7.0
```

## Publishing a package

It is possible to only publish to a registry stored on your file system because we don't have a web service or anything like that.

The intented workflow for publishing a package is:
1. Check out the git repository with the registry
2. `cd` into the package you want to publish
3. Run `nupm publish chosen_registry` to preview the changes
4. Repeat 3 by adjusting the `nupm publish` flags until you have the desired output
5. Run the final command with the `--save` flag which will save the registry files
6. Commit the changes to the registry, create a PR upstream, etc.

The reason for steps 3. and 4. is that `nupm publish` tries to guess some values to make publishing less tedious. For example, if you're in a git repository, nupm tries to get the URL of the "origin", or the first available remote by default. This should be a sane default for most packages and frees you from having to pass the `--info` flag every time. The guess can be wrong, however, that's why you should check the output of step 3 and make the desired changes before saving the changes with `--save`.
