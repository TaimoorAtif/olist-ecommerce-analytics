
											"RAW Table Creation Stage"

-----------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------

										-- Creation of Raw Tables --

CREATE TABLE public."RAW - Customer"
	(
	customer_id TEXT,
	customer_unique_id TEXT,
	customer_zip_code_prefix TEXT,
	customer_city TEXT,
	customer_state TEXT
	);

CREATE TABLE public."RAW - Geolocation"
	(
	geolocation_zip_code_prefix TEXT,
	geolocation_lat TEXT,
	geolocation_lng TEXT,
	geolocation_city TEXT,
	geolocation_state TEXT
	);

CREATE TABLE public."RAW - Order Items"
	(
	order_id TEXT,
	order_item_id TEXT,
	product_id TEXT,
	seller_id TEXT,
	shipping_limit_date TEXT,
	price TEXT,
	freight_value TEXT
	);

CREATE TABLE public."RAW - Payments"
	(
	order_id TEXT,
	payment_sequential TEXT,
	payment_type TEXT,
	payment_installments TEXT,
	payment_value TEXT
	);

CREATE TABLE public."RAW - Reviews"
	(
	review_id TEXT,
	order_id TEXT,
	review_score TEXT,
	review_comment_title TEXT,
	review_comment_message TEXT,
	review_creation_date TEXT,
	review_answer_timestamp TEXT
	);

CREATE TABLE public."RAW - Orders"
	(
	order_id TEXT,
	customer_id TEXT,
	order_status TEXT,
	order_purchase_timestamp TEXT,
	order_approved_at TEXT,
	order_delivered_carrier_date TEXT,
	order_delivered_customer_date TEXT,
	order_estimated_delivery_date TEXT
	);

CREATE TABLE public."RAW - Products"
	(
	product_id TEXT,
	product_category_name TEXT,
	product_name_length TEXT,
	product_description_length TEXT,
	product_photos_qty TEXT,
	product_weight_g TEXT,
	product_length_cm TEXT,
	product_height_cm TEXT,
	product_width_cm TEXT
	);

CREATE TABLE public."RAW - Sellers"
	(
	seller_id TEXT,
	seller_zip_code_prefix TEXT,
	seller_city TEXT,
	seller_state TEXT
	);

CREATE TABLE public."RAW - Product Category Name Translation"
	(
	product_category_name TEXT,
	product_category_name_english TEXT
	);

-----------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------




											"VALIDATION STAGE"




------------------------------------------------------------------------------------------------------------------------------------------------

										-- Customer Table Validation --

-- Checking total rows

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Customer";

-- Checking for duplicate rows

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Customer"
GROUP BY
	customer_id,
	customer_unique_id,
	customer_zip_code_prefix,
	customer_city,
	customer_state
					HAVING
							COUNT(*) > 1;

-- Checking customer_id if UNIQUE 

SELECT
	COUNT(customer_id)
FROM
	"RAW"."RAW - Customer"
GROUP BY
	customer_id
				HAVING
						COUNT(customer_id) > 1

-- Are any customer_id values NULL or blank

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Customer"
WHERE
	customer_id IS NULL
	OR
	customer_id = '';

-- Do any customer_unique_id values occur more than once (signal to orders from repeat customer)

SELECT
	customer_unique_id,
	COUNT(*) AS customer_record_count
FROM
	"RAW"."RAW - Customer"
GROUP BY
	customer_unique_id
						HAVING
								COUNT(customer_unique_id) > 1
ORDER BY
	customer_record_count DESC;

-- How many distinct persistent customers are there in total?

SELECT
	COUNT(DISTINCT(customer_unique_id))
FROM
	"RAW"."RAW - Customer";

-- Are any customer_unique_id values NULL or blank

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Customer"
WHERE
	customer_unique_id IS NULL
	OR
	customer_unique_id = '';

-- Does every customer_id appearing in Orders have a matching customer_id in Customers?

SELECT
	*
FROM
	"RAW"."RAW - Orders" ro LEFT JOIN "RAW"."RAW - Customer" rc
								ON ro.customer_id = rc.customer_id
WHERE
	rc.customer_id IS NULL;

-- Does every customer_id appearing in Customers have a matching customer_id in Orders?

SELECT
	*
FROM
	"RAW"."RAW - Customer" rc LEFT JOIN "RAW"."RAW - Orders" ro
								  ON rc.customer_id = ro.customer_id
WHERE
	ro.customer_id IS NULL;

-- Does any customer_id appear more than once in Orders?

SELECT
	customer_id,
	COUNT(*) AS customer_count
FROM
	"RAW"."RAW - Orders"
GROUP BY
	customer_id
				HAVING
						COUNT(*) > 1;

-- Do any customer_zip_code_prefix values appear more than once?

SELECT
	customer_zip_code_prefix,
	COUNT(*) AS zip_code_count
FROM
	"RAW"."RAW - Customer"
GROUP BY
	customer_zip_code_prefix
							HAVING
									COUNT(*) > 1
ORDER BY
	zip_code_count DESC;

-- Are any customer_zip_code_prefix values NULL or blank?

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Customer"
WHERE
	customer_zip_code_prefix IS NULL
	OR
	customer_zip_code_prefix = '';

-- Are any customer_city values NULL or blank?

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Customer"
WHERE
	customer_city IS NULL
	OR
	customer_city = '';

-- Are any customer_state values NULL or blank?

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Customer"
WHERE
	customer_state IS NULL
	OR
	customer_state = '';

-- Does one ZIP prefix consistently map to one state, or are there ZIP prefixes associated with multiple states?

SELECT
	customer_zip_code_prefix,
	COUNT(DISTINCT(customer_state))
FROM
	"RAW"."RAW - Customer"
GROUP BY
	customer_zip_code_prefix
							HAVING
									COUNT(DISTINCT(customer_state)) > 1;

-- Does one ZIP prefix consistently map to one city, or are there ZIP prefixes associated with multiple cities?

SELECT
	customer_zip_code_prefix,
	COUNT(DISTINCT(customer_city))
FROM
	"RAW"."RAW - Customer"
GROUP BY
	customer_zip_code_prefix
							HAVING
									COUNT(DISTINCT(customer_city)) > 1;

-- Which cities in the above query, share customer_zip_code_prefix?

SELECT
	customer_zip_code_prefix,
	COUNT(DISTINCT(customer_city)) AS city_count,
	STRING_AGG(DISTINCT(customer_city), ', ') AS cities
FROM
	"RAW"."RAW - Customer"
GROUP BY
	customer_zip_code_prefix
							HAVING
									COUNT(DISTINCT(customer_city)) > 1
ORDER BY
	city_count DESC;

-- Do all customer_zip_code_prefix values from Customers, exist in Geolocation?

SELECT
	DISTINCT(rc.customer_zip_code_prefix)
FROM
	"RAW"."RAW - Customer" rc LEFT JOIN "RAW"."RAW - Geolocation" rg
									ON rc.customer_zip_code_prefix = rg.geolocation_zip_code_prefix
WHERE
	rg.geolocation_zip_code_prefix IS NULL;

-- How many customer rows are affected by those unmatched ZIP prefixes?

SELECT
	rc.customer_zip_code_prefix AS zipcode,
	COUNT(DISTINCT(rc.customer_id)) AS customer_count
FROM
	"RAW"."RAW - Customer" rc LEFT JOIN "RAW"."RAW - Geolocation" rg
									ON rc.customer_zip_code_prefix = rg.geolocation_zip_code_prefix
WHERE
	rg.geolocation_zip_code_prefix IS NULL
GROUP BY
	rc.customer_zip_code_prefix
ORDER BY
	customer_count DESC;

-- How many customer records in total are affected?

SELECT
	COUNT(DISTINCT(rc.customer_id)) customer_count
FROM
	"RAW"."RAW - Customer" rc LEFT JOIN "RAW"."RAW - Geolocation" rg
									ON rc.customer_zip_code_prefix = rg.geolocation_zip_code_prefix
WHERE
	rg.geolocation_zip_code_prefix IS NULL;

-- Can the same customer_unique_id appear with more than one ZIP prefix?

SELECT
	customer_unique_id AS indv_customer,
	COUNT(DISTINCT(customer_zip_code_prefix)) AS zip_count
FROM
	"RAW"."RAW - Customer"
GROUP BY
	customer_unique_id
						HAVING
								COUNT(DISTINCT(customer_zip_code_prefix)) > 1
ORDER BY
	zip_count DESC;










------------------------------------------------------------------------------------------------------------------------------------------------

										-- Geolocation Table Validation --

-- How many total rows?

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Geolocation";

-- How many rows have exact duplicates?

SELECT
	COUNT(*) AS duplicate_count,
	geolocation_zip_code_prefix,
	geolocation_lat,
	geolocation_lng,
	geolocation_city,
	geolocation_state
FROM
	"RAW"."RAW - Geolocation"
GROUP BY
	geolocation_zip_code_prefix,
	geolocation_lat,
	geolocation_lng,
	geolocation_city,
	geolocation_state
						HAVING
								COUNT(*) > 1
ORDER BY
	duplicate_count DESC;

-- How many physical rows are part of duplicate groups, and how many are “extra” duplicate rows beyond the first occurrence?

SELECT
	SUM(duplicate_count) AS total_duplicates
FROM
	(
	SELECT
		COUNT(*) -1 as duplicate_count
	FROM
		"RAW"."RAW - Geolocation"
	GROUP BY
		geolocation_zip_code_prefix,
		geolocation_lat,
		geolocation_lng,
		geolocation_city,
		geolocation_state
							HAVING
									COUNT(*) > 1
	);

-- Does any latitude / longitude pair occur more than once?

SELECT
	(geolocation_lat||', '||geolocation_lng) AS geolocation_coord,
	COUNT(*) AS duplicate_coord
FROM
	"RAW"."RAW - Geolocation"
GROUP BY
	geolocation_lat,
	geolocation_lng
					HAVING
							COUNT(*) > 1
ORDER BY
	duplicate_coord DESC;

-- How many extra duplicate coordinate rows are there?

SELECT
	SUM(duplicate_coord) AS total_duplicates
FROM
	(
	SELECT
		(geolocation_lat||', '||geolocation_lng) AS geolocation_coord,
		COUNT(*) - 1 AS duplicate_coord
	FROM
		"RAW"."RAW - Geolocation"
	GROUP BY
		geolocation_lat,
		geolocation_lng
						HAVING
								COUNT(*) > 1
	ORDER BY
		duplicate_coord DESC
	);

-- Does the same Lat/Lng pair even map to multiple ZIP prefixes?

SELECT
	(geolocation_lat||', '||geolocation_lng) AS geolocation_coord,
	STRING_AGG(DISTINCT(geolocation_zip_code_prefix), ', ') AS zip
FROM
	"RAW"."RAW - Geolocation"
GROUP BY
	geolocation_lat,
	geolocation_lng

-- Only coordinates associated with multiple ZIP prefixes:

SELECT
	(geolocation_lat||', '||geolocation_lng) AS geolocation_coord,
	STRING_AGG(DISTINCT(geolocation_zip_code_prefix), ', ') AS zip
FROM
	"RAW"."RAW - Geolocation"
GROUP BY
	geolocation_lat,
	geolocation_lng
					HAVING
							COUNT(DISTINCT(geolocation_zip_code_prefix)) > 1;

-- Do the same coordinates map to multiple states?

SELECT
	(geolocation_lat||', '||geolocation_lng) AS geolocation_coord,
	STRING_AGG(DISTINCT(geolocation_state), ', ') AS states
FROM
	"RAW"."RAW - Geolocation"
GROUP BY
	geolocation_lat,
	geolocation_lng
					HAVING
							COUNT(DISTINCT(geolocation_state)) > 1;

-- Drilling into the above 5 coordinates that share States:

SELECT
	*
FROM
	"RAW"."RAW - Geolocation"
WHERE
	(geolocation_lat = '-20.153463886133054' AND geolocation_lng = '-41.62518894554678') OR
	(geolocation_lat = '-22.919164311034095' AND geolocation_lng = '-43.61109694482953') OR
	(geolocation_lat = '-23.57870736918802' AND geolocation_lng = '-46.645778615462866') OR
	(geolocation_lat = '-30.005202456575603' AND geolocation_lng = '-51.19099166472387') OR
	(geolocation_lat = '-8.056736000115334' AND geolocation_lng = '-34.9159460114293')
ORDER BY
	geolocation_lat;

-- Do any of the five Geolocation attributes contain NULL or blank values?

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Geolocation"
WHERE
	(geolocation_zip_code_prefix IS NULL OR geolocation_zip_code_prefix = '') OR
	(geolocation_lat IS NULL OR geolocation_lat = '') OR
	(geolocation_lng IS NULL OR geolocation_lng = '') OR
	(geolocation_city IS NULL OR geolocation_city = '') OR
	(geolocation_state IS NULL OR geolocation_state = '');

-- Do any rows in geolocation_zip_code_prefix contain anything other than digits and any length NOT equal to 5?

SELECT
	COUNT(geolocation_zip_code_prefix)
FROM
	"RAW"."RAW - Geolocation"
WHERE
	(geolocation_zip_code_prefix ~'[^0-9]') OR (LENGTH(geolocation_zip_code_prefix) <> 5);

-- Are all rows in geolocation_lat NUMERIC and do they fall within the -90 to +90 range?

SELECT
	COUNT(geolocation_lat)
FROM
	"RAW"."RAW - Geolocation"
WHERE
	(geolocation_lat ~'[^0-9.-]') OR 
	(CAST(geolocation_lat AS NUMERIC) > 90) OR 
	(CAST(geolocation_lat AS NUMERIC) < -90);

-- Are all rows in geolocation_lng NUMERIC and do they fall within the -180 to +180 range?

SELECT
	COUNT(geolocation_lng)
FROM
	"RAW"."RAW - Geolocation"
WHERE
	(geolocation_lng ~'[^0-9.-]') OR 
	(CAST(geolocation_lng AS NUMERIC) > 180) OR 
	(CAST(geolocation_lng AS NUMERIC) < -180);

-- Which distinct geolocation_city values contain numeric characters (based from Excel Exploration)?

SELECT
	DISTINCT(geolocation_city)
FROM
	"RAW"."RAW - Geolocation"
WHERE
	geolocation_city ~'[0-9]';

-- Any city values made entirely of digits?

SELECT
	DISTINCT(geolocation_city)
FROM
	"RAW"."RAW - Geolocation"
WHERE
	geolocation_city ~'^[0-9]+$';

-- Any state values that aren't valid Brazilian State UF codes?

SELECT
	COUNT(geolocation_state)
FROM
	"RAW"."RAW - Geolocation"
WHERE
	geolocation_state NOT IN ('AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO',
							  'MA', 'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 
							  'RJ', 'RN', 'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO');

-- Do all seller_zip_code_prefix values from Sellers, exist in Geolocation?

SELECT
	rs.seller_zip_code_prefix,
	rg.geolocation_zip_code_prefix
FROM
	"RAW"."RAW - Sellers" rs LEFT JOIN "RAW"."RAW - Geolocation" rg
								 ON rs.seller_zip_code_prefix = rg.geolocation_zip_code_prefix
WHERE
	rg.geolocation_zip_code_prefix IS NULL;

-- How many of those Seller Zips are affected?

SELECT
	rs.seller_zip_code_prefix AS seller_zip,
	COUNT(seller_id) AS seller_count
FROM
	"RAW"."RAW - Sellers" rs LEFT JOIN "RAW"."RAW - Geolocation" rg
								 ON rs.seller_zip_code_prefix = rg.geolocation_zip_code_prefix
WHERE
	rg.geolocation_zip_code_prefix IS NULL
GROUP BY
	rs.seller_zip_code_prefix
ORDER BY
	seller_count DESC;

-- How many geolocation_zip_code_prefix's are in Geolocation but NOT with equivalent in Sellers?

SELECT
	COUNT(DISTINCT(rg.geolocation_zip_code_prefix))
FROM
	"RAW"."RAW - Geolocation" rg LEFT JOIN "RAW"."RAW - Sellers" rs
									 ON rg.geolocation_zip_code_prefix = rs.seller_zip_code_prefix
WHERE
	rs.seller_zip_code_prefix IS NULL;

-- How many distince ZIP prefixes exist in Geolocation altogether?

SELECT
	COUNT(DISTINCT(geolocation_zip_code_prefix))
FROM
	"RAW"."RAW - Geolocation";

-- How many Geolocation rows can belong to the same ZIP prefix?

SELECT
	geolocation_zip_code_prefix AS prefix,
	COUNT(*) AS total_count
FROM
	"RAW"."RAW - Geolocation"
GROUP BY
	geolocation_zip_code_prefix
ORDER BY
	total_count DESC;

-- Within each ZIP prefix, how many distinct Lat/Lng combinations exist?

SELECT
	geolocation_zip_code_prefix AS prefix,
	COUNT(*) AS total_count,
	COUNT(DISTINCT(geolocation_lat||', '||geolocation_lng)) AS distinct_coords
FROM
	"RAW"."RAW - Geolocation"
GROUP BY
	geolocation_zip_code_prefix
ORDER BY
	total_count DESC;

-- Which ZIP prefixes are associated with more than one distinct City value?

SELECT
	geolocation_zip_code_prefix AS prefix,
	COUNT(DISTINCT(geolocation_city)) AS city_count,
	STRING_AGG(DISTINCT(geolocation_city), ', ') AS cities
FROM
	"RAW"."RAW - Geolocation"
GROUP BY
	geolocation_zip_code_prefix
								HAVING
										COUNT(DISTINCT(geolocation_city)) > 1
ORDER BY
	city_count DESC;










------------------------------------------------------------------------------------------------------------------------------------------------

										-- Order Items Table Validation --

-- Checking total rows

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Order Items";

-- Checking for duplicate rows

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Order Items"
GROUP BY
	order_id,
	order_item_id,
	product_id,
	seller_id,
	shipping_limit_date,
	price,
	freight_value
						HAVING
								COUNT(*) > 1;

-- Any NULL or Blank values in order_id?

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Order Items"
WHERE
	order_id IS NULL
	OR
	order_id = '';

-- Any NULL or Blank values in order_item_id?

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Order Items"
WHERE
	order_item_id IS NULL
	OR
	order_item_id = '';

-- Any duplicates for potential key?

SELECT
	(order_id||'.'||order_item_id) AS comp_key,
	COUNT(*) AS total_count
FROM
	"RAW"."RAW - Order Items"
GROUP BY
	order_id,
	order_item_id
					HAVING
							COUNT(*) > 1
ORDER BY
	total_count DESC;

-- For each order, do the order_item_id values start at 1 and increase consecutively up to the number of item rows in that order?

SELECT
	order_id,
	MIN(order_item_id :: INTEGER),
	MAX(order_item_id :: INTEGER),
	COUNT(*)
FROM
	"RAW"."RAW - Order Items"
GROUP BY
	order_id
			HAVING
					MIN(order_item_id :: INTEGER) <> 1
					OR
					MAX(order_item_id :: INTEGER) <> COUNT(*);

-- Any NULL or blanks for product_id?

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Order Items"
WHERE
	product_id IS NULL
	OR
	product_id = '';

-- Any NULL or blanks for seller_id?

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Order Items"
WHERE
	seller_id IS NULL
	OR
	seller_id = '';

-- Any NULL or blanks or invalid datatype for shipping_limit_date?

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Order Items"
WHERE
	shipping_limit_date IS NULL
	OR
	shipping_limit_date = ''
	OR
	TO_TIMESTAMP(shipping_limit_date, 'YYYY-MM-DD HH24:MI:SS') IS NULL;

-- Any NULL, blanks, non-NUMERIC or Negative values for price?

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Order Items"
WHERE
	price IS NULL
	OR
	price = ''
	OR
	price !~'^[0-9]+(\.[0-9]+)?$'
	OR
	CAST(price AS NUMERIC) < 0;

-- MIN and MAX range for price?

SELECT
	MIN(CAST(price AS NUMERIC)) AS min_num,
	MAX(CAST(price AS NUMERIC)) AS max_num
FROM
	"RAW"."RAW - Order Items";

-- Any NULL, blanks, non-NUMERIC or Negative values for freight_value?

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Order Items"
WHERE
	freight_value IS NULL
	OR
	freight_value = ''
	OR
	freight_value !~'^[0-9]+(\.[0-9]+)?$'
	OR
	CAST(freight_value AS NUMERIC) < 0;

-- MIN and MAX range for freight_value?

SELECT
	MIN(CAST(freight_value AS NUMERIC)) AS min_num,
	MAX(CAST(freight_value AS NUMERIC)) AS max_num
FROM
	"RAW"."RAW - Order Items";

-- Are there any order_ids in Orders but NOT in Order Items?

SELECT
	COUNT(o.order_id)
FROM
	"RAW"."RAW - Orders" o LEFT JOIN "RAW"."RAW - Order Items" oi
							   ON o.order_id = oi.order_id
WHERE
	oi.order_id IS NULL;

-- Are there any order_ids in Order Items but NOT in Orders?

SELECT
	COUNT(oi.order_id)
FROM
	"RAW"."RAW - Orders" o RIGHT JOIN "RAW"."RAW - Order Items" oi
							   ON o.order_id = oi.order_id
WHERE
	o.order_id IS NULL;

-- Profiling the unmatched order_ids (present in Orders but not Order Items) by order_status

SELECT
	o.order_status AS status,
	COUNT(o.order_id) AS unmatched_order_count
FROM
	"RAW"."RAW - Orders" o LEFT JOIN "RAW"."RAW - Order Items" oi
							   ON o.order_id = oi.order_id
WHERE
	oi.order_id IS NULL
GROUP BY
	o.order_status
ORDER BY
	unmatched_order_count DESC;

-- What are the full details of those 8 non-cancelled/non-unavailable unmatched orders, especially the shipped one?

SELECT
	*
FROM
	"RAW"."RAW - Orders" o LEFT JOIN "RAW"."RAW - Order Items" oi
							   ON o.order_id = oi.order_id
WHERE
	oi.order_id IS NULL
	AND
	(o.order_status <> 'unavailable' AND o.order_status <> 'canceled')
ORDER BY
	o.order_status ASC;

-- How many Order Item rows can one Orders have?

SELECT
	order_id,
	COUNT(order_item_id) AS item_count
FROM
	"RAW"."RAW - Order Items"
GROUP BY
	order_id
ORDER BY
	item_count DESC;

-- Are there any product_id values in Order Items that do not exist in Products?

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Order Items" ro LEFT JOIN "RAW"."RAW - Products" rp
									 ON ro.product_id = rp.product_id
WHERE
	rp.product_id IS NULL;

-- How many Order Item rows can Products have?

SELECT
	product_id,
	COUNT(order_item_id) AS item_count
FROM
	"RAW"."RAW - Order Items"
GROUP BY
	product_id
ORDER BY
	item_count DESC;

-- Are there any seller_id values in Order Items that do not exist in Sellers?

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Order Items" ro LEFT JOIN "RAW"."RAW - Sellers" rs
									 ON ro.seller_id = rs.seller_id
WHERE
	rs.seller_id IS NULL;

-- How many Order Item rows can Sellers have?

SELECT
	seller_id,
	COUNT(order_item_id) AS item_count
FROM
	"RAW"."RAW - Order Items"
GROUP BY
	seller_id
ORDER BY
	item_count DESC;

-- How many rows have an order_approved_at TIMESTAMP greater than shipping_limit_date TIMESTAMP?

SELECT
	DISTINCT(o.order_id),
	o.order_approved_at AS approved,
	oi.shipping_limit_date AS ship
FROM
	"RAW"."RAW - Order Items" oi INNER JOIN "RAW"."RAW - Orders" o
									  ON oi.order_id = o.order_id
WHERE
	(o.order_approved_at :: TIMESTAMP) > (oi.shipping_limit_date :: TIMESTAMP)
ORDER BY
	o.order_approved_at ASC;

-- Are there any orders represented in Order Items with no corresponding record in Payments?

SELECT
	COUNT(DISTINCT(oi.order_id)) total_orders,
	COUNT(oi.order_item_id) total_rows_per_order
FROM
	"RAW"."RAW - Order Items" oi LEFT JOIN "RAW"."RAW - Payments" rp
									 ON oi.order_id = rp.order_id
WHERE
	rp.order_id IS NULL;

-- Financial Reconciliation - At order level, does SUM(price + freight_value) from Order Items reconcile with SUM(payment_value) from Payments?

WITH item_total AS
(
SELECT
	order_id,
	(SUM(((price :: NUMERIC) + (freight_value :: NUMERIC)))) AS sum_price
FROM
	"RAW"."RAW - Order Items"
GROUP BY
	order_id
),
payment_total AS
(
SELECT
	order_id,
	(SUM(payment_value :: NUMERIC)) AS sum_payment,
	COUNT(*) AS num_of_rows,
	COUNT(DISTINCT(payment_type)) AS num_of_types,
	STRING_AGG(DISTINCT(payment_type), ', ') as pmt_types,
	MAX(payment_installments :: NUMERIC) AS installments
FROM
	"RAW"."RAW - Payments"
GROUP BY
	order_id
),
reconciliation AS
(
SELECT
	it.order_id,
	it.sum_price,
	pt.sum_payment,
	ABS(pt.sum_payment - it.sum_price) AS abs_diff,
	pt.num_of_rows,
	pt.num_of_types,
	pt.pmt_types,
	pt.installments
FROM
	item_total it LEFT JOIN payment_total pt
						ON it.order_id = pt.order_id
WHERE
	sum_price <> sum_payment
)
SELECT
	COUNT(order_id) AS total_count,
	(CASE
		WHEN abs_diff <= 0.05 THEN '0.01 - 0.05'
		WHEN abs_diff <= 1.00 THEN '0.06 - 1.00'
		ELSE 'Over 1.00'
	END) AS class_diff,
	(CASE
		WHEN pmt_types = 'credit_card' AND installments > 1 THEN 'Credit Card >1 installments'
		WHEN pmt_types = 'credit_card' AND installments = 1 THEN 'Credit Card =1 installments'
		WHEN pmt_types = 'debit_card' THEN 'Debit Card'
		WHEN pmt_types = 'boleto' THEN 'Boleto'
		WHEN pmt_types = 'voucher' THEN 'Voucher'
		WHEN num_of_types > 1 THEN 'Mixed Payments'
	END) AS pmt_category
FROM
	reconciliation
GROUP BY
	pmt_category,
	class_diff
