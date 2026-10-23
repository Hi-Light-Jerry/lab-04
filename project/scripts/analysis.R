# Reproducible Seoul Bike Sharing analysis.
# Run from the RStudio project folder (project/): source("scripts/analysis.R")
# Models use observed same-hour weather; this is retrospective conditional prediction.

suppressPackageStartupMessages(library(tidyverse))

project_data_file <- function() {
  paths <- c("data/SeoulBikeData.csv", "data/raw/SeoulBikeData.csv")
  existing <- paths[file.exists(paths)]
  if (!length(existing)) stop("Place the official UCI SeoulBikeData.csv in data/ before running the analysis.")
  existing[[1]]
}

prediction_metrics <- function(observed, predicted, model, partition) {
  stopifnot(length(observed) == length(predicted), all(is.finite(predicted)))
  tibble(
    partition = partition, model = model, n = length(observed),
    rmse = sqrt(mean((observed - predicted)^2)),
    mae = mean(abs(observed - predicted)),
    r_squared = 1 - sum((observed - predicted)^2) / sum((observed - mean(observed))^2),
    mean_error = mean(predicted - observed)
  )
}

fit_calendar_baseline <- function(training) {
  list(
    cell = training |> group_by(hour, weekday) |> summarise(prediction = mean(rentals), .groups = "drop"),
    hour = training |> group_by(hour) |> summarise(hour_prediction = mean(rentals), .groups = "drop"),
    mean = mean(training$rentals)
  )
}

predict_calendar_baseline <- function(model, newdata) {
  newdata |>
    select(hour, weekday) |>
    mutate(.row = row_number()) |>
    left_join(model$cell, by = c("hour", "weekday")) |>
    left_join(model$hour, by = "hour") |>
    arrange(.row) |>
    transmute(prediction = coalesce(prediction, hour_prediction, model$mean)) |>
    pull(prediction)
}

