CREATE DATABASE world_population_analytics;

USE world_population_analytics;

CREATE TABLE countries (
    country_id INT AUTO_INCREMENT PRIMARY KEY,
    country_name VARCHAR(100) NOT NULL,
    continent VARCHAR(50),
    region VARCHAR(100),
    area_km2 BIGINT
);


CREATE TABLE population_data (
    pop_id INT AUTO_INCREMENT PRIMARY KEY,
    country_id INT,
    year INT,
    population BIGINT,
    growth_rate FLOAT,
    FOREIGN KEY (country_id) REFERENCES countries(country_id)
);

CREATE TABLE economic_data (
    econ_id INT AUTO_INCREMENT PRIMARY KEY,
    country_id INT,
    year INT,
    gdp_usd BIGINT,
    gdp_per_capita FLOAT,
    inflation_rate FLOAT,
    FOREIGN KEY (country_id) REFERENCES countries(country_id)
);

CREATE TABLE social_data (
    soc_id INT AUTO_INCREMENT PRIMARY KEY,
    country_id INT,
    year INT,
    literacy_rate FLOAT,
    life_expectancy FLOAT,
    unemployment_rate FLOAT,
    FOREIGN KEY (country_id) REFERENCES countries(country_id)
);

-- Insert data into countries table

INSERT INTO countries (country_name, continent, region, area_km2) VALUES
('India', 'Asia', 'Southern Asia', 3287263),
('China', 'Asia', 'Eastern Asia', 9596961),
('United States', 'North America', 'Northern America', 9833517),
('Brazil', 'South America', 'South America', 8515767),
('Nigeria', 'Africa', 'Western Africa', 923768),
('Germany', 'Europe', 'Western Europe', 357022),
('Australia', 'Oceania', 'Australia and New Zealand', 7692024),
('Japan', 'Asia', 'Eastern Asia', 377975),
('Russia', 'Europe', 'Eastern Europe', 17098246),
('Canada', 'North America', 'Northern America', 9984670);

-- Population data (for 2020)

INSERT INTO population_data (country_id, year, population, growth_rate) VALUES
(1, 2020, 1380004385, 1.02),
(2, 2020, 1439323776, 0.39),
(3, 2020, 331002651, 0.59),
(4, 2020, 212559417, 0.72),
(5, 2020, 206139589, 2.58),
(6, 2020, 83783942, 0.32),
(7, 2020, 25499884, 1.18),
(8, 2020, 126476461, -0.30),
(9, 2020, 145934462, -0.25),
(10, 2020, 37742154, 0.89);

-- Economic data (for 2020)

INSERT INTO economic_data (country_id, year, gdp_usd, gdp_per_capita, inflation_rate) VALUES
(1, 2020, 2875000000000, 2100, 6.6),
(2, 2020, 14722700000000, 10500, 2.4),
(3, 2020, 20937000000000, 63500, 1.3),
(4, 2020, 1444730000000, 6800, 3.2),
(5, 2020, 448120000000, 2200, 13.2),
(6, 2020, 3846000000000, 46000, 0.4),
(7, 2020, 1336800000000, 52000, 1.5),
(8, 2020, 5065000000000, 40000, 0.2),
(9, 2020, 1699900000000, 11700, 3.4),
(10, 2020, 1647000000000, 44000, 0.7);

-- Social data (for 2020)

INSERT INTO social_data (country_id, year, literacy_rate, life_expectancy, unemployment_rate) VALUES
(1, 2020, 74.4, 69.4, 7.1),
(2, 2020, 96.8, 76.9, 4.2),
(3, 2020, 99.0, 78.9, 8.1),
(4, 2020, 93.2, 75.9, 11.4),
(5, 2020, 62.0, 54.3, 9.0),
(6, 2020, 99.0, 81.2, 4.4),
(7, 2020, 99.0, 83.3, 5.2),
(8, 2020, 99.0, 84.6, 2.8),
(9, 2020, 99.7, 73.2, 5.8),
(10, 2020, 99.0, 82.0, 7.5);


-- Q1 — Top 5 most populated countries in 2020

