def main [package_file: path] {
      use std/log
    log info $env.nupm.home
    let package = open $package_file
    print $"Installing ($package.name) to ($env.nupm.home) inside ($env.PWD)"
    mkdir ($env.nupm.home | path join plugins)
    touch ($env.nupm.home | path join plugins nu_plugin_test)
}
