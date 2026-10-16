# Using the CARS vehicle data

User documentation for the [CARS project](https://cars-project.github.io/):
a [Quarto](https://quarto.org) book explaining the CARS research-ready vehicle
dataset, the background needed to use it, its pitfalls, and worked examples.

Published at <https://cars-project.github.io/documentation/>.

## Structure

| Path | Contents |
|---|---|
| `index.qmd`, `chapters/` | The chapters |
| `reports/` | Reports copied from MOT-pipline, shown as appendices (do not edit) |
| `data/manifest.yml` | Which MOT-pipline files the book uses |
| `data/pipeline/` | Snapshot of those files (do not edit) |
| `sql/` | Worked-example queries, shown in the book and run by `scripts/run-examples.R` |
| `data/examples/` | Results of those queries |
| `R/book.R` | Helpers used by every chapter |
| `scripts/` | Sync, examples and rebuild scripts |
| `_freeze/` | Stored chapter results, so CI can render without R |

## Building

Requires Quarto and R with `ggplot2`, `scales`, `sf`, `knitr`, `rmarkdown`,
`yaml`, and, for the examples, `duckdb` and `DBI`.

```sh
quarto preview                    # preview while editing
```

After a new MOT-pipline build, with MOT-pipline checked out alongside this
repository (or `MOT_PIPELINE_DIR` set):

```sh
Rscript scripts/sync-pipeline.R   # copy outputs into data/ and reports/
Rscript scripts/run-examples.R    # rerun the example queries (needs the parquet)
Rscript scripts/rebuild.R         # re-execute every chapter and render
```

Commit `data/`, `reports/` and `_freeze/`, then push. Pushing to `main`
publishes the book via GitHub Actions. See the *Maintaining this book*
appendix for details.
