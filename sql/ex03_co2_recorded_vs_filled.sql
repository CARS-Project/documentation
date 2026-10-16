-- CO2 of petrol and diesel cars first used 2012-2019: all values against
-- recorded values only. co2_src says where each value came from.
SELECT
  year(first_use_date) AS first_use_year,
  fuel_simple,
  count(co2) AS n_with_co2,
  round(avg(co2), 1) AS mean_co2_all,
  count(co2) FILTER (WHERE co2_src = 'dvla') AS n_recorded,
  round(avg(co2) FILTER (WHERE co2_src = 'dvla'), 1) AS mean_co2_recorded
FROM read_parquet('vehicles_enhanced.parquet')
WHERE body_type = 'Cars'
  AND fuel_simple IN ('Petrol', 'Diesel')
  AND year(first_use_date) BETWEEN 2012 AND 2019
GROUP BY first_use_year, fuel_simple
ORDER BY fuel_simple, first_use_year;