ORDER BY
	total_count DESC;	










------------------------------------------------------------------------------------------------------------------------------------------------

										-- Payments Table Validation --

-- Checking total rows:

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Payments";

-- Checking for exact duplicate rows:

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Payments"
GROUP BY
	order_id,
	payment_sequential,
	payment_type,
	payment_installments,
	payment_value
							HAVING
									COUNT(*) > 1;

-- Any NULL or Blanks in order_id?

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Payments"
WHERE
	order_id IS NULL
	OR
	order_id = '';

-- Any NULL or Blanks in payment_sequential?

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Payments"
WHERE
	payment_sequential IS NULL
	OR
	payment_sequential = '';

-- Any duplicates in potential composite key (order_id + payment sequential)?

SELECT
	order_id||'.'||payment_sequential AS comp_key,
	COUNT(*) AS duplicate_count
FROM
	"RAW"."RAW - Payments"
GROUP BY
	order_id,
	payment_sequential
						HAVING
							 	COUNT(*) > 1;

-- For each order, does the payment_sequential value start at 1 and increase consecutively up to the number of payment_sequences in that order?

SELECT
	order_id,
	MIN(payment_sequential :: NUMERIC),
	MAX(payment_sequential :: NUMERIC),
	COUNT(*),
	STRING_AGG(payment_sequential, ', ') AS pmt_seq
FROM
	"RAW"."RAW - Payments"
GROUP BY
	order_id
			HAVING
					MIN(payment_sequential :: NUMERIC) <> 1
					OR
					MAX(payment_sequential :: NUMERIC) <> COUNT(*);

-- Are there payment records whose order_id doesn’t exist in Orders?

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Payments" rp LEFT JOIN "RAW"."RAW - Orders" ro
								  ON rp.order_id = ro.order_id
WHERE
	ro.order_id IS NULL;

-- Are there Orders with no Payment records?

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Payments" rp RIGHT JOIN "RAW"."RAW - Orders" ro
								  ON rp.order_id = ro.order_id
WHERE
	rp.order_id IS NULL;

-- Cross Matching with previous finding (OrderItemTable Order with no payment VS PaymentTable Order with no payment):

SELECT
	ro.order_id
FROM
	"RAW"."RAW - Payments" rp RIGHT JOIN "RAW"."RAW - Orders" ro
								  ON rp.order_id = ro.order_id
WHERE
	rp.order_id IS NULL;
-------------
SELECT
	oi.order_id,
	COUNT(oi.order_item_id) total_rows_per_order
FROM
	"RAW"."RAW - Order Items" oi LEFT JOIN "RAW"."RAW - Payments" rp
									 ON oi.order_id = rp.order_id
WHERE
	rp.order_id IS NULL
GROUP BY
	oi.order_id;

-- How many Distinct order_ids in Payments?

SELECT
	COUNT(DISTINCT(order_id))
FROM
	"RAW"."RAW - Payments";

-- What is the MAX number of Payment rows associated with a single Order?

SELECT
	order_id,
	COUNT(payment_sequential) AS pmt_seq
FROM
	"RAW"."RAW - Payments"
GROUP BY
	order_id
ORDER BY
	pmt_seq DESC;

-- Any NULL or Blanks in payment_type?

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Payments"
WHERE
	payment_type IS NULL
	OR
	payment_type = '';

-- Any NULL or Blanks in payment_installment?

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Payments"
WHERE
	payment_installments IS NULL
	OR
	payment_installments = '';

-- Any NULL or Blanks in payment_value?

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Payments"
WHERE
	payment_value IS NULL
	OR
	payment_value = '';

-- Appropriate value/format for payment_type?

SELECT
	*
FROM
	"RAW"."RAW - Payments"
WHERE
	payment_type NOT IN ('credit_card', 'debit_card', 'boleto', 'voucher');

-- Appropriate value/format for payment_installment?

SELECT
	*
FROM
	"RAW"."RAW - Payments"
WHERE
	payment_installments !~'^\d+$';

-- Appropriate value/format for payment_value?

SELECT
	*
FROM
	"RAW"."RAW - Payments"
WHERE
	payment_value !~'^-?\d+\.\d+$'

-- Profiling MIN and MAX for payment_installments:

SELECT
	MIN(payment_installments :: NUMERIC),
	MAX(payment_installments :: NUMERIC)
FROM
	"RAW"."RAW - Payments";
----------------
SELECT
	*
FROM
	"RAW"."RAW - Payments"
WHERE
	(payment_installments :: NUMERIC) IN
	(
	(SELECT
		MIN(payment_installments :: NUMERIC)
	FROM
		"RAW"."RAW - Payments"),
	(SELECT
		MAX(payment_installments :: NUMERIC)
	FROM
		"RAW"."RAW - Payments")
	)
ORDER BY
	(payment_installments :: NUMERIC) ASC;

-- Profiling MIN and MAX for payment_value:

SELECT
	MIN(payment_value :: NUMERIC),
	MAX(payment_value :: NUMERIC)
FROM
	"RAW"."RAW - Payments";
----------------
SELECT
	*
FROM
	"RAW"."RAW - Payments"
WHERE
	(payment_value :: NUMERIC) IN
	(
	(SELECT
		MIN(payment_value :: NUMERIC)
	FROM
		"RAW"."RAW - Payments"),
	(SELECT
		MAX(payment_value :: NUMERIC)
	FROM
		"RAW"."RAW - Payments")
	)
ORDER BY
	(payment_value :: NUMERIC) ASC;

-- Follow up with anomalies:

SELECT
	*
FROM
	"RAW"."RAW - Payments"
WHERE
	(payment_installments :: NUMERIC) = 0;
---------------
SELECT
	*
FROM
	"RAW"."RAW - Payments"
WHERE
	(payment_value :: NUMERIC) = 0;

-- For each payment_type, what installment values actually occur, and how frequently?

SELECT
	payment_type,
	payment_installments,
	COUNT(*) AS frequency
FROM
	"RAW"."RAW - Payments"
GROUP BY
	payment_type,
	payment_installments
ORDER BY
	payment_type ASC,
	(payment_installments :: NUMERIC) DESC;










------------------------------------------------------------------------------------------------------------------------------------------------

										-- Orders Table Validation --

-- Checking total rows:

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Orders";

-- Any exact duplicate rows?

SELECT
	order_id,
	COUNT(*) AS duplicate_count
FROM
	"RAW"."RAW - Orders"
GROUP BY
	order_id,
	customer_id,
	order_status,
	order_purchase_timestamp,
	order_approved_at,
	order_delivered_carrier_date,
	order_delivered_customer_date,
	order_estimated_delivery_date
									HAVING
											COUNT(*) > 1;

-- Any NULL or Blank values in order_id?

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Orders"
WHERE
	order_id IS NULL
	OR
	order_id = '';

-- Any duplicates in order_id?

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Orders"
GROUP BY
	order_id
			HAVING
					COUNT(*) > 1;

-- Any NULL or Blank values in customer_id?

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Orders"
WHERE
	customer_id IS NULL
	OR
	customer_id = '';
	
-- Any NULL or Blank values in order_status?

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Orders"
WHERE
	order_status IS NULL
	OR
	order_status = '';

-- Any NULL or Blank values in order_estimated_delivery_date?

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Orders"
WHERE
	order_estimated_delivery_date IS NULL
	OR
	order_estimated_delivery_date = '';

-- What distinct order_status values occur, and how many Orders belong to each?

SELECT
	order_status,
	COUNT(*) AS total_count
FROM
	"RAW"."RAW - Orders"
GROUP BY
	order_status
ORDER BY
	total_count DESC;

-- For each order_status, how many records have each lifecycle timestamp missing?

SELECT
	order_status,
	COUNT(order_id) AS total_orders,
	COUNT(order_purchase_timestamp) AS total_purchase,
	COUNT(order_approved_at) AS total_approved,
	COUNT(order_delivered_carrier_date) AS total_carrier_delivered,
	COUNT(order_delivered_customer_date) AS total_customer_delivered
FROM
	"RAW"."RAW - Orders"
GROUP BY
	order_status
ORDER BY
	total_approved ASC;

-- Row-level consistency testing for the above query (anomaly spotted):

SELECT
	order_id,
	order_approved_at,
	order_delivered_carrier_date,
	order_delivered_customer_date
FROM
	"RAW"."RAW - Orders"
WHERE
	order_status = 'delivered'
	AND
	(
	((order_approved_at IS NULL) OR (order_approved_at = ''))
	OR
	((order_delivered_carrier_date IS NULL) OR (order_delivered_carrier_date = ''))
	OR
	((order_delivered_customer_date IS NULL) OR (order_delivered_customer_date = ''))
	);

-- Any order_ids with incorrect chronological timestamp order; approval before purchase?

SELECT
	*
FROM
	"RAW"."RAW - Orders"
WHERE
	order_approved_at < order_purchase_timestamp;

-- Any order_ids with incorrect chronological timestamp order; carrier before approval?

SELECT
	*
FROM
	"RAW"."RAW - Orders"
WHERE
	order_delivered_carrier_date < order_approved_at;

-- Time difference profiling for above query:

SELECT
	order_id,
	order_approved_at,
	order_delivered_carrier_date,
	((order_approved_at :: TIMESTAMP) - (order_delivered_carrier_date :: TIMESTAMP)) AS time_difference
FROM
	"RAW"."RAW - Orders"
WHERE
	order_delivered_carrier_date < order_approved_at
ORDER BY
	time_difference DESC
LIMIT
	10;

-- Quantifying the above result into Bins:

SELECT
	(CASE
		WHEN time_difference <= INTERVAL '1 hour' THEN 'Less than 1 hour'
		WHEN time_difference > INTERVAL '1 hour' AND time_difference <= INTERVAL '1 day' THEN '1 - 24 hours'
		WHEN time_difference > INTERVAL '1 day' AND time_difference <= INTERVAL '7 days' THEN '1 - 7 days'
		ELSE 'More than 7 days'
	END) AS time_interval,
	COUNT(*) AS total_orders
FROM
	(
	SELECT
		order_id,
		order_approved_at,
		order_delivered_carrier_date,
		((order_approved_at :: TIMESTAMP) - (order_delivered_carrier_date :: TIMESTAMP)) AS time_difference
	FROM
		"RAW"."RAW - Orders"
	WHERE
		order_delivered_carrier_date < order_approved_at
	ORDER BY
		time_difference DESC
	) AS time_table
GROUP BY
	time_interval
ORDER BY
	time_interval ASC;

-- Any order_ids with incorrect chronological timestamp order; customer delivery before carrier?

SELECT
	*
FROM
	"RAW"."RAW - Orders"
WHERE
	order_delivered_customer_date < order_delivered_carrier_date;

-- Time difference profiling for above query:

SELECT
	order_id,
	order_delivered_carrier_date,
	order_delivered_customer_date,
	((order_delivered_carrier_date :: TIMESTAMP) - (order_delivered_customer_date :: TIMESTAMP)) AS time_difference
FROM
	"RAW"."RAW - Orders"
WHERE
	order_delivered_customer_date < order_delivered_carrier_date
ORDER BY
	time_difference DESC;

-- Compact Orders-centric relationship check showing for every order, whether it has a matching Customer, at least one Order Item and at least one Payment?

WITH order_items AS
(
SELECT
	order_id,
	STRING_AGG(order_item_id, ', ') AS order_item_ids,
	COUNT(*) total_items,
	SUM((price :: NUMERIC) + (freight_value :: NUMERIC)) AS total_price
FROM
	"RAW"."RAW - Order Items"
GROUP BY
	order_id
),
payment AS
(
SELECT
	order_id,
	STRING_AGG(DISTINCT(payment_sequential), ', ') AS payment_sequentials,
	STRING_AGG(DISTINCT(payment_type), ', ') AS payment_types,
	SUM(payment_installments :: NUMERIC) AS total_installments,
	SUM(payment_value :: NUMERIC) AS total_value
FROM
	"RAW"."RAW - Payments"
GROUP BY
	order_id
)
SELECT
	ro.order_status,
	COUNT(ro.order_id) AS total_orders,
	(COUNT(*) FILTER (WHERE rc.customer_id IS NULL)) AS missing_customer,
	(COUNT(*) FILTER (WHERE oi.order_item_ids IS NULL)) AS missing_items,
	(COUNT(*) FILTER (WHERE p.total_value IS NULL)) AS missing_payment
FROM
	"RAW"."RAW - Orders" ro LEFT JOIN "RAW"."RAW - Customer" rc ON ro.customer_id = rc.customer_id
							LEFT JOIN order_items oi ON ro.order_id = oi.order_id
							LEFT JOIN payment p ON ro.order_id = p.order_id
GROUP BY
	ro.order_status
ORDER BY
    (CASE order_status
        WHEN 'created'    THEN 1
		WHEN 'approved'   THEN 2
        WHEN 'invoiced'   THEN 3
        WHEN 'processing' THEN 4
        WHEN 'shipped'    THEN 5
        WHEN 'delivered'  THEN 6
        WHEN 'canceled'   THEN 7
        ELSE 8
    END) ASC;
	









------------------------------------------------------------------------------------------------------------------------------------------------

										-- Reviews Table Validation --

-- Checking total rows:

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Reviews";

-- Check for exact duplicate rows:

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Reviews"
GROUP BY
	review_id,
	order_id,
	review_score,
	review_comment_title,
	review_comment_message,
	review_creation_date,
	review_answer_timestamp
							HAVING
									COUNT(*) > 1;

-- Any NULL/Blanks in review_id?

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Reviews"
WHERE
	review_id IS NULL
	OR
	review_id = '';
	
-- Any NULL/Blanks in order_id?

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Reviews"
WHERE
	order_id IS NULL
	OR
	order_id = '';

-- Any duplicates in (review_id, order_id)?

SELECT
	(review_id||'.'||order_id) AS key_combo,
	COUNT(*)
FROM
	"RAW"."RAW - Reviews"
GROUP BY
	review_id,
	order_id
								HAVING
										COUNT(*) > 1;

-- Any NULL/Blank values in review_score?

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Reviews"
WHERE
	review_score IS NULL
	OR
	review_score = '';

-- Any invalid scores in review_score?

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Reviews"
WHERE
	review_score NOT IN ('1','2','3','4','5');

-- Review_score distribution:

SELECT
	review_score,
	COUNT(*)
FROM
	"RAW"."RAW - Reviews"
GROUP BY
	review_score
ORDER BY
	review_score ASC;

-- Any NULL/Blank values in review_creation_date?

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Reviews"
WHERE
	review_creation_date IS NULL
	OR
	review_creation_date = '';

-- Any NULL/Blank values in review_answer_timestamp?

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Reviews"
WHERE
	review_answer_timestamp IS NULL
	OR
	review_answer_timestamp = '';

-- Are review_creation_date values valid/castable as timestamps?

SELECT
	review_creation_date :: TIMESTAMP
FROM
	"RAW"."RAW - Reviews";

-- Are review_answer_timestamp values valid/castable as timestamps?

SELECT
	review_answer_timestamp :: TIMESTAMP
FROM
	"RAW"."RAW - Reviews";

-- How many reviews have review_answer_timestamp < review_creation_date?

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Reviews"
WHERE
	review_answer_timestamp < review_creation_date;

-- Any NULL/Blank values in review_comment_title?

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Reviews"
WHERE
	review_comment_title IS NULL
	OR
	review_comment_title = '';

-- Any NULL/Blank values in review_comment_message?

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Reviews"
WHERE
	review_comment_message IS NULL
	OR
	review_comment_message = '';

-- How many distinct review_ids occur more than once?

SELECT
	review_id,
	COUNT(*)
FROM
	"RAW"."RAW - Reviews"
GROUP BY
	review_id
			HAVING
				  COUNT(*) > 1;

-- How many distinct order_ids occur more than once?

SELECT
	order_id,
	COUNT(*)
FROM
	"RAW"."RAW - Reviews"
GROUP BY
	order_id
			HAVING
				  COUNT(*) > 1;

-- For every review_id that occurs more than once, how many distinct persistent customers (customer_unique_id) are associated with it?

SELECT
	rr.review_id,
	STRING_AGG(DISTINCT(rc.customer_unique_id), ', ') AS persistant_customer,
	COUNT(DISTINCT(rc.customer_unique_id)) AS total_cust_id
FROM
	"RAW"."RAW - Reviews" rr LEFT JOIN "RAW"."RAW - Orders" ro ON rr.order_id = ro.order_id
							 LEFT JOIN "RAW"."RAW - Customer" rc ON ro.customer_id = rc.customer_id
GROUP BY
	rr.review_id
				HAVING
						COUNT(DISTINCT(rc.customer_unique_id)) > 1;

-- For orders that occur more than once in Reviews, how many distinct review_ids do they have?

SELECT
	order_id,
	STRING_AGG(DISTINCT(review_id), ', ') AS review_ids,
	COUNT(DISTINCT(review_id)) AS distinct_ids
FROM
	"RAW"."RAW - Reviews"
GROUP BY
	order_id
			HAVING
					COUNT(order_id) > 1
ORDER BY
	distinct_ids DESC;

-- For those 547 multi-review orders, how many have more than one distinct review_score?

SELECT
	order_id,
	STRING_AGG(DISTINCT(review_score), ', ') AS scores,
	COUNT(DISTINCT(review_score)) AS distinct_scores
FROM
	"RAW"."RAW - Reviews"
GROUP BY
	order_id
			HAVING
					COUNT(DISTINCT(review_score)) > 1;

-- Among repeated review_ids, how many have more than one distinct review_score?

SELECT
	review_id,
	STRING_AGG(DISTINCT(review_score), ', ') AS scores,
	COUNT(DISTINCT(review_score)) AS distinct_score
FROM
	"RAW"."RAW - Reviews"
GROUP BY
	review_id
			HAVING
					COUNT(DISTINCT(review_score)) > 1

-- For the same review_id, does any of this information(title, message, creation date & answer timestamp) vary between its occurrences?

SELECT
	review_id,
	COUNT(DISTINCT(COALESCE(review_comment_title, 'NULL'))) AS review_title,
	COUNT(DISTINCT(COALESCE(review_comment_message, 'NULL'))) AS review_message,
	COUNT(DISTINCT(COALESCE(review_creation_date, 'NULL'))) AS review_creation,
	COUNT(DISTINCT(COALESCE(review_answer_timestamp, 'NULL'))) AS review_answer
FROM
	"RAW"."RAW - Reviews"
GROUP BY
	review_id
			HAVING
					COUNT(DISTINCT(COALESCE(review_comment_title, 'NULL'))) > 1 OR
					COUNT(DISTINCT(COALESCE(review_comment_message, 'NULL'))) > 1 OR
					COUNT(DISTINCT(COALESCE(review_creation_date, 'NULL'))) > 1 OR
					COUNT(DISTINCT(COALESCE(review_answer_timestamp, 'NULL'))) > 1;

-- How many Orders have no Review at all?

SELECT
	COUNT(*) AS total_count
FROM
	"RAW"."RAW - Reviews" rr RIGHT JOIN "RAW"."RAW - Orders" ro
								 ON rr.order_id = ro.order_id
WHERE
	review_id IS NULL
	OR
	review_id = '';

-- Are there any Review records whose order_id does not exist in Orders?

SELECT
	COUNT(*) AS total_count
FROM
	"RAW"."RAW - Reviews" rr LEFT JOIN "RAW"."RAW - Orders" ro
								 ON rr.order_id = ro.order_id
WHERE
	ro.order_id IS NULL
	OR
	ro.order_id = '';










------------------------------------------------------------------------------------------------------------------------------------------------

										-- Products Table Validation --

-- Checking total rows: 

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Products";

-- Check for exact duplicate rows:

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Products"
GROUP BY
	product_id,
	product_category_name,
	product_name_length,
	product_description_length,
	product_photos_qty,
	product_weight_g,
	product_length_cm,
	product_height_cm,
	product_width_cm
						HAVING
								COUNT(*) > 1;

-- Any NULL/Blank values in product_id?

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Products"
WHERE
	product_id IS NULL
	OR
	product_id = '';

-- Any duplicates in product_id?

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Products"
GROUP BY
	product_id
				HAVING
						COUNT(*) > 1;

-- Any NULL/Blank values in the remaining attribute columns?

SELECT
	(COUNT(*) FILTER(WHERE (product_category_name IS NULL) OR (product_category_name = ''))) AS missing_category,
	(COUNT(*) FILTER(WHERE (product_name_length IS NULL) OR (product_name_length = ''))) AS missing_name,
	(COUNT(*) FILTER(WHERE (product_description_length IS NULL) OR (product_description_length = ''))) AS missing_description,
	(COUNT(*) FILTER(WHERE (product_photos_qty IS NULL) OR (product_photos_qty = ''))) AS missing_photos,
	(COUNT(*) FILTER(WHERE (product_weight_g IS NULL) OR (product_weight_g = ''))) AS missing_weight,
	(COUNT(*) FILTER(WHERE (product_length_cm IS NULL) OR (product_length_cm = ''))) AS missing_length,
	(COUNT(*) FILTER(WHERE (product_height_cm IS NULL) OR (product_height_cm = ''))) AS missing_height,
	(COUNT(*) FILTER(WHERE (product_width_cm IS NULL) OR (product_width_cm = ''))) AS missing_width
FROM
	"RAW"."RAW - Products";

-- Are these two consistent missingness patterns, or just coincidentally equal counts?

SELECT
	*
FROM
	"RAW"."RAW - Products"
WHERE
	((product_category_name IS NULL) OR (product_category_name = '')) AND
	((product_name_length IS NULL) OR (product_name_length = '')) AND
	((product_description_length IS NULL) OR (product_description_length = '')) AND
	((product_photos_qty IS NULL) OR (product_photos_qty = ''));
--------------------
SELECT
	*
FROM
	"RAW"."RAW - Products"
WHERE
	((product_weight_g IS NULL) OR (product_weight_g = '')) AND
	((product_length_cm IS NULL) OR (product_length_cm = '')) AND
	((product_height_cm IS NULL) OR (product_height_cm = '')) AND
	((product_width_cm IS NULL) OR (product_width_cm = ''));

-- Checking for invalid formats for descriptive and dimension columns:

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Products"
WHERE
	(product_name_length !~'^\d+$') OR
	(product_description_length !~'^\d+$') OR
	(product_photos_qty !~'^\d+$') OR
	(product_weight_g !~'^\d+(\.\d+)?$') OR
	(product_length_cm !~'^\d+(\.\d+)?$') OR
	(product_height_cm !~'^\d+(\.\d+)?$') OR
	(product_width_cm !~'^\d+(\.\d+)?$');

-- Checking for invalid range for descriptive and dimension columns:

SELECT
	((MIN(product_name_length :: NUMERIC))||', '||(MAX(product_name_length :: NUMERIC))) AS min_max_name,
	((MIN(product_description_length :: NUMERIC))||', '||(MAX(product_description_length :: NUMERIC))) AS min_max_description,
	((MIN(product_photos_qty :: NUMERIC))||', '||(MAX(product_photos_qty :: NUMERIC))) AS min_max_photos,
	((MIN(product_weight_g :: NUMERIC))||', '||(MAX(product_weight_g :: NUMERIC))) AS min_max_weight,
	((MIN(product_length_cm :: NUMERIC))||', '||(MAX(product_length_cm :: NUMERIC))) AS min_max_length,
	((MIN(product_height_cm :: NUMERIC))||', '||(MAX(product_height_cm :: NUMERIC))) AS min_max_height,
	((MIN(product_width_cm :: NUMERIC))||', '||(MAX(product_width_cm :: NUMERIC))) AS min_max_width
FROM
	"RAW"."RAW - Products";

-- Exploring above query result Weight anomaly:

SELECT
	rp.*,
	rpct.product_category_name_english
FROM
	"RAW"."RAW - Products" rp LEFT JOIN "RAW"."RAW - Product Category Name Translation" rpct
									ON rp.product_category_name = rpct.product_category_name
WHERE
	(product_weight_g :: NUMERIC) = 0;

-- Coverage check for Order Items -> Products:

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Order Items" roi LEFT JOIN "RAW"."RAW - Products" rp
										ON roi.product_id = rp.product_id
WHERE
	rp.product_id IS NULL
	OR
	rp.product_id = '';

-- Coverage check for Products -> Order Items:

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Products" rp LEFT JOIN "RAW"."RAW - Order Items" roi
										ON roi.product_id = rp.product_id
WHERE
	roi.product_id IS NULL
	OR
	roi.product_id = '';

-- Coverage check for Category Translation -> Products:

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Product Category Name Translation" rpct LEFT JOIN "RAW"."RAW - Products" rp
																ON rpct.product_category_name = rp.product_category_name
WHERE
	rp.product_category_name IS NULL
	OR
	rp.product_category_name = '';

-- Coverage check for Products -> Category Translation:

SELECT
	(COUNT(*) FILTER(WHERE((rp.product_category_name IS NOT NULL) AND (rp.product_category_name <> '')))) AS filtered_total
FROM
	"RAW"."RAW - Products" rp LEFT JOIN "RAW"."RAW - Product Category Name Translation" rpct
									ON rp.product_category_name = rpct.product_category_name
WHERE
	rpct.product_category_name IS NULL
	OR
	rpct.product_category_name = '';

-- Exploring those 13 rows from the above query:

SELECT
	rp.product_category_name,
	COUNT(rp.*) AS number_of_products
FROM
	"RAW"."RAW - Products" rp LEFT JOIN "RAW"."RAW - Product Category Name Translation" rpct
									ON rp.product_category_name = rpct.product_category_name
WHERE
	((rpct.product_category_name IS NULL) OR (rpct.product_category_name = ''))
	AND
	((rp.product_category_name IS NOT NULL) AND (rp.product_category_name <> ''))
GROUP BY
	rp.product_category_name
ORDER BY
	number_of_products DESC;

-- Are the 610 metadata-missing products concentrated among particular sellers, or spread broadly across sellers?

SELECT
	roi.seller_id AS seller,
	COUNT(DISTINCT(rp.product_id)) AS number_of_products
FROM
	"RAW"."RAW - Products" rp LEFT JOIN "RAW"."RAW - Order Items" roi
									ON rp.product_id = roi.product_id
WHERE
	((rp.product_category_name IS NULL) OR (rp.product_category_name = '')) AND
	((rp.product_name_length IS NULL) OR (rp.product_name_length = '')) AND
	((rp.product_description_length IS NULL) OR (rp.product_description_length = '')) AND
	((rp.product_photos_qty IS NULL) OR (rp.product_photos_qty = ''))
