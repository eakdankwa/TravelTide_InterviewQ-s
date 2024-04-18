/*
Question #1:
Calculate the number of flights with a departure time during the work week (Monday through Friday) and the number of flights departing during the weekend (Saturday or Sunday).

Expected column names: working_cnt, weekend_cnt
*/

-- q1 solution:
SELECT 
  CASE WHEN EXTRACT(DOW FROM departure_time::date) BETWEEN 1 AND 5 THEN 'working_cnt'
  WHEN (EXTRACT(DOW FROM departure_time::date) = 0) OR (EXTRACT(DOW FROM departure_time::date)) = 6 THEN 'weekend_cnt'
  END AS count_per_weekday,
COUNT(trip_id) AS no_of_departed_flights
 
FROM flights
GROUP BY 1;


/*

Question #2: 
For users that have booked at least 2  trips with a hotel discount, it is possible to calculate their average hotel discount, and maximum hotel discount. write a solution to find users whose maximum hotel discount is strictly greater than the max average discount across all users.

Expected column names: user_id

*/

-- q2 solution:

SELECT  user_id
	FROM(
      SELECT  user_id,
    	MAX(hotel_discount_amount) AS max_hotel_discount
    FROM sessions 
     	WHERE (hotel_discount_amount IS NOT NULL)  and (trip_id IS NOT NULL) 
          AND (hotel_discount is true) AND (cancellation = false)
     GROUP BY user_id
     HAVING COUNT( trip_id) >= 2
  		)AS subgroup
WHERE max_hotel_discount > 
		 (
	SELECT MAX(avg_discount)
  FROM (
     SELECT user_id,
    	AVG(hotel_discount_amount) AS avg_discount
		  FROM sessions
     	WHERE (hotel_discount_amount IS NOT NULL)  and (trip_id IS NOT NULL) 
          AND (hotel_discount is true) AND (cancellation = false)
     GROUP BY user_id
  	HAVING COUNT(trip_id) >= 2
     ) AS avg_subquery 
);

/*
Question #3: 
when a customer passes through an airport we count this as one “service”.

for example:

suppose a group of 3 people book a flight from LAX to SFO with return flights. In this case the number of services for each airport is as follows:

3 services when the travelers depart from LAX

3 services when they arrive at SFO

3 services when they depart from SFO

3 services when they arrive home at LAX

for a total of 6 services each for LAX and SFO.

find the airport with the most services.

Expected column names: airport

*/

-- q3 solution:

WITH airport_table AS (
  SELECT origin_airport AS airports, 
  COUNT(trip_id) AS service 
  FROM flights WHERE departure_time IS NOT NULL  
  GROUP BY 1 
	UNION ALL
	SELECT destination_airport AS airports, 
  COUNT(trip_id) AS service 
  FROM flights 
  WHERE departure_time IS NOT NULL AND (trip_id)IS NOT NULL
  GROUP BY 1
)
SELECT airports
FROM airport_table
GROUP BY 1
ORDER BY (SUM(service)) DESC
LIMIT 1
;

/*
Question #4: 
using the definition of “services” provided in the previous question, we will now rank airports by total number of services. 

write a solution to report the rank of each airport as a percentage, where the rank as a percentage is computed using the following formula: 

`percent_rank = (airport_rank - 1) * 100 / (the_number_of_airports - 1)`

The percent rank should be rounded to 1 decimal place. airport rank is ascending, such that the airport with the least services is rank 1. If two airports have the same number of services, they also get the same rank.

Return by ascending order of rank

E**xpected column names: airport, percent_rank**

Expected column names: airport, percent_rank
*/

-- q4 solution:
WITH airport_table AS (
  SELECT DISTINCT origin_airport AS airports, 
  COUNT(DISTINCT trip_id) AS service 
  FROM flights WHERE departure_time IS NOT NULL  
  GROUP BY 1 
  HAVING COUNT(trip_id) IS NOT NULL
	UNION ALL
	SELECT destination_airport AS airports, 
  COUNT(trip_id) AS service 
  FROM flights 
  WHERE departure_time IS NOT NULL AND (trip_id)IS NOT NULL 
  GROUP BY 1
)

select airports,
--RANK() OVER(ORDER BY SUM(service) ASC) AS airport_rank,
ROUND((RANK() OVER( ORDER BY SUM(service) ASC) - 1)*100.0/(Count(*) OVER() -1 ), 1) AS percentage_rank
 FROM airport_table 
  GROUP BY 1
;



