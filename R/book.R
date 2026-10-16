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
