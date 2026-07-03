-- Style Finder: quiz option analysis
-- Purpose: check that each quiz answer has enough real purchases behind it.

\o results/quiz_option_summary.csv
COPY (
WITH joined_sales AS (
    SELECT
        c.age,
        t.sales_channel_id,
        EXTRACT(MONTH FROM t.t_dat) AS purchase_month,
        a.garment_group_name,
        a.product_type_name,
        a.graphical_appearance_name,
        a.colour_group_name,
        a.perceived_colour_master_name,
        t.price
    FROM transactions t
    JOIN customers c
        ON t.customer_id = c.customer_id
    JOIN articles a
        ON t.article_id = a.article_id
),
price_thresholds AS (
    SELECT
        percentile_cont(0.333) WITHIN GROUP (ORDER BY price) AS budget_max,
        percentile_cont(0.667) WITHIN GROUP (ORDER BY price) AS midrange_max
    FROM transactions
)
SELECT 'age_group' AS quiz_question, '16-24' AS answer_option, COUNT(*) AS purchase_count
FROM joined_sales
WHERE age BETWEEN 16 AND 24
UNION ALL
SELECT 'age_group', '25-34', COUNT(*) FROM joined_sales WHERE age BETWEEN 25 AND 34
UNION ALL
SELECT 'age_group', '35-44', COUNT(*) FROM joined_sales WHERE age BETWEEN 35 AND 44
UNION ALL
SELECT 'age_group', '45+', COUNT(*) FROM joined_sales WHERE age >= 45
UNION ALL
SELECT 'shopping_style', 'mostly_store', COUNT(*) FROM joined_sales WHERE sales_channel_id = 1
UNION ALL
SELECT 'shopping_style', 'mostly_online', COUNT(*) FROM joined_sales WHERE sales_channel_id = 2
UNION ALL
SELECT 'style_vibe', 'casual_basics', COUNT(*)
FROM joined_sales
WHERE garment_group_name IN ('Jersey Basic', 'Trousers Denim')
   OR product_type_name IN ('T-shirt', 'Vest top', 'Top', 'Trousers', 'Sneakers')
UNION ALL
SELECT 'style_vibe', 'polished', COUNT(*)
FROM joined_sales
WHERE garment_group_name IN ('Blouses', 'Shirts', 'Dressed')
   OR product_type_name IN ('Blouse', 'Shirt', 'Blazer', 'Dress', 'Pumps', 'Ballerinas', 'Bag', 'Belt')
UNION ALL
SELECT 'style_vibe', 'statement_trendy', COUNT(*)
FROM joined_sales
WHERE garment_group_name IN ('Jersey Fancy', 'Accessories')
   OR graphical_appearance_name NOT IN ('Solid', 'All over pattern')
   OR product_type_name IN ('Earring', 'Necklace', 'Ring', 'Heeled sandals', 'Skirt')
UNION ALL
SELECT 'style_vibe', 'cozy', COUNT(*)
FROM joined_sales
WHERE garment_group_name IN ('Knitwear', 'Outdoor')
   OR product_type_name IN ('Sweater', 'Hoodie', 'Cardigan', 'Coat', 'Boots', 'Scarf', 'Hat/beanie')
UNION ALL
SELECT 'color_palette', 'neutral_dark', COUNT(*)
FROM joined_sales
WHERE colour_group_name IN ('Black', 'Dark Grey', 'Grey', 'White', 'Off White', 'Beige', 'Dark Beige')
   OR perceived_colour_master_name IN ('Black', 'White', 'Grey', 'Beige')
UNION ALL
SELECT 'color_palette', 'soft_light', COUNT(*)
FROM joined_sales
WHERE perceived_colour_master_name IN ('Pink', 'Lilac Purple', 'Beige', 'White')
   OR colour_group_name IN ('Light Pink', 'Light Beige', 'Light Blue', 'Light Grey', 'White')
UNION ALL
SELECT 'color_palette', 'colorful', COUNT(*)
FROM joined_sales
WHERE perceived_colour_master_name IN ('Red', 'Pink', 'Yellow', 'Green', 'Orange', 'Purple', 'Turquoise')
UNION ALL
SELECT 'color_palette', 'denim_blue', COUNT(*)
FROM joined_sales
WHERE perceived_colour_master_name = 'Blue'
   OR colour_group_name IN ('Blue', 'Light Blue', 'Dark Blue')
   OR garment_group_name = 'Trousers Denim'
UNION ALL
SELECT 'season', 'spring_summer', COUNT(*) FROM joined_sales WHERE purchase_month BETWEEN 3 AND 8
UNION ALL
SELECT 'season', 'autumn_winter', COUNT(*) FROM joined_sales WHERE purchase_month IN (9, 10, 11, 12, 1, 2)
UNION ALL
SELECT 'price_preference', 'budget', COUNT(*)
FROM joined_sales, price_thresholds
WHERE price <= budget_max
UNION ALL
SELECT 'price_preference', 'mid_range', COUNT(*)
FROM joined_sales, price_thresholds
WHERE price > budget_max AND price <= midrange_max
UNION ALL
SELECT 'price_preference', 'premium', COUNT(*)
FROM joined_sales, price_thresholds
WHERE price > midrange_max
ORDER BY quiz_question, purchase_count DESC
) TO STDOUT WITH CSV HEADER;
\o
