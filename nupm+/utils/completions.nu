export def complete-registries [] {
    $env.NUPM_REGISTRIES? | default {} | columns
}
