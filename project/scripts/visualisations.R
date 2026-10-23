# Recreate the three main descriptive figures from the original UCI CSV.
# Run from the project root in RStudio: source("scripts/visualisations.R")
# The full year is used here for descriptive summaries. The prediction analysis
# uses its own pre-specified chronological split in scripts/analysis.R.

suppressPackageStartupMessages(library(tidyverse))

if (!file.exists("data/SeoulBikeData.csv")) {
  stop("Open the project in RStudio and run this script from the project root.")
}
dir.create("img", showWarnings = FALSE)
dir.create("tables", showWarnings = FALSE)

viz_raw <- read_csv(
  "data/SeoulBikeData.csv",
  locale = locale(encoding = "Latin1"),
  show_col_types = FALSE
)
viz_data <- viz_raw |>
  transmute(
    date = as.Date(Date, format = "%d/%m/%Y"),
    hour = as.integer(Hour),
    rentals = `Rented Bike Count`,
    temperature_c = `Temperature(°C)`,
    rainfall_mm = `Rainfall(mm)`,
    season = factor(Seasons, levels = c("Winter", "Spring", "Summer", "Autumn")),
    functioning = `Functioning Day` == "Yes",
    holiday = Holiday
  ) |>
  mutate(
    day_type = factor(
      if_else(as.integer(format(date, "%u")) <= 5 & holiday == "No Holiday",
              "Working day", "Weekend or holiday"),
      levels = c("Working day", "Weekend or holiday")
    )
  )

stopifnot(
  nrow(viz_data) == 8760L,
  !anyNA(viz_data),
  !anyDuplicated(viz_data[c("date", "hour")]),
  all(viz_data$hour %in% 0:23),
  all(viz_data$rentals >= 0)
)

viz_active <- filter(viz_data, functioning)
viz_closed <- filter(viz_data, !functioning)
viz_source <- "Source: UCI Seoul Bike Sharing Demand, dataset 560. DOI: 10.24432/C5F62R."
viz_ink <- "#183B4E"
viz_teal <- "#168B8B"
viz_coral <- "#DA765E"

viz_theme <- theme_minimal(base_size = 13, base_family = "sans") +
  theme(
    text = element_text(colour = viz_ink),
    plot.title = element_text(size = 20, face = "bold", margin = margin(b = 8)),
    plot.subtitle = element_text(size = 12.5, colour = "#506672", margin = margin(b = 16)),
    plot.caption = element_text(size = 10, colour = "#536A75", hjust = 0, lineheight = 1.15,
                                margin = margin(t = 14)),
    plot.title.position = "plot",
    plot.caption.position = "plot",
    plot.background = element_rect(fill = "white", colour = NA),
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(colour = "#E4EBEE", linewidth = 0.35),
    axis.title = element_text(size = 12),
    axis.text = element_text(size = 11, colour = "#425B68"),
    legend.position = "top",
    legend.title = element_text(size = 11),
    legend.text = element_text(size = 11),
    legend.key.width = grid::unit(1.7, "lines"),
    plot.margin = margin(20, 22, 16, 16)
  )

