---For upload reason sometimes data have varchar values. In order to use them inside the calculation the datatype will be changed with the cast function. 
--- 
---Look into CovidDeaths table
SELECT *
FROM dbo.CovidDeaths
ORDER BY location

---Look into CovidVaccinations table
SELECT *
FROM dbo.CovidVaccinations
ORDER BY location

---Total cases for each country
	---Method 1
Select location, max(cast (total_cases as float)) as TotalCases
FROM dbo.CovidDeaths
WHERE continent is not null
group by location
order by 2 desc

	---Method 2
Select location, sum(cast (new_cases as float)) as TotalCases
FROM dbo.CovidDeaths
WHERE continent is not null
group by location
order by 2 desc

---Total cases for each continent
	---Method 1
Select continent, sum(cast (new_cases as float)) as TotalCases
FROM dbo.CovidDeaths
WHERE continent is not null
group by continent
order by 2 desc

	---Method 2
WITH Cases(continent, location, TotalCases)
as 
(
Select continent, location, max(cast (total_cases as float)) as TotalCases
FROM dbo.CovidDeaths
WHERE continent is not null
group by continent,location
)
select continent, sum(TotalCases) as TotalCases
from Cases
group by continent 
order by 2 desc

---Total deaths for each country
Select location, sum(cast (new_deaths as float)) as TotalDeaths
FROM dbo.CovidDeaths
WHERE continent is not null
group by location
order by 2 desc


---Total Deaths for continent 
Select continent, sum(cast (new_deaths as float)) as TotalDeaths
FROM dbo.CovidDeaths
WHERE continent is not null
group by continent
order by 2 desc

---Total cases vs Total deaths per day
Select location, date, total_cases, total_deaths, (cast(total_deaths as float)/cast(total_cases as float))*100 as DeathPercentage
FROM dbo.CovidDeaths
where continent is not null
order by 1,2

---Percentage of infected population
Select location, date, population, total_cases, (cast(total_cases as float)/cast(population as float))*100 as InfectionRate
FROM dbo.CovidDeaths
where continent is not null
order by 1,2


---Highest infection rate per country 
select location, population, max(cast(total_cases as float)) as Total_cases, max((cast(total_cases as float)/cast(population as float))*100) as InfectionRate
FROM dbo.CovidDeaths
where continent is not null
group by location, population
order by 4 DESC

---Highest death rate countries at the end of 2020
Select location, date, total_cases, total_deaths, (cast(total_deaths as float)/cast(total_cases as float))*100 as DeathPercentage
FROM dbo.CovidDeaths
where cast(date as date)='2020-12-31' and continent is not null
order by 5 desc,1 


---Global death, infection and death rate
select sum(cast(new_cases as float)) GlobalCases, sum(cast(new_deaths as float)) as GlobalDeaths, round((sum(cast(new_deaths as float))/sum(cast(new_cases as float)))*100,2) As GlobalDeathRatePercentage
FROM dbo.CovidDeaths
where continent is not null


---Global death, infection and death rate per year
select year(cast (date as date)) as Year, sum(cast(new_cases as float)) GlobalCases, sum(cast(new_deaths as float)) as GlobalDeaths, round((sum(cast(new_deaths as float))/sum(cast(new_cases as float)))*100,2) As GlobalDeathRatePercentage
FROM dbo.CovidDeaths
where continent is not null
group by year(cast (date as date))
order by 1

---Highest reproduction rate per country (with the relative date)
with ReproductionRate as(
select location,max(cast(reproduction_rate as float)) as reproduction_rate
from dbo.CovidDeaths
where continent is not null and reproduction_rate is not null
group by location)
select r.location, r.reproduction_rate, d.date
from ReproductionRate as r join dbo.CovidDeaths as d on r.location=d.location and r.reproduction_rate=d.reproduction_rate

---Join death with vaccination table
select *
from dbo.CovidDeaths as d join dbo.CovidVaccinations as c on d.date=c.date and d.location=c.location
where d.location like 'italy' and d.date>'01-01-2021'
order by 3,4

