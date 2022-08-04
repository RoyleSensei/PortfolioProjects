select *
from coviddeath;


-- Looking at Total Cases VS Total Deaths
-- Shows likelihood of dying if you contract Covid in your country
select location, date, total_cases, total_deaths, round((total_deaths/total_cases)*100,2) as death_rate
from coviddeath
where location = 'United States';



-- Looking at the total cases vs the population in the United States
-- shows what percentage of population got covid

select location, date, total_cases, population, round((total_cases/population)*100,2) as Infection_Rate
from coviddeath
where location = 'United States';



-- Looking at Countries with Highest Infection Rate compared to population

select location, population, max(total_cases) as Highest_Infection_Count,
        max(round((total_cases/population)*100,2)) as Infection_Rate
from coviddeath
-- where location like "%states%"
group by location, population
order by Infection_Rate desc;


-- Showing the countries with Highest death count per population

select location, max(total_deaths) as TotalDeathCount
from coviddeath
where location != 'World'
and location not like '%income'
and location not like '%Unknown%'
and location not like '%Union%'
and location is not null
group by location
order by TotalDeathCount DESC;


-- LET"S BREAK THINGS DOWN BY CONTINENT
-- Showing the continents with Highest death count per population
select continent, max(total_deaths) as TotalDeathCount
from coviddeath
where location != 'World'
and location not like '%income'
and location not like '%Unknown%'
and location not like '%Union%'
and location is not null
and continent is not null
group by continent
order by TotalDeathCount DESC;


-- GLOBAL NUMBERS
select date, SUM(new_cases), sum(new_deaths), round(sum(new_deaths)/sum(new_cases)*100, 2)as DeathPercentage
from coviddeath
where continent is not null
-- group by date
order by iso_code, continent;


#Move on to CovidVaccination

select c.continent, c.location, c.date, c.population, v.new_vaccinations,
       sum(v.new_vaccinations) over(partition by c.location order by c.location, c.date) As RollingPeopleVaccinated

from covidvaccinations v
left join coviddeath c
on v.v_date = c.date
where c.location not like '%Unknown%'
and v.new_vaccinations is not null

-- use CTE

with PopVSVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated) as
(select c.continent, c.location, c.date, c.population, v.new_vaccinations,
       sum(v.new_vaccinations) over(partition by c.location order by c.location, c.date) As RollingPeopleVaccinated
from covidvaccinations v
left join coviddeath c
on v.v_date = c.date
and v.location = c.location
where c.location not like '%Unknown%'
and c.continent is not null
order by c.location, c.date
limit 500
)
select *
from PopVSVac;


-- Temp table
Create Table PercentPopulationVaccinated
(
    Continent varchar(255),
    Location varchar(255),
    Date datetime,
    Population numeric,
    New_vaccinations numeric,
    RollingPeopleVaccinated numeric
)
insert into PercentPopulationVaccinated
select c.continent, c.location, c.date, c.population, v.new_vaccinations,
       sum(v.new_vaccinations) over(partition by c.location order by c.location, c.date) As RollingPeopleVaccinated
from covidvaccinations v
left join coviddeath c
on v.v_date = c.date
and v.location = c.location
where c.location not like '%Unknown%'
and c.continent is not null
order by c.location, c.date;

select *, (RollingPeopleVaccinated/population)*100
from PercentPopulationVaccinated


#Create View to Store Data for later visualizations

Create view V_PercentPopulationVaccinated as
select c.continent, c.location, c.date, c.population, v.new_vaccinations,
       sum(v.new_vaccinations) over(partition by c.location order by c.location, c.date) As RollingPeopleVaccinated
from covidvaccinations v
left join coviddeath c
on v.v_date = c.date
and v.location = c.location
where c.location not like '%Unknown%'
and c.continent is not null
order by c.location, c.date;

select * from V_PercentPopulationVaccinated