GROUP BY
	roi.seller_id
ORDER BY
	number_of_products DESC

-- Calculate missing-metadata products / total distinct products associated with each seller:

WITH pct_calc AS
(
SELECT
	roi.seller_id AS seller,
	(COUNT(DISTINCT(rp.product_id)) FILTER(WHERE(
									((rp.product_category_name IS NULL) OR (rp.product_category_name = '')) AND
									((rp.product_name_length IS NULL) OR (rp.product_name_length = '')) AND
									((rp.product_description_length IS NULL) OR (rp.product_description_length = '')) AND
									((rp.product_photos_qty IS NULL) OR (rp.product_photos_qty = ''))
									))) AS missing_metadata_products,
	COUNT(DISTINCT(rp.product_id)) AS total_products,
	ROUND(((((COUNT(DISTINCT(rp.product_id)) FILTER(WHERE(
									((rp.product_category_name IS NULL) OR (rp.product_category_name = '')) AND
									((rp.product_name_length IS NULL) OR (rp.product_name_length = '')) AND
									((rp.product_description_length IS NULL) OR (rp.product_description_length = '')) AND
									((rp.product_photos_qty IS NULL) OR (rp.product_photos_qty = ''))
									))) :: NUMERIC) / ((COUNT(DISTINCT(rp.product_id))) :: NUMERIC)) * 100), 2)AS raw_pct
FROM
	"RAW"."RAW - Products" rp LEFT JOIN "RAW"."RAW - Order Items" roi
									ON rp.product_id = roi.product_id
GROUP BY
	roi.seller_id
)
SELECT
	seller,
	missing_metadata_products,
	total_products,
	(raw_pct||'%') AS "Missing %"
FROM
	pct_calc
WHERE
	missing_metadata_products > 0
ORDER BY
	raw_pct DESC;

-- Do products with missing metadata tend to sell fewer units than products with complete metadata?

WITH products_sold AS
(
SELECT
	rp.product_id AS product,
	(CASE
		 WHEN (((rp.product_category_name IS NULL) OR (rp.product_category_name = ''))
		  AND ((rp.product_name_length IS NULL) OR (rp.product_name_length = ''))
		  AND ((rp.product_description_length IS NULL) OR (rp.product_description_length = ''))
		  AND ((rp.product_photos_qty IS NULL) OR (rp.product_photos_qty = '')))
		 THEN 'Missing'
		 ELSE 'Complete'
	END) AS metadata_status,
	COUNT(roi.product_id) AS units_sold
FROM
	"RAW"."RAW - Order Items" roi LEFT JOIN "RAW"."RAW - Products" rp
										ON roi.product_id = rp.product_id
GROUP BY
	rp.product_id,
	rp.product_category_name,
	rp.product_name_length,
	rp.product_description_length,
	rp.product_photos_qty
)
SELECT
	metadata_status,
	ROUND(AVG(units_sold), 2) AS Avg_units_sold,
	COUNT(*) AS total_products
FROM
	products_sold
GROUP BY
	metadata_status;

-- What proportion of products in each group sold only 1–3 units?

WITH products_sold AS
(
SELECT
	rp.product_id AS product,
	(CASE
		 WHEN (((rp.product_category_name IS NULL) OR (rp.product_category_name = ''))
		  AND ((rp.product_name_length IS NULL) OR (rp.product_name_length = ''))
		  AND ((rp.product_description_length IS NULL) OR (rp.product_description_length = ''))
		  AND ((rp.product_photos_qty IS NULL) OR (rp.product_photos_qty = '')))
		 THEN 'Missing'
		 ELSE 'Complete'
	END) AS metadata_status,
	COUNT(roi.product_id) AS units_sold
FROM
	"RAW"."RAW - Order Items" roi LEFT JOIN "RAW"."RAW - Products" rp
										ON roi.product_id = rp.product_id
GROUP BY
	rp.product_id,
	rp.product_category_name,
	rp.product_name_length,
	rp.product_description_length,
	rp.product_photos_qty
)
SELECT
	metadata_status,
	(COUNT(product) FILTER(WHERE units_sold <= 3)) AS "Products with Units 1-3 Sold",
	(COUNT(product)) AS total_products,
	((ROUND(((((COUNT(product) FILTER(WHERE units_sold <= 3)) :: NUMERIC) / ((COUNT(product)) :: NUMERIC)) * 100), 2))||'%') AS pct
FROM
	products_sold
GROUP BY
	metadata_status
ORDER BY
	metadata_status ASC;










------------------------------------------------------------------------------------------------------------------------------------------------

										-- Sellers Table Validation --

-- Checking total rows: 

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Sellers";

-- Checking for exact duplicate rows:

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Sellers"
GROUP BY
	seller_id,
	seller_zip_code_prefix,
	seller_city,
	seller_state
				HAVING
						COUNT(*) > 1;

-- Any NULL/Blank values in seller_id?

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Sellers"
WHERE
	seller_id IS NULL
	OR
	seller_id = '';

-- Any duplicates in seller_id?

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Sellers"
GROUP BY
	seller_id
			HAVING
					COUNT(*) > 1;

-- Any NULL/Blank values in seller_zip_code_prefix?

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Sellers"
WHERE
	seller_zip_code_prefix IS NULL
	OR
	seller_zip_code_prefix = '';

-- Any NULL/Blank/Numeric values in seller_city?

SELECT
	*
FROM
	"RAW"."RAW - Sellers"
WHERE
	seller_city IS NULL
	OR
	seller_city = ''
	OR
	seller_city ~ '\d';

-- Any NULL/Blank values in seller_state?

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Sellers"
WHERE
	seller_state IS NULL
	OR
	seller_state = '';

-- Any invalid format in seller_zip_code_prefix?

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Sellers"
WHERE
	seller_zip_code_prefix !~'^\d+$'
	OR
	LENGTH(seller_zip_code_prefix) <> 5;

-- Any invalid format in seller_state?

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Sellers"
WHERE
	seller_state NOT IN ('AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO',
						 'MA', 'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 
						 'RJ', 'RN', 'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO')

-- Do any Seller ZIP prefixes fail to appear in Geolocation?

SELECT
	*
FROM
	"RAW"."RAW - Sellers" rs LEFT JOIN "RAW"."RAW - Geolocation" rg
									ON rs.seller_zip_code_prefix = rg.geolocation_zip_code_prefix
WHERE
	rg.geolocation_zip_code_prefix IS NULL
	OR
	rg.geolocation_zip_code_prefix = '';

-- Does any seller ZIP map to a Geolocation state different from the seller’s recorded state?

SELECT
	rs.seller_id,
	rs.seller_zip_code_prefix AS zip_sell,
	rg.geolocation_zip_code_prefix AS zip_geo,
	rs. seller_state AS sell_state,
	rg.geolocation_state AS geo_state
FROM
	"RAW"."RAW - Sellers" rs LEFT JOIN "RAW"."RAW - Geolocation" rg
									ON rs.seller_zip_code_prefix = rg.geolocation_zip_code_prefix
WHERE
	((rg.geolocation_zip_code_prefix IS NOT NULL) AND (rg.geolocation_zip_code_prefix <> ''))
	AND
	rs.seller_state <> rg.geolocation_state
GROUP BY
	rs.seller_id,
	rs.seller_zip_code_prefix,
	rg.geolocation_zip_code_prefix,
	rs. seller_state,
	rg.geolocation_state;

-- For these Seller ZIP prefixes, does Geolocation consistently map that ZIP to one state, or does the ZIP itself appear under multiple states?

SELECT
	geolocation_zip_code_prefix AS zip,
	COUNT(DISTINCT(geolocation_state)) AS state_count,
	STRING_AGG(DISTINCT(geolocation_state), ', ') AS state_names
FROM
	"RAW"."RAW - Geolocation"
GROUP BY
	geolocation_zip_code_prefix
								HAVING
										COUNT(DISTINCT(geolocation_state)) > 1;

-- Find rows where Seller State ≠ Geolocation State AND that ZIP has only one DISTINCT state in Geolocation:

WITH one_state AS
(
SELECT
	geolocation_zip_code_prefix AS zip,
	MIN(geolocation_state) AS geo_state
FROM
	"RAW"."RAW - Geolocation"
GROUP BY
	geolocation_zip_code_prefix
								HAVING
										COUNT(DISTINCT(geolocation_state)) = 1
)
SELECT
	rs.seller_id,
	rs.seller_zip_code_prefix,
	os.zip,
	rs.seller_state,
	os.geo_state
FROM
	"RAW"."RAW - Sellers" rs LEFT JOIN one_state os
									ON rs.seller_zip_code_prefix = os.zip
WHERE
	((os.zip IS NOT NULL) AND (os.zip <> ''))
	AND
	rs.seller_state <> os.geo_state
GROUP BY
	rs.seller_id,
	rs.seller_zip_code_prefix,
	os.zip,
	rs.seller_state,
	os.geo_state;

-- For each Seller ZIP, does the Seller city appear among the distinct city values recorded for that ZIP in Geolocation?

SELECT
	seller_zip_code_prefix AS seller_zip,
	geolocation_zip_code_prefix AS geo_zip,
	seller_city,
	geolocation_city,
	(CASE
		WHEN seller_city = geolocation_city THEN 'True'
		ELSE 'False'
	END) AS city_match
FROM
	"RAW"."RAW - Sellers" rs LEFT JOIN "RAW"."RAW - Geolocation" rg
									ON rs.seller_zip_code_prefix = rg.geolocation_zip_code_prefix
WHERE
	(CASE
		WHEN seller_city = geolocation_city THEN 'True'
		ELSE 'False'
	END) = 'False'
GROUP BY
	seller_zip_code_prefix,
	geolocation_zip_code_prefix,
	seller_city,
	geolocation_city
ORDER BY
	seller_zip_code_prefix DESC;

-- Above query optimised even further for better answer:

SELECT
	rs.seller_id,
	rs.seller_zip_code_prefix,
	rs.seller_city
FROM
	"RAW"."RAW - Sellers" rs
WHERE
	EXISTS
		(
		SELECT
			1
		FROM
			"RAW"."RAW - Geolocation" rg
		WHERE
			rg.geolocation_zip_code_prefix = rs.seller_zip_code_prefix
		)
	AND
	NOT EXISTS
		(
		SELECT
			1
		FROM
			"RAW"."RAW - Geolocation" rg
		WHERE
			(rg.geolocation_zip_code_prefix = rs.seller_zip_code_prefix)
			AND
			(rg.geolocation_city = rs.seller_city)
		);

-- Further exploration the mismatches:

SELECT
	srs.seller_id,
	srs.seller_zip_code_prefix,
	rg.geolocation_zip_code_prefix,
	srs.seller_city,
	rg.geolocation_city
FROM
	(
	SELECT
		rs.seller_id,
		rs.seller_zip_code_prefix,
		rs.seller_city
	FROM
		"RAW"."RAW - Sellers" rs
	WHERE
		EXISTS
			(
			SELECT
				1
			FROM
				"RAW"."RAW - Geolocation" rg
			WHERE
				rg.geolocation_zip_code_prefix = rs.seller_zip_code_prefix
			)
		AND
		NOT EXISTS
			(
			SELECT
				1
			FROM
				"RAW"."RAW - Geolocation" rg
			WHERE
				(rg.geolocation_zip_code_prefix = rs.seller_zip_code_prefix)
				AND
				(rg.geolocation_city = rs.seller_city)
			)
		) AS srs
				LEFT JOIN "RAW"."RAW - Geolocation" rg
						ON srs.seller_zip_code_prefix = rg.geolocation_zip_code_prefix
GROUP BY
	srs.seller_id,
	srs.seller_zip_code_prefix,
	rg.geolocation_zip_code_prefix,
	srs.seller_city,
	rg.geolocation_city;

-- Coverage check for Sellers -> Order Items:

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Sellers" rs LEFT JOIN "RAW"."RAW - Order Items" roi
									ON rs.seller_id = roi.seller_id
WHERE
	roi.seller_id IS NULL
	OR
	roi.seller_id = '';

-- Coverage check for Order Items -> Sellers:

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Order Items" roi LEFT JOIN "RAW"."RAW - Sellers" rs
										ON roi.seller_id = rs.seller_id
WHERE
	rs.seller_id IS NULL
	OR
	rs.seller_id = '';

-- Verify cardinality of Sellers - Order Items:

SELECT
	rs.seller_id,
	COUNT(roi.order_id) AS total_order_items
FROM
	"RAW"."RAW - Sellers" rs LEFT JOIN "RAW"."RAW - Order Items" roi
									ON rs.seller_id = roi.seller_id
GROUP BY
	rs.seller_id
				HAVING
						COUNT(roi.order_id) > 1
ORDER BY
	total_order_items DESC;










------------------------------------------------------------------------------------------------------------------------------------------------

										-- Sellers Table Validation --

-- Checking total rows: 

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Product Category Name Translation";

-- Any exact duplicate rows:

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Product Category Name Translation"
GROUP BY
	product_category_name,
	product_category_name_english
									HAVING
											COUNT(*) > 1;
									
-- Any NULL/Blanks for product_category_name?

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Product Category Name Translation"
WHERE
	product_category_name IS NULL
	OR
	product_category_name = '';

-- Any duplicates for product_category_name?

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Product Category Name Translation"
GROUP BY
	product_category_name
						HAVING
								COUNT(*) > 1;

-- Any NULL/Blanks for product_category_name_english?

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Product Category Name Translation"
WHERE
	product_category_name_english IS NULL
	OR
	product_category_name_english = '';

-- Any duplicates for product_category_name_english?

SELECT
	COUNT(*)
FROM
	"RAW"."RAW - Product Category Name Translation"
GROUP BY
	product_category_name_english
									HAVING
											COUNT(*) > 1;










-----------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------




											"STAGING/CLEANING STAGE"




------------------------------------------------------------------------------------------------------------------------------------------------

										-- Customer Table Staging/Cleaning --

-- stage.customers Table creation:

CREATE TABLE stage.customers
(
	customer_id TEXT PRIMARY KEY,
	customer_unique_id TEXT NOT NULL CHECK(customer_unique_id <> ''),
	customer_zip_code_prefix TEXT NOT NULL CHECK((LENGTH(customer_zip_code_prefix) = 5) AND (customer_zip_code_prefix ~ '^[0-9]{5}$')),
	customer_city TEXT NOT NULL CHECK(customer_city <> ''),
	customer_state TEXT NOT NULL CHECK(customer_state IN ('AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO',
														  'MA', 'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 
														  'RJ', 'RN', 'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO'))
)

-- Insertion of Data into stage.customers Table:

INSERT INTO stage.customers
(
	customer_id,
	customer_unique_id,
	customer_zip_code_prefix,
	customer_city,
	customer_state
)
SELECT
	customer_id,
	customer_unique_id,
	customer_zip_code_prefix,
	customer_city,
	customer_state
FROM
	"RAW"."RAW - Customer"

SELECT
	*
FROM
	stage.customers

-- Clean customer post-transformation validation (ensure nothing went wrong):

SELECT
	COUNT(rc.*) AS raw_count,
	COUNT(sc.*) AS clean_count
FROM
	stage.customers sc FULL OUTER JOIN "RAW"."RAW - Customer" rc
									ON sc.customer_id = rc.customer_id;
--------------------
SELECT
	sc.customer_id,
	rc.customer_id
FROM
	stage.customers sc RIGHT JOIN "RAW"."RAW - Customer" rc
							ON sc.customer_id = rc.customer_id
WHERE
	sc.customer_id IS NULL
	OR
	sc.customer_id = '';
--------------------
SELECT
	sc.customer_id,
	rc.customer_id
FROM
	stage.customers sc LEFT JOIN "RAW"."RAW - Customer" rc
							ON sc.customer_id = rc.customer_id
WHERE
	rc.customer_id IS NULL
	OR
	rc.customer_id = '';
--------------------
SELECT
	sc.customer_id,
	rc.customer_id
FROM
	stage.customers sc LEFT JOIN "RAW"."RAW - Customer" rc
							ON sc.customer_id = rc.customer_id
WHERE
	(sc.customer_unique_id <> rc.customer_unique_id) OR
	(sc.customer_zip_code_prefix <> rc.customer_zip_code_prefix) OR
	(sc.customer_city <> rc.customer_city) OR
	(sc.customer_state <> rc.customer_state);










------------------------------------------------------------------------------------------------------------------------------------------------

										-- Orders Table Staging/Cleaning --

-- stage.orders Table creation:

CREATE TABLE stage.orders
(
	order_id TEXT PRIMARY KEY,
	customer_id TEXT NOT NULL CHECK(customer_id <> '') REFERENCES stage.customers(customer_id),
	order_status TEXT NOT NULL CHECK(order_status IN ('delivered', 'shipped', 'canceled', 'unavailable', 
													  'invoiced', 'processing', 'created', 'approved')),
	order_purchase_timestamp TIMESTAMP NOT NULL,
	order_approved_at TIMESTAMP,
	order_delivered_carrier_date TIMESTAMP,
	order_delivered_customer_date TIMESTAMP,
	order_estimated_delivery_date DATE NOT NULL
);

-- Insertion of Data into stage.orders Table:

INSERT INTO stage.orders 
(
	order_id,
	customer_id,
	order_status,
	order_purchase_timestamp,
	order_approved_at,
	order_delivered_carrier_date,
	order_delivered_customer_date,
	order_estimated_delivery_date
)
SELECT
	order_id,
	customer_id,
	order_status,
	order_purchase_timestamp :: TIMESTAMP,
	order_approved_at :: TIMESTAMP,
	order_delivered_carrier_date :: TIMESTAMP,
	order_delivered_customer_date :: TIMESTAMP,
	order_estimated_delivery_date :: DATE
FROM
	"RAW"."RAW - Orders";

-- Clean orders post-transformation validation (ensure nothing went wrong):

SELECT
	COUNT(ro.*) AS raw_count,
	 COUNT(so.*) AS clean_count
FROM
	stage.orders so FULL OUTER JOIN "RAW"."RAW - Orders" ro
								ON so.order_id = ro.order_id;
--------------------
SELECT
	so.order_id,
	ro.order_id
FROM
	stage.orders so LEFT JOIN "RAW"."RAW - Orders" ro
							ON so.order_id = ro.order_id
WHERE
	ro.order_id IS NULL
	OR
	ro.order_id = '';
--------------------
SELECT
	so.order_id,
	ro.order_id
FROM
	stage.orders so RIGHT JOIN "RAW"."RAW - Orders" ro
							ON so.order_id = ro.order_id
WHERE
	so.order_id IS NULL
	OR
	so.order_id = '';
--------------------
SELECT
	so.order_id,
	ro.order_id
FROM
	stage.orders so LEFT JOIN "RAW"."RAW - Orders" ro
							ON so.order_id = ro.order_id
WHERE
	(so.customer_id IS DISTINCT FROM ro.customer_id) OR
	(so.order_status IS DISTINCT FROM ro.order_status) OR
	(so.order_purchase_timestamp IS DISTINCT FROM (ro.order_purchase_timestamp :: TIMESTAMP)) OR
	(so.order_approved_at IS DISTINCT FROM (ro.order_approved_at :: TIMESTAMP)) OR
	(so.order_delivered_carrier_date IS DISTINCT FROM (ro.order_delivered_carrier_date :: TIMESTAMP)) OR
	(so.order_delivered_customer_date IS DISTINCT FROM (ro.order_delivered_customer_date :: TIMESTAMP)) OR
	(so.order_estimated_delivery_date IS DISTINCT FROM (ro.order_estimated_delivery_date :: DATE));
--------------------
SELECT
	COUNT(*) FILTER(WHERE order_approved_at IS NULL) AS approved_null,
	COUNT(*) FILTER(WHERE order_delivered_carrier_date IS NULL) AS carrier_null,
	COUNT(*) FILTER(WHERE order_delivered_customer_date IS NULL) AS customer_null
FROM
	stage.orders;










------------------------------------------------------------------------------------------------------------------------------------------------

										-- Order Items Table Staging/Cleaning --

-- stage.order_items Table creation:

CREATE TABLE stage.order_items
(
	order_id TEXT NOT NULL REFERENCES stage.orders(order_id),
	order_item_id INTEGER NOT NULL CHECK(order_item_id > 0),
	product_id TEXT NOT NULL CHECK(product_id <> ''),
	seller_id TEXT NOT NULL CHECK(seller_id <> ''),
	shipping_limit_date TIMESTAMP NOT NULL,
	price NUMERIC NOT NULL CHECK(price > 0),
	freight_value NUMERIC NOT NULL CHECK(freight_value >= 0),
	PRIMARY KEY (order_id, order_item_id)
);

-- Insertion of Data into stage.order_items Table:

INSERT INTO stage.order_items
(
	order_id,
	order_item_id,
	product_id,
	seller_id,
	shipping_limit_date,
	price,
	freight_value
)
SELECT
	order_id,
	order_item_id :: INTEGER,
	product_id,
	seller_id,
	shipping_limit_date :: TIMESTAMP,
	price :: NUMERIC,
	freight_value :: NUMERIC
FROM
	"RAW"."RAW - Order Items";

-- Clean orders_items post-transformation validation (ensure nothing went wrong):

SELECT
	COUNT(roi.*) AS raw_count,
	COUNT(soi.*) AS clean_count
FROM
	stage.order_items soi FULL OUTER JOIN "RAW"."RAW - Order Items" roi
										ON (soi.order_id = roi.order_id)
										AND (soi.order_item_id = (roi.order_item_id :: INTEGER));
--------------------
SELECT
	soi.order_id||'.'||soi.order_item_id AS composite_key,
	roi.order_id||'.'||roi.order_item_id AS raw_comp_key
FROM
	stage.order_items soi LEFT JOIN "RAW"."RAW - Order Items" roi
								ON (soi.order_id = roi.order_id)
								AND (soi.order_item_id = (roi.order_item_id :: INTEGER))
WHERE
	((roi.order_id IS NULL) OR (roi.order_item_id IS NULL))
	OR
	((roi.order_id = '') OR (roi.order_item_id = ''));
--------------------
SELECT
	soi.order_id||'.'||soi.order_item_id AS composite_key,
	roi.order_id||'.'||roi.order_item_id AS raw_comp_key
FROM
	stage.order_items soi RIGHT JOIN "RAW"."RAW - Order Items" roi
								ON (soi.order_id = roi.order_id)
								AND (soi.order_item_id = (roi.order_item_id :: INTEGER))
WHERE
	((soi.order_id IS NULL) OR (soi.order_item_id IS NULL))
	OR
	(soi.order_id = '');
--------------------
SELECT
	soi.order_id||'.'||soi.order_item_id AS composite_key,
	roi.order_id||'.'||roi.order_item_id AS raw_comp_key
FROM
	stage.order_items soi LEFT JOIN "RAW"."RAW - Order Items" roi
								ON (soi.order_id = roi.order_id)
								AND (soi.order_item_id = (roi.order_item_id :: INTEGER))
WHERE
	(soi.product_id IS DISTINCT FROM roi.product_id) OR
	(soi.seller_id IS DISTINCT FROM roi.seller_id) OR
	(soi.shipping_limit_date IS DISTINCT FROM roi.shipping_limit_date :: TIMESTAMP) OR
	(soi.price IS DISTINCT FROM roi.price :: NUMERIC) OR
	(soi.freight_value IS DISTINCT FROM roi.freight_value :: NUMERIC);

-- Alter stage.order_items to input foreign key against newly created stage.products Table:

ALTER TABLE stage.order_items
ADD CONSTRAINT fk_order_items_products
FOREIGN KEY (product_id)
REFERENCES stage.products(product_id);

-- Alter stage.order_items to input foreign key against newly created stage.sellers Table:

ALTER TABLE stage.order_items
ADD CONSTRAINT fk_order_items_sellers
FOREIGN KEY (seller_id)
REFERENCES stage.sellers(seller_id);










------------------------------------------------------------------------------------------------------------------------------------------------

										-- Payments Table Staging/Cleaning --

-- stage.payments Table creation:

CREATE TABLE stage.payments
(
	order_id TEXT NOT NULL REFERENCES stage.orders(order_id),
	payment_sequential INTEGER NOT NULL CHECK(payment_sequential > 0),
	payment_type TEXT NOT NULL CHECK(payment_type <> '') CHECK(payment_type IN ('credit_card', 'boleto',
																				'voucher', 'debit_card',
																				'not_defined')),
	payment_installments INTEGER NOT NULL CHECK(payment_installments >= 0),
	payment_value NUMERIC NOT NULL CHECK(payment_value >= 0),
	PRIMARY KEY (order_id, payment_sequential)
);

-- Insertion of Data into stage.payments Table:

INSERT INTO stage.payments
(
	order_id,
	payment_sequential,
	payment_type,
	payment_installments,
	payment_value
)
SELECT
	order_id,
	payment_sequential :: INTEGER,
	payment_type,
	payment_installments :: INTEGER,
	payment_value :: NUMERIC
FROM
	"RAW"."RAW - Payments";

-- Clean payments post-transformation validation (ensure nothing went wrong):

SELECT
	COUNT(sp.*) AS clean_count,
	COUNT(rp.*) AS raw_count
FROM
	stage.payments sp FULL OUTER JOIN "RAW"."RAW - Payments" rp
									ON (sp.order_id = rp.order_id)
									AND (sp.payment_sequential = (rp.payment_sequential :: INTEGER));
--------------------
SELECT
	sp.order_id||'.'||sp.payment_sequential AS composite_key,
	rp.order_id||'.'||rp.payment_sequential AS raw_comp_key
FROM
	stage.payments sp LEFT JOIN "RAW"."RAW - Payments" rp
									ON (sp.order_id = rp.order_id)
									AND (sp.payment_sequential = (rp.payment_sequential :: INTEGER))
WHERE
	((rp.order_id IS NULL) OR (rp.order_id = ''))
	OR
	((rp.payment_sequential IS NULL) OR (rp.payment_sequential = ''));
--------------------
SELECT
	sp.order_id||'.'||sp.payment_sequential AS composite_key,
	rp.order_id||'.'||rp.payment_sequential AS raw_comp_key
FROM
	stage.payments sp RIGHT JOIN "RAW"."RAW - Payments" rp
									ON (sp.order_id = rp.order_id)
									AND (sp.payment_sequential = (rp.payment_sequential :: INTEGER))
