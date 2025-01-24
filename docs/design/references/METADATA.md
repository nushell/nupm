# `nupm`'s package metadata reference

## Required attributes
- `name`: Package name
- `nu-version`: Supported Nushell version. Just like `dependencies` might be either exact version or some matcher like "greater than 1.70"
- `version`: Version of the package. Semantic versioning is advised to enable users to have more generic requirements
- `type`: Tells `nupm` how to install the package

## Required attributes for publishing
- `author`: Name of the developer/organization/etc.
- `short-description`: Short info about the package, displayed by default
- `supported-os`: Operating systems supported by the package, the most broad possibility: `{"arch": ["*"], "family": ["*"], "name": ["*"]}`. Matched by `$nu.os-info`
- `url`: Package website/GitHub repository. Basically a place where one can find some additional info about the package

## Optional attributes
- `dependencies`: Packages needed by the package — versions have to be specified. e.g. `[nupm/0.7.0]`. Semantic versioning is also supported: `[nupm/~0.7]`
- `installer`: Name of a script (relative to the package scope) that will install the package instead (or in addition to) of default `nupm` logic
- `keywords`: List of keywords used by `nupm search` in addition to `name`

## Automatically generated, outside of the user-created metadata file
- `files`: List of records of files being part of the package. Records reference:
  - `checksum`: SHA256 sum of the file
  - `name`: File path (relative to the package scope)
  - `raw-url`: `GET`table link to the file
  - `supported-os`: Exactly like in the top-level metadata
