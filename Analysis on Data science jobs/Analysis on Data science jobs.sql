show databases;
/*You're a compensation analyst employed by multinational corporation. Your task is to pinpoint Countries
who give work fully remote , for the title 'managers' paying salaries exceeding $90,000 USD */

use campusx;
select distinct company_location from salaries where salary_in_usd>=90000 
and remote_ratio=100
and job_title like '%Manager%';

/*As a remote work advocate working for a progressive HR tech startup who place their freshers' clients
in large tech firms, you're tasked with identifying top 5 countries having greatest count of large
(company size) number of companies */

select company_location, count(*) from salaries where experience_level='EN' and company_size='L' 
group by company_location order by count(*) desc limit 5;

/*Picture yourself as a data scientist working for a workforce management platform. Objective is to 
calculate the percentage of employees who enjoy fully remote roles with salaries exceeding $100,000 USD, 
Shedding light on the attractiveness of high paying remote positions in todays job market */

select job_title, round(100*count(job_title)/(select count(*) from salaries where remote_ratio=100 and salary_in_usd>100000),2)
as percentage from salaries where remote_ratio=100 and salary_in_usd>100000
group by job_title order by percentage desc;

/*Imagine you're a data analyst working for a global recruitment agency, your task is to identify the locations 
where entry level avg slaries exceed the avg salary of that job title in market for entry level, helping your agency guide candidates
towards lucrative opportunities*/

select a.job_title, company_location, average, avg_per_country from
(select job_title, avg(salary_in_usd) as average from salaries group by job_title) a
inner join 
(select company_location, job_title, avg(salary_in_usd) as avg_per_country from salaries group by company_location, job_title) b
on a.job_title=b.job_title;

/*For each job title which country pays max avg salary. This helps you place your candiddates in that country*/
#windows function

use campusx;
with cte as (select *, dense_Rank() over (partition by job_title order by avrg desc ) as num from (
select job_title, company_location, round(avg(salary_in_usd),2) as avrg from salaries group by job_title, company_location) a)
select job_title, company_location, avrg from cte where num=1;

/*As a data driven business consultant, you need to analyse salary trends across diff company locations. Goal is to pinpoint locations
where the avg salary has consistently increased over the past few years (countries where data is available for 3 yrs , only present 
and past 2 yrs) providing insights into locations experiencing sustained salary growth*/

select * from salaries limit 5;
with cte as (
select * from salaries where company_location in (select company_location from 
(select company_location, work_year, round(avg(salary_in_usd),2) as avrg
 from salaries where work_year >= year(current_date())-2 
group by company_location having count(distinct work_year)=3) c)) #filtering that has 3 year consistent records
select company_location, 
max(case when work_year=2022 then average end) as avg_sal_2022,
max(case when work_year=2023 then average end) as avg_sal_2023,
max(case when work_year=2024 then average end) as avg_sal_2024      #pivoting for YOY growth
from(
select company_location, work_year, avg(salary_in_usd) as average from cte group by company_location, work_year) a
group by company_location having avg_sal_2024>avg_sal_2023 and avg_sal_2023>avg_sal_2022;

/*As a workforce strategist employed by a global HR determine the % of  fully remote work for each experience level in 2021
and compare it with the corresponding figures for 2024, highlighting any significant increase or decrease in remote work adoption
over the years*/

with cte as (
select a.experience_level, total, cnt from 
(
select experience_level, count(*) as total from salaries where work_year= 2021 group by experience_level
) a inner join
(
select experience_level, count(*) as cnt from salaries where work_year= 2021 and remote_ratio=100 group by experience_level
) b on a.experience_level=b.experience_level
)
select experience_level, round(100*cnt/total,2) as percentage from cte;       #creating 2 var cnt and total to take % later

with cte1 as (
select a.experience_level, total, cnt from 
(
select experience_level, count(*) as total from salaries where work_year= 2021 group by experience_level
) a inner join
(
select experience_level, count(*) as cnt from salaries where work_year= 2021 and remote_ratio=100 group by experience_level
) b on a.experience_level=b.experience_level
), 
cte2 as (
select a.experience_level, total, cnt from 
(
select experience_level, count(*) as total from salaries where work_year= 2024 group by experience_level
) a inner join
(
select experience_level, count(*) as cnt from salaries where work_year= 2024 and remote_ratio=100 group by experience_level
) b on a.experience_level=b.experience_level
)
select c1.experience_level, round(100*c1.cnt/c1.total,2) as percentage_2021, round(100*c2.cnt/c2.total,2) as percentage_2024
from cte1 c1 inner join cte2 c2 on c1.experience_level=c2.experience_level;

/* As a compensation specialist analyse salary trends over time. Calculate the avg salary increase percentage for each 
experience level and job title between 2023 and 2024, helping company stay competetive in the talent market*/

/* As a dba tasked with role based access control for a company's employee database. Goal is to implement a security measure
where employees from diff experience levels can only access details relevant to their role ensuring data confidentiality 
and minimizing the risk of unauthorized access*/

#DCL Grant and revoke after @ you put host name
create user 'Entry_level'@'%' identified by 'EN';
create view entry_level as 
(select * from salaries where experience_level='EN');
show privileges;
grant select on campusx.entry_level to 'Entry_level'@'%';

