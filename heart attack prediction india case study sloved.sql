CREATE TABLE heart_attack_data (
    patient_id INT PRIMARY KEY,
    state_name VARCHAR(100),
    age INT,
    gender VARCHAR(10),
    diabetes BOOLEAN,
    hypertension BOOLEAN,
    obesity BOOLEAN,
    smoking BOOLEAN,
    alcohol_consumption BOOLEAN,
    physical_activity VARCHAR(20),
    diet_score INT,
    cholesterol_level FLOAT,
    triglyceride_level FLOAT,
    ldl_level FLOAT,
    hdl_level FLOAT,
    systolic_bp INT,
    diastolic_bp INT,
    air_pollution_exposure FLOAT,
    family_history BOOLEAN,
    stress_level VARCHAR(20),
    healthcare_access VARCHAR(20),
    heart_attack_history BOOLEAN,
    emergency_response_time INT,
    annual_income INT,
    health_insurance BOOLEAN,
    heart_attack_risk VARCHAR(20) -- e.g., 'Low', 'Medium', 'High'
);
#1. TOTAL NUMBER OF PATIENTS IN THE DATASET
SELECT COUNT(*) AS total_patients FROM heart_attack_data;
#2.AVERAGE AGE OF PATIENTS
SELECT AVG(age) AS avg_age FROM heart_attack_data;
#3.gender wise heart attack risk distribution
SELECT gender, heart_attack_risk, COUNT(*) AS count 
FROM heart_attack_data 
GROUP BY gender, heart_attack_risk;
#4.state with the highest number of high -risk patients
SELECT state_name, COUNT(*) AS high_risk_count
FROM heart_attack_data
WHERE heart_attack_risk = 'High'
GROUP BY state_name
ORDER BY high_risk_count DESC
LIMIT 1;
#5.how many patients have both diabetes and hypertension
SELECT COUNT(*) AS count 
FROM heart_attack_data
WHERE diabetes = 1 AND hypertension = 1;
#6.Distribution of patients based on physical activity
SELECT physical_activity, COUNT(*) 
FROM heart_attack_data
GROUP BY physical_activity;
#7.Average cholesterol level by heart attack risk
SELECT heart_attack_risk, AVG(cholesterol_level) AS avg_cholesterol
FROM heart_attack_data
GROUP BY heart_attack_risk;
#8.Compare HDL LEVELS BETWEEN MALES AND FEMALES
SELECT gender, AVG(hdl_level) AS avg_hdl
FROM heart_attack_data
GROUP BY gender;
#9.Find patients with LDL LEVEL GREATER THAN 130
SELECT patient_id, age, ldl_level 
FROM heart_attack_data 
WHERE ldl_level > 130;
#10.HEART Attack risk by stress level
SELECT stress_level, heart_attack_risk, COUNT(*) 
FROM heart_attack_data
GROUP BY stress_level, heart_attack_risk;
#11.Top 5 patients with highest air pollution exposure
SELECT patient_id, air_pollution_exposure 
FROM heart_attack_data
ORDER BY air_pollution_exposure DESC
LIMIT 5;
#12.AVERAGE systolic and diastolic BP for patients with family history
SELECT AVG(systolic_bp) AS avg_sys, AVG(diastolic_bp) AS avg_dia
FROM heart_attack_data
WHERE family_history = 1;
#13.Does insurance coverage vary with heart attack risk?
SELECT heart_attack_risk, health_insurance, COUNT(*) 
FROM heart_attack_data
GROUP BY heart_attack_risk, health_insurance;
#14.find correlation indicators(e.g., obesity and heart attack risk)
SELECT obesity, heart_attack_risk, COUNT(*) 
FROM heart_attack_data
GROUP BY obesity, heart_attack_risk;
#15.list patients with poor healthcare access and high heart attack risk
SELECT patient_id, state_name, healthcare_access, heart_attack_risk
FROM heart_attack_data
WHERE healthcare_access = 'Poor' AND heart_attack_risk = 'High';

