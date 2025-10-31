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

-- Quality groups combine multiple qualities treated as equivalent
CREATE TABLE quality_groups (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(100) UNIQUE NOT NULL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
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
    language_id INTEGER NOT NULL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (language_id) REFERENCES languages(id)
);

-- Conditions define the matching logic for custom formats
-- Each condition has a type and corresponding data in a type-specific table
CREATE TABLE custom_format_conditions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    custom_format_id INTEGER NOT NULL,
    name VARCHAR(100) NOT NULL,
    type VARCHAR(50) NOT NULL,  -- release_title, release_group, edition, language, etc.
    negate INTEGER NOT NULL DEFAULT 0,  -- Invert the match (e.g., "NOT language")
    required INTEGER NOT NULL DEFAULT 0,  -- Condition must match for format to apply
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
CREATE TABLE quality_profile_qualities (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    quality_profile_id INTEGER NOT NULL,
    quality_id INTEGER,  -- References a single quality
    quality_group_id INTEGER,  -- OR references a quality group
    position INTEGER NOT NULL,  -- Display order in the profile
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
    score INTEGER NOT NULL,  -- Positive scores prefer, negative scores reject
    PRIMARY KEY (quality_profile_id, custom_format_id),
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
-- INDEXES AND CONSTRAINTS
-- ============================================================================

-- Ensure only one quality item per profile can be marked as upgrade_until
CREATE UNIQUE INDEX idx_one_upgrade_until_per_profile 
ON quality_profile_qualities(quality_profile_id) 
WHERE upgrade_until = 1;