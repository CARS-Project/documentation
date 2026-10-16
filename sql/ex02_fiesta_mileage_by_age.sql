-- Average annual mileage of Ford Fiestas by age, for three years.
-- The vehicle table is wide (one column per year), so the mileage and
-- plausibility columns are first turned into long form: one row per
-- vehicle per year.
WITH fiesta AS (
  SELECT *
  FROM read_parquet('vehicles_enhanced.parquet')
  WHERE make_final = 'FORD' AND model_final = 'FIESTA'
),
mileage AS (
  UNPIVOT (SELECT vehicle_id, COLUMNS('^mileage_[0-9]{4}$') FROM fiesta)
  ON COLUMNS('^mileage_') INTO NAME col VALUE mileage
),
legit AS (
  UNPIVOT (SELECT vehicle_id, COLUMNS('^legit_mileage_[0-9]{4}$') FROM fiesta)
  ON COLUMNS('^legit_mileage_') INTO NAME col VALUE legit
)
SELECT
  CAST(right(m.col, 4) AS INTEGER) AS year,
  CAST(right(m.col, 4) AS INTEGER) - year(f.first_use_date) AS age,
  count(*) AS n_vehicles,
  round(avg(m.mileage)) AS mean_mileage,
  median(m.mileage) AS median_mileage
FROM mileage m
JOIN legit l
  ON l.vehicle_id = m.vehicle_id AND right(l.col, 4) = right(m.col, 4)
JOIN fiesta f ON f.vehicle_id = m.vehicle_id
WHERE l.legit                          -- plausible mileage only
  AND right(m.col, 4) IN ('2010', '2016', '2022')
GROUP BY year, age
HAVING age BETWEEN 3 AND 20
ORDER BY year, age;
