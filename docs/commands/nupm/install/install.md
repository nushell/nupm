# `install` (`install nupm`)
Install a nupm package



## Parameters
- parameter_name: package
- parameter_type: positional
- syntax_shape: any
- is_optional: false
- description: Name, path, or link to the package
---
- parameter_name: path
- parameter_type: switch
- is_optional: true
- description: Install package from a directory with nupm.nuon given by 'name'
---
- parameter_name: force
- parameter_type: switch
- is_optional: true
- short_flag: f
- description: Overwrite already installed package
---
- parameter_name: no-confirm
- parameter_type: switch
- is_optional: true
- description: Allows to bypass the interactive confirmation, useful for scripting

## Signatures
| input     | output    |
| --------- | --------- |
| `nothing` | `nothing` |
