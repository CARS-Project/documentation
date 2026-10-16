# Run the worked-example queries in sql/ against the vehicle table and save
# their results to data/examples/, where the book reads them.
#
# Usage, from the book's root folder:
#   Rscript scripts/run-examples.R            # every query
#   Rscript scripts/run-examples.R ex02       # queries whose name starts ex02
#
# The queries name the file as 'vehicles_enhanced.parquet', exactly as a
# reader would; that name is replaced here by CARS_PARQUET, or by
# <MOT_PIPELINE_DIR>/outputs/vehicles_enhanced.parquet. DuckDB's memory limit
# is DUCKDB_MEMORY_LIMIT (default 16GB).

pipeline_dir <- Sys.getenv("MOT_PIPELINE_DIR", "../MOT-pipline")
parquet <- Sys.getenv(
  "CARS_PARQUET",
  file.path(pipeline_dir, "outputs", "vehicles_enhanced.parquet")
)
if (!file.exists(parquet)) stop("Vehicle table not found: ", parquet)
parquet <- normalizePath(parquet, winslash = "/")

files <- list.files("sql", pattern = "\\.sql$", full.names = TRUE)
args <- commandArgs(trailingOnly = TRUE)
if (length(args) > 0) {
  keep <- Reduce(`|`, lapply(args, function(a) startsWith(basename(files), a)))
  files <- files[keep]
}

con <- DBI::dbConnect(duckdb::duckdb())
on.exit(DBI::dbDisconnect(con, shutdown = TRUE))
invisible(DBI::dbExecute(con, sprintf("SET memory_limit = '%s'",
                            Sys.getenv("DUCKDB_MEMORY_LIMIT", "16GB"))))

dir.create("data/examples", showWarnings = FALSE, recursive = TRUE)
for (f in files) {
  sql <- paste(readLines(f, warn = FALSE), collapse = "\n")
  sql <- gsub("'vehicles_enhanced.parquet'", paste0("'", parquet, "'"), sql,
              fixed = TRUE)
  t0 <- Sys.time()
  res <- DBI::dbGetQuery(con, sql)
  out <- file.path("data/examples", sub("\\.sql$", ".csv", basename(f)))
  write.csv(res, out, row.names = FALSE, na = "")
  message(sprintf("%s: %d rows in %.0f s", basename(f), nrow(res),
                  as.numeric(difftime(Sys.time(), t0, units = "secs"))))
}

# Record which vehicle table the results came from
writeLines(c(
  paste("parquet:", parquet),
  paste("parquet_modified:", format(file.mtime(parquet), "%Y-%m-%d %H:%M")),
  paste("run_at:", format(Sys.time(), "%Y-%m-%d %H:%M"))
), "data/examples/provenance.txt")
