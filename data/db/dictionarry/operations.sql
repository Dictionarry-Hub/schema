INSERT INTO profiles (name, description) VALUES
    ('radarr', 'Radarr quality profile for movies'),
    ('sonarr', 'Sonarr quality profile for TV shows');

INSERT INTO profile_items (profile_id, quality_name, allowed, position) VALUES
    (1, 'WEBDL-1080p', 1, 1),
    (1, 'Bluray-1080p', 1, 2),
    (1, 'WEBDL-720p', 1, 3),
    (2, 'WEBDL-1080p', 1, 1),
    (2, 'HDTV-1080p', 1, 2),
    (2, 'WEBDL-720p', 1, 3);