WHERE
	((sp.order_id IS NULL) OR (sp.order_id = ''))
	OR
	(sp.payment_sequential IS NULL);
--------------------
SELECT
	sp.order_id||'.'||sp.payment_sequential AS composite_key,
	rp.order_id||'.'||rp.payment_sequential AS raw_comp_key
FROM
	stage.payments sp LEFT JOIN "RAW"."RAW - Payments" rp
									ON (sp.order_id = rp.order_id)
									AND (sp.payment_sequential = (rp.payment_sequential :: INTEGER))
WHERE
	(sp.payment_type IS DISTINCT FROM rp.payment_type) OR
	(sp.payment_installments IS DISTINCT FROM (rp.payment_installments :: INTEGER)) OR
	(sp.payment_value IS DISTINCT FROM (rp.payment_value :: NUMERIC));










------------------------------------------------------------------------------------------------------------------------------------------------

										-- Reviews Table Staging/Cleaning --

-- stage.reviews Table creation:

CREATE TABLE stage.reviews
(
	review_id TEXT NOT NULL,
	order_id TEXT NOT NULL REFERENCES stage.orders(order_id),
	review_score INTEGER NOT NULL CHECK(review_score BETWEEN 1 AND 5),
	review_comment_title TEXT,
	review_comment_message TEXT,
	review_creation_date DATE NOT NULL,
	review_answer_timestamp TIMESTAMP NOT NULL,
	PRIMARY KEY (review_id, order_id)
);

-- Insertion of Data into stage.reviews Table:

INSERT INTO stage.reviews
(
	review_id,
	order_id,
	review_score,
	review_comment_title,
	review_comment_message,
	review_creation_date,
	review_answer_timestamp
)
SELECT
	review_id,
	order_id,
	review_score :: INTEGER,
	review_comment_title,
	review_comment_message,
	review_creation_date :: DATE,
	review_answer_timestamp :: TIMESTAMP
FROM
	"RAW"."RAW - Reviews";

-- Clean reviews post-transformation validation (ensure nothing went wrong):

SELECT
	COUNT(sr.*) AS clean_review,
	COUNT(rr.*) AS raw_review
FROM
	stage.reviews sr FULL OUTER JOIN "RAW"."RAW - Reviews" rr
								ON (sr.review_id = rr.review_id)
								AND (sr.order_id = rr.order_id);
--------------------
SELECT
	(sr.review_id||'.'||sr.order_id) AS composite_key,
	(rr.review_id||'.'||rr.order_id) AS raw_comp_key
FROM
	stage.reviews sr LEFT JOIN "RAW"."RAW - Reviews" rr
								ON (sr.review_id = rr.review_id)
								AND (sr.order_id = rr.order_id)
WHERE
	((rr.review_id IS NULL) OR (rr.review_id = ''))
	OR
	((rr.order_id IS NULL) OR (rr.order_id = ''));
--------------------
SELECT
	(sr.review_id||'.'||sr.order_id) AS composite_key,
	(rr.review_id||'.'||rr.order_id) AS raw_comp_key
FROM
	stage.reviews sr RIGHT JOIN "RAW"."RAW - Reviews" rr
								ON (sr.review_id = rr.review_id)
								AND (sr.order_id = rr.order_id)
WHERE
	((sr.review_id IS NULL) OR (sr.review_id = ''))
	OR
	((sr.order_id IS NULL) OR (sr.order_id = ''));
--------------------
SELECT
	(sr.review_id||'.'||sr.order_id) AS composite_key,
	(rr.review_id||'.'||rr.order_id) AS raw_comp_key
FROM
	stage.reviews sr RIGHT JOIN "RAW"."RAW - Reviews" rr
								ON (sr.review_id = rr.review_id)
								AND (sr.order_id = rr.order_id)
WHERE
	(sr.review_score IS DISTINCT FROM (rr.review_score :: INTEGER)) OR
	(sr.review_comment_title IS DISTINCT FROM rr.review_comment_title) OR
	(sr.review_comment_message IS DISTINCT FROM rr.review_comment_message) OR
	(sr.review_creation_date IS DISTINCT FROM (rr.review_creation_date :: DATE)) OR
	(sr.review_answer_timestamp IS DISTINCT FROM (rr.review_answer_timestamp :: TIMESTAMP));



















------------------------------------------------------------------------------------------------------------------------------------------------

										-- Products Table Staging/Cleaning --

-- stage.products Table creation:

CREATE TABLE stage.products
(
	product_id TEXT NOT NULL PRIMARY KEY,
	product_category_name TEXT,
	product_name_length INTEGER CHECK(product_name_length > 0),
	product_description_length INTEGER CHECK(product_description_length > 0),
	product_photos_qty INTEGER CHECK(product_photos_qty > 0),
	product_weight_g NUMERIC CHECK(product_weight_g >= 0),
	product_length_cm NUMERIC CHECK(product_length_cm > 0),
	product_height_cm NUMERIC CHECK(product_height_cm > 0),
	product_width_cm NUMERIC CHECK(product_width_cm > 0)
);

-- Insertion of Data into stage.products Table:

INSERT INTO stage.products
(
	product_id,
	product_category_name,
	product_name_length,
	product_description_length,
	product_photos_qty,
	product_weight_g,
	product_length_cm,
	product_height_cm,
	product_width_cm
)
SELECT
	product_id,
	product_category_name,
	product_name_length :: INTEGER,
	product_description_length :: INTEGER,
	product_photos_qty :: INTEGER,
	product_weight_g :: NUMERIC,
	product_length_cm :: NUMERIC,
	product_height_cm :: NUMERIC,
	product_width_cm :: NUMERIC
FROM
	"RAW"."RAW - Products";

-- Clean products post-transformation validation (ensure nothing went wrong):

SELECT
	COUNT(sp.*) AS clean_products,
	COUNT(rp.*) AS raw_products
FROM
	stage.products sp FULL OUTER JOIN "RAW"."RAW - Products" rp
									ON sp.product_id = rp.product_id;
--------------------
SELECT
	sp.product_id,
	rp.product_id
FROM
	stage.products sp LEFT JOIN "RAW"."RAW - Products" rp
							ON sp.product_id = rp.product_id
WHERE
	rp.product_id IS NULL
	OR
	rp.product_id = '';
--------------------
SELECT
	sp.product_id,
	rp.product_id
FROM
	stage.products sp RIGHT JOIN "RAW"."RAW - Products" rp
							ON sp.product_id = rp.product_id
WHERE
	sp.product_id IS NULL
	OR
	sp.product_id = '';
--------------------
SELECT
	sp.product_id,
	rp.product_id
FROM
	stage.products sp LEFT JOIN "RAW"."RAW - Products" rp
							ON sp.product_id = rp.product_id
WHERE
	(sp.product_category_name IS DISTINCT FROM rp.product_category_name) OR
	(sp.product_name_length IS DISTINCT FROM (rp.product_name_length :: INTEGER)) OR
	(sp.product_description_length IS DISTINCT FROM (rp.product_description_length :: INTEGER)) OR
	(sp.product_photos_qty IS DISTINCT FROM (rp.product_photos_qty :: INTEGER)) OR
	(sp.product_weight_g IS DISTINCT FROM (rp.product_weight_g :: NUMERIC)) OR
	(sp.product_length_cm IS DISTINCT FROM (rp.product_length_cm :: NUMERIC)) OR
	(sp.product_height_cm IS DISTINCT FROM (rp.product_height_cm :: NUMERIC)) OR
	(sp.product_width_cm IS DISTINCT FROM (rp.product_width_cm :: NUMERIC));










------------------------------------------------------------------------------------------------------------------------------------------------

										-- Sellers Table Staging/Cleaning --

-- stage.sellers Table creation:

CREATE TABLE stage.sellers
(
	seller_id TEXT NOT NULL PRIMARY KEY,
	seller_zip_code_prefix TEXT NOT NULL CHECK((LENGTH(seller_zip_code_prefix) = 5) AND (seller_zip_code_prefix ~ '^[0-9]{5}$')),
	seller_city TEXT NOT NULL CHECK(seller_city <> ''),
	seller_state TEXT NOT NULL CHECK(seller_state IN ('AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO',
													  'MA', 'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 
													  'RJ', 'RN', 'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO'))
);

-- Insertion of Data into stage.sellers Table:

INSERT INTO stage.sellers
(
	seller_id,
	seller_zip_code_prefix,
	seller_city,
	seller_state
)
SELECT
	seller_id,
	seller_zip_code_prefix,
	seller_city,
	seller_state
FROM
	"RAW"."RAW - Sellers";

-- Clean sellers post-transformation validation (ensure nothing went wrong):

SELECT
	COUNT(ss.*) AS clean_sellers,
	COUNT(rs.*) AS raw_sellers
FROM
	stage.sellers ss FULL OUTER JOIN "RAW"."RAW - Sellers" rs
								ON ss.seller_id = rs.seller_id;
--------------------
SELECT
	ss.seller_id AS clean_sellers,
	rs.seller_id AS raw_sellers
FROM
	stage.sellers ss LEFT JOIN "RAW"."RAW - Sellers" rs
							ON ss.seller_id = rs.seller_id
WHERE
	rs.seller_id IS NULL
	OR
	rs.seller_id = '';
--------------------
SELECT
	ss.seller_id AS clean_sellers,
	rs.seller_id AS raw_sellers
FROM
	stage.sellers ss RIGHT JOIN "RAW"."RAW - Sellers" rs
							ON ss.seller_id = rs.seller_id
WHERE
	ss.seller_id IS NULL
	OR
	ss.seller_id = '';
--------------------
SELECT
	ss.seller_id AS clean_sellers,
	rs.seller_id AS raw_sellers
FROM
	stage.sellers ss LEFT JOIN "RAW"."RAW - Sellers" rs
							ON ss.seller_id = rs.seller_id
WHERE
	(ss.seller_zip_code_prefix IS DISTINCT FROM rs.seller_zip_code_prefix) OR
	(ss.seller_city IS DISTINCT FROM rs.seller_city) OR
	(ss.seller_state IS DISTINCT FROM rs.seller_state);










------------------------------------------------------------------------------------------------------------------------------------------------

										-- Geolocation Table Staging/Cleaning --

-- stage.geolocation Table creation:

CREATE TABLE stage.geolocation
(
	geolocation_zip_code_prefix TEXT NOT NULL PRIMARY KEY,
	geolocation_lat DOUBLE PRECISION NOT NULL CHECK(geolocation_lat BETWEEN -90 AND 90),
	geolocation_lng DOUBLE PRECISION NOT NULL CHECK(geolocation_lng BETWEEN -180 AND 180),
	geolocation_city TEXT NOT NULL CHECK(geolocation_city <> ''),
	geolocation_state TEXT NOT NULL CHECK(geolocation_state IN ('AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO',
															 	'MA', 'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 
																'RJ', 'RN', 'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO')) 
);

-- ZIP-level aggregation + Insertion of Data into stage.geolocation Table:

INSERT INTO stage.geolocation
(
	geolocation_zip_code_prefix,
	geolocation_lat,
	geolocation_lng,
	geolocation_city,
	geolocation_state
)
WITH deduplication AS
(
SELECT
	DISTINCT
			geolocation_zip_code_prefix AS geo_zip,
			(geolocation_lat :: NUMERIC) AS geo_lat,
			(geolocation_lng :: NUMERIC) AS geo_lng
FROM
	"RAW"."RAW - Geolocation"
),
coordinates AS
(
SELECT
	geo_zip,
	(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY geo_lat)) AS median_lat,
	(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY geo_lng)) AS median_lng
FROM
	deduplication
GROUP BY
	geo_zip
),
city_frq AS
(
SELECT
	geolocation_zip_code_prefix,
	geolocation_city,
	COUNT(geolocation_city) AS city_frequency
FROM
	"RAW"."RAW - Geolocation"
GROUP BY
	geolocation_zip_code_prefix,
	geolocation_city
),
city_ranked AS
(
SELECT
	geolocation_zip_code_prefix,
	geolocation_city,
	city_frequency,
	ROW_NUMBER() OVER
		(
		PARTITION BY geolocation_zip_code_prefix
		ORDER BY city_frequency DESC, geolocation_city ASC
		) AS city_rank
FROM
	city_frq
),
state_frq AS
(
SELECT
	geolocation_zip_code_prefix,
	geolocation_state,
	COUNT(geolocation_state) AS state_frequency
FROM
	"RAW"."RAW - Geolocation"
GROUP BY
	geolocation_zip_code_prefix,
	geolocation_state
),
state_ranked AS
(
SELECT
	geolocation_zip_code_prefix,
	geolocation_state,
	state_frequency,
	ROW_NUMBER() OVER
		(
		PARTITION BY geolocation_zip_code_prefix
		ORDER BY state_frequency DESC, geolocation_state ASC
		) AS state_rank
FROM
	state_frq
)
SELECT
	cr.geolocation_zip_code_prefix,
	c.median_lat,
	c.median_lng,
	cr.geolocation_city,
	sr.geolocation_state
FROM
	city_ranked cr INNER JOIN coordinates c ON cr.geolocation_zip_code_prefix = c.geo_zip
				   INNER JOIN state_ranked sr ON c.geo_zip = sr.geolocation_zip_code_prefix
WHERE
	cr.city_rank = 1
	AND
	sr.state_rank = 1;

-- Clean geolocation post-transformation validation (ensure nothing went wrong):

SELECT
    (SELECT COUNT(DISTINCT geolocation_zip_code_prefix)
     FROM "RAW"."RAW - Geolocation") AS dist_raw_zip,
    (SELECT COUNT(*)
     FROM stage.geolocation) AS stage_rows;
--------------------
SELECT
	DISTINCT
			sg.geolocation_zip_code_prefix,
			rg.geolocation_zip_code_prefix
FROM
	stage.geolocation sg LEFT JOIN "RAW"."RAW - Geolocation" rg
								ON sg.geolocation_zip_code_prefix = rg.geolocation_zip_code_prefix
WHERE
	rg.geolocation_zip_code_prefix IS NULL
	OR
	rg.geolocation_zip_code_prefix = '';
--------------------
SELECT
	DISTINCT
			sg.geolocation_zip_code_prefix,
			rg.geolocation_zip_code_prefix
FROM
	stage.geolocation sg RIGHT JOIN "RAW"."RAW - Geolocation" rg
								ON sg.geolocation_zip_code_prefix = rg.geolocation_zip_code_prefix
WHERE
	sg.geolocation_zip_code_prefix IS NULL
	OR
	sg.geolocation_zip_code_prefix = '';
--------------------
WITH deduplication AS
(
SELECT
	DISTINCT
			geolocation_zip_code_prefix AS geo_zip,
			(geolocation_lat :: NUMERIC) AS geo_lat,
			(geolocation_lng :: NUMERIC) AS geo_lng
FROM
	"RAW"."RAW - Geolocation"
),
coordinates AS
(
SELECT
	geo_zip,
	(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY geo_lat)) AS median_lat,
	(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY geo_lng)) AS median_lng
FROM
	deduplication
GROUP BY
	geo_zip
),
city_frq AS
(
SELECT
	geolocation_zip_code_prefix,
	geolocation_city,
	COUNT(geolocation_city) AS city_frequency
FROM
	"RAW"."RAW - Geolocation"
GROUP BY
	geolocation_zip_code_prefix,
	geolocation_city
),
city_ranked AS
(
SELECT
	geolocation_zip_code_prefix,
	geolocation_city,
	city_frequency,
	ROW_NUMBER() OVER
		(
		PARTITION BY geolocation_zip_code_prefix
		ORDER BY city_frequency DESC, geolocation_city ASC
		) AS city_rank
FROM
	city_frq
),
state_frq AS
(
SELECT
	geolocation_zip_code_prefix,
	geolocation_state,
	COUNT(geolocation_state) AS state_frequency
FROM
	"RAW"."RAW - Geolocation"
GROUP BY
	geolocation_zip_code_prefix,
	geolocation_state
),
state_ranked AS
(
SELECT
	geolocation_zip_code_prefix,
	geolocation_state,
	state_frequency,
	ROW_NUMBER() OVER
		(
		PARTITION BY geolocation_zip_code_prefix
		ORDER BY state_frequency DESC, geolocation_state ASC
		) AS state_rank
FROM
	state_frq
),
expected_geolocation AS
(
SELECT
	cr.geolocation_zip_code_prefix AS prefix,
	c.median_lat AS med_lat,
	c.median_lng AS med_lng,
	cr.geolocation_city AS geo_city,
	sr.geolocation_state AS geo_state
FROM
	city_ranked cr INNER JOIN coordinates c ON cr.geolocation_zip_code_prefix = c.geo_zip
				   INNER JOIN state_ranked sr ON c.geo_zip = sr.geolocation_zip_code_prefix
WHERE
	cr.city_rank = 1
	AND
	sr.state_rank = 1
)
SELECT
	eg.prefix AS cte_prefix,
	sg.geolocation_zip_code_prefix AS new_prefix
FROM
	expected_geolocation eg LEFT JOIN stage.geolocation sg
						ON eg.prefix = sg.geolocation_zip_code_prefix
WHERE
	(eg.med_lat IS DISTINCT FROM sg.geolocation_lat) OR
	(eg.med_lng IS DISTINCT FROM sg.geolocation_lng) OR
	(eg.geo_city IS DISTINCT FROM sg.geolocation_city) OR
	(eg.geo_state IS DISTINCT FROM sg.geolocation_state);









------------------------------------------------------------------------------------------------------------------------------------------------

										-- Product Category Name Translation Table Staging/Cleaning --

-- stage.category_translation Table creation:

CREATE TABLE stage.product_category_name_translation
(
	product_category_name TEXT NOT NULL PRIMARY KEY CHECK(product_category_name <> ''),
	product_category_name_english TEXT NOT NULL CHECK(product_category_name_english <> '')
);

-- Insertion of Data into stage.product_category_name_translation Table:

INSERT INTO stage.product_category_name_translation
(
	product_category_name,
	product_category_name_english
)
SELECT
	product_category_name,
	product_category_name_english
FROM
	"RAW"."RAW - Product Category Name Translation";

-- Clean product_category_name_translation post-transformation validation (ensure nothing went wrong):

SELECT
	COUNT(spcnt.*) AS clean_count,
	COUNT(rpcnt.*) AS raw_count
FROM
	stage.product_category_name_translation spcnt FULL OUTER JOIN "RAW"."RAW - Product Category Name Translation" rpcnt
															ON spcnt.product_category_name = rpcnt.product_category_name;
--------------------
SELECT
	spcnt.product_category_name,
	rpcnt.product_category_name
FROM
	stage.product_category_name_translation spcnt LEFT JOIN "RAW"."RAW - Product Category Name Translation" rpcnt
														ON spcnt.product_category_name = rpcnt.product_category_name
WHERE
	rpcnt.product_category_name IS NULL
	OR
	rpcnt.product_category_name = '';
--------------------
SELECT
	spcnt.product_category_name,
	rpcnt.product_category_name
FROM
	stage.product_category_name_translation spcnt RIGHT JOIN "RAW"."RAW - Product Category Name Translation" rpcnt
														ON spcnt.product_category_name = rpcnt.product_category_name
WHERE
	spcnt.product_category_name IS NULL
	OR
	spcnt.product_category_name = '';
--------------------
SELECT
	spcnt.product_category_name,
	rpcnt.product_category_name
FROM
	stage.product_category_name_translation spcnt LEFT JOIN "RAW"."RAW - Product Category Name Translation" rpcnt
														ON spcnt.product_category_name = rpcnt.product_category_name
WHERE
	(spcnt.product_category_name_english IS DISTINCT FROM rpcnt.product_category_name_english);









-----------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------




											"MODELLING STAGE"




------------------------------------------------------------------------------------------------------------------------------------------------

										-- Products Analytics Table Creation --

-- dim_products Table creation:

CREATE TABLE analytics.dim_products
(
	product_id TEXT PRIMARY KEY,
	product_category_name TEXT,
	product_category_name_english TEXT,
	product_name_length INTEGER CHECK(product_name_length > 0),
	product_description_length INTEGER CHECK(product_description_length > 0),
	product_photos_qty INTEGER CHECK(product_photos_qty > 0),
	product_weight_g NUMERIC CHECK(product_weight_g >= 0),
	product_length_cm NUMERIC CHECK(product_length_cm > 0),
	product_height_cm NUMERIC CHECK(product_height_cm > 0),
	product_width_cm NUMERIC CHECK(product_width_cm > 0)
);

-- dim_products Data insertion:

INSERT INTO analytics.dim_products
(
	product_id,
	product_category_name,
	product_category_name_english,
	product_name_length,
	product_description_length,
	product_photos_qty,
	product_weight_g,
	product_length_cm,
	product_height_cm,
	product_width_cm
)
SELECT
	sp.product_id,
	sp.product_category_name,
	spcnt.product_category_name_english,
	sp.product_name_length,
	sp.product_description_length,
	sp.product_photos_qty,
	sp.product_weight_g,
	sp.product_length_cm,
	sp.product_height_cm,
	sp.product_width_cm
FROM
	stage.products sp LEFT JOIN stage.product_category_name_translation spcnt
							ON sp.product_category_name = spcnt.product_category_name;

-- Post Transformation QA:

SELECT
	(SELECT
		COUNT(*)
	FROM
		stage.products) AS stage_prod,
	(SELECT
		COUNT(*)
	FROM
		analytics.dim_products) AS analy_prod;
--------------------
SELECT
	sp.product_id
FROM
	stage.products sp LEFT JOIN analytics.dim_products dp
							ON sp.product_id = dp.product_id
WHERE
	dp.product_id IS NULL;
--------------------
SELECT
	dp.product_id
FROM
	stage.products sp RIGHT JOIN analytics.dim_products dp
							ON sp.product_id = dp.product_id
WHERE
	sp.product_id IS NULL;
--------------------
SELECT
	dp.product_id
FROM
	stage.products sp INNER JOIN analytics.dim_products dp
							ON sp.product_id = dp.product_id
WHERE
	(dp.product_category_name IS DISTINCT FROM sp.product_category_name) OR
	(dp.product_name_length IS DISTINCT FROM sp.product_name_length) OR
	(dp.product_description_length IS DISTINCT FROM sp.product_description_length) OR
	(dp.product_photos_qty IS DISTINCT FROM sp.product_photos_qty) OR
	(dp.product_weight_g IS DISTINCT FROM sp.product_weight_g) OR
	(dp.product_length_cm IS DISTINCT FROM sp.product_length_cm) OR
	(dp.product_height_cm IS DISTINCT FROM sp.product_height_cm) OR
	(dp.product_width_cm IS DISTINCT FROM sp.product_width_cm);
--------------------
SELECT
	dp.product_id,
	dp.product_category_name,
	dp.product_category_name_english AS translated_name,
	spcnt.product_category_name_english AS expected_translation
FROM
	analytics.dim_products dp LEFT JOIN stage.product_category_name_translation spcnt
									ON dp.product_category_name  = spcnt.product_category_name
WHERE
	dp.product_category_name_english IS DISTINCT FROM spcnt.product_category_name_english;










------------------------------------------------------------------------------------------------------------------------------------------------

										-- Customers Analytics Table Creation --

-- dim_customers Table creation:

CREATE TABLE analytics.dim_customers
(
	customer_id TEXT PRIMARY KEY,
	customer_unique_id TEXT NOT NULL CHECK(customer_unique_id <> ''),
	customer_zip_code_prefix TEXT NOT NULL CHECK(customer_zip_code_prefix ~'^[0-9]{5}$'),
	geolocation_lat DOUBLE PRECISION CHECK(geolocation_lat BETWEEN -90 AND 90),
	geolocation_lng DOUBLE PRECISION CHECK(geolocation_lng BETWEEN -180 AND 180),
	customer_city TEXT NOT NULL CHECK(customer_city <> ''),
	customer_state TEXT NOT NULL CHECK(customer_state IN ('AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO',
												 		  'MA', 'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 
												 		  'RJ', 'RN', 'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO'))
);

-- dim_customers Data insertion:

INSERT INTO analytics.dim_customers
(
	customer_id,
	customer_unique_id,
	customer_zip_code_prefix,
	geolocation_lat,
	geolocation_lng,
	customer_city,
	customer_state
)
SELECT
	sc.customer_id,
	sc.customer_unique_id,
	sc.customer_zip_code_prefix,
	sg.geolocation_lat,
	sg.geolocation_lng,
	sc.customer_city,
	sc.customer_state
FROM
	stage.customers sc LEFT JOIN stage.geolocation sg
							ON sc.customer_zip_code_prefix = sg.geolocation_zip_code_prefix;

-- Post Transformation QA:

SELECT
	(SELECT
		COUNT(*)
	FROM
		stage.customers) AS stage_count,
	(SELECT
		COUNT(*)
	FROM
		analytics.dim_customers) AS analy_count;
--------------------
SELECT
	dc.customer_id
FROM
	analytics.dim_customers dc LEFT JOIN stage.customers sc
									ON dc.customer_id = sc.customer_id
WHERE
	sc.customer_id IS NULL;
--------------------
SELECT
	sc.customer_id
FROM
	analytics.dim_customers dc RIGHT JOIN stage.customers sc
									ON dc.customer_id = sc.customer_id
WHERE
	dc.customer_id IS NULL;
--------------------
SELECT
	dc.customer_id
FROM
	analytics.dim_customers dc INNER JOIN stage.customers sc
										ON dc.customer_id = sc.customer_id
WHERE
	(dc.customer_unique_id IS DISTINCT FROM sc.customer_unique_id) OR
	(dc.customer_zip_code_prefix IS DISTINCT FROM sc.customer_zip_code_prefix) OR
	(dc.customer_city IS DISTINCT FROM sc.customer_city) OR
	(dc.customer_state IS DISTINCT FROM sc.customer_state);
--------------------
SELECT
	dc.customer_id,
	dc.customer_zip_code_prefix,
	dc.geolocation_lat AS inserted_lat,
	dc.geolocation_lng AS inserted_lng,
	sg.geolocation_lat AS expected_lat,
	sg.geolocation_lng AS expected_lng
FROM
	analytics.dim_customers dc LEFT JOIN stage.geolocation sg
									ON dc.customer_zip_code_prefix = sg.geolocation_zip_code_prefix
WHERE
	(dc.geolocation_lat IS DISTINCT FROM sg.geolocation_lat) OR
	(dc.geolocation_lng IS DISTINCT FROM sg.geolocation_lng);










