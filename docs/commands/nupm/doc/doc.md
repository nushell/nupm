# `doc` (`doc nupm`)
Generates markdown documentation of the current or provided nushell modules.

## Examples
Basic usage
```nushell
nupm doc
```

## Parameters
- parameter_name: documentation-dir
- parameter_type: named
- syntax_shape: path
- is_optional: true
- description: The directory to put generated documentation in.
---
- parameter_name: library-paths
- parameter_type: named
- syntax_shape: list<path>
- is_optional: true
- description: A list of paths to nushell modules to generate documentation for.
---
- parameter_name: plugin-paths
- parameter_type: named
- syntax_shape: list<path>
- is_optional: true
- description: NOT IMPLEMENTED YET
---
- parameter_name: not-local
- parameter_type: switch
- is_optional: true
- description: Tells the command not to generate documentation for the current directory if the current directory has a nupm.nuon file in it.

## Signatures
| input     | output    |
| --------- | --------- |
| `nothing` | `nothing` |