SELECT c.country_name, p.population
FROM population_data p
JOIN countries c ON p.country_id = c.country_id
WHERE p.year = 2020
ORDER BY p.population DESC
LIMIT 5;


-- Q2 — Population density and ranking

SELECT country_name,
       population / NULLIF(area_km2,0) AS population_density,
       RANK() OVER (ORDER BY population / NULLIF(area_km2,0) DESC) AS density_rank
FROM countries c
JOIN population_data p ON c.country_id = p.country_id
WHERE p.year = 2020;


-- Q3 — Fastest-growing countries (avg growth_rate 2010–2020)

SELECT c.country_name,
       ROUND(AVG(p.growth_rate), 4) AS avg_growth_rate
FROM population_data p
JOIN countries c ON p.country_id = c.country_id
WHERE p.year BETWEEN 2010 AND 2020
GROUP BY c.country_name
ORDER BY avg_growth_rate DESC
LIMIT 10;


-- Q4 — Continent contributing most to world population in 2020

SELECT c.continent, SUM(p.population) AS total_population
FROM population_data p
JOIN countries c ON p.country_id = c.country_id
WHERE p.year = 2020
GROUP BY c.continent
ORDER BY total_population DESC
LIMIT 1;


-- Q5 — Population CAGR per country between 2000 and 2020

WITH bounds AS (
  SELECT 
    p.country_id,
    MAX(CASE WHEN p.year = 2000 THEN p.population END) AS pop_2000,
    MAX(CASE WHEN p.year = 2020 THEN p.population END) AS pop_2020
  FROM population_data p
  WHERE p.year IN (2000, 2020)
  GROUP BY p.country_id
)
SELECT 
  c.country_name,
  ROUND((POWER(CAST(pop_2020 AS DECIMAL(18,4)) / NULLIF(pop_2000, 0), 1.0 / 20) - 1) * 100, 4) AS CAGR_percent
FROM bounds b
JOIN countries c ON b.country_id = c.country_id
WHERE pop_2000 IS NOT NULL 
  AND pop_2020 IS NOT NULL
ORDER BY CAGR_percent DESC;


-- Q6 — Countries with any negative population growth in any year

SELECT DISTINCT c.country_name, p.year, p.growth_rate
FROM population_data p
JOIN countries c ON p.country_id = c.country_id
WHERE p.growth_rate < 0
ORDER BY c.country_name, p.year;


-- Q7 — Top 3 countries per continent by GDP in 2020

SELECT country_name, continent, year, gdp_usd
FROM (
  SELECT c.country_name, c.continent, e.year, e.gdp_usd,
         ROW_NUMBER() OVER (PARTITION BY c.continent ORDER BY e.gdp_usd DESC) AS rn
  FROM economic_data e
  JOIN countries c ON e.country_id = c.country_id
  WHERE e.year = 2020
) t
WHERE rn <= 3
ORDER BY continent, rn;


-- Q8 — Countries where GDP per capita increased but population declined (2010→2020)

WITH p AS (
  SELECT country_id,
         MAX(CASE WHEN year = 2010 THEN population END) AS pop_2010,
         MAX(CASE WHEN year = 2020 THEN population END) AS pop_2020
  FROM population_data
  WHERE year IN (2010,2020)
  GROUP BY country_id
),
e AS (
  SELECT country_id,
         MAX(CASE WHEN year = 2010 THEN gdp_per_capita END) AS gdp_pc_2010,
         MAX(CASE WHEN year = 2020 THEN gdp_per_capita END) AS gdp_pc_2020
  FROM economic_data
  WHERE year IN (2010,2020)
  GROUP BY country_id
)
SELECT c.country_name
FROM countries c
JOIN p ON c.country_id = p.country_id
JOIN e ON c.country_id = e.country_id
WHERE p.pop_2020 < p.pop_2010
  AND e.gdp_pc_2020 > e.gdp_pc_2010;


-- Q9 — Avg GDP per capita per continent vs global avg (2020)

SELECT continent, ROUND(AVG(gdp_per_capita),2) AS avg_gdp_pc,
       CASE WHEN AVG(gdp_per_capita) > (SELECT AVG(gdp_per_capita) FROM economic_data WHERE year = 2020) THEN 'ABOVE_GLOBAL' ELSE 'BELOW_GLOBAL' END AS vs_global