------------------------------------------------------------------------------------------------------------------------------------------------

										-- Sellers Analytics Table Creation --

-- dim_sellers Table creation:

CREATE TABLE analytics.dim_sellers
(
	seller_id TEXT PRIMARY KEY,
	seller_zip_code_prefix TEXT NOT NULL CHECK(seller_zip_code_prefix ~'^[0-9]{5}$'),
	geolocation_lat DOUBLE PRECISION CHECK(geolocation_lat BETWEEN -90 AND 90),
	geolocation_lng DOUBLE PRECISION CHECK(geolocation_lng BETWEEN -180 AND 180),
	seller_city TEXT NOT NULL CHECK(seller_city <> ''),
	seller_state TEXT NOT NULL CHECK(seller_state IN ('AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO',
												 	  'MA', 'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 
												 	  'RJ', 'RN', 'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO'))
);

-- dim_sellers Data insertion:

INSERT INTO analytics.dim_sellers
(
	seller_id,
	seller_zip_code_prefix,
	geolocation_lat,
	geolocation_lng,
	seller_city,
	seller_state
)
SELECT
	ss.seller_id,
	ss.seller_zip_code_prefix,
	sg.geolocation_lat,
	sg.geolocation_lng,
	ss.seller_city,
	ss.seller_state
FROM
	stage.sellers ss LEFT JOIN stage.geolocation sg
									ON ss.seller_zip_code_prefix = sg.geolocation_zip_code_prefix;

-- Post Transformation QA:

SELECT
	(SELECT
		COUNT(*)
	FROM
		stage.sellers) AS stage_count,
	(SELECT
		COUNT(*)
	FROM
		analytics.dim_sellers) AS analy_count;
--------------------
SELECT
	ds.seller_id
FROM
	analytics.dim_sellers ds LEFT JOIN stage.sellers ss
									ON ds.seller_id = ss.seller_id
WHERE
	ss.seller_id IS NULL;
--------------------
SELECT
	ss.seller_id
FROM
	analytics.dim_sellers ds RIGHT JOIN stage.sellers ss
									ON ds.seller_id = ss.seller_id
WHERE
	ds.seller_id IS NULL;
--------------------
SELECT
	ds.seller_id
FROM
	analytics.dim_sellers ds INNER JOIN stage.sellers ss
									ON ds.seller_id = ss.seller_id
WHERE
	(ds.seller_zip_code_prefix IS DISTINCT FROM ss.seller_zip_code_prefix) OR
	(ds.seller_city IS DISTINCT FROM ss.seller_city) OR
	(ds.seller_state IS DISTINCT FROM ss.seller_state);
--------------------
SELECT
	ds.seller_id,
	ds.geolocation_lat AS inserted_lat,
	ds.geolocation_lng AS inserted_lng,
	sg.geolocation_lat AS expected_lat,
	sg.geolocation_lng AS expected_lng
FROM
	analytics.dim_sellers ds LEFT JOIN stage.geolocation sg
									ON ds.seller_zip_code_prefix = sg.geolocation_zip_code_prefix
WHERE
	(ds.geolocation_lat IS DISTINCT FROM sg.geolocation_lat) OR
	(ds.geolocation_lng IS DISTINCT FROM sg.geolocation_lng);










------------------------------------------------------------------------------------------------------------------------------------------------

										-- Dates Analytics Table Creation --

-- dim_dates Table creation; parameters exploration:

WITH master_date_table AS
(
	SELECT
		 order_purchase_timestamp AS master_date,
		 'order_purchase_timestamp' AS original_column_name
	FROM
		stage.orders
	WHERE
		order_purchase_timestamp IS NOT NULL
UNION ALL
	SELECT
		 order_approved_at,
		 'order_approved_at' AS original_column_name
	FROM
		stage.orders
	WHERE
		order_approved_at IS NOT NULL
UNION ALL
	SELECT
		 order_delivered_carrier_date,
		 'order_delivered_carrier_date' AS original_column_name
	FROM
		stage.orders
	WHERE
		order_delivered_carrier_date IS NOT NULL
UNION ALL
	SELECT
		 order_delivered_customer_date,
		 'order_delivered_customer_date' AS original_column_name
	FROM
		stage.orders
	WHERE
		order_delivered_customer_date IS NOT NULL
UNION ALL
	SELECT
		 order_estimated_delivery_date :: TIMESTAMP,
		 'order_estimated_delivery_date' AS original_column_name
	FROM
		stage.orders
	WHERE
		order_estimated_delivery_date IS NOT NULL
UNION ALL
	SELECT
		 shipping_limit_date,
		 'shipping_limit_date' AS original_column_name
	FROM
		stage.order_items
	WHERE
		shipping_limit_date IS NOT NULL
UNION ALL
	SELECT
		 review_creation_date :: TIMESTAMP,
		 'review_creation_date' AS original_column_name
	FROM
		stage.reviews
	WHERE
		review_creation_date IS NOT NULL
UNION ALL
	SELECT
		 review_answer_timestamp,
		 'review_answer_timestamp' AS original_column_name
	FROM
		stage.reviews
	WHERE
		review_answer_timestamp IS NOT NULL
)
SELECT
	MAX(master_date) AS max_date,
	original_column_name
FROM
	master_date_table
GROUP BY
	original_column_name;
--------------------
SELECT
	soi.order_id,
	soi.order_item_id,
	soi.shipping_limit_date,
	so.order_purchase_timestamp,
	so.order_approved_at,
	so.order_status
FROM
	stage.order_items soi LEFT JOIN stage.orders so
								ON soi.order_id = so.order_id
WHERE
	EXTRACT(YEAR FROM soi.shipping_limit_date) > 2018;

-- dim_dates Table creation:

CREATE TABLE analytics.dim_dates
(
	date DATE PRIMARY KEY,
	day INTEGER NOT NULL CHECK(day BETWEEN 1 AND 31),
	day_name TEXT NOT NULL,
	weekday_number INTEGER NOT NULL CHECK(weekday_number BETWEEN 1 AND 7),
	day_type TEXT NOT NULL CHECK(day_type IN ('Weekday', 'Weekend')),
	week_number INTEGER NOT NULL CHECK(week_number BETWEEN 1 AND 53),
	month_name TEXT NOT NULL CHECK(month_name IN ('January', 'February', 'March', 'April',
												  'May', 'June', 'July', 'August',
												  'September', 'October', 'November', 'December')),
	month_number INTEGER NOT NULL CHECK(month_number BETWEEN 1 AND 12),
	year_month TEXT NOT NULL,
	quarter TEXT NOT NULL CHECK(quarter IN ('Q1', 'Q2', 'Q3', 'Q4')),
	quarter_number INTEGER NOT NULL CHECK(quarter_number BETWEEN 1 AND 4),
	year_quarter TEXT NOT NULL,
	year INTEGER NOT NULL CHECK(year BETWEEN 2016 AND 2018)
);

-- dim_dates Data insertion:

INSERT INTO analytics.dim_dates
(
	date,
	day,
	day_name,
	weekday_number,
	day_type,
	week_number,
	month_name,
	month_number,
	year_month,
	quarter,
	quarter_number,
	year_quarter,
	year
)
WITH date_table AS
(
SELECT
	(GENERATE_SERIES(
		'2016-01-01' :: TIMESTAMP,
		'2018-12-31' :: TIMESTAMP,
		'1 day' :: INTERVAL) :: DATE) AS date
)
SELECT
	date,
	(EXTRACT(DAY FROM date) :: INTEGER) AS day,
	TO_CHAR(date, 'FMDay') AS day_name,
	(EXTRACT(ISODOW FROM date) :: INTEGER) AS weekday_number,
	(CASE
		WHEN EXTRACT(ISODOW FROM date) IN (6, 7) THEN 'Weekend'
		ELSE 'Weekday'
	END) AS day_type,
	(EXTRACT(WEEK FROM date) :: INTEGER) AS week_number,
	TO_CHAR(date, 'FMMonth') AS month_name,
	(EXTRACT(MONTH FROM date) :: INTEGER) AS month_number,
	TO_CHAR(date, 'YYYY-MM') AS year_month,
	'Q'||TO_CHAR(date, 'Q') AS quarter,
	(EXTRACT(QUARTER FROM date) :: INTEGER) AS quarter_number,
	TO_CHAR(date, 'YYYY')||'-Q'||TO_CHAR(date,'Q') AS year_quarter,
	(EXTRACT(YEAR FROM date) :: INTEGER) AS year
FROM
	date_table;

-- Post Transformation QA:

SELECT
	COUNT(*)
FROM
	analytics.dim_dates;
--------------------
SELECT
	MIN(date) AS min_date,
	MAX(date) AS max_date
FROM
	analytics.dim_dates;
--------------------
WITH exp_date AS
(
SELECT
	(GENERATE_SERIES(
		'2016-01-01' :: TIMESTAMP,
		'2018-12-31' :: TIMESTAMP,
		'1 day' :: INTERVAL) :: DATE) AS expected_date
)
SELECT
	ed.expected_date,
	dd.date AS existing_date
FROM
	exp_date ed FULL OUTER JOIN analytics.dim_dates dd
							ON ed.expected_date = dd.date
WHERE
	ed.expected_date IS DISTINCT FROM dd.date;
--------------------
SELECT
	*
FROM
	analytics.dim_dates
WHERE
	date IS NULL OR
	day IS NULL OR
	day_name IS NULL OR
	weekday_number IS NULL OR
	day_type IS NULL OR
	week_number IS NULL OR
	month_name IS NULL OR
	month_number IS NULL OR
	year_month IS NULL OR
	quarter IS NULL OR
	quarter_number IS NULL OR
	year_quarter IS NULL OR
	year IS NULL;
--------------------
SELECT
	date
FROM
	analytics.dim_dates
WHERE
	(day IS DISTINCT FROM ((EXTRACT(DAY FROM date) :: INTEGER))) OR
	(day_name IS DISTINCT FROM (TO_CHAR(date, 'FMDay'))) OR
	(weekday_number IS DISTINCT FROM ((EXTRACT(ISODOW FROM date) :: INTEGER))) OR
	(day_type IS DISTINCT FROM ((CASE
									WHEN EXTRACT(ISODOW FROM date) IN (6, 7) THEN 'Weekend'
									ELSE 'Weekday'
								END))) OR
	(week_number IS DISTINCT FROM ((EXTRACT(WEEK FROM date) :: INTEGER))) OR
	(month_name IS DISTINCT FROM (TO_CHAR(date, 'FMMonth'))) OR
	(month_number IS DISTINCT FROM ((EXTRACT(MONTH FROM date) :: INTEGER))) OR
	(year_month IS DISTINCT FROM (TO_CHAR(date, 'YYYY-MM'))) OR
	(quarter IS DISTINCT FROM ('Q'||TO_CHAR(date, 'Q'))) OR
	(quarter_number IS DISTINCT FROM ((EXTRACT(QUARTER FROM date) :: INTEGER))) OR
	(year_quarter IS DISTINCT FROM (TO_CHAR(date, 'YYYY')||'-Q'||TO_CHAR(date,'Q'))) OR
	(year IS DISTINCT FROM ((EXTRACT(YEAR FROM date) :: INTEGER)));










------------------------------------------------------------------------------------------------------------------------------------------------

										-- Orders Analytics Table Creation --

-- fact_orders Table creation:

CREATE TABLE analytics.fact_orders
(
	order_id TEXT PRIMARY KEY,
	customer_id TEXT NOT NULL CHECK(customer_id <> '') REFERENCES analytics.dim_customers(customer_id),
	order_status TEXT NOT NULL CHECK(order_status IN ('delivered', 'shipped', 'canceled', 'unavailable', 
													  'invoiced', 'processing', 'created', 'approved')),
	order_purchase_timestamp TIMESTAMP NOT NULL,
	order_approved_at  TIMESTAMP,
	order_delivered_carrier_date TIMESTAMP,
	order_delivered_customer_date TIMESTAMP,
	order_estimated_delivery_date DATE NOT NULL,
	delivery_duration_days INTEGER,
	delivery_variance_days INTEGER,
	delivery_performance TEXT CHECK(delivery_performance IN ('On Time', 'Late'))
);

-- fact_orders Data insertion:

INSERT INTO analytics.fact_orders
(
	order_id,
	customer_id,
	order_status,
	order_purchase_timestamp,
	order_approved_at,
	order_delivered_carrier_date,
	order_delivered_customer_date,
	order_estimated_delivery_date,
	delivery_duration_days,
	delivery_variance_days,
	delivery_performance
)
SELECT
	order_id,
	customer_id,
	order_status,
	order_purchase_timestamp,
	order_approved_at,
	order_delivered_carrier_date,
	order_delivered_customer_date,
	order_estimated_delivery_date,
	(((order_delivered_customer_date :: DATE) - (order_purchase_timestamp :: DATE)) :: INTEGER) AS delivery_duration_days,
	(((order_delivered_customer_date :: DATE) - order_estimated_delivery_date) :: INTEGER) AS delivery_variance_days,
	(CASE
		WHEN (order_delivered_customer_date :: DATE) <= order_estimated_delivery_date THEN 'On Time'
		WHEN (order_delivered_customer_date :: DATE) > order_estimated_delivery_date THEN 'Late'
		ELSE NULL
	END) AS delivery_performance
FROM
	stage.orders;

-- Post Transformation QA:

SELECT
	(SELECT
		COUNT(*)
	FROM
		analytics.fact_orders) AS analy_count,
	(SELECT
		COUNT(*)
	FROM
		stage.orders) AS stage_count;
--------------------
SELECT
	fo.order_id
FROM
	analytics.fact_orders fo LEFT JOIN stage.orders so
									ON fo.order_id = so.order_id
WHERE
	so.order_id IS NULL;
--------------------
SELECT
	so.order_id
FROM
	analytics.fact_orders fo RIGHT JOIN stage.orders so
									ON fo.order_id = so.order_id
WHERE
	fo.order_id IS NULL;
--------------------
SELECT
	fo.order_id
FROM
	analytics.fact_orders fo INNER JOIN stage.orders so
									ON fo.order_id = so.order_id
WHERE
	(fo.customer_id IS DISTINCT FROM so.customer_id) OR
	(fo.order_status IS DISTINCT FROM so.order_status) OR
	(fo.order_purchase_timestamp IS DISTINCT FROM so.order_purchase_timestamp) OR
	(fo.order_approved_at IS DISTINCT FROM so.order_approved_at) OR
	(fo.order_delivered_carrier_date IS DISTINCT FROM so.order_delivered_carrier_date) OR
	(fo.order_delivered_customer_date IS DISTINCT FROM so.order_delivered_customer_date) OR
	(fo.order_estimated_delivery_date IS DISTINCT FROM so.order_estimated_delivery_date);
--------------------
SELECT
	fo.order_id
FROM
	analytics.fact_orders fo INNER JOIN stage.orders so
									ON fo.order_id = so.order_id
WHERE
	(((so.order_delivered_customer_date :: DATE) - (so.order_purchase_timestamp :: DATE)) IS DISTINCT FROM fo.delivery_duration_days) OR
	(((so.order_delivered_customer_date :: DATE) - so.order_estimated_delivery_date) IS DISTINCT FROM fo.delivery_variance_days) OR
	((CASE
		WHEN (so.order_delivered_customer_date :: DATE) <= so.order_estimated_delivery_date THEN 'On Time'
		WHEN (so.order_delivered_customer_date :: DATE) > so.order_estimated_delivery_date THEN 'Late'
		ELSE NULL
	END) IS DISTINCT FROM fo.delivery_performance);
--------------------
SELECT
	delivery_performance,
	COUNT(*) AS sanity_count,
	(COUNT(*) FILTER (WHERE order_delivered_customer_date IS NULL)) AS null_count
FROM
	analytics.fact_orders
GROUP BY
	delivery_performance;










------------------------------------------------------------------------------------------------------------------------------------------------

										-- Order Items Analytics Table Creation --

-- fact_order_items Table creation:

CREATE TABLE analytics.fact_order_items
(
	order_id TEXT,
	order_item_id INTEGER CHECK(order_item_id > 0),
	customer_id TEXT NOT NULL CHECK(customer_id <> '') REFERENCES analytics.dim_customers(customer_id),
	product_id TEXT NOT NULL CHECK(product_id <> '') REFERENCES analytics.dim_products(product_id),
	seller_id TEXT NOT NULL CHECK(seller_id <> '') REFERENCES analytics.dim_sellers(seller_id),
	order_status TEXT NOT NULL CHECK(order_status IN ('delivered', 'shipped', 'canceled', 'unavailable', 
													  'invoiced', 'processing', 'created', 'approved')),
	order_purchase_timestamp TIMESTAMP NOT NULL,
	shipping_limit_date TIMESTAMP NOT NULL,
	price NUMERIC NOT NULL CHECK(price > 0),
	freight_value NUMERIC NOT NULL CHECK(freight_value >= 0),
	item_total_value NUMERIC NOT NULL CHECK(item_total_value > 0),
	PRIMARY KEY (order_id, order_item_id)
);

-- fact_order_items Data insertion:

INSERT INTO analytics.fact_order_items
(
	order_id,
	order_item_id,
	customer_id,
	product_id,
	seller_id,
	order_status,
	order_purchase_timestamp,
	shipping_limit_date,
	price,
	freight_value,
	item_total_value
)
SELECT
	soi.order_id,
	soi.order_item_id,
	so.customer_id,
	soi.product_id,
	soi.seller_id,
	so.order_status,
	so.order_purchase_timestamp,
	soi.shipping_limit_date,
	soi.price,
	soi.freight_value,
	(soi.price + soi.freight_value) AS item_total_value
FROM
	stage.order_items soi LEFT JOIN stage.orders so
								ON soi.order_id = so.order_id;

-- Post Transformation QA:

SELECT
	(SELECT
		COUNT(*)
	FROM
		stage.order_items) AS stage_count,
	(SELECT
		COUNT(*)
	FROM
		analytics.fact_order_items) AS analy_count;
--------------------
SELECT
	foi.order_id,
	foi.order_item_id
FROM
	analytics.fact_order_items foi LEFT JOIN stage.order_items soi
										ON foi.order_id = soi.order_id
										AND foi.order_item_id = soi.order_item_id
WHERE
	soi.order_id IS NULL
	OR
	soi.order_item_id IS NULL;
--------------------
SELECT
	soi.order_id,
	soi.order_item_id
FROM
	analytics.fact_order_items foi RIGHT JOIN stage.order_items soi
										ON foi.order_id = soi.order_id
										AND foi.order_item_id = soi.order_item_id
WHERE
	foi.order_id IS NULL
	OR
	foi.order_item_id IS NULL;
--------------------
SELECT
	foi.order_id,
	foi.order_item_id
FROM
	analytics.fact_order_items foi INNER JOIN stage.order_items soi ON (foi.order_id = soi.order_id
																  AND foi.order_item_id = soi.order_item_id)
								   	INNER JOIN stage.orders so 	   ON foi.order_id = so.order_id
WHERE
	(foi.product_id IS DISTINCT FROM soi.product_id) OR
	(foi.seller_id IS DISTINCT FROM soi.seller_id) OR
	(foi.shipping_limit_date IS DISTINCT FROM soi.shipping_limit_date) OR
	(foi.price IS DISTINCT FROM soi.price) OR
	(foi.freight_value IS DISTINCT FROM soi.freight_value) OR
	(foi.customer_id IS DISTINCT FROM so.customer_id) OR
	(foi.order_status IS DISTINCT FROM so.order_status) OR
	(foi.order_purchase_timestamp IS DISTINCT FROM so.order_purchase_timestamp);
--------------------
SELECT
	foi.order_id,
	foi.order_item_id
FROM
	analytics.fact_order_items foi INNER JOIN stage.order_items soi
											ON foi.order_id = soi.order_id
											AND foi.order_item_id = soi.order_item_id
WHERE
	(foi.item_total_value IS DISTINCT FROM (soi.price + soi.freight_value));
--------------------
SELECT
	order_status,
	COUNT(*) AS item_count
FROM
	analytics.fact_order_items
GROUP BY
	order_status
ORDER BY
	item_count DESC;










------------------------------------------------------------------------------------------------------------------------------------------------

										-- Payments Analytics Table Creation --

-- fact_payments Table creation:

CREATE TABLE analytics.fact_payments
(
	order_id TEXT,
	payment_sequential INTEGER CHECK(payment_sequential > 0),
	customer_id TEXT NOT NULL CHECK(customer_id <> '') REFERENCES analytics.dim_customers(customer_id),
	order_status TEXT NOT NULL CHECK(order_status IN ('delivered', 'shipped', 'canceled', 'unavailable', 
													  'invoiced', 'processing', 'created', 'approved')),
	order_purchase_timestamp TIMESTAMP NOT NULL,
	payment_type TEXT NOT NULL CHECK(payment_type IN ('credit_card', 'boleto', 'voucher', 'debit_card',
													  'not_defined')),
	payment_installments INTEGER NOT NULL CHECK(payment_installments >= 0),
	payment_value NUMERIC NOT NULL CHECK(payment_value >= 0),
	PRIMARY KEY (order_id, payment_sequential)
);

-- fact_payments Data insertion:

INSERT INTO analytics.fact_payments
(
	order_id,
	payment_sequential,
	customer_id,
	order_status,
	order_purchase_timestamp,
	payment_type,
	payment_installments,
	payment_value
)
SELECT
	sp.order_id,
	sp.payment_sequential,
	so.customer_id,
	so.order_status,
	so.order_purchase_timestamp,
	sp.payment_type,
	sp.payment_installments,
	sp.payment_value
FROM
	stage.payments sp LEFT JOIN stage.orders so
							ON sp.order_id = so.order_id;

-- Post Transformation QA:

SELECT
	(SELECT
		COUNT(*)
	FROM
		stage.payments) AS stage_count,
	(SELECT
		COUNT(*)
	FROM
		analytics.fact_payments) AS analy_count;
--------------------
SELECT
	fp.order_id,
	fp.payment_sequential
FROM
	analytics.fact_payments fp LEFT JOIN stage.payments sp
									ON fp.order_id = sp.order_id
									AND fp.payment_sequential = sp.payment_sequential
WHERE
	sp.order_id IS NULL
	OR
	sp.payment_sequential IS NULL;
--------------------
SELECT
	sp.order_id,
	sp.payment_sequential
FROM
	analytics.fact_payments fp RIGHT JOIN stage.payments sp
									ON fp.order_id = sp.order_id
									AND fp.payment_sequential = sp.payment_sequential
WHERE
	fp.order_id IS NULL
	OR
	fp.payment_sequential IS NULL;
--------------------
SELECT
	fp.order_id,
	fp.payment_sequential
FROM
	analytics.fact_payments fp INNER JOIN stage.payments sp ON (fp.order_id = sp.order_id
														  AND fp.payment_sequential = sp.payment_sequential)
							   INNER JOIN stage.orders so ON fp.order_id = so.order_id
WHERE
	(fp.customer_id IS DISTINCT FROM so.customer_id) OR
	(fp.order_status IS DISTINCT FROM so.order_status) OR
	(fp.order_purchase_timestamp IS DISTINCT FROM so.order_purchase_timestamp) OR
	(fp.payment_type IS DISTINCT FROM sp.payment_type) OR
	(fp.payment_installments IS DISTINCT FROM sp.payment_installments) OR
	(fp.payment_value IS DISTINCT FROM sp.payment_value);
--------------------
SELECT
	payment_type,
	COUNT(*) AS payment_rows,
	COUNT(DISTINCT(order_id)) AS distinct_orders,
	SUM(payment_value) AS total_payment_value
FROM
	analytics.fact_payments
GROUP BY
	payment_type;










------------------------------------------------------------------------------------------------------------------------------------------------

										-- Reviews Analytics Table Creation --

-- fact_reviews Table creation:

CREATE TABLE analytics.fact_reviews
(
	review_id TEXT,
	order_id TEXT,
	customer_id TEXT NOT NULL CHECK(customer_id <> '') REFERENCES analytics.dim_customers(customer_id),
	review_score INTEGER NOT NULL CHECK(review_score BETWEEN 1 AND 5),
	review_comment_title TEXT,
	review_comment_message TEXT,
	review_creation_date DATE NOT NULL,
	review_answer_timestamp TIMESTAMP NOT NULL,
	order_purchase_date DATE,
	PRIMARY KEY (review_id, order_id)
);

-- fact_reviews Data insertion:

INSERT INTO analytics.fact_reviews
(
	review_id,
	order_id,
	customer_id,
	review_score,
	review_comment_title,
	review_comment_message,
	review_creation_date,
	review_answer_timestamp,
	order_purchase_date
)
SELECT
	sr.review_id,
	sr.order_id,
	so.customer_id,
	sr.review_score,
	sr.review_comment_title,
	sr.review_comment_message,
	sr.review_creation_date,
	sr.review_answer_timestamp,
	so.order_purchase_date :: DATE
FROM
	stage.reviews sr LEFT JOIN stage.orders so
							ON sr.order_id = so.order_id;

-- Post Transformation QA:

SELECT
	(SELECT
		COUNT(*)
	FROM
		stage.reviews) AS stage_count,
	(SELECT
		COUNT(*)
	FROM
		analytics.fact_reviews) AS analy_count;
--------------------
SELECT
	fr.review_id,
	fr.order_id
FROM
	analytics.fact_reviews fr LEFT JOIN stage.reviews sr
									ON fr.review_id = sr.review_id
									AND fr.order_id = sr.order_id
WHERE
	sr.review_id IS NULL
	OR
	sr.order_id IS NULL;
--------------------
SELECT
	sr.review_id,
	sr.order_id
FROM
	analytics.fact_reviews fr RIGHT JOIN stage.reviews sr
									ON fr.review_id = sr.review_id
									AND fr.order_id = sr.order_id
WHERE
	fr.review_id IS NULL
	OR
	fr.order_id IS NULL;
--------------------
SELECT
	fr.review_id,
	fr.order_id
FROM
	analytics.fact_reviews fr INNER JOIN stage.reviews sr ON (fr.review_id = sr.review_id
														AND fr.order_id = sr.order_id)
							  INNER JOIN stage.orders so ON fr.order_id = so.order_id
WHERE
	(fr.customer_id IS DISTINCT FROM so.customer_id) OR
	(fr.review_score IS DISTINCT FROM sr.review_score) OR
	(fr.review_comment_title IS DISTINCT FROM sr.review_comment_title) OR
	(fr.review_comment_message IS DISTINCT FROM sr.review_comment_message) OR
	(fr.review_creation_date IS DISTINCT FROM sr.review_creation_date) OR
	(fr.review_answer_timestamp IS DISTINCT FROM sr.review_answer_timestamp);
