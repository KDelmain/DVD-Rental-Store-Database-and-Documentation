/******************************************
*	Kaitlyn Delmain		D191 PA
******************************************/

-- Section B: Create Tables
	CREATE TABLE summary_table
	(
		store_id int NOT NULL,
		total_rentals int NOT NULL,
		total_sales decimal(12,2) NOT NULL
	);

	CREATE TABLE detailed_table
	(
		store_id int NOT NULL,
		staff_id int NOT NULL,
		staff_name varchar(90) NOT NULL,
		rental_id int NOT NULL,
		rental_price decimal(10,2) NOT NULL
	);

-- Section C: Extract Data into Detailed Table
	INSERT INTO detailed_table
		SELECT s.store_id, e.staff_id, concat_name(e.first_name, e.last_name), r.rental_id, p.amount
			FROM store AS s
				JOIN staff AS e ON s.store_id=e.store_id
					JOIN rental AS r ON e.staff_id=r.staff_id
						JOIN payment AS p ON r.rental_id=p.rental_id
			WHERE e.active = true
			ORDER BY s.store_id;
		
	-- SELECT * FROM detailed_table;
	-- SELECT * FROM summary_table;
	
-- Section D: Transformation Function
	CREATE FUNCTION concat_name(first_name varchar(45), last_name varchar(45))
		RETURNS varchar(90)
		LANGUAGE plpgsql
		AS
		$$
			DECLARE staff_name varchar(90);
				BEGIN
				SELECT first_name || ' ' || last_name INTO staff_name;
				RETURN staff_name;
			END;
		$$
	
-- Section E: Trigger to Update Summary Table when Data Inserted into Detailed Table
	CREATE PROCEDURE update_sum_table()
		LANGUAGE plpgsql
		AS
		$$
			BEGIN
				TRUNCATE summary_table;

				INSERT INTO summary_table
					SELECT store_id, count(rental_id), sum(rental_price)
						FROM detailed_table
						GROUP BY store_id
						ORDER BY store_id;
			END;
		$$;
	
	CREATE FUNCTION insert_trigger_function()
		RETURNS TRIGGER
		LANGUAGE plpgsql
		AS
		$$
			BEGIN
				CALL update_sum_table();
				RETURN NEW;
			END;
		$$;
	
	CREATE TRIGGER detailed_inserted
		AFTER INSERT ON detailed_table
		FOR EACH ROW
		EXECUTE PROCEDURE insert_trigger_function();
		
		-- INSERT INTO detailed_table VALUES (1, 1, "Mike Hillyer", 20000, 14.99);
	
--Section F: Stored Procedure to Refresh the Summary and Detailed Tables
	CREATE PROCEDURE reload_tables_data() -- Should be executed monthly
		LANGUAGE plpgsql
		AS
		$$
			BEGIN
				TRUNCATE summary_table;
				TRUNCATE detailed_table;

				INSERT INTO detailed_table
					SELECT s.store_id, e.staff_id, concat_name(e.first_name, e.last_name), r.rental_id, p.amount
						FROM store AS s
							JOIN staff AS e ON s.store_id=e.store_id
								JOIN rental AS r ON e.staff_id=r.staff_id
									JOIN payment AS p ON r.rental_id=p.rental_id
						WHERE e.active = true
						ORDER BY e.staff_id;

				INSERT INTO summary_table
					SELECT store_id, count(rental_id), sum(rental_price)
						FROM detailed_table
						GROUP BY store_id;
			END;
		$$

		-- CALL reload_tables_data();



/******************************************
*	DROP TABLE summary_table;
*   DROP TABLE detailed_table;
*
*   DROP FUNCTION concat_name;
*	DROP FUNCTION insert_trigger_function;
*
*	DROP TRIGGER detailed_inserted ON detailed_table;
*
*	DROP PROCEDURE update_sum_table;
*	DROP PROCEDURE reload_table_data;
******************************************/
