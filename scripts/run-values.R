# Summarise the values of each column of the vehicle table over time, for the
# Values sections of the data dictionary chapters. Saves the results to
# data/values/, where the book reads them.
#
# Usage, from the book's root folder (after scripts/sync-pipeline.R, as the
# columns are taken from the synced data dictionary):
#   Rscript scripts/run-values.R
#
# The vehicle table is found as in scripts/run-examples.R: CARS_PARQUET, or
# <MOT_PIPELINE_DIR>/outputs/vehicles_enhanced.parquet. DuckDB's memory limit
# is DUCKDB_MEMORY_LIMIT (default 16GB).
#
# Columns are summarised by kind, as dict_kind() in R/book.R decides:
#   numeric_by_first_use_year.csv      numeric and date columns: minimum,
#     quartiles and maximum by year of first use (dates as days since
#     1970-01-01)
#   categorical_by_first_use_year.csv  other columns: vehicles by value and
#     year of first use, for the 7 commonest values; the rest are counted as
#     group "other", and blanks as group "blank"
#   numeric_by_year.csv, categorical_by_year.csv  the same for the
#     year-by-year columns, by calendar year
# Years of first use outside 1990 to the current year are left out.

source("R/book.R")
n_top <- 7
first_year <- 1990
last_year <- as.integer(format(Sys.Date(), "%Y"))

pipeline_dir <- Sys.getenv("MOT_PIPELINE_DIR", "../MOT-pipline")
parquet <- Sys.getenv(
  "CARS_PARQUET",
  file.path(pipeline_dir, "outputs", "vehicles_enhanced.parquet")
)
if (!file.exists(parquet)) stop("Vehicle table not found: ", parquet)
parquet <- normalizePath(parquet, winslash = "/")

dd <- read_pipeline("outputs", "data_dictionary.csv")
dd$kind <- dict_kind(sub("_[0-9]{4}$", "_YYYY", dd$column_name),
                     dd$column_type)
is_year <- grepl("_[0-9]{4}$", dd$column_name)
years <- sort(unique(as.integer(sub(".*_", "", dd$column_name[is_year]))))

con <- DBI::dbConnect(duckdb::duckdb())
on.exit(DBI::dbDisconnect(con, shutdown = TRUE))
invisible(DBI::dbExecute(con, sprintf("SET memory_limit = '%s'",
                            Sys.getenv("DUCKDB_MEMORY_LIMIT", "16GB"))))
out_dir <- "data/values"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

invisible(DBI::dbExecute(con, sprintf(
  "CREATE VIEW v AS SELECT *, year(first_use_date) AS fu_year
   FROM read_parquet('%s')
   WHERE year(first_use_date) BETWEEN %d AND %d",
  parquet, first_year, last_year)))

timed <- function(label, expr) {
  t0 <- Sys.time()
  res <- expr
  message(sprintf("%s: %.0f s", label,
                  as.numeric(difftime(Sys.time(), t0, units = "secs"))))
  res
}

# Expression giving a column as a number: dates as days since 1970-01-01
as_number <- function(col, kind) {
  if (kind == "date") {
    sprintf("date_diff('day', DATE '1970-01-01', CAST(\"%s\" AS DATE))", col)
  } else sprintf("CAST(\"%s\" AS DOUBLE)", col)
}

quartiles_sql <- function(x, group, from, where = "TRUE") {
  sprintf(
    "SELECT %s AS period, count(%s) AS n, min(%s) AS min,
  quantile_cont(%s, 0.25) AS q1, quantile_cont(%s, 0.5) AS median,
  quantile_cont(%s, 0.75) AS q3, max(%s) AS max
FROM %s WHERE %s AND %s IS NOT NULL GROUP BY period", group, x, x, x, x, x, x,
    from, where, x)
}

# Keep the n_top commonest values; fold the rest into "other"
fold <- function(d) {
  vals <- d[!is.na(d$value), ]
  tot <- tapply(vals$n_vehicles, vals$value, sum)
  top <- names(sort(tot, decreasing = TRUE))[seq_len(min(n_top, length(tot)))]
  d$group <- ifelse(is.na(d$value), "blank",
                    ifelse(d$value %in% top, "value", "other"))
  d$value[d$group != "value"] <- NA
  d$rank <- match(d$value, top)
  aggregate(n_vehicles ~ period + group + value + rank,
            data = transform(d, value = ifelse(is.na(value), "", value),
                             rank = ifelse(is.na(rank), 0L, rank)),
            FUN = sum)
}

