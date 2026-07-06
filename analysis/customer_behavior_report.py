#!/usr/bin/env python3
"""Generate a short customer behavior insights report.

PostgreSQL does the analysis in sql/07_customer_behavior_analysis.sql.
Python runs that SQL script, reads the exported CSVs, and formats a short
Markdown report for the portfolio.
"""

from __future__ import annotations

import csv
import subprocess
import sys
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
OUTPUT_DIR = PROJECT_ROOT / "analysis"
DB_NAME = "fashion_sql_project"


def run_sql_exports() -> None:
    result = subprocess.run(
        [
            "psql",
            "-h",
            "localhost",
            "-d",
            DB_NAME,
            "-v",
            "ON_ERROR_STOP=1",
            "-f",
            "sql/07_customer_behavior_analysis.sql",
        ],
        cwd=PROJECT_ROOT,
        text=True,
        capture_output=True,
        check=False,
    )
    if result.returncode != 0:
        sys.exit(f"SQL export failed:\n{result.stderr}")


def read_csv(name: str) -> list[dict[str, str]]:
    with (OUTPUT_DIR / name).open(newline="") as file:
        return list(csv.DictReader(file))


def pct(value: str) -> str:
    return f"{float(value):.1f}%"


def normalized(value: str) -> str:
    return f"{float(value):.4f}"


def main() -> None:
    OUTPUT_DIR.mkdir(exist_ok=True)
    run_sql_exports()

    spending_rows = read_csv("customer_spending_segments.csv")
    retention_rows = read_csv("customer_retention_summary.csv")
    cohort_rows = read_csv("cohort_retention.csv")

    retention = retention_rows[0]
    lowest = spending_rows[0]
    highest = spending_rows[-1]

    month_1_values = [
        float(row["retention_pct"])
        for row in cohort_rows
        if row["months_since_first_purchase"] == "1"
    ]
    avg_month_1_retention = sum(month_1_values) / len(month_1_values)

    report = f"""# Customer Behavior Insights

This is a short supplement to the Style Finder project. The main project recommends outfits, while this report looks more directly at customer behavior: spending, repeat purchases, and cohort retention.

The analysis uses SQL for the heavy aggregation and Python to format the final report.

Important note: the H&M `price` field is normalized, so I describe spending as **normalized spend** instead of real currency.

## Repeat Purchase Behavior

- Total customers analyzed: {int(retention["total_customers"]):,}
- Repeat customers: {int(retention["repeat_customers"]):,}
- Repeat customer rate: {pct(retention["repeat_customer_pct"])}
- Average purchases per customer: {float(retention["avg_purchase_count"]):.2f}
- Median purchases per customer: {float(retention["median_purchase_count"]):.2f}
- Average active months per customer: {float(retention["avg_active_months"]):.2f}

The repeat purchase rate is high, which suggests the dataset is not just one-off shopping. There is enough repeated customer behavior to make segmentation and quiz-based recommendations more meaningful.

## Spending Segments

I split customers into four equal-sized groups based on total normalized spend.

- Lowest spend segment average purchases: {float(lowest["avg_purchase_count"]):.2f}
- Highest spend segment average purchases: {float(highest["avg_purchase_count"]):.2f}
- Lowest spend segment average normalized spend: {normalized(lowest["avg_total_normalized_spend"])}
- Highest spend segment average normalized spend: {normalized(highest["avg_total_normalized_spend"])}
- Highest spend segment average active months: {float(highest["avg_active_months"]):.2f}

The highest-spend customers are not only buying higher-value baskets. They also purchase more often and stay active across more months.

## Cohort Retention

I grouped customers by their first purchase month and measured how many came back in later months.

- Average month 1 retention across cohorts: {avg_month_1_retention:.2f}%
- Full cohort results are saved in `analysis/cohort_retention.csv`.

Cohort retention is useful because it shows return behavior over time, instead of only giving one overall repeat-purchase number.

## Main Takeaway

This supplement supports the main Style Finder project because it shows that the dataset has real customer behavior patterns. Customers differ by spending level, repeat behavior, and retention, which makes the quiz more interesting than simply recommending the most popular products overall.
"""

    (OUTPUT_DIR / "customer_behavior_insights.md").write_text(report)

    print("Wrote customer behavior supplement:")
    print("- analysis/customer_behavior_insights.md")
    print("- analysis/customer_spending_segments.csv")
    print("- analysis/customer_retention_summary.csv")
    print("- analysis/cohort_retention.csv")


if __name__ == "__main__":
    main()
