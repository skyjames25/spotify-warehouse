-- SPOTIFY STAR SCHEMA - DDL
-- Purpose: Dimensional model for Spotify chart analysis

-- Drop existing tables (if re-running)
DROP TABLE IF EXISTS fact_chart_rankings CASCADE;
DROP TABLE IF EXISTS dim_tracks CASCADE;
DROP TABLE IF EXISTS dim_artists CASCADE;
DROP TABLE IF EXISTS dim_date CASCADE;

-- DIMENSION TABLES
CREATE TABLE dim_date (
    date_key INTEGER PRIMARY KEY,
    full_date DATE NOT NULL,
    chart_date DATE NOT NULL,
    year INTEGER NOT NULL,
    month INTEGER NOT NULL,
    quarter INTEGER NOT NULL,
    day INTEGER NOT NULL,
    day_of_week INTEGER NOT NULL,
    month_name VARCHAR(20) NOT NULL,
    day_name VARCHAR(20) NOT NULL
);

COMMENT ON TABLE dim_date IS 'Date dimension with calendar attributes';

CREATE TABLE dim_artists (
    artist_sk BIGINT PRIMARY KEY,
    artist_name VARCHAR(255) NOT NULL
);

COMMENT ON TABLE dim_artists IS 'Artist dimension - one row per unique artist';

CREATE TABLE dim_tracks (
    track_sk BIGINT PRIMARY KEY,
    uri VARCHAR(255),
    track_name VARCHAR(500),
    source VARCHAR(100)
);

COMMENT ON TABLE dim_tracks IS 'Track dimension - one row per unique track';


-- Fact table: Daily chart rankings at track-artist grain
CREATE TABLE fact_chart_rankings (
    ranking_sk BIGINT PRIMARY KEY,
    track_sk BIGINT NOT NULL,
    artist_sk BIGINT NOT NULL,
    date_key INTEGER NOT NULL,
    rank INTEGER,
    streams BIGINT,
    previous_rank INTEGER,
    peak_rank INTEGER,
    days_on_chart INTEGER,
    
    CONSTRAINT fk_track 
        FOREIGN KEY (track_sk) 
        REFERENCES dim_tracks(track_sk)
        ON DELETE RESTRICT
        ON UPDATE RESTRICT,
    
    CONSTRAINT fk_artist 
        FOREIGN KEY (artist_sk) 
        REFERENCES dim_artists(artist_sk)
        ON DELETE RESTRICT
        ON UPDATE RESTRICT,
    
    CONSTRAINT fk_date 
        FOREIGN KEY (date_key) 
        REFERENCES dim_date(date_key)
        ON DELETE RESTRICT
        ON UPDATE RESTRICT,
    
    CONSTRAINT chk_rank_positive CHECK (rank > 0),
    CONSTRAINT chk_streams_positive CHECK (streams >= 0),
    CONSTRAINT chk_peak_rank_valid CHECK (peak_rank > 0)
);


-- INDEXES
-- Dimension indexes
CREATE INDEX idx_date_full_date ON dim_date(full_date);
CREATE INDEX idx_date_year_month ON dim_date(year, month);
CREATE INDEX idx_date_quarter ON dim_date(year, quarter);

CREATE INDEX idx_artist_name ON dim_artists(artist_name);

CREATE INDEX idx_track_name ON dim_tracks(track_name);
CREATE INDEX idx_track_uri ON dim_tracks(uri);

-- Fact table indexes
CREATE INDEX idx_fact_track_sk ON fact_chart_rankings(track_sk);
CREATE INDEX idx_fact_artist_sk ON fact_chart_rankings(artist_sk);
CREATE INDEX idx_fact_date_key ON fact_chart_rankings(date_key);
CREATE INDEX idx_fact_rank ON fact_chart_rankings(rank);
CREATE INDEX idx_fact_streams ON fact_chart_rankings(streams DESC);
CREATE INDEX idx_fact_peak_rank ON fact_chart_rankings(peak_rank);

-- Composite indexes
CREATE INDEX idx_fact_artist_date ON fact_chart_rankings(artist_sk, date_key);
CREATE INDEX idx_fact_track_date ON fact_chart_rankings(track_sk, date_key);
CREATE INDEX idx_fact_date_rank ON fact_chart_rankings(date_key, rank);
CREATE INDEX idx_fact_artist_perf ON fact_chart_rankings(artist_sk, date_key, streams, rank);

-- UPDATE STATISTICS
ANALYZE dim_date;
ANALYZE dim_artists;
ANALYZE dim_tracks;
ANALYZE fact_chart_rankings;