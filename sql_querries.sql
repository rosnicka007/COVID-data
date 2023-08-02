-- FIRST UPLOAD OF COVID DEATH DATA WITH DROPPING VALUES WITHOUT CONTINENT LOCATION
SELECT *
FROM CovidDeaths
WHERE continent IS NOT NULL;

-- SELECTION OF DATA FOR MY NEXT WORK
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
ORDER BY 1, 2;

-- TOTAL CASES VS. TOTAL DEATHS IN THE CZECH REPUBLIC
SELECT location, date, total_cases, total_deaths, ROUND((total_deaths/total_cases)*100, 2) AS DeathPercentage
FROM CovidDeaths
WHERE location LIKE 'Czech%'
AND continent IS NOT NULL
ORDER BY 1, 2;

-- LOOKING AT TOTAL CASES VS. POPULATION (THE RISK OF INFECTION)
SELECT location, date, total_cases, population, ROUND((total_cases/population)*100, 2) AS PercentageOfInfection
FROM CovidDeaths
WHERE location LIKE 'Czech%'
AND continent IS NOT NULL
ORDER BY 1, 2;

-- LOOKING AT COUNTRIES WITH THE HIGHEST INFECTION RATE COMPARED TO POPULATION
SELECT location, date, MAX(total_cases) AS HighestInfectionCount, population, MAX((total_cases/population))*100 AS PercentageOfInfection
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PercentageOfInfection DESC;

-- NUMBERS OF DEATHS IN PERCENTS IN POPULATION ACCORDING CONTINENT AND LOCATION
SELECT continent, location, population, SUM(new_deaths) AS Total_deaths, ROUND(SUM(new_deaths) /population*100, 2) AS Percent_of_deaths_in_population
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent, location
ORDER BY Percent_of_deaths_in_population DESC;

-- LOOKING AT COUNTRIES WITH THE HIGHEST DEATH COUNT PER POPULATION
SELECT location, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- SELECTING THE CONTINENTS WITH THE HIGHEST DEATH COUNT PER POPULATION
SELECT continent, MAX(CAST(Total_deaths AS int)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- GLOBAL NUMBERS
SELECT date, SUM(new_cases), SUM(new_deaths), (SUM(new_deaths)/SUM(new_cases))*100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1, 2;

-- JOINING TABLES CovidDeaths + CovidVaccinations FOR THE FUTURE WORK
SELECT *
FROM CovidDeaths AS dea
JOIN CovidVaccinations AS vac
ON dea.location = vac.location AND dea.date=vac.date;

-- NUMBERS OF VACCINATED PEOPLE IN THE CZECH REPUBLIC
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations ) OVER (PARTITION BY dea.Location LIKE 'Czech%' ORDER BY dea.location, dea.Date)
FROM CovidDeaths AS dea
JOIN CovidVaccinations AS vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND dea.location LIKE 'Czech%'
ORDER BY 3;

-- OVERVIEW OF VACCINATED AND DEATH PEOPLE
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations ) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date)
FROM CovidDeaths AS dea
JOIN CovidVaccinations AS vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;

-- LOOKING AT TOTAL POPULATION VS. VACCINATION
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;

-- PREPARING A VIEW TO CALCULATE PERCENTAGES OF VACCINATED PEOPLE
CREATE VIEW Percents_of_vaccinated AS
WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT * , (RollingPeopleVaccinated/population)*100 AS PercentPopulationVaccinated
FROM PopvsVac;

-- PREPARING OF TEMPORARY TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinated;
CREATE TABLE #PercentPopulationVaccinated (continent nvarchar(255), location nvarchar(255), date datetime, population numeric, new_vaccinations numeric, RollingPeopleVaccinated numeric);

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL; --AND dea.location LIKE 'Canada'
--ORDER BY 2, 3

SELECT *, (RollingPeopleVaccinated/population)*100
FROM #PercentPopulationVaccinated;

-- CREATING A VIEW TO STORE DATA FOR VISUALIZATION - PERCENTS OF VACCINATED POPULATION
CREATE VIEW PercentPopulationVaccinated3 AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated, (RollingPeopleVaccinated/population)*100
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

SELECT *, (RollingPeopleVaccinated/population)*100 AS PercentPopulationVaccinated
FROM #PercentPopulationVaccinated;

-- CREATING VIEW VACCINATION STATS
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated/Population)*100 AS PercentPeopleVaccinated
FROM PopvsVac;

SELECT Location, Population, date, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM CovidDeaths
WHERE location LIKE '%states%'
GROUP BY Location, Population, date
ORDER BY PercentPopulationInfected DESC;

-- CREATING VIEW OF PERCENTAGE OF VACCINATED POPULATION
CREATE VIEW PercentPopulationVaccinated2 AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;