---Test vs positives
select d.location, d.date, d.new_cases, c.new_tests, cast(d.new_cases as float)/cast(c.new_tests as float)*100 as PercentageOfPositiveTests
from dbo.CovidDeaths as d join dbo.CovidVaccinations as c on d.date=c.date and d.location=c.location
where d.continent is not null
order by PercentageOfPositiveTests desc


---New people vaccinated per day
select d.location, d.date, d.population, cast(c.people_vaccinated as float) as PeopleVaccinated, cast(c.people_vaccinated as float)-(lag(cast(c.people_vaccinated as float)) over (partition by d.location order by d.location, d.date)) as NewPeopleVaccinated
from dbo.CovidDeaths as d join dbo.CovidVaccinations as c on d.date=c.date and d.location=c.location
where d.continent is not null


---Percentage of people vaccinated daily and total
with Vaccinations (location, date, population, PeopleVaccinated, NewPeopleVaccinated)
as
(select d.location, d.date, d.population, cast(c.people_vaccinated as float) as PeopleVaccinated, cast(c.people_vaccinated as float)-(lag(cast(c.people_vaccinated as float)) over (partition by d.location order by d.location, d.date)) as NewPeopleVaccinated
from dbo.CovidDeaths as d join dbo.CovidVaccinations as c on d.date=c.date and d.location=c.location
where d.continent is not null)
select location, date, population, PeopleVaccinated, NewPeopleVaccinated, PeopleVaccinated/cast(population as float)*100 as PercentageOfVaccinatedPeople, NewPeopleVaccinated/cast(population as float)*100 as DailyPercentageOfVaccinatedPeople  
from Vaccinations

---Contries with the highest percentage of vaccinated people
---Excluding countries with percentage >100% because it's probably and error
select top 20 d.location, max(cast(c.people_vaccinated as float)/cast(d.population as float))*100 as Percentage_of_vaccinated
from dbo.CovidDeaths as d join dbo.CovidVaccinations as c on d.date=c.date and d.location=c.location
where d.continent is not null
group by d.location
having max(cast(c.people_vaccinated as float)/cast(d.population as float))<1
order by 2 desc


---Percentage of people fully vaccinated 
select d.location, d.date, d.population, c.people_fully_vaccinated, cast(c.people_fully_vaccinated as float)/cast(d.population as float)*100 as Percentage_of_fully_vaccinated
from dbo.CovidDeaths as d join dbo.CovidVaccinations as c on d.date=c.date and d.location=c.location
where d.continent is not null
order by 1,2

---European countries with the highest percentage of fully vaccinated people
---Excluding countries with percentage >100% because it's probably and error
select top 20 d.location, max(cast(c.people_fully_vaccinated as float)/cast(d.population as float))*100 as Percentage_of_fully_vaccinated
from dbo.CovidDeaths as d join dbo.CovidVaccinations as c on d.date=c.date and d.location=c.location
where d.continent is not null and d.continent='Europe'
group by d.location
having max(cast(c.people_fully_vaccinated as float)/cast(d.population as float))<1
order by 2 desc

---Creating view with the main information about vaccination
---Using the group by and max function because selecting just one day some information are null
create view CovidData as 
select d.location, max(d.population) as population, max(d.total_deaths) as total_deaths, max(c.people_vaccinated) as people_vaccinated, max(c.people_fully_vaccinated) as people_fully_vaccinated, max(cast(c.people_fully_vaccinated as float)/cast(d.population as float)) as PercentageOfVaccinated, max(cast(c.people_fully_vaccinated as float)/cast(d.population as float)) as PercentageOfFullyVaccinated, max(c.total_boosters) as total_boosters, max(c.total_vaccinations) as total_vaccinations
from dbo.CovidDeaths as d join dbo.CovidVaccinations as c on d.date=c.date and d.location=c.location
where d.continent is not null
group by d.location


