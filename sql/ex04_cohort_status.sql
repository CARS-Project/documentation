-- What happened to the cars first used in 2008? For each year, count how
-- many were observed, unknown or dead. Only the pca_YYYY columns are needed.
WITH cohort AS (
  SELECT vehicle_id, COLUMNS('^pca_[0-9]{4}$')
  FROM read_parquet('vehicles_enhanced.parquet')
  WHERE body_type = 'Cars' AND year(first_use_date) = 2008
),
long AS (
  UNPIVOT cohort ON COLUMNS('^pca_') INTO NAME col VALUE pca
)
SELECT
  CAST(right(col, 4) AS INTEGER) AS year,
  CASE WHEN pca IN ('unborn', 'dead', 'unknown') THEN pca
       ELSE 'observed' END AS status,
  count(*) AS n_vehicles
FROM long
GROUP BY year, status
ORDER BY year, status;
