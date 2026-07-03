-- Style Finder: sample outfit paths
-- Purpose: generate complete outfits for example quiz personas.

\o results/sample_outfits.csv
COPY (
WITH personas AS (
    SELECT *
    FROM (
        VALUES
            ('Gen Z colorful online trend seeker', '16-24', 'mostly_online', 'statement_trendy', 'colorful', 'spring_summer', 'mid_range'),
            ('Polished neutral city shopper', '25-34', 'mostly_store', 'polished', 'neutral_dark', 'all_year', 'premium'),
            ('Cozy budget winter basics', '35-44', 'mostly_online', 'cozy', 'neutral_dark', 'autumn_winter', 'budget'),
            ('Soft casual everyday outfit', '25-34', 'no_preference', 'casual_basics', 'soft_light', 'spring_summer', 'mid_range')
    ) AS p(quiz_persona, age_group, shopping_style, style_vibe, color_palette, season, price_preference)
),
price_thresholds AS (
    SELECT
        percentile_cont(0.333) WITHIN GROUP (ORDER BY price) AS budget_max,
        percentile_cont(0.667) WITHIN GROUP (ORDER BY price) AS midrange_max
    FROM transactions
),
matched_purchases AS (
    SELECT
        p.quiz_persona,
        p.age_group,
        p.shopping_style,
        p.style_vibe,
        p.color_palette,
        p.season,
        p.price_preference,
        CASE
            WHEN a.product_group_name = 'Garment Upper body' THEN 'top'
            WHEN a.product_group_name = 'Garment Lower body' THEN 'bottom'
            WHEN a.product_group_name = 'Garment Full body' AND a.product_type_name = 'Dress' THEN 'dress'
            WHEN a.product_group_name = 'Accessories' THEN 'accessory'
            WHEN a.product_group_name = 'Shoes' THEN 'shoes'
        END AS outfit_slot,
        a.article_id,
        a.prod_name,
        a.product_group_name,
        a.product_type_name,
        a.garment_group_name,
        a.colour_group_name,
        a.detail_desc,
        CONCAT('images/', SUBSTRING(a.article_id FROM 1 FOR 3), '/', a.article_id, '.jpg') AS image_path,
        COUNT(*) AS purchase_count
    FROM personas p
    JOIN transactions t
        ON TRUE
    JOIN customers c
        ON t.customer_id = c.customer_id
    JOIN articles a
        ON t.article_id = a.article_id
    CROSS JOIN price_thresholds pt
    WHERE
        CASE p.age_group
            WHEN '16-24' THEN c.age BETWEEN 16 AND 24
            WHEN '25-34' THEN c.age BETWEEN 25 AND 34
            WHEN '35-44' THEN c.age BETWEEN 35 AND 44
            WHEN '45+' THEN c.age >= 45
        END
        AND (
            p.shopping_style = 'no_preference'
            OR (p.shopping_style = 'mostly_store' AND t.sales_channel_id = 1)
            OR (p.shopping_style = 'mostly_online' AND t.sales_channel_id = 2)
        )
        AND (
            p.season = 'all_year'
            OR (p.season = 'spring_summer' AND EXTRACT(MONTH FROM t.t_dat) BETWEEN 3 AND 8)
            OR (p.season = 'autumn_winter' AND EXTRACT(MONTH FROM t.t_dat) IN (9, 10, 11, 12, 1, 2))
        )
        AND (
            (p.price_preference = 'budget' AND t.price <= pt.budget_max)
            OR (p.price_preference = 'mid_range' AND t.price > pt.budget_max AND t.price <= pt.midrange_max)
            OR (p.price_preference = 'premium' AND t.price > pt.midrange_max)
        )
        AND (
            a.product_group_name = 'Accessories'
            OR
            (p.style_vibe = 'casual_basics' AND (
                a.garment_group_name IN ('Jersey Basic', 'Trousers Denim')
                OR a.product_type_name IN ('T-shirt', 'Vest top', 'Top', 'Trousers', 'Sneakers')
            ))
            OR (p.style_vibe = 'polished' AND (
                a.garment_group_name IN ('Blouses', 'Shirts', 'Dressed')
                OR a.product_type_name IN ('Blouse', 'Shirt', 'Blazer', 'Dress', 'Pumps', 'Ballerinas', 'Bag', 'Belt')
            ))
            OR (p.style_vibe = 'statement_trendy' AND (
                a.garment_group_name IN ('Jersey Fancy', 'Accessories')
                OR a.graphical_appearance_name NOT IN ('Solid', 'All over pattern')
                OR a.product_type_name IN ('Earring', 'Necklace', 'Ring', 'Heeled sandals', 'Skirt')
            ))
            OR (p.style_vibe = 'cozy' AND (
                a.garment_group_name IN ('Knitwear', 'Outdoor')
                OR a.product_type_name IN ('Sweater', 'Hoodie', 'Cardigan', 'Coat', 'Boots', 'Scarf', 'Hat/beanie')
            ))
        )
        AND (
            (p.color_palette = 'neutral_dark' AND (
                a.colour_group_name IN ('Black', 'Dark Grey', 'Grey', 'White', 'Off White', 'Beige', 'Dark Beige')
                OR a.perceived_colour_master_name IN ('Black', 'White', 'Grey', 'Beige')
            ))
            OR (p.color_palette = 'soft_light' AND (
                a.perceived_colour_master_name IN ('Pink', 'Lilac Purple', 'Beige', 'White')
                OR a.colour_group_name IN ('Light Pink', 'Light Beige', 'Light Blue', 'Light Grey', 'White')
            ))
            OR (p.color_palette = 'colorful' AND a.perceived_colour_master_name IN ('Red', 'Pink', 'Yellow', 'Green', 'Orange', 'Purple', 'Turquoise'))
            OR (p.color_palette = 'denim_blue' AND (
                a.perceived_colour_master_name = 'Blue'
                OR a.colour_group_name IN ('Blue', 'Light Blue', 'Dark Blue')
                OR a.garment_group_name = 'Trousers Denim'
            ))
        )
        AND (
            a.product_group_name IN ('Garment Upper body', 'Garment Lower body', 'Accessories', 'Shoes')
            OR (a.product_group_name = 'Garment Full body' AND a.product_type_name = 'Dress')
        )
    GROUP BY
        p.quiz_persona,
        p.age_group,
        p.shopping_style,
        p.style_vibe,
        p.color_palette,
        p.season,
        p.price_preference,
        outfit_slot,
        a.article_id,
        a.prod_name,
        a.product_group_name,
        a.product_type_name,
        a.garment_group_name,
        a.colour_group_name,
        a.detail_desc
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY quiz_persona, outfit_slot
            ORDER BY purchase_count DESC
        ) AS slot_rank
    FROM matched_purchases
    WHERE outfit_slot IS NOT NULL
),
best_slots AS (
    SELECT *
    FROM ranked
    WHERE slot_rank = 1
),
outfit_type AS (
    SELECT
        quiz_persona,
        CASE
            WHEN COALESCE(MAX(purchase_count) FILTER (WHERE outfit_slot = 'dress'), 0)
               >= GREATEST(
                    COALESCE(MAX(purchase_count) FILTER (WHERE outfit_slot = 'top'), 0),
                    COALESCE(MAX(purchase_count) FILTER (WHERE outfit_slot = 'bottom'), 0)
               )
            THEN 'dress_outfit'
            ELSE 'top_bottom_outfit'
        END AS inferred_outfit_type
    FROM best_slots
    GROUP BY quiz_persona
)
SELECT
    b.quiz_persona,
    o.inferred_outfit_type,
    b.age_group,
    b.shopping_style,
    b.style_vibe,
    b.color_palette,
    b.season,
    b.price_preference AS price_band,
    b.outfit_slot,
    b.article_id,
    b.prod_name,
    b.product_type_name,
    b.garment_group_name,
    b.colour_group_name,
    b.detail_desc,
    b.image_path,
    b.purchase_count
FROM best_slots b
JOIN outfit_type o
    ON b.quiz_persona = o.quiz_persona
WHERE
    (o.inferred_outfit_type = 'dress_outfit' AND b.outfit_slot IN ('dress', 'accessory', 'shoes'))
    OR (o.inferred_outfit_type = 'top_bottom_outfit' AND b.outfit_slot IN ('top', 'bottom', 'accessory', 'shoes'))
ORDER BY
    b.quiz_persona,
    CASE b.outfit_slot
        WHEN 'dress' THEN 1
        WHEN 'top' THEN 1
        WHEN 'bottom' THEN 2
        WHEN 'accessory' THEN 3
        WHEN 'shoes' THEN 4
    END
) TO STDOUT WITH CSV HEADER;
\o
