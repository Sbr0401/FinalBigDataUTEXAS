# ============================================================================
# Credit Card Customer Behavior Analysis
# Hypothesis Testing + K-Means Clustering
# ----------------------------------------------------------------------------
# Course    : Big Data & Data Mining
# Instructor: Dr. Kia Teymourian
# School    : The University of Texas at Austin
# Authors   : Hannia Ashley Alvarado Galvan  | ha26947
#             Santiago Basaldua Ramirez      | sb74887
# ============================================================================

library(dplyr)

# ── 0. Load Data ─────────────────────────────────────────────────────────────
cc <- read.csv("Files/CC_GENERAL.csv", stringsAsFactors = FALSE)

cat("Original rows:", nrow(cc), "\n")

# ── 1. Data Wrangling ─────────────────────────────────────────────────────────
cc_clean <- cc %>%
  filter(!is.na(CREDIT_LIMIT), !is.na(MINIMUM_PAYMENTS)) %>%
  mutate(
    # Binary group: Heavy CA (>= 0.25 frequency) vs Light CA
    CA_Group    = if_else(CASH_ADVANCE_FREQUENCY >= 0.25,
                          "Heavy CA", "Light CA"),
    # Log-transform to reduce right-skew (skewness ~2.39)
    LOG_BALANCE = log1p(BALANCE)
  )

cat("Rows after cleaning:", nrow(cc_clean), "\n")
print(table(cc_clean$CA_Group))

alpha <- 0.05  # Significance level for all tests

# ── 2. Hypothesis 1: Heavy CA Users Carry Higher Balances ────────────────────
# H0: mu_HeavyCA = mu_LightCA
# H1: mu_HeavyCA > mu_LightCA  (one-tailed)
# Test: Welch's two-sample t-test (var.equal = FALSE)

heavy <- cc_clean$BALANCE[cc_clean$CA_Group == "Heavy CA"]
light <- cc_clean$BALANCE[cc_clean$CA_Group == "Light CA"]

t_result_h1 <- t.test(
  x           = heavy,
  y           = light,
  alternative = "greater",  # one-tailed: Heavy > Light
  var.equal   = FALSE       # Welch's t-test (unequal variances)
)

cat("\n── H1 Results ───────────────────────────────\n")
cat(sprintf("t-statistic : %.3f\n",   t_result_h1$statistic))
cat(sprintf("df          : %.1f\n",   t_result_h1$parameter))
cat(sprintf("p-value     : %.2e\n",   t_result_h1$p.value))
cat(sprintf("95%% CI lower: $%.2f\n", t_result_h1$conf.int[1]))
cat(sprintf("Decision    : %s\n",
            ifelse(t_result_h1$p.value < alpha,
                   "REJECT H0 — CONFIRMED", "FAIL TO REJECT H0")))

# Exploratory plots for H1
par(mfrow = c(1, 2), mar = c(4, 4, 3, 1), bg = "white")

boxplot(BALANCE ~ CA_Group, data = cc_clean,
        col    = c("#BF5700", "#4A90D9"),
        border = c("#8B3D00", "#1A5FA8"),
        main   = "Balance by Group",
        xlab   = "Cash-Advance Group",
        ylab   = "Balance (USD)",
        outline = FALSE, lwd = 1.4)

hist(log1p(heavy), col = adjustcolor("#BF5700", 0.65), breaks = 40,
     main = "Log-Balance Distribution", xlab = "log(1 + Balance)",
     xlim = c(0, 12), border = "white")
hist(log1p(light), col = adjustcolor("#4A90D9", 0.55),
     breaks = 40, add = TRUE, border = "white")
legend("topright", legend = c("Heavy CA", "Light CA"),
       fill = c("#BF5700", "#4A90D9"), bty = "n", cex = 0.9)

# ── 3. Hypothesis 2: Balance Predicts Credit Limit? (Debunk) ─────────────────
# H0: rho = 0
# H1: rho != 0  (strong positive correlation)
# Test: Pearson correlation

