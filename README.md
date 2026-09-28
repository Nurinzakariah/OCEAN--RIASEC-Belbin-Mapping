# OCEAN × RIASEC → Belbin Team Role Mapping & Team Composition Analysis

A reproducible R workflow that maps individual personality (OCEAN / Big Five)
and interest (RIASEC / Holland Code) scores to Belbin team roles using a
profile-similarity (Q-correlation) method, then aggregates role assignments
to the department level to test whether **role balance** relates to
**average performance rating**.

This repository accompanies a conference talk submission (Technical Talk
track, Pedagogy / Open Science / Scalable Onboarding) and exists to make the
core methodology transparent and reproducible.

## ⚠️ On the data used here

**The dataset in this repository (`data/sample_employee_data.csv`) is fully
synthetic.** It was generated to match the scale (n = 1,485) of the original
organizational study for demonstration purposes only. Every value —
trait scores, department, performance rating — is randomly generated and
does **not** correspond to any real person.

The original study was conducted using confidential, real employee data from
a private organization. That data cannot be shared publicly. This repository
lets anyone reproduce the *method* end-to-end without needing access to the
original (confidential) dataset.

Because the sample data here is random noise, **the correlation results this
script prints are not meaningful as findings** — they only confirm the
pipeline runs correctly. Actual study results are reported (with full
statistical caveats) in the accompanying extended abstract / talk.

## What this demonstrates

1. **Standardizing** multi-scale personality/interest trait scores (z-scores)
2. **Profile-similarity scoring**: comparing each person's trait profile
   against 9 expert-defined "ideal" Belbin role profiles using Q-correlation
   (pattern/shape matching, not raw magnitude matching)
3. **Role assignment**: converting similarity scores to percentiles and
   assigning each person their best-matching (primary) Belbin role
4. **Team composition metrics**: a Shannon-entropy-based Balance Index and
   Max Role Share, computed per department
5. **Hypothesis testing**: a Pearson correlation between department-level
   role balance and average performance rating, with a minimum group-size
   filter to avoid unstable small-sample estimates

## Repository structure

```
.
├── README.md
├── LICENSE
├── data/
│   └── sample_employee_data.csv     # synthetic demo data (n = 1,485)
└── scripts/
    └── belbin_reprex.R              # end-to-end reproducible script
```

## Requirements

- R (>= 4.0)
- Packages: `readr`, `dplyr`, `tidyr`

```r
install.packages(c("readr", "dplyr", "tidyr"))
```

## Running the example

Clone the repo, then from the repository root in R:

```r
source("scripts/belbin_reprex.R")
```

This will:
- Load the synthetic sample data
- Score all 1,485 synthetic employees against the 9 Belbin role profiles
- Print the resulting primary-role distribution
- Compute department-level composition metrics
- Run and print a correlation test between role balance and performance

## Using your own data

To run this on your own dataset, provide a CSV with these columns (renaming
as needed):

| Column | Description |
|---|---|
| `Openness`, `Conscientiousness`, `Extraversion`, `Agreeableness` | OCEAN trait scores |
| `Neuroticism` | Emotional stability, in the *reversed* convention (higher = more stable) — see comment in script if your data uses raw Neuroticism instead |
| `Realistic`, `Investigative`, `Artistic`, `Social`, `Enterprising`, `Conventional` | RIASEC scores |
| `department` | Team/department grouping |
| `performance_rating` | Numeric performance outcome |

## Methodology reference

The OCEAN × RIASEC → Belbin mapping used here is an expert-validated
framework; see the accompanying extended abstract for the full mapping
table, citations, and discussion of statistical limitations (sample size,
department-size confounds, and the distinction between descriptive and
statistically significant results).

## License

MIT — see [LICENSE](LICENSE).

## Citation

If you use this methodology, please cite the associated conference talk
(details to be added upon acceptance).
