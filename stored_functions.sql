CREATE TABLE vault (
    id INT,
    date DATE,
    "time" TIME,
    crime_type_name VARCHAR(100),
    crime_severity VARCHAR(50),
    crime_description TEXT,
    region VARCHAR(100),
    district VARCHAR(100),
    city VARCHAR(100),
    person_called VARCHAR(100),
    policeman_accepted VARCHAR(100),
    policeman_accepted_rank VARCHAR(50),
    policeman_accepted_department TEXT,
    policeman_1 VARCHAR(100),
    policeman_1_rank VARCHAR(50),
    policeman_1_department TEXT,
    policeman_2 VARCHAR(100),
    policeman_2_rank VARCHAR(50),
    policeman_2_department TEXT,
    detective VARCHAR(100),
    detective_rank VARCHAR(50),
    detective_department TEXT,
    detective_specialization VARCHAR(100),
    is_solved BOOLEAN,
    date_of_solving DATE,
    suspect VARCHAR(100),
    suspect_dob DATE,
    suspect_phone VARCHAR(20),
    suspect_sex BOOLEAN,
    suspect_record BOOLEAN,
    criminal VARCHAR(100),
    criminal_dob DATE,
    criminal_phone VARCHAR(20),
    criminal_sex BOOLEAN,
    criminal_record BOOLEAN
);

DROP FUNCTION IF EXISTS get_vault_table();

CREATE OR REPLACE FUNCTION get_vault_table()
RETURNS TABLE (
    id INT
) AS $$
BEGIN
    RETURN QUERY
    INSERT INTO vault
    SELECT
        cc.id,
        cc.date,
        cc."time",
        ct.name,
        ct.severity,
        cc.crime_description,
        l.region,
        l.district,
        l.city,
        p.full_name,
        pm1p.full_name,
        pm1.rank,
        pd1.address,
        pm2p.full_name,
        pm2.rank,
        pd2.address,
        pm3p.full_name,
        pm3.rank,
        pd3.address,
        dp_p.full_name,
        dp.rank,
        pd4.address,
        d.specialization,
        cc.is_solved,
        cc.date_of_solving,
        s.full_name,
        s.date_of_birth,
        s.mobile_phone,
        s.sex,
        s.criminal_record,
        c.full_name,
        c.date_of_birth,
        c.mobile_phone,
        c.sex,
        c.criminal_record
    FROM crime_case cc
    JOIN crime_type ct ON cc.crime_type_name = ct.name
    JOIN location l ON cc.location_id = l.id
    JOIN person p ON cc.person_called = p.id
    JOIN policeman pm1 ON cc.policeman_accepted = pm1.id
    JOIN person pm1p ON pm1.person_id = pm1p.id
    JOIN police_department pd1 ON pm1.police_department_number = pd1.number
    JOIN policeman pm2 ON cc.policeman_1 = pm2.id
    JOIN person pm2p ON pm2.person_id = pm2p.id
    JOIN police_department pd2 ON pm2.police_department_number = pd2.number
    JOIN policeman pm3 ON cc.policeman_2 = pm3.id
    JOIN person pm3p ON pm3.person_id = pm3p.id
    JOIN police_department pd3 ON pm3.police_department_number = pd3.number
    JOIN detective d ON cc.detective_id = d.id
    JOIN policeman dp ON d.policeman_id = dp.id
    JOIN person dp_p ON dp.person_id = dp_p.id
    JOIN police_department pd4 ON dp.police_department_number = pd4.number
    LEFT JOIN crime_case_person ccp ON cc.id = ccp.crime_case_id
    LEFT JOIN person s ON ccp.suspect_id = s.id
    LEFT JOIN person c ON ccp.criminal_id = c.id
    WHERE cc.is_solved = true
    RETURNING vault.id;
END; $$ LANGUAGE plpgsql;

SELECT * FROM get_vault_table();



DROP FUNCTION IF EXISTS delete_moved_cases();
CREATE OR REPLACE FUNCTION delete_moved_cases()
RETURNS VOID AS $$
DECLARE
    _id INT;
BEGIN
    FOR _id IN (SELECT id FROM get_vault_table())
    LOOP
        DELETE FROM crime_case_person WHERE crime_case_id = _id;
        DELETE FROM crime_case WHERE id = _id;
    END LOOP;
END; $$ LANGUAGE plpgsql;

SELECT * FROM delete_moved_cases();



