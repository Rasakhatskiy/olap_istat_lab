
CREATE TABLE crime_type (
    name VARCHAR(100) PRIMARY KEY,
    severity VARCHAR(50)
);

CREATE TABLE police_department (
    address TEXT,
    number SERIAL PRIMARY KEY
);

CREATE TABLE person (
    id SERIAL PRIMARY KEY,
    full_name VARCHAR(100),
    date_of_birth DATE,
    mobile_phone VARCHAR(20),
    sex BOOLEAN,
    criminal_record BOOLEAN
);

CREATE TABLE policeman (
    id SERIAL PRIMARY KEY,
    person_id INT REFERENCES person(id),
    rank VARCHAR(50),
    police_department_number INT REFERENCES police_department(number)
);

CREATE TABLE detective (
    id SERIAL PRIMARY KEY,
    policeman_id INT REFERENCES policeman(id),
    specialization VARCHAR(100)
);

CREATE TABLE location (
    id SERIAL PRIMARY KEY,
    region VARCHAR(100),
    district VARCHAR(100),
    city VARCHAR(100)
);

CREATE TABLE crime_case (
    id SERIAL PRIMARY KEY,
    date DATE,
    time TIME,
    crime_type_name VARCHAR(100) REFERENCES crime_type(name),
    crime_description TEXT,
    location_id INT REFERENCES location(id),
    person_called INT REFERENCES person(id),
    policeman_accepted INT REFERENCES policeman(id),
    policeman_1 INT REFERENCES policeman(id),
    policeman_2 INT REFERENCES policeman(id),
    detective_id INT REFERENCES detective(id),
    is_solved BOOLEAN,
    date_of_solving DATE
);


CREATE TABLE crime_case_person (
    crime_case_id INT REFERENCES crime_case(id),
    suspect_id INT REFERENCES person(id),
    criminal_id INT REFERENCES person(id),
    PRIMARY KEY (crime_case_id, suspect_id, criminal_id)
);
