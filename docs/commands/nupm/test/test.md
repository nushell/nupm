# `test` (`test nupm`)
Experimental test runner



## Parameters
- parameter_name: filter
- parameter_type: positional
- syntax_shape: string
- is_optional: true
- description: Run only tests containing this substring
---
- parameter_name: dir
- parameter_type: named
- syntax_shape: path
- is_optional: true
- description: Directory where to run tests (default: $env.PWD)
---
- parameter_name: show-stdout
- parameter_type: switch
- is_optional: true
- description: Show standard output of each test

## Signatures
| input     | output    |
| --------- | --------- |
| `nothing` | `nothing` |
