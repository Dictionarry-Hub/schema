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
- Make quality groups unique and not reusable across profiles

## 28-12-25

- Add quality API mappings for Radarr/Sonarr name translation
  - quality_api_mappings: maps canonical Profilarr quality names to arr-specific
    API names (e.g., Remux-1080p -> Bluray-1080p Remux for Sonarr)
- Add media management tables (arr-specific)
  - radarr_quality_definitions / sonarr_quality_definitions: size limits
    (min/max/preferred) per quality
  - radarr_naming / sonarr_naming: file/folder naming formats
  - radarr_media_settings / sonarr_media_settings: general settings
    (propers_repacks, enable_media_info)
- Add delay profiles for download timing control
  - delay_profiles: protocol preference, delays, bypass conditions
  - delay_profile_tags: junction table for tag associations
  - CHECK constraints for protocol/delay validation

## 31-12-25
- Add custom format testing table
  - custom_format_tests: stores test cases for validating custom format matching
  - Each test specifies a release title and whether it should match the format
  - Supports movie/series type differentiation for parser context
  - Unique constraint on (custom_format_id, title, type) prevents duplicate tests
- Add include_in_rename column to custom_formats table
  - Controls whether custom format name appears in renamed filenames

## 3-1-26
- Add quality profile testing tables
  - test_entities: stores movies/series from TMDB for testing quality profiles
  - test_releases: stores sample releases attached to test entities
  - Supports languages, indexers, and flags as JSON arrays for release metadata