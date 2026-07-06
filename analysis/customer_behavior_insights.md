# Customer Behavior Insights

This is a short supplement to the Style Finder project. The main project recommends outfits, while this report looks more directly at customer behavior: spending, repeat purchases, and cohort retention.

The analysis uses SQL for the heavy aggregation and Python to format the final report.

Important note: the H&M `price` field is normalized, so I describe spending as **normalized spend** instead of real currency.

## Repeat Purchase Behavior

- Total customers analyzed: 1,362,281
- Repeat customers: 1,230,767
- Repeat customer rate: 90.3%
- Average purchases per customer: 23.33
- Median purchases per customer: 9.00
- Average active months per customer: 4.57

The repeat purchase rate is high, which suggests the dataset is not just one-off shopping. There is enough repeated customer behavior to make segmentation and quiz-based recommendations more meaningful.

## Spending Segments

I split customers into four equal-sized groups based on total normalized spend.

- Lowest spend segment average purchases: 2.21
- Highest spend segment average purchases: 68.23
- Lowest spend segment average normalized spend: 0.0486
- Highest spend segment average normalized spend: 1.9661
- Highest spend segment average active months: 10.67

The highest-spend customers are not only buying higher-value baskets. They also purchase more often and stay active across more months.

## Cohort Retention

I grouped customers by their first purchase month and measured how many came back in later months.

- Average month 1 retention across cohorts: 18.14%
- Full cohort results are saved in `analysis/cohort_retention.csv`.

Cohort retention is useful because it shows return behavior over time, instead of only giving one overall repeat-purchase number.

## Main Takeaway

This supplement supports the main Style Finder project because it shows that the dataset has real customer behavior patterns. Customers differ by spending level, repeat behavior, and retention, which makes the quiz more interesting than simply recommending the most popular products overall.
