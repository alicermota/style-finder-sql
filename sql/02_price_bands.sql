-- Style Finder: price band analysis
-- Purpose: calculate relative price bands because H&M prices are normalized, not real currency.

\o results/price_band_summary.csv
COPY (
WITH price_thresholds AS (
    SELECT
        percentile_cont(0.333) WITHIN GROUP (ORDER BY price) AS budget_max,
        percentile_cont(0.667) WITHIN GROUP (ORDER BY price) AS midrange_max
    FROM transactions
),
transaction_price_bands AS (
    SELECT
        CASE
            WHEN t.price <= p.budget_max THEN 'budget'
            WHEN t.price <= p.midrange_max THEN 'mid_range'
            ELSE 'premium'
        END AS price_band,
        t.price
    FROM transactions t
    CROSS JOIN price_thresholds p
)
SELECT
    price_band,
    COUNT(*) AS transaction_count,
    ROUND(MIN(price), 6) AS min_normalized_price,
    ROUND(AVG(price), 6) AS avg_normalized_price,
    ROUND(MAX(price), 6) AS max_normalized_price
FROM transaction_price_bands
GROUP BY price_band
ORDER BY
    CASE price_band
        WHEN 'budget' THEN 1
        WHEN 'mid_range' THEN 2
        WHEN 'premium' THEN 3
    END
) TO STDOUT WITH CSV HEADER;
\o
