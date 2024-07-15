create database music_database;
use music_database;

-- comment for Rename table because album csv not in correct format

Rename table album2 to album;

-- Question and Answers
-- Easy
-- Q1: Who is the senior most employee based on job title? 

select * from employee;-- highest level is most senior get that person with minimum id who has highest level
select title,first_name,last_name from employee order by levels desc limit 1;

--  Q2: Which countries have the most Invoices? 
select * from invoice;
select billing_country as "Country" from invoice group by billing_country order by count(invoice_id) desc limit 1;

-- Q3: What are top 3 values of total invoice?
select * from invoice;
select * from invoice order by total desc limit 3;
-- To show all in top 3 instead of just 3 invoices
Select invoice_id,customer_id,invoice_date,billing_address,billing_city,billing_country,billing_postal_code,total from 
(select * , dense_rank() over(order by total desc) as Ranking from invoice ) as T1 where Ranking<4;

/* Q4: Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. 
Write a query that returns one city that has the highest sum of invoice totals. 
Return both the city name & sum of all invoice totals
*/
select * from invoice;
select billing_city,sum(total) as Total_Invoices from invoice group by billing_city order by Total_Invoices desc limit 1;

/*Q5: Who is the best customer? The customer who has spent the most money will be declared the best customer. 
Write a query that returns the person who has spent the most money.
*/
select * from customer;
-- method 1
select concat(c.first_name," ",c.last_name) as "Customer_Name",sum(total) as Total_Invoices from invoice i inner join customer c on i.customer_id=c.customer_id group by 1 order by Total_Invoices desc limit 1 ;

-- method 2
select concat(max(b.first_name)," ",max(b.last_name)) as Full_Name,sum(a.total) as Total_Invoices  from invoice as a inner join customer as b on a.customer_id=b.customer_id
group by a.customer_id order by Total_Invoices desc limit 1 ;

-- Moderate
/* Q1: Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
Return your list ordered alphabetically by email starting with A. */
-- See Schema connection and know that 5 tables connected
select * from genre;
select distinct(a.email),concat(a.first_name,a.last_name) as "Full_Name",e.name from customer as a
 inner join invoice as b on a.customer_id=b.customer_id 
 inner join invoice_line as c on b.invoice_id=c.invoice_id 
 inner join track as d on c.track_id=d.track_id 
 inner join genre as e on d.genre_id=e.genre_id 
 where e.name="Rock" order by a.email;

/* Q2: Let's invite the artists who have written the most rock music in our dataset. 
Write a query that returns the Artist name and total track count of the top 10 rock bands. */
select * from artist;
select artist_id , count(track_id) as counting from Track order by counting desc;
-- run this 
select max(a.name) as Name , count(track_id) as Total_tracks from artist a 
inner join album al on a.artist_id=al.artist_id
inner join track t on al.album_id=t.album_id
inner join genre g on t.genre_id=g.genre_id where g.name like "Rock"
group by a.artist_id order by Total_tracks desc limit 10;

/* Q3: Return all the track names that have a song length longer than the average song length. 
Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first. */

select name,milliseconds as "Song_Length" from track where milliseconds > (Select avg(milliseconds) from track )order by milliseconds desc;

-- Advance 

/* Q1: Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent but only for best selling artist*/
with cte as (
select a.name,a.artist_id,sum(il.unit_price*il.quantity) as Total_Price from artist a 
inner join album al on a.artist_id=al.artist_id
inner join track t on al.album_id=t.album_id
inner join invoice_line il on t.track_id=il.track_id
group by 1,2 order by Total_Price desc
limit 1
)-- gets that best selling artist 
select c.first_name as Customer_Name,cte.name as Artist_Name,sum(il.unit_price*il.quantity) as Total_Value from
customer c inner join invoice i on i.customer_id=c.customer_id 
inner join invoice_line il on il.invoice_id=i.invoice_id
inner join track t on t.track_id=il.track_id
inner join album al on al.album_id=t.album_id
inner join cte on al.artist_id=cte.artist_id 
group by 1,2
order by Total_Value desc;-- get customer wise money for that best selling artist

/* Q2: We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre 
with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where 
the maximum number of purchases is shared return all Genres. */
-- method 1 using view
create or replace view cte as(select c.country,g.name as Genre_Name,count(il.quantity) as Total_Tracks from customer c 
inner join invoice i on c.customer_id=i.customer_id 
inner join invoice_line il on il.invoice_id=i.invoice_id
inner join track t on t.track_id =il.track_id
inner join genre g on g.genre_id=t.genre_id
group by 1,2);
select country,Genre_Name,Total_Tracks from (select *,dense_rank() over(partition by cte.country order by cte.Total_tracks desc) as Ranking from cte) as New_cte where Ranking=1 ;
-- method 2 using CTE
with ct as(select c.country,g.name as Genre_Name,count(il.quantity) as Total_Tracks ,dense_rank() over(partition by c.country order by count(il.quantity) desc) as Ranking
from customer c 
inner join invoice i on c.customer_id=i.customer_id 
inner join invoice_line il on il.invoice_id=i.invoice_id
inner join track t on t.track_id =il.track_id
inner join genre g on g.genre_id=t.genre_id
group by 1,2)
select country,Genre_Name,Total_Tracks from ct where Ranking=1 ;


/* Q3: Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount. */
with cvt as (
select c.country,c.first_name as Name , sum(il.unit_price*il.quantity) as Total_Price ,dense_rank() over(partition by c.country order by sum(il.unit_price*il.quantity) desc)as Ranking 
from customer c 
inner join invoice i on c.customer_id=i.customer_id
inner join invoice_line il on i.invoice_id=il.invoice_id
group by 1,2
)
select country,Name,round(Total_Price,2) as Total from cvt where Ranking=1;