cor_h2 <- cor.test(cc_clean$BALANCE, cc_clean$CREDIT_LIMIT,
                   method = "pearson")

r_val <- as.numeric(cor_h2$estimate)

cat("\n── H2 Results ───────────────────────────────\n")
cat(sprintf("r (Pearson)          : %.4f\n",    r_val))
cat(sprintf("r^2 (variance expl.) : %.2f%%\n", r_val^2 * 100))
cat(sprintf("p-value              : %.2e\n",    cor_h2$p.value))
cat(sprintf("Decision             : DEBUNKED — r^2 = %.1f%% only\n",
            r_val^2 * 100))

# Scatter plot + distribution
par(mfrow = c(1, 2), mar = c(4, 4, 3, 1), bg = "white")

plot(cc_clean$BALANCE, cc_clean$CREDIT_LIMIT,
     pch = 20, cex = 0.35, col = adjustcolor("#BF5700", 0.30),
     main = "Balance vs. Credit Limit",
     xlab = "Balance (USD)", ylab = "Credit Limit (USD)")
abline(lm(CREDIT_LIMIT ~ BALANCE, data = cc_clean),
       col = "#1A1A1A", lwd = 2, lty = 2)

hist(cc_clean$BALANCE, col = adjustcolor("#BF5700", 0.70),
     breaks = 60, main = "Balance — Right-Skewed",
     xlab = "Balance (USD)", border = "white")

# Outlier count (IQR rule)
q3  <- quantile(cc_clean$BALANCE, 0.75)
iqr <- IQR(cc_clean$BALANCE)
cat(sprintf("Balance outliers (IQR rule): %d customers\n",
            sum(cc_clean$BALANCE > q3 + 1.5 * iqr)))

# ── 4. Correlation Matrix ─────────────────────────────────────────────────────
clust_vars <- c("BALANCE", "PURCHASES", "CASH_ADVANCE", "CREDIT_LIMIT",
                "PAYMENTS", "PURCHASES_FREQUENCY",
                "CASH_ADVANCE_FREQUENCY", "PRC_FULL_PAYMENT")

cc_clust <- cc_clean %>% select(all_of(clust_vars)) %>% na.omit()

short_names <- c("BAL", "PURCH", "CA", "CL", "PAY", "PF", "CAF", "FULL")
cor_mat <- cor(cc_clust[, clust_vars], use = "pairwise.complete.obs")
colnames(cor_mat) <- rownames(cor_mat) <- short_names

cat("\n── Correlation Matrix ───────────────────────\n")
print(round(cor_mat, 2))

# Heatmap
n   <- length(short_names)
pal <- colorRampPalette(c("#2166AC", "white", "#BF5700"))(200)

layout(matrix(c(1, 2), 1, 2), widths = c(4.2, 0.8))
par(mar = c(3.5, 3.5, 2.5, 0.5), bg = "white")
image(1:n, 1:n, t(cor_mat[n:1, ]),
      col = pal, zlim = c(-1, 1), axes = FALSE, xlab = "", ylab = "")
axis(1, 1:n, short_names, las = 1, cex.axis = 0.80, tick = FALSE)
axis(2, 1:n, rev(short_names), las = 1, cex.axis = 0.80, tick = FALSE)
for (i in 1:n) for (j in 1:n) {
  val  <- cor_mat[n + 1 - j, i]
  tcol <- if (abs(val) > 0.55) "white" else "black"
  text(i, j, sprintf("%.2f", val), cex = 0.62, col = tcol)
}
box(col = "gray70")
title("Correlation Matrix — Clustering Variables", cex.main = 1.05)

par(mar = c(3.5, 0.5, 2.5, 2.5))
image(1, seq(-1, 1, length.out = 200),
      matrix(seq(-1, 1, length.out = 200), 1, 200),
      col = pal, axes = FALSE, xlab = "", ylab = "")
axis(4, at = c(-1, -0.5, 0, 0.5, 1),
     labels = c("-1.0", "-0.5", "0.0", "0.5", "1.0"),
     las = 1, cex.axis = 0.70, tick = TRUE)
