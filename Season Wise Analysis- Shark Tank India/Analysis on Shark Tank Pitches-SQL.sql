
use campusx;
truncate table sharktank;
desc sharktank;
ALTER TABLE sharktank
MODIFY Started_in text;
ALTER TABLE sharktank
RENAME COLUMN `Namita_Investment_Amount_in lakhs` TO Namita_Investment_Amount_in_lakhs;

load data infile "C:/Users/simra/Downloads/sharktank.csv"
into table sharktank
fields terminated by ','
optionally enclosed by '"'
lines terminated by '\r\n'
ignore 1 rows;

/* You Team have to  promote shark Tank India  season 4, The senior come up with the idea to show highest 
funding domain wise  and you were assigned the task to  show the same. */

select * from sharktank limit 5;
select industry, max(Total_Deal_Amount_in_lakhs) as Total_deal_in_lakhs
from sharktank group by industry order by Total_deal_in_lakhs desc;

/* You have been assigned the role of finding the domain where female as pitchers have female to male pitcher ratio >70% */

select *, round(female/male*100,2) as percentage from (
select industry, sum(Female_Presenters) as female, sum(Male_Presenters) as male from sharktank group by industry
having female>0 and male>0) a having percentage>70;

/* You are working at marketing firm of Shark Tank India, you have got the task to determine volume of per year sale 
pitch made, pitches who received offer and pitches that were converted. Also show the percentage of pitches 
converted and percentage of pitches received. */

select * from sharktank;
select a.Season_Number, Total, Received, round((Received/Total)*100,2) as Perc_received, Accepted, round((Accepted/Total)*100,2) as Perc_Accepted from (
select Season_Number, count(Startup_Name) as Total from sharktank group by Season_Number) a -- total startups that came
inner join (
select Season_Number, count(Startup_Name) as Received from sharktank where Received_Offer='Yes' group by Season_Number) b-- how many received offer
on a.Season_Number=b.Season_Number inner join (
select Season_Number, count(Startup_Name) as Accepted from sharktank where Accepted_Offer='Yes' group by Season_Number) c 
on b.Season_Number=c.Season_Number;

/* As a venture capital firm specializing in investing in startups featured on a renowned entrepreneurship TV show, how would you determine the season with the
startups with highest average monthly sales and identify the top 5 industries with the highest average monthly sales during that season to optimize investment decisions?*/

set @seas= (select Season_Number from (
select Season_Number, round(avg(Monthly_Sales_in_lakhs),2) avrg from sharktank group by Season_Number order by avrg desc limit 1) a);

select Industry, round(avg(Monthly_Sales_in_lakhs),2) avrg from sharktank where Season_Number=@seas group by Industry order by avrg desc limit 5;

/* As a data scientist at our firm, your role involves solving real-world challenges like identifying industries with consistent increases in funds raised over 
multiple seasons. This requires focusing on industries where data is available across all three years.
 Once these industries are pinpointed, your task is to delve into the specifics, analyzing the number of pitches made, offers received, and offers 
-- converted per season within each industry. */

with cte as (select Industry,
max(case when Season_Number=1 then Total_Deal_Amount_in_lakhs end) as S1,
max(case when Season_Number=2 then Total_Deal_Amount_in_lakhs end) as S2,
max(case when Season_Number=3 then Total_Deal_Amount_in_lakhs end) as S3 from sharktank 
group by Industry having S2>S1 and S3>S2 and S1 != 0)
select s.Industry,s.Season_Number, count(s.Startup_Name) as total, 
count(case when s.Received_Offer="Yes" then s.Startup_Name end) as Received,
count(case when s.Accepted_Offer="Yes" then s.Startup_Name end) as Accepted 
from cte c inner join sharktank s on c.Industry=s.Industry
group by s.Industry, s.Season_Number
order by s.Industry;

/* Every shark want to  know in how much year their investment will be returned, so you have to create a system for them , where shark will enter the name of the 
startup's  and the based on the total deal and quity given in how many years their principal amount will be returned. */
select * from sharktank;

Delimiter \\
create procedure TOT(in startup varchar(255))
begin
	case when (select Accepted_Offer="No" from sharktank where Startup_Name=startup)
		then select "TOT cannot be calculated as offer wasn't accepted";
		when (select Accepted_Offer="Yes" and Yearly_Revenue_in_lakhs="Not Mentioned" from sharktank where Startup_Name=startup)
		then select "TOT cannot be calculated due to insufficient data";
	else
		select `Startup_Name`,`Yearly_Revenue_in_lakhs`, `Total_Deal_Amount_in_lakhs`, `Total_Deal_Equity_%`,
        `Total_Deal_Amount_in_lakhs`/(`Total_Deal_Equity_%`*100)*`Yearly_Revenue_in_lakhs` as Years_to_return from sharktank
        where Startup_Name=startup;
	end case;
end \\
Delimiter ;

call TOT('BluePineFoods');

