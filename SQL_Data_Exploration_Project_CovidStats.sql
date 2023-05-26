SELECT *
FROM CovidDeaths
WHERE continent IS NOT NULL
order by 3,4

SELECT *
FROM CovidVaccinations
order by 3,4;

-- Select Data that we are going to be using

Select Location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
Order by location, date 

-- Looking for total cases vs total deaths
-- Shows likelihood of dying if you contract Covid in Argentina

Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM CovidDeaths
WHERE location like 'Argentina'
Order by location, date 

-- Looking at total cases vs population
-- Shows what % of the population got covid

Select Location, date,population, total_cases,(total_cases/population)*100 as infection_rate
FROM CovidDeaths
WHERE location like 'Argentina'
Order by location, date 

-- What countries have the highest infection rates compared to population

Select Location,population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as infection_rate
FROM CovidDeaths
group by location,population
order by infection_rate desc


-- Show Countries with highest death count per capita

UPDATE CovidDeaths 
SET CONTINENT = NULL 
WHERE CONTINENT = ''

Select Location,population, MAX(total_deaths) as TotalDeathCount, MAX((total_deaths/population))*100 as death_rate
FROM CovidDeaths
WHERE CONTINENT IS NOT NULL
group by location,population
order by TotalDeathCount desc

-- BREAK DOWN BY CONTINENT

Select Location, MAX(total_deaths) as TotalDeathCount
FROM CovidDeaths
WHERE CONTINENT IS NULL AND LOCATION NOT IN ('HIGH INCOME','UPPER MIDDLE INCOME','LOWER MIDDLE INCOME','LOW INCOME')
group by location
order by TotalDeathCount desc

-- BREAK DOWN BY GLOBAL NUMBERS


Select date, SUM(new_cases) AS TotalDailyCases, SUM(new_deaths) TotalDailyDeaths,  SUM(new_deaths)/SUM(new_cases)*100 AS DailyDeathPcg
FROM CovidDeaths
WHERE CONTINENT IS NOT NULL AND new_cases > 0
group by date 
order by date 

Select SUM(new_cases) AS TotalDailyCases, SUM(new_deaths) TotalDailyDeaths,  SUM(new_deaths)/SUM(new_cases)*100 AS DailyDeathPcg
FROM CovidDeaths
WHERE CONTINENT IS NOT NULL

--Looking at Total Population vs Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM (vac.new_vaccinations) OVER (Partition by dea.Location ORDER by dea.location, dea.date) as RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
where dea.continent is not null 
order by 2,3

--USING CTE for RollingPeopleVaccinated Column

With PopvsVac (Continent, Location, Date, Population, New_vaccinations, RollingPeopleVaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM (vac.new_vaccinations) OVER (Partition by dea.Location ORDER by dea.location, dea.date) as RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
where dea.continent is not null 
)
Select *, (RollingPeopleVaccinated/population)*100
From PopvsVac

--USING TEMP TABLE
DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(Continent nvarchar(50), Location nvarchar(50), Date datetime, Population float, New_vaccinations float, RollingPeopleVaccinated float)

Insert Into #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM (vac.new_vaccinations) OVER (Partition by dea.Location ORDER by dea.location, dea.date) as RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
where dea.continent is not null 

Select *, (RollingPeopleVaccinated/population)*100
From #PercentPopulationVaccinated

--Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM (vac.new_vaccinations) OVER (Partition by dea.Location ORDER by dea.location, dea.date) as RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
where dea.continent is not null 

Select * 
From PercentPopulationVaccinated