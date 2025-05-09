-- HA 2
-- Author: Elena Ibraeva
-- Topics: JOIN, GROUP BY, TEMP TABLE, AGGREGATION, SUBQUERIES

-- Task 1: Regions and continents with independence year 1900–1920, life expectancy ≥ 70, area per capita ≥ 0.05
SELECT c."name", c.continent, c.region
FROM country c
WHERE indepyear BETWEEN 1900 AND 1920
  AND lifeexpectancy >= 70
  AND (surfacearea / population) >= 0.05;

-- Task 2: Countries where international and local names differ
SELECT name
FROM country c
WHERE c."name" != c.localname;

-- Task 3: Most populous countries by continent
SELECT c.continent, c.name, c.surfacearea
FROM country c
JOIN (
   SELECT continent, MAX(population) AS max_population
   FROM country
   WHERE population != 0
   GROUP BY continent
) c2 ON c.continent = c2.continent AND c.population = c2.max_population;

-- Task 4: Government forms with life expectancy < 61 in Asia or Europe
SELECT DISTINCT c.governmentform
FROM country c
WHERE c.lifeexpectancy < 61 AND c.continent IN ('Asia', 'Europe');

-- Task 5: Countries with names that include their country code
SELECT DISTINCT c."name"
FROM country c
WHERE c."name" ILIKE '%' || code || '%';

-- Task 6: Flights from DME in a specific interval, with duration in minutes
SELECT f.flight_id,
       EXTRACT(EPOCH FROM (f.actual_arrival - f.actual_departure)) / 60 AS flight_duration
FROM flights f
WHERE f.actual_departure >= '2017-02-20 15:00:00.000+03'
  AND f.actual_departure < '2017-02-20 18:00:00.000+03';

-- Task 7: Languages with ≥ 30% popularity per country, with speaker population
CREATE TEMP TABLE popularlanguages AS
SELECT l.*,
       c.population,
       ROUND((c.population * l.percentage)::numeric / 100) AS speakingpopulation
FROM countrylanguage l
LEFT JOIN country c ON l.countrycode = c.code;

SELECT p.countrycode, c."name", p.language, p.isofficial, p.speakingpopulation
FROM popularlanguages p
LEFT JOIN country c ON p.countrycode = c.code
ORDER BY c."name" ASC, p.isofficial DESC;

-- Task 8: Top 10 largest cities in English-speaking countries
SELECT c.*
FROM city c
LEFT JOIN popularlanguages p ON c.countrycode = p.countrycode
WHERE p.language = 'English'
ORDER BY c.population DESC
LIMIT 10;

-- Task 9: Combined list of continents, countries, and regions
SELECT DISTINCT LEFT(name, 1) AS first_letter, name AS geo_name, 'Страна' AS geo_type FROM country
UNION
SELECT DISTINCT LEFT(continent, 1), continent, 'Континент' FROM country
ORDER BY geo_name;

-- Task 10: Compare city population to country capital
SELECT
   ct."name" AS city_name,
   (SELECT c."name" FROM city c WHERE c.id = cn.capital) AS capital_name,
   cn."name" AS country_name,
   cn.continent,
   ROUND((ct.population / NULLIF((SELECT c.population FROM city c WHERE c.id = cn.capital), 0)) * 100, 2) AS population_percentage
FROM city ct
LEFT JOIN country cn ON cn.code = ct.countrycode
ORDER BY cn.continent, ct."name";
