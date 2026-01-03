-- Step 1: Count how many artists are credited on each track
-- This is needed to split streams fairly among collaborators
WITH track_artist_counts AS (
    SELECT
        track_sk,
        COUNT(DISTINCT artist_sk) as num_artists
    FROM fact_chart_rankings
    GROUP BY track_sk
),
-- Step 2: Calculate total streams per artist
-- Key insight: Divide streams by number of artists on the track
-- Example: If "Stay" has 10M streams and 2 artists (Bieber & LAROI),
--          each artist gets credit for 5M streams
artist_totals AS (
    SELECT
        a.artist_name,
        COUNT(DISTINCT f.track_sk) as unique_tracks,
        -- Proportional attribution prevents double-counting
        -- This matches how Spotify calculates royalty payments
        SUM(f.streams / tac.num_artists) as total_streams,
        MIN(f.rank) as best_position
    FROM fact_chart_rankings f
    JOIN dim_artists a ON f.artist_sk = a.artist_sk
    JOIN track_artist_counts tac ON f.track_sk = tac.track_sk
    GROUP BY a.artist_name
),
-- Step 3: Calculate market share percentage
-- Uses window function to get total across all artists
market_share AS (
    SELECT
        artist_name,
        unique_tracks,
        ROUND(total_streams, 0) as total_streams,
        best_position,
        ROUND(100.0 * total_streams / SUM(total_streams) OVER (), 10) as market_share_pct
    FROM artist_totals
)
-- Step 4: Final output sorted by dominance
SELECT
    artist_name,
    unique_tracks,
    total_streams,
    best_position,
    market_share_pct,
    SUM(market_share_pct) OVER () as total_pct
FROM market_share
ORDER BY total_streams DESC;