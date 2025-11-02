# Profile Compliant Databases (PCDs)

## 1. Purpose

PCDs describe a database as a sequence of SQL operations, not as final data. The
stored artifact is **how to build the state**, not **the state** itself. We
describe this as _operational_, instead of the traditional _stateful_.

## 2. Operational SQL (OSQL)

PCDs use SQL in an append-only, ordered way. Call this **Operational SQL
(OSQL)**.

1. **Append-only**: once an operation exists, it is never edited or deleted.
2. **Ordered**: operations run in a defined order; later operations can override
   the effects of earlier ones.
3. **Replayable**: anyone can rebuild the database by replaying operations in
   order.
4. **Relational**: operations target real tables/columns/rows, so constraints
   (FKs) still apply.

This gives "Mutable Immutability": history is immutable; results are mutable
because new ops (operations) can be added.

## 3. Change-Driven Development (CDD)

CDD is the workflow for producing operations.

1. Start from a change: "profile `1080p Quality HDR` should give `Dolby Atmos` a
   higher score".
2. Express it as a single SQL operation:

```sql
UPDATE quality_profile_custom_formats
SET score = 1200
WHERE profile_id = qp('1080p Quality HDR')
AND custom_format_id = cf('Dolby Atmos')
AND score = 400; -- expected previous value
```

3. Append it to the appropriate layer (see Layers below)
4. Recompose.

The expected-value guard (`AND score = 400`) is what makes conflicts explicit.

## 4. Layers

PCDs run in layers. Every layer is append-only, but later layers can override
the effect of earlier ones.

1. **Schema**\
   Core DDL for the PCD. Created and maintained by Profilarr. Creates tables,
   FKs, indexes. **No data.**

2. **Dependencies**\
   Reserved for future use. Will allow PCDs to compose with other PCDs.

3. **Base**\
   The actual shipped database content (profiles, quality lists, format
   definitions) for this PCD/version.

4. **Tweaks**\
   Optional, append-only operations that adjust behaviour (allow DV, allow CAMS,
   disable group Z).

5. **User Ops**\
   User changes created for a specific instantiation of a database. Heavy value
   guards to detect conflicts and alert users when upstream changes.

## 5. Repository Layout

A PCD repository has a manifest, an operations folder, and an optional tweaks
folder.

```text
my-pcd/
├── pcd.json
├── ops/
│   ├── 1.create-1080p-Efficient.sql
└── tweaks/
    ├── allow-DV-no-fallback.sql
    └── ban-megusta.sql
```

In the case of the schema, it's the same layout, with only the DDL in `ops/` and
no tweaks:

```text
schema-pcd/
├── pcd.json
└── ops/
    └── 0.schema.sql
```

## 6. Dependencies (Post-2.0)

**Dependencies are not part of 2.0.** At current scale (~10 in use databases),
forking solves shared-code needs without the complexity of dependency
resolution, version conflicts, and circular dependency detection. The layer
system supports adding dependencies in 2.1+ without breaking existing PCDs.
We'll build dependency support when clear duplication patterns emerge and
forking proves insufficient.
