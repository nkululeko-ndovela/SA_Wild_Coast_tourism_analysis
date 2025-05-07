-- create Stored Procedure: clean_and_prepare_tourism_data()
-- This procedure:

-- Removes duplicates

-- Formats fields (trims and proper cases)

-- Converts travel_date to DATE format

-- Updates nulls and standardizes key values

CREATE OR REPLACE PROCEDURE clean_and_prepare_tourism_data()
LANGUAGE plpgsql
AS $$
BEGIN
  --Remove duplicates by keeping the first entry per ID
  DELETE FROM tourism_data a
  USING (
    SELECT MIN(ctid) AS keep_ctid, id
    FROM tourism_data
    GROUP BY id
    HAVING COUNT(*) > 1
  ) b
  WHERE a.id = b.id AND a.ctid <> b.keep_ctid;

  --Normalize string fields
  UPDATE tourism_data
  SET
    place_of_origin = INITCAP(TRIM(place_of_origin)),
    travel_agent = INITCAP(TRIM(travel_agent)),
    visited_places = INITCAP(TRIM(visited_places)),
    transport_mode = INITCAP(TRIM(transport_mode)),
    payment_method = INITCAP(TRIM(payment_method));

  --Format travel_date to date type if stored as text
  ALTER TABLE tourism_data
  ALTER COLUMN travel_date TYPE DATE
  USING travel_date::date;

  --Standardize text fields
  UPDATE tourism_data
  SET
    crime_report = CASE
      WHEN LOWER(crime_report) IN ('yes', 'y') THEN 'Yes'
      ELSE 'No'
    END;

  RAISE NOTICE 'Tourism data cleaned and prepared successfully.';
END;
$$;

-- Materialized View: tourism_summary_view
-- This view gives quick access to:

-- Total tourists

-- Revenue summaries

-- Booking stats by origin, agent, date, and transport

CREATE MATERIALIZED VIEW tourism_summary_view AS
SELECT
  travel_date,
  quarter,
  place_of_origin,
  travel_agent,
  visited_places,
  transport_mode,
  COUNT(*) AS total_bookings,
  SUM(tourists_per_booking) AS total_tourists,
  ROUND(AVG(total_cost), 2) AS avg_booking_cost,
  SUM(total_cost) AS total_revenue,
  SUM(CASE WHEN crime_report = 'Yes' THEN 1 ELSE 0 END) AS crime_cases
FROM tourism_data
GROUP BY travel_date, quarter, place_of_origin, travel_agent, visited_places, transport_mode;

--Run the procedure before refreshing the view:

CALL clean_and_prepare_tourism_data();
REFRESH MATERIALIZED VIEW tourism_summary_view;
