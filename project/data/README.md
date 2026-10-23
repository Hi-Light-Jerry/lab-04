# Data provenance and handling

## Source and attribution

**Seoul Bike Sharing Demand [Dataset]. (2020). UCI Machine Learning Repository.**

- Official dataset: <https://archive.ics.uci.edu/dataset/560/seoul+bike+sharing+demand>
- Persistent identifier: <https://doi.org/10.24432/C5F62R>
- Retrieved: **23 October 2026**
- Licence: [Creative Commons Attribution 4.0 International](https://creativecommons.org/licenses/by/4.0/)
- Original local file: [`SeoulBikeData.csv`](SeoulBikeData.csv)

This project preserves the downloaded CSV's original bytes. Its source text encoding is **ISO-8859-1**, also called Latin-1. The analysis reads that encoding explicitly. Do not resave the original file through a spreadsheet or text editor; that can change its bytes or measurement-column names.

Expected SHA-256:

```text
373339b71a8935d69e9af0abf26a70744632119862eeb3919efb389a7b749c60
```

To check it from the project root in R:

```r
digest::digest(file = "data/SeoulBikeData.csv", algo = "sha256")
```

## Coverage and variables

The CSV contains **8,760 hourly rows and 14 original columns**, covering **1 December 2017 to 30 November 2018**. Calendar dates and hours refer to Seoul local time. The script constructs timestamps using `Asia/Seoul`.

| Original field | Meaning or units |
| --- | --- |
| Date | Calendar date, day/month/year |
| Rented Bike Count | Recorded bicycles rented during the hour |
| Hour | Local hour, 0 to 23 |
| Temperature | Degrees Celsius |
| Humidity | Percent |
| Wind speed | Metres per second |
| Visibility | Units of 10 metres |
| Dew point temperature | Degrees Celsius |
| Solar Radiation | Megajoules per square metre |
| Rainfall | Millimetres |
| Snowfall | Centimetres |
| Seasons | Recorded season category |
| Holiday | Holiday indicator |
| Functioning Day | Whether the service was functioning |

The exact original column names and analysis names are exported to [`../tables/variable_dictionary.csv`](../tables/variable_dictionary.csv).

## Cleaning and analysis population

[`../scripts/analysis.R`](../scripts/analysis.R) parses dates and numeric measurements, validates ranges and categorical values, checks duplicates and date/hour uniqueness, and creates calendar features. Its audit records no missing source cells or exact duplicate rows in this input.

All **295 non-functioning hours** have zero recorded rentals. They remain in the annual overview, where closure hours are distinguished visually. Modelling uses the **8,465 functioning hours** to study rentals during service operation. No active-service rows require exclusion for missing values.

A working day is a Monday to Friday with `Holiday` equal to `No Holiday`; other days form the weekend or holiday group. Rainfall and temperature summaries describe associations across recorded hours. Same-hour observed weather enters the prediction models, so the evaluation measures retrospective conditional prediction.

The fixed time boundaries are:

| Partition | Intended dates | Active-service observations |
| --- | --- | --- |
| Training | 1 December 2017 to 31 July 2018 | 5,784 |
| Validation | 1 August to 30 September 2018 | 1,368 |
| Test | 1 October to 30 November 2018 | 1,313 |

Closure periods can make the last available active-service observation earlier than a partition's intended boundary. Model settings are selected on validation data, then frozen before the reported test comparison.

## Generated data and outputs

The analysis generates [`clean/seoul_bike_clean.csv`](clean/seoul_bike_clean.csv) and [`clean/seoul_bike_clean.rds`](clean/seoul_bike_clean.rds) from the preserved source. These derived files include the source observations with cleaned names and constructed features; the modelling restriction is applied explicitly in the script. Rebuild them through the project scripts rather than editing individual cells.

Audit results, partition counts and model outputs are exported to [`../tables/`](../tables/). The result summary in [`../outputs/results-summary.json`](../outputs/results-summary.json) records the input checksum and the fixed evaluation protocol. See [`../investigation.Rmd`](../investigation.Rmd) for the full code and checks.
