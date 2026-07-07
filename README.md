# Style Finder: SQL-Powered Fashion Outfit Quiz

Individual SQL analytics project using the H&M Kaggle dataset to turn customer, transaction, and product data into recommendation-ready analytical views. The project demonstrates joins, CTEs, `CASE` logic, window functions, materialized views, customer behavior analysis, and a small Python terminal interface.

## Technical Summary

The SQL scripts profile quiz options, build price bands, rank products by customer/style segments, generate outfit paths, and create a materialized support view for the Python quiz. Supplementary SQL and Python outputs analyze repeat purchase behavior, normalized spending segments, active months, and cohort retention.

## Project Status

Portfolio-ready individual project. The raw H&M dataset is not committed because of size; setup instructions are documented in [`DATA_SETUP.md`](DATA_SETUP.md).

This is a SQL project I built using the H&M Personalized Fashion Recommendations dataset from Kaggle.

I wanted to make a project that was more interesting than just "top 10 products" or basic sales statistics, so I created a small fashion quiz that recommends an outfit based on a person's answers. The quiz uses real customer purchase data, product information, and SQL logic to suggest either:

- a top, bottom, accessory, and shoes
- or a dress, accessory, and shoes

The project is mainly focused on SQL, but I also added a simple Python terminal game so the analysis feels more interactive.

## Why I Built This

I'm interested in fashion, trends, and data, so I wanted to build a project that connected those things in a realistic way.

The goal was not to build a perfect recommendation system or an advanced machine learning model. Instead, I wanted to show that I can:

- work with a large real-world dataset
- design useful SQL queries
- join and analyze multiple tables
- turn data analysis into something more user-facing
- explain the logic behind the results

## Dataset

The project uses the H&M Personalized Fashion Recommendations dataset from Kaggle.

The original data includes:

- `articles.csv` - product information
- `customers.csv` - customer information
- `transactions_train.csv` - purchase history

The raw dataset is not included in this repository because the files are too large. Instructions for setting up the data locally are in `DATA_SETUP.md`.

## Project Idea

The quiz asks 6 questions:

1. What is your age group?
2. Do you usually shop online, in store, or both?
3. What style vibe do you want?
4. What color palette do you prefer?
5. What season are you dressing for?
6. What price range do you prefer?

Based on those answers, SQL filters and ranks products using real purchase behavior.

For example, if someone chooses:

```text
Age group: 16-24
Shopping style: mostly online
Style vibe: statement/trendy
Color palette: colorful
Season: spring/summer
Price range: mid-range
```

The project finds products that match that profile and recommends a full outfit.

## How The Recommendation Works

The recommendation is SQL-based.

I used:

- joins between customers, transactions, and products
- `CASE` statements to create quiz categories
- price percentiles to create budget, mid-range, and premium groups
- date logic to separate spring/summer and autumn/winter purchases
- `GROUP BY` to count purchases
- window functions like `ROW_NUMBER()` to rank items
- a materialized view to make the Python quiz faster

The outfit type is inferred by the SQL logic. The user is not directly asked if they want a dress. If a dress is the strongest full-body match, the result can be:

```text
dress + accessory + shoes
```

Otherwise, the result is:

```text
top + bottom + accessory + shoes
```

## Files In This Project

`style_finder_quiz.py`

A simple Python terminal quiz that asks questions and returns an outfit.

`make_outfit_gallery.py`

Creates an HTML gallery from sample outfit results.

`sql/`

Contains the SQL scripts used for analysis and recommendation logic.

`results/`

Contains smaller CSV outputs generated from the SQL analysis.

`insights.md`

A short written summary of the main conclusions.

`analysis/customer_behavior_insights.md`

A short SQL and Python supplement about customer spending, repeat purchases, and cohort retention.

`DATA_SETUP.md`

Instructions for downloading the Kaggle data and recreating the database.

## SQL Files

`sql/01_quiz_option_analysis.sql`

Checks whether each quiz option has enough purchase data behind it.

`sql/02_price_bands.sql`

Creates relative price bands because the H&M price column is normalized.

`sql/03_recommendation_logic.sql`

Ranks products by style category and popularity.

`sql/04_sample_outfit_paths.sql`

Generates sample outfit recommendations.

`sql/05_age_channel_price_items.sql`

Compares popular product types by age group, shopping channel, and price band.

`sql/06_game_support.sql`

Creates the materialized view used by the Python quiz.

`sql/07_customer_behavior_analysis.sql`

Exports the customer behavior analysis used in the supplemental report.

## Customer Behavior Supplement

I also added a short analysis report focused on customer spending and retention:

```text
analysis/customer_behavior_insights.md
```

This supplement looks at:

- repeat purchase rate
- normalized spending segments
- active months per customer
- monthly cohort retention

The SQL exports the analysis tables, and Python formats the final Markdown report:

```bash
python3 analysis/customer_behavior_report.py
```

## How To Run The Quiz

First, make sure the PostgreSQL database has been created and the Kaggle data has been imported.

Then build the support view:

```bash
psql -h localhost -d fashion_sql_project -f sql/06_game_support.sql
```

Run the quiz:

```bash
python3 style_finder_quiz.py
```

To show the SQL query while playing:

```bash
python3 style_finder_quiz.py --show-sql
```

To download product images for the outfit result:

```bash
python3 style_finder_quiz.py --download-images
```

To open an HTML page showing the outfit images:

```bash
python3 style_finder_quiz.py --download-images --open
```

## Example Output

The quiz returns an outfit with:

- outfit type
- product names
- product categories
- colors
- article IDs
- purchase counts
- product descriptions
- image paths

Example:

```text
TOP
Product: AK Deidre tee
Type: Polo shirt
Color: Light Green

BOTTOM
Product: Kevin skirt
Type: Skirt
Color: Red

ACCESSORY
Product: Ring
Type: Accessories

SHOES
Product: Espadrille
Type: Flat shoe
```

## Image Notes

The project does not include the full H&M image dataset because it is very large.

However, the project is image-ready. Each result includes an image path like:

```text
assets/images/078/0784472003.jpg
```

If images are downloaded from Kaggle, the quiz can display them in an HTML outfit page.

## What I Learned

This project helped me practice:

- importing and working with a large dataset
- choosing correct data types for IDs
- writing joins across multiple tables
- using CTEs to organize SQL logic
- creating categories with `CASE`
- using window functions for ranking
- using materialized views for performance
- connecting SQL analysis to a small Python interface
- presenting data results as a more interactive project

## Limitations

This is not a production recommendation system. It does not use machine learning or personal user history beyond the quiz answers.

The recommendations are based on matching quiz answers to purchase patterns in the dataset. This makes the project easier to understand and more focused on SQL skills.

## Main Takeaway

This project shows how SQL can be used for more than static reports. By combining customer behavior, product data, and ranking logic, I turned a large fashion dataset into a simple outfit recommendation quiz.
