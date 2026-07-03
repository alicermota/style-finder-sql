# Data Setup

This repo does not include the raw H&M Kaggle data because the files are large.

## 1. Download the Kaggle data

Dataset/competition:

```text
H&M Personalized Fashion Recommendations
https://www.kaggle.com/competitions/h-and-m-personalized-fashion-recommendations
```

Required CSV files:

```text
articles.csv
customers.csv
transactions_train.csv
```

Place those files in the project root.

## 2. Create the PostgreSQL database

```bash
createdb fashion_sql_project
```

## 3. Import the CSV files

The important detail is that product and customer IDs must be imported as text, not numbers.

Use the table definitions you created locally, or recreate the same tables in PostgreSQL:

```sql
CREATE TABLE articles (
    article_id VARCHAR(20),
    product_code VARCHAR(20),
    prod_name VARCHAR(255),
    product_type_no INTEGER,
    product_type_name VARCHAR(255),
    product_group_name VARCHAR(255),
    graphical_appearance_no INTEGER,
    graphical_appearance_name VARCHAR(255),
    colour_group_code VARCHAR(20),
    colour_group_name VARCHAR(255),
    perceived_colour_value_id INTEGER,
    perceived_colour_value_name VARCHAR(255),
    perceived_colour_master_id INTEGER,
    perceived_colour_master_name VARCHAR(255),
    department_no INTEGER,
    department_name VARCHAR(255),
    index_code VARCHAR(20),
    index_name VARCHAR(255),
    index_group_no INTEGER,
    index_group_name VARCHAR(255),
    section_no INTEGER,
    section_name VARCHAR(255),
    garment_group_no INTEGER,
    garment_group_name VARCHAR(255),
    detail_desc TEXT
);

CREATE TABLE customers (
    customer_id VARCHAR(80),
    fn NUMERIC(3,1),
    active NUMERIC(3,1),
    club_member_status VARCHAR(50),
    fashion_news_frequency VARCHAR(50),
    age INTEGER,
    postal_code VARCHAR(80)
);

CREATE TABLE transactions (
    t_dat DATE,
    customer_id VARCHAR(80),
    article_id VARCHAR(20),
    price NUMERIC(20,18),
    sales_channel_id INTEGER
);
```

Then import:

```sql
\copy articles FROM 'articles.csv' WITH (FORMAT csv, HEADER true, NULL '', ENCODING 'UTF8');
\copy customers FROM 'customers.csv' WITH (FORMAT csv, HEADER true, NULL '', ENCODING 'UTF8');
\copy transactions FROM 'transactions_train.csv' WITH (FORMAT csv, HEADER true, NULL '', ENCODING 'UTF8');
```

## 4. Build the quiz support view

```bash
psql -h localhost -d fashion_sql_project -f sql/06_game_support.sql
```

## 5. Play the quiz

```bash
python3 style_finder_quiz.py
```

To download images for the quiz result:

```bash
python3 style_finder_quiz.py --download-images --open
```

