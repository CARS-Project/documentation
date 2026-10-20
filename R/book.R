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
                   "type_approval_src", "typeApproval_DVLA", "wheelplan",
                   "wheelplan_src", "wheelplan_DVLA", "revenue_weight",
                   "revenue_weight_src", "revenueWeight_DVLA",
                   "primaryColour_DVSA", "secondaryColour_DVSA",
                   "colour_DVLA", "automatedVehicle_DVLA"),
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