# Figure 1. Every observation retains its date and hour. A square-root colour
# scale makes low and moderate demand visible without clipping high counts.
viz_heatmap <- ggplot(viz_active, aes(x = date, y = hour, fill = rentals)) +
  geom_tile(width = 1, height = 1) +
  geom_tile(data = viz_closed, fill = "#ECA28E", width = 1, height = 1) +
  scale_fill_gradientn(
    colours = c("#F4F7F8", "#C2E2E3", "#75C1C1", "#258D99", "#123C55"),
    transform = "sqrt",
    limits = c(0, max(viz_data$rentals)),
    breaks = c(0, 250, 1000, 2000, 3500),
    labels = scales::label_comma(),
    name = "Rentals per hour"
  ) +
  scale_x_date(
    breaks = seq(as.Date("2017-12-01"), as.Date("2018-11-01"), by = "month"),
    date_labels = "%b\n%Y",
    expand = expansion(add = 0.5)
  ) +
  scale_y_continuous(
    breaks = c(0, 6, 12, 18, 23),
    labels = c("00:00", "06:00", "12:00", "18:00", "23:00"),
    expand = expansion(add = 0.5)
  ) +
  labs(
    title = "A year of Seoul bike rentals, one hour at a time",
    subtitle = "Evening demand strengthens in the warmer months. Coral cells mark non-functioning service hours.",
    x = NULL, y = "Hour of day",
    caption = paste0(
      "All 8,760 hourly records, December 2017 to November 2018. ",
      nrow(viz_closed), " non-functioning hours appear in coral.\n",
      "Rental counts use a square-root colour scale. ", viz_source
    )
  ) +
  guides(fill = guide_colourbar(
    direction = "horizontal", title.position = "top", title.hjust = 0,
    barwidth = grid::unit(115, "mm"), barheight = grid::unit(4, "mm")
  )) +
  viz_theme +
  theme(
    legend.position = "bottom", legend.justification = "left",
    panel.grid = element_blank(),
    axis.text.x = element_text(size = 10.5, lineheight = 1.1)
  )

ggsave("img/fig-01-demand-heatmap.png", viz_heatmap,
       width = 12.2, height = 5.9, dpi = 220, bg = "white")

# Figure 2. Each mean counts the functioning observations in its particular
# season, day type and hour. Working days are Monday-Friday non-holidays.
viz_hourly <- viz_active |>
  group_by(season, day_type, hour) |>
  summarise(n_hours = n(), mean_rentals = mean(rentals), .groups = "drop")
viz_profile_denominators <- viz_active |>
  group_by(season, day_type) |>
  summarise(n_dates = n_distinct(date), n_hours = n(), .groups = "drop")
viz_profile_peaks <- viz_hourly |>
  group_by(season, day_type) |>
  slice_max(mean_rentals, n = 1, with_ties = FALSE) |>
  ungroup()

viz_profiles <- ggplot(viz_hourly, aes(hour, mean_rentals, colour = day_type)) +
  geom_vline(xintercept = c(8, 18), linetype = "dotted", colour = "#BBCBD2", linewidth = 0.4) +
  geom_line(linewidth = 1.1) +
  geom_point(size = 1.25) +
  facet_wrap(vars(season), ncol = 2) +
  scale_colour_manual(values = c("Working day" = viz_ink, "Weekend or holiday" = viz_coral), name = NULL) +
  scale_x_continuous(breaks = c(0, 6, 12, 18, 23),
                     labels = c("00:00", "06:00", "12:00", "18:00", "23:00")) +
  scale_y_continuous(labels = scales::label_comma(), limits = c(0, NA),
                     expand = expansion(mult = c(0, 0.08))) +
  labs(
    title = "Daily demand depends on the type of day and season",
    subtitle = "Mean hourly rentals by season, using functioning service hours only",
    x = "Hour of day", y = "Mean rentals per hour",
    caption = paste0(
      "Working day means Monday-Friday with no public holiday. The comparison group includes weekends and public holidays.\n",
      "Means use the available service hours in each season, day type and hour. ",
      viz_source
    )
  ) +
  viz_theme +
  theme(
    strip.text = element_text(face = "bold", size = 13, hjust = 0, margin = margin(b = 8, t = 6)),
    panel.spacing = grid::unit(1.4, "lines"),
    legend.justification = "left", legend.box.just = "left",
    panel.grid.major.x = element_blank()
  )

ggsave("img/fig-02-hourly-profiles.png", viz_profiles,
       width = 12.2, height = 7.0, dpi = 220, bg = "white")

# Figure 3. Compare rain groups within fixed 5-degree bands. This is an
# unadjusted descriptive comparison: temperature, hour and season can covary.
viz_weather <- viz_active |>
  mutate(
    temperature_band_low = floor(temperature_c / 5) * 5,
    temperature_band_mid = temperature_band_low + 2.5,
    rain_group = factor(
      if_else(rainfall_mm > 0, "Rain recorded", "No recorded rain"),
      levels = c("No recorded rain", "Rain recorded")
    )
  ) |>
  group_by(temperature_band_low, temperature_band_mid, rain_group) |>
  summarise(n_hours = n(), mean_rentals = mean(rentals), .groups = "drop") |>
  mutate(displayed = n_hours >= 20)