CREATE OR REPLACE FUNCTION get_crimes_by_city()
RETURNS TABLE (
    city VARCHAR(100),
    number_of_crimes BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT l.city, COUNT(*) AS number_of_crimes
    FROM crime_case cc
    JOIN location l ON cc.location_id = l.id
    JOIN crime_type ct ON cc.crime_type_name = ct.name
    WHERE ct.severity = 'Особливо тяжкий' AND cc.date BETWEEN '2023-01-01' AND '2023-06-30'
    GROUP BY l.city;
END; $$ LANGUAGE plpgsql;

-- CREATE OR REPLACE FUNCTION get_detective_solved_cases()
-- RETURNS TABLE (
--     detective_name VARCHAR(100),
--     solved_cases BIGINT
-- ) AS $$
-- BEGIN
--     RETURN QUERY
--     SELECT
--         dp_p.full_name AS detective_name,
--         COUNT(cc.id) AS solved_cases
--     FROM detective d
--     JOIN policeman dp ON d.policeman_id = dp.id
--     JOIN person dp_p ON dp.person_id = dp_p.id
--     LEFT JOIN crime_case cc ON d.id = cc.detective_id AND cc.is_solved = true
--     GROUP BY dp_p.full_name;
-- END; $$ LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS get_detective_solved_cases();
CREATE OR REPLACE FUNCTION get_detective_solved_cases()
RETURNS TABLE (
    detective_name VARCHAR(100),
    solved_cases BIGINT,
    unsolved_cases BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        dp_p.full_name AS detective_name,
        (SELECT COUNT(*) FROM vault v WHERE v.detective = dp_p.full_name AND v.is_solved = true) AS solved_cases,
        (SELECT COUNT(*) FROM crime_case cc WHERE cc.detective_id = d.id AND cc.is_solved = false) AS unsolved_cases
    FROM detective d
    JOIN policeman dp ON d.policeman_id = dp.id
    JOIN person dp_p ON dp.person_id = dp_p.id;
END; $$ LANGUAGE plpgsql;
SELECT * FROM get_detective_solved_cases();


CREATE OR REPLACE FUNCTION get_crime_cases_status()
RETURNS TABLE (
    crime_name VARCHAR(100),
    total_cases BIGINT,
    solved_cases BIGINT,
    unsolved_cases BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        ct.name AS crime_name,
        COUNT(cc.id) AS total_cases,
        COUNT(cc.id) FILTER (WHERE cc.is_solved = true) AS solved_cases,
        COUNT(cc.id) FILTER (WHERE cc.is_solved = false) AS unsolved_cases
    FROM crime_case cc
    JOIN crime_type ct ON cc.crime_type_name = ct.name
    GROUP BY ct.name;
END; $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_cases_by_person()
RETURNS TABLE (
    case_id INT,
    date DATE,
    crime_type_name VARCHAR(100),
    crime_description TEXT,
    person_name VARCHAR(100)
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        cc.id AS case_id,
        cc.date,
        ct.name AS crime_type_name,
        cc.crime_description,
        p.full_name AS person_name
    FROM crime_case cc
    JOIN crime_type ct ON cc.crime_type_name = ct.name
    JOIN person p ON cc.person_called = p.id
    LEFT JOIN crime_case_person ccp ON cc.id = ccp.crime_case_id
    WHERE ccp.suspect_id = p.id OR ccp.criminal_id = p.id;
END; $$ LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS get_crimes_per_week();
CREATE OR REPLACE FUNCTION get_crimes_per_week()
RETURNS TABLE (
    crime_week DATE,
    total_cases BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        date_trunc('week', date_series.date)::DATE AS crime_week,
        COUNT(cc.id) AS total_cases
    FROM generate_series(
        '2023-01-01'::date,
        '2023-12-31'::date,
        '1 day'::interval) AS date_series(date)
    LEFT JOIN crime_case cc ON date_series.date::DATE = cc.date
    GROUP BY crime_week
    ORDER BY crime_week;
END; $$ LANGUAGE plpgsql;
SELECT * FROM get_crimes_per_week();

DROP FUNCTION IF EXISTS get_crimes_per_severity();
CREATE OR REPLACE FUNCTION get_crimes_per_severity()
RETURNS TABLE (
    crime_severity VARCHAR(50),
    total_cases BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        ct.severity AS crime_severity,
        COUNT(cc.id) AS total_cases
    FROM crime_case cc
    JOIN crime_type ct ON cc.crime_type_name = ct.name
    GROUP BY ct.severity;
END; $$ LANGUAGE plpgsql;
SELECT * FROM get_crimes_per_severity();


DROP FUNCTION IF EXISTS get_criminals_by_age_category();
CREATE OR REPLACE FUNCTION get_criminals_by_age_category()
RETURNS TABLE (
    age_category VARCHAR(20),
    number_of_criminals BIGINT
) AS $$
BEGIN
    RETURN QUERY
    WITH age_categories AS (
        SELECT unnest(ARRAY['0-18', '19-25', '26-45', '46-70', '70+'])::VARCHAR(20) AS age_category
    )
    SELECT
        ac.age_category,
        COALESCE(c.number_of_criminals, 0) AS number_of_criminals
    FROM age_categories ac
    LEFT JOIN (
        SELECT
            CASE
                WHEN EXTRACT(YEAR FROM AGE(current_date, c.date_of_birth)) BETWEEN 0 AND 18 THEN '0-18'
                WHEN EXTRACT(YEAR FROM AGE(current_date, c.date_of_birth)) BETWEEN 19 AND 25 THEN '19-25'
                WHEN EXTRACT(YEAR FROM AGE(current_date, c.date_of_birth)) BETWEEN 26 AND 45 THEN '26-45'
                WHEN EXTRACT(YEAR FROM AGE(current_date, c.date_of_birth)) BETWEEN 46 AND 70 THEN '46-70'
                ELSE '70+'
            END::VARCHAR(20) AS age_category,
            COUNT(*) AS number_of_criminals
        FROM person c
        JOIN crime_case_person ccp ON c.id = ccp.criminal_id
        GROUP BY age_category
    ) c ON ac.age_category = c.age_category;
END; $$ LANGUAGE plpgsql;
SELECT * FROM get_criminals_by_age_category();


DROP FUNCTION IF EXISTS get_crime_counts();
CREATE OR REPLACE FUNCTION get_crime_counts()
RETURNS TABLE (
    crime_name VARCHAR(100),
    crime_severity VARCHAR(50),
    total_cases BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        cc.crime_type_name AS crime_name,
        ct.severity AS crime_severity,
        COUNT(*) AS total_cases
    FROM crime_case cc
    JOIN crime_type ct ON cc.crime_type_name = ct.name
    GROUP BY cc.crime_type_name, ct.severity
    UNION ALL
    SELECT
        v.crime_type_name AS crime_name,
        ct.severity AS crime_severity,
        COUNT(*) AS total_cases
    FROM vault v
    JOIN crime_type ct ON v.crime_type_name = ct.name
    GROUP BY v.crime_type_name, ct.severity;
END; $$ LANGUAGE plpgsql;
SELECT * FROM get_crime_counts();