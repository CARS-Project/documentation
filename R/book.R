# Helpers shared by every chapter. Each chapter that uses data starts with
#   source("R/book.R")
# (chunks run from the project root: execute-dir is set in _quarto.yml).
#
# Chapters read pipeline outputs only through read_pipeline() and
# read_example(), never from ../MOT-pipline directly, so the book can be
# rebuilt from the snapshot committed in data/. See chapters/maintaining.qmd.

suppressPackageStartupMessages({
  library(ggplot2)
})

knitr::opts_chunk$set(fig.width = 7, fig.height = 4.2, dpi = 150,
                      fig.align = "center")

# ---- Reading data ----------------------------------------------------------

pipeline_path <- function(...) {
  p <- file.path("data", "pipeline", ...)
  if (!file.exists(p)) {
    stop("Pipeline file missing: ", p, ". Add it to data/manifest.yml and ",
         "run scripts/sync-pipeline.R")
  }
  p
}

read_pipeline <- function(...) {
  utils::read.csv(pipeline_path(...), stringsAsFactors = FALSE,
                  check.names = FALSE, na.strings = c("", "NA"))
}

read_example <- function(name) {
  p <- file.path("data", "examples", paste0(name, ".csv"))
  if (!file.exists(p)) {
    stop("Example result missing: ", p, ". Run scripts/run-examples.R")
  }
  utils::read.csv(p, stringsAsFactors = FALSE, check.names = FALSE,
                  na.strings = "")
}

provenance <- function(item) {
  p <- read_pipeline("provenance.csv")
  p$value[p$item == item]
}

# ---- Formatting numbers for the text ---------------------------------------

fmt_n <- function(x, digits = 0) {
  formatC(round(x, digits), format = "f", digits = digits, big.mark = ",")
}
fmt_pct <- function(x, digits = 1) {
  paste0(formatC(100 * x, format = "f", digits = digits), "%")
}
fmt_m <- function(x, digits = 1) {
  paste0(formatC(x / 1e6, format = "f", digits = digits), " million")
}

kable <- function(x, ...) {
  knitr::kable(x, format.args = list(big.mark = ","), ...)
}

# ---- Charts ----------------------------------------------------------------
# Categorical slots in fixed order (validated reference palette); use at most
# four series per chart, folding the rest into "Other" or small multiples.

cars_cols <- c("#2a78d6", "#eb6834", "#1baf7a", "#eda100")
cars_seq <- c("#cde2fb", "#86b6ef", "#3987e5", "#1c5cab", "#0d366b")
ink <- "#0b0b0b"
ink_muted <- "#52514e"

theme_cars <- function(base_size = 11) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.background = element_rect(fill = "white", colour = NA),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(colour = "#e6e5e1", linewidth = 0.3),
      axis.text = element_text(colour = ink_muted),
      axis.title = element_text(colour = ink_muted),
      plot.title = element_text(colour = ink, face = "bold"),
      plot.title.position = "plot",
      legend.position = "top",
      legend.justification = "left",
      legend.title = element_blank(),
      strip.text = element_text(colour = ink, face = "bold", hjust = 0)
    )
}

scale_y_count <- function(...) {
  scale_y_continuous(labels = scales::label_number(scale_cut =
                                                     scales::cut_short_scale()),
                     ...)
}

# ---- Postcode areas --------------------------------------------------------

read_pca_boundaries <- function() {
  sf::st_read(pipeline_path("inputs", "postcode_areas_100m.gpkg"),
              quiet = TRUE)
}

# Codes in pca_YYYY that are not postcode areas
pca_statuses <- c("unborn", "dead", "unknown")

# ---- Data dictionary -------------------------------------------------------
# The chapters of the Data dictionary part each describe one group of columns
# of the vehicle table. The groups are defined here, once, so the part's
# introduction can check that every column belongs to exactly one of them.
# Year-by-year columns are named with YYYY for the year.

