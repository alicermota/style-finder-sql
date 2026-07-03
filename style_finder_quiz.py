#!/usr/bin/env python3
"""Play the Style Finder outfit quiz from the terminal.

The game uses PostgreSQL for the recommendation step. It queries the
precomputed materialized view from sql/06_game_support.sql, ranks matching
products with SQL window functions, and prints a complete outfit.
"""

from __future__ import annotations

import csv
import html
from pathlib import Path
import shutil
import subprocess
import sys
from dataclasses import dataclass
from io import StringIO


DB_NAME = "fashion_sql_project"
LATEST_OUTFIT_FILE = Path("latest_outfit.html")


@dataclass(frozen=True)
class Option:
    label: str
    value: str
    note: str


QUESTIONS: list[tuple[str, list[Option]]] = [
    (
        "What is your age group?",
        [
            Option("16-24", "16-24", "Gen Z / young trend behavior"),
            Option("25-34", "25-34", "young adult customer behavior"),
            Option("35-44", "35-44", "adult customer behavior"),
            Option("45+", "45+", "mature customer behavior"),
        ],
    ),
    (
        "How do you usually shop?",
        [
            Option("Mostly online", "mostly_online", "uses sales_channel_id = 2"),
            Option("Mostly in store", "mostly_store", "uses sales_channel_id = 1"),
            Option("No preference", "no_preference", "keeps both sales channels"),
        ],
    ),
    (
        "What style vibe do you want?",
        [
            Option("Casual basics", "casual_basics", "T-shirts, tops, trousers, sneakers"),
            Option("Polished", "polished", "blazers, shirts, dresses, bags, pumps"),
            Option("Statement/trendy", "statement_trendy", "patterns, jewelry, trend-led pieces"),
            Option("Cozy", "cozy", "knitwear, hoodies, coats, boots, scarves"),
        ],
    ),
    (
        "What color palette do you prefer?",
        [
            Option("Neutral/dark", "neutral_dark", "black, white, grey, beige"),
            Option("Soft/light", "soft_light", "white, light pink, light blue, light beige"),
            Option("Colorful", "colorful", "red, pink, yellow, green, orange, purple"),
            Option("Denim/blue", "denim_blue", "blue tones and denim-related items"),
        ],
    ),
    (
        "What season are you dressing for?",
        [
            Option("Spring/summer", "spring_summer", "transactions from March-August"),
            Option("Autumn/winter", "autumn_winter", "transactions from September-February"),
            Option("All year", "all_year", "keeps both seasons"),
        ],
    ),
    (
        "What price range do you prefer?",
        [
            Option("Budget", "budget", "bottom third of normalized prices"),
            Option("Mid-range", "mid_range", "middle third of normalized prices"),
            Option("Premium", "premium", "top third of normalized prices"),
        ],
    ),
]


def run_psql(sql: str) -> str:
    if shutil.which("psql") is None:
        sys.exit("Could not find psql. Install PostgreSQL or add psql to your PATH.")

    result = subprocess.run(
        ["psql", "-h", "localhost", "-d", DB_NAME, "-X", "-q", "-v", "ON_ERROR_STOP=1"],
        input=sql,
        text=True,
        capture_output=True,
        check=False,
    )
    if result.returncode != 0:
        sys.exit(
            "PostgreSQL query failed.\n\n"
            f"{result.stderr}\n"
            "Tip: run this setup command first:\n"
            "psql -h localhost -d fashion_sql_project -f sql/06_game_support.sql"
        )
    return result.stdout


def check_setup() -> None:
    sql = """
    SELECT to_regclass('public.style_finder_item_segments') IS NOT NULL AS exists;
    """
    output = run_psql(sql)
    if "t" not in output:
        sys.exit(
            "The game support view does not exist yet.\n"
            "Run this once first:\n"
            "psql -h localhost -d fashion_sql_project -f sql/06_game_support.sql"
        )


def ask_question(prompt: str, options: list[Option]) -> Option:
    print(f"\n{prompt}")
    for index, option in enumerate(options, start=1):
        print(f"  {index}. {option.label} - {option.note}")

    while True:
        answer = input("Choose a number: ").strip()
        if answer.isdigit() and 1 <= int(answer) <= len(options):
            return options[int(answer) - 1]
        print("Please type one of the numbers above.")


