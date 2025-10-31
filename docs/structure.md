# PCD Structure

## Operational vs Stateful

PCDs are **operational databases** - they store SQL operations, not data
snapshots.

| Stateful                       | Operational                                                 |
| ------------------------------ | ----------------------------------------------------------- |
| Stores what data should be     | Stores how to create data                                   |
| `{"name": "HD Quality"}`       | `INSERT INTO quality_profiles (name) VALUES ('HD Quality')` |
| Merge conflicts when combining | Natural composition through execution order                 |
| Diffs show state changes       | Diffs show operation changes                                |

## Document Driven SQL

Each entity is stored as a complete SQL document containing all related
operations.

**Example: A profile document (`profiles/hd-quality.sql`)**

```sql
-- Profile entity
INSERT INTO quality_profiles (name, language_id) VALUES (...);

-- Quality list
INSERT INTO quality_profile_qualities (...);

-- Custom format scores  
INSERT INTO quality_profile_custom_formats (...);

-- Tags
INSERT INTO quality_profile_tags (...);
```

One file = one complete entity with all relationships.

## Directory Structure

```
database-repo/
├── pcd.json                           # Manifest
├── operations/
│   ├── core/
│   │   ├── quality_profiles/
│   │   │   ├── hd-quality.sql
│   │   │   ├── 4k-remux.sql
│   │   │   └── efficient-1080p.sql
│   │   ├── custom_formats/
│   │   │   ├── dv-hdr10-plus.sql
│   │   │   ├── dolby-atmos.sql
│   │   │   └── scene-release.sql
│   │   └── regular_expressions/
│   │       ├── dolby-vision-pattern.sql
│   │       ├── hdr10-plus-pattern.sql
│   │       └── remux-pattern.sql
│   └── tweaks/
│       ├── anime-formats.sql
│       └── av1-profiles.sql
└── README.md
```

Each entity type has its own directory. Each entity gets its own document file.

## Execution Model

PCDs execute as layered operations:

```
1. Schema (CREATE TABLE statements)
   ↓
2. Dependencies (other PCD operations)
   ↓
3. Database (this PCD's operations)
   ↓
4. User customizations (user's operations)
   ↓
Result: Populated database
```
