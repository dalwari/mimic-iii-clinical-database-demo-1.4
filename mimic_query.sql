---q1---
---1.1--
with icd_code_cte as ( select * from d_icd_diagnoses did where did.short_title like '%diabe%'),
patients_admissions_cte as (select distinct p.subject_id, p.gender from patients p inner join admissions a on p.subject_id= a.subject_id ),
admissions_diagnosis_cte as (select distinct a.subject_id ,a.hadm_id, a.admittime, a.dischtime, d.icd9_code from admissions a inner join diagnoses_icd d on a.hadm_id = d.hadm_id),
patients_admissions_diagnosis_cte as (select * from patients_admissions_cte a inner join admissions_diagnosis_cte b on a.subject_id=b.subject_id)
select * from patients_admissions_diagnosis_cte a inner join icd_code_cte b on a.icd9_code = b.icd9_code;

---1.2--
 patients_admissions_cte as (select distinct p.subject_id, p.gender from patients p inner join admissions a on p.subject_id= a.subject_id ),
 admissions_diagnosis_cte as (select distinct a.subject_id ,a.hadm_id, a.admittime, a.dischtime, d.icd9_code from admissions a inner join diagnoses_icd d on a.hadm_id = d.hadm_id),
 patients_admissions_diagnosis_cte as (select * from patients_admissions_cte a inner join admissions_diagnosis_cte b on a.subject_id=b.subject_id)
select * from patients_admissions_diagnosis_cte a where a.icd9_code in (select icd9_code from d_icd_diagnoses did where did.short_title like '%diabe%');

---q2---
WITH diabetes_patients AS (
    SELECT p.subject_id, 
           p.gender,
            extract(year from age(a.admittime,p.dob)) AS age,
           l.valuenum AS glucose_level
    FROM PATIENTS p
    JOIN ADMISSIONS a ON p.subject_id = a.subject_id
    JOIN DIAGNOSES_ICD d ON a.hadm_id = d.hadm_id
    JOIN LABEVENTS l ON a.hadm_id = l.hadm_id
    WHERE d.icd9_code in 
    (select icd9_code from d_icd_diagnoses did where did.short_title like '%diabe%') 
      AND l.itemid = 50809 
)
SELECT 
    CASE 
        WHEN age BETWEEN 0 AND 40 THEN '0-40'
        WHEN age BETWEEN 41 AND 60 THEN '41-60'
         WHEN age BETWEEN 61 AND 80 THEN '61-80'
        ELSE '81+' 
    END AS age_group,
    COUNT(CASE WHEN gender = 'M' THEN true END) AS male_patient_count,
    COUNT(CASE WHEN gender = 'F' THEN true END) AS female_patient_count,
    AVG(CASE WHEN gender = 'M' THEN glucose_level END) AS male_patients_glucose_avg,
    AVG(CASE WHEN gender = 'F' THEN glucose_level END) AS female_patients_glucose_avg