viz_weather_plot <- ggplot(
  filter(viz_weather, displayed),
  aes(temperature_band_mid, mean_rentals, colour = rain_group, shape = rain_group)
) +
  geom_line(linewidth = 0.9) +
  geom_point(aes(size = n_hours), stroke = 0.75) +
  scale_colour_manual(values = c("No recorded rain" = viz_teal, "Rain recorded" = viz_coral), name = NULL) +
  scale_shape_manual(values = c("No recorded rain" = 16, "Rain recorded" = 17), name = NULL) +
  scale_size_area(max_size = 7.5, breaks = c(50, 500, 1000), name = "Recorded hours") +
  scale_x_continuous(breaks = seq(-15, 35, 10)) +
  scale_y_continuous(labels = scales::label_comma(), limits = c(0, NA),
                     expand = expansion(mult = c(0, 0.08))) +
  labs(
    title = "Rainy hours record fewer rentals across temperature bands",
    subtitle = "Mean demand within 5°C bands, using functioning service hours only",
    x = "Temperature band midpoint (°C)", y = "Mean rentals per hour",
    caption = paste0(
      "Only groups with at least 20 recorded hours appear. Point area represents the number of hours.\n",
      "These unadjusted associations also reflect differences in season and time of day. ", viz_source
    )
  ) +
  viz_theme +
  guides(
    colour = guide_legend(order = 1, override.aes = list(size = 3)),
    shape = guide_legend(order = 1),
    size = guide_legend(order = 2, override.aes = list(colour = "#7D909A", shape = 16))
  ) +
  theme(legend.justification = "left", legend.box.just = "left")

ggsave("img/fig-03-weather-demand.png", viz_weather_plot,
       width = 12.2, height = 6.0, dpi = 220, bg = "white")

write_csv(viz_hourly, "tables/viz-hourly-profiles.csv")
write_csv(viz_profile_denominators, "tables/viz-profile-denominators.csv")
write_csv(viz_profile_peaks, "tables/viz-profile-peaks.csv")
write_csv(viz_weather, "tables/viz-weather-bands.csv")

viz_overview <- viz_data |>
  summarise(
    total_hours = n(), active_hours = sum(functioning), closed_hours = sum(!functioning),
    first_date = as.character(min(date)), last_date = as.character(max(date)),
    max_hourly_rentals = max(rentals), total_rentals = sum(rentals)
  )
viz_rain_summary <- viz_active |>
  mutate(rain_group = if_else(rainfall_mm > 0, "Rain recorded", "No recorded rain")) |>
  group_by(rain_group) |>
  summarise(n_hours = n(), mean_rentals = mean(rentals), .groups = "drop")

viz_findings <- list(
  scope = "Descriptive summaries across the full observed year. Model evaluation has a separate chronological split.",
  overview = viz_overview,
  hourly_peaks = viz_profile_peaks,
  rain_summary = viz_rain_summary,
  main_finding = "The heatmap shows stronger evening demand in the warmer months, alongside a much quieter winter.",
  profile_finding = "The mean working-day peak occurs at 18:00 in spring, summer and autumn, and at 08:00 in winter.",
  weather_finding = "For displayed temperature bands containing at least 20 hours per rain group, rainy hours have lower mean rentals than dry hours in every overlapping band.",
  caveat = "All findings describe observed associations, with no causal interpretation. Non-functioning service hours are shown separately in the heatmap and excluded from the profile and weather means.",
  source = "Seoul Bike Sharing Demand (2020), UCI Machine Learning Repository, https://doi.org/10.24432/C5F62R, CC BY 4.0. Retrieved 23 October 2026."
)
jsonlite::write_json(viz_findings, "tables/viz-findings.json", auto_unbox = TRUE,
                     pretty = TRUE, dataframe = "rows", digits = 8)
message("Created the three descriptive figures and their summary tables.")
