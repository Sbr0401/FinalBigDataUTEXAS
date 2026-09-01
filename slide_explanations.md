# Slide-by-Slide Study Guide
### Credit Card Customer Behavior — Hypothesis Testing + Clustering Extension

---

> **How to use this guide**
> Each slide section has three parts:
> 1. 📋 **What the slide shows** — plain-language summary
> 2. 📖 **Key terms** — technical vocabulary with Spanish translations
> 3. 🎯 **Why we made this decision** — the reasoning behind every choice

---

## Official Variable Definitions (Dataset Reference)

All explanations in this guide are based on the following official definitions:

| Variable | Official Definition |
|---|---|
| `CUST_ID` | Identification of Credit Card holder (Categorical) |
| `BALANCE` | Balance amount left in their account to make purchases |
| `BALANCE_FREQUENCY` | How frequently the Balance is updated; score 0–1 (1 = frequently updated) |
| `PURCHASES` | Amount of purchases made from account |
| `ONEOFF_PURCHASES` | Maximum purchase amount done in one-go |
| `INSTALLMENTS_PURCHASES` | Amount of purchase done in installment |
| `CASH_ADVANCE` | Cash in advance given by the user |
| `PURCHASES_FREQUENCY` | How frequently purchases are being made; score 0–1 (1 = frequently purchased) |
| `ONEOFFPURCHASES_FREQUENCY` | How frequently purchases are happening in one-go; score 0–1 |
| `PURCHASES_INSTALLMENTS_FREQUENCY` | How frequently purchases in installments are being done; score 0–1 |
| `CASH_ADVANCE_FREQUENCY` | How frequently the cash in advance is being paid |
| `CASH_ADVANCE_TRX` | Number of transactions made with "Cash in Advanced" |
| `PURCHASES_TRX` | Number of purchase transactions made |
| `CREDIT_LIMIT` | Limit of Credit Card for user |
| `PAYMENTS` | Amount of Payment done by user |
| `MINIMUM_PAYMENTS` | Minimum amount of payments made by user |
| `PRCFULLPAYMENT` | Percent of full payment paid by user |
| `TENURE` | Tenure of credit card service for user |

---

## Slide 1 — Title Slide

### 📋 What it shows
The project title, author, and date. Nothing technical here — it sets up the context
for the audience.

### 📖 Key Terms
| English | Spanish | Meaning |
|---|---|---|
| Hypothesis Testing | Prueba de hipótesis | A formal statistical method to decide whether a claim about data is true or not |
| Clustering Extension | Extensión de agrupamiento | An additional analysis that groups data points by similarity |
| Data Analytics | Análisis de datos | The process of examining datasets to draw conclusions |

### 🎯 Why this structure?
The subtitle "Hypothesis Testing + Clustering Extension" immediately tells the audience
the project has **two distinct parts** — inferential statistics (confirmatory) and
unsupervised learning (exploratory). This separation is important: one part tests
specific claims with yes/no answers; the other discovers patterns without a
predefined goal.

---

## Slide 2 — Project Overview

### 📋 What it shows
A table comparing both parts of the project side by side, plus the research question
that motivates the whole analysis.

**Research Question:**
*Do distinct patterns of credit card usage carry statistically measurable differences,
and can we identify natural customer profiles through clustering?*

### 📖 Key Terms
| English | Spanish | Meaning |
|---|---|---|
| Research Question | Pregunta de investigación | The central question the entire project tries to answer |
| Significance Level α | Nivel de significancia α | The threshold we set to decide if a result is "statistically significant" (we chose α = 0.05, meaning we accept a 5% chance of being wrong) |
| Inferential Statistics | Estadística inferencial | Using a sample to draw conclusions about a larger population |
| Unsupervised Learning | Aprendizaje no supervisado | Finding patterns in data without predefined labels or categories |

### 🎯 Why α = 0.05?
This is the **standard convention** in social sciences and business analytics.
It means: "I will only reject the null hypothesis if the probability of seeing
this result by pure chance is less than 5%." It balances rigor and practicality —
0.01 would be too strict for behavioral data; 0.10 would be too permissive.

### 🎯 Why two parts?
Hypothesis testing can only answer questions you already have.
Clustering answers questions you haven't thought to ask yet.
Using both gives a **complete picture**: we confirm what we suspect (H1, H2)
and discover what we don't expect (5 customer profiles).

---

## Slide 3 — Data Wrangling with `dplyr`

### 📋 What it shows
The actual R code used to clean and prepare the data before any analysis.
Two key operations: filtering out missing values, and creating two new variables.

```r
cc_clean <- cc %>%
  filter(!is.na(CREDIT_LIMIT), !is.na(MINIMUM_PAYMENTS)) %>%
  mutate(
    CA_Group    = if_else(CASH_ADVANCE_FREQUENCY >= 0.25, "Heavy CA", "Light CA"),
    LOG_BALANCE = log1p(BALANCE)
  )
```