FROM economic_data e
JOIN countries c ON e.country_id = c.country_id
WHERE e.year = 2020
GROUP BY continent;


-- Q10 — Country with highest GDP growth between 2010 and 2020

WITH growth AS (
  SELECT e.country_id,
         MAX(CASE WHEN year = 2010 THEN gdp_usd END) AS gdp_2010,
         MAX(CASE WHEN year = 2020 THEN gdp_usd END) AS gdp_2020
  FROM economic_data e
  WHERE year IN (2010,2020)
  GROUP BY e.country_id
)
SELECT c.country_name,
       ROUND(((gdp_2020 - gdp_2010) / NULLIF(gdp_2010,0)) * 100, 2) AS pct_growth
FROM growth g
JOIN countries c ON g.country_id = c.country_id
WHERE gdp_2010 IS NOT NULL AND gdp_2020 IS NOT NULL
ORDER BY pct_growth DESC
LIMIT 1;


-- Q11 — Correlation (GDP per capita vs population growth)

SELECT CORR(p.growth_rate, e.gdp_per_capita) AS correlation
FROM population_data p
JOIN economic_data e ON p.country_id = e.country_id AND p.year = e.year
WHERE p.year BETWEEN 2010 AND 2020;


-- Q12 — Continent with highest inflation rate in 2020

SELECT c.continent, ROUND(AVG(e.inflation_rate),2) AS avg_inflation
FROM economic_data e
JOIN countries c ON e.country_id = c.country_id
WHERE e.year = 2020
GROUP BY c.continent
ORDER BY avg_inflation DESC
LIMIT 1;


-- Q13 — Avg literacy rate & life expectancy per continent (2020)

SELECT c.continent,
       ROUND(AVG(s.literacy_rate),2) AS avg_literacy,
       ROUND(AVG(s.life_expectancy),2) AS avg_life_expectancy
FROM social_data s
JOIN countries c ON s.country_id = c.country_id
WHERE s.year = 2020
GROUP BY c.continent
ORDER BY avg_literacy DESC;


-- Q14 — High GDP per capita but literacy below 80% (2020)

SELECT c.country_name, e.gdp_per_capita, s.literacy_rate
FROM economic_data e
JOIN social_data s ON e.country_id = s.country_id AND e.year = s.year
JOIN countries c ON c.country_id = e.country_id
WHERE e.year = 2020
  AND e.gdp_per_capita > 20000 -- threshold; adjust as needed
  AND s.literacy_rate < 80
ORDER BY e.gdp_per_capita DESC;


-- Q15 — Top 10 countries by life expectancy (2020)

SELECT c.country_name, s.life_expectancy
FROM social_data s
JOIN countries c ON s.country_id = c.country_id
WHERE s.year = 2020
ORDER BY s.life_expectancy DESC
LIMIT 10;


-- Q16 — Countries with life expectancy <60 and literacy <70 (2020)

SELECT c.country_name, s.life_expectancy, s.literacy_rate
FROM social_data s
JOIN countries c ON s.country_id = c.country_id
WHERE s.year = 2020
  AND s.life_expectancy < 60
  AND s.literacy_rate < 70;


-- Q17 — For each continent, country with lowest unemployment rate (2020)

SELECT continent, country_name, unemployment_rate
FROM (
  SELECT c.continent, c.country_name, s.unemployment_rate,
         ROW_NUMBER() OVER (PARTITION BY c.continent ORDER BY s.unemployment_rate ASC) AS rn
  FROM social_data s
  JOIN countries c ON s.country_id = c.country_id
  WHERE s.year = 2020
) t
WHERE rn = 1;

-- Q18 — Countries where unemployment decreased while GDP per capita increased (2010→2020)

