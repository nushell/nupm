def main [package_file: path] {
    let package = open $package_file
    print $"Installing ($package.name) to ($env.NUPM_HOME) inside ($env.PWD)"
    mkdir ($env.NUPM_HOME | path join plugins)
    touch ($env.NUPM_HOME | path join plugins nu_plugin_test)
}