**Result:** 8,636 rows after cleaning (314 rows removed due to missing data).
**Groups:** 2,204 Heavy CA customers / 6,432 Light CA customers.

### 📖 Key Terms
| English | Spanish | Meaning |
|---|---|---|
| Data Wrangling | Limpieza y transformación de datos | The process of cleaning, restructuring, and enriching raw data |
| `filter()` | filtrar | Removes rows that don't meet a condition |
| `mutate()` | mutar / transformar | Adds new columns or modifies existing ones |
| `is.na()` | es nulo / es vacío | Checks if a value is missing (NA = Not Available) |
| `if_else()` | si/si no | Creates a category based on a condition |
| `log1p()` | logaritmo de (1 + x) | A mathematical transformation that compresses very large values |
| `%>%` (pipe) | tubo / encadenamiento | Passes the result of one operation into the next, like an assembly line |
| CASH_ADVANCE_FREQUENCY | Frecuencia de adelantos en efectivo | How frequently the cash in advance is being paid (0 = never, 1 = always) |

### 🎯 Why remove rows with missing CREDIT_LIMIT and MINIMUM_PAYMENTS?
These two variables are central to our analysis (H2 uses CREDIT_LIMIT; MINIMUM_PAYMENTS
is used in cluster profiling). A row with no credit limit cannot be classified properly.
We do **not** remove rows with missing values in other variables — we only remove
what is essential. This preserves as much data as possible.

### 🎯 Why the threshold 0.25 for "Heavy CA"?
A frequency of 0.25 means the customer used cash advances in at least 1 out of every
4 billing cycles. This is a meaningful behavioral threshold — occasional use vs.
habitual use. It is also consistent with the distribution in the data, where 0.25
is approximately the 75th percentile of CASH_ADVANCE_FREQUENCY.

### 🎯 Why create LOG_BALANCE?
BALANCE is very right-skewed (most customers have low balances, a few have extremely
high ones). The logarithm transformation compresses the scale so that the distribution
becomes closer to normal — which is required for valid t-tests and visual comparison.
`log1p(x)` = log(1 + x) is used instead of `log(x)` to safely handle zeros
(since log(0) is undefined).

---

## Slide 4 — Part 1: Hypothesis Testing Overview

### 📋 What it shows
A preview of both hypotheses — what we're testing, how we're testing it,
and what we expect to find before running any analysis.

| | H1 | H2 |
|--|--|--|
| Null (H₀) | Both groups have equal mean balance | No correlation between balance and credit limit |
| Alternative (H₁) | Heavy CA users have higher balance | Correlation exists (claimed to be strong) |
| What we expect | **Confirmed** | **Debunked** |

### 📖 Key Terms
| English | Spanish | Meaning |
|---|---|---|
| Null Hypothesis H₀ | Hipótesis nula | The "boring" default assumption — nothing is happening, no difference exists |
| Alternative Hypothesis H₁ | Hipótesis alternativa | What we actually believe or suspect is true |
| One-tailed test | Prueba de una cola | Tests if the difference goes in one specific direction (e.g., only "greater than") |
| Two-tailed test | Prueba de dos colas | Tests if there is any difference, in either direction |
| t-test | Prueba t | A test that compares the means of two groups |
| cor.test() | Prueba de correlación | A test that measures and evaluates the linear relationship between two variables |
| Debunk | Desmentir / refutar | To prove that a commonly accepted belief is false or misleading |

### 🎯 Why state expectations BEFORE running the tests?
This is called **pre-registration** in science. If you decide what you expect
*after* seeing the results, you risk unconsciously adjusting your interpretation
to fit the data. Stating expectations upfront makes the analysis honest and objective.

---

## Slide 5 — H1: Formal Statement

### 📋 What it shows
The mathematical formulation of Hypothesis 1 and the statistical test chosen.

$$H_0 : \mu_{\text{Heavy CA}} = \mu_{\text{Light CA}}$$
$$H_1 : \mu_{\text{Heavy CA}} > \mu_{\text{Light CA}} \quad \text{(one-tailed)}$$

The rationale: the correlation matrix already showed r(BALANCE, CASH_ADVANCE_FREQUENCY)
≈ 0.449 — a moderate positive relationship. This gives us prior evidence to
expect a real difference.

### 📖 Key Terms
| English | Spanish | Meaning |
|---|---|---|
| μ (mu) | Media poblacional | The true population mean (average) of a group |
| One-tailed | Una cola | We only care if Heavy CA > Light CA; not if Light CA > Heavy CA |
| Welch's t-test | Prueba t de Welch | A version of the t-test that does NOT assume both groups have equal variances — safer and more robust |
| `var.equal = FALSE` | varianzas desiguales | The R argument telling the t-test NOT to assume equal variances |
| Correlation matrix | Matriz de correlación | A table showing how strongly every pair of variables is related |
| Prior evidence | Evidencia previa | Existing clues from the data that support our hypothesis before testing it formally |

