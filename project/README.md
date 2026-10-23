# When does Seoul's bike sharing demand rise?

An Introduction to Data Science group project using the official **Seoul Bike Sharing Demand** dataset. The analysis covers 8,760 hourly observations from December 2017 to November 2018.

[Read the report](report.html) · [Open the presentation](presentation.html) · [Inspect the investigation](investigation.html)

Download the HTML files and open them in a browser. GitHub's file view displays their source. All three HTML documents are self-contained and can be read offline. Rebuilding them uses the source files and dependencies in this project.

![Hourly bike rentals across the observation year, with service closures distinguished from recorded demand](img/fig-01-demand-heatmap.png)

## Questions and findings

1. How do recorded hourly rentals vary across the year, time of day and working-day status?
2. How are rentals associated with weather?
3. Can calendar and weather variables predict recorded rentals in later months?

The visual analysis shows strong daily and seasonal variation. The regression tree wins the validation comparison, then performs worse than the calendar baseline in the later test period. We retain this reversal in the report. Weather is observed in the same hour, so the modelling exercise assesses retrospective conditional prediction. The findings describe associations and do not establish causal effects.

## Reproduce in RStudio

From the cloned repository, open **`project/ids-project.Rproj`**. RStudio then uses this `project/` folder as its working directory. Run the following in the RStudio Console:

```r
# Install project packages once. Internet access is needed for installation.
source("scripts/setup.R")

# Recreate the analysis, figures, tables and all three HTML documents.
source("scripts/build.R")
```

Run the build from the project root. It uses the checked-in CSV, with no live data download required. The analysis protocol uses a fixed chronological split and selects the model using validation RMSE before evaluating the test period.

## Files to read

| Location | Purpose |
| --- | --- |
| [report.Rmd](report.Rmd), [report.html](report.html) | Main project narrative and findings |
| [presentation.Rmd](presentation.Rmd), [presentation.html](presentation.html) | Slides based on the course's xaringan template |
| [investigation.Rmd](investigation.Rmd), [investigation.html](investigation.html) | Detailed checks, code, comparisons and limitations |
| [scripts/](scripts/) | Setup, reproducible build, analysis and visualisations |
| [data/README.md](data/README.md) | Data source, licence, encoding and input checksum |
| [tables/](tables/), [img/](img/) | Generated summaries, predictions and figures |
| [outputs/](outputs/) | Machine-readable results and execution information |
| [docs/team-workflow.md](docs/team-workflow.md) | Chinese guide to RStudio, GitHub collaboration and presentation preparation |
| [docs/project-checklist.md](docs/project-checklist.md) | Review checklist and remaining team actions |
| [docs/ai-assistance.md](docs/ai-assistance.md) | Assistance record and responsibilities for team review |

The existing [Hi-Light-Jerry/lab-04](https://github.com/Hi-Light-Jerry/lab-04) repository was initially imported from the Lab 04 template. This final project follows the separate official course project template inside `project/`. The original lab files and existing repository history are preserved. An unmodified project-template commit precedes the actual analysis and writing changes.

## Team review and course arrangements

Account handles supplied for team coordination are `Hi-Light-Jerry`, `Wenbohub1224`, `Peter9985666` and `RogerWang6`. The team must confirm its real names, team name, roles and access arrangements. No contribution or invitation acceptance is inferred from this list.

The documents form an assisted project draft with reproducible results. The team still needs to review the work, contribute under its own accounts, complete tutor check-ins, rehearse with every member speaking, submit individually required peer evaluations and make the formal course submission. Adding the course account `uoeIDS` remains an owner action to confirm.

The linked [project brief](https://uoe-ids.netlify.app/assessments/project/) has a site title referring to 2023 and deadline text without an explicit year. Its first check-in is in week 7, while the template README says week 6. Confirm current arrangements through the course's ELM/Learn announcements and teaching team.

## Sources

Seoul Bike Sharing Demand [Dataset]. (2020). UCI Machine Learning Repository. [DOI: 10.24432/C5F62R](https://doi.org/10.24432/C5F62R). Retrieved 23 October 2026. Data licence: [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).

Project structure and presentation format are adapted from the [official course template](https://github.com/uoeIDS/project_template).
