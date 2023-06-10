use std log

# install a Nuhshell package
#
# > **Warning**  
# > - only supports GitHub packages
# > - a package needs to have a `package.nuon` file at its root with some keys
#
# # Examples
#     install a repo package
#     > nupm install https://github.com/amtoine/nu-git-manager
#
#     install a subpath package
#     > nupm install https://github.com/amtoine/zellij-layouts --path nu-zellij
export def main [
    url: string  # the URL to the root of the repo holding the package
    --path: string  # if the package is not the repo itself, gives the path to it
] {
}
