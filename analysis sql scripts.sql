 --1. Remove Duplicates Based on All Columns

DELETE FROM tourism_data a
USING (
  SELECT MIN(ctid) AS ctid_keep, id
  FROM tourism_data
  GROUP BY id
  HAVING COUNT(*) > 1
) b
WHERE a.id = b.id AND a.ctid <> b.ctid_keep;

--2. Normalize Text Fields (Trim & Proper Case)

UPDATE tourism_data
SET
  place_of_origin = INITCAP(TRIM(place_of_origin)),
  visited_places = INITCAP(TRIM(visited_places)),
  transport_mode = INITCAP(TRIM(transport_mode)),
  travel_agent = INITCAP(TRIM(travel_agent));
--3. Format and Convert Travel Date Properly

ALTER TABLE tourism_data
ALTER COLUMN travel_date TYPE DATE
USING travel_date::date;

--4. Summary of Tourists, Bookings, and Revenue
SELECT
  COUNT(*) AS total_bookings,
  SUM(tourists_per_booking) AS total_tourists,
  ROUND(AVG(total_cost), 2) AS avg_total_cost,
  SUM(total_cost) AS total_revenue
FROM tourism_data;

--Booking Trend Over Time (With Cumulative Spend)

SELECT
  travel_date,
  COUNT(*) AS bookings,
  SUM(total_cost) AS daily_revenue,
  SUM(SUM(total_cost)) OVER (ORDER BY travel_date) AS cumulative_revenue
FROM tourism_data
GROUP BY travel_date
ORDER BY travel_date;

-- 6. Top Origins and Their Spending

SELECT
  place_of_origin,
  COUNT(*) AS total_visits,
  SUM(total_cost) AS total_spent,
  ROUND(AVG(total_cost), 2) AS avg_cost
FROM tourism_data
GROUP BY place_of_origin
ORDER BY total_spent DESC
LIMIT 5;

--7. Agent Performance Report

SELECT
  travel_agent,
  COUNT(*) AS bookings_handled,
  ROUND(SUM(total_cost), 2) AS total_revenue,
  ROUND(AVG(total_cost), 2) AS avg_booking_value
FROM tourism_data
GROUP BY travel_agent
ORDER BY total_revenue DESC;

--8. Crime-Reported Analysis

SELECT
  visited_places,
  COUNT(*) AS total_visits,
  SUM(CASE WHEN crime_report ILIKE 'Yes' THEN 1 ELSE 0 END) AS crime_incidents
FROM tourism_data
GROUP BY visited_places
ORDER BY crime_incidents DESC;

-- 9. Payment Method Usage Breakdown

SELECT
  payment_method,
  COUNT(*) AS usage_count,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS usage_percent
FROM tourism_data
GROUP BY payment_method
ORDER BY usage_count DESC;

--10. Trip Cost Breakdown in JSON Format

SELECT
  id,
  jsonb_build_object(
    'food', food_cost,
    'guide', guide_cost,
    'accommodation', accommodation_cost,
    'total', total_cost
  ) AS cost_summary
FROM tourism_data;

--11. Weekly Booking Patterns

SELECT 
  TO_CHAR(travel_date, 'Day') AS weekday,
  COUNT(*) AS bookings
FROM tourism_data
GROUP BY weekday
ORDER BY bookings DESC;

--12. Highest Cost Trip Details

SELECT *
FROM tourism_data
ORDER BY total_cost DESC
LIMIT 1;