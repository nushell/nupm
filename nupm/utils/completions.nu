export def complete-registries [] {
    $env.nupm.registries? | default {} | columns
}