def recommendation_sql(answers: dict[str, str]) -> str:
    return f"""
COPY (
WITH quiz_answers AS (
    SELECT
        '{answers["age_group"]}'::text AS age_group,
        '{answers["shopping_style"]}'::text AS shopping_style,
        '{answers["style_vibe"]}'::text AS style_vibe,
        '{answers["color_palette"]}'::text AS color_palette,
        '{answers["season"]}'::text AS season,
        '{answers["price_band"]}'::text AS price_band
),
matched_items AS (
    SELECT
        s.outfit_slot,
        s.article_id,
        s.prod_name,
        s.product_type_name,
        s.garment_group_name,
        s.colour_group_name,
        s.detail_desc,
        s.image_path,
        SUM(s.purchase_count) AS purchase_count
    FROM style_finder_item_segments s
    CROSS JOIN quiz_answers q
    WHERE s.age_group = q.age_group
      AND (q.shopping_style = 'no_preference' OR s.shopping_style = q.shopping_style)
      AND (s.outfit_slot = 'accessory' OR s.style_vibe = q.style_vibe)
      AND s.color_palette = q.color_palette
      AND (q.season = 'all_year' OR s.season = q.season)
      AND s.price_band = q.price_band
    GROUP BY
        s.outfit_slot,
        s.article_id,
        s.prod_name,
        s.product_type_name,
        s.garment_group_name,
        s.colour_group_name,
        s.detail_desc,
        s.image_path
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY outfit_slot
            ORDER BY purchase_count DESC
        ) AS slot_rank
    FROM matched_items
),
best_slots AS (
    SELECT *
    FROM ranked
    WHERE slot_rank = 1
),
outfit_type AS (
    SELECT
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
)
SELECT
    o.inferred_outfit_type,
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
CROSS JOIN outfit_type o
WHERE
    (o.inferred_outfit_type = 'dress_outfit' AND b.outfit_slot IN ('dress', 'accessory', 'shoes'))
    OR (o.inferred_outfit_type = 'top_bottom_outfit' AND b.outfit_slot IN ('top', 'bottom', 'accessory', 'shoes'))
ORDER BY
    CASE b.outfit_slot
        WHEN 'dress' THEN 1
        WHEN 'top' THEN 1
        WHEN 'bottom' THEN 2
        WHEN 'accessory' THEN 3
        WHEN 'shoes' THEN 4
    END
) TO STDOUT WITH CSV HEADER;
"""


def fetch_outfit(answers: dict[str, str]) -> list[dict[str, str]]:
    output = run_psql(recommendation_sql(answers))
    rows = list(csv.DictReader(StringIO(output)))
    return rows


def print_outfit(rows: list[dict[str, str]], answers: dict[str, str]) -> None:
    if not rows:
        print("\nNo exact outfit found for that combination.")
        print("Try a broader choice like no preference, neutral/dark, or mid-range.")
        return

    outfit_type = rows[0]["inferred_outfit_type"].replace("_", " ")
    total_support = sum(int(row["purchase_count"]) for row in rows)

    print("\n" + "=" * 64)
    print("YOUR STYLE FINDER RESULT")
    print("=" * 64)
    print(f"Outfit type inferred by SQL: {outfit_type}")
    print(
        "Quiz path: "
        f"{answers['age_group']} | {answers['shopping_style']} | "
        f"{answers['style_vibe']} | {answers['color_palette']} | "
        f"{answers['season']} | {answers['price_band']}"
    )
    print(f"Purchase support across chosen pieces: {total_support:,}")

    for row in rows:
        print("\n" + row["outfit_slot"].upper())
        print(f"  Product: {row['prod_name']}")
        print(f"  Type: {row['product_type_name']} | {row['garment_group_name']}")
        print(f"  Color: {row['colour_group_name']}")
        print(f"  Article ID: {row['article_id']}")
        print(f"  Matching purchases: {int(row['purchase_count']):,}")
        local_image_path = Path("assets") / row["image_path"]
        if local_image_path.exists():
            print(f"  Image downloaded: {local_image_path}")
        else:
            print(f"  Future image path: {local_image_path}")
        if row["detail_desc"]:
            print(f"  Description: {row['detail_desc'][:180]}")

    print("\nSQL concept shown:")
    print("  CTEs + joins + CASE categories + GROUP BY + window ranking + outfit inference")


