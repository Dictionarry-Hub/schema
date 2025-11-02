# Changelog

All schema changes will be documented in this file.

## 31-10-25

- Hello, World!
- Initial PCD 2.0 schema definition
- Core entity tables: quality_profiles, custom_formats, regular_expressions,
  languages, tags, qualities, quality_groups
- Custom format conditions system with 11 condition types (patterns, language,
  indexer_flag, source, resolution, quality_modifier, size, release_type, year)
- Quality profile system supporting individual qualities and quality groups
- Junction tables for tags, quality groups, profile qualities, and profile
  custom formats
- Unique index ensuring single upgrade_until per profile
- Add arr_type support for Radarr/Sonarr differentiation
  - custom_format_conditions.arr_type: conditions can be arr-specific or
    universal
  - quality_profile_custom_formats.arr_type: scores can differ between Radarr
    and Sonarr

## 3-11-25

- Better profile langauge procesing
