--datetime dimension

CREATE TABLE datetime_dim(
date_id DATE,
year INTEGER,
month INTEGER,
PRIMARY KEY (date_id));

SELECT * from datetime_dim limit 50;
SELECT COUNT(*) FROM datetime_dim;

--vaccine dimension SCD2
CREATE TABLE vaccine_dim
(
cleaned_vaccine VARCHAR(50),
vaccine_description VARCHAR(200),
vaccine_strains VARCHAR(200),
vaccine_names VARCHAR(200),
start_date DATE references datetime_dim(date_id),
end_date DATE references datetime_dim(date_id),
current_flag VARCHAR(1),
vaccine_id SERIAL,
PRIMARY KEY (vaccine_id));

ALTER TABLE vaccine_dim
ADD CONSTRAINT unique_cleaned_vaccine UNIQUE (cleaned_vaccine, start_date);

select * from vaccine_dim;

SELECT setval('vaccine_dim_vaccine_id_seq', (SELECT MAX(vaccine_id) FROM vaccine_dim));
SELECT currval('vaccine_dim_vaccine_id_seq');

--dose dimension SCD0
CREATE TABLE dose_dim(
dose VARCHAR(100),
dose_id SERIAL,
PRIMARY KEY (dose_id));
ALTER TABLE dose_dim
ADD CONSTRAINT unique_dose_dim UNIQUE (dose);

SELECT setval('dose_dim_dose_id_seq', (SELECT MAX(dose_id) FROM dose_dim));
SELECT currval('dose_dim_dose_id_seq');

select * from dose_dim;

--geography dimension SCD1
CREATE TABLE geography_dim(
state_territory VARCHAR(50),
municipality VARCHAR(50),
county VARCHAR(50),
region VARCHAR(20),
original_geography_type VARCHAR(50),
original_geography VARCHAR(50),
geography_id SERIAL,
PRIMARY KEY (geography_id));

ALTER TABLE geography_dim
ADD CONSTRAINT unique_geography_dim UNIQUE (original_geography);

SELECT setval('geography_dim_geography_id_seq', (SELECT MAX(geography_id) FROM geography_dim));
SELECT currval('geography_dim_geography_id_seq');

select * from geography_dim;

--race ethnicity SCD1
CREATE TABLE race_ethnicity_dim(
race_ethnicity VARCHAR(100),
race_ethnicity_id SERIAL,
PRIMARY KEY (race_ethnicity_id));

select * from race_ethnicity_dim;
ALTER TABLE race_ethnicity_dim
ADD CONSTRAINT unique_race_ethnicity_dim UNIQUE (race_ethnicity);
SELECT setval('race_ethnicity_dim_race_ethnicity_id_seq', (SELECT MAX(race_ethnicity_id) FROM race_ethnicity_dim));
SELECT currval('race_ethnicity_dim_race_ethnicity_id_seq');

--urbanicity SCD1
CREATE TABLE urbanicity_dim(
urbanicity VARCHAR(50),
urbanicity_id SERIAL,
PRIMARY KEY (urbanicity_id));

select * from urbanicity_dim;

ALTER TABLE urbanicity_dim
ADD CONSTRAINT unique_urbanicity_dim UNIQUE (urbanicity);
SELECT setval('urbanicity_dim_urbanicity_id_seq', (SELECT MAX(urbanicity_id) FROM urbanicity_dim));
SELECT currval('urbanicity_dim_urbanicity_id_seq');

--poverty SCD3
CREATE TABLE poverty_dim(
poverty_status VARCHAR(50),
current_poverty_description VARCHAR(150),
previous_poverty_description VARCHAR(150),
poverty_id SERIAL,
PRIMARY KEY (poverty_id));

select * from poverty_dim;


ALTER TABLE poverty_dim
ADD CONSTRAINT unique_poverty_dim UNIQUE (poverty_status);

SELECT setval('poverty_dim_poverty_id_seq', (SELECT MAX(poverty_id) FROM poverty_dim));
SELECT currval('poverty_dim_poverty_id_seq');

--insurance SCD2
CREATE TABLE insurance_dim(
insurance_coverage VARCHAR(50),
start_date DATE references datetime_dim(date_id),
end_date DATE references datetime_dim(date_id),
current_flag VARCHAR(1),
insurance_id SERIAL,
PRIMARY KEY (insurance_id));

select * from insurance_dim;

ALTER TABLE insurance_dim
ADD CONSTRAINT unique_insurance_dim UNIQUE (insurance_coverage);
SELECT setval('insurance_dim_insurance_id_seq', (SELECT MAX(insurance_id) FROM insurance_dim));
SELECT currval('insurance_dim_insurance_id_seq');

