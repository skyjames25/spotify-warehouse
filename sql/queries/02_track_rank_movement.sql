-- Track Rank Changes(Current date vs Previous Date)
SELECT
    t.track_name,
    a.artist_name,
    d.full_date as date,
    f.rank as current_rank,
    -- LAG retrieves the rank from the previous row
    -- PARTITION BY f.track_sk ensures we compare the SAME track across days
    -- ORDER BY d.full_date ensures chronological comparison
    LAG(f.rank) OVER (PARTITION BY f.track_sk ORDER BY d.full_date) as previous_rank,
    -- Rank change calculation (negated for intuitive interpretation)
    -(f.rank - LAG(f.rank) OVER (PARTITION BY f.track_sk ORDER BY d.full_date)) as rank_change
FROM fact_chart_rankings f
JOIN dim_tracks t ON f.track_sk = t.track_sk
JOIN dim_artists a ON f.artist_sk = a.artist_sk
JOIN dim_date d ON f.date_key = d.date_key
ORDER BY d.full_date DESC, f.rank
LIMIT 20;