--------------------
SELECT
	review_score,
	COUNT(*) AS review_rows,
	COUNT(DISTINCT(order_id)) AS distinct_orders
FROM
	analytics.fact_reviews
GROUP BY
	review_score;










------------------------------------------------------------------------------------------------------------------------------------------------

										-- Fact-Dimension Table Coverage QA --

-- fact_orders -> dim_customers & dim_dates coverage:

SELECT
	COUNT(fo.*)
FROM
	analytics.fact_orders fo LEFT JOIN analytics.dim_customers dc ON fo.customer_id = dc.customer_id
							 LEFT JOIN analytics.dim_dates dd ON (fo.order_purchase_timestamp :: DATE) = dd.date
WHERE
	dc.customer_id IS NULL
	OR
	dd.date IS NULL;

-- fact_order_items -> dim_customers, dim_products, dim_sellers & dim_dates coverage:

SELECT
	COUNT(foi.*)
FROM
	analytics.fact_order_items foi LEFT JOIN analytics.dim_customers dc ON foi.customer_id = dc.customer_id
								   LEFT JOIN analytics.dim_products dp ON foi.product_id = dp.product_id
								   LEFT JOIN analytics.dim_sellers ds ON foi.seller_id = ds.seller_id
								   LEFT JOIN analytics.dim_dates dd ON (foi.order_purchase_timestamp :: DATE) = dd.date
WHERE
	dc.customer_id IS NULL OR
	dp.product_id IS NULL OR
	ds.seller_id IS NULL OR
	dd.date IS NULL;

-- fact_payments -> dim_customers & dim_dates coverage:

SELECT
	COUNT(fp.*)
FROM
	analytics.fact_payments fp LEFT JOIN analytics.dim_customers dc ON fp.customer_id = dc.customer_id
							   LEFT JOIN analytics.dim_dates dd ON (fp.order_purchase_timestamp :: DATE) = dd.date
WHERE
	dc.customer_id IS NULL
	OR
	dd.date IS NULL;

-- fact_reviews -> dim_customers & dim_dates coverage:

SELECT
	COUNT(fr.*)
FROM
	analytics.fact_reviews fr LEFT JOIN analytics.dim_customers dc ON fr.customer_id = dc.customer_id
							  LEFT JOIN analytics.dim_dates dd ON fr.review_creation_date = dd.date
WHERE
	dc.customer_id IS NULL
	OR
	dd.date IS NULL;

-- Cardinality coverage:


SELECT
	'Customer to Orders' AS table_relationship,
	MAX(row_counts) AS max_fact_rows_per_key
FROM
	(SELECT
		customer_id,
		COUNT(*) AS row_counts
	FROM
		analytics.fact_orders
	GROUP BY
		customer_id)
UNION
SELECT
	'Customer to Order Items' AS table_relationship,
	MAX(row_counts) AS max_fact_rows_per_key
FROM
	(SELECT
		customer_id,
		COUNT(*) AS row_counts
	FROM
		analytics.fact_order_items
	GROUP BY
		customer_id)
UNION
SELECT
	'Customer to Payments' AS table_relationship,
	MAX(row_counts) AS max_fact_rows_per_key
FROM
	(SELECT
		customer_id,
		COUNT(*) AS row_counts
	FROM
		analytics.fact_payments
	GROUP BY
		customer_id)
UNION
SELECT
	'Customer to Reviews' AS table_relationship,
	MAX(row_counts) AS max_fact_rows_per_key
FROM
	(SELECT
		customer_id,
		COUNT(*) AS row_counts
	FROM
		analytics.fact_reviews
	GROUP BY
		customer_id)
UNION
SELECT
	'Dates to Orders' AS table_relationship,
	MAX(row_counts) AS max_fact_rows_per_key
FROM
	(SELECT
		order_purchase_timestamp :: DATE,
		COUNT(*) AS row_counts
	FROM
		analytics.fact_orders
	GROUP BY
		order_purchase_timestamp :: DATE)
UNION
SELECT
	'Dates to Order Items' AS table_relationship,
	MAX(row_counts) AS max_fact_rows_per_key
FROM
	(SELECT
		order_purchase_timestamp :: DATE,
		COUNT(*) AS row_counts
	FROM
		analytics.fact_order_items
	GROUP BY
		order_purchase_timestamp :: DATE)
UNION
SELECT
	'Dates to Payments' AS table_relationship,
	MAX(row_counts) AS max_fact_rows_per_key
FROM
	(SELECT
		order_purchase_timestamp :: DATE,
		COUNT(*) AS row_counts
	FROM
		analytics.fact_payments
	GROUP BY
		order_purchase_timestamp :: DATE)
UNION
SELECT
	'Dates to Reviews' AS table_relationship,
	MAX(row_counts) AS max_fact_rows_per_key
FROM
	(SELECT
		review_creation_date,
		COUNT(*) AS row_counts
	FROM
		analytics.fact_reviews
	GROUP BY
		review_creation_date)
UNION
SELECT
	'Product to Order Items' AS table_relationship,
	MAX(row_counts) AS max_fact_rows_per_key
FROM
	(SELECT
		product_id,
		COUNT(*) AS row_counts
	FROM
		analytics.fact_order_items
	GROUP BY
		product_id)
UNION
SELECT
	'Seller to Order Items' AS table_relationship,
	MAX(row_counts) AS max_fact_rows_per_key
FROM
	(SELECT
		seller_id,
		COUNT(*) AS row_counts
	FROM
		analytics.fact_order_items
	GROUP BY
		seller_id);

-- Secondary Date-role coverage for fact_orders:

SELECT
	'Approval Date' AS date_role,
	COUNT(fo.*) AS unmatched_rows
FROM
	analytics.fact_orders fo LEFT JOIN analytics.dim_dates dd ON (fo.order_approved_at :: DATE) = dd.date
WHERE
	dd.date IS NULL
	AND
	fo.order_approved_at IS NOT NULL
UNION
SELECT
	'Carrier Delivery Date' AS date_role,
	COUNT(fo.*) AS unmatched_rows
FROM
	analytics.fact_orders fo LEFT JOIN analytics.dim_dates dd ON (fo.order_delivered_carrier_date :: DATE) = dd.date
WHERE
	dd.date IS NULL
	AND
	fo.order_delivered_carrier_date IS NOT NULL
UNION
SELECT
	'Customer Delivery Date' AS date_role,
	COUNT(fo.*) AS unmatched_rows
FROM
	analytics.fact_orders fo LEFT JOIN analytics.dim_dates dd ON (fo.order_delivered_customer_date :: DATE) = dd.date
WHERE
	dd.date IS NULL
	AND
	fo.order_delivered_customer_date IS NOT NULL
UNION
SELECT
	'Estimated Delivery Date' AS date_role,
	COUNT(fo.*) AS unmatched_rows
FROM
	analytics.fact_orders fo LEFT JOIN analytics.dim_dates dd ON (fo.order_estimated_delivery_date :: DATE) = dd.date
WHERE
	dd.date IS NULL
	AND
	fo.order_estimated_delivery_date IS NOT NULL;










-----------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------




											"ANALYSIS STAGE"




------------------------------------------------------------------------------------------------------------------------------------------------

										-- Executive Performance Analysis --

-- Building the baseline KPI query:

WITH overall_orders_metrics AS
(
SELECT
	COUNT(*) AS total_orders_placed
FROM
	analytics.fact_orders
),
delivered_commercial_metrics AS
(
SELECT
	COUNT(DISTINCT(order_id)) AS completed_orders,
	COUNT(*) AS total_units_sold,
	SUM(price) AS total_merchandise_sales_value,
	SUM(freight_value) AS total_freight_value,
	SUM(item_total_value) AS total_order_value,
	ROUND(((SUM(item_total_value)) / (COUNT(DISTINCT(order_id)))), 2) AS avg_order_value,
	ROUND(AVG(price), 2) AS avg_selling_price
FROM
	analytics.fact_order_items
WHERE
	order_status = 'delivered'
),
delivered_unique_customer_metrics AS
(
SELECT
	  COUNT(DISTINCT(dc.customer_unique_id)) AS total_unique_customers
FROM
	analytics.dim_customers dc INNER JOIN analytics.fact_orders fo ON dc.customer_id = fo.customer_id
WHERE
	fo.order_status = 'delivered'
)
SELECT
	total_orders_placed,
	completed_orders,
	total_unique_customers,
	total_units_sold,
	total_merchandise_sales_value,
	total_freight_value,
	total_order_value,
	avg_order_value,
	avg_selling_price
FROM
	overall_orders_metrics oom CROSS JOIN delivered_commercial_metrics dcm
							   CROSS JOIN delivered_unique_customer_metrics ducm;

-- Purchase Date range check:

SELECT
	MIN(order_purchase_timestamp) AS earliest_timestamp,
	MAX(order_purchase_timestamp) AS latest_timestamp
FROM
	analytics.fact_orders;

-- Number of Orders by Year and Month check:

SELECT
	dd.year,
	dd.month_name,
	dd.month_number,
	COUNT(fo.*) AS total_orders
FROM
	analytics.fact_orders fo LEFT JOIN analytics.dim_dates dd
									ON (fo.order_purchase_timestamp :: DATE) = dd.date
GROUP BY
	dd.year,
	dd.month_name,
	dd.month_number
ORDER BY
	dd.year ASC,
	dd.month_number ASC;

-- Building the Monthly Trend Analysis query:

WITH orders_dates_customers AS
(
SELECT
	dd.year,
	dd.month_name,
	dd.month_number,
	COUNT(fo.order_id) AS completed_orders,
	COUNT(DISTINCT(dc.customer_unique_id)) AS total_customers
FROM
	analytics.fact_orders fo INNER JOIN analytics.dim_customers dc ON fo.customer_id = dc.customer_id
							 INNER JOIN analytics.dim_dates dd ON (fo.order_purchase_timestamp :: DATE) = dd.date
WHERE
	fo.order_status = 'delivered'
GROUP BY
	dd.year,
	dd.month_name,
	dd.month_number
),
delivered_commercial_metrics AS
(
SELECT
	dd.year,
	dd.month_name,
	dd.month_number,
	COUNT(foi.*) AS total_units_sold,
	SUM(foi.price) AS merchandise_sales_value,
	SUM(foi.item_total_value) AS total_order_value
FROM
	analytics.fact_order_items foi INNER JOIN analytics.dim_dates dd
										ON (foi.order_purchase_timestamp :: DATE) = dd.date
WHERE
	foi.order_status = 'delivered'
GROUP BY
	dd.year,
	dd.month_name,
	dd.month_number
)
SELECT
	odc.year,
	odc.month_name,
	odc.month_number,
	odc.completed_orders,
	dcm.total_units_sold,
	odc.total_customers,
	dcm.merchandise_sales_value,
	dcm.total_order_value
FROM
	orders_dates_customers odc INNER JOIN delivered_commercial_metrics dcm
										ON odc.year = dcm.year
										AND odc.month_number = dcm.month_number
ORDER BY
	odc.year ASC,
	odc.month_number ASC;

-- Jan–Aug 2017 vs Jan–Aug 2018 comparable-period performance and percentage growth:

WITH orders_years_customers AS
(
SELECT
	dd.year,
	COUNT(fo.order_id) AS completed_orders,
	COUNT(DISTINCT(dc.customer_unique_id)) AS total_customers
FROM
	analytics.fact_orders fo INNER JOIN analytics.dim_customers dc ON fo.customer_id = dc.customer_id
							 INNER JOIN analytics.dim_dates dd ON (fo.order_purchase_timestamp :: DATE) = dd.date
WHERE
	fo.order_status = 'delivered'
	AND
	(EXTRACT(MONTH FROM fo.order_purchase_timestamp) BETWEEN 1 AND 8)
	AND
	dd.year IN (2017, 2018)
GROUP BY
	dd.year
),
delivered_commercial_metrics AS
(
SELECT
	dd.year,
	COUNT(foi.*) AS total_units_sold,
	SUM(foi.price) AS merchandise_sales_value,
	SUM(foi.item_total_value) AS total_order_value
FROM
	analytics.fact_order_items foi INNER JOIN analytics.dim_dates dd
										ON (foi.order_purchase_timestamp :: DATE) = dd.date
WHERE
	foi.order_status = 'delivered'
	AND
	(EXTRACT(MONTH FROM foi.order_purchase_timestamp) BETWEEN 1 AND 8)
	AND
	dd.year IN (2017, 2018)
GROUP BY
	dd.year
),
comparison_metrics AS
(
SELECT
	'Jan - Aug'||' '||oyc.year AS period,
	oyc.year,
	oyc.completed_orders,
	oyc.total_customers,
	dcm.total_units_sold,
	dcm.merchandise_sales_value,
	dcm.total_order_value
FROM
	orders_years_customers oyc INNER JOIN delivered_commercial_metrics dcm
										ON oyc.year = dcm.year
)
SELECT
	period,
	completed_orders,
	total_customers,
	total_units_sold,
	merchandise_sales_value,
	total_order_value
FROM
	comparison_metrics
UNION ALL
SELECT
	'YoY %' AS period,
	ROUND((((y2018.completed_orders :: NUMERIC - y2017.completed_orders :: NUMERIC) / y2017.completed_orders :: NUMERIC) * 100), 2) AS completed_orders,
	ROUND((((y2018.total_customers :: NUMERIC - y2017.total_customers :: NUMERIC) / y2017.total_customers :: NUMERIC) * 100), 2) AS total_customers,
	ROUND((((y2018.total_units_sold :: NUMERIC - y2017.total_units_sold :: NUMERIC) / y2017.total_units_sold :: NUMERIC) * 100), 2) AS total_units_sold,
	ROUND((((y2018.merchandise_sales_value - y2017.merchandise_sales_value) / y2017.merchandise_sales_value) * 100), 2) AS merchandise_sales_value,
	ROUND((((y2018.total_order_value - y2017.total_order_value) / y2017.total_order_value) * 100), 2) AS total_order_value
FROM
	comparison_metrics y2017 CROSS JOIN comparison_metrics y2018
WHERE
	y2017.year = 2017
	AND
	y2018.year = 2018;

-- Investigating the November 2017 spike:

SELECT
	dd.date,
	COUNT(fo.*) AS completed_orders
FROM
	analytics.fact_orders fo INNER JOIN analytics.dim_dates dd
									ON (fo.order_purchase_timestamp :: DATE) = dd.date
WHERE
	fo.order_status = 'delivered'
	AND
	dd.year = 2017
	AND
	dd.month_name = 'November'
GROUP BY
	dd.date
ORDER BY
	dd.date ASC;










------------------------------------------------------------------------------------------------------------------------------------------------

										-- Customer Intelligence Analysis --

-- Analyse New vs Returning Customer activity and compare Jan–Aug 2017 vs 2018:

WITH first_delivered_order AS
(
SELECT
	dc.customer_unique_id,
	MIN(fo.order_purchase_timestamp) AS first_delivered_order_date
FROM
	analytics.fact_orders fo INNER JOIN analytics.dim_customers dc
									ON fo.customer_id = dc.customer_id
WHERE
	fo.order_status = 'delivered'
GROUP BY
	dc.customer_unique_id
),
customer_orders_by_month AS
(
SELECT
	dc.customer_unique_id,
	dd.month_name,
	dd.year,
	dd.month_number
FROM
	analytics.fact_orders fo INNER JOIN analytics.dim_customers dc ON fo.customer_id = dc.customer_id
							 INNER JOIN analytics.dim_dates dd ON (fo.order_purchase_timestamp :: DATE) = dd.date
WHERE
	fo.order_status = 'delivered'
GROUP BY
	dc.customer_unique_id,
	dd.month_name,
	dd.month_number,
	dd.year
),
customer_classification AS
(
SELECT
	fdo.customer_unique_id,
	com.month_name,
	com.year,
	com.month_number,
	fdo.first_delivered_order_date,
	(CASE
		WHEN (EXTRACT(MONTH FROM fdo.first_delivered_order_date) = com.month_number) 
			AND (EXTRACT(YEAR FROM fdo.first_delivered_order_date) = com.year) THEN 'New'
		ELSE 'Returning'
	END) AS customer_type
FROM
	first_delivered_order fdo INNER JOIN customer_orders_by_month com
									ON fdo.customer_unique_id = com.customer_unique_id
),
monthly_customer_summary AS
(
SELECT
	cc.year,
	cc.month_name,
	(COUNT(cc.customer_unique_id) FILTER (WHERE cc.customer_type = 'New')) AS new_customers,
	(COUNT(cc.customer_unique_id) FILTER (WHERE cc.customer_type = 'Returning')) AS returning_customers,
	COUNT(cc.customer_unique_id) AS total_customers,
	ROUND(((((COUNT(cc.customer_unique_id) FILTER (WHERE cc.customer_type = 'Returning')) :: NUMERIC) / (COUNT(cc.customer_unique_id) :: NUMERIC)) * 100), 2) AS returning_customer_pct,
	cc.month_number
FROM
	customer_classification cc
GROUP BY
	cc.year,
	cc.month_name,
	cc.month_number
ORDER BY
	cc.year,
	cc.month_number
)
SELECT
	'Jan - Aug'||' '||mcs.year AS period,
	SUM(mcs.new_customers) AS total_new_customers,
	SUM(mcs.returning_customers) AS total_returning_customers,
	SUM(mcs.total_customers) AS total_customers_by_period
FROM
	monthly_customer_summary mcs
WHERE
	mcs.month_number BETWEEN 1 and 8
	AND
	mcs.year IN (2017, 2018)
GROUP BY
	'Jan - Aug'||' '||mcs.year
UNION ALL
SELECT
	'YoY %' AS period,
	ROUND((((((SUM(mcs.new_customers) FILTER (WHERE (mcs.month_number BETWEEN 1 and 8) AND (mcs.year = 2018))) :: NUMERIC) - ((SUM(mcs.new_customers) FILTER (WHERE (mcs.month_number BETWEEN 1 and 8) AND (mcs.year = 2017))) :: NUMERIC)) / ((SUM(mcs.new_customers) FILTER (WHERE (mcs.month_number BETWEEN 1 and 8) AND (mcs.year = 2017))) :: NUMERIC)) * 100), 2) AS total_new_customers,
	ROUND((((((SUM(mcs.returning_customers) FILTER (WHERE (mcs.month_number BETWEEN 1 and 8) AND (mcs.year = 2018))) :: NUMERIC) - ((SUM(mcs.returning_customers) FILTER (WHERE (mcs.month_number BETWEEN 1 and 8) AND (mcs.year = 2017))) :: NUMERIC)) / ((SUM(mcs.returning_customers) FILTER (WHERE (mcs.month_number BETWEEN 1 and 8) AND (mcs.year = 2017))) :: NUMERIC)) * 100), 2) AS total_returning_customers,
	ROUND((((((SUM(mcs.total_customers) FILTER (WHERE (mcs.month_number BETWEEN 1 and 8) AND (mcs.year = 2018))) :: NUMERIC) - ((SUM(mcs.total_customers) FILTER (WHERE (mcs.month_number BETWEEN 1 and 8) AND (mcs.year = 2017))) :: NUMERIC)) / ((SUM(mcs.total_customers) FILTER (WHERE (mcs.month_number BETWEEN 1 and 8) AND (mcs.year = 2017))) :: NUMERIC)) * 100), 2) AS total_customers_by_period
FROM
	monthly_customer_summary mcs;










------------------------------------------------------------------------------------------------------------------------------------------------

										-- Customer & Geographic Intelligence Analysis --

-- Among customers with Delivered orders, how many customer_unique_ids are associated with more than one distinct customer state?

SELECT
	dc.customer_unique_id,
	COUNT(DISTINCT(dc.customer_state)) AS total_states
FROM
	analytics.dim_customers dc INNER JOIN analytics.fact_orders fo
									ON dc.customer_id = fo.customer_id
WHERE
	fo.order_status = 'delivered'
GROUP BY
	dc.customer_unique_id
							HAVING
									COUNT(DISTINCT(dc.customer_state)) > 1

-- Analyse Customer Activity, Commercial Value and Repeat Purchasing by State:

WITH state_activity AS
(
SELECT
	dc.customer_state AS states,
	COUNT(DISTINCT(dc.customer_unique_id)) AS unique_customers,
	COUNT(fo.order_id) AS completed_orders
FROM
	analytics.fact_orders fo INNER JOIN analytics.dim_customers dc
									ON fo.customer_id = dc.customer_id
WHERE
	fo.order_status = 'delivered'
GROUP BY
	dc.customer_state
),
state_value AS
(
SELECT
	dc.customer_state AS states,
	SUM(item_total_value) AS total_order_value
FROM
	analytics.fact_orders fo INNER JOIN analytics.dim_customers dc ON fo.customer_id = dc.customer_id
							 INNER JOIN analytics.fact_order_items foi ON fo.order_id = foi.order_id
WHERE
	fo.order_status = 'delivered'
GROUP BY
	dc.customer_state
),
repeat_customers AS
(
SELECT
	dc.customer_unique_id AS repeat_customer,
	COUNT(fo.order_id) AS delivered_order_count
FROM
	analytics.fact_orders fo INNER JOIN analytics.dim_customers dc
									ON fo.customer_id = dc.customer_id
WHERE
	fo.order_status = 'delivered'
GROUP BY
	dc.customer_unique_id
						HAVING
								COUNT(fo.order_id) > 1
),
state_repeat_customers AS
(
SELECT
	dc.customer_state AS states,
	COUNT(DISTINCT(rc.repeat_customer)) AS total_repeat_customers
FROM
	repeat_customers rc INNER JOIN analytics.dim_customers dc ON rc.repeat_customer = dc.customer_unique_id
						INNER JOIN analytics.fact_orders fo ON dc.customer_id = fo.customer_id
WHERE
	fo.order_status = 'delivered'
GROUP BY
	dc.customer_state
)
SELECT
	sa.states AS state,
	sa.unique_customers,
	ROUND((((sa.unique_customers :: NUMERIC) / ((SUM(sa.unique_customers) OVER ()) :: NUMERIC)) * 100), 2) AS customer_share_pct,
	sa.completed_orders,
	sv.total_order_value,
	ROUND((((sv.total_order_value :: NUMERIC) / ((SUM(sv.total_order_value) OVER ()) :: NUMERIC)) * 100), 2) AS total_order_value_share_pct,
	ROUND((sv.total_order_value / sa.completed_orders), 2) AS avg_order_value,
	ROUND((sv.total_order_value / sa.unique_customers), 2) AS avg_customer_value,
	COALESCE(src.total_repeat_customers, 0) AS total_repeat_customers,
	ROUND((((COALESCE(src.total_repeat_customers, 0) :: NUMERIC) / (sa.unique_customers :: NUMERIC)) * 100), 2) AS repeat_customer_rate
FROM
	state_activity sa LEFT JOIN state_value sv ON sa.states = sv.states
					  LEFT JOIN state_repeat_customers src ON sa.states = src.states;










------------------------------------------------------------------------------------------------------------------------------------------------

										-- Product & Category Performance Analysis --

-- Analayse Product Category Peformance by Demand and Commercial Value:

WITH category_performance AS
(
SELECT
	(CASE
		WHEN (dp.product_category_name_english IS NULL AND dp.product_category_name IS NOT NULL) THEN 'untranslated'
		WHEN (dp.product_category_name IS NULL) THEN 'unknown'
		ELSE dp.product_category_name_english
	END) AS category,
	COUNT(foi.*) AS units_sold,
	COUNT(DISTINCT(foi.order_id)) AS completed_orders,
	SUM(foi.price) AS merchandise_sales_value,
	SUM(item_total_value) AS total_order_value,
	ROUND(AVG(foi.price), 2) AS avg_selling_price
FROM
	analytics.fact_order_items foi LEFT JOIN analytics.dim_products dp
										ON foi.product_id = dp.product_id
WHERE
	foi.order_status = 'delivered'
GROUP BY
	(CASE
		WHEN (dp.product_category_name_english IS NULL AND dp.product_category_name IS NOT NULL) THEN 'untranslated'
		WHEN (dp.product_category_name IS NULL) THEN 'unknown'
		ELSE dp.product_category_name_english
	END)
)
SELECT
	category,
	units_sold,
	ROUND((((units_sold :: NUMERIC) / ((SUM(units_sold) OVER()) :: NUMERIC)) * 100), 2) AS units_sold_share_pct,
	completed_orders,
	merchandise_sales_value,
	total_order_value,
	ROUND((((total_order_value :: NUMERIC) / ((SUM(total_order_value) OVER()) :: NUMERIC)) * 100), 2) AS total_order_value_share_pct,
	avg_selling_price
FROM
	category_performance
ORDER BY
	category ASC;

-- QA Product Category Performance Totals:

WITH category_performance AS
(
SELECT
	(CASE
		WHEN (dp.product_category_name_english IS NULL AND dp.product_category_name IS NOT NULL) THEN 'untranslated'
		WHEN (dp.product_category_name IS NULL) THEN 'unknown'
		ELSE dp.product_category_name_english
	END) AS category,
	COUNT(foi.*) AS units_sold,
	COUNT(DISTINCT(foi.order_id)) AS completed_orders,
	SUM(foi.price) AS merchandise_sales_value,
	SUM(item_total_value) AS total_order_value,
	ROUND(AVG(foi.price), 2) AS avg_selling_price
FROM
	analytics.fact_order_items foi LEFT JOIN analytics.dim_products dp
										ON foi.product_id = dp.product_id
WHERE
	foi.order_status = 'delivered'
GROUP BY
	(CASE
		WHEN (dp.product_category_name_english IS NULL AND dp.product_category_name IS NOT NULL) THEN 'untranslated'
		WHEN (dp.product_category_name IS NULL) THEN 'unknown'
		ELSE dp.product_category_name_english
	END)
),
category_summary AS
(
SELECT
	category,
	units_sold,
	ROUND((((units_sold :: NUMERIC) / ((SUM(units_sold) OVER()) :: NUMERIC)) * 100), 2) AS units_sold_share_pct,
	completed_orders,
	merchandise_sales_value,
	total_order_value,
	ROUND((((total_order_value :: NUMERIC) / ((SUM(total_order_value) OVER()) :: NUMERIC)) * 100), 2) AS total_order_value_share_pct,
	avg_selling_price
FROM
	category_performance
)
SELECT
	SUM(units_sold) AS units_sold,
	SUM(merchandise_sales_value) AS merchandise_sales_value,
	SUM(total_order_value) AS total_order_value,
	SUM(units_sold_share_pct) AS units_sold_share_pct_total,
	SUM(total_order_value_share_pct) AS total_order_value_share_pct_total
