# Style Finder Insights

## Main Idea

This project uses SQL to turn fashion purchase data into a quiz-style outfit recommendation. The goal is not just to find the most popular products, but to connect customer traits and style preferences to a practical outfit result.

## Key Conclusions

1. Every quiz answer has enough purchase volume to support recommendations. For example, the dataset includes 22.4M online purchases and 9.4M store purchases.
2. Neutral and dark colors dominate the data with 19.8M matching purchases, which suggests H&M customer behavior is strongly driven by wearable everyday palettes.
3. Style preferences are not evenly distributed: `statement_trendy` has the most matching purchases, followed by `casual_basics`, `polished`, and `cozy`.
4. The relative price bands are usable for recommendations: budget has 11.7M transactions, mid-range has 9.5M, and premium has 10.6M.
5. The generated sample outfits show that SQL can turn raw purchase data into a user-facing fashion result, not only a static report.

## How To Read The Outfit Results

Open `results/sample_outfits.csv`.

Each `quiz_persona` represents one possible quiz result. The file shows:

- the inferred outfit type
- each outfit slot
- the recommended product
- the color and garment group
- the relative price band
- the future image path
- the purchase count supporting that recommendation

Example result:

- `Gen Z colorful online trend seeker` produced a dress outfit with a red midi dress, pink sunglasses, and pink heeled sandals.
- `Polished neutral city shopper` produced a top-bottom outfit with a black blazer, black trousers, a black tote bag, and black pumps.
- `Soft casual everyday outfit` produced a light casual outfit with an off-white strap top, white trousers, a beige shopper bag, and white sneakers.

## Portfolio Conclusion

Style Finder shows how SQL can support a more creative product idea: a fashion quiz that recommends outfits from real customer behavior. The recommendation is still simple, but it demonstrates a realistic path from raw data to a user-facing feature that could later become a small web app.
