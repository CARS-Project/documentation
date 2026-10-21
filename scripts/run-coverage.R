# Count how many vehicles have a value in each column of the vehicle table,
# by year, for the coverage sections of the data dictionary chapters. Saves
# the results to data/coverage/, where the book reads them.
#
# Usage, from the book's root folder (after scripts/sync-pipeline.R, as the
# columns are taken from the synced data dictionary):
#   Rscript scripts/run-coverage.R
#
# The vehicle table is CARS_PARQUET, or the maximal table
# <MOT_PIPELINE_DIR>/outputs/vehicles_enhanced_maximal.parquet, which has every
# column of the data dictionary. DuckDB's memory limit is DUCKDB_MEMORY_LIMIT
# (default 16GB).
#
# Outputs:
#   coverage_by_first_use_year.csv  every column that is not year by year:
#     vehicles, and vehicles with a value, by year of first use
#   true_by_first_use_year.csv      every flag (BOOLEAN column) that is not
#     year by year: vehicles, and vehicles with the flag TRUE, by year of
#     first use
#   coverage_by_year.csv            the year-by-year columns: in each year,
#     vehicles on the road (pca_YYYY not unborn or dead), and how many of
#     them have a postcode area, a mileage and a plausible mileage, a value
#     in each other year-by-year column and, for flags, the flag TRUE

pipeline_dir <- Sys.getenv("MOT_PIPELINE_DIR", "../MOT-pipline")
parquet <- Sys.getenv(
  "CARS_PARQUET",
  file.path(pipeline_dir, "outputs", "vehicles_enhanced_maximal.parquet")
)
if (!file.exists(parquet)) stop("Vehicle table not found: ", parquet)
parquet <- normalizePath(parquet, winslash = "/")

dd <- utils::read.csv("data/pipeline/outputs/data_dictionary.csv",
                      stringsAsFactors = FALSE)
is_year <- grepl("_[0-9]{4}$", dd$column_name)
cols <- dd$column_name[!is_year]
years <- sort(unique(as.integer(sub(".*_", "", dd$column_name[is_year]))))

con <- DBI::dbConnect(duckdb::duckdb())
on.exit(DBI::dbDisconnect(con, shutdown = TRUE))
invisible(DBI::dbExecute(con, sprintf("SET memory_limit = '%s'",
                            Sys.getenv("DUCKDB_MEMORY_LIMIT", "16GB"))))
src <- sprintf("read_parquet('%s')", parquet)
out_dir <- "data/coverage"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# ---- Columns that do not change: by year of first use ------------------------

t0 <- Sys.time()
counts <- paste(sprintf('count("%s") AS "%s"', cols, cols), collapse = ",\n  ")
sql <- sprintf(
  "SELECT year(first_use_date) AS first_use_year, count(*) AS n_vehicles,
  %s
FROM %s
GROUP BY first_use_year
ORDER BY first_use_year", counts, src)
wide <- DBI::dbGetQuery(con, sql)
long <- do.call(rbind, lapply(cols, function(k) {
  data.frame(first_use_year = wide$first_use_year, column_name = k,
             n_vehicles = wide$n_vehicles, n_present = wide[[k]])
}))
write.csv(long, file.path(out_dir, "coverage_by_first_use_year.csv"),
          row.names = FALSE, na = "")
message(sprintf("coverage_by_first_use_year.csv: %d rows in %.0f s",
                nrow(long), as.numeric(difftime(Sys.time(), t0, units = "secs"))))

# ---- Flags: how many are TRUE, by year of first use --------------------------

t0 <- Sys.time()
flags <- dd$column_name[!is_year & dd$column_type == "BOOLEAN"]
counts <- paste(sprintf('count(*) FILTER (WHERE "%s") AS "%s"', flags, flags),
                collapse = ",\n  ")
wide <- DBI::dbGetQuery(con, sprintf(
  "SELECT year(first_use_date) AS first_use_year, count(*) AS n_vehicles,
  %s
FROM %s
GROUP BY first_use_year
ORDER BY first_use_year", counts, src))
long <- do.call(rbind, lapply(flags, function(k) {
  data.frame(first_use_year = wide$first_use_year, column_name = k,
             n_vehicles = wide$n_vehicles, n_true = wide[[k]])
}))
write.csv(long, file.path(out_dir, "true_by_first_use_year.csv"),
          row.names = FALSE, na = "")
message(sprintf("true_by_first_use_year.csv: %d rows in %.0f s",
                nrow(long), as.numeric(difftime(Sys.time(), t0, units = "secs"))))

# ---- Year-by-year columns: vehicles on the road in each year -----------------

t0 <- Sys.time()
# The other year-by-year columns (carried through from the input): how many
# on the road have a value, as n_<stem>, and for flags how many are TRUE, as
# n_<stem>_true
stems <- unique(sub("_[0-9]{4}$", "", dd$column_name[is_year]))
extra <- setdiff(stems, c("pca", "mileage", "legit_mileage"))
extra_flag <- extra %in% sub("_[0-9]{4}$", "",
                             dd$column_name[is_year & dd$column_type == "BOOLEAN"])
per_year <- vapply(years, function(y) {
  on_road <- sprintf("pca_%d NOT IN ('unborn', 'dead')", y)
  more <- c(sprintf("count(%s_%d) FILTER (WHERE %s) AS n_%s", extra, y,
                    on_road, extra),
            sprintf("count(*) FILTER (WHERE %s AND %s_%d) AS n_%s_true",
                    on_road, extra[extra_flag], y, extra[extra_flag]))
  sprintf(
    "SELECT %d AS year,
  count(*) FILTER (WHERE %s) AS n_on_road,
  count(*) FILTER (WHERE %s AND pca_%d <> 'unknown') AS n_pca,
  count(mileage_%d) FILTER (WHERE %s) AS n_mileage,
  count(*) FILTER (WHERE %s AND legit_mileage_%d) AS n_legit_mileage%s
FROM %s", y, on_road, on_road, y, y, on_road, on_road, y,
    paste0(",\n  ", more, collapse = ""), src)
}, character(1))
by_year <- DBI::dbGetQuery(con, paste(per_year, collapse = "\nUNION ALL\n"))
by_year <- by_year[order(by_year$year), ]
write.csv(by_year, file.path(out_dir, "coverage_by_year.csv"),
          row.names = FALSE, na = "")
message(sprintf("coverage_by_year.csv: %d rows in %.0f s", nrow(by_year),
                as.numeric(difftime(Sys.time(), t0, units = "secs"))))

writeLines(c(
  paste("parquet:", parquet),
  paste("parquet_modified:", format(file.mtime(parquet), "%Y-%m-%d %H:%M")),
  paste("run_at:", format(Sys.time(), "%Y-%m-%d %H:%M"))
), file.path(out_dir, "provenance.txt"))