def write_outfit_html(rows: list[dict[str, str]], answers: dict[str, str]) -> Path | None:
    if not rows:
        return None

    outfit_type = rows[0]["inferred_outfit_type"].replace("_", " ")
    total_support = sum(int(row["purchase_count"]) for row in rows)
    quiz_path = (
        f"{answers['age_group']} | {answers['shopping_style']} | "
        f"{answers['style_vibe']} | {answers['color_palette']} | "
        f"{answers['season']} | {answers['price_band']}"
    )

    cards = []
    for row in rows:
        local_image_path = Path("assets") / row["image_path"]
        if local_image_path.exists():
            media = (
                f'<img src="{html.escape(local_image_path.as_posix())}" '
                f'alt="{html.escape(row["prod_name"])}">'
            )
        else:
            media = (
                '<div class="missing">'
                '<span>Image not downloaded yet</span>'
                f'<small>{html.escape(local_image_path.as_posix())}</small>'
                '</div>'
            )

        cards.append(
            f"""
            <article class="card">
                {media}
                <div class="content">
                    <p class="slot">{html.escape(row["outfit_slot"])}</p>
                    <h2>{html.escape(row["prod_name"])}</h2>
                    <p class="meta">{html.escape(row["product_type_name"])} / {html.escape(row["garment_group_name"])}</p>
                    <p class="meta">{html.escape(row["colour_group_name"])} / article {html.escape(row["article_id"])}</p>
                    <p class="support">{int(row["purchase_count"]):,} matching purchases</p>
                    <p class="desc">{html.escape(row["detail_desc"] or "")}</p>
                </div>
            </article>
            """
        )

    page = f"""<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Your Style Finder Outfit</title>
    <style>
        :root {{
            color-scheme: light;
            --paper: #f8f4ef;
            --ink: #1f1d1b;
            --muted: #706a63;
            --line: #ddd3c7;
            --card: #fffdf9;
            --accent: #8d4637;
        }}
        * {{ box-sizing: border-box; }}
        body {{
            margin: 0;
            font-family: Arial, Helvetica, sans-serif;
            background: var(--paper);
            color: var(--ink);
        }}
        header {{
            max-width: 1180px;
            margin: 0 auto;
            padding: 36px 20px 20px;
        }}
        h1 {{
            margin: 0 0 10px;
            font-size: clamp(32px, 6vw, 58px);
            line-height: 1;
        }}
        .summary {{
            color: var(--muted);
            max-width: 760px;
            line-height: 1.5;
        }}
        .grid {{
            max-width: 1180px;
            margin: 0 auto;
            padding: 20px;
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
            gap: 18px;
        }}
        .card {{
            background: var(--card);
            border: 1px solid var(--line);
            border-radius: 8px;
            overflow: hidden;
        }}
        img, .missing {{
            width: 100%;
            aspect-ratio: 3 / 4;
            object-fit: cover;
            background: #e7ded3;
            display: grid;
            place-items: center;
            text-align: center;
            color: var(--muted);
            padding: 16px;
        }}
        .missing small {{
            display: block;
            margin-top: 8px;
            overflow-wrap: anywhere;
        }}
        .content {{ padding: 14px; }}
        .slot {{
            margin: 0 0 8px;
            text-transform: uppercase;
            font-size: 12px;
            font-weight: 700;
            color: var(--accent);
        }}
        h2 {{
            margin: 0 0 8px;
            font-size: 20px;
            line-height: 1.15;
        }}
        p {{ margin: 0; }}
        .meta, .desc {{
            color: var(--muted);
            line-height: 1.35;
            margin-top: 6px;
        }}
        .support {{
            margin-top: 10px;
            font-weight: 700;
        }}
    </style>
</head>
<body>
    <header>
        <h1>Your Style Finder Outfit</h1>
        <p class="summary">
            Outfit type inferred by SQL: <strong>{html.escape(outfit_type)}</strong><br>
            Quiz path: {html.escape(quiz_path)}<br>
            Purchase support across chosen pieces: {total_support:,}
        </p>
    </header>
    <main class="grid">
        {''.join(cards)}
    </main>
</body>
</html>
"""
    LATEST_OUTFIT_FILE.write_text(page)
    return LATEST_OUTFIT_FILE


def open_file(path: Path) -> None:
    subprocess.run(["open", str(path.resolve())], check=False)


def download_images(rows: list[dict[str, str]]) -> None:
    kaggle_cli = Path(".venv/bin/kaggle")
    kaggle_command = str(kaggle_cli) if kaggle_cli.exists() else shutil.which("kaggle")
    if not kaggle_command:
        print("\nCould not find the Kaggle CLI, so images were not downloaded.")
        return

    print("\nChecking outfit images...")
    for row in rows:
        local_image_path = Path("assets") / row["image_path"]
        if local_image_path.exists():
            print(f"  Already downloaded: {local_image_path}")
            continue

        local_image_path.parent.mkdir(parents=True, exist_ok=True)
        result = subprocess.run(
            [
                kaggle_command,
                "competitions",
                "download",
                "-c",
                "h-and-m-personalized-fashion-recommendations",
                "-f",
                row["image_path"],
                "-p",
                str(local_image_path.parent),
            ],
            text=True,
            capture_output=True,
            check=False,
        )
        if result.returncode == 0:
            print(f"  Downloaded: {local_image_path}")
        else:
            print(f"  Could not download {row['image_path']}: {result.stderr.strip()}")


def main() -> None:
    print("STYLE FINDER")
    print("A SQL-powered fashion outfit quiz using the H&M dataset.")
    print("Images are optional; this version shows product details and future image paths.")

    check_setup()

    answer_keys = [
        "age_group",
        "shopping_style",
        "style_vibe",
        "color_palette",
        "season",
        "price_band",
    ]
    answers: dict[str, str] = {}

    for key, (question, options) in zip(answer_keys, QUESTIONS):
        chosen = ask_question(question, options)
        answers[key] = chosen.value

    if "--show-sql" in sys.argv:
        print("\nSQL recommendation query generated from your answers:")
        print(recommendation_sql(answers))

    print("\nRunning SQL recommendation query...")
    rows = fetch_outfit(answers)
    if "--download-images" in sys.argv:
        download_images(rows)
    print_outfit(rows, answers)
    html_file = write_outfit_html(rows, answers)
    if html_file:
        print(f"\nOutfit image page: {html_file.resolve()}")
        if "--open" in sys.argv:
            open_file(html_file)


if __name__ == "__main__":
    main()
