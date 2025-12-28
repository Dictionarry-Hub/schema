-- ============================================================================
-- PCD SCHEMA v1
-- ============================================================================

-- ============================================================================
-- CORE ENTITY TABLES (Independent - No Foreign Key Dependencies)
-- ============================================================================
-- These tables form the foundation and can be populated in any order

-- Tags are reusable labels that can be applied to multiple entity types
CREATE TABLE tags (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(50) UNIQUE NOT NULL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Languages used for profile configuration and custom format conditions
CREATE TABLE languages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(30) UNIQUE NOT NULL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Regular expressions used in custom format pattern conditions
CREATE TABLE regular_expressions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(100) UNIQUE NOT NULL,
    pattern TEXT NOT NULL,
    regex101_id VARCHAR(50),  -- Optional link to regex101.com for testing
    description TEXT,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Individual quality definitions (e.g., "1080p Bluray", "2160p REMUX")
CREATE TABLE qualities (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(100) UNIQUE NOT NULL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Maps Profilarr canonical qualities to arr-specific API names
-- Absence of a row means the quality doesn't exist for that arr
CREATE TABLE quality_api_mappings (
    quality_id INTEGER NOT NULL,
    arr_type VARCHAR(20) NOT NULL,  -- 'radarr', 'sonarr'
    api_name VARCHAR(100) NOT NULL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (quality_id, arr_type),
    FOREIGN KEY (quality_id) REFERENCES qualities(id) ON DELETE CASCADE
);

-- Custom formats define patterns and conditions for media matching
CREATE TABLE custom_formats (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- DEPENDENT ENTITY TABLES (Depend on Core Entities)
-- ============================================================================

-- Quality profiles define complete media acquisition strategies
CREATE TABLE quality_profiles (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    upgrades_allowed INTEGER NOT NULL DEFAULT 1,
    minimum_custom_format_score INTEGER NOT NULL DEFAULT 0,
    upgrade_until_score INTEGER NOT NULL DEFAULT 0,
    upgrade_score_increment INTEGER NOT NULL DEFAULT 1 CHECK (upgrade_score_increment > 0),
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Quality groups combine multiple qualities treated as equivalent
-- Each group is specific to a quality profile (profiles do not share groups)
CREATE TABLE quality_groups (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    quality_profile_id INTEGER NOT NULL,
    name VARCHAR(100) NOT NULL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(quality_profile_id, name),
    FOREIGN KEY (quality_profile_id) REFERENCES quality_profiles(id) ON DELETE CASCADE
);

-- Conditions define the matching logic for custom formats
-- Each condition has a type and corresponding data in a type-specific table
CREATE TABLE custom_format_conditions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    custom_format_id INTEGER NOT NULL,
    name VARCHAR(100) NOT NULL,
    type VARCHAR(50) NOT NULL,
    arr_type VARCHAR(20) NOT NULL,  -- 'radarr', 'sonarr', 'all'
    negate INTEGER NOT NULL DEFAULT 0,
    required INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (custom_format_id) REFERENCES custom_formats(id) ON DELETE CASCADE
);

-- ============================================================================
-- JUNCTION TABLES (Many-to-Many Relationships)
-- ============================================================================

-- Link regular expressions to tags
CREATE TABLE regular_expression_tags (
    regular_expression_id INTEGER NOT NULL,
    tag_id INTEGER NOT NULL,
    PRIMARY KEY (regular_expression_id, tag_id),
    FOREIGN KEY (regular_expression_id) REFERENCES regular_expressions(id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
);

-- Link custom formats to tags
CREATE TABLE custom_format_tags (
    custom_format_id INTEGER NOT NULL,
    tag_id INTEGER NOT NULL,
    PRIMARY KEY (custom_format_id, tag_id),
    FOREIGN KEY (custom_format_id) REFERENCES custom_formats(id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
);

-- Link quality profiles to tags
CREATE TABLE quality_profile_tags (
    quality_profile_id INTEGER NOT NULL,
    tag_id INTEGER NOT NULL,
    PRIMARY KEY (quality_profile_id, tag_id),
    FOREIGN KEY (quality_profile_id) REFERENCES quality_profiles(id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
);

-- Link quality profiles to languages with type modifiers
-- Type can be: 'must', 'only', 'not', or 'simple' (default language preference)
CREATE TABLE quality_profile_languages (
    quality_profile_id INTEGER NOT NULL,
    language_id INTEGER NOT NULL,
    type VARCHAR(20) NOT NULL DEFAULT 'simple',  -- 'must', 'only', 'not', 'simple'
    PRIMARY KEY (quality_profile_id, language_id),
    FOREIGN KEY (quality_profile_id) REFERENCES quality_profiles(id) ON DELETE CASCADE,
    FOREIGN KEY (language_id) REFERENCES languages(id) ON DELETE CASCADE
);

-- Define which qualities belong to which quality groups
-- All qualities in a group are treated as equivalent
CREATE TABLE quality_group_members (
    quality_group_id INTEGER NOT NULL,
    quality_id INTEGER NOT NULL,
    PRIMARY KEY (quality_group_id, quality_id),
    FOREIGN KEY (quality_group_id) REFERENCES quality_groups(id) ON DELETE CASCADE,
    FOREIGN KEY (quality_id) REFERENCES qualities(id) ON DELETE CASCADE
);

-- Define the quality list for a profile (ordered by position)
-- Each item references either a single quality OR a quality group (never both)
-- Every quality must be represented (either directly or in a group)
-- The enabled flag controls whether the quality/group is active
CREATE TABLE quality_profile_qualities (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    quality_profile_id INTEGER NOT NULL,
    quality_id INTEGER,  -- References a single quality
    quality_group_id INTEGER,  -- OR references a quality group
    position INTEGER NOT NULL,  -- Display order in the profile
    enabled INTEGER NOT NULL DEFAULT 1,  -- Whether this quality/group is enabled
    upgrade_until INTEGER NOT NULL DEFAULT 0,  -- Stop upgrading at this quality
    CHECK ((quality_id IS NOT NULL AND quality_group_id IS NULL) OR (quality_id IS NULL AND quality_group_id IS NOT NULL)),
    FOREIGN KEY (quality_profile_id) REFERENCES quality_profiles(id) ON DELETE CASCADE,
    FOREIGN KEY (quality_id) REFERENCES qualities(id) ON DELETE CASCADE,
    FOREIGN KEY (quality_group_id) REFERENCES quality_groups(id) ON DELETE CASCADE
);

-- Assign custom formats to quality profiles with scoring
-- Scores determine upgrade priority and filtering behavior
CREATE TABLE quality_profile_custom_formats (
    quality_profile_id INTEGER NOT NULL,
    custom_format_id INTEGER NOT NULL,
    arr_type VARCHAR(20) NOT NULL,  -- 'radarr', 'sonarr', 'all',
    score INTEGER NOT NULL,
    PRIMARY KEY (quality_profile_id, custom_format_id, arr_type),
    FOREIGN KEY (quality_profile_id) REFERENCES quality_profiles(id) ON DELETE CASCADE,
    FOREIGN KEY (custom_format_id) REFERENCES custom_formats(id) ON DELETE CASCADE
);

-- ============================================================================
-- CUSTOM FORMAT CONDITION TYPE TABLES
-- ============================================================================
-- Each condition type has a dedicated table storing type-specific data
-- A condition_id should only appear in ONE of these tables, matching its type

-- Pattern-based conditions (release_title, release_group, edition)
-- Each pattern condition references exactly one regular expression
CREATE TABLE condition_patterns (
    custom_format_condition_id INTEGER PRIMARY KEY,
    regular_expression_id INTEGER NOT NULL,
    FOREIGN KEY (custom_format_condition_id) REFERENCES custom_format_conditions(id) ON DELETE CASCADE,
    FOREIGN KEY (regular_expression_id) REFERENCES regular_expressions(id) ON DELETE CASCADE
);

-- Language-based conditions
CREATE TABLE condition_languages (
    custom_format_condition_id INTEGER PRIMARY KEY,
    language_id INTEGER NOT NULL,
    except_language INTEGER NOT NULL DEFAULT 0,  -- Match everything EXCEPT this language
    FOREIGN KEY (custom_format_condition_id) REFERENCES custom_format_conditions(id) ON DELETE CASCADE,
    FOREIGN KEY (language_id) REFERENCES languages(id) ON DELETE CASCADE
);

-- Indexer flag conditions (e.g., "Scene", "Freeleech")
CREATE TABLE condition_indexer_flags (
    custom_format_condition_id INTEGER PRIMARY KEY,
    flag VARCHAR(100) NOT NULL,
    FOREIGN KEY (custom_format_condition_id) REFERENCES custom_format_conditions(id) ON DELETE CASCADE
);

-- Source conditions (e.g., "Bluray", "Web", "DVD")
CREATE TABLE condition_sources (
    custom_format_condition_id INTEGER PRIMARY KEY,
    source VARCHAR(100) NOT NULL,
    FOREIGN KEY (custom_format_condition_id) REFERENCES custom_format_conditions(id) ON DELETE CASCADE
);

-- Resolution conditions (e.g., "1080p", "2160p")
CREATE TABLE condition_resolutions (
    custom_format_condition_id INTEGER PRIMARY KEY,
    resolution VARCHAR(100) NOT NULL,
    FOREIGN KEY (custom_format_condition_id) REFERENCES custom_format_conditions(id) ON DELETE CASCADE
);

-- Quality modifier conditions (e.g., "REMUX", "WEBDL")
CREATE TABLE condition_quality_modifiers (
    custom_format_condition_id INTEGER PRIMARY KEY,
    quality_modifier VARCHAR(100) NOT NULL,
    FOREIGN KEY (custom_format_condition_id) REFERENCES custom_format_conditions(id) ON DELETE CASCADE
);

-- Size-based conditions with min/max bounds in bytes
CREATE TABLE condition_sizes (
    custom_format_condition_id INTEGER PRIMARY KEY,
    min_bytes INTEGER,  -- Null means no minimum
    max_bytes INTEGER,  -- Null means no maximum
    FOREIGN KEY (custom_format_condition_id) REFERENCES custom_format_conditions(id) ON DELETE CASCADE
);

-- Release type conditions (e.g., "Movie", "Episode")
CREATE TABLE condition_release_types (
    custom_format_condition_id INTEGER PRIMARY KEY,
    release_type VARCHAR(100) NOT NULL,
    FOREIGN KEY (custom_format_condition_id) REFERENCES custom_format_conditions(id) ON DELETE CASCADE
);

-- Year-based conditions with min/max bounds
CREATE TABLE condition_years (
    custom_format_condition_id INTEGER PRIMARY KEY,
    min_year INTEGER,  -- Null means no minimum
    max_year INTEGER,  -- Null means no maximum
    FOREIGN KEY (custom_format_condition_id) REFERENCES custom_format_conditions(id) ON DELETE CASCADE
);

-- ============================================================================
-- MEDIA MANAGEMENT TABLES
-- ============================================================================

-- Radarr quality size definitions
CREATE TABLE radarr_quality_definitions (
    quality_id INTEGER PRIMARY KEY,
    min_size INTEGER NOT NULL DEFAULT 0,
    max_size INTEGER NOT NULL,
    preferred_size INTEGER NOT NULL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (quality_id) REFERENCES qualities(id) ON DELETE CASCADE
);

-- Sonarr quality size definitions
CREATE TABLE sonarr_quality_definitions (
    quality_id INTEGER PRIMARY KEY,
    min_size INTEGER NOT NULL DEFAULT 0,
    max_size INTEGER NOT NULL,
    preferred_size INTEGER NOT NULL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (quality_id) REFERENCES qualities(id) ON DELETE CASCADE
);

-- Radarr naming configuration
CREATE TABLE radarr_naming (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    rename INTEGER NOT NULL DEFAULT 1,
    movie_format TEXT NOT NULL,
    movie_folder_format TEXT NOT NULL,
    replace_illegal_characters INTEGER NOT NULL DEFAULT 0,
    colon_replacement_format VARCHAR(20) NOT NULL DEFAULT 'smart',
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Sonarr naming configuration
CREATE TABLE sonarr_naming (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    rename INTEGER NOT NULL DEFAULT 1,
    standard_episode_format TEXT NOT NULL,
    daily_episode_format TEXT NOT NULL,
    anime_episode_format TEXT NOT NULL,
    series_folder_format TEXT NOT NULL,
    season_folder_format TEXT NOT NULL,
    replace_illegal_characters INTEGER NOT NULL DEFAULT 0,
    colon_replacement_format INTEGER NOT NULL DEFAULT 4,
    custom_colon_replacement_format TEXT,
    multi_episode_style INTEGER NOT NULL DEFAULT 5,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Radarr general media settings
CREATE TABLE radarr_media_settings (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    propers_repacks VARCHAR(50) NOT NULL DEFAULT 'doNotPrefer',
    enable_media_info INTEGER NOT NULL DEFAULT 1,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Sonarr general media settings
CREATE TABLE sonarr_media_settings (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    propers_repacks VARCHAR(50) NOT NULL DEFAULT 'doNotPrefer',
    enable_media_info INTEGER NOT NULL DEFAULT 1,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- DELAY PROFILES
-- ============================================================================

-- Delay profiles control download timing preferences
CREATE TABLE delay_profiles (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(100) UNIQUE NOT NULL,
    preferred_protocol VARCHAR(20) NOT NULL CHECK (
        preferred_protocol IN ('prefer_usenet', 'prefer_torrent', 'only_usenet', 'only_torrent')
    ),
    usenet_delay INTEGER,  -- minutes, NULL if only_torrent
    torrent_delay INTEGER,  -- minutes, NULL if only_usenet
    bypass_if_highest_quality INTEGER NOT NULL DEFAULT 0,
    bypass_if_above_custom_format_score INTEGER NOT NULL DEFAULT 0,
    minimum_custom_format_score INTEGER,  -- Required when bypass_if_above_custom_format_score = 1
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    -- Enforce usenet_delay is NULL only when only_torrent
    CHECK (
        (preferred_protocol = 'only_torrent' AND usenet_delay IS NULL) OR
        (preferred_protocol != 'only_torrent' AND usenet_delay IS NOT NULL)
    ),
    -- Enforce torrent_delay is NULL only when only_usenet
    CHECK (
        (preferred_protocol = 'only_usenet' AND torrent_delay IS NULL) OR
        (preferred_protocol != 'only_usenet' AND torrent_delay IS NOT NULL)
    ),
    -- Enforce minimum_custom_format_score required when bypass enabled
    CHECK (
        (bypass_if_above_custom_format_score = 0 AND minimum_custom_format_score IS NULL) OR
        (bypass_if_above_custom_format_score = 1 AND minimum_custom_format_score IS NOT NULL)
    )
);

-- Link delay profiles to tags (at least 1 required - enforced at application level)
CREATE TABLE delay_profile_tags (
    delay_profile_id INTEGER NOT NULL,
    tag_id INTEGER NOT NULL,
    PRIMARY KEY (delay_profile_id, tag_id),
    FOREIGN KEY (delay_profile_id) REFERENCES delay_profiles(id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
);

-- ============================================================================
-- INDEXES AND CONSTRAINTS
-- ============================================================================

-- Ensure only one quality item per profile can be marked as upgrade_until
CREATE UNIQUE INDEX idx_one_upgrade_until_per_profile
ON quality_profile_qualities(quality_profile_id)
WHERE upgrade_until = 1;