/* In the world of startup investing, we're curious to know which big-name investor, often referred to as "sharks," tends to put the most money into each
deal on average. This comparison helps us see who's the most generous with their investments and how they measure up against their fellow investors*/


select Shark, round(avg(investment),2) as Avrg_in_lakhs from (
select `Namita_Investment_Amount_in_lakhs` as investment, 'Namita' as Shark from sharktank where Namita_Investment_Amount_in_lakhs>0
union all
select `Vineeta_Investment_Amount_in_lakhs` as investment, 'Vineeta' as Shark from sharktank where Vineeta_Investment_Amount_in_lakhs>0
union all
select `Anupam_Investment_Amount_in_lakhs` as investment, 'Anupam' as Shark from sharktank where Anupam_Investment_Amount_in_lakhs>0
union all
select `Aman_Investment_Amount_in_lakhs` as investment, 'Aman' as Shark from sharktank where Aman_Investment_Amount_in_lakhs>0
union all
select `Peyush_Investment_Amount__in_lakhs` as investment, 'Peyush' as Shark from sharktank where Peyush_Investment_Amount__in_lakhs>0
union all
select `Amit_Investment_Amount_in_lakhs` as investment, 'Amit' as Shark from sharktank where Amit_Investment_Amount_in_lakhs>0
union all
select `Ashneer_Investment_Amount` as investment, 'Ashneer' as Shark from sharktank where Ashneer_Investment_Amount>0) k
group by Shark;

/* Develop a system that accepts inputs for the season number and the name of a shark. The procedure will then provide detailed insights into the total investment made by 
-- that specific shark across different industries during the specified season. Additionally, it will calculate the percentage of their investment in each sector relative to
-- the total investment in that year, giving a comprehensive understanding of the shark's investment distribution and impact. */
delimiter //
create procedure getseason(in season int, in sname varchar(255))
begin
	case
			when sname="Namita" then
            set @tot=(select sum(`Namita_Investment_Amount_in_lakhs`) from sharktank where Season_Number=season);
            select Industry, sum(`Namita_Investment_Amount_in_lakhs`) as total,(sum(`Namita_Investment_Amount_in_lakhs`)/@tot)*100 as perc from sharktank where Season_Number=season and `Namita_Investment_Amount_in_lakhs`>0
            group by Industry;
            when sname="Vineeta" then
            set @tot=(select sum(`Vineeta_Investment_Amount_in_lakhs`) from sharktank where Season_Number=season);
            select Industry, sum(`Vineeta_Investment_Amount_in_lakhs`) as total, (sum(`Vineeta_Investment_Amount_in_lakhs`)/@tot)*100 as perc from sharktank where Season_Number=season and `Vineeta_Investment_Amount_in_lakhs`>0
            group by Industry;
            when sname="Anupam" then
            set @tot=(select sum(`Anupam_Investment_Amount_in_lakhs`) from sharktank where Season_Number=season);
            select Industry, sum(`Anupam_Investment_Amount_in_lakhs`) as total, (sum(`Anupam_Investment_Amount_in_lakhs`)/@tot)*100 as perc from sharktank where Season_Number=season and `Anupam_Investment_Amount_in_lakhs`>0
            group by Industry;
            when sname="Aman" then
            set @tot=(select sum(`Aman_Investment_Amount_in_lakhs`) from sharktank where Season_Number=season);
            select Industry, sum(`Aman_Investment_Amount_in_lakhs`) as total, (sum(`Aman_Investment_Amount_in_lakhs`)/@tot)*100 as perc from sharktank where Season_Number=season and `Aman_Investment_Amount_in_lakhs`>0
            group by Industry;
            when sname="Peyush" then
            set @tot=(select sum(`Peyush_Investment_Amount__in_lakhs`) from sharktank where Season_Number=season);
            select Industry, sum(`Peyush_Investment_Amount__in_lakhs`) as total, (sum(`Peyush_Investment_Amount__in_lakhs`)/@tot)*100 as perc from sharktank where Season_Number=season and `Peyush_Investment_Amount__in_lakhs`>0
            group by Industry;
            when sname="Amit" then
            set @tot=(select sum(`Amit_Investment_Amount_in_lakhs`) from sharktank where Season_Number=season);
            select Industry, sum(`Amit_Investment_Amount_in_lakhs`) as total, (sum(`Amit_Investment_Amount_in_lakhs`)/@tot)*100 as perc from sharktank where Season_Number=season and `Amit_Investment_Amount_in_lakhs`>0
            group by Industry;
            when sname="Ashneer" then
            set @tot=(select sum(`Ashneer_Investment_Amount`) from sharktank where Season_Number=season);
            select Industry, sum(`Ashneer_Investment_Amount`) as total, (sum(`Ashneer_Investment_Amount`)/@tot)*100 as perc from sharktank where Season_Number=season and `Ashneer_Investment_Amount`>0
            group by Industry;
            else 
            select "This is incorrect input";
    end case ;
end // 

call getseason(2, 'Anupam');