WITH soc AS (
  SELECT country_id,
         MAX(CASE WHEN year = 2010 THEN unemployment_rate END) AS unemp_2010,
         MAX(CASE WHEN year = 2020 THEN unemployment_rate END) AS unemp_2020
  FROM social_data
  WHERE year IN (2010,2020)
  GROUP BY country_id
),
eco AS (
  SELECT country_id,
         MAX(CASE WHEN year = 2010 THEN gdp_per_capita END) AS gdp_2010,
         MAX(CASE WHEN year = 2020 THEN gdp_per_capita END) AS gdp_2020
  FROM economic_data
  WHERE year IN (2010,2020)
  GROUP BY country_id
)
SELECT c.country_name
FROM countries c
JOIN soc ON c.country_id = soc.country_id
JOIN eco ON c.country_id = eco.country_id
WHERE unemp_2020 < unemp_2010
  AND gdp_2020 > gdp_2010;


-- Q19 — Countries in top 10% GDP per capita and bottom 10% population (same year)

WITH metrics AS (
  SELECT c.country_id, c.country_name, e.year, e.gdp_per_capita, p.population,
         PERCENT_RANK() OVER (PARTITION BY e.year ORDER BY e.gdp_per_capita) AS gdp_pc_pr,
         PERCENT_RANK() OVER (PARTITION BY e.year ORDER BY p.population) AS pop_pr
  FROM economic_data e
  JOIN population_data p ON e.country_id = p.country_id AND e.year = p.year
  JOIN countries c ON c.country_id = e.country_id
  WHERE e.year = 2020
)
SELECT country_name, gdp_per_capita, population
FROM metrics
WHERE gdp_pc_pr >= 0.9
  AND pop_pr <= 0.1;


-- Q20 — Year-over-year GDP growth % per country (using window)

SELECT country_name, year,
       ROUND((gdp_usd - LAG(gdp_usd) OVER (PARTITION BY e.country_id ORDER BY year)) / NULLIF(LAG(gdp_usd) OVER (PARTITION BY e.country_id ORDER BY year),0) * 100, 2) AS yoy_gdp_pct
FROM economic_data e
JOIN countries c ON e.country_id = c.country_id
ORDER BY country_name, year;


-- Q21 — Top 3 countries with highest life expectancy improvement (2000→2020)

WITH diff AS (
  SELECT s.country_id,
         MAX(CASE WHEN year = 2000 THEN life_expectancy END) AS life_2000,
         MAX(CASE WHEN year = 2020 THEN life_expectancy END) AS life_2020
  FROM social_data s
  WHERE year IN (2000,2020)
  GROUP BY s.country_id
)
SELECT c.country_name, ROUND(life_2020 - life_2000,2) AS improvement
FROM diff d
JOIN countries c ON d.country_id = c.country_id
WHERE life_2000 IS NOT NULL AND life_2020 IS NOT NULL
ORDER BY improvement DESC
LIMIT 3;


-- Q22 — Rank countries by Development Score (composite) for 2020

SELECT c.country_name, c.continent,
       ROUND((e.gdp_per_capita * 0.4) + (s.life_expectancy * 0.3) + (s.literacy_rate * 0.3), 2) AS development_score,
       RANK() OVER (ORDER BY (e.gdp_per_capita * 0.4) + (s.life_expectancy * 0.3) + (s.literacy_rate * 0.3) DESC) AS dev_rank
FROM economic_data e
JOIN social_data s ON e.country_id = s.country_id AND e.year = s.year
JOIN countries c ON c.country_id = e.country_id
WHERE e.year = 2020;


-- Q23 — Continent with best average development score (2020)

WITH scores AS (
  SELECT c.country_id, c.continent,
         (e.gdp_per_capita * 0.4) + (s.life_expectancy * 0.3) + (s.literacy_rate * 0.3) AS development_score
  FROM economic_data e
  JOIN social_data s ON e.country_id = s.country_id AND e.year = s.year
  JOIN countries c ON c.country_id = e.country_id
  WHERE e.year = 2020
)
SELECT continent, ROUND(AVG(development_score),2) AS avg_development_score
FROM scores
GROUP BY continent
ORDER BY avg_development_score DESC
LIMIT 1;


-- Q24 — Compare GDP per capita growth vs life expectancy growth per continent (2010→2020)

