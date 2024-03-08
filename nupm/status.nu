use utils/log.nu throw-error
use utils/package.nu [open-package-file list-package-files]


# Display status of a package
export def main [
    path?: path  # path to the package
] -> record<filename: string> {
    let path = $path | default $env.PWD | path expand

    let pkg = open-package-file $path
    let files = list-package-files $path $pkg

    {
        ...$pkg
        files: $files
    }
}