--gender SCD1
CREATE TABLE gender_dim(
gender VARCHAR(50),
gender_id SERIAL,
PRIMARY KEY (gender_id)
);
ALTER TABLE gender_dim
ADD CONSTRAINT unique_gender_dim UNIQUE (gender);
SELECT setval('gender_dim_gender_id_seq', (SELECT MAX(gender_id) FROM gender_dim));
SELECT currval('gender_dim_gender_id_seq');

--snapshot fact table
CREATE TABLE vaccine_cumulative_fact(
vaccine_cumulative_id SERIAL,
vaccine_cumulative_start_cohort_year INTEGER,
vaccine_cumulative_end_cohort_year INTEGER,
vaccine_cumulative_estimate_pct FLOAT,
vaccine_cumulative_sample_size INTEGER,
vaccine_cumulative_ci_lower FLOAT,
vaccine_cumulative_ci_upper FLOAT,
vaccine_cumulative_vaccine_id INTEGER REFERENCES vaccine_dim(vaccine_id),
vaccine_cumulative_dose_id INTEGER REFERENCES dose_dim(dose_id),
vaccine_cumulative_geography_id INTEGER REFERENCES geography_dim(geography_id),
vaccine_cumulative_insurance_id INTEGER REFERENCES insurance_dim(insurance_id),
vaccine_cumulative_poverty_id INTEGER REFERENCES poverty_dim (poverty_id),
vaccine_cumulative_race_ethnicity_id INTEGER REFERENCES race_ethnicity_dim (race_ethnicity_id),
vaccine_cumulative_urbanicity_id INTEGER REFERENCES urbanicity_dim (urbanicity_id),
vaccine_cumulative_gender_id INTEGER REFERENCES gender_dim(gender_id),
w VARCHAR(10),

PRIMARY KEY (vaccine_cumulative_id)
);

--vaccine location SCD0
CREATE TABLE vaccine_location_dim(
vaccine_location VARCHAR(100),
vaccine_location_id SERIAL,
PRIMARY KEY (vaccine_location_id));
ALTER TABLE vaccine_location_dim
ADD CONSTRAINT unique_vaccine_location_dim UNIQUE (vaccine_location);

SELECT setval('vaccine_location_dim_vaccine_location_id_seq', (SELECT MAX(vaccine_location_id) FROM vaccine_location_dim));
SELECT currval('vaccine_location_dim_vaccine_location_id_seq');

select * from vaccine_location_dim

--influenza_cumulative_fact
CREATE TABLE influenza_cumulative_fact(
influenza_cumulative_id SERIAL,
age VARCHAR(100),
influenza_cumulative_estimate_pct FLOAT,
influenza_cumulative_sample_size FLOAT, 
influenza_cumulative_ci_lower FLOAT,
influenza_cumulative_ci_upper FLOAT,
influenza_cumulative_start_cohort_datetime DATE REFERENCES datetime_dim(date_id),
influenza_cumulative_end_cohort_datetime DATE REFERENCES datetime_dim(date_id),
influenza_cumulative_vaccine_id INTEGER REFERENCES vaccine_dim(vaccine_id),
influenza_cumulative_geography_id INTEGER REFERENCES geography_dim(geography_id),
influenza_cumulative_race_ethnicity_id INTEGER REFERENCES race_ethnicity_dim(race_ethnicity_id),
influenza_cumulative_vaccine_location_id INTEGER REFERENCES vaccine_location_dim(vaccine_location_id),
PRIMARY KEY (influenza_cumulative_id)
);


--vaccine_transaction_fact
CREATE TABLE vaccine_transaction_fact(
vaccine_transaction_id SERIAL,
vaccine_transaction_survey_year INTEGER,
vaccine_transaction_birth_year INTEGER,
vaccine_transaction_age VARCHAR(50),
vaccine_transaction_estimate_pct FLOAT,
vaccine_transaction_ci_lower FLOAT,
vaccine_transaction_ci_upper FLOAT,
vaccine_transaction_sample_size INTEGER,
vaccine_transaction_vaccine_id INTEGER,
vaccine_transaction_dose_id INTEGER, 
vaccine_transaction_gender_id INTEGER,
vaccine_transaction_geography_id INTEGER,

PRIMARY KEY (vaccine_transaction_id),
FOREIGN KEY (vaccine_transaction_vaccine_id) REFERENCES vaccine_dim(vaccine_id),
FOREIGN KEY (vaccine_transaction_dose_id) REFERENCES dose_dim(dose_id),
FOREIGN KEY (vaccine_transaction_geography_id) REFERENCES geography_dim(geography_id),
FOREIGN KEY (vaccine_transaction_gender_id) REFERENCES gender_dim(gender_id));