WITH eco AS (
  SELECT country_id,
         MAX(CASE WHEN year = 2010 THEN gdp_per_capita END) AS gdp_2010,
         MAX(CASE WHEN year = 2020 THEN gdp_per_capita END) AS gdp_2020
  FROM economic_data
  WHERE year IN (2010,2020)
  GROUP BY country_id
),
soc AS (
  SELECT country_id,
         MAX(CASE WHEN year = 2010 THEN life_expectancy END) AS life_2010,
         MAX(CASE WHEN year = 2020 THEN life_expectancy END) AS life_2020
  FROM social_data
  WHERE year IN (2010,2020)
  GROUP BY country_id
)
SELECT c.continent,
       ROUND(AVG((eco.gdp_2020 - eco.gdp_2010) / NULLIF(eco.gdp_2010,0)) * 100,2) AS avg_gdp_pc_pct_change,
       ROUND(AVG(soc.life_2020 - soc.life_2010),2) AS avg_life_exp_change
FROM countries c
JOIN eco ON c.country_id = eco.country_id
JOIN soc ON c.country_id = soc.country_id
GROUP BY c.continent
ORDER BY avg_gdp_pc_pct_change DESC;


-- Q25 — Top 5 most populated countries for each year (RANK)

SELECT year, country_name, population, population_rank
FROM (
  SELECT p.year, c.country_name, p.population,
         RANK() OVER (PARTITION BY p.year ORDER BY p.population DESC) AS population_rank
  FROM population_data p
  JOIN countries c ON p.country_id = c.country_id
) t
WHERE population_rank <= 5
ORDER BY year, population_rank;


-- Q26 — Use LAG() to calculate YoY GDP growth (%) for each country

SELECT country_name, year,
       ROUND((gdp_usd - LAG(gdp_usd) OVER (PARTITION BY e.country_id ORDER BY year)) / NULLIF(LAG(gdp_usd) OVER (PARTITION BY e.country_id ORDER BY year),0) * 100,2) AS yoy_gdp_percent
FROM economic_data e
JOIN countries c ON e.country_id = c.country_id
ORDER BY country_name, year;


-- Q27 — NTILE(4) quartiles for GDP per capita and list top quartile countries (2020)

WITH q AS (
  SELECT c.country_name, e.gdp_per_capita,
         NTILE(4) OVER (ORDER BY e.gdp_per_capita) AS quartile
  FROM economic_data e
  JOIN countries c ON e.country_id = c.country_id
  WHERE e.year = 2020
)
SELECT country_name, gdp_per_capita
FROM q
WHERE quartile = 4
ORDER BY gdp_per_capita DESC;

-- Q28 — CUME_DIST percentile ranks of countries by GDP per capita (2020)

SELECT c.country_name, e.gdp_per_capita,
       CUME_DIST() OVER (ORDER BY e.gdp_per_capita) AS percentile_rank
FROM economic_data e
JOIN countries c ON e.country_id = c.country_id
WHERE e.year = 2020
ORDER BY percentile_rank DESC;


-- Q29 — Rolling 5-year average GDP per capita for each country

SELECT country_name, year,
       ROUND(AVG(gdp_per_capita) OVER (PARTITION BY e.country_id ORDER BY year ROWS BETWEEN 4 PRECEDING AND CURRENT ROW),2) AS rolling_5yr_avg_gdp_pc
FROM economic_data e
JOIN countries c ON e.country_id = c.country_id
ORDER BY country_name, year;


-- Q30 — Country with most consistent GDP growth (lowest stddev of YoY growth)

WITH yoy AS (
  SELECT e.country_id, e.year,
         (e.gdp_usd - LAG(e.gdp_usd) OVER (PARTITION BY e.country_id ORDER BY year)) / NULLIF(LAG(e.gdp_usd) OVER (PARTITION BY e.country_id ORDER BY year),0) AS yoy_growth
  FROM economic_data e
)
SELECT c.country_name, STDDEV_SAMP(y.yoy_growth) AS sd_yoy_growth
FROM yoy y
JOIN countries c ON y.country_id = c.country_id
WHERE y.yoy_growth IS NOT NULL
GROUP BY c.country_name
ORDER BY sd_yoy_growth ASC
LIMIT 1;


-- Q31 — 5 countries contributing most to global GDP growth (2000–2020)