### 🎯 Why a one-tailed test here?
We have a **directional hypothesis** — we believe Heavy CA users have HIGHER balances,
not just DIFFERENT balances. A one-tailed test is more powerful (easier to detect
the effect) when you're confident about the direction. The prior correlation of 0.449
gives us that confidence.

### 🎯 Why Welch's t-test and not the standard t-test?
Standard t-tests assume both groups have the same variance (spread).
For credit card data with heavily skewed distributions, this assumption almost
certainly fails. Welch's test (`var.equal = FALSE`) relaxes this requirement —
it is the recommended default for any two-sample comparison in practice.

---

## Slide 6 — H1: Exploratory Plots

### 📋 What it shows
Two side-by-side charts that visually confirm what we expect before doing the math:

- **Left (Boxplot):** The Heavy CA group has a clearly higher median and wider spread
  of BALANCE values than the Light CA group.
- **Right (Histogram of log-BALANCE):** Both distributions are right-skewed even on
  the log scale, confirming the groups are non-normal — but the difference in location
  (where the peak is) is visible.

### 📖 Key Terms
| English | Spanish | Meaning |
|---|---|---|
| Boxplot | Diagrama de caja | Shows median, quartiles (IQR), and whiskers — a 5-number summary of a distribution |
| Median | Mediana | The middle value when all data points are sorted — more robust than the mean for skewed data |
| IQR (Interquartile Range) | Rango intercuartil | The range from the 25th to the 75th percentile — the "middle 50%" of the data |
| Histogram | Histograma | A bar chart that shows how frequently values fall in each range |
| Log-scale | Escala logarítmica | A transformation that compresses large values so distributions are easier to compare |
| Skewed distribution | Distribución sesgada | A distribution where most values are on one side and a long tail stretches to the other |

### 🎯 Why explore visually BEFORE running the test?
Exploratory plots serve two purposes:
1. **Sanity check** — if the boxplot showed NO visual difference, we would question
   our hypothesis and re-examine the data before running a test.
2. **Assumption check** — the histogram lets us see if the log-transformation
   worked and whether the distributions are approximately normal.

A test result without a supporting visual is difficult to trust or explain
to a non-technical audience.

---

## Slide 7 — H1: Welch's t-Test (Code + Results)

### 📋 What it shows
The actual R code and output of the t-test:

| Result | Value | Meaning |
|---|---|---|
| t = 32.319 | Very large | The difference between groups is 32 standard errors away from zero |
| df = 2889.6 | Large degrees of freedom | More data → more reliable estimate |
| p = 3.43e-196 | Essentially zero | The probability of seeing this result by chance is astronomically small |
| 95% CI lower bound | $1,775 | We are 95% confident Heavy CA users carry at least $1,775 more in balance |

### 📖 Key Terms
| English | Spanish | Meaning |
|---|---|---|
| t-statistic | Estadístico t | How many "standard errors" the observed difference is from zero — the larger, the stronger the evidence |
| p-value | Valor p | The probability of observing a result this extreme if H₀ were true — small p → reject H₀ |
| Degrees of freedom (df) | Grados de libertad | Roughly the effective sample size; larger = more reliable test |
| Confidence Interval (CI) | Intervalo de confianza | A range of values we are X% confident contains the true population parameter |
| 3.43e-196 | 3.43 × 10⁻¹⁹⁶ | A number so close to zero it has 195 zeros after the decimal point before the first significant digit |
| Standard error | Error estándar | How much the sample mean is expected to vary from the true population mean |

### 🎯 What does t = 32.319 really mean?
If there were truly NO difference between Heavy CA and Light CA users (H₀ is true),
getting a t-statistic this extreme would happen roughly 3.43 × 10⁻¹⁹⁶ of the time —
effectively never in the history of the universe. This is overwhelming evidence
against H₀.

### 🎯 What is the 95% CI lower bound ($1,775)?
A one-tailed 95% CI for a "greater than" test gives us a lower bound.
We are 95% confident that Heavy CA users carry **at least** $1,775 more in
average balance than Light CA users. The true difference is probably much larger
(the point estimate is around $2,000+), but $1,775 is the conservative floor.

---

## Slide 8 — H1: Decision & Interpretation

### 📋 What it shows
The formal decision and what it means in plain language.

- **t = 32.319, p = 3.43e-196 → REJECT H₀**
- Heavy CA users carry significantly higher balances — by thousands of dollars on average.

### 📖 Key Terms
| English | Spanish | Meaning |
|---|---|---|
| Reject H₀ | Rechazar la hipótesis nula | The data provides enough evidence to conclude H₀ is false |
| Fail to reject H₀ | No rechazar la hipótesis nula | The data does NOT provide enough evidence; we don't "accept" H₀, just can't disprove it |
| Statistical significance | Significancia estadística | A result is "statistically significant" if p < α (we chose α = 0.05) |
| Financial risk signal | Señal de riesgo financiero | A measurable variable that reliably predicts risky financial behavior |

