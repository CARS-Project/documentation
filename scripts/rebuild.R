# Rebuild the whole book from the data snapshot in data/.
#
# Usage, from the book's root folder:
#   Rscript scripts/sync-pipeline.R   # 1. copy the latest pipeline outputs
#   Rscript scripts/run-examples.R    # 2. rerun the example queries (needs the parquet)
#   Rscript scripts/run-coverage.R    # 3. recount column coverage (needs the parquet)
#   Rscript scripts/run-values.R      # 4. resummarise column values (needs the parquet)
#   Rscript scripts/rebuild.R         # 5. re-execute every chapter and render
#
# The book uses Quarto's freeze, so a normal `quarto render` only re-executes
# chapters whose source changed. New data does not change the source, so this
# script clears the frozen results first and every chapter runs again.
# Commit _freeze/ afterwards: GitHub Actions renders from it without R.

unlink("_freeze", recursive = TRUE)
status <- system2("quarto", "render")
if (status != 0) stop("quarto render failed")
message("Rendered to _book/. Commit data/, reports/ and _freeze/, then push.")
