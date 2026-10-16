-- Cars tested in the Leeds postcode area (LS) in 2019: where were they
-- in 2023?
SELECT
  pca_2023,
  count(*) AS n_vehicles
FROM read_parquet('vehicles_enhanced.parquet')
WHERE body_type = 'Cars' AND pca_2019 = 'LS'
GROUP BY pca_2023
ORDER BY n_vehicles DESC
LIMIT 12;