box(col = "gray70")

# ── 5. K-Means Clustering ─────────────────────────────────────────────────────
# Variables standardised so dollar values don't dominate 0-1 frequency scales
X_scaled <- scale(cc_clust)

set.seed(123)
km <- kmeans(X_scaled, centers = 5, nstart = 25, iter.max = 300)
cc_clust$Cluster <- km$cluster

# ── 6. Cluster Profiles ───────────────────────────────────────────────────────
profiles <- cc_clust %>%
  group_by(Cluster) %>%
  summarise(
    n       = n(),
    pct     = round(n() / nrow(cc_clust) * 100, 1),
    m_bal   = round(mean(BALANCE),             0),
    m_purch = round(mean(PURCHASES),           0),
    m_ca    = round(mean(CASH_ADVANCE),        0),
    m_pf    = round(mean(PURCHASES_FREQUENCY), 2),
    m_prc   = round(mean(PRC_FULL_PAYMENT),    2)
  )

# Auto-label clusters by dominant characteristic
lbl <- rep("", nrow(profiles))
lbl[which.max(profiles$m_purch)] <- "High-Value Customers"
lbl[which.max(profiles$m_prc)]   <- "Full-Payment Customers"
lbl[which.max(profiles$m_ca)]    <- "High Cash-Advance Users"
rem <- which(lbl == "")
if (profiles$m_pf[rem[1]] > profiles$m_pf[rem[2]]) {
  lbl[rem[1]] <- "Regular Purchasers"
  lbl[rem[2]] <- "Low-Activity Customers"
} else {
  lbl[rem[2]] <- "Regular Purchasers"
  lbl[rem[1]] <- "Low-Activity Customers"
}
profiles$Name <- lbl

present_order <- c("Low-Activity Customers", "Regular Purchasers",
                   "Full-Payment Customers", "High Cash-Advance Users",
                   "High-Value Customers")
profiles <- profiles[match(present_order, profiles$Name), ]

cat("\n── K-Means Cluster Profiles ─────────────────\n")
print(profiles[, c("Name", "n", "pct", "m_bal", "m_purch", "m_ca", "m_pf", "m_prc")])

# BALANCE distribution plot per cluster
par(mfrow = c(1, 1), mar = c(4, 5, 3, 1), bg = "white")
clust_cols <- c("#F0C040", "#BF5700", "#4A90D9", "#E74C3C", "#55A868")
short_clust <- c("Low-\nActivity", "Regular\nPurchasers",
                 "Full-\nPayment", "High CA\nUsers", "High-\nValue")

boxplot(BALANCE ~ Cluster, data = cc_clust,
        col    = clust_cols,
        names  = short_clust,
        main   = "Balance Distribution by Cluster",
        xlab   = "Customer Cluster",
        ylab   = "Balance (USD)",
        outline = FALSE, lwd = 1.3)

# ── 7. Summary ────────────────────────────────────────────────────────────────
cat("\n════════════════════════════════════════════\n")
cat(" FINAL SUMMARY\n")
cat("════════════════════════════════════════════\n")
cat(sprintf("H1 : %s  (p = %.2e, t = %.2f)\n",
            ifelse(t_result_h1$p.value < alpha, "CONFIRMED", "NOT CONFIRMED"),
            t_result_h1$p.value, t_result_h1$statistic))
cat(sprintf("H2 : DEBUNKED  (r = %.3f, r2 = %.1f%%)\n",
            r_val, r_val^2 * 100))
cat(sprintf("K-Means: %d clusters | %d customers analysed\n",
            km$centers %>% nrow(), nrow(cc_clust)))
cat("Cluster labels:\n")
for (i in seq_along(present_order)) {
  p <- profiles[i, ]
  cat(sprintf("  %-28s %5.1f%%  avg_balance=$%.0f\n",
              p$Name, p$pct, p$m_bal))
}
cat("════════════════════════════════════════════\n")
