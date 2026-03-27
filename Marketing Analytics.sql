-- Categorize products based on their price
select * from dbo.products 
select ProductID, ProductName, Price,
	case
		when Price < 50 then 'Low'
		when Price between 50 and 200 then 'Medium'
		else 'High'
	end as PriceCategory
from dbo.products

-- Join dim_customers with dim_geography to enrich customer data with geographic information
select * from dbo.customers
select * from dbo.geography
select c.CustomerID, c.CustomerName, c.Email, c.Gender, c.Age, g.Country, g.City
from dbo.customers as c
left join 
	dbo.geography g
on
c.GeographyID = g.GeographyID

-- Clean whitespace issues in the ReviewText colunm
select * from dbo.customer_reviews
select ReviewID, CustomerID, ProductID, ReviewDate, Rating,
	replace(ReviewText, '  ', ' ') as ReviewText
from dbo.customer_reviews

-- Clean and normalize the engage_data table: formating the ContentType column, EngagementData column, extract Views from ViewsClicksCombined column
select * from dbo.engagement_data
select EngagementID, ContentID, CampaignID, ProductID,
	upper(replace(ContentType, 'Socialmedia', 'Social Media')) as ContentType,
	format(convert(date, EngagementDate), 'dd.MM.yyyy') as EngagementDate,
	left(ViewsClicksCombined,charindex('-', ViewsClicksCombined)-1) as Views,
	right(ViewsClicksCombined,len(ViewsClicksCombined)-charindex('-', ViewsClicksCombined)) as Clicks,
	Likes
from dbo.engagement_data
where 
	ContentType != 'Newsletter'

-- Remove duplicate row and replace the null value
select * from dbo.customer_journey;
with DuplicateRecords as (
	select JourneyID, CustomerID, ProductID, VisitDate, Stage, Action, Duration,
		row_number() over (
		partition by CustomerID, ProductID, VisitDate, Stage, Action
		order by JourneyID ) as row_num
	from dbo.customer_journey )
select * from DuplicateRecords
where row_num >1
order by JourneyID

select JourneyID, CustomerID, ProductID, VisitDate, Stage, Action, Coalesce(Duration,avg_duration) as Duration
from
	(
		select
			 JourneyID, CustomerID, ProductID, VisitDate, 
			 upper(Stage) as Stage,
			 Action,
			 Duration,
			 avg(Duration) over (partition by VisitDate) as avg_duration,
			 row_number() over (partition by  CustomerID, ProductID, VisitDate, upper(Stage), Action
			 order by JourneyID) as row_num
		from
			dbo.customer_journey) as subquery
where row_num = 1
order by VisitDate
