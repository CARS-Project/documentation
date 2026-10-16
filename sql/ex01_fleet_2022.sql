-- Vehicles observed in 2022, by body type and fuel group.
-- "Observed" means the vehicle has a real postcode area in 2022,
-- not one of the statuses unborn, dead or unknown.
SELECT
  body_type,
  fuel_simple,
  count(*) AS n_vehicles
FROM read_parquet('vehicles_enhanced.parquet')
WHERE pca_2022 NOT IN ('unborn', 'dead', 'unknown')
GROUP BY body_type, fuel_simple
ORDER BY n_vehicles DESC;
