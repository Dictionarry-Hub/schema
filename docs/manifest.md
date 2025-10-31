# Manifest Specification

Every Profilarr Compliant Database must include a `pcd.json` manifest file in
its root directory. This file defines the database's identity, compatibility,
and dependencies.

## Required Fields

| Field                       | Description                                                                                   |
| --------------------------- | --------------------------------------------------------------------------------------------- |
| `name`                      | Unique identifier for the database (lowercase, hyphens preferred)                             |
| `version`                   | Semantic version of the database (MAJOR.MINOR.PATCH)                                          |
| `description`               | Short summary of what the database provides                                                   |
| `dependencies`              | Object mapping dependency names to semver ranges. All PCDs must depend on `schema` at minimum |
| `profilarr.minimum_version` | Minimum Profilarr version required to use this database                                       |

## Optional Fields

| Field          | Description                                                                                                                        |
| -------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| `arr_types`    | Array of supported arr applications (`["radarr"]`, `["sonarr"]`, or `["radarr", "sonarr"]`). If omitted, assumes all are supported |
| `authors`      | Array of contributor objects with name and optional email                                                                          |
| `license`      | SPDX license identifier                                                                                                            |
| `repository`   | Git repository URL                                                                                                                 |
| `dependencies` | Can include other PCDs in addition to the schema, enabling layered databases                                                       |
| `tags`         | Array of descriptive keywords for discovery                                                                                        |
| `links`        | External resource URLs (homepage, documentation, issues)                                                                           |

## Example

```json
{
    "name": "db",
    "version": "2.1.35",
    "description": "Seraphys' OCD Playground",
    "arr_types": ["radarr", "sonarr", "whisparr"],

    "dependencies": {
        "schema": "^1.1.0"
    },

    "authors": [
        {
            "name": "Dictionarry Team",
            "email": "team@dictionarry.dev"
        }
    ],

    "license": "MIT",
    "repository": "https://github.com/dictionarry-hub/database",

    "tags": ["4k", "hdr", "remux", "quality", "archival"],

    "links": {
        "homepage": "https://dictionarry.dev",
        "issues": "https://github.com/dictionarry-hub/db/issues"
    },

    "profilarr": {
        "minimum_version": "2.0.0"
    }
}
```
