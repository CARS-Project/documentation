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

## Open issues

Notes from the first draft (October 2026), to come back to. Placeholders in
the text itself are callouts titled **To be written** or **To be confirmed**;
search the chapters for `.todo` to list them (28 in the first draft).

### Decisions

- [ ] **Publishing the repository publishes the data.** `data/pipeline/`
  (about 5.5 MB of aggregate tables and quality files) and `reports/` are
  committed copies of MOT-pipline outputs. A public repository releases them
  before MOT-pipline is public. The alternative is to keep this repository
  private until release, but GitHub Pages from a private repository needs a
  paid plan.
- [ ] **GitHub Pages set-up.** The `gh-pages` branch has been created. Still
  to do: in Settings › Pages, set the source to "Deploy from a branch",
  `gh-pages` / `(root)`. If the workflow fails on permissions, set Settings ›
  Actions › General › Workflow permissions to "Read and write".
- [ ] **Link from the project website.** Add the book to the navigation of
  [cars-project.github.io](https://github.com/CARS-Project/cars-project.github.io)
  (`mkdocs.yml`).
- [ ] **Licence and citation** for each data product, and the OGL attribution
  statement (placeholders in the preface and in *Data products and access*).
- [ ] **Registration numbers.** Whether `registration_DVSA` is published in
  the vehicle table, given that a registration number can be personal data in
  some circumstances.

### Things found in MOT-pipline

- [ ] **Stale plate description in `methodology.md`.** Section 6.2 still says
  the post-2001 age identifier `12` means "Jan–Jun 2012". The MOT-pipline
  README says the issue periods were corrected to March–August and
  September–February. The fix belongs in `reports/methodology.qmd`; the book
  shows the methodology as an appendix, so it picks up the fix at the next
  sync.
- [ ] **`quality/cross_checks.csv` is missing.** The MOT-pipline README lists
  it, but the build the book uses has no such file. It was removed from
  `data/manifest.yml`; add it back once it exists.
- [ ] **Motorcycle coverage falls over time.** CARS observes about 0.55 of
  DfT's motorcycles aged 3+ in 2025, and the ratio falls steadily from about
  1.0 in 2014. SORN and seasonal use explain some of this; check whether
  classification or linkage contributes (*How good is the data?*).
- [ ] **Impossible Euro 6 values.** About 5% of cars appear as Euro 6 in 2005.
  They are Euro statuses filled from similar vehicles, where one wrong
  recorded value spread to its whole make/model/year/fuel group
  (`euro_check = 'later_than_date'`, about 10.3 million vehicles). The book
  uses this as a worked pitfall (spreadsheet Example 3). Consider capping
  backfilled Euro statuses at the schedule, or raising
  `backfill.min_vehicles`.
- [ ] **New output added to MOT-pipline (not yet committed there):**
  `quality/type_approval_by_test_class.csv`, one extra query in
  `build_quality_tables()` (`R/report_quality.R`), used by the type approval
  matrix in *Classifying vehicles*. The CSV was written by hand with the same
  query and `write_table_csv()`, so the next `tar_make()` will rebuild the
  quality tables (and the reports that depend on them) and regenerate it
  unchanged. Only that one file has been copied into `data/pipeline/`; run
  `scripts/sync-pipeline.R` once the current pipeline build has finished.
- [ ] **L4 is not mapped to a body type.** The body type rules map type
  approval L1–L3 to Motorcycles and L5–L7 to Other vehicles; L4 (motorcycle
  with sidecar) is in neither. Probably tiny in practice.
- [ ] **Postcode areas are copied back and carried forward.** The pipeline
  notes (`R/report_quality.R`, `R/dft_compare.R`) say the annualisation copies a
  vehicle's first-test postcode area back to its first registration, and
  carries its postcode area forward for two years after its last MOT. The
  first draft of the book assumed the opposite; the affected passages
  (*The MOT test*, *The life of a vehicle*, *Concepts and pitfalls*, *How
  good is the data?* and two worked examples) were corrected. Confirm the
  exact rules for the linkage stage.
- [ ] **Example results come from the 13 October 2026 parquet.** A pipeline
  build was running while the first draft was written. Rerun
  `scripts/run-examples.R` after the next complete build.

### Facts to check

These background facts were written from general knowledge, not project
sources. Each needs confirming against an authoritative source and, ideally,
a reference.

- [ ] MOT history: introduced in 1960 for vehicles ten years old and over;
  first test at three years since 1967 (*The MOT test*).
- [ ] About 23,000 MOT testing stations in Great Britain (*The MOT test*).
- [ ] COVID-19: six-month MOT extension from 30 March 2020; tests needed
  again for vehicles due from 1 August 2020 (*The MOT test*).
- [ ] Northern Ireland: lift faults at DVA test centres in early 2020 and the
  temporary exemption certificates; vehicle registration moved to the DVLA in
  2014 (*The MOT test*, *Who holds vehicle data*).
- [ ] Historic vehicle exemption: vehicles over 40 years old exempt from the
  MOT since May 2018; electric goods vehicles registered before March 2015
  exempt (*The MOT test*).
- [ ] First MOT at one year for taxis, ambulances and passenger vehicles with
  9 or more seats (*Classifying vehicles*, from GOV.UK).
- [ ] CO2-based vehicle tax for cars registered from March 2001; WLTP from
  September 2017 for new models and September 2018 for all new cars
  (*Fuels, emissions and Euro standards*).
- [ ] ULEV definition (under 75 g/km CO2) and the usual CAZ and ULEZ minimum
  standards: Euro 4 petrol, Euro 6 diesel, Euro VI buses and lorries
  (*Fuels, emissions and Euro standards*).
- [ ] L category limits (speed, engine size, power and mass for L1e–L7e,
  from EU Regulation 168/2013) and the examples given (microcars, Renault
  Twizy as L7) (*Classifying vehicles*).
- [ ] Number plate formats: prefix plates from August 1983, six-monthly
  changes from 1999, suffix plates from 1963 (*Number plates*).
- [ ] SORN history: when it was introduced, and when annual renewal ended
  (*The life of a vehicle*, already a placeholder).
- [ ] Postcode history and counts: London districts from the 1850s–60s,
  national roll-out 1950s–1970s; about 120 areas, 3,000 districts, 11,000
  sectors and 1.8 million unit postcodes; 228 travel to work areas
  (*Geography*).
- [ ] Linkage method details written from the early draft (*Source data and
  linkage*): how mileage is shared between years, the 1 July straddle date,
  and the `is_new_vehicle` / `is_intertest` / `is_end_use` definitions.