dict_groups <- list(
  identifiers = c("vehicle_id", "dup_vrm", "scope_mileage", "scope_pca",
                  "scope_born", "scope_dvla_activity"),
  registration = c("registration_DVSA", "registration_DVLA",
                   "registration_clean", "plate_type", "plate_date",
                   "plate_date_from", "plate_date_to", "plate_location",
                   "vanity_plate", "plate_ever_changed_VES"),
  make_model = c("make_final", "model_final", "derivative_final",
                 "dft_genmodel", "dft_model", "make_method", "model_method",
                 "model_confidence", "make_DVSA", "model_DVSA", "make_DVLA"),
  vehicle_type = c("body_type", "body_type_src", "test_class",
                   "test_class_src", "test_class_ANON", "type_approval",
                   "type_approval_src", "typeApproval_DVLA",
                   "automatedVehicle_DVLA"),
  body = c("primaryColour_DVSA", "secondaryColour_DVSA", "colour_DVLA",
           "wheelplan", "wheelplan_src", "wheelplan_DVLA", "revenue_weight",
           "revenue_weight_src", "revenueWeight_DVLA"),
  fuel_engine = c("fuel", "fuel_src", "fuel_check", "fuel_simple", "fuel_DFT",
                  "fuel_DFT_src", "fuel_DVSA", "fuelType_DVLA", "engine_cc",
                  "engine_cc_src", "engine_check", "engineSize_DVSA",
                  "engineCapacity_DVLA"),
  emissions = c("co2", "co2_src", "co2_check", "co2Emissions_DVLA",
                "euro_status", "euro_status_src", "euro_standard",
                "euro_check", "euroStatus_DVLA", "realDrivingEmissions_DVLA"),
  dates = c("birth_date", "first_use_date", "first_use_source",
            "firstUsedDate_DVSA", "registrationDate_DVSA",
            "manufactureDate_DVSA", "monthOfFirstRegistration_DVLA",
            "monthOfFirstDvlaRegistration_DVLA", "yearOfManufacture_DVLA",
            "final_test_date_DVSA", "last_mot_year"),
  mileage = c("mileage_YYYY", "legit_mileage_YYYY", "total_mileage"),
  location = c("pca_YYYY"),
  dvla_status = c("taxStatus_DVLA", "taxDueDate_DVLA", "motStatus_DVLA",
                  "motExpiryDate_DVLA", "markedForExport_DVLA",
                  "ever_export_marked", "ever_SORN", "artEndDate_DVLA",
                  "dateOfLastV5CIssued_DVLA", "v5C_issue_date_ever_changed",
                  "change_in_other_VES_field", "dvla_match", "dvla_evidence",
                  "collectionDate_DVLA", "is_error", "error",
                  "n_VES_checks_to_linked_DVSA_regs",
                  "n_VES_checks_for_DVLA_reg", "n_VES_returns",
                  "first_VES_check", "first_VES_return", "last_VES_check",
                  "last_VES_return")
)

# How a column's values are summarised over time: "numeric" and "date" by
# their quartiles, "categorical" by the share of each value, and "id" (unique
# to each vehicle) not at all. Used by scripts/run-values.R and the Values
# sections of the data dictionary chapters.
dict_ids <- c("vehicle_id", "registration_DVSA", "registration_DVLA",
              "registration_clean")
dict_coded <- c("test_class", "test_class_ANON", "euro_standard",
                "dvla_evidence", "ever_export_marked")

dict_kind <- function(column_name, column_type) {
  ifelse(column_name %in% dict_ids, "id",
  ifelse(column_name %in% dict_coded, "categorical",
  ifelse(column_type %in% c("DATE", "TIMESTAMP"), "date",
  ifelse(column_type %in% c("INTEGER", "BIGINT", "DOUBLE"), "numeric",
  "categorical"))))
}

# The data dictionary with year-by-year columns folded into one row each
# (column_name ending _YYYY), their missing share given as a range
dict_columns <- function() {
  dd <- read_pipeline("outputs", "data_dictionary.csv")
  dd$stem <- sub("_[0-9]{4}$", "_YYYY", dd$column_name)
  do.call(rbind, lapply(split(dd, factor(dd$stem, unique(dd$stem))),
                        function(x) {
    rng <- range(x$pct_missing)
    data.frame(column_name = x$stem[1], column_type = x$column_type[1],
               source = x$source[1], description = x$description[1],
               missing = if (rng[1] == rng[2]) paste0(rng[1], "%")
                         else paste0(rng[1], "–", rng[2], "%"))
  }))
}

# Table of a group's columns, in the group's order
dict_table <- function(group) {
  cols <- dict_groups[[group]]
  d <- dict_columns()
  gone <- setdiff(cols, d$column_name)
  if (length(gone) > 0) {
    stop("Not in the data dictionary: ", paste(gone, collapse = ", "),
         ". Update dict_groups in R/book.R")
  }
  d <- d[match(cols, d$column_name), ]
  d$column_name <- paste0("`", d$column_name, "`")
  kable(d, row.names = FALSE,
        col.names = c("Column", "Type", "Source", "Description", "Missing"))
}

read_coverage <- function(name) {
  p <- file.path("data", "coverage", paste0(name, ".csv"))
  if (!file.exists(p)) {
    stop("Coverage table missing: ", p, ". Run scripts/run-coverage.R")
  }
  utils::read.csv(p, stringsAsFactors = FALSE, check.names = FALSE,
                  na.strings = "")
}

# Share of vehicles with a value, for each column, overall and by when the
# vehicles were first used
coverage_bands <- c("Before 2000" = -Inf, "2000–09" = 2000,
                    "2010–19" = 2010, "2020 on" = 2020)

