SELECT Location, date, total_cases, new_cases, total_deaths, population FROM CovidDeaths$
ORDER BY 1,2

-- Looking at the total cases vs total deaths

SELECT Location, date, total_cases, total_deaths,(total_deaths/total_cases*100) as 'Death Percentage' 
FROM CovidDeaths$
ORDER BY 1,2

-- Looking at the total cases vs the population
-- in other words, what percentage of the population has been infected
-- Filtered by United States because I found it interesting. Comment out "WHERE location like '%states%'" to see world wide

SELECT Location, date, total_cases, population,(total_cases/population*100) as 'Infection Rate (Percent)' 
FROM CovidDeaths$
WHERE location like '%states%'
ORDER BY 1,2

--Looking at which country has the highest infection rate compared to population
--Highest infection count which will be the most recent total infection count, and also gets the max of total_cases/population, which will also be the most recent because those numbers will always increase over time.

SELECT Location, MAX(total_cases) as 'Highest Infection Count', population,MAX((total_cases/population))*100 as 'percent population infected' 
FROM CovidDeaths$
GROUP BY Location,population
ORDER BY [percent population infected] desc


--Looking at highest death rate by country
-- Must disclude results where continent is NULL because otherwise inappropriate grouping of countries appears. Rather than see "Asia" I would rather see how each country in Asia stacks up.

SELECT Location, max(CAST(total_deaths as int)) as 'Total Death Count'
FROM CovidDeaths$
WHERE continent is not NULL
GROUP BY Location
ORDER BY [Total Death Count] desc


--If you would rather see continent break down then this is more appropriate

SELECT location, max(CAST(total_deaths as int)) as 'Total Death Count'
FROM CovidDeaths$
WHERE continent is NULL
GROUP BY location
ORDER BY [Total Death Count] desc


--Worldwide Numbers

SELECT  date, SUM(new_cases) as 'Global Cases', SUM(CAST(new_deaths as int)) as 'Global Deaths', SUM(CAST(new_deaths as int))/SUM(new_cases)*100 as 'Global Death Percentage'
FROM CovidDeaths$
WHERE continent is not NULL
group by date
ORDER BY 1,2



--This is our second table with information about vaccines
SELECT * FROM CovidVaccinations$


--Now we join them to find out what the vaccination rate vs population is

SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
SUM(convert(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as 'Rolling Count of Vaccinations'
FROM CovidDeaths$ dea
JOIN CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not NULL
ORDER BY 2,3


--Using CTE

WITH popvsvac (Continent, location, date, population, [Rolling Count of Vaccinations],new_vaccinations)
as
(
SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
SUM(convert(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as 'Rolling Count of Vaccinations'
FROM CovidDeaths$ dea
JOIN CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not NULL
)

select *, (([Rolling Count of Vaccinations]/population)*100) as 'Percentage Population Vaccinated' from popvsvac 


--TEMP TABLE

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255), location nvarchar(255), Date datetime, Population numeric, new_vaccinations numeric, [Rolling Count of Vaccinations] numeric
)

INSERT #PercentPopulationVaccinated
SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
SUM(convert(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as 'Rolling Count of Vaccinations'
FROM CovidDeaths$ dea
JOIN CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not NULL

select *, (([Rolling Count of Vaccinations]/population)*100) as 'Percentage Population Vaccinated' from #PercentPopulationVaccinated
ORDER BY 2,3



--Creating views to Store data for vizzes

CREATE VIEW PercentPopulationVaccinated as
SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
SUM(convert(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as 'Rolling Count of Vaccinations'
FROM CovidDeaths$ dea
JOIN CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not NULL


CREATE VIEW ContinentDeathRate as
SELECT location, max(CAST(total_deaths as int)) as 'Total Death Count'
FROM CovidDeaths$
WHERE continent is NULL
GROUP BY location
--ORDER BY [Total Death Count] desc

CREATE VIEW CountryDeathRate as
SELECT Location, max(CAST(total_deaths as int)) as 'Total Death Count'
FROM CovidDeaths$
WHERE continent is not NULL
GROUP BY Location
--ORDER BY [Total Death Count] desc

CREATE VIEW PercentPopulationInfected as
SELECT Location, MAX(total_cases) as 'Highest Infection Count', population,MAX((total_cases/population))*100 as 'percent population infected' 
FROM CovidDeaths$
GROUP BY Location,population
--ORDER BY [percent population infected] desc

CREATE VIEW WorldWideDeathRate as
SELECT  date, SUM(new_cases) as 'Global Cases', SUM(CAST(new_deaths as int)) as 'Global Deaths', SUM(CAST(new_deaths as int))/SUM(new_cases)*100 as 'Global Death Percentage'
FROM CovidDeaths$
WHERE continent is not NULL
group by date
--ORDER BY 1,2

CREATE VIEW USDeathRate as
SELECT Location, date, total_cases, population,(total_cases/population*100) as 'Infection Rate (Percent)' 
FROM CovidDeaths$
WHERE location like '%states%'
--ORDER BY 1,2

CREATE VIEW DeathRateByCountry as
SELECT Location, date, total_cases, total_deaths,(total_deaths/total_cases*100) as 'Death Percentage' 
FROM CovidDeaths$
--ORDER BY 1,2