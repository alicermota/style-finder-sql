-- Style Finder: recommendation logic
-- Purpose: rank popular products by style vibe and keep image-ready article paths.

\o results/top_items_by_style_vibe.csv
COPY (
WITH price_thresholds AS (
    SELECT
        percentile_cont(0.333) WITHIN GROUP (ORDER BY price) AS budget_max,
        percentile_cont(0.667) WITHIN GROUP (ORDER BY price) AS midrange_max
    FROM transactions
),
article_popularity AS (
    SELECT
        t.article_id,
        COUNT(*) AS purchase_count,
        AVG(t.price) AS avg_price
    FROM transactions t
    GROUP BY t.article_id
),
scored_items AS (
    SELECT
        CASE
            WHEN a.garment_group_name IN ('Jersey Basic', 'Trousers Denim')
              OR a.product_type_name IN ('T-shirt', 'Vest top', 'Top', 'Trousers', 'Sneakers')
                THEN 'casual_basics'
            WHEN a.garment_group_name IN ('Blouses', 'Shirts', 'Dressed')
              OR a.product_type_name IN ('Blouse', 'Shirt', 'Blazer', 'Dress', 'Pumps', 'Ballerinas', 'Bag', 'Belt')
                THEN 'polished'
            WHEN a.garment_group_name IN ('Knitwear', 'Outdoor')
              OR a.product_type_name IN ('Sweater', 'Hoodie', 'Cardigan', 'Coat', 'Boots', 'Scarf', 'Hat/beanie')
                THEN 'cozy'
            ELSE 'statement_trendy'
        END AS style_vibe,
        CASE
            WHEN ap.avg_price <= p.budget_max THEN 'budget'
            WHEN ap.avg_price <= p.midrange_max THEN 'mid_range'
            ELSE 'premium'
        END AS price_band,
        a.product_group_name,
        a.article_id,
        a.prod_name,
        a.product_type_name,
        a.garment_group_name,
        a.colour_group_name,
        CONCAT('images/', SUBSTRING(a.article_id FROM 1 FOR 3), '/', a.article_id, '.jpg') AS image_path,
        ap.purchase_count
    FROM article_popularity ap
    JOIN articles a
        ON ap.article_id = a.article_id
    CROSS JOIN price_thresholds p
    WHERE a.product_group_name IN ('Garment Upper body', 'Garment Lower body', 'Garment Full body', 'Accessories', 'Shoes')
),
ranked_items AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY style_vibe, product_group_name
            ORDER BY purchase_count DESC
        ) AS item_rank
    FROM scored_items
)
SELECT
    style_vibe,
    product_group_name,
    article_id,
    prod_name,
    product_type_name,
    garment_group_name,
    colour_group_name,
    price_band,
    image_path,
    purchase_count
FROM ranked_items
WHERE item_rank <= 10
ORDER BY style_vibe, product_group_name, purchase_count DESC
) TO STDOUT WITH CSV HEADER;
\o