### 🎯 Key insight: "Significant" ≠ "Important"
With a sample of 8,636 customers, even small differences would be statistically
significant. But here, the **effect is also large** — thousands of dollars difference
in average balance. This makes the result both statistically AND practically meaningful.

### 🎯 Real-world application:
A bank could use CASH_ADVANCE_FREQUENCY as an **early warning system**.
Customers who frequently take cash advances are accumulating significantly
higher debt — they could be flagged for credit counseling or monitored for
default risk before the situation becomes critical.

---

## Slide 9 — H2 (Debunk): The Intuitive Claim

### 📋 What it shows
The common belief we are testing — and planning to debunk:

> *"Customers with higher balances must have higher credit limits — the bank
> gave them more credit, so they use more of it."*

This feels logical, but our job is to test whether the data actually supports it.

### 📖 Key Terms
| English | Spanish | Meaning |
|---|---|---|
| Intuitive claim | Afirmación intuitiva | A belief that "feels" true based on common sense, not data |
| ρ (rho) | Coeficiente de correlación poblacional | The true correlation between two variables in the population (we estimate it with r from our sample) |
| Debunk | Desmentir / refutar | To show, using evidence, that a popular belief is incorrect or misleading |
| Three-prong strategy | Estrategia de tres ángulos | Attacking the claim from three different angles (statistical, visual, and distributional) |
| Pearson correlation | Correlación de Pearson | A measure of the linear relationship between two continuous variables; ranges from -1 to +1 |

### 🎯 Why is this hypothesis "two-tailed"?
For H2 we test whether any correlation exists (ρ ≠ 0) — we don't pre-specify
the direction. The claim is about "strong positive correlation," so if we find
a weak correlation (even if positive and significant), we can debunk the strength
of the claim.

### 🎯 Why three prongs?
A single number (like the correlation coefficient) can be misleading.
By adding:
1. A **visual** (scatterplot) to see if the relationship looks strong
2. An **outlier check** to see if a few extreme points are creating an illusion
3. A **distributional check** to see if assumptions are met

...we build a much more convincing debunk than just citing a p-value.

---

## Slide 10 — H2: Scatterplot & Distribution

### 📋 What it shows
Two charts:
- **Left (Scatterplot):** BALANCE vs. CREDIT_LIMIT — the points form a very
  wide cloud, not a tight line. The dashed regression line is nearly flat.
- **Right (Histogram):** BALANCE is extremely right-skewed — most customers
  have balances under $2,000, but a few have over $15,000.

### 📖 Key Terms
| English | Spanish | Meaning |
|---|---|---|
| Scatterplot | Diagrama de dispersión | A chart where each point represents one observation (customer); shows two variables simultaneously |
| Regression line | Línea de regresión | The "best fit" straight line through a scatterplot — shows the average trend |
| Wide cloud | Nube amplia | When points are spread far from the regression line → weak linear relationship |
| Right-skewed | Sesgado a la derecha | Most values cluster near zero/low values; a long tail extends toward large values |
| Normality assumption | Supuesto de normalidad | Some tests require the data to be normally distributed (bell-shaped) |