coverage_share <- function(cols) {
  cv <- read_coverage("coverage_by_first_use_year")
  cv <- cv[cv$column_name %in% cols, ]
  cv$band <- cut(cv$first_use_year, c(coverage_bands, Inf), right = FALSE,
                 labels = names(coverage_bands))
  share <- function(x) sum(x$n_present) / sum(x$n_vehicles)
  out <- do.call(rbind, lapply(cols, function(k) {
    x <- cv[cv$column_name == k, ]
    by_band <- vapply(names(coverage_bands), function(b) {
      share(x[!is.na(x$band) & x$band == b, ])
    }, numeric(1))
    data.frame(column_name = k, all = share(x), t(by_band), check.names = FALSE)
  }))
  rownames(out) <- NULL
  out
}

coverage_table <- function(cols) {
  out <- coverage_share(cols)
  out[-1] <- lapply(out[-1], fmt_pct)
  out$column_name <- paste0("`", out$column_name, "`")
  kable(out, row.names = FALSE,
        col.names = c("Column", "All vehicles", names(coverage_bands)),
        align = c("l", rep("r", length(coverage_bands) + 1)))
}

# Small multiples, one panel per column, by year of first use: the share of
# vehicles with a value or, with flags = TRUE, the share with the flag TRUE
coverage_plot <- function(cols, from = 1990, ncol = 2, flags = FALSE) {
  if (flags) {
    cv <- read_coverage("true_by_first_use_year")
    cv$n_present <- cv$n_true
  } else {
    cv <- read_coverage("coverage_by_first_use_year")
  }
  cv <- cv[cv$column_name %in% cols & !is.na(cv$first_use_year) &
             cv$first_use_year >= from &
             cv$first_use_year <= as.integer(format(Sys.Date(), "%Y")), ]
  cv$share <- cv$n_present / cv$n_vehicles
  cv$column_name <- factor(cv$column_name, cols)
  ggplot(cv, aes(first_use_year, share)) +
    geom_line(colour = cars_cols[1], linewidth = 0.7) +
    facet_wrap(~column_name, ncol = ncol) +
    scale_y_continuous(labels = scales::label_percent(), limits = c(0, 1),
                       breaks = c(0, 0.5, 1)) +
    labs(x = "Year of first use",
         y = if (flags) "Vehicles with TRUE" else "Vehicles with a value") +
    theme_cars() +
    theme(panel.spacing.x = grid::unit(1.2, "lines"))
}

# Share with a value as text, for one column of coverage_share() output
cov_pct <- function(cs, col, band = "all", digits = 0) {
  fmt_pct(cs[[band]][cs$column_name == col], digits)
}

# Share with a value as text, for one column and year of first use
cov_year <- function(col, year, digits = 0) {
  cv <- read_coverage("coverage_by_first_use_year")
  x <- cv[cv$column_name == col & cv$first_use_year %in% year, ]
  fmt_pct(sum(x$n_present) / sum(x$n_vehicles), digits)
}

# ---- Values over time ------------------------------------------------------
# Charts of each column's values by year of first use (or by year, for the
# year-by-year columns), from the summaries made by scripts/run-values.R.

read_values <- function(name) {
  p <- file.path("data", "values", paste0(name, ".csv"))
  if (!file.exists(p)) {
    stop("Values table missing: ", p, ". Run scripts/run-values.R")
  }
  utils::read.csv(p, stringsAsFactors = FALSE, check.names = FALSE,
                  na.strings = "")
}

# Validated categorical order (slots 1-8), then neutrals for Other and Blank
values_cols <- c(cars_cols, "#e87ba4", "#008300", "#6250d6", "#e34948")
other_col <- "#a3a29b"
blank_col <- "#dddcd6"

values_data <- function(col) {
  by_year <- grepl("_YYYY$", col)
  d <- dict_columns()
  kind <- dict_kind(col, d$column_type[d$column_name == col])
  file <- paste0(if (kind %in% c("numeric", "date")) "numeric" else "categorical",
                 if (by_year) "_by_year" else "_by_first_use_year")
  v <- read_values(file)
  v <- v[v$column_name == col, ]
  v$period <- if (by_year) v$year else v$first_use_year
  list(v = v, kind = kind,
       x_lab = if (by_year) "Year" else "Year of first use",
       when = if (by_year) "by year" else "by year of first use")
}

# A log scale is used where the maximum dwarfs the upper quartile
values_log <- function(v) {
  all(v$min >= 0) && max(v$max) > 20 * max(v$q3, 1)
}

