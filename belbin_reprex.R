# =============================================================================
# OCEAN x RIASEC -> Belbin Team Role Mapping & Team Composition Analysis
# -----------------------------------------------------------------------------
# A minimal reproducible example (reprex) demonstrating the full workflow:
#   1. Map OCEAN (Big Five) + RIASEC trait scores to Belbin team roles using
#      a validated profile-similarity (Q-correlation) scoring method.
#   2. Aggregate individual role assignments to the department level.
#   3. Test whether department-level role BALANCE relates to average
#      performance rating.
#
# NOTE ON DATA: This script runs on data/sample_employee_data.csv, a fully
# SYNTHETIC dataset generated to match the scale (n = 1,485) of the original
# organizational study for demonstration purposes. All values are randomly
# generated and contain no real employee information. The original data used
# in the associated research is confidential and not publicly available.
# =============================================================================

library(readr)
library(dplyr)
library(tidyr)

# -----------------------------------------------------------------------------
# 1. LOAD DATA
# -----------------------------------------------------------------------------
df <- read_csv("sample_employee_data_belbin_synthetic1485.csv", show_col_types = FALSE)

# Trait columns, in a fixed order (5 OCEAN + 6 RIASEC)
ALL_TRAITS <- c("Openness", "Conscientiousness", "Extraversion",
                 "Agreeableness", "EmotionalStability",
                 "Realistic", "Investigative", "Artistic",
                 "Social", "Enterprising", "Conventional")

# The sample data's "Neuroticism" column follows the already-reversed
# convention used in the original study (higher = more emotionally stable).
# If your own data uses raw Neuroticism (higher = less stable), reverse it
# first: df$EmotionalStability <- -1 * df$Neuroticism (after standardizing).
df <- df %>% rename(EmotionalStability = Neuroticism)

ROLES <- c("Shaper", "Implementer", "Completer Finisher", "Co-ordinator",
           "Teamworker", "Resource Investigator", "Plant",
           "Monitor Evaluator", "Specialist")

# -----------------------------------------------------------------------------
# 2. IDEAL ROLE PROFILES (expert-validated OCEAN x RIASEC -> Belbin mapping)
# -----------------------------------------------------------------------------
# 1 = trait is a defining driver of the role, 0 = not implicated.
IDEAL_PROFILES <- list(
  "Shaper" = c(Openness = 1, Extraversion = 1, Enterprising = 1),
  "Implementer" = c(Agreeableness = 1, Conscientiousness = 1,
                     EmotionalStability = 1, Conventional = 1, Realistic = 1),
  "Completer Finisher" = c(Conscientiousness = 1, Conventional = 1),
  "Co-ordinator" = c(EmotionalStability = 1, Agreeableness = 1,
                      Conscientiousness = 1, Extraversion = 1,
                      Enterprising = 1, Social = 1),
  "Teamworker" = c(Agreeableness = 1, Conscientiousness = 1, Social = 1),
  "Resource Investigator" = c(Extraversion = 1, Openness = 1,
                               Enterprising = 1, Social = 1),
  "Plant" = c(Openness = 1, Investigative = 1, Artistic = 1),
  "Monitor Evaluator" = c(Openness = 1, Investigative = 1),
  "Specialist" = c(Conscientiousness = 1, Investigative = 1,
                    Realistic = 1, Conventional = 1)
)

build_ideal_matrix <- function() {
  mat <- matrix(0, nrow = length(ROLES), ncol = length(ALL_TRAITS),
                dimnames = list(ROLES, ALL_TRAITS))
  for (role in ROLES) {
    vals <- IDEAL_PROFILES[[role]]
    mat[role, names(vals)] <- vals
  }
  mat
}
IDEAL_MATRIX <- build_ideal_matrix()

# -----------------------------------------------------------------------------
# 3. STANDARDIZE TRAIT SCORES (z-score)
# -----------------------------------------------------------------------------
df_z <- df %>%
  mutate(across(all_of(ALL_TRAITS), ~ as.numeric(scale(.))))

