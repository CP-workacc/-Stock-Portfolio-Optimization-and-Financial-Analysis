/*
 ISDS 570 Group T1 - SQL Database Creation Code

*/

-------------------------------------------
-- Step 1: Create a database "stockmarket" 
-------------------------------------------

----------------------------------------------------------
-- Step 2: Import EOD (End of Day) Quotes ---------
----------------------------------------------------------
-- Create table eod_quotes
-- NOTE: ticker and date will be the PK; volume numeric, and other numbers real (4 bytes)

/*
-- LIFELINE
-- DROP TABLE public.eod_quotes;

CREATE TABLE public.eod_quotes
(
    ticker character varying(16) COLLATE pg_catalog."default" NOT NULL,
    date date NOT NULL,
    adj_open real,
    adj_high real,
    adj_low real,
    adj_close real,
    adj_volume numeric,
    CONSTRAINT eod_quotes_pkey PRIMARY KEY (ticker, date)
)
WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;

ALTER TABLE public.eod_quotes
    OWNER to postgres;
*/

-- Import eod.csv to the table - it will take some time (approx. 17 million rows)

-- Checks
SELECT * FROM eod_quotes LIMIT 10;
SELECT COUNT(*) FROM eod_quotes; 

--------------------------------------------------------------------
-- Step 3: Import 2016-2021(March) SP500TR data from Yahoo ---------
--------------------------------------------------------------------

-- Navigate to Yahoo's historical data website: https://finance.yahoo.com/quote/%5ESP500TR/history?p=^SP500TR
-- Set dates to 2016-01-01 and 2021-03-26, copy and paste data to an excel
-- Save that excel as "SP500TR_PROJECT"
-- Create table to store data and then import it

/*

LIFELINE:

-- DROP TABLE public.eod_indices;

CREATE TABLE public.eod_indices
(
    symbol character varying(16) COLLATE pg_catalog."default" NOT NULL,
    date date NOT NULL,
    open real,
    high real,
    low real,
    close real,
    adj_close real,
    volume double precision,
    CONSTRAINT eod_indices_pkey PRIMARY KEY (symbol, date)
)
WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;

ALTER TABLE public.eod_indices
    OWNER to postgres;

*/

-- Check
SELECT * FROM eod_indices LIMIT 10;

------------------------------------------------------------
-- Step 4: Prepare a custom calendar (using Excel) ---------
------------------------------------------------------------
-- Use the professor's custom calendar excel sheet available
-- Modify this excel to start on 2016-01-01 and end on 2021-03-26
-- Modify excel so that the three market holidays of New Year's Day (1/1/21), MLK Jr Day (1/18/21), and President's Day (2/15/21) are captured
-- Import this modified custom_calendar.csv to a new table

/*
LIFELINE:
-- DROP TABLE public.custom_calendar;

CREATE TABLE public.custom_calendar
(
    date date NOT NULL,
    y integer,
    m integer,
    d integer,
    dow character varying(3) COLLATE pg_catalog."default",
    trading smallint,
    CONSTRAINT custom_calendar_pkey PRIMARY KEY (date)
)
WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;

ALTER TABLE public.custom_calendar
    OWNER to postgres;

*/

-- CHECK:
SELECT * FROM custom_calendar LIMIT 10;

--Add columns for later returns analysis: eom (end-of-month) and prev_trading_day

/*
-- LIFELINE
ALTER TABLE public.custom_calendar
    ADD COLUMN eom smallint;

ALTER TABLE public.custom_calendar
    ADD COLUMN prev_trading_day date;
*/

-- CHECK:
SELECT * FROM custom_calendar LIMIT 10;

-- After creating table - import csv file into table

--Identify trading days
SELECT * FROM custom_calendar WHERE trading=1;
-- Identify previous trading days via a nested query
SELECT date, (SELECT MAX(CC.date) FROM custom_calendar CC 
			  WHERE CC.trading=1 AND CC.date<custom_calendar.date) ptd 
			  FROM custom_calendar
			  ORDER BY date;
			  
-- Update the table with new data 
UPDATE custom_calendar
SET prev_trading_day = PTD.ptd
FROM (SELECT date, (SELECT MAX(CC.date) FROM custom_calendar CC WHERE CC.trading=1 AND CC.date<custom_calendar.date) ptd FROM custom_calendar) PTD
WHERE custom_calendar.date = PTD.date;

-- CHECK
SELECT * FROM custom_calendar ORDER BY date;

-- Add the last trading day of 2015 (as the end of the month)
INSERT INTO custom_calendar VALUES('2015-12-31',2015,12,31,'Thu',1,1,NULL);

-- Re-run the update
-- CHECK again
SELECT * FROM custom_calendar ORDER BY date;

-- Identify the end of the month
SELECT CC.date,CASE WHEN EOM.y IS NULL THEN 0 ELSE 1 END endofm FROM custom_calendar CC LEFT JOIN
(SELECT y,m,MAX(d) lastd FROM custom_calendar WHERE trading=1 GROUP by y,m) EOM
ON CC.y=EOM.y AND CC.m=EOM.m AND CC.d=EOM.lastd;

-- Update the table with new data
UPDATE custom_calendar
SET eom = EOMI.endofm
FROM (SELECT CC.date,CASE WHEN EOM.y IS NULL THEN 0 ELSE 1 END endofm FROM custom_calendar CC LEFT JOIN
(SELECT y,m,MAX(d) lastd FROM custom_calendar WHERE trading=1 GROUP by y,m) EOM
ON CC.y=EOM.y AND CC.m=EOM.m AND CC.d=EOM.lastd) EOMI
WHERE custom_calendar.date = EOMI.date;

-- CHECK
SELECT * FROM custom_calendar ORDER BY date;
SELECT * FROM custom_calendar WHERE eom=1 ORDER BY date;

----------------------------------------------
-- Step 5: Prepare roles for database  -------
----------------------------------------------
-- rolename: stockmarketreader
-- password: read123

/*
-- LIFELINE:
-- REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM stockmarketreader;
-- DROP USER stockmarketreader;

CREATE USER stockmarketreader WITH
	LOGIN
	NOSUPERUSER
	NOCREATEDB
	NOCREATEROLE
	INHERIT
	NOREPLICATION
	CONNECTION LIMIT -1
	PASSWORD 'read123';
*/

-- Grant read rights (on existing tables and views)
GRANT SELECT ON ALL TABLES IN SCHEMA public TO stockmarketreader;

-- Grant read rights (for future tables and views)
ALTER DEFAULT PRIVILEGES IN SCHEMA public
   GRANT SELECT ON TABLES TO stockmarketreader;

-----------------------------------
-- End of Database Portion  -------
-----------------------------------






