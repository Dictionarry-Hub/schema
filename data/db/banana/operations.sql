INSERT INTO profiles (name, description) VALUES
    ('banana-test', 'Test profile for banana database');

INSERT INTO profile_items (profile_id, quality_name, allowed, position) VALUES
    (1, 'WEBDL-2160p', 1, 1),
    (1, 'WEBDL-1080p', 1, 2),
    (1, 'Bluray-2160p', 1, 3);
