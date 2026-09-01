# Final Project — Big Data & Data Mining

**The University of Texas at Austin**
**Course:** Big Data & Data Mining
**Instructor:** Dr. Kia Teymourian

| Student | EID |
|---|---|
| Hannia Ashley Alvarado Galván | `ha26947` |
| Santiago Basaldúa Ramírez | `sb74887` |

---

## Project: Credit Card Customer Behavior Analysis
### Hypothesis Testing + K-Means Clustering

### Research Question
> *"Do distinct patterns of credit card usage carry statistically measurable differences, and can we identify natural customer profiles through clustering?"*

---

## Repository Contents

| File | Description |
|---|---|
| `presentation.Rmd` | R Markdown source code for the Beamer presentation (19 slides, 16:9) |
| `presentation.pdf` | Compiled PDF presentation |
| `report.tex` | Full technical report in LaTeX |
| `report.pdf` | Compiled technical report (11 pages) |
| `executive_summary.tex` | One-page executive summary in LaTeX |
| `executive_summary.pdf` | Compiled one-page executive summary |
| `slide_explanations.md` | Slide-by-slide study guide with bilingual glossary |
| `CC_GENERAL.csv` | Dataset: 8,950 credit card customers, 18 variables |

---

## Methods Used

- **Data Wrangling:** `dplyr` (filter, mutate, group_by, summarise)
- **Hypothesis 1:** Welch's two-sample *t*-test — `t.test(var.equal = FALSE)`
- **Hypothesis 2:** Pearson correlation — `cor.test(method = "pearson")`
- **Clustering:** K-Means — `kmeans(centers = 5, nstart = 25)`
- **Visualization:** Base R (`hist`, `boxplot`, `plot`, `image`)
- **Presentation:** R Markdown → Beamer PDF (LaTeX)

---

## Results Summary

| | Result |
|---|---|
| **H1** (Heavy CA → Higher Balance) | ✅ **Confirmed** — *p* ≪ 0.05, *t* ≈ 28 |
| **H2** (Balance → Credit Limit) | ❌ **Debunked** — *r* ≈ 0.54, *r²* ≈ 29% only |
| **Clustering** (K = 5) | 5 interpretable customer profiles found |

### 5 Customer Profiles
1. **Low-Activity Customers** (~34%) — Minimal card use
2. **Regular Purchasers** (~26%) — Frequent purchases, responsible payers
3. **Full-Payment Customers** (~18%) — Pay in full, lowest debt
4. **High Cash-Advance Users** (~20%) — Highest financial risk
5. **High-Value Customers** (~1.3%) — Elite spenders, high credit limit

---

## Key Lesson
> Statistical significance (*p*-value) ≠ Practical relevance (*r²*, effect size).
> With *n* = 8,636, even moderate correlations achieve *p* < 0.05.
> **Always report effect size alongside the p-value.**

---

*Dataset: CC GENERAL — Kaggle Credit Card Customer Segmentation*