FROM
	category_summary;

-- Analyse Top 5 Product Category concentration:

WITH category_performance AS
(
SELECT
	(CASE
		WHEN (dp.product_category_name_english IS NULL AND dp.product_category_name IS NOT NULL) THEN 'untranslated'
		WHEN (dp.product_category_name IS NULL) THEN 'unknown'
		ELSE dp.product_category_name_english
	END) AS category,
	COUNT(foi.*) AS units_sold,
	COUNT(DISTINCT(foi.order_id)) AS completed_orders,
	SUM(foi.price) AS merchandise_sales_value,
	SUM(item_total_value) AS total_order_value,
	ROUND(AVG(foi.price), 2) AS avg_selling_price
FROM
	analytics.fact_order_items foi LEFT JOIN analytics.dim_products dp
										ON foi.product_id = dp.product_id
WHERE
	foi.order_status = 'delivered'
GROUP BY
	(CASE
		WHEN (dp.product_category_name_english IS NULL AND dp.product_category_name IS NOT NULL) THEN 'untranslated'
		WHEN (dp.product_category_name IS NULL) THEN 'unknown'
		ELSE dp.product_category_name_english
	END)
),
category_summary AS
(
SELECT
	category,
	units_sold,
	ROUND((((units_sold :: NUMERIC) / ((SUM(units_sold) OVER()) :: NUMERIC)) * 100), 2) AS units_sold_share_pct,
	completed_orders,
	merchandise_sales_value,
	total_order_value,
	ROUND((((total_order_value :: NUMERIC) / ((SUM(total_order_value) OVER()) :: NUMERIC)) * 100), 2) AS total_order_value_share_pct,
	avg_selling_price
FROM
	category_performance
)
SELECT
	(
	SELECT
		SUM(units_sold_share_pct)
	FROM
		(
		SELECT
			units_sold_share_pct
		FROM
			category_summary
		ORDER BY
			units_sold DESC
		LIMIT
			5
		) AS top_5_units_sold
	) AS Unit_Sold_Share,
	(
	SELECT
		SUM(total_order_value_share_pct)
	FROM
		(
		SELECT
			total_order_value_share_pct
		FROM
			category_summary
		ORDER BY
			total_order_value DESC
		LIMIT
			5
		) AS top_5_tov
	) AS Total_Order_Value_Share;










------------------------------------------------------------------------------------------------------------------------------------------------

										-- Product & Category Performance / Customer & Geographic Intelligence Analysis --

-- Analyse Product Category demand across the Top 5 Customer States:

WITH state_category_sales AS
(
SELECT
	dc.customer_state AS state,
	(CASE
		WHEN (dp.product_category_name_english IS NULL AND dp.product_category_name IS NOT NULL) THEN 'untranslated'
		WHEN (dp.product_category_name IS NULL) THEN 'unknown'
		ELSE dp.product_category_name_english
	END) AS category,
	COUNT(foi.*) AS units_sold
FROM
	analytics.fact_order_items foi LEFT JOIN analytics.dim_customers dc ON foi.customer_id = dc.customer_id
								   LEFT JOIN analytics.dim_products dp ON foi.product_id = dp.product_id
WHERE
	foi.order_status = 'delivered'
	AND
	dc.customer_state IN ('SP', 'RJ', 'MG', 'RS', 'PR')
GROUP BY
	dc.customer_state,
	(CASE
		WHEN (dp.product_category_name_english IS NULL AND dp.product_category_name IS NOT NULL) THEN 'untranslated'
		WHEN (dp.product_category_name IS NULL) THEN 'unknown'
		ELSE dp.product_category_name_english
	END)
),
category_rank AS
(
SELECT
	state,
	category,
	units_sold,
	(DENSE_RANK() OVER(PARTITION BY state ORDER BY units_sold DESC)) AS category_rank_by_state,
	ROUND((((units_sold :: NUMERIC) / ((SUM(units_sold) OVER(PARTITION BY state)) :: NUMERIC)) * 100), 2) AS category_share
FROM
	state_category_sales
),
top_5_categories AS
(
SELECT
	state,
	category,
	units_sold,
	category_rank_by_state,
	category_share
FROM
	category_rank
WHERE
	category_rank_by_state <= 5
)
SELECT
	state,
	STRING_AGG(category, ', ' ORDER BY category_rank_by_state) AS top_categories,
	SUM(category_share) AS top_5_concentration
FROM
	top_5_categories
GROUP BY
	state
ORDER BY
	state DESC;










------------------------------------------------------------------------------------------------------------------------------------------------

										-- Seller Intelligence Analysis --

-- Analyse Seller Performance and Commercial Value contribution:

SELECT
	seller_id,
	COUNT(*) AS units_sold,
	COUNT(DISTINCT(order_id)) AS completed_orders,
	SUM(item_total_value) AS total_order_value,
	ROUND(AVG(price), 2) AS avg_selling_price
FROM
	analytics.fact_order_items
WHERE
	order_status = 'delivered'
GROUP BY
	seller_id
ORDER BY
	total_order_value DESC;

-- Analyse marketplace Commercial Value concentration among Top Sellers (1%, 5%, 10%):

WITH indv_seller_sales AS
(
SELECT
	seller_id,
	COUNT(*) AS units_sold,
	COUNT(DISTINCT(order_id)) AS completed_orders,
	SUM(item_total_value) AS total_order_value,
	ROUND(AVG(price), 2) AS avg_selling_price
FROM
	analytics.fact_order_items
WHERE
	order_status = 'delivered'
GROUP BY
	seller_id
),
seller_ranks AS
(
SELECT
	seller_id,
	total_order_value,
	ROW_NUMBER() OVER(ORDER BY total_order_value DESC, seller_id ASC) AS seller_rank,
	COUNT(seller_id) OVER() AS total_sellers
FROM
	indv_seller_sales
)
SELECT
	'Top 1%' AS seller_group,
	(COUNT(seller_id) FILTER (WHERE seller_rank <= CEIL((total_sellers :: NUMERIC) * 0.01))) AS seller_count,
	(SUM(total_order_value) FILTER (WHERE seller_rank <= CEIL((total_sellers :: NUMERIC) * 0.01))) AS top_total_order_value,
	ROUND(((((SUM(total_order_value) FILTER (WHERE seller_rank <= CEIL((total_sellers :: NUMERIC) * 0.01))) :: NUMERIC) / (SUM(total_order_value) :: NUMERIC)) * 100), 2) AS share_of_marketplace_value_pct
FROM
	seller_ranks
UNION ALL
SELECT
	'Top 5%' AS seller_group,
	(COUNT(seller_id) FILTER (WHERE seller_rank <= CEIL((total_sellers :: NUMERIC) * 0.05))) AS seller_count,
	(SUM(total_order_value) FILTER (WHERE seller_rank <= CEIL((total_sellers :: NUMERIC) * 0.05))) AS top_total_order_value,
	ROUND(((((SUM(total_order_value) FILTER (WHERE seller_rank <= CEIL((total_sellers :: NUMERIC) * 0.05))) :: NUMERIC) / (SUM(total_order_value) :: NUMERIC)) * 100), 2) AS share_of_marketplace_value_pct
FROM
	seller_ranks
UNION ALL
SELECT
	'Top 10%' AS seller_group,
	(COUNT(seller_id) FILTER (WHERE seller_rank <= CEIL((total_sellers :: NUMERIC) * 0.1))) AS seller_count,
	(SUM(total_order_value) FILTER (WHERE seller_rank <= CEIL((total_sellers :: NUMERIC) * 0.1))) AS top_total_order_value,
	ROUND(((((SUM(total_order_value) FILTER (WHERE seller_rank <= CEIL((total_sellers :: NUMERIC) * 0.1))) :: NUMERIC) / (SUM(total_order_value) :: NUMERIC)) * 100), 2) AS share_of_marketplace_value_pct
FROM
	seller_ranks;










------------------------------------------------------------------------------------------------------------------------------------------------

										-- Seller & Geographic Intelligence Analysis --

-- Analyse Seller Geographic distribution and Commercial contribution:

WITH state_metrics AS
(
SELECT
	ds.seller_state,
	COUNT(DISTINCT(foi.seller_id)) AS active_sellers,
	COUNT(foi.*) AS units_sold,
	COUNT(DISTINCT(foi.order_id)) AS completed_orders,
	SUM(foi.item_total_value) AS total_order_value
FROM
	analytics.fact_order_items foi LEFT JOIN analytics.dim_sellers ds
										ON foi.seller_id = ds.seller_id
WHERE
	foi.order_status = 'delivered'
GROUP BY
	ds.seller_state
)
SELECT
	seller_state,
	active_sellers,
	ROUND((((active_sellers :: NUMERIC) / ((SUM(active_sellers) OVER()) :: NUMERIC)) * 100), 2) AS seller_share_pct,
	units_sold,
	ROUND((((units_sold :: NUMERIC) / ((SUM(units_sold) OVER()) :: NUMERIC)) * 100), 2) AS units_share_pct,
	completed_orders,
	total_order_value,
	ROUND((((total_order_value :: NUMERIC) / ((SUM(total_order_value) OVER()) :: NUMERIC)) * 100), 2) AS value_share_pct
FROM
	state_metrics
ORDER BY
	total_order_value DESC;

-- QA Validation for previous query:

WITH state_metrics AS
(
SELECT
	ds.seller_state,
	COUNT(DISTINCT(foi.seller_id)) AS active_sellers,
	COUNT(foi.*) AS units_sold,
	COUNT(DISTINCT(foi.order_id)) AS completed_orders,
	SUM(foi.item_total_value) AS total_order_value
FROM
	analytics.fact_order_items foi LEFT JOIN analytics.dim_sellers ds
										ON foi.seller_id = ds.seller_id
WHERE
	foi.order_status = 'delivered'
GROUP BY
	ds.seller_state
),
state_summary AS
(
SELECT
	seller_state,
	active_sellers,
	ROUND((((active_sellers :: NUMERIC) / ((SUM(active_sellers) OVER()) :: NUMERIC)) * 100), 2) AS seller_share_pct,
	units_sold,
	ROUND((((units_sold :: NUMERIC) / ((SUM(units_sold) OVER()) :: NUMERIC)) * 100), 2) AS units_share_pct,
	completed_orders,
	total_order_value,
	ROUND((((total_order_value :: NUMERIC) / ((SUM(total_order_value) OVER()) :: NUMERIC)) * 100), 2) AS value_share_pct
FROM
	state_metrics
)
SELECT
	SUM(active_sellers) AS total_sellers,
	SUM(units_sold) AS total_units_sold,
	SUM(total_order_value) AS TOTAL_order_value
FROM
	state_summary;










------------------------------------------------------------------------------------------------------------------------------------------------

										-- Fulfilment & Delivery Performance Analysis --

-- Analyse overall Order Fulfilment and Delivery Performance:

SELECT
	order_status,
	COUNT(order_id) AS total_orders,
	ROUND((((COUNT(order_id) :: NUMERIC) / ((SUM(COUNT(order_id)) OVER()) :: NUMERIC)) * 100), 2) AS share_of_orders_pct
FROM
	analytics.fact_orders
GROUP BY
	order_status
ORDER BY
	total_orders DESC;

-- Analyse Delivery timeliness and Average Delivery duration:

SELECT
	COUNT(order_id) AS total_delivered_orders,
	(COUNT(order_id) FILTER (WHERE (order_delivered_customer_date :: DATE) <= order_estimated_delivery_date)) AS on_time_deliveries,
	(COUNT(order_id) FILTER (WHERE (order_delivered_customer_date :: DATE) > order_estimated_delivery_date)) AS late_deliveries,
	ROUND(((((COUNT(order_id) FILTER (WHERE (order_delivered_customer_date :: DATE) <= order_estimated_delivery_date)) :: NUMERIC) / (COUNT(order_id) :: NUMERIC)) * 100), 2) AS on_time_rate_pct,
	ROUND(((((COUNT(order_id) FILTER (WHERE (order_delivered_customer_date :: DATE) > order_estimated_delivery_date)) :: NUMERIC) / (COUNT(order_id) :: NUMERIC)) * 100), 2) AS late_rate_pct,
	ROUND(AVG(delivery_duration_days), 2) AS avg_delivery_days,
	ROUND((AVG(delivery_variance_days) FILTER (WHERE delivery_performance = 'Late')), 2) AS avg_delay_days_late
FROM
	analytics.fact_orders
WHERE
	order_status = 'delivered';

-- QA Validation of delivered orders discrepancy:

SELECT
	(COUNT(order_id) FILTER (WHERE order_delivered_customer_date IS NULL)) AS missing_actual_delivery_date,
	(COUNT(order_id) FILTER (WHERE order_estimated_delivery_date IS NULL)) AS missing_estimated_delivery_date,
	(COUNT(order_id) FILTER (WHERE (order_delivered_customer_date IS NULL) AND (order_estimated_delivery_date IS NULL))) AS missing_both_dates
FROM
	analytics.fact_orders
WHERE
	order_status = 'delivered';

-- Examining the distribution of delivery delays:

SELECT
	(CASE
		WHEN (delivery_variance_days BETWEEN 1 AND 3) THEN '1 - 3 days'
		WHEN (delivery_variance_days BETWEEN 4 AND 7) THEN '4 - 7 days'
		WHEN (delivery_variance_days BETWEEN 8 AND 14) THEN '8 - 14 days'
		WHEN (delivery_variance_days BETWEEN 15 AND 30) THEN '15 - 30 days'
		WHEN (delivery_variance_days > 30) THEN 'Over 30 days'
		ELSE 'Unclassified'
	END) AS delay_group,
	COUNT(order_id) AS late_orders,
	ROUND((((COUNT(order_id) :: NUMERIC) / ((SUM(COUNT(order_id)) OVER()) :: NUMERIC)) * 100), 2) AS share_of_late_orders_pct
FROM
	analytics.fact_orders
WHERE
	delivery_performance = 'Late'
	AND
	order_status = 'delivered'
GROUP BY
	delay_group
ORDER BY
	late_orders DESC;

-- One Late order Discrepancy:

SELECT
	order_id,
	order_status,
	order_delivered_customer_date,
	order_estimated_delivery_date,
	delivery_variance_days,
	delivery_performance
FROM
	analytics.fact_orders
WHERE
	order_status != 'delivered'
	AND
	delivery_performance = 'Late';










------------------------------------------------------------------------------------------------------------------------------------------------

										-- Geographic Delivery Performance Analysis --

-- Analyse Geographic Differences in Delivery Performance:

SELECT
	dc.customer_state,
	COUNT(fo.order_id) AS delivered_orders,
	(COUNT(fo.order_id) FILTER (WHERE (fo.order_delivered_customer_date :: DATE) <= fo.order_estimated_delivery_date)) AS on_time_deliveries,
	(COUNT(fo.order_id) FILTER (WHERE (fo.order_delivered_customer_date :: DATE) > fo.order_estimated_delivery_date)) AS late_deliveries,
	COUNT(fo.order_id) FILTER (WHERE fo.order_delivered_customer_date IS NOT NULL AND fo.order_estimated_delivery_date IS NOT NULL) AS evaluable_deliveries,
	ROUND(COUNT(fo.order_id) FILTER (WHERE fo.order_delivered_customer_date::DATE <= fo.order_estimated_delivery_date)::NUMERIC / NULLIF(COUNT(fo.order_id) FILTER (WHERE fo.order_delivered_customer_date IS NOT NULL AND fo.order_estimated_delivery_date IS NOT NULL), 0) * 100, 2) AS on_time_rate_pct,
	ROUND(COUNT(fo.order_id) FILTER (WHERE fo.order_delivered_customer_date::DATE > fo.order_estimated_delivery_date)::NUMERIC / NULLIF(COUNT(fo.order_id) FILTER (WHERE fo.order_delivered_customer_date IS NOT NULL AND fo.order_estimated_delivery_date IS NOT NULL), 0) * 100, 2) AS late_rate_pct,
	ROUND(AVG(fo.delivery_duration_days), 2) AS avg_delivery_days,
	ROUND((AVG(fo.delivery_variance_days) FILTER (WHERE fo.delivery_performance = 'Late')), 2) AS avg_delay_days_late
FROM
	analytics.fact_orders fo INNER JOIN analytics.dim_customers dc
									ON fo.customer_id = dc.customer_id
WHERE
	fo.order_status = 'delivered'
GROUP BY
	dc.customer_state
ORDER BY
	late_rate_pct DESC;

-- Which five customer states account for the greatest number of late deliveries, and what percentage of all marketplace late deliveries does each state represent?

WITH delivery_stats AS
(
SELECT
	dc.customer_state,
	COUNT(fo.order_id) AS delivered_orders,
	(COUNT(fo.order_id) FILTER (WHERE (fo.order_delivered_customer_date :: DATE) <= fo.order_estimated_delivery_date)) AS on_time_deliveries,
	(COUNT(fo.order_id) FILTER (WHERE (fo.order_delivered_customer_date :: DATE) > fo.order_estimated_delivery_date)) AS late_deliveries,
	COUNT(fo.order_id) FILTER (WHERE fo.order_delivered_customer_date IS NOT NULL AND fo.order_estimated_delivery_date IS NOT NULL) AS evaluable_deliveries,
	ROUND(COUNT(fo.order_id) FILTER (WHERE fo.order_delivered_customer_date::DATE <= fo.order_estimated_delivery_date)::NUMERIC / NULLIF(COUNT(fo.order_id) FILTER (WHERE fo.order_delivered_customer_date IS NOT NULL AND fo.order_estimated_delivery_date IS NOT NULL), 0) * 100, 2) AS on_time_rate_pct,
	ROUND(COUNT(fo.order_id) FILTER (WHERE fo.order_delivered_customer_date::DATE > fo.order_estimated_delivery_date)::NUMERIC / NULLIF(COUNT(fo.order_id) FILTER (WHERE fo.order_delivered_customer_date IS NOT NULL AND fo.order_estimated_delivery_date IS NOT NULL), 0) * 100, 2) AS late_rate_pct,
	ROUND(AVG(fo.delivery_duration_days), 2) AS avg_delivery_days,
	ROUND((AVG(fo.delivery_variance_days) FILTER (WHERE fo.delivery_performance = 'Late')), 2) AS avg_delay_days_late
FROM
	analytics.fact_orders fo INNER JOIN analytics.dim_customers dc
									ON fo.customer_id = dc.customer_id
WHERE
	fo.order_status = 'delivered'
GROUP BY
	dc.customer_state
)
SELECT
	customer_state,
	late_deliveries,
	ROUND((((late_deliveries :: NUMERIC) / ((SUM(late_deliveries) OVER()) :: NUMERIC)) * 100), 2) AS share_of_all_late_deliveries_pct
FROM
	delivery_stats
ORDER BY
	share_of_all_late_deliveries_pct DESC
LIMIT
	5;










------------------------------------------------------------------------------------------------------------------------------------------------

										-- Customer Satisfaction & Review Performance Analysis --

-- Analyse Customer Review Score Distribution:

SELECT
	review_score,
	COUNT(review_score) AS total_reviews,
	ROUND((((COUNT(review_score) :: NUMERIC) / ((SUM(COUNT(review_score)) OVER()) :: NUMERIC)) * 100), 2) AS share_of_reviews_pct
FROM
	analytics.fact_reviews
GROUP BY
	review_score
ORDER BY
	review_score ASC;

-- How many distinct orders have at least one review, and what percentage of all orders does this represent?

SELECT
	COUNT(DISTINCT(fo.order_id)) AS total_orders,
	(COUNT(DISTINCT(fo.order_id)) FILTER (WHERE fr.review_id IS NOT NULL)) AS orders_with_reviews,
	(COUNT(DISTINCT(fo.order_id)) FILTER (WHERE fr.review_id IS NULL)) AS orders_without_reviews,
	ROUND(((((COUNT(DISTINCT(fo.order_id)) FILTER (WHERE fr.review_id IS NOT NULL)) :: NUMERIC) / NULLIF(COUNT(DISTINCT(fo.order_id)), 0)) * 100), 2) AS review_coverage_pct
FROM
	analytics.fact_orders fo LEFT JOIN analytics.fact_reviews fr
									ON fo.order_id = fr.order_id

-- Do late deliveries receive worse customer review scores than on-time deliveries?

SELECT
	fo.delivery_performance,
	COUNT(DISTINCT(fr.order_id)) AS reviewed_orders,
	COUNT(*) AS total_reviews,
	ROUND(AVG(fr.review_score), 2) AS avg_review_score,
	ROUND(((((COUNT(*) FILTER (WHERE fr.review_score IN (4, 5))) :: NUMERIC) / (COUNT(*) :: NUMERIC)) * 100), 2) AS positive_review_rate_pct,
	ROUND(((((COUNT(*) FILTER (WHERE fr.review_score IN (1, 2))) :: NUMERIC) / (COUNT(*) :: NUMERIC)) * 100), 2) AS negative_review_rate_pct
FROM
	analytics.fact_reviews fr INNER JOIN analytics.fact_orders fo
									ON fr.order_id = fo.order_id
WHERE
	fo.delivery_performance IS NOT NULL
	AND
	fo.order_status = 'delivered'
GROUP BY
	fo.delivery_performance;










------------------------------------------------------------------------------------------------------------------------------------------------

										-- Payment Methods & Customer Spending Analysis --

-- Which payment methods are used most frequently, and what proportion of total payment value does each method represent?

SELECT
	payment_type,
	COUNT(*) AS payment_records,
	COUNT(DISTINCT(order_id)) AS distinct_orders,
	ROUND((((COUNT(*) :: NUMERIC) / ((SUM(COUNT(*)) OVER()) :: NUMERIC)) * 100), 2) AS payments_records_share_pct,
	SUM(payment_value) AS total_payment_value,
	ROUND(((((SUM(payment_value) :: NUMERIC) / (SUM(SUM(payment_value)) OVER()) :: NUMERIC)) * 100), 2) AS payment_value_share_pct,
	ROUND(AVG(payment_value), 2) AS avg_payment_value
FROM
	analytics.fact_payments
GROUP BY
	payment_type
ORDER BY
	payment_records DESC;

-- How does total recorded payment value differ between Delivered and non-Delivered orders?

SELECT
	(CASE
		WHEN fo.order_status = 'delivered' THEN 'Delivered'
		ELSE 'Non-Delivered'
	END) AS order_group,
	COUNT(DISTINCT(fo.order_id)) AS distinct_orders,
	COUNT(fp.*) AS payment_records,
	SUM(fp.payment_value) AS total_payment_value
FROM
	analytics.fact_orders fo INNER JOIN analytics.fact_payments fp
									ON fo.order_id = fp.order_id
GROUP BY
	order_group;

-- Which order has no corresponding payment record, and what is its order status?

SELECT
	fo.order_id,
	fo.order_status
FROM
	analytics.fact_orders fo LEFT JOIN analytics.fact_payments fp
									ON fo.order_id = fp.order_id
WHERE
	fp.order_id IS NULL;

-- How does credit-card payment activity and average payment value vary by the number of instalments?

SELECT
	payment_instalments,
	COUNT(*) AS payment_records,
	COUNT(DISTINCT(order_id)) AS distinct_orders,
	SUM(payment_value) AS total_payment_value,
	ROUND(AVG(payment_value), 2) AS avg_payment_value
FROM
	analytics.fact_payments
WHERE
	payment_type = 'credit_card'
GROUP BY
	payment_instalments
ORDER BY
	payment_instalments ASC;

-- How many credit-card orders have more than one distinct instalment count?

WITH instalment_count AS
(
SELECT
	order_id,
	COUNT(DISTINCT(payment_instalments)) AS distinct_instalment_counts
FROM
	analytics.fact_payments
WHERE
	payment_type = 'credit_card'
GROUP BY
	order_id
)
SELECT
	(CASE
		WHEN distinct_instalment_counts = 1 THEN 'Consistent'
		ELSE 'Conflicting'
	END) AS instalment_count_category,
	COUNT(DISTINCT(order_id)) AS distinct_orders
FROM
	instalment_count
GROUP BY
	instalment_count_category;

-- How does average total order value vary between orders using different credit-card instalment counts?

WITH order_values AS
(
SELECT
	order_id,
	SUM(item_total_value) AS total_order_value
FROM
	analytics.fact_order_items
GROUP BY
	order_id
),
instalment_count AS
(
SELECT
	order_id,
	COUNT(DISTINCT(payment_instalments)) AS distinct_instalment_counts
FROM
	analytics.fact_payments
WHERE
	payment_type = 'credit_card'
GROUP BY
	order_id
),
credit_card_instalments AS
(
SELECT
	order_id,
	MAX(payment_instalments) AS payment_instalments
FROM
	analytics.fact_payments
WHERE
	payment_type = 'credit_card'
GROUP BY
	order_id
			HAVING
					COUNT(DISTINCT(payment_instalments)) =1
)
SELECT
	(CASE 
		WHEN cci.payment_instalments = 0 THEN 'Exceptional (0)'
		WHEN cci.payment_instalments = 1 THEN 'Single Payment (1)'
		WHEN cci.payment_instalments IN (2, 3) THEN 'Short (2-3)'
		WHEN cci.payment_instalments IN (4, 5, 6) THEN 'Medium (4-6)'
		WHEN cci.payment_instalments IN (7, 8, 9, 10, 11, 12) THEN 'Long (7-12)'
		ELSE 'Extended (13+)'
	END) AS instalment_group,
	COUNT(*) AS distinct_orders,
	ROUND(AVG(ov.total_order_value), 2) AS avg_order_value,
	SUM(ov.total_order_value) AS total_order_value
FROM 
	order_values ov INNER JOIN credit_card_instalments cci ON ov.order_id = cci.order_id
					INNER JOIN analytics.fact_orders fo ON ov.order_id = fo.order_id
WHERE
	fo.order_status = 'delivered'
GROUP BY
	instalment_group
ORDER BY
	instalment_group DESC;










------------------------------------------------------------------------------------------------------------------------------------------------

										-- Freight Costs & Order Economics Analysis --

-- Distribution Analysis of freight cost as a pct of merchandise value, on the order-level grain:

