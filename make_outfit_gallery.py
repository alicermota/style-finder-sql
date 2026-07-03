#!/usr/bin/env python3
"""Create a small HTML gallery from results/sample_outfits.csv."""

from __future__ import annotations

import csv
from collections import defaultdict
from pathlib import Path


PROJECT_DIR = Path(__file__).parent
RESULTS_FILE = PROJECT_DIR / "results" / "sample_outfits.csv"
OUTPUT_FILE = PROJECT_DIR / "outfit_gallery.html"


def main() -> None:
    outfits: dict[str, list[dict[str, str]]] = defaultdict(list)
    with RESULTS_FILE.open(newline="") as file:
        for row in csv.DictReader(file):
            outfits[row["quiz_persona"]].append(row)

    sections = []
    for persona, items in outfits.items():
        cards = []
        for item in items:
            image_path = Path("assets") / item["image_path"]
            image_html = (
                f'<img src="{image_path.as_posix()}" alt="{item["prod_name"]}">'
                if (PROJECT_DIR / image_path).exists()
                else '<div class="missing">Image missing</div>'
            )
            cards.append(
                f"""
                <article class="card">
                    {image_html}
                    <p class="slot">{item["outfit_slot"]}</p>
                    <h3>{item["prod_name"]}</h3>
                    <p>{item["product_type_name"]} · {item["colour_group_name"]}</p>
                    <p class="support">{int(item["purchase_count"]):,} matching purchases</p>
                </article>
                """
            )
        sections.append(
            f"""
            <section>
                <h2>{persona}</h2>
                <div class="grid">{''.join(cards)}</div>
            </section>
            """
        )

    html = f"""<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Style Finder Outfit Gallery</title>
    <style>
        body {{
            margin: 0;
            font-family: Arial, sans-serif;
            background: #f7f4ef;
            color: #1f1f1f;
        }}
        header, section {{
            max-width: 1100px;
            margin: 0 auto;
            padding: 32px 20px;
        }}
        h1, h2, h3, p {{
            margin: 0;
        }}
        h1 {{
            font-size: 36px;
            margin-bottom: 8px;
        }}
        h2 {{
            font-size: 24px;
            margin-bottom: 16px;
        }}
        .grid {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
            gap: 16px;
        }}
        .card {{
            background: #fff;
            border: 1px solid #ded8cf;
            border-radius: 8px;
            overflow: hidden;
        }}
        img, .missing {{
            width: 100%;
            aspect-ratio: 3 / 4;
            object-fit: cover;
            background: #e6e0d7;
        }}
        .missing {{
            display: grid;
            place-items: center;
            color: #6c665f;
        }}
        .card h3, .card p {{
            padding: 0 12px 10px;
        }}
        .slot {{
            padding-top: 12px;
            text-transform: uppercase;
            font-size: 12px;
            letter-spacing: .08em;
            color: #7a3e2f;
            font-weight: bold;
        }}
        .support {{
            color: #69635c;
            font-size: 14px;
        }}
    </style>
</head>
<body>
    <header>
        <h1>Style Finder Outfit Gallery</h1>
        <p>Sample SQL-generated outfits from the H&M dataset.</p>
    </header>
    {''.join(sections)}
</body>
</html>
"""
    OUTPUT_FILE.write_text(html)
    print(f"Wrote {OUTPUT_FILE}")


if __name__ == "__main__":
    main()
