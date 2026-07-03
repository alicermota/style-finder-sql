-- Style Finder: age, channel, and price analysis
-- Purpose: show how product choices change by customer age, shopping channel, and price preference.

\o results/top_items_by_age_channel_price.csv
COPY (
WITH price_thresholds AS (
    SELECT
        percentile_cont(0.333) WITHIN GROUP (ORDER BY price) AS budget_max,
        percentile_cont(0.667) WITHIN GROUP (ORDER BY price) AS midrange_max
    FROM transactions
),
grouped_items AS (
    SELECT
        CASE
            WHEN c.age BETWEEN 16 AND 24 THEN '16-24'
            WHEN c.age BETWEEN 25 AND 34 THEN '25-34'
            WHEN c.age BETWEEN 35 AND 44 THEN '35-44'
            WHEN c.age >= 45 THEN '45+'
            ELSE 'unknown'
        END AS age_group,
        CASE
            WHEN t.sales_channel_id = 1 THEN 'mostly_store'
            WHEN t.sales_channel_id = 2 THEN 'mostly_online'
            ELSE 'unknown'
        END AS shopping_style,
        CASE
            WHEN t.price <= p.budget_max THEN 'budget'
            WHEN t.price <= p.midrange_max THEN 'mid_range'
            ELSE 'premium'
        END AS price_band,
        a.product_group_name,
        a.product_type_name,
        COUNT(*) AS purchase_count
    FROM transactions t
    JOIN customers c
        ON t.customer_id = c.customer_id
    JOIN articles a
        ON t.article_id = a.article_id
    CROSS JOIN price_thresholds p
    WHERE a.product_group_name IN ('Garment Upper body', 'Garment Lower body', 'Garment Full body', 'Accessories', 'Shoes')
    GROUP BY age_group, shopping_style, price_band, a.product_group_name, a.product_type_name
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY age_group, shopping_style, price_band
            ORDER BY purchase_count DESC
        ) AS item_rank
    FROM grouped_items
    WHERE age_group <> 'unknown' AND shopping_style <> 'unknown'
)
SELECT
    age_group,
    shopping_style,
    price_band,
    product_group_name,
    product_type_name,
    purchase_count
FROM ranked
WHERE item_rank <= 5
ORDER BY age_group, shopping_style, price_band, purchase_count DESC
) TO STDOUT WITH CSV HEADER;
\o
