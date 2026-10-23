# Run from the RStudio project root: source("scripts/build.R")
# All data cleaning, numerical analysis and visualisations use R.
required <- c("tidyverse", "rmarkdown", "knitr", "xaringan", "rpart", "jsonlite", "digest")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) stop("Run source('scripts/setup.R') first. Missing packages: ", paste(missing, collapse = ", "))
if (!file.exists("data/SeoulBikeData.csv")) stop("Open project/ids-project.Rproj and run this script from that project folder.")
if (!rmarkdown::pandoc_available()) stop("Pandoc is unavailable. Run this script from RStudio.")
source("scripts/analysis.R")
analysis_results <- run_analysis()
source("scripts/visualisations.R")
if (!file.exists("libs/remark-latest.min.js")) xaringan::summon_remark(to = "libs/")
for (document in c("report.Rmd", "investigation.Rmd", "presentation.Rmd")) {
  message("Rendering ", document)
  rmarkdown::render(document, envir = environment(), quiet = TRUE, clean = TRUE)
}
stopifnot(all(file.exists(c("report.html", "investigation.html", "presentation.html"))))
if (Sys.getenv("RSTUDIO") == "1" && requireNamespace("rstudioapi", quietly = TRUE)) {
  writeLines(c(paste("RStudio", rstudioapi::getVersion()), "RSTUDIO 1",
               "Analysis, visualisations and all three HTML documents regenerated in RStudio"),
             "outputs/rstudio-verification.txt")
}
message("Build complete: report.html, investigation.html, presentation.html")
