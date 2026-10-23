# Project review and completion checklist

This checklist separates reviewable project materials from actions that require the real team. Check an item only after observing its completion. Items below are deliberately left open for final review.

## Data and analysis

- [ ] The original UCI file is present at `data/SeoulBikeData.csv` and matches the checksum in [data/README.md](../data/README.md).
- [ ] The data source, retrieval date of 23 October 2026 and CC BY 4.0 attribution appear in the report.
- [ ] The team can explain the 8,760 source hours, 295 closure hours and 8,465 active-service modelling hours.
- [ ] Dates, units, missingness, duplicate checks and the active-service restriction have been reviewed.
- [ ] All models use the same observations within each evaluation partition.
- [ ] Model selection uses validation RMSE; the selected tree remains identified after its later test performance is known.
- [ ] The report retains the validation-to-test ranking reversal and avoids presenting the tree as a test-period improvement.
- [ ] Observed same-hour weather, temporal dependence, the single annual cycle and the distinction between rentals and unmet demand are explained.
- [ ] The conclusions are limited to the evidence and contain no causal or station-level allocation claims.

## Reproducibility and files

- [ ] Open `project/ids-project.Rproj` in RStudio and run `source("scripts/setup.R")` where dependencies require installation.
- [ ] Run `source("scripts/build.R")` from the project root and review its completion output.
- [ ] Open `report.html`, `presentation.html` and `investigation.html` in a browser.
- [ ] Confirm that every figure, table and linked support file is available in the downloaded project.
- [ ] Inspect slide text and plots at presentation size and verify the presentation's supporting assets.
- [ ] The repository includes all three `.Rmd` sources and their `.html` outputs, data, scripts, figures, results and this documentation.
- [ ] The original Lab 04 files remain present.
- [ ] No passwords, tokens, personal environment files or fabricated contribution records are included.

## Report and presentation

- [ ] Confirm the real team name and author names in report and presentation metadata.
- [ ] Review the Research Question, Data, Findings and References sections as a coherent narrative.
- [ ] Confirm that the final report is around 1,500 words and no more than 1,650 words, excluding figures, tables, code blocks and references.
- [ ] Confirm that the report links to <https://github.com/Hi-Light-Jerry/lab-04>.
- [ ] Hide presentation code with `echo = FALSE`, apart from any intentional code example that serves the explanation.
- [ ] Remove all remaining instructional or identity placeholders before submission.
- [ ] Read the assistance record and meet the current course's disclosure and permitted-use requirements.

## Team actions still to confirm

- [ ] Each member confirms their real name, understanding of the project and substantive contribution.
- [ ] `Hi-Light-Jerry`, `Wenbohub1224`, `Peter9985666` and `RogerWang6` confirm the access arrangements relevant to their roles.
- [ ] The owner confirms and, when authorised, completes the required `uoeIDS` collaborator arrangement. No invitation is claimed by this checklist.
- [ ] Record the actual distribution of work and genuine meetings using [team-workflow.md](team-workflow.md).
- [ ] Complete tutor check-ins and enter only feedback actually received.
- [ ] Confirm current dates in ELM/Learn. The linked site title refers to 2023 and its deadline text omits the year; the template's week 6 first check-in differs from the brief's week 7.
- [ ] Rehearse with every member speaking. Aim for 7 minutes of content and 2 minutes of questions within the 10-minute total.
- [ ] Deliver the live presentation under the course's confirmed arrangements.
- [ ] One team member submits the required report and presentation HTML through the current course system and adds the other team members to the group submission.
- [ ] Every member submits their own peer evaluation based on actual contributions.
- [ ] Retain the final submission receipt and record who submitted and when.

## Source of requirements

The checklist follows the [official project brief](https://uoe-ids.netlify.app/assessments/project/) and [course project template](https://github.com/uoeIDS/project_template), checked on 23 October 2026. Current course announcements and clarification from the teaching team are needed to settle the date and week discrepancies.
