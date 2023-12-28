# Commands related to handling versions
#
# We might move some of this to Nushell builtins

# Sort packages by version
export def sort-pkgs []: table<version: string> -> table<version: string> {
    sort-by version
}