WITH totals AS (
  SELECT country_id,
         MAX(CASE WHEN year = 2000 THEN gdp_usd END) AS gdp_2000,
         MAX(CASE WHEN year = 2020 THEN gdp_usd END) AS gdp_2020
  FROM economic_data
  WHERE year IN (2000,2020)
  GROUP BY country_id
)
SELECT c.country_name,
       (gdp_2020 - gdp_2000) AS absolute_growth
FROM totals t
JOIN countries c ON t.country_id = c.country_id
ORDER BY absolute_growth DESC
LIMIT 5;


-- Q32 — Continents with high economic growth but low social development (example definition)

WITH cont_stats AS (
  SELECT c.continent,
         AVG((e.gdp_per_capita - LAG(e.gdp_per_capita) OVER (PARTITION BY c.continent ORDER BY e.year)) / NULLIF(LAG(e.gdp_per_capita) OVER (PARTITION BY c.continent ORDER BY e.year),0) * 100) AS avg_gdp_pc_growth,
         AVG(s.life_expectancy) AS avg_life_expectancy
  FROM economic_data e
  JOIN countries c ON e.country_id = c.country_id
  JOIN social_data s ON s.country_id = c.country_id AND s.year = e.year
  WHERE e.year BETWEEN 2010 AND 2020
  GROUP BY c.continent
)
SELECT continent
FROM cont_stats
WHERE avg_gdp_pc_growth > (SELECT AVG((gdp_per_capita) ) FROM economic_data WHERE year = 2020) -- adjust logic as needed
  AND avg_life_expectancy < (SELECT AVG(life_expectancy) FROM social_data WHERE year = 2020);


-- Q33 — Countries moving from developing → developed (GDP per capita > 12k for 5 consecutive years)

WITH flag AS (
  SELECT e.country_id, e.year,
         CASE WHEN e.gdp_per_capita > 12000 THEN 1 ELSE 0 END AS above
  FROM economic_data e
),
streaks AS (
  SELECT country_id, year,
         SUM(CASE WHEN above = 0 THEN 1 ELSE 0 END) OVER (PARTITION BY country_id ORDER BY year ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS grp,
         above
  FROM flag
)
SELECT DISTINCT c.country_name
FROM (
  SELECT country_id, COUNT(*) OVER (PARTITION BY country_id, grp) AS consecutive_years
  FROM streaks
  WHERE above = 1
) t
JOIN countries c ON t.country_id = c.country_id
WHERE consecutive_years >= 5;


-- Q34 — Rank continents by population share vs GDP share (2020)

WITH cont AS (
  SELECT c.continent,
         SUM(p.population) AS pop_sum,
         SUM(e.gdp_usd) AS gdp_sum
  FROM countries c
  JOIN population_data p ON c.country_id = p.country_id AND p.year = 2020
  JOIN economic_data e ON c.country_id = e.country_id AND e.year = 2020
  GROUP BY c.continent
),
totals AS (
  SELECT SUM(pop_sum) AS world_pop, SUM(gdp_sum) AS world_gdp FROM cont
)
SELECT cont.continent,
       ROUND(100.0 * cont.pop_sum / totals.world_pop,2) AS pop_share_pct,
       ROUND(100.0 * cont.gdp_sum / totals.world_gdp,2) AS gdp_share_pct
FROM cont, totals
ORDER BY pop_share_pct DESC;


-- Q35 — Predict which countries may overtake others by 2030 using linear growth projection (simple straight-line)

WITH latest AS (
  SELECT p.country_id, p.year, p.population,
         LAG(p.population) OVER (PARTITION BY p.country_id ORDER BY p.year DESC) AS previous_population,
         p.year - LAG(p.year) OVER (PARTITION BY p.country_id ORDER BY p.year DESC) AS year_diff
  FROM population_data p
),
growth_rate AS (
  SELECT country_id,
         (population - previous_population) / NULLIF(year_diff,0) AS yearly_change,
         population AS latest_population,
         year AS latest_year
  FROM latest
  WHERE previous_population IS NOT NULL
)
SELECT c.country_name,
       ROUND(latest_population + yearly_change * (2030 - latest_year)) AS projected_population_2030
FROM growth_rate g
JOIN countries c ON g.country_id = c.country_id
ORDER BY projected_population_2030 DESC
LIMIT 20;