FROM diabetes_patients
GROUP BY age_group;
---q3---
SELECT AVG(age(a.dischtime, a.admittime)) AS avg_length_of_stay
FROM ADMISSIONS a
JOIN DIAGNOSES_ICD d ON a.hadm_id = d.hadm_id
WHERE d.icd9_code in (select icd9_code from d_icd_diagnoses did where did.short_title like '%diabe%');
---q4---
SELECT pr.drug as top_10_frequently_used_drug_prescription, COUNT(*) AS prescription_count
FROM PRESCRIPTIONS pr
JOIN ADMISSIONS a ON pr.hadm_id = a.hadm_id
JOIN DIAGNOSES_ICD d ON a.hadm_id = d.hadm_id
WHERE d.icd9_code in (select icd9_code from d_icd_diagnoses did where did.short_title like '%diabe%')
GROUP BY pr.drug
ORDER BY prescription_count desc limit 10;
---q5---
---5.1---
SELECT p.subject_id, a.hadm_id, i.last_careunit as curr_icu_ward, i.intime, i.outtime, age( i.outtime, i.intime ) as duration
FROM PATIENTS p
JOIN ADMISSIONS a ON p.subject_id = a.subject_id
JOIN ICUSTAYS i ON a.hadm_id = i.hadm_id
JOIN DIAGNOSES_ICD d ON a.hadm_id = d.hadm_id
WHERE d.icd9_code in (select icd9_code from d_icd_diagnoses did where did.short_title like '%diabe%') 
order by age( i.outtime, i.intime ) desc;
---5.2---
with cte as (SELECT p.subject_id, a.hadm_id, i.last_careunit as curr_icu_ward, i.intime, i.outtime, age( i.outtime, i.intime ) as duration
FROM PATIENTS p
JOIN ADMISSIONS a ON p.subject_id = a.subject_id
JOIN ICUSTAYS i ON a.hadm_id = i.hadm_id
JOIN DIAGNOSES_ICD d ON a.hadm_id = d.hadm_id
WHERE d.icd9_code in (select icd9_code from d_icd_diagnoses did where did.short_title like '%diabe%') 
order by age( i.outtime, i.intime ) desc)
select distinct subject_id, hadm_id, curr_icu_ward, intime, outtime, duration from cte group by subject_id, hadm_id, curr_icu_ward, intime, outtime, duration
having duration > INTERVAL '30 days';
---q6---
SELECT  COUNT(*) AS total_patients,
SUM(a.hospital_expire_flag) AS deceased_patients,
concat( round ((SUM(a.hospital_expire_flag)* 100.00) / COUNT(*), 2) ,' %') AS mortality_rate
FROM ADMISSIONS a
JOIN DIAGNOSES_ICD d ON a.hadm_id = d.hadm_id
WHERE d.icd9_code in (select icd9_code from d_icd_diagnoses did where did.short_title like '%diabe%');
---q7---
---7.1---
WITH latest_glucose_tests AS (
SELECT l.subject_id,l.hadm_id,l.itemid,l.valuenum AS glucose_level,l.charttime,
ROW_NUMBER() OVER (PARTITION BY l.subject_id ORDER BY l.charttime DESC) AS rn
FROM LABEVENTS l inner join DIAGNOSES_ICD d ON l.hadm_id = d.hadm_id
WHERE d.icd9_code IN ( 
SELECT icd9_code FROM d_icd_diagnoses did WHERE did.short_title LIKE '%diabe%') 
AND l.itemid = 50809 order by l.charttime desc)
SELECT subject_id, hadm_id, itemid, glucose_level, charttime FROM latest_glucose_tests
WHERE rn = 1; 
---7.2---
WITH latest_glucose_tests AS (
SELECT l.subject_id, l.hadm_id,l.itemid,l.valuenum AS glucose_level,l.charttime,
ROW_NUMBER() OVER (PARTITION BY l.subject_id ORDER BY l.charttime DESC) AS rn
FROM LABEVENTS l inner join DIAGNOSES_ICD d ON l.hadm_id = d.hadm_id
WHERE d.icd9_code IN (
SELECT icd9_code FROM d_icd_diagnoses did WHERE did.short_title LIKE '%diabe%') 
AND l.itemid = 50809 order by l.charttime desc)
SELECT subject_id, hadm_id, itemid, glucose_level,charttime as mimic_charttime,
charttime - INTERVAL '1 year' * (EXTRACT(YEAR FROM charttime) - (2000 + (EXTRACT(YEAR FROM charttime) % 25))) AS normalized_charttime
FROM latest_glucose_tests
WHERE rn = 1; 
---q8---
SELECT p.subject_id, extract(year from age(a.admittime,p.dob)) AS age FROM PATIENTS p inner JOIN ADMISSIONS a ON p.subject_id = a.subject_id;
WITH diabetes_patients AS (
    SELECT p.subject_id, 
            extract(year from age(a.admittime,p.dob)) AS age,
           l.valuenum AS glucose_level
    FROM PATIENTS p
    inner JOIN ADMISSIONS a ON p.subject_id = a.subject_id
    inner JOIN DIAGNOSES_ICD d ON a.hadm_id = d.hadm_id
    inner JOIN LABEVENTS l ON a.hadm_id = l.hadm_id
    WHERE d.icd9_code in
    (select icd9_code from d_icd_diagnoses did where did.short_title like '%diabe%') 
      AND l.itemid = 50809 -- Glucose lab item ID
)
SELECT 
    CASE 
        WHEN age BETWEEN 0 AND 40 THEN '0-40'
        WHEN age BETWEEN 41 AND 60 THEN '41-60'
        WHEN age BETWEEN 61 AND 80 THEN '61-80'
        ELSE '81+' 
    END AS age_group,
    AVG(glucose_level) AS avg_glucose_level, 
    count(*) as patient_count
FROM diabetes_patients
GROUP BY age_group;
---q9---
WITH diabetes_admissions AS (
    SELECT a.subject_id, a.hadm_id, a.admittime, a.dischtime
    FROM ADMISSIONS a
    JOIN DIAGNOSES_ICD d ON a.hadm_id = d.hadm_id
    WHERE d.icd9_code in
    (select icd9_code from d_icd_diagnoses did where did.short_title like '%diabe%') 
),
readmission_counts AS (
    SELECT subject_id, COUNT(*) AS admission_count
    FROM diabetes_admissions
    GROUP BY subject_id
)
SELECT COUNT(*) AS total_patients,
SUM(CASE WHEN admission_count > 1 THEN 1 ELSE 0 END) AS readmitted_patients,
(SUM(CASE WHEN admission_count > 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) AS readmission_rate
FROM readmission_counts;
---q10---
---10.1---
SELECT a.insurance, COUNT(DISTINCT p.subject_id) AS patient_count
FROM PATIENTS p
JOIN ADMISSIONS a ON p.subject_id = a.subject_id
JOIN DIAGNOSES_ICD d ON a.hadm_id = d.hadm_id
WHERE d.icd9_code in (select icd9_code from d_icd_diagnoses did where did.short_title like '%diabe%')
GROUP BY a.insurance;
---10.2---
with cte as (
SELECT distinct a.insurance, p.subject_id, gender
FROM PATIENTS p
JOIN ADMISSIONS a ON p.subject_id = a.subject_id
JOIN DIAGNOSES_ICD d ON a.hadm_id = d.hadm_id
WHERE d.icd9_code in 
(select icd9_code from d_icd_diagnoses did where did.short_title like '%diabe%')
GROUP BY a.insurance,gender,p.subject_id
) 
select insurance, 
count(case when gender='M' then true end) as male_patient_count,
count(case when gender='F' then true end) as female_patient_count
from cte group by insurance;
