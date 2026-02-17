CREATE DATABASE hospital_db;

CREATE TABLE patients (
    patient_id SERIAL PRIMARY KEY,
    age VARCHAR(20)
);

CREATE TABLE diagnoses (
    diagnosis_id SERIAL PRIMARY KEY,
    diag_1 VARCHAR(50),
    diag_2 VARCHAR(50),
    diag_3 VARCHAR(50)
);

CREATE TABLE admissions (
    admission_id SERIAL PRIMARY KEY,
    patient_id INT,
    diagnosis_id INT,
    time_in_hospital INT,
    n_procedures INT,
    n_lab_procedures INT,
    n_medications INT,
    n_outpatient INT,
    n_inpatient INT,
    n_emergency INT,
    medical_specialty VARCHAR(100),
    glucose_test VARCHAR(20),
    a1c_test VARCHAR(20),
    change VARCHAR(5),
    diabetes_med VARCHAR(5),
    readmitted VARCHAR(5),

    CONSTRAINT fk_patient
        FOREIGN KEY (patient_id)
        REFERENCES patients(patient_id),

    CONSTRAINT fk_diagnosis
        FOREIGN KEY (diagnosis_id)
        REFERENCES diagnoses(diagnosis_id)
);


CREATE TABLE admissions_staging (
    age VARCHAR,
    time_in_hospital INT,
    n_procedures INT,
    n_lab_procedures INT,
    n_medications INT,
    n_outpatient INT,
    n_inpatient INT,
    n_emergency INT,
    medical_specialty VARCHAR,
    diag_1 VARCHAR,
    diag_2 VARCHAR,
    diag_3 VARCHAR,
    glucose_test VARCHAR,
    a1c_test VARCHAR,
    change VARCHAR,
    diabetes_med VARCHAR,
    readmitted VARCHAR
);

COPY admissions_staging
FROM 'C:/Users/User/hospital_readmissions.csv'
DELIMITER ','
CSV HEADER;

select * from admissions_staging;

INSERT INTO patients (age)
SELECT DISTINCT age
FROM admissions_staging;

INSERT INTO diagnoses (diag_1, diag_2, diag_3)
SELECT DISTINCT diag_1, diag_2, diag_3
FROM admissions_staging;

INSERT INTO admissions (
    patient_id, diagnosis_id,
    time_in_hospital, n_procedures,
    n_lab_procedures, n_medications,
    n_outpatient, n_inpatient, n_emergency,
    medical_specialty, glucose_test,
    a1c_test, change, diabetes_med, readmitted
)
SELECT 
    p.patient_id,
    d.diagnosis_id,
    s.time_in_hospital,
    s.n_procedures,
    s.n_lab_procedures,
    s.n_medications,
    s.n_outpatient,
    s.n_inpatient,
    s.n_emergency,
    s.medical_specialty,
    s.glucose_test,
    s.a1c_test,
    s.change,
    s.diabetes_med,
    s.readmitted
FROM admissions_staging s
JOIN patients p ON s.age = p.age
JOIN diagnoses d 
  ON s.diag_1 = d.diag_1 
 AND s.diag_2 = d.diag_2 
 AND s.diag_3 = d.diag_3;

select * from admissions;

EXPLAIN ANALYZE
SELECT * FROM admissions
WHERE readmitted = 'yes';

CREATE INDEX idx_readmitted
ON admissions(readmitted);
CREATE INDEX idx_medical_specialty
ON admissions(medical_specialty);
CREATE INDEX idx_time_in_hospital
ON admissions(time_in_hospital);


"1. Readmission Rate"

SELECT 
    readmitted,
    COUNT(*) AS total,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM admissions
GROUP BY readmitted;


"Top Risk Diagnoses (Window Function)"
SELECT *
FROM (
    SELECT 
        d.diag_1,
        COUNT(*) AS total_cases,
        RANK() OVER (ORDER BY COUNT(*) DESC) AS rank
    FROM admissions a
    JOIN diagnoses d ON a.diagnosis_id = d.diagnosis_id
    WHERE readmitted = 'yes'
    GROUP BY d.diag_1
) ranked
WHERE rank <= 5;

"Average Stay by Specialty"

SELECT 
    medical_specialty,
    AVG(time_in_hospital) AS avg_stay
FROM admissions
GROUP BY medical_specialty
ORDER BY avg_stay DESC;

"CTE – High Risk Patients"
WITH high_risk AS (
    SELECT *
    FROM admissions
    WHERE n_inpatient > 2
      AND n_emergency > 1
)
SELECT COUNT(*)
FROM high_risk
WHERE readmitted = 'yes';


select * from admissions;