# ---- Columns that do not change: by year of first use ------------------------

fixed <- dd[!is_year & dd$kind != "id", ]

num <- fixed[fixed$kind %in% c("numeric", "date"), ]
numeric_fu <- do.call(rbind, lapply(seq_len(nrow(num)), function(i) {
  k <- num$column_name[i]
  r <- timed(k, DBI::dbGetQuery(con, quartiles_sql(
    as_number(k, num$kind[i]), "fu_year", "v")))
  cbind(column_name = k, kind = num$kind[i], r)
}))
names(numeric_fu)[names(numeric_fu) == "period"] <- "first_use_year"
write.csv(numeric_fu[order(numeric_fu$column_name, numeric_fu$first_use_year), ],
          file.path(out_dir, "numeric_by_first_use_year.csv"),
          row.names = FALSE, na = "")

cat_cols <- fixed$column_name[fixed$kind == "categorical"]
categorical_fu <- do.call(rbind, lapply(cat_cols, function(k) {
  r <- timed(k, DBI::dbGetQuery(con, sprintf(
    "SELECT fu_year AS period, CAST(\"%s\" AS VARCHAR) AS value,
       count(*) AS n_vehicles
     FROM v GROUP BY ALL", k)))
  cbind(column_name = k, fold(r))
}))
names(categorical_fu)[names(categorical_fu) == "period"] <- "first_use_year"
write.csv(categorical_fu[order(categorical_fu$column_name,
                               categorical_fu$first_use_year,
                               categorical_fu$rank), ],
          file.path(out_dir, "categorical_by_first_use_year.csv"),
          row.names = FALSE, na = "")

# ---- Year-by-year columns: by calendar year ----------------------------------

src <- sprintf("read_parquet('%s')", parquet)
stems <- unique(sub("_[0-9]{4}$", "_YYYY", dd$column_name[is_year]))
stem_kind <- dict_kind(stems, dd$column_type[is_year][match(
  stems, sub("_[0-9]{4}$", "_YYYY", dd$column_name[is_year]))])

numeric_yr <- do.call(rbind, lapply(stems[stem_kind == "numeric"], function(st) {
  sql <- paste(vapply(years, function(y) {
    x <- as_number(sub("YYYY", y, st), "numeric")
    quartiles_sql(x, as.character(y), src)
  }, character(1)), collapse = "\nUNION ALL\n")
  cbind(column_name = st, kind = "numeric", timed(st, DBI::dbGetQuery(con, sql)))
}))
names(numeric_yr)[names(numeric_yr) == "period"] <- "year"
write.csv(numeric_yr[order(numeric_yr$column_name, numeric_yr$year), ],
          file.path(out_dir, "numeric_by_year.csv"), row.names = FALSE, na = "")

categorical_yr <- do.call(rbind, lapply(stems[stem_kind == "categorical"],
                                        function(st) {
  sql <- paste(vapply(years, function(y) {
    sprintf("SELECT %d AS period, CAST(\"%s\" AS VARCHAR) AS value,
       count(*) AS n_vehicles FROM %s GROUP BY ALL", y, sub("YYYY", y, st), src)
  }, character(1)), collapse = "\nUNION ALL\n")
  cbind(column_name = st, fold(timed(st, DBI::dbGetQuery(con, sql))))
}))
names(categorical_yr)[names(categorical_yr) == "period"] <- "year"
write.csv(categorical_yr[order(categorical_yr$column_name, categorical_yr$year,
                               categorical_yr$rank), ],
          file.path(out_dir, "categorical_by_year.csv"),
          row.names = FALSE, na = "")

writeLines(c(
  paste("parquet:", parquet),
  paste("parquet_modified:", format(file.mtime(parquet), "%Y-%m-%d %H:%M")),
  paste("run_at:", format(Sys.time(), "%Y-%m-%d %H:%M"))
), file.path(out_dir, "provenance.txt"))