# -----------------------------------------------------------------------------
# 4. SCORE EACH EMPLOYEE AGAINST EACH ROLE (Q-correlation)
# -----------------------------------------------------------------------------
# Q-correlation: correlate a person's 11-trait profile against a role's
# 11-trait "ideal profile" - measures pattern/shape similarity, not raw
# magnitude.
q_correlation <- function(vec, ideal) {
  if (sd(vec) == 0 || sd(ideal) == 0) return(0)
  cor(vec, ideal)
}

trait_mat <- as.matrix(df_z[, ALL_TRAITS])
scores <- matrix(NA, nrow = nrow(df_z), ncol = length(ROLES),
                  dimnames = list(NULL, ROLES))
for (i in seq_len(nrow(df_z))) {
  for (role in ROLES) {
    scores[i, role] <- q_correlation(trait_mat[i, ], IDEAL_MATRIX[role, ])
  }
}

# Convert to within-role percentiles for interpretability
pct_scores <- as_tibble(scores) %>%
  mutate(across(everything(), ~ rank(.x, ties.method = "average") / n() * 100))

# Assign primary role = highest-percentile role per employee
primary_role <- apply(pct_scores[, ROLES], 1, function(row) {
  ROLES[which.max(row)]
})

df_scored <- df %>%
  mutate(primary_belbin_role = primary_role)

cat("=== Primary role distribution (synthetic sample) ===\n")
print(table(df_scored$primary_belbin_role))

# -----------------------------------------------------------------------------
# 5. DEPARTMENT-LEVEL COMPOSITION METRICS
# -----------------------------------------------------------------------------
# Balance Index: normalized Shannon entropy of role distribution within a
# department. 1 = all 9 roles equally represented, 0 = one role dominates.
shannon_evenness <- function(counts) {
  total <- sum(counts)
  if (total == 0) return(NA_real_)
  p <- counts[counts > 0] / total
  H <- -sum(p * log(p))
  H / log(length(counts))
}

dept_composition <- df_scored %>%
  group_by(department) %>%
  summarise(
    N = n(),
    role_counts_list = list(table(factor(primary_belbin_role, levels = ROLES))),
    avg_performance = mean(performance_rating, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  rowwise() %>%
  mutate(
    role_coverage   = sum(role_counts_list > 0),
    balance_index   = round(shannon_evenness(as.numeric(role_counts_list)), 3),
    max_role_share  = round(max(role_counts_list) / N, 3)
  ) %>%
  ungroup() %>%
  select(department, N, role_coverage, balance_index, max_role_share,
         avg_performance) %>%
  arrange(desc(N))

cat("\n=== Department-level composition ===\n")
print(dept_composition)

# -----------------------------------------------------------------------------
# 6. TEST: DOES ROLE BALANCE RELATE TO PERFORMANCE?
# -----------------------------------------------------------------------------
# Filter to departments with a reasonably stable sample before testing.
stable <- dept_composition %>% filter(N >= 30)

cat(sprintf("\nDepartments included in test (N >= 30): %d\n", nrow(stable)))

if (nrow(stable) >= 3) {
  cor_result <- cor.test(stable$balance_index, stable$avg_performance,
                          method = "pearson")
  cat("\nBalance Index vs. Avg Performance:\n")
  print(cor_result)
} else {
  cat("\nNot enough departments with N >= 30 in this synthetic sample to run",
      "a meaningful correlation test. Adjust the threshold or sample size.\n")
}

# -----------------------------------------------------------------------------
# NOTE ON INTERPRETATION
# -----------------------------------------------------------------------------
# This script demonstrates the METHOD end-to-end. Because the input here is
# synthetic (randomly generated) data, the printed correlation result is NOT
# meaningful on its own and should not be interpreted as a research finding -
# it only confirms that the pipeline runs correctly. See the accompanying
# extended abstract for the actual study's results and their statistical
# caveats.
