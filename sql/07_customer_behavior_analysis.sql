-- Customer behavior supplement
-- Purpose: analyze normalized spending, repeat purchase behavior, and cohort retention.

CREATE TEMP TABLE customer_summary AS
SELECT
    customer_id,
    COUNT(*) AS purchase_count,
    SUM(price) AS total_normalized_spend,
    AVG(price) AS avg_item_price,
    MIN(t_dat) AS first_purchase_date,
    MAX(t_dat) AS last_purchase_date,
    COUNT(DISTINCT DATE_TRUNC('month', t_dat)) AS active_months
FROM transactions
GROUP BY customer_id;

CREATE INDEX customer_summary_customer_idx
    ON customer_summary (customer_id);

\o analysis/customer_spending_segments.csv
COPY (
WITH segmented AS (
    SELECT
        *,
        NTILE(4) OVER (ORDER BY total_normalized_spend) AS spend_quartile
    FROM customer_summary
)
SELECT
    CASE spend_quartile
        WHEN 1 THEN 'lowest_spend'
        WHEN 2 THEN 'lower_mid_spend'
        WHEN 3 THEN 'upper_mid_spend'
        WHEN 4 THEN 'highest_spend'
    END AS spend_segment,
    COUNT(*) AS customer_count,
    ROUND(AVG(purchase_count), 2) AS avg_purchase_count,
    ROUND(AVG(total_normalized_spend), 4) AS avg_total_normalized_spend,
    ROUND(MIN(total_normalized_spend), 4) AS min_total_normalized_spend,
    ROUND(MAX(total_normalized_spend), 4) AS max_total_normalized_spend,
    ROUND(AVG(avg_item_price), 4) AS avg_item_price,
    ROUND(AVG(active_months), 2) AS avg_active_months,
    ROUND(AVG(last_purchase_date - first_purchase_date), 1) AS avg_days_between_first_and_last_purchase
FROM segmented
GROUP BY spend_quartile
ORDER BY spend_quartile
) TO STDOUT WITH CSV HEADER;
\o

\o analysis/customer_retention_summary.csv
COPY (
SELECT
    COUNT(*) AS total_customers,
    COUNT(*) FILTER (WHERE purchase_count > 1) AS repeat_customers,
    ROUND(100.0 * COUNT(*) FILTER (WHERE purchase_count > 1) / COUNT(*), 2) AS repeat_customer_pct,
    ROUND(AVG(purchase_count), 2) AS avg_purchase_count,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY purchase_count)::numeric, 2) AS median_purchase_count,
    ROUND(AVG(total_normalized_spend), 4) AS avg_total_normalized_spend,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_normalized_spend)::numeric, 4) AS median_total_normalized_spend,
    ROUND(AVG(active_months), 2) AS avg_active_months,
    ROUND(AVG(last_purchase_date - first_purchase_date), 1) AS avg_days_between_first_and_last_purchase
FROM customer_summary
) TO STDOUT WITH CSV HEADER;
\o

CREATE TEMP TABLE monthly_activity AS
SELECT DISTINCT
    customer_id,
    DATE_TRUNC('month', t_dat)::date AS activity_month
FROM transactions;

CREATE INDEX monthly_activity_customer_idx
    ON monthly_activity (customer_id);

\o analysis/cohort_retention.csv
COPY (
WITH first_purchase AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', first_purchase_date)::date AS cohort_month
    FROM customer_summary
),
cohort_activity AS (
    SELECT
        f.cohort_month,
        (
            (EXTRACT(YEAR FROM a.activity_month) - EXTRACT(YEAR FROM f.cohort_month)) * 12
            + (EXTRACT(MONTH FROM a.activity_month) - EXTRACT(MONTH FROM f.cohort_month))
        )::int AS months_since_first_purchase,
        COUNT(DISTINCT a.customer_id) AS active_customers
    FROM first_purchase f
    JOIN monthly_activity a
        ON f.customer_id = a.customer_id
    GROUP BY f.cohort_month, months_since_first_purchase
),
cohort_sizes AS (
    SELECT
        cohort_month,
        active_customers AS cohort_size
    FROM cohort_activity
    WHERE months_since_first_purchase = 0
)
SELECT
    c.cohort_month,
    c.months_since_first_purchase,
    s.cohort_size,
    c.active_customers,
    ROUND(100.0 * c.active_customers / s.cohort_size, 2) AS retention_pct
FROM cohort_activity c
JOIN cohort_sizes s
    ON c.cohort_month = s.cohort_month
WHERE c.months_since_first_purchase BETWEEN 0 AND 6
ORDER BY c.cohort_month, c.months_since_first_purchase
) TO STDOUT WITH CSV HEADER;
\o
