module pkg/lib/lib.nu                # allow to `use lib` in the whole module
export module pkg/lib/bar.nu         # re-export a submodule named `bar`
export use pkg/lib/internal.nu yeah  # re-export an internal command named `yeah`

use lib

export def main [] {
    print "this is foo"
    lib
}
