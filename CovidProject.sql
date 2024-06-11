		-- Portfolio Project -- 

-- SELECT * 
-- FROM coviddeaths
-- WHERE continent IS NOT NULL
-- order by 3, 4; 

-- SELECT * 
-- FROM covidvaccinations
-- order by 3, 4;

-- ALTER TABLE covidvaccinations
-- RENAME COLUMN ï»¿iso_code TO iso_code; 

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM coviddeaths; 

-- Country Level
-- Evaluate total cases vs total deaths, otherwise, deaths per case
	-- this output will show the likelihood of death if covid is contracted in selected country
SELECT location, date, total_cases, new_cases, total_deaths, (total_deaths/total_cases)* 100 AS death_rate
FROM coviddeaths
WHERE location  LIKE '%costa%'; 

 -- Look at the MAX number of cases per country 
SELECT location, 
MAX(total_cases)
FROM coviddeaths
GROUP BY location; 


-- Evaluate total cases per population
	-- output will show the contraction rate of covid of selected country
SELECT location, date, population, total_cases, (total_cases/population)* 100 AS contraction_rate
FROM coviddeaths
WHERE continent IS NOT NULL
AND location  LIKE '%costa%'; 


-- Evaluate countries with highest infection rate per population

SELECT location, population, MAX(total_cases) as highest_infection, MAX((total_cases/population))* 100 AS maxinfection_percounty
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY maxinfection_percounty DESC; 

		-- Highest Death Count per Country Population
SELECT location, MAX(cast(total_deaths AS UNSIGNED)) AS maxtotaldeaths
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY maxtotaldeaths DESC; 

-- Continent level
		-- Highest Death Count by Continent
SELECT continent, MAX(cast(total_deaths AS UNSIGNED)) AS maxtotaldeaths
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY maxtotaldeaths DESC; 

-- Global Level
		-- Death Rates by Continent
SELECT date, SUM(new_cases) as total_newcases, SUM(new_deaths) AS total_newdeaths, SUM(new_deaths)/SUM(new_cases)*100 as global_deathrates
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY date; 

		-- New Cases to New Ratio
SELECT SUM(new_cases) as total_newcases, SUM(new_deaths) AS total_newdeaths, SUM(new_deaths)/SUM(new_cases)*100 as global_deathrates
FROM coviddeaths
WHERE continent IS NOT NULL;
-- GROUP BY date; 


-- -------------------- --

-- Vaccinations 
	-- Join tables coviddeaths & covidvaccinations
SELECT * 
FROM coviddeaths cd
JOIN covidvaccinations cv
	ON cd.location = cv.location 
    AND cd.date = cv.date; 
    
-- Total Vaccinations per Population 
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
	SUM(CAST(cv.new_vaccinations as UNSIGNED)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS vaccinationcount_rolling -- produces a rolling count of vaccinations
FROM coviddeaths cd
JOIN covidvaccinations cv
	ON cd.location = cv.location 
    AND cd.date = cv.date
WHERE cd.continent is NOT NULL AND cd.location = 'Costa Rica'
ORDER BY 2,3; 

		-- USING CTE -- 
WITH vac_per_pop (continent, location, date, population, new_vaccinations, vaccinationcount_rolling)
AS 
(
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
	SUM(CAST(cv.new_vaccinations as UNSIGNED)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS vaccinationcount_rolling
FROM coviddeaths cd
JOIN covidvaccinations cv
	ON cd.location = cv.location 
    AND cd.date = cv.date
WHERE cd.continent is NOT NULL
-- ORDER BY 2,3 
)
SELECT *, (vaccinationcount_rolling/population) * 100 AS percentvacc_rolling
FROM vac_per_pop; 

		-- USING TEMP TABLE -- 
DROP TABLE IF EXISTS percentpopulationvaccinated; 
CREATE TEMPORARY TABLE percentpopulationvaccinated
(
continent varchar(255), 
location varchar(255), 
date datetime, 
population int, 
new_vaccinations int, 
vaccinationcount_rolling int
); 
INSERT INTO percentpopulationvaccinated (continent, location, date, population, new_vaccinations, vaccinationcount_rolling)
SELECT cd.continent, cd.location, STR_TO_DATE(cd.date, '%d/%m/%Y') AS date, cd.population, NULLIF(cv.new_vaccinations, '') AS new_vaccinations,
	SUM(NULLIF(cv.new_vaccinations, 0)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS vaccinationcount_rolling
FROM coviddeaths cd
JOIN covidvaccinations cv
	ON cd.location = cv.location 
    AND cd.date = cv.date; 
-- WHERE cd.continent IS NOT NULL; 
-- ORDER BY 2,3; 
SELECT *, (vaccinationcount_rolling/population) * 100 AS vac_rate
FROM percentpopulationvaccinated;

-- ----------------------- --

-- Create View For Data Visualizations -- 
CREATE VIEW percentpopulationvaccinated AS 
SELECT cd.continent, cd.location, STR_TO_DATE(cd.date, '%d/%m/%Y') AS date, cd.population, NULLIF(cv.new_vaccinations, '') AS new_vaccinations,
	SUM(NULLIF(cv.new_vaccinations, 0)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS vaccinationcount_rolling
FROM coviddeaths cd
JOIN covidvaccinations cv
	ON cd.location = cv.location 
    AND cd.date = cv.date
WHERE cd.continent IS NOT NULL; 
-- ORDER BY 2,3; 