### 🎯 What does the wide point cloud tell us?
If BALANCE strongly predicted CREDIT_LIMIT, the scatterplot would show a narrow,
tight band of points along a diagonal line. Instead we see a **wide scatter** —
many customers with LOW balances have HIGH credit limits (they don't use them),
and many customers with HIGH balances have LOW credit limits (they're maxed out).
The visual alone suggests the relationship is weak.

### 🎯 Why also show the histogram?
The histogram reveals that BALANCE violates the **normality assumption** required
for Pearson correlation to be fully valid. When a distribution is this skewed,
the correlation coefficient r can be inflated by extreme values. This sets up
the outlier detection in the next slide.

---

## Slide 11 — H2: Outlier Detection

### 📋 What it shows
Two boxplots (BALANCE and CREDIT_LIMIT) showing the distribution with outliers
as individual points above the whiskers.

**Result:** 666 customers are classified as outliers in BALANCE using the IQR rule.

### 📖 Key Terms
| English | Spanish | Meaning |
|---|---|---|
| Outlier | Valor atípico / dato extremo | A data point that lies far from the rest of the distribution |
| IQR Rule | Regla del rango intercuartil | An outlier is defined as any point more than 1.5 × IQR above Q3 or below Q1 |
| Q1 / Q3 | Cuartil 1 / Cuartil 3 | The 25th and 75th percentiles — the boundaries of the "middle 50%" of data |
| Whisker | Bigote | The lines extending from a boxplot, usually to 1.5 × IQR from the box |
| Upper fence | Límite superior | Q3 + 1.5 × IQR — any point beyond this is an outlier |

### 🎯 Why detect outliers here?
Pearson's r is sensitive to outliers — a single extreme point can dramatically
increase or decrease the measured correlation. If 666 customers have unusually
high balances, they could create an **artificial correlation** with credit limit
(since banks might give higher limits to higher-income customers who happen
to also have higher balances). Detecting outliers helps us understand whether the
correlation we measure is real or distorted.

### 🎯 Do we remove the outliers?
**No.** We identify them to EXPLAIN the correlation, not to delete them.
Removing outliers arbitrarily would distort the analysis. Instead, we use this
information to caution the audience that the correlation r they'll see on the
next slide may be partially driven by these extreme cases.

---

## Slide 12 — H2: Pearson Correlation Test & Debunk

### 📋 What it shows
The actual test and its results:

| Metric | Value | Interpretation |
|---|---|---|
| r (Pearson) | 0.5355 | Moderate positive correlation |
| r² | 28.68% | BALANCE explains only 29% of CREDIT_LIMIT variance |
| p-value | ~0.00 | Statistically significant (but n is large!) |
| Is |r| < 0.35? | NO | The correlation EXISTS — but is it STRONG? |

The **debunk** is not that there's no correlation — it's that the correlation is
**not strong enough** to support the original claim of "BALANCE strongly predicts
CREDIT_LIMIT."

### 📖 Key Terms
| English | Spanish | Meaning |
|---|---|---|
| r (Pearson) | Coeficiente de correlación de Pearson | A number from -1 to +1 measuring linear association; 0 = none, ±1 = perfect |
| r² (R-squared) | Coeficiente de determinación | The proportion of variance in Y explained by X; r² = 0.29 means 71% of variation is unexplained |
| Variance explained | Varianza explicada | How much of the "wiggle" in one variable is accounted for by another |
| Large sample bias | Sesgo de muestra grande | With very large n, even trivial effects yield tiny p-values — p alone is not enough |
| Prospective | Prospectivo | Forward-looking; a bank sets the credit limit BEFORE the customer accumulates a balance |

### 🎯 Why is r = 0.54 considered "not strong enough"?
The original claim was that BALANCE *strongly* predicts CREDIT_LIMIT.
In behavioral science, r > 0.70 is considered strong. r ≈ 0.54 is moderate.
More importantly, **r² = 0.29** means 71% of what determines your credit limit
is NOT your balance — it's your income, credit history, payment record, etc.
So the intuitive claim ("banks gave them more credit, so they use more") is an
oversimplification at best and simply false at worst.

### 🎯 The key lesson: Statistical significance ≠ Practical strength
With n = 8,636, even r = 0.10 would give p < 0.05. The p-value tells you
the result is *real*, not random — but it does NOT tell you the effect is *large*.
Always look at r² (effect size), not just p-value.

---

## Slide 13 — Key Correlations Found

### 📋 What it shows
Three specific correlations highlighted from the matrix and explained:

1. **PURCHASES and PAYMENTS** r ≈ 0.60 → Spend more, pay more
2. **CASH_ADVANCE and BALANCE** r ≈ 0.50 → CA use accumulates debt
3. **PRC_FULL_PAYMENT and BALANCE** r ≈ -0.32 → Full payers carry less debt

### 📖 Key Terms
| English | Spanish | Meaning |
|---|---|---|
| Positive correlation | Correlación positiva | When one variable increases, the other tends to increase too |
| Negative correlation | Correlación negativa | When one variable increases, the other tends to decrease |
| Moderate correlation | Correlación moderada | Typically 0.30 < |r| < 0.70 — a real but not overwhelming relationship |
| Revolving debt | Deuda revolvente | Credit card debt that is carried from month to month (not paid in full) |
| ONEOFF_PURCHASES | Compras individuales (no recurrentes) | Large, one-time purchases on the credit card |

### 🎯 Why do PURCHASES and PAYMENTS correlate strongly?
High-spending customers tend to be financially active in both directions —
they spend more AND pay more. This group likely includes high-income customers
who use their card heavily but also manage their finances well. This insight
foreshadows the "Regular Purchasers" and "High-Value" clusters.

### 🎯 How does this help clustering?
These correlations tell us which variables contain unique information:
- PURCHASES and PAYMENTS are correlated → including both adds similar information
- CASH_ADVANCE has a different pattern → it captures a distinct behavioral dimension
- PRC_FULL_PAYMENT is negatively related to BALANCE → it adds yet another dimension

This confirms that our 8 selected variables cover different behavioral dimensions
without excessive redundancy.

---

## Slide 14 — Correlation Matrix

### 📋 What it shows
A color-coded heatmap of the correlations between the 8 clustering variables.
Blue = negative correlation, White = near zero, Orange/Brown = positive correlation.
Numbers inside each cell show the exact r value.

**Abbreviated variable names:**
| Abbreviation | Full Name |
|---|---|
| BAL | BALANCE |
| PURCH | PURCHASES |
| CA | CASH_ADVANCE |
| CL | CREDIT_LIMIT |
| PAY | PAYMENTS |
| PF | PURCHASES_FREQUENCY |
| CAF | CASH_ADVANCE_FREQUENCY |
| FULL | PRC_FULL_PAYMENT |

### 📖 Key Terms
| English | Spanish | Meaning |
|---|---|---|
| Heatmap | Mapa de calor | A grid where cells are colored by value — easier to spot patterns than reading raw numbers |
| Correlation matrix | Matriz de correlación | A square table where every cell (i,j) shows the correlation between variable i and variable j |
| Diagonal | Diagonal | Always 1.0 — every variable is perfectly correlated with itself |
| Redundancy | Redundancia | When two variables carry mostly the same information (r > 0.80) — using both in clustering is wasteful |

### 🎯 Why compute this before clustering?
K-Means works better when input variables are **not highly redundant**.
If two variables are nearly identical (r ≈ 0.90), including both would make
the algorithm "double-count" that dimension. The correlation matrix helps us
select a good, non-redundant set of variables.

### 🎯 Notable finding from the matrix:
PRC_FULL_PAYMENT and BALANCE have r ≈ -0.33 (negative). This makes intuitive
sense: customers who consistently pay their full balance don't accumulate revolving
debt. This relationship will later distinguish the "Full-Payment" cluster from others.

---

## Slide 15 — Part 2: Clustering Extension (Transition)

### 📋 What it shows
A conceptual bridge between the hypothesis testing section and the clustering analysis.

> The hypothesis tests answered questions we already had.
> Now we ask: *Can we find natural customer groups in the data?*

### 📖 Key Terms
| English | Spanish | Meaning |
|---|---|---|
| Unsupervised learning | Aprendizaje no supervisado | A type of analysis where you don't have predefined labels — the algorithm finds patterns on its own |
| Exploratory | Exploratorio | Analysis done without a specific hypothesis — you're "exploring" to see what the data reveals |
| Natural groups | Grupos naturales | Clusters that emerge from the data itself, not imposed by the analyst |
| Complement | Complemento | Something that adds to and enriches what was already done |

### 🎯 Why add clustering after hypothesis testing?
Hypothesis testing is **confirmatory** — you test what you already suspect.
Clustering is **exploratory** — you discover things you didn't know to look for.
Together they give a much richer picture:
- Hypotheses told us *specific* behavioral differences exist.
- Clustering tells us *what kinds* of customers exist overall.

---

## Slide 16 — EDA: Key Findings

### 📋 What it shows
A summary of key exploratory findings plus the BALANCE histogram, which serves as
the main visual example of the skewness pattern seen across all variables.

**Key findings:**
- 8,950 customers, 18 variables
- PURCHASES skewness = 8.14 → very heavily right-skewed
- CASH_ADVANCE skewness = 5.17 → heavily right-skewed
- BALANCE skewness = 2.39 → moderately right-skewed
- Mean > Median for almost all variables (a small group of high-activity customers
  pulls the mean upward)

### 📖 Key Terms
| English | Spanish | Meaning |
|---|---|---|
| EDA (Exploratory Data Analysis) | Análisis exploratorio de datos | The first step of any data project — summarizing and visualizing data before formal modeling |
| Skewness | Sesgo / asimetría | A measure of how asymmetric a distribution is; positive skew = long right tail |
| Skewness > 1 | Sesgo > 1 | Conventionally considered "substantially skewed" |
| Mean vs. Median gap | Brecha media-mediana | When mean ≫ median, the distribution is right-skewed — a few very high values inflate the mean |
| Outlier retention | Retención de valores atípicos | We KEPT extreme values because they represent real high-activity customers, not data errors |

### 🎯 Why is skewness important for clustering?
Before running K-Means, we need to understand the shape of the data.
Very skewed variables will produce clusters that are dominated by a few extreme
customers rather than capturing true behavioral differences. This is why we
**standardize** the variables before clustering (see Slide 17).

### 🎯 Why show BALANCE as the example?
BALANCE is the variable that appears in both hypotheses AND in clustering.
It's the most central variable in the project. Its histogram (Mean $1,601 vs.
Median $917) clearly illustrates the skewness pattern that exists across
all major financial variables.

---

## Slide 17 — Why K-Means Clustering?

### 📋 What it shows
The conceptual motivation and technical setup for the clustering analysis:
- Dataset has NO predefined labels
- EDA showed very different behaviors across customers
- Selected 8 non-redundant variables
- Standardized all variables before running the algorithm
- Chose K = 5 groups

### 📖 Key Terms
| English | Spanish | Meaning |
|---|---|---|
| K-Means | K-Medias | An algorithm that divides data into K groups by minimizing the distance between each point and its cluster center |
| Cluster | Grupo / clúster | A group of observations that are more similar to each other than to observations in other groups |
| Standardization | Estandarización | Transforming variables to have mean = 0 and standard deviation = 1, so all variables are on the same scale |
| Centroid | Centroide | The "center" of a cluster — the average value of all variables for customers in that cluster |
| K = 5 | Número de grupos = 5 | We told the algorithm to find exactly 5 groups |
| Elbow method | Método del codo | A technique to choose K by plotting how much "better" the clustering gets as K increases |
| Silhouette score | Puntuación de silueta | A metric that measures how well each point fits in its cluster vs. the nearest other cluster |

### 🎯 Why standardize the variables?
Consider BALANCE (values in the thousands of dollars) vs. PURCHASES_FREQUENCY
(values from 0 to 1). Without standardization, the algorithm would be dominated
by BALANCE simply because its numbers are larger — not because it's more important.
Standardizing puts all variables on equal footing, letting the algorithm find
clusters based on BEHAVIORAL patterns, not numeric scale.

### 🎯 Why K = 5?
K = 5 was chosen by examining both the **elbow method** (inertia dropped significantly
from K=2 to K=5, then leveled off) and the **silhouette score** (highest at K=2, but
K=5 provided far more interpretable and actionable groups). The final choice balances
mathematical optimization with practical usefulness — 5 groups are distinct enough
to be interesting and few enough to explain to a business audience.

### 🎯 Is K-Means the best algorithm?
K-Means is the most common first choice: fast, interpretable, and easy to explain.
Its main limitation is that it assumes spherical clusters of similar size, which
may not perfectly match real customer data. However, for an **exploratory** analysis
like this, it provides good, actionable starting points.

---

## Slide 18 — K-Means Result: 5 Customer Groups

### 📋 What it shows
A summary table of the 5 discovered clusters with their size and key characteristics:

| Cluster | % | Key Trait |
|---|---|---|
| Low-Activity Customers | ~39% | Very low purchases and frequency |
| Regular Purchasers | ~33% | Frequent purchases, almost no CA |
| Full-Payment Customers | ~15% | Consistently pay full balance |
| High Cash-Advance Users | ~12% | High balance from CA |
| High-Value Customers | ~1% | Extremely high spending + credit limit (n≈112) |

### 📖 Key Terms
| English | Spanish | Meaning |
|---|---|---|
| Customer profile | Perfil del cliente | A description of a typical customer in a group based on their average behaviors |
| Cluster size | Tamaño del clúster | Number (or percentage) of customers assigned to that cluster |
| CASH_ADVANCE (CA) | Adelanto en efectivo | Cash in advance given by the user (total amount); incurs high fees and immediate interest |
| PRCFULLPAYMENT | Porcentaje de pago completo | Percent of full payment paid by user (official name: PRCFULLPAYMENT, used as PRC_FULL_PAYMENT in code) |
| High-Value | Alto valor / Premium | Customers with very high spending and credit limits — likely high-income individuals |

### 🎯 Why is the "High-Value" cluster so small (n ≈ 112, 1.3%)?
This is normal and expected. Very high-spending customers are rare in any population.
This cluster likely includes business owners using corporate cards, high-net-worth
individuals, or customers with very high credit scores. Despite being small, this
group is commercially very valuable — they generate a disproportionate share of
transaction revenue for the bank.

### 🎯 How do these clusters connect to our hypotheses?
- **H1** found that Heavy CA users have higher balances → the "High Cash-Advance Users"
  cluster directly confirms this: they have both the highest CA use AND the highest
  revolving balances.
- **H2** found that BALANCE doesn't strongly predict CREDIT_LIMIT → the clusters show
  why: "Full-Payment Customers" have low balances AND low/moderate credit limits;
  "Regular Purchasers" have low balances but can have moderate credit limits.

---

## Slide 19 — Conclusions

### 📋 What it shows
A two-part summary bringing together both sections of the project.

**Part 1 — Hypothesis Testing:**
- ✅ H1 Confirmed: Heavy CA users carry significantly higher balances (p ≪ 0.05)
- ✅ H2 Debunked: r ≈ 0.54 / r² ≈ 0.29 → BALANCE explains only ~29% of CREDIT_LIMIT

**Part 2 — Clustering:**
- K-Means found 5 interpretable customer profiles
- These are exploratory, NOT official categories

### 📖 Key Terms
| English | Spanish | Meaning |
|---|---|---|
| Practical relevance | Relevancia práctica | Whether a result matters in the real world, not just statistically |
| Exploratory profiles | Perfiles exploratorios | Descriptions of customer types discovered through unsupervised analysis — should be validated before being used operationally |
| Official categories | Categorías oficiales | Formally defined groups used in business decisions — require validation beyond this analysis |
| Contextualise | Contextualizar | To place results within a broader framework to make them more meaningful |

### 🎯 The overarching lesson from this project:
Statistics is a tool for **decision support**, not a machine that gives automatic
answers. This project illustrates three key principles:

1. **Statistical significance ≠ Practical importance** (H2 was significant BUT weak)
2. **Confirmatory and exploratory analyses complement each other** (H1/H2 + Clustering)
3. **Always check assumptions** (Welch's test, log transformation, standardization)

---

## Slide 21 — References

### 📋 What it shows
A list of the dataset, R packages, statistical functions, and concepts used
throughout the project.

### 📖 Key Terms Summary — Full Glossary

**Dataset Variables (official definitions)**

| Variable | Spanish | Official Definition |
|---|---|---|
| `BALANCE` | Saldo disponible | Balance amount left in their account to make purchases |
| `BALANCE_FREQUENCY` | Frecuencia de actualización del saldo | How frequently the Balance is updated; score 0–1 |
| `PURCHASES` | Compras totales | Amount of purchases made from account |
| `ONEOFF_PURCHASES` | Compra máxima de una sola vez | Maximum purchase amount done in one-go |
| `INSTALLMENTS_PURCHASES` | Compras a plazos | Amount of purchase done in installment |
| `CASH_ADVANCE` | Adelanto en efectivo (total) | Cash in advance given by the user |
| `PURCHASES_FREQUENCY` | Frecuencia de compras | How frequently purchases are being made; score 0–1 |
| `ONEOFFPURCHASES_FREQUENCY` | Frecuencia de compras únicas | How frequently purchases are happening in one-go; score 0–1 |
| `PURCHASES_INSTALLMENTS_FREQUENCY` | Frecuencia de compras a plazos | How frequently purchases in installments are being done; score 0–1 |
| `CASH_ADVANCE_FREQUENCY` | Frecuencia de adelantos en efectivo | How frequently the cash in advance is being paid; score 0–1 |
| `CASH_ADVANCE_TRX` | Número de transacciones de adelanto | Number of transactions made with "Cash in Advanced" |
| `PURCHASES_TRX` | Número de transacciones de compra | Number of purchase transactions made |
| `CREDIT_LIMIT` | Límite de crédito | Limit of Credit Card for user |
| `PAYMENTS` | Pagos realizados | Amount of Payment done by user |
| `MINIMUM_PAYMENTS` | Pagos mínimos | Minimum amount of payments made by user |
| `PRCFULLPAYMENT` | Porcentaje de pago completo | Percent of full payment paid by user |
| `TENURE` | Antigüedad del servicio | Tenure of credit card service for user |

**Statistical & R Terms**

| English Term | Spanish | Brief Definition |
|---|---|---|
| `dplyr` | — | R package for data manipulation (filter, mutate, group_by, summarise) |
| `t.test()` | — | R function for t-tests |
| `cor.test()` | — | R function for correlation tests |
| `kmeans()` | — | R function for K-Means clustering |
| Welch's t-test | Prueba t de Welch | t-test that handles unequal variances between groups |
| Pearson correlation | Correlación de Pearson | Measures linear association between two continuous variables; ranges -1 to +1 |
| K-Means clustering | K-Medias | Partitions data into K groups by minimizing within-cluster distance |
| IQR rule | Regla del IQR | Outlier = point > Q3 + 1.5×IQR or < Q1 − 1.5×IQR |
| Standardization | Estandarización | Rescales variables to mean 0 and standard deviation 1 |
| Alpha (α) | Nivel de significancia | Decision threshold; we use α = 0.05 (5% false-positive tolerance) |
| p-value | Valor p | Probability of observing the result if H₀ is true; small p → reject H₀ |
| r (Pearson's) | Coeficiente r | Correlation coefficient; -1 = perfect negative, 0 = none, +1 = perfect positive |
| r² | Coeficiente de determinación | Proportion of variance in Y explained by X |
| Skewness | Sesgo / asimetría | Measure of how asymmetric a distribution is |
| Right-skewed | Sesgado a la derecha | Most values cluster low; long tail stretches toward large values |
| Confidence Interval | Intervalo de confianza | Range of values we are X% confident contains the true parameter |
| Centroid | Centroide | The mean point of all observations in a cluster |
| Elbow method | Método del codo | Choosing K by finding where adding more clusters gives diminishing returns |
| Silhouette score | Puntuación de silueta | How well each point fits its cluster vs. the nearest alternative cluster |

---

## Quick-Reference Decision Map

```
                     START: Do I have a specific claim to test?
                               /            \
                             YES             NO
                              |               |
                    Hypothesis Testing    Clustering / EDA
                              |               |
                    One-tailed or         K-Means
                    Two-tailed?           - Standardize first
                              |           - Choose K with elbow/silhouette
                    Is direction known?
                         /      \
                       YES       NO
                  One-tailed  Two-tailed
                              |
                    Check assumptions:
                    - Variance equal? → Welch's if not
                    - Normality? → Log-transform if skewed
                              |
                    Report: t, df, p, CI, effect size
                              |
                    p < α? → REJECT H₀
                    p ≥ α? → FAIL TO REJECT H₀
                              |
                    ALWAYS report effect size (r², Cohen's d)
                    not just p-value!
```

---

*Study Guide — Final Project | Data Analytics | Class 8:30 AM*