WITH freight_calc AS
(
SELECT
	order_id,
	SUM(price) AS merchandise_value,
	SUM(freight_value) AS freight_value,
	ROUND((((SUM(freight_value) :: NUMERIC) / (NULLIF(SUM(price), 0))) * 100), 2) AS freight_pct
FROM
	analytics.fact_order_items
WHERE
	order_status = 'delivered'
GROUP BY
	order_id
)
SELECT
	(CASE
		WHEN freight_pct <= 10 THEN '0% - 10%'
		WHEN freight_pct <= 20 THEN '>10% - 20%'
		WHEN freight_pct <= 30 THEN '>20% - 30%'
		WHEN freight_pct <= 40 THEN '>30% - 40%'
		WHEN freight_pct <= 50 THEN '>40% - 50%'
		ELSE '>50%'
	END) AS freight_group,
	COUNT(order_id) AS total_orders,
	ROUND((((COUNT(order_id) :: NUMERIC) / ((SUM(COUNT(order_id)) OVER()) :: NUMERIC)) * 100), 2) AS pct_of_delivered_orders
FROM
	freight_calc
GROUP BY
	freight_group
ORDER BY
	freight_group ASC;

-- Testing if lower Average Merchandise Value can be a possible reason for the existence of >50% freight charges:

WITH freight_calc AS
(
SELECT
	order_id,
	SUM(price) AS merchandise_value,
	SUM(freight_value) AS freight_value,
	ROUND((((SUM(freight_value) :: NUMERIC) / (NULLIF(SUM(price), 0))) * 100), 2) AS freight_pct
FROM
	analytics.fact_order_items
WHERE
	order_status = 'delivered'
GROUP BY
	order_id
)
SELECT
	(CASE
		WHEN freight_pct <= 50 THEN 'Less or equal to 50%'
		ELSE 'More than 50%'
	END) AS freight_group,
	COUNT(order_id) AS total_orders,
	ROUND(AVG(merchandise_value), 2) AS avg_merchandise_value,
	ROUND(AVG(freight_value), 2) AS avg_freight_value
FROM
	freight_calc
GROUP BY
	freight_group;

-- Are heavier orders associated with higher average freight charges?

WITH total_order_weight AS
(
SELECT
	foi.order_id,
	SUM(dp.product_weight_g) FILTER (WHERE dp.product_weight_g IS NOT NULL) AS total_order_weight_g,
	COUNT(foi.product_id) FILTER (WHERE dp.product_weight_g IS NOT NULL) AS total_products,
	COUNT(foi.product_id) FILTER (WHERE dp.product_weight_g IS NULL) AS products_in_order_without_weight
FROM
	analytics.fact_order_items foi INNER JOIN analytics.dim_products dp
										ON foi.product_id = dp.product_id
WHERE
	foi.order_status = 'delivered'
GROUP BY
	foi.order_id
)
SELECT
	COUNT(*) AS total_delivered_orders,
	COUNT(*) FILTER (WHERE products_in_order_without_weight = 0) AS order_with_complete_weight_data,
	COUNT(*) FILTER (WHERE products_in_order_without_weight > 0) AS orders_with_atleast_one_missing_weight
FROM
	total_order_weight;
--------------------
WITH total_order_weight AS
(
SELECT
	foi.order_id,
	SUM(dp.product_weight_g) FILTER (WHERE dp.product_weight_g IS NOT NULL) AS total_order_weight_g,
	SUM(foi.freight_value) AS freight_value
FROM
	analytics.fact_order_items foi INNER JOIN analytics.dim_products dp
										ON foi.product_id = dp.product_id
WHERE
	foi.order_status = 'delivered'
GROUP BY
	foi.order_id
				HAVING
						(COUNT(foi.product_id) FILTER (WHERE dp.product_weight_g IS NULL)) = 0
)
SELECT
	(CASE
		WHEN total_order_weight_g <= 1000 THEN '≤ 1kg'
		WHEN total_order_weight_g <= 3000 THEN '>1kg - 3kg'
		WHEN total_order_weight_g <= 5000 THEN '>3kg - 5kg'
		WHEN total_order_weight_g <= 10000 THEN '>5kg - 10kg'
		ELSE '> 10kg'
	END) AS weight_group,
	COUNT(*) AS total_orders,
	ROUND(AVG(freight_value), 2) AS avg_freight,
	ROUND((((COUNT(*) :: NUMERIC) / ((SUM(COUNT(*)) OVER()) :: NUMERIC)) * 100), 2) AS pct_of_total_orders
FROM
	total_order_weight
GROUP BY
	weight_group
ORDER BY
	avg_freight;

-- Are shipments between different Brazilian states associated with higher freight charges than shipments within the same state?

WITH state_diff AS
(
SELECT
	foi.order_id,
	dc.customer_state,
	ds.seller_state,
	foi.freight_value
FROM
	analytics.fact_order_items foi LEFT JOIN analytics.dim_customers dc ON foi.customer_id = dc.customer_id
							   	   LEFT JOIN analytics.dim_sellers ds ON foi.seller_id = ds.seller_id
WHERE
	foi.order_status = 'delivered'
)
SELECT
	(CASE
		WHEN customer_state = seller_state THEN 'Same State'
		ELSE 'Different State'
	END) AS shipping_group,
	COUNT(*) AS total_order_items,
	ROUND(AVG(freight_value), 2) AS avg_freight_per_item
FROM
	state_diff
GROUP BY
	shipping_group;

-- QA

WITH state_diff AS
(
SELECT
	foi.order_id,
	dc.customer_state,
	ds.seller_state,
	foi.freight_value
FROM
	analytics.fact_order_items foi LEFT JOIN analytics.dim_customers dc ON foi.customer_id = dc.customer_id
							   	   LEFT JOIN analytics.dim_sellers ds ON foi.seller_id = ds.seller_id
WHERE
	foi.order_status = 'delivered'
)
SELECT
	COUNT(*) AS total_delivered_order_items,
	(COUNT(*) FILTER (WHERE customer_state IS NULL)) AS items_with_missing_customer_state,
	(COUNT(*) FILTER (WHERE seller_state IS NULL)) AS items_with_missing_seller_state
FROM
	state_diff;










------------------------------------------------------------------------------------------------------------------------------------------------

										-- Customer Retention & Repeat Purchasing Analysis --

-- What proportion of Olist customers placed multiple orders?

WITH order_count AS
(
SELECT
	dc.customer_unique_id,
	COUNT(fo.order_id) AS total_order_count
FROM
	analytics.dim_customers dc INNER JOIN analytics.fact_orders fo
									ON dc.customer_id = fo.customer_id
WHERE
	fo.order_status = 'delivered'
GROUP BY
	dc.customer_unique_id
)
SELECT
	(CASE
		WHEN total_order_count = 1 THEN 'One-time Customers'
		ELSE 'Repeat Customers'
	END) AS customer_type,
	COUNT(customer_unique_id) AS number_of_customers,
	ROUND((((COUNT(customer_unique_id) :: NUMERIC) / (SUM(COUNT(customer_unique_id)) OVER())) * 100), 2) AS pct_of_customers
FROM
	order_count
GROUP BY
	customer_type;

-- How much of Olist’s Total Order Value (TOV) and Average Order Value (AOV) comes from one-time versus repeat customers?

WITH order_count AS
(
SELECT
	dc.customer_unique_id,
	COUNT(DISTINCT(fo.order_id)) AS total_order_count,
	SUM(foi.item_total_value) AS total_order_value,
	SUM(foi.price) AS order_merch_price,
	COUNT(*) AS total_items_purchased
FROM
	analytics.dim_customers dc INNER JOIN analytics.fact_orders fo ON dc.customer_id = fo.customer_id
							   INNER JOIN analytics.fact_order_items foi ON fo.order_id = foi.order_id
WHERE
	fo.order_status = 'delivered'
GROUP BY
	dc.customer_unique_id
)
SELECT
	(CASE
		WHEN total_order_count = 1 THEN 'One-time Customers'
		ELSE 'Repeat Customers'
	END) AS customer_type,
	COUNT(customer_unique_id) AS number_of_customers,
	SUM(total_order_count) AS customer_type_order_count,
	SUM(total_order_value) AS customer_type_tov,
	ROUND((((SUM(total_order_value) :: NUMERIC) / (SUM(SUM(total_order_value)) OVER())) * 100), 2) AS pct_of_tov,
	ROUND(((SUM(total_order_value) :: NUMERIC) / (SUM(total_order_count) :: NUMERIC)), 2) AS avg_order_value,
	ROUND(((SUM(order_merch_price) :: NUMERIC) / (SUM(total_items_purchased) :: NUMERIC)), 2) AS avg_product_price,
	ROUND(((SUM(total_items_purchased) :: NUMERIC) / SUM(total_order_count)), 2) AS avg_items_purchased
FROM
	order_count
GROUP BY
	customer_type;

-- Which product categories are most popular among repeat customers?

WITH category_item_count AS
(
SELECT
	dc.customer_unique_id
FROM
	analytics.dim_customers dc INNER JOIN analytics.fact_orders fo ON dc.customer_id = fo.customer_id
							   INNER JOIN analytics.fact_order_items foi ON fo.order_id = foi.order_id
WHERE
	fo.order_status = 'delivered'
GROUP BY
	dc.customer_unique_id
							HAVING
									COUNT(DISTINCT(fo.order_id)) > 1
)
SELECT
	dp.product_category_name,
	dp.product_category_name_english AS product_category,
	COUNT(foi.*) AS total_items
FROM
	category_item_count cic INNER JOIN analytics.dim_customers dc ON cic.customer_unique_id = dc.customer_unique_id
							INNER JOIN analytics.fact_orders fo ON dc.customer_id = fo.customer_id
							INNER JOIN analytics.fact_order_items foi ON fo.order_id = foi.order_id
							INNER JOIN analytics.dim_products dp ON foi.product_id = dp.product_id
WHERE
	fo.order_status = 'delivered'
GROUP BY
	product_category_name,
	product_category
ORDER BY
	total_items DESC
LIMIT
	5;









------------------------------------------------------------------------------------------------------------------------------------------------

										-- Executive Business Insights & Recommendations --

-- Repeat customer Geographic concentration:

WITH order_count AS
(
SELECT
	dc.customer_unique_id,
	dc.customer_state,
	COUNT(DISTINCT(fo.order_id)) AS total_order_count,
	SUM(foi.item_total_value) AS total_order_value
FROM
	analytics.dim_customers dc INNER JOIN analytics.fact_orders fo ON dc.customer_id = fo.customer_id
							   INNER JOIN analytics.fact_order_items foi ON fo.order_id = foi.order_id
WHERE
	fo.order_status = 'delivered'
GROUP BY
	dc.customer_unique_id,
	dc.customer_state
							HAVING
									COUNT(DISTINCT(fo.order_id)) > 1
)
SELECT
	customer_state AS state,
	COUNT(DISTINCT(customer_unique_id)),
	SUM(total_order_count) AS state_order_count,
	SUM(total_order_value) AS state_tov
FROM
	order_count
GROUP BY
	state
ORDER BY
	state_tov DESC;

-- Which states should we prioritize for improving delivery performance?

WITH delivery_stats AS
(
SELECT
	dc.customer_state,
	COUNT(fo.order_id) AS delivered_orders,
	(COUNT(fo.order_id) FILTER (WHERE (fo.order_delivered_customer_date :: DATE) <= fo.order_estimated_delivery_date)) AS on_time_deliveries,
	(COUNT(fo.order_id) FILTER (WHERE (fo.order_delivered_customer_date :: DATE) > fo.order_estimated_delivery_date)) AS late_deliveries,
	COUNT(fo.order_id) FILTER (WHERE fo.order_delivered_customer_date IS NOT NULL AND fo.order_estimated_delivery_date IS NOT NULL) AS evaluable_deliveries,
	ROUND(COUNT(fo.order_id) FILTER (WHERE fo.order_delivered_customer_date::DATE <= fo.order_estimated_delivery_date)::NUMERIC / NULLIF(COUNT(fo.order_id) FILTER (WHERE fo.order_delivered_customer_date IS NOT NULL AND fo.order_estimated_delivery_date IS NOT NULL), 0) * 100, 2) AS on_time_rate_pct,
	ROUND(COUNT(fo.order_id) FILTER (WHERE fo.order_delivered_customer_date::DATE > fo.order_estimated_delivery_date)::NUMERIC / NULLIF(COUNT(fo.order_id) FILTER (WHERE fo.order_delivered_customer_date IS NOT NULL AND fo.order_estimated_delivery_date IS NOT NULL), 0) * 100, 2) AS late_rate_pct,
	ROUND(AVG(fo.delivery_duration_days), 2) AS avg_delivery_days,
	ROUND((AVG(fo.delivery_variance_days) FILTER (WHERE fo.delivery_performance = 'Late')), 2) AS avg_delay_days_late
FROM
	analytics.fact_orders fo INNER JOIN analytics.dim_customers dc
									ON fo.customer_id = dc.customer_id
WHERE
	fo.order_status = 'delivered'
GROUP BY
	dc.customer_state
)
SELECT
	customer_state,
	late_deliveries,
	ROUND((((late_deliveries :: NUMERIC) / (evaluable_deliveries :: NUMERIC)) * 100), 2) late_deliveries_by_state_pct,
	ROUND((((late_deliveries :: NUMERIC) / ((SUM(late_deliveries) OVER()) :: NUMERIC)) * 100), 2) AS share_of_all_late_deliveries_pct
FROM
	delivery_stats
ORDER BY
	share_of_all_late_deliveries_pct DESC
LIMIT
	5;

-- Are unavailable orders concentrated among particular months?

SELECT
	dd.month_name,
	dd.year,
	COUNT(fo.*) AS total_orders,
	COUNT(fo.order_id) FILTER (WHERE fo.order_status = 'unavailable') AS unavailable_orders,
	ROUND(((((COUNT(fo.order_id) FILTER (WHERE fo.order_status = 'unavailable')) :: NUMERIC) / (COUNT(fo.*) :: NUMERIC)) * 100), 2) AS unavailable_monthly_rate
FROM
	analytics.fact_orders fo INNER JOIN analytics.dim_dates dd
									ON (fo.order_purchase_timestamp :: DATE) = dd.date
GROUP BY
	dd.month_name,
	dd.month_number,
	dd.year
ORDER BY
	dd.year ASC,
	dd.month_number ASC;










-----------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------




											"DASHBOARD & REPORTING STAGE"




------------------------------------------------------------------------------------------------------------------------------------------------

-- Altering and Updating analytics.fact_reviews to add order_purchase_date for analysis purposes:
-- One - time migration

ALTER TABLE analytics.fact_reviews
ADD COLUMN
	order_purchase_date DATE;

UPDATE analytics.fact_reviews fr
SET
	order_purchase_date = fo.order_purchase_timestamp :: DATE
FROM
	analytics.fact_orders fo
WHERE
	fr.order_id = fo.order_id;

-- Validating alteration:

SELECT
	*
FROM
	analytics.fact_reviews;

SELECT
	COUNT(*) AS total_reviews,
	COUNT(order_purchase_date) AS reviews_with_purchase_date,
	COUNT(*) - COUNT(order_purchase_date) AS missing_purchase_dates
FROM
	analytics.fact_reviews;

SELECT
	SUM(price)
FROM
	analytics.fact_order_items
WHERE
	order_status = 'delivered';

-- Validating DAX results:

SELECT
	COUNT(*) AS total_rows,
	COUNT(DISTINCT(order_id)) AS distinct_orders
FROM
	analytics.fact_orders;
--------------------
SELECT
	COUNT(*) AS total_rows
FROM
	analytics.fact_reviews;
--------------------
SELECT
    COUNT(*) AS joined_rows,
    COUNT(DISTINCT r.review_id) AS distinct_review_ids
FROM analytics.fact_reviews r
LEFT JOIN analytics.fact_orders o
    ON r.order_id = o.order_id;
--------------------
SELECT
	dc.customer_unique_id,
	COUNT(order_id)
FROM
	analytics.dim_customers dc INNER JOIN analytics.fact_orders fo
									ON dc.customer_id = fo.customer_id
WHERE
	fo.order_status = 'delivered'
GROUP BY
	dc.customer_unique_id
						HAVING
								COUNT(fo.order_id) > 1;
--------------------
SELECT
    ROUND(AVG(EXTRACT(EPOCH FROM (order_delivered_customer_date - order_purchase_timestamp)) / 86400.0), 2) AS avg_delivery_time_days
FROM
    analytics.fact_orders
WHERE
    order_status = 'delivered'
    AND order_purchase_timestamp IS NOT NULL
    AND order_delivered_customer_date IS NOT NULL;
--------------------
SELECT
	COUNT(*) AS delivered_orders,
	COUNT(delivery_variance_days) AS valid_delivery_variances,
	COUNT(*) - COUNT(delivery_variance_days) AS missing_delivery_variances,
	COUNT(*) FILTER (WHERE delivery_variance_days <= 0) AS on_time_deliveries
FROM
	analytics.fact_orders
WHERE
	order_status = 'delivered';
--------------------
SELECT
	ROUND(AVG(fr.review_score), 2) AS avg_review_score,
	COUNT(*) AS review_records,
	COUNT(DISTINCT(fr.order_id)) AS reviewed_orders
FROM
	analytics.fact_orders fo INNER JOIN analytics.fact_reviews fr
									ON fo.order_id = fr.order_id
WHERE
	fo.order_status = 'delivered';
--------------------
SELECT
	(COUNT(fr.review_id) FILTER (WHERE fr.review_score <= 2)) AS low_reviews,
	COUNT(fr.review_id) AS total_reviews,
	ROUND(((((COUNT(fr.review_id) FILTER (WHERE fr.review_score <= 2)) :: NUMERIC) / (COUNT(fr.review_id) :: NUMERIC)) * 100), 2) AS low_review_pct
FROM
	analytics.fact_reviews fr INNER JOIN analytics.fact_orders fo
									ON fr.order_id = fo.order_id
WHERE
	fo.order_status = 'delivered';
--------------------
SELECT
	(COUNT(fr.review_id) FILTER (WHERE fr.review_score <= 2)) AS low_reviews,
	COUNT(fr.review_id) AS total_reviews,
	ROUND(((((COUNT(fr.review_id) FILTER (WHERE fr.review_score <= 2)) :: NUMERIC) / (COUNT(fr.review_id) :: NUMERIC)) * 100), 2) AS low_review_pct
FROM
	analytics.fact_reviews fr INNER JOIN analytics.fact_orders fo
									ON fr.order_id = fo.order_id;
--------------------
SELECT
	COUNT(fr.review_id) AS total_reviews,
	(COUNT(fr.review_id) FILTER (WHERE fr.review_score >= 4)) AS high_reviews,
	(COUNT(fr.review_id) FILTER (WHERE fr.review_score = 3)) AS med_reviews,
	(COUNT(fr.review_id) FILTER (WHERE fr.review_score <= 2)) AS low_reviews,
	ROUND(((((COUNT(fr.review_id) FILTER (WHERE fr.review_score >= 4)) :: NUMERIC) / (COUNT(fr.review_id) :: NUMERIC)) * 100), 2) AS high_review_pct,
	ROUND(((((COUNT(fr.review_id) FILTER (WHERE fr.review_score = 3)) :: NUMERIC) / (COUNT(fr.review_id) :: NUMERIC)) * 100), 2) AS med_review_pct,
	ROUND(((((COUNT(fr.review_id) FILTER (WHERE fr.review_score <= 2)) :: NUMERIC) / (COUNT(fr.review_id) :: NUMERIC)) * 100), 2) AS low_review_pct
FROM
	analytics.fact_reviews fr INNER JOIN analytics.fact_orders fo
									ON fr.order_id = fo.order_id
WHERE
	fo.order_status = 'delivered';
--------------------
SELECT
	COUNT(DISTINCT(foi.seller_id)) AS distinct_sellers,
	COUNT(DISTINCT(foi.product_id)) AS distinct_products,
	COUNT(DISTINCT(dp.product_category_name)) FILTER (WHERE dp.product_category_name IS NOT NULL) AS distinct_product_categories
FROM
	analytics.fact_order_items foi LEFT JOIN analytics.dim_products dp
											ON foi.product_id = dp.product_id
WHERE
	foi.order_status = 'delivered';
--------------------
SELECT
    COUNT(*) AS delivered_orders,
    COUNT(delivery_variance_days) AS valid_delivery_records,
    COUNT(*) - COUNT(delivery_variance_days) AS missing_delivery_records
FROM 
	analytics.fact_orders
WHERE 
	order_status = 'delivered';
--------------------
SELECT
    COUNT(fr.review_id) AS total_reviews,
    COUNT(fr.review_id) FILTER (WHERE fr.review_score <= 2) AS negative_reviews,
    ROUND(AVG(fr.review_score)::NUMERIC, 2) AS avg_review_score,
    ROUND(100.0 * COUNT(fr.review_id) FILTER (WHERE fr.review_score <= 2) / NULLIF(COUNT(fr.review_id), 0), 2) AS negative_review_rate_pct
FROM 
	analytics.fact_reviews fr INNER JOIN analytics.fact_orders fo
			    						ON fr.order_id = fo.order_id
WHERE 
	fo.order_status = 'delivered';
--------------------
SELECT
    COUNT(*) AS total_late_deliveries,
    COUNT(*) FILTER (WHERE delivery_variance_days <> TRUNC(delivery_variance_days)) AS fractional_day_records,
    MIN(delivery_variance_days) AS minimum_delay,
    MAX(delivery_variance_days) AS maximum_delay
FROM 
	analytics.fact_orders
WHERE 
	order_status = 'delivered'
  	AND 
	delivery_variance_days > 0;
--------------------
SELECT
	COUNT(*) AS payment_records,
	COUNT(DISTINCT(fp.order_id)) AS distinct_orders
FROM
	analytics.fact_payments fp LEFT JOIN analytics.fact_orders fo
									ON fp.order_id = fo.order_id;
--------------------
SELECT
	COUNT(*) AS total_payment_records
FROM
	analytics.fact_orders fo LEFT JOIN analytics.fact_payments fp
									ON fo.order_id = fp.order_id
WHERE
	((fp.order_id IS NULL) OR (fp.order_id = ''))
	AND
	fo.order_status = 'delivered';
--------------------
SELECT
	SUM(payment_value) AS total_payment_value
FROM
	analytics.fact_payments fp
WHERE
	order_status = 'delivered';
--------------------
SELECT 
	SUM(price) AS total_price,
	SUM(freight_value) AS total_freight
FROM
	analytics.fact_order_items foi
WHERE
	order_status = 'delivered';
--------------------
WITH pmt_reconc AS
(
SELECT
	order_id,
	SUM(payment_value) AS total_payment_value
FROM
	analytics.fact_payments
GROUP BY
	order_id
),
value_reconc AS
(
SELECT
	order_id,
	order_status,
	SUM(item_total_value) AS total_order_value
FROM
	analytics.fact_order_items
GROUP BY
	order_id,
	order_status
),
reconc AS
(
SELECT
	pr.order_id,
	vr.order_status,
	total_payment_value,
	total_order_value
FROM
	pmt_reconc pr INNER JOIN value_reconc vr
						ON pr.order_id = vr.order_id
WHERE
	order_status = 'delivered'
)
SELECT
	COUNT(order_id) FILTER (WHERE ROUND(total_payment_value :: NUMERIC, 2) = ROUND(total_order_value :: NUMERIC, 2)) AS total_equal_orders,
	COUNT(order_id) FILTER (WHERE ROUND(total_payment_value :: NUMERIC, 2) <> ROUND(total_order_value :: NUMERIC, 2)) AS total_unequal_orders,
	ROUND(SUM(ABS(ROUND(total_payment_value :: NUMERIC, 2) - ROUND(total_order_value :: NUMERIC, 2))), 2) AS abs_diff 
FROM
	reconc;
--------------------
SELECT
	COUNT(DISTINCT(order_id))
FROM
	analytics.fact_payments
WHERE
	payment_sequential > 1;
--------------------
WITH pmt_reconc AS
(
SELECT
	order_id,
	SUM(payment_value) AS total_payment_value
FROM
	analytics.fact_payments
GROUP BY
	order_id
),
value_reconc AS
(
SELECT
	order_id,
	order_status,
	SUM(item_total_value) AS total_order_value
FROM
	analytics.fact_order_items
GROUP BY
	order_id,
	order_status
),
reconc AS
(
SELECT
	pr.order_id,
	vr.order_status,
	total_payment_value,
	total_order_value
FROM
	pmt_reconc pr INNER JOIN value_reconc vr
						ON pr.order_id = vr.order_id
WHERE
	order_status = 'delivered'
),
reconc_2 AS
(
SELECT
	order_id,
	total_payment_value,
	total_order_value,
	(ROUND(total_payment_value, 2) - ROUND(total_order_value, 2)) AS difference,
	ABS(ROUND(total_payment_value, 2) - ROUND(total_order_value, 2)) AS abs_diff
FROM
	reconc
)
SELECT
	COUNT(*) FILTER (WHERE difference > 0) AS count_positive,
	SUM(difference) FILTER (WHERE difference > 0) AS positive_diff,
	COUNT(*) FILTER (WHERE difference < 0) AS count_negative,
	SUM(difference) FILTER (WHERE difference < 0) AS negative_diff,
	SUM(abs_diff)
FROM
	reconc_2
WHERE
	difference <> 0;
--------------------
WITH missing_payment AS
(
SELECT
	fo.order_id
FROM
	analytics.fact_orders fo LEFT JOIN analytics.fact_payments fp
									ON fo.order_id = fp.order_id
WHERE
	fp.order_id IS NULL
	AND
	fo.order_status = 'delivered'
)
SELECT
	foi.order_id,
	foi.price,
	foi.freight_value,
	foi.item_total_value
FROM
	missing_payment mp LEFT JOIN analytics.fact_order_items foi
							ON mp.order_id = foi.order_id;
--------------------
SELECT
	*
FROM
	analytics.fact_payments;
--------------------
SELECT
	COUNT(DISTINCT(order_id)) AS total_count
FROM
	analytics.dim_products dp INNER JOIN analytics.fact_order_items foi
									ON dp.product_id = foi.product_id
WHERE
	foi.order_status = 'delivered'
	AND
	dp.product_weight_g IS NULL;
--------------------

--------------------

--------------------

--------------------

--------------------

--------------------

--------------------

--------------------

--------------------