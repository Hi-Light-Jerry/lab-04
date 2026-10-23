# Run once in the RStudio Console from the project root.
required <- c("tidyverse", "rmarkdown", "knitr", "xaringan", "rpart", "jsonlite", "digest")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) install.packages(missing, repos = "https://cloud.r-project.org")
if (!rmarkdown::pandoc_available()) {
  stop("Pandoc is unavailable. Run this project inside RStudio, which supplies Pandoc.")
}
message("Dependencies are ready. Run source('scripts/build.R') to rebuild the project.")
