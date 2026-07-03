# Style Finder: SQL Outfit Quiz

## Project Summary

Style Finder is a beginner-friendly but portfolio-ready SQL project. It uses real H&M purchase data to power a small fashion quiz that recommends an outfit from customer behavior.

This is not an advanced machine learning recommender. It is a SQL-first recommendation project that demonstrates data modeling, analysis, segmentation, ranking, and a simple Python interface.

## Overview

Style Finder is a SQL portfolio project built with the H&M Personalized Fashion Recommendations dataset. Instead of only reporting generic fashion statistics, the project turns customer and product data into a quiz-style outfit recommendation.

The quiz asks about age, shopping style, style vibe, color palette, season, and price preference. SQL then finds products bought by similar customers and recommends either:

- a top, bottom, accessory, and shoes
- or a dress, accessory, and shoes

The outfit type is inferred from the data, so the user is not directly asked whether they want a dress.

## Dataset

Source: H&M Personalized Fashion Recommendations dataset from Kaggle.

Raw Kaggle files are not included in this repo because they are large. See `DATA_SETUP.md` to recreate the database locally.

Imported tables:

- `articles`: product details
- `customers`: customer attributes
- `transactions`: purchase history

Expected row counts:

- `articles`: 105,542
- `customers`: 1,371,980
- `transactions`: 31,788,324

## Quiz Logic

The quiz uses 6 questions:

1. Age group: `16-24`, `25-34`, `35-44`, `45+`
2. Shopping style: `mostly_online`, `mostly_store`, `no_preference`
3. Style vibe: `casual_basics`, `polished`, `statement_trendy`, `cozy`
4. Color palette: `neutral_dark`, `soft_light`, `colorful`, `denim_blue`
5. Season: `spring_summer`, `autumn_winter`, `all_year`
6. Price preference: `budget`, `mid_range`, `premium`

The H&M price column is normalized, so the project uses relative price bands rather than real currency.

## Files

- `style_finder_quiz.py`: playable Python terminal quiz powered by PostgreSQL.
- `make_outfit_gallery.py`: creates a simple HTML gallery from sample outfit results.
- `DATA_SETUP.md`: explains how to download/import the Kaggle data.
- `sql/01_quiz_option_analysis.sql`: checks purchase volume behind each quiz answer.
- `sql/02_price_bands.sql`: calculates relative price bands.
- `sql/03_recommendation_logic.sql`: ranks products by style vibe and popularity.
- `sql/04_sample_outfit_paths.sql`: generates complete outfit recommendations for sample quiz personas.
- `sql/05_age_channel_price_items.sql`: compares top product types by age, channel, and price band.
- `sql/06_game_support.sql`: creates the materialized view used by the Python quiz.
- `results/`: exported CSV outputs.
- `insights.md`: plain-English conclusions from the result files.

## Image-Ready Setup

This version does not require product images, but it is ready for them later.

Each outfit result includes an `image_path` such as:

```text
images/010/0108775015.jpg
```

After downloading the Kaggle image folder, place it here:

```text
assets/images/
```

A future app can display each item by combining:

```text
assets/ + image_path
```

Example:

```text
assets/images/010/0108775015.jpg
```

## SQL Skills Shown

- joins across customer, transaction, and product tables
- grouped analysis with `COUNT`
- date logic with transaction months
- percentile-based price bands
- `CASE` statements for quiz answer mapping
- window functions for ranking recommended products
- CSV exports for portfolio-ready outputs

## How To Re-run

From the project folder, run:

```bash
psql -h localhost -d fashion_sql_project -f sql/01_quiz_option_analysis.sql
psql -h localhost -d fashion_sql_project -f sql/02_price_bands.sql
psql -h localhost -d fashion_sql_project -f sql/03_recommendation_logic.sql
psql -h localhost -d fashion_sql_project -f sql/04_sample_outfit_paths.sql
psql -h localhost -d fashion_sql_project -f sql/05_age_channel_price_items.sql
```

You can also open each SQL file in DBeaver to study the logic.

## Play The Quiz Game

The project includes a simple terminal game:

```bash
python3 style_finder_quiz.py
```

Before playing for the first time, build the SQL support view:

```bash
psql -h localhost -d fashion_sql_project -f sql/06_game_support.sql
```

The game asks the 6 quiz questions, runs a PostgreSQL recommendation query, and prints a complete outfit. It does not need images, but each item includes a future image path like:

```text
assets/images/071/0714828001.jpg
```

The game showcases SQL proficiency because the recommendation uses:

- joins across customers, transactions, and articles
- CTEs
- CASE statements for quiz categories
- percentile-based price bands
- GROUP BY purchase counts
- ROW_NUMBER window ranking
- automatic outfit type inference

To print the generated recommendation SQL while playing, run:

```bash
python3 style_finder_quiz.py --show-sql
```

To download the images for the outfit you get, run:

```bash
python3 style_finder_quiz.py --download-images
```

To generate and automatically open an image page for your outfit, run:

```bash
python3 style_finder_quiz.py --download-images --open
```

If you want both:

```bash
python3 style_finder_quiz.py --show-sql --download-images --open
```