values_caption <- function(col) {
  x <- values_data(col)
  if (x$kind == "categorical") {
    return(sprintf("Share of vehicles by value of %s, %s.", col, x$when))
  }
  cap <- sprintf(
    "Minimum, quartiles and maximum of %s, %s, among vehicles with a value.",
    col, x$when)
  if (x$kind == "numeric" && values_log(x$v)) cap <- paste(cap, "Log scale.")
  if (x$kind == "date") {
    cap <- paste(cap, "Extreme minimums and maximums run off the chart.")
  }
  cap
}

values_plot <- function(col) {
  x <- values_data(col)
  v <- x$v
  if (x$kind == "categorical") {
    # Named so as not to clash with real values such as fuel "Other"
    grouped <- c(other = "All other values", blank = "Blank")
    v$label <- ifelse(v$group == "value", v$value, grouped[v$group])
    top <- unique(v[v$group == "value", c("label", "rank")])
    levs <- c(top$label[order(top$rank)], intersect(grouped, v$label))
    s <- aggregate(n_vehicles ~ period + label, data = v, FUN = sum)
    s <- merge(expand.grid(period = sort(unique(v$period)), label = levs,
                           stringsAsFactors = FALSE), s, all.x = TRUE)
    s$n_vehicles[is.na(s$n_vehicles)] <- 0
    s$share <- s$n_vehicles / ave(s$n_vehicles, s$period, FUN = sum)
    s$label <- factor(s$label, levs)
    fills <- setNames(c(values_cols[seq_len(nrow(top))],
                        setNames(c(other_col, blank_col), grouped)[
                          setdiff(levs, top$label)]), levs)
    return(
      ggplot(s, aes(period, share, fill = label)) +
        geom_area(colour = "white", linewidth = 0.25) +
        scale_fill_manual(values = fills) +
        scale_y_continuous(labels = scales::label_percent(),
                           expand = c(0, 0)) +
        scale_x_continuous(expand = c(0, 0)) +
        labs(x = x$x_lab, y = "Share of vehicles") +
        theme_cars() +
        theme(legend.position = "right", legend.justification = "top",
              legend.key.size = grid::unit(0.8, "lines"))
    )
  }
  q <- c("min", "q1", "median", "q3", "max")
  if (x$kind == "date") {
    v[q] <- lapply(v[q], function(d) as.Date(d, origin = "1970-01-01"))
  }
  p <- ggplot(v, aes(period)) +
    geom_ribbon(aes(ymin = q1, ymax = q3, fill = "Q1 to Q3")) +
    geom_line(aes(y = min, linetype = "Minimum and maximum"),
              colour = ink_muted, linewidth = 0.4) +
    geom_line(aes(y = max, linetype = "Minimum and maximum"),
              colour = ink_muted, linewidth = 0.4) +
    geom_line(aes(y = median, colour = "Median"), linewidth = 0.7) +
    scale_fill_manual(values = c("Q1 to Q3" = cars_seq[2])) +
    scale_colour_manual(values = c("Median" = cars_cols[1])) +
    scale_linetype_manual(values = c("Minimum and maximum" = "22")) +
    labs(x = x$x_lab, y = NULL) +
    theme_cars()
  if (x$kind == "date") {
    span <- range(c(v$q1, v$q3))
    pad <- max(as.numeric(diff(span)) * 0.5, 5 * 365)
    p + scale_y_date() +
      coord_cartesian(ylim = c(span[1] - pad, span[2] + pad))
  } else if (values_log(v)) {
    p + scale_y_continuous(
      trans = scales::pseudo_log_trans(sigma = 1, base = 10),
      breaks = c(0, 10^(0:9)),
      labels = scales::label_number(scale_cut = scales::cut_short_scale()))
  } else {
    p + scale_y_continuous(
      labels = scales::label_number(scale_cut = scales::cut_short_scale()))
  }
}

# The Values section of a dictionary chapter: one subsection per column, with
# its description and a chart of its values. Use in an `output: asis` chunk.
dict_values <- function(group) {
  d <- dict_columns()
  parts <- vapply(dict_groups[[group]], function(k) {
    row <- d[d$column_name == k, ]
    kind <- dict_kind(k, row$column_type)
    head <- sprintf("### `%s`\n\n%s.\n\n", k, sub("\\.$", "", row$description))
    if (kind == "id") {
      return(paste0(head, "Each value belongs to one vehicle, so the values ",
                    "are not summarised.\n\n"))
    }
    paste0(head, sprintf(
      "```{r}\n#| label: fig-dd-v-%s\n#| fig-cap: \"%s\"\n#| fig-height: %s\nvalues_plot(\"%s\")\n```\n\n",
      gsub("[^a-z0-9]+", "-", tolower(k)), values_caption(k),
      if (kind == "categorical") 3 else 2.8, k))
  }, character(1))
  knitr::knit_child(text = paste(parts, collapse = ""), quiet = TRUE,
                    envir = globalenv())
}
