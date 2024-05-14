use campusx;
show tables;
truncate table playstore;
select * from playstore limit 5;

/*Used inline data loading because of encoding issues, csv was unable to get uploaded here using table wizard*/

load data infile "C:/Users/simra/Downloads/playstore.csv"
into table playstore
fields terminated by ','
optionally enclosed by '"'
lines terminated by '\r\n'
ignore 1 rows;

/* 1.You're working as a market analyst for a mobile app development company. Your task is to identify the most promising categories(TOP 5) for 
 launching new free apps based on their average ratings. */
 
 select Category, round(avg(Rating),2) as average from playstore where Type='Free' group by Category order by average desc limit 5;
 
/* 2. As a business strategist for a mobile app company, your objective is to pinpoint the three categories that generate the most revenue from paid apps.
 This calculation is based on the product of the app price and its number of installations. */
 
 select Category, avg(Installs*Price) as Revenue from playstore where Type = 'Paid' group by Category order by Revenue desc limit 3;
 
/* 3. As a data analyst for a gaming company, you're tasked with calculating the percentage of apps within each game category. 
-- This information will help the company understand the distribution of gaming apps across different categories. */

with cte as (select Category, count(App) as cnt from playstore group by Category)
select *, (cnt*100/(select count(*) from playstore)) as percentage from cte;

/* 4. As a data analyst at a mobile app-focused market research firm, 
you'll recommend whether the company should develop paid or free apps for each category based on the  ratings of that category. */
with cte as (
select Category,
max(case when Type='Free' Then average end) as Free,
max(case when Type='Paid' Then average end) as Paid
from (
Select Category, Type, round(avg(Rating),2) as average from playstore group by Category, Type order by Category, Type) C 
group by Category
)
select *, if(Free>Paid,'Free','Paid') as Develop from cte;

/* 5.Suppose you're a database administrator, your databases have been hacked  and hackers are changing price of certain apps on the database , its taking long for IT team to 
neutralize the hack , however you as a responsible manager  dont want your data to be changed , do some measure where the changes in price can be recorded as you cant 
stop hackers from making changes */

create table price_change(
app varchar(255),
old_price decimal(10,2),
new_price decimal(10,2),
operation_type varchar(30),
op_date timestamp);

create table play as select * from playstore; #copy of playstore

DELIMITER //
create trigger price_change_log
after update 
on play
for each row
begin
	insert into price_change (app, old_price, new_price, operation_type, op_date)
    values (new.app, old.price, new.price, 'update', current_timestamp);
end ;
// DELIMITER ;

SELECT * FROM price_change;

set sql_safe_updates= 0;

UPDATE PLAY
SET PRICE= 4
WHERE APP='Infinite Painter';

/* 6. your IT team have neutralize the threat,  however hacker have made some changes in the prices, but becasue of your measure you have noted the changes , now you want
correct data to be inserted into the database. */

select * from play p inner join price_change pc on p.app=pc.app;
drop trigger price_change_log;

update play as p
inner join price_change as pc on p.app=pc.app
set p.price= pc.old_price;

/* 7. As a data person you are assigned the task to investigate the 
correlation between two numeric factors: app ratings and the quantity of reviews. */

set @x= (select round(avg(rating),2) from playstore);
set @y= (select round(avg(reviews),2) from playstore);

with cte as (
select *, rat*rat as sqrrat, rev*rev as sqrrev from (
select rating, @x, round(rating-@x,2) as rat, reviews, @y, round(reviews-@y,2) as rev from playstore) sq
)
select @numerator:= sum(rat*rev),
@deno1:= sum(sqrrat),
@deno2:= sum(sqrrev)
from cte;

select round(@numerator/sqrt(@deno1*@deno2),5) as corr_coeff;

/* 8. Your boss noticed  that some rows in genres columns have multiple generes in them, which was creating issue when developing the  recommendor system from the data
he/she asssigned you the task to clean the genres column and make two genres out of it, rows that have only one genre will have other column as blank. */

Delimiter //
create function f_name(a varchar(255))
returns varchar(255)
deterministic
begin
	set @l = locate(';',a);
    set @s = if(@l>0, left(a, @l-1),a);
    return @s;
end //
Delimiter ;

Delimiter //
create function l_name(a varchar(255))
returns varchar(255)
deterministic
begin
	set @l = locate(';',a);
    set @s = if(@l=0, ' ', substring(a,@l+1,length(a)));
    return @s;
end // 
Delimiter ;

SELECT l_name('Art & Design;Pretend Play') AS first_part;
select genres, f_name(genres) as first_name, l_name(genres) as last_name from playstore;