run_analysis <- function(data_file = project_data_file(), output_root = ".") {
  set.seed(20261023)
  for (folder in c("tables", "img", "outputs")) {
    dir.create(file.path(output_root, folder), recursive = TRUE, showWarnings = FALSE)
  }
  write_table <- function(data, name) readr::write_csv(data, file.path(output_root, "tables", paste0(name, ".csv")))

  raw <- readr::read_csv(
    data_file,
    locale = readr::locale(encoding = "ISO-8859-1"),
    col_types = readr::cols(.default = readr::col_character()),
    na = c("", "NA"), show_col_types = FALSE
  )
  stopifnot(ncol(raw) == 14L, identical(names(raw)[1:3], c("Date", "Rented Bike Count", "Hour")))
  original_names <- names(raw)
  canonical_names <- c(
    "date", "rentals", "hour", "temp_c", "humidity_pct", "wind_ms",
    "visibility_10m", "dewpoint_c", "solar_mj_m2", "rainfall_mm", "snowfall_cm",
    "season", "holiday", "functioning"
  )
  names(raw) <- canonical_names
  missingness <- tibble(variable = canonical_names, missing = vapply(raw, function(x) sum(is.na(x)), integer(1)))
  write_table(missingness, "missingness")
  numeric_fields <- canonical_names[2:11]
  parsed <- raw |>
    mutate(across(all_of(numeric_fields), as.numeric), date = as.Date(date, format = "%d/%m/%Y"))
  for (field in numeric_fields) {
    if (any(!is.na(raw[[field]]) & is.na(parsed[[field]]))) stop("Unparseable numeric field: ", field)
  }
  if (any(!is.na(raw$date) & is.na(parsed$date))) stop("An input date could not be parsed as day/month/year.")
  exact_duplicates <- sum(duplicated(parsed))
  parsed <- distinct(parsed)
  if (anyDuplicated(parsed[c("date", "hour")])) stop("Conflicting duplicate date/hour records require review.")
  stopifnot(all(na.omit(parsed$hour) %in% 0:23), all(na.omit(parsed$rentals) >= 0))
  stopifnot(all(na.omit(parsed$humidity_pct) >= 0 & na.omit(parsed$humidity_pct) <= 100))
  for (field in c("wind_ms", "visibility_10m", "solar_mj_m2", "rainfall_mm", "snowfall_cm")) {
    if (any(parsed[[field]] < 0, na.rm = TRUE)) stop("Invalid negative measurement in ", field)
  }
  stopifnot(all(na.omit(parsed$functioning) %in% c("Yes", "No")),
            all(na.omit(parsed$holiday) %in% c("Holiday", "No Holiday")),
            all(na.omit(parsed$season) %in% c("Winter", "Spring", "Summer", "Autumn")))

  data <- parsed |>
    mutate(
      timestamp = as.POSIXct(paste(date, sprintf("%02d:00:00", hour)), tz = "Asia/Seoul"),
      weekday = factor(as.integer(format(date, "%u")), levels = 1:7,
                       labels = c("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")),
      hour_factor = factor(hour, levels = 0:23),
      day_type = factor(if_else(as.integer(format(date, "%u")) >= 6L | holiday == "Holiday",
                                "Weekend or holiday", "Working day"),
                        levels = c("Working day", "Weekend or holiday")),
      season = factor(season, levels = c("Winter", "Spring", "Summer", "Autumn")),
      doy = as.integer(format(date, "%j")),
      doy_sin = sin(2 * pi * (doy - 1) / 365),
      doy_cos = cos(2 * pi * (doy - 1) / 365)
    ) |>
    arrange(timestamp)
  # A complete hourly series should have a one-hour spacing throughout.
  if (any(diff(as.numeric(data$timestamp)) != 3600)) stop("Hourly timestamp coverage is incomplete or irregular.")

  required <- c("date", "rentals", "hour", "temp_c", "humidity_pct", "wind_ms",
                "visibility_10m", "solar_mj_m2", "rainfall_mm", "snowfall_cm", "weekday", "day_type")
  complete <- complete.cases(data[, required])
  active <- data |> filter(functioning == "Yes", complete)
  closures <- data |> filter(functioning == "No")
  stopifnot(nrow(active) >= 100L)
  train <- active |> filter(date <= as.Date("2018-07-31"))
  validation <- active |> filter(date >= as.Date("2018-08-01"), date <= as.Date("2018-09-30"))
  test <- active |> filter(date >= as.Date("2018-10-01"), date <= as.Date("2018-11-30"))
  stopifnot(nrow(train) > 100L, nrow(validation) > 100L, nrow(test) > 100L,
            nrow(train) + nrow(validation) + nrow(test) == nrow(active),
            max(train$timestamp) < min(validation$timestamp), max(validation$timestamp) < min(test$timestamp))
  split_summary <- bind_rows(
    train |> summarise(partition = "Training", n = n(), first_date = min(date), last_date = max(date)),
    validation |> summarise(partition = "Validation", n = n(), first_date = min(date), last_date = max(date)),
    test |> summarise(partition = "Test", n = n(), first_date = min(date), last_date = max(date))
  )
  audit <- tibble(
    check = c("input_rows", "input_columns", "exact_duplicates_removed", "missing_cells",
              "functioning_hours", "non_functioning_hours", "non_functioning_hours_with_nonzero_rentals",
              "active_rows_excluded_for_missing_values", "analysis_rows", "first_date", "last_date"),
    value = as.character(c(nrow(raw), ncol(raw), exact_duplicates, sum(is.na(raw)),
                           sum(data$functioning == "Yes", na.rm = TRUE), nrow(closures),
                           sum(closures$rentals != 0, na.rm = TRUE),
                           sum(data$functioning == "Yes" & !complete, na.rm = TRUE), nrow(active),
                           as.character(min(data$date)), as.character(max(data$date))))
  )
  write_table(audit, "data_audit")
  write_table(split_summary, "split_summary")
  variable_dictionary <- tibble(
    source_column = original_names, variable = canonical_names,
    description = c("Seoul local calendar date", "Bikes rented during this hour", "Local hour, 0 to 23",
      "Air temperature, degrees Celsius", "Relative humidity, percent", "Wind speed, metres per second",
      "Visibility in units of 10 metres", "Dew-point temperature, degrees Celsius",
      "Solar radiation, megajoules per square metre", "Rainfall, millimetres", "Snowfall, centimetres",
      "Recorded season", "Holiday or No Holiday", "Whether the bike service was functioning")
  )
  write_table(variable_dictionary, "variable_dictionary")
  dir.create(file.path(output_root, "data", "clean"), recursive = TRUE, showWarnings = FALSE)
  readr::write_csv(data, file.path(output_root, "data", "clean", "seoul_bike_clean.csv"))
  saveRDS(data, file.path(output_root, "data", "clean", "seoul_bike_clean.rds"), compress = "xz")

  # Fixed specifications below are set before viewing test performance.
  linear_formula <- rentals ~ hour_factor * day_type + temp_c + I(temp_c^2) + humidity_pct +
    wind_ms + visibility_10m + solar_mj_m2 + log1p(rainfall_mm) + log1p(snowfall_cm) + doy_sin + doy_cos
  tree_formula <- rentals ~ hour + day_type + temp_c + humidity_pct + wind_ms + visibility_10m +
    solar_mj_m2 + rainfall_mm + snowfall_cm + doy_sin + doy_cos
  tree_controls <- rpart::rpart.control(cp = 0, minsplit = 60, minbucket = 30, maxdepth = 8, xval = 0)
  baseline_train <- fit_calendar_baseline(train)
  linear_train <- lm(linear_formula, data = train)
  tree_full_train <- rpart::rpart(tree_formula, data = train, method = "anova", control = tree_controls)
  cp_grid <- c(0, 0.0005, 0.001, 0.002, 0.005, 0.01)
  tree_tuning <- purrr::map_dfr(cp_grid, function(cp) {
    tree_candidate <- rpart::prune(tree_full_train, cp = cp)
    predictions <- pmax(0, predict(tree_candidate, newdata = validation))
    prediction_metrics(validation$rentals, predictions, "Regression tree", "Validation") |>
      mutate(cp = cp, terminal_nodes = sum(tree_candidate$frame$var == "<leaf>"))
  }) |>
    arrange(rmse, desc(cp))
  chosen_cp <- tree_tuning$cp[[1]]
  tree_train <- rpart::prune(tree_full_train, cp = chosen_cp)
  validation_predictions <- tibble(
    actual = validation$rentals,
    `Calendar baseline` = pmax(0, predict_calendar_baseline(baseline_train, validation)),
    `Linear regression` = pmax(0, predict(linear_train, newdata = validation)),
    `Regression tree` = pmax(0, predict(tree_train, newdata = validation))
  )
  model_names <- c("Calendar baseline", "Linear regression", "Regression tree")
  validation_metrics <- purrr::map_dfr(model_names, function(name)
    prediction_metrics(validation_predictions$actual, validation_predictions[[name]], name, "Validation")) |>
    arrange(rmse)
  selected_model <- validation_metrics$model[[1]]
  write_table(tree_tuning, "tree_tuning")
  write_table(validation_metrics, "validation_metrics")

  # Freeze model choice and hyperparameters, then refit on train + validation.
  development <- bind_rows(train, validation)
  fitted_models <- list(
    baseline = fit_calendar_baseline(development),
    linear = lm(linear_formula, data = development),
    tree = rpart::prune(rpart::rpart(tree_formula, data = development, method = "anova", control = tree_controls), cp = chosen_cp)
  )
  test_predictions <- test |>
    select(timestamp, date, hour, weekday, day_type, season, rentals) |>
    mutate(
      `Calendar baseline` = pmax(0, predict_calendar_baseline(fitted_models$baseline, test)),
      `Linear regression` = pmax(0, predict(fitted_models$linear, newdata = test)),
      `Regression tree` = pmax(0, predict(fitted_models$tree, newdata = test))
    )
  test_metrics <- purrr::map_dfr(model_names, function(name)
    prediction_metrics(test_predictions$rentals, test_predictions[[name]], name, "Test")) |>
    mutate(selected_on_validation = model == selected_model)
  selected_predictions <- test_predictions |>
    transmute(timestamp, date, hour, weekday, day_type, actual = rentals,
              predicted = .data[[selected_model]], error = predicted - actual)
  write_table(test_metrics, "test_metrics")
  write_table(test_predictions, "test_predictions")
  write_table(tibble(term = names(coef(fitted_models$linear)), estimate = unname(coef(fitted_models$linear))), "linear_coefficients")

  hourly_profile <- active |> group_by(day_type, hour) |>
    summarise(n = n(), mean_rentals = mean(rentals), median_rentals = median(rentals), .groups = "drop")
  monthly_summary <- active |> mutate(month = as.Date(format(date, "%Y-%m-01"))) |>
    group_by(month) |> summarise(active_hours = n(), mean_rentals = mean(rentals), total_rentals = sum(rentals), .groups = "drop")
  weather_summary <- active |> mutate(weather = if_else(rainfall_mm > 0, "Rain recorded", "No rain recorded")) |>
    group_by(weather) |> summarise(n = n(), mean_rentals = mean(rentals), median_rentals = median(rentals), .groups = "drop")
  temperature_summary <- active |> mutate(temperature_band_c = 5 * floor(temp_c / 5) + 2.5) |>
    group_by(temperature_band_c) |> summarise(n = n(), mean_rentals = mean(rentals), .groups = "drop")
  residual_hour <- selected_predictions |> group_by(hour) |>
    summarise(n = n(), mean_error = mean(error), mae = mean(abs(error)), .groups = "drop")
  write_table(hourly_profile, "hourly_profile")
  write_table(monthly_summary, "monthly_summary")
  write_table(weather_summary, "weather_summary")
  write_table(temperature_summary, "temperature_summary")
  write_table(residual_hour, "test_error_by_hour")
  numeric_summary <- purrr::map_dfr(numeric_fields, function(field) {
    x <- active[[field]]
    tibble(variable = field, n = sum(!is.na(x)), mean = mean(x, na.rm = TRUE),
           sd = sd(x, na.rm = TRUE), median = median(x, na.rm = TRUE),
           minimum = min(x, na.rm = TRUE), maximum = max(x, na.rm = TRUE))
  })
  write_table(numeric_summary, "numeric_summary_active_hours")
  stopifnot(all(is.finite(selected_predictions$predicted)),
            all(selected_predictions$predicted >= 0),
            sum(test_metrics$selected_on_validation) == 1L,
            identical(test_predictions$timestamp, test$timestamp))

  project_theme <- theme_minimal(base_size = 13) +
    theme(plot.title = element_text(face = "bold", size = 16),
          plot.subtitle = element_text(size = 11, color = "#445366"),
          panel.grid.minor = element_blank(), legend.position = "top",
          plot.caption = element_text(hjust = 0, size = 9, color = "#526074"),
          plot.background = element_rect(fill = "white", colour = NA))
  palette <- c("Working day" = "#165A72", "Weekend or holiday" = "#DC7542")
  figures <- list()
  figures$hourly_profile <- ggplot(hourly_profile, aes(hour, mean_rentals, colour = day_type)) +
    geom_line(linewidth = 1.15) + geom_point(size = 1.8) +
    scale_colour_manual(values = palette) + scale_x_continuous(breaks = seq(0, 23, 3)) +
    labs(title = "Rental demand changes across the day", subtitle = "Mean rentals per functioning hour across the full observation year",
         x = "Local hour in Seoul", y = "Mean bikes rented per hour", colour = NULL,
         caption = "Descriptive associations; weekday groups also differ in weather and season.") + project_theme
  figures$temperature <- ggplot(temperature_summary, aes(temperature_band_c, mean_rentals)) +
    geom_line(linewidth = 1, colour = "#165A72") + geom_point(aes(size = n), colour = "#165A72") +
    scale_size_continuous(range = c(2, 7), name = "Active hours") +
    labs(title = "Warmer temperature bands generally have more rentals", subtitle = "Unadjusted means in 5 C bands, functioning hours only",
         x = "Temperature band midpoint (C)", y = "Mean bikes rented per hour",
         caption = "Season, time of day and other weather variables can confound this relationship.") + project_theme
  figures$monthly <- ggplot(monthly_summary, aes(month, mean_rentals)) +
    geom_col(fill = "#165A72", width = 23) + scale_x_date(date_breaks = "1 month", date_labels = "%b") +
    labs(title = "Hourly rentals vary substantially across months", subtitle = "December 2017 to November 2018, functioning hours only",
         x = NULL, y = "Mean bikes rented per active hour",
         caption = "One observed annual cycle cannot establish a recurring seasonal effect.") + project_theme
  figures$validation <- ggplot(validation_metrics, aes(reorder(model, rmse), rmse)) +
    geom_col(fill = "#165A72", width = 0.6) + geom_text(aes(label = sprintf("%.1f", rmse)), hjust = -0.12, size = 4.5) +
    coord_flip() + expand_limits(y = max(validation_metrics$rmse) * 1.13) +
    labs(title = "Model choice uses August and September validation", subtitle = paste("Selected before test evaluation:", selected_model),
         x = NULL, y = "Validation RMSE (bikes per hour)", caption = "Lower RMSE is better; test months do not determine model selection.") + project_theme
  figures$test_predictions <- ggplot(selected_predictions, aes(actual, predicted)) +
    geom_point(alpha = 0.25, colour = "#165A72", size = 1.6) +
    geom_abline(slope = 1, intercept = 0, linetype = 2, colour = "#DC7542", linewidth = 0.9) +
    labs(title = "Predictions are evaluated on later, unseen months", subtitle = paste(selected_model, "on October and November 2018"),
         x = "Observed hourly rentals", y = "Predicted hourly rentals",
         caption = "The dashed line denotes perfect predictions. Weather is measured in the same hour.") + project_theme
  figures$test_errors <- ggplot(residual_hour, aes(hour, mean_error)) +
    geom_hline(yintercept = 0, colour = "#8B96A3", linetype = 2) +
    geom_line(colour = "#165A72", linewidth = 1.1) + geom_point(colour = "#165A72", size = 2) +
    scale_x_continuous(breaks = seq(0, 23, 3)) +
    labs(title = "Prediction bias can differ by hour", subtitle = paste("Test-set diagnostics for", selected_model),
         x = "Local hour in Seoul", y = "Mean prediction minus observation",
         caption = "Positive values indicate overprediction. Hourly observations are serially correlated.") + project_theme
  first_week <- tibble(timestamp = seq(min(test$timestamp), min(test$timestamp) + 7 * 24 * 3600 - 3600, by = "hour")) |>
    left_join(selected_predictions |> select(timestamp, actual, predicted), by = "timestamp")
  figures$test_week <- first_week |> select(timestamp, Observed = actual, Predicted = predicted) |>
    pivot_longer(-timestamp, names_to = "series", values_to = "rentals") |>
    ggplot(aes(timestamp, rentals, colour = series)) + geom_line(linewidth = 0.8, na.rm = TRUE) +
    scale_colour_manual(values = c(Observed = "#165A72", Predicted = "#DC7542")) +
    labs(title = "The first test week reveals the shape of prediction errors", subtitle = "A prespecified seven-day window beginning 1 October 2018",
         x = NULL, y = "Bikes rented per hour", colour = NULL,
         caption = "Gaps mark non-functioning hours. This illustrative week is part of the fixed test set.") + project_theme
  figure_names <- c(hourly_profile = "01_hourly_profile.png", temperature = "02_temperature.png",
                    monthly = "03_monthly_rentals.png", validation = "04_validation_rmse.png",
                    test_predictions = "05_test_predictions.png", test_errors = "06_test_hourly_bias.png",
                    test_week = "07_test_week.png")
  # The main EDA figures are built separately by scripts/visualisations.R.
  # Only compact model diagnostics are exported here; all plot objects remain in the RDS.
  for (name in c("validation", "test_errors", "test_week")) {
    ggsave(file.path(output_root, "img", figure_names[[name]]), figures[[name]], width = 9, height = 5.1, dpi = 160, bg = "white")
  }

  source_checksum <- digest::digest(file = data_file, algo = "sha256")
  summary <- list(
    dataset = list(source = "UCI Machine Learning Repository, Seoul Bike Sharing Demand", input_file = data_file,
                   sha256 = source_checksum, raw_rows = nrow(raw), active_rows = nrow(active),
                   non_functioning_rows = nrow(closures), missing_cells = sum(is.na(raw)),
                   first_date = as.character(min(data$date)), last_date = as.character(max(data$date))),
    split = split_summary,
    selection = list(rule = "Lowest validation RMSE, before examining the fixed test partition",
                     selected_model = selected_model, tree_cp = chosen_cp,
                     tree_minbucket = 30, tree_maxdepth = 8),
    validation_metrics = validation_metrics,
    test_metrics = test_metrics,
    descriptive = list(hourly_profile = hourly_profile, monthly = monthly_summary, rain = weather_summary),
    caveats = c("Observed same-hour weather: conditional retrospective prediction, not an operational advance forecast.",
                "Active-service hours only; closures are not treated as zero-demand hours.",
                "A single city and annual cycle; temporal holdout measures a specific seasonal shift.",
                "Associational analysis does not identify causal effects.",
                "Hourly serial dependence means conventional independent-observation inference is inappropriate."),
    random_seed = 20261023
  )
  jsonlite::write_json(summary, file.path(output_root, "outputs", "results-summary.json"), pretty = TRUE, auto_unbox = TRUE, digits = 10)
  results <- list(data = data, active = active, train = train, validation = validation, test = test,
                  audit = audit, split_summary = split_summary, variable_dictionary = variable_dictionary,
                  hourly_profile = hourly_profile, monthly_summary = monthly_summary, weather_summary = weather_summary,
                  temperature_summary = temperature_summary, numeric_summary = numeric_summary, validation_metrics = validation_metrics, test_metrics = test_metrics,
                  tree_tuning = tree_tuning, selected_model = selected_model, chosen_cp = chosen_cp,
                  fitted_models = fitted_models, test_predictions = test_predictions,
                  selected_predictions = selected_predictions, residual_hour = residual_hour,
                  plots = figures, summary = summary)
  saveRDS(results, file.path(output_root, "outputs", "analysis-results.rds"), compress = "xz")
  writeLines(capture.output(sessionInfo()), file.path(output_root, "outputs", "session-info.txt"))
  message("Analysis completed. Selected on validation: ", selected_model)
  print(validation_metrics)
  print(test_metrics)
  invisible(results)
}

if (sys.nframe() == 0L) run_analysis()
