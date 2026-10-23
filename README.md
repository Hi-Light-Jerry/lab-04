# Introduction to Data Science: group project

The final group project is **[When does Seoul’s bike sharing demand rise?](project/README.md)**, using the official UCI Seoul Bike Sharing Demand dataset.

| Deliverable | Source | Rendered document |
| --- | --- | --- |
| Report | [report.Rmd](project/report.Rmd) | [report.html](project/report.html) |
| Presentation | [presentation.Rmd](project/presentation.Rmd) | [presentation.html](project/presentation.html) |
| Investigation | [investigation.Rmd](project/investigation.Rmd) | [investigation.html](project/investigation.html) |

Download the HTML documents and open them in a browser. They are self-contained.

![Seoul hourly bike rentals across the observation year](project/img/fig-01-demand-heatmap.png)

## Reproduce and collaborate

Open **`project/ids-project.Rproj`** in RStudio. From that project’s Console, run:

```r
source("scripts/setup.R")
source("scripts/build.R")
```

The complete [project README](project/README.md) describes the research questions, findings, sources and pending team review. See the [RStudio and collaboration guide](project/docs/team-workflow.md) for team instructions and the [project checklist](project/docs/project-checklist.md) for course arrangements.

## Repository background

This repository was initially imported from the course’s Lab 04 template. The final group project follows [uoeIDS/project_template](https://github.com/uoeIDS/project_template) inside **`project/`**, preserving the existing repository, collaborators and previous commits. The original [Lab 04 worksheet](lab-04.Rmd) remains available at the repository root.

The history records the unmodified official project template first, followed by the actual Seoul Bike Sharing analysis and writing changes. Both new commits record the current work.
