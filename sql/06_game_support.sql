-- Style Finder: game support view
-- Purpose: precompute segmented item popularity so the Python quiz can run fast SQL recommendations.

DROP MATERIALIZED VIEW IF EXISTS style_finder_item_segments;

CREATE MATERIALIZED VIEW style_finder_item_segments AS
WITH price_thresholds AS (
    SELECT
        percentile_cont(0.333) WITHIN GROUP (ORDER BY price) AS budget_max,
        percentile_cont(0.667) WITHIN GROUP (ORDER BY price) AS midrange_max
    FROM transactions
),
enriched_purchases AS (
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
            WHEN EXTRACT(MONTH FROM t.t_dat) BETWEEN 3 AND 8 THEN 'spring_summer'
            ELSE 'autumn_winter'
        END AS season,
        CASE
            WHEN t.price <= p.budget_max THEN 'budget'
            WHEN t.price <= p.midrange_max THEN 'mid_range'
            ELSE 'premium'
        END AS price_band,
        CASE
            WHEN a.product_group_name = 'Garment Upper body' THEN 'top'
            WHEN a.product_group_name = 'Garment Lower body' THEN 'bottom'
            WHEN a.product_group_name = 'Garment Full body' AND a.product_type_name = 'Dress' THEN 'dress'
            WHEN a.product_group_name = 'Accessories' THEN 'accessory'
            WHEN a.product_group_name = 'Shoes' THEN 'shoes'
            ELSE 'other'
        END AS outfit_slot,
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
            WHEN a.perceived_colour_master_name = 'Blue'
              OR a.colour_group_name IN ('Blue', 'Light Blue', 'Dark Blue')
              OR a.garment_group_name = 'Trousers Denim'
                THEN 'denim_blue'
            WHEN a.colour_group_name IN ('Black', 'Dark Grey', 'Grey', 'White', 'Off White', 'Beige', 'Dark Beige')
              OR a.perceived_colour_master_name IN ('Black', 'White', 'Grey', 'Beige')
                THEN 'neutral_dark'
            WHEN a.perceived_colour_master_name IN ('Pink', 'Lilac Purple', 'Beige', 'White')
              OR a.colour_group_name IN ('Light Pink', 'Light Beige', 'Light Blue', 'Light Grey', 'White')
                THEN 'soft_light'
            WHEN a.perceived_colour_master_name IN ('Red', 'Pink', 'Yellow', 'Green', 'Orange', 'Purple', 'Turquoise')
                THEN 'colorful'
            ELSE 'other'
        END AS color_palette,
        a.article_id,
        a.prod_name,
        a.product_type_name,
        a.garment_group_name,
        a.colour_group_name,
        a.detail_desc,
        CONCAT('images/', SUBSTRING(a.article_id FROM 1 FOR 3), '/', a.article_id, '.jpg') AS image_path
    FROM transactions t
    JOIN customers c
        ON t.customer_id = c.customer_id
    JOIN articles a
        ON t.article_id = a.article_id
    CROSS JOIN price_thresholds p
    WHERE a.product_group_name IN ('Garment Upper body', 'Garment Lower body', 'Garment Full body', 'Accessories', 'Shoes')
)
SELECT
    age_group,
    shopping_style,
    season,
    price_band,
    outfit_slot,
    style_vibe,
    color_palette,
    article_id,
    prod_name,
    product_type_name,
    garment_group_name,
    colour_group_name,
    detail_desc,
    image_path,
    COUNT(*) AS purchase_count
FROM enriched_purchases
WHERE age_group <> 'unknown'
  AND shopping_style <> 'unknown'
  AND outfit_slot <> 'other'
GROUP BY
    age_group,
    shopping_style,
    season,
    price_band,
    outfit_slot,
    style_vibe,
    color_palette,
    article_id,
    prod_name,
    product_type_name,
    garment_group_name,
    colour_group_name,
    detail_desc,
    image_path;

CREATE INDEX style_finder_segments_lookup_idx
    ON style_finder_item_segments (
        age_group,
        shopping_style,
        season,
        price_band,
        style_vibe,
        color_palette,
        outfit_slot,
        purchase_count DESC
    );

CREATE INDEX style_finder_segments_article_idx
    ON style_finder_item_segments (article_id);
