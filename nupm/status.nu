use utils/log.nu throw-error
use utils/package.nu [open-package-file list-package-files]


# Display status and information about a package
#
# Shows package metadata and lists all files that would be included
# in the package installation. Useful for inspecting package contents
# before installation or for debugging package structure.
@example "Check status of current directory package" {
  nupm status
}
@example "Check status of specific package directory" {
  nupm status ./my-package
}
@example "View package files and metadata" {
  nupm status ./my-package | get files
}
export def main [
    path?: path  # path to the package
]: nothing -> record<filename: string> {
    let path = $path | default $env.PWD | path expand

    let pkg = open-package-file $path
    let files = list-package-files $path $pkg

    {
        ...$pkg
        files: $files
    }
}
