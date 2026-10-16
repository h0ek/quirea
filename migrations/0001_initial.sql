CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE TABLE IF NOT EXISTS users (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email text NOT NULL,
    password_hash text NOT NULL,
    display_name text NOT NULL DEFAULT '',
    role text NOT NULL DEFAULT 'user' CHECK (role IN ('user','admin')),
    status text NOT NULL DEFAULT 'active' CHECK (status IN ('active','disabled','pending')),
    totp_secret_encrypted bytea,
    totp_enabled_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    last_login_at timestamptz
);

CREATE UNIQUE INDEX IF NOT EXISTS users_email_lower_uq ON users (lower(email));

CREATE TABLE IF NOT EXISTS feeds (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    url text NOT NULL,
    canonical_url text,
    site_url text,
    title text NOT NULL DEFAULT '',
    description text NOT NULL DEFAULT '',
    language text,
    etag text,
    last_modified text,
    last_checked_at timestamptz,
    last_success_at timestamptz,
    next_fetch_at timestamptz,
    failure_count integer NOT NULL DEFAULT 0,
    disabled_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS feeds_url_uq ON feeds (url);
CREATE INDEX IF NOT EXISTS feeds_title_trgm_idx ON feeds USING gin (title gin_trgm_ops);

CREATE TABLE IF NOT EXISTS entries (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    feed_id bigint NOT NULL REFERENCES feeds(id) ON DELETE CASCADE,
    guid text,
    url text NOT NULL DEFAULT '',
    title text NOT NULL DEFAULT '',
    author text NOT NULL DEFAULT '',
    summary text NOT NULL DEFAULT '',
    content_html text NOT NULL DEFAULT '',
    content_text text NOT NULL DEFAULT '',
    image_url text,
    published_at timestamptz,
    discovered_at timestamptz NOT NULL DEFAULT now(),
    search_vector tsvector GENERATED ALWAYS AS (
        to_tsvector('simple', coalesce(title, '') || ' ' || coalesce(author, '') || ' ' || coalesce(summary, '') || ' ' || coalesce(content_text, ''))
    ) STORED
);

CREATE UNIQUE INDEX IF NOT EXISTS entries_feed_guid_uq ON entries (feed_id, guid) WHERE guid IS NOT NULL;
CREATE INDEX IF NOT EXISTS entries_feed_published_idx ON entries (feed_id, published_at DESC);
CREATE INDEX IF NOT EXISTS entries_search_idx ON entries USING gin (search_vector);
CREATE INDEX IF NOT EXISTS entries_title_trgm_idx ON entries USING gin (title gin_trgm_ops);

CREATE TABLE IF NOT EXISTS subscriptions (
    user_id bigint NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    feed_id bigint NOT NULL REFERENCES feeds(id) ON DELETE CASCADE,
    created_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, feed_id)
);

CREATE TABLE IF NOT EXISTS categories (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id bigint NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name text NOT NULL,
    position integer NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS categories_user_name_lower_uq ON categories (user_id, lower(name));

CREATE TABLE IF NOT EXISTS category_feeds (
    category_id bigint NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    feed_id bigint NOT NULL REFERENCES feeds(id) ON DELETE CASCADE,
    PRIMARY KEY (category_id, feed_id)
);

CREATE TABLE IF NOT EXISTS entry_user_state (
    user_id bigint NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    entry_id bigint NOT NULL REFERENCES entries(id) ON DELETE CASCADE,
    read_at timestamptz,
    favorite_at timestamptz,
    read_later_at timestamptz,
    updated_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, entry_id)
);

CREATE INDEX IF NOT EXISTS entry_user_state_unread_idx ON entry_user_state (user_id, entry_id) WHERE read_at IS NULL;
CREATE INDEX IF NOT EXISTS entry_user_state_favorite_idx ON entry_user_state (user_id, favorite_at DESC) WHERE favorite_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS entry_user_state_read_later_idx ON entry_user_state (user_id, read_later_at DESC) WHERE read_later_at IS NOT NULL;

CREATE TABLE IF NOT EXISTS sessions (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id bigint NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash bytea NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    last_seen_at timestamptz NOT NULL DEFAULT now(),
    expires_at timestamptz NOT NULL,
    revoked_at timestamptz,
    user_agent text NOT NULL DEFAULT ''
);

CREATE UNIQUE INDEX IF NOT EXISTS sessions_token_hash_uq ON sessions (token_hash);
CREATE INDEX IF NOT EXISTS sessions_user_active_idx ON sessions (user_id, expires_at) WHERE revoked_at IS NULL;

CREATE TABLE IF NOT EXISTS recovery_codes (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id bigint NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    code_hash bytea NOT NULL,
    used_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS invitations (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    token_hash bytea NOT NULL,
    created_by bigint REFERENCES users(id) ON DELETE SET NULL,
    email text,
    expires_at timestamptz NOT NULL,
    used_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS invitations_token_hash_uq ON invitations (token_hash);

CREATE TABLE IF NOT EXISTS public_source_submissions (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    feed_id bigint NOT NULL REFERENCES feeds(id) ON DELETE CASCADE,
    submitted_by bigint REFERENCES users(id) ON DELETE SET NULL,
    status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','approved','rejected')),
    created_at timestamptz NOT NULL DEFAULT now(),
    reviewed_at timestamptz,
    reviewed_by bigint REFERENCES users(id) ON DELETE SET NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS public_source_submissions_pending_uq ON public_source_submissions (feed_id) WHERE status IN ('pending','approved');

CREATE TABLE IF NOT EXISTS instance_settings (
    key text PRIMARY KEY,
    value jsonb NOT NULL,
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS stats_daily (
    day date PRIMARY KEY,
    registrations bigint NOT NULL DEFAULT 0,
    active_users bigint NOT NULL DEFAULT 0,
    feeds_added bigint NOT NULL DEFAULT 0,
    entries_discovered bigint NOT NULL DEFAULT 0,
    fetch_success bigint NOT NULL DEFAULT 0,
    fetch_failure bigint NOT NULL DEFAULT 0
);

INSERT INTO instance_settings (key, value) VALUES
    ('registration_mode', '"closed"'::jsonb),
    ('explore_enabled', 'false'::jsonb),
    ('public_status_enabled', 'true'::jsonb),
    ('default_theme', '"system"'::jsonb),
    ('analytics_mode', '"builtin"'::jsonb)
ON CONFLICT (key) DO NOTHING;
