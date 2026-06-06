import pandas as pd
from faker import Faker
import random
from datetime import datetime, timedelta
import os

fake = Faker()
random.seed(42)
Faker.seed(42)

OUTPUT_DIR = os.path.join(os.path.dirname(__file__), '..', 'data', 'raw')
os.makedirs(OUTPUT_DIR, exist_ok=True)

# ── CONFIG ──────────────────────────────────────────
NUM_PATIENTS   = 500
NUM_ADMISSIONS = 2000
NUM_DIAGNOSES  = 3000
NUM_HOSPITALS  = 50

# Real ICD-10 codes for authenticity
ICD10_CODES = [
    ("I21.0",  "ST elevation myocardial infarction",          "Cardiovascular"),
    ("I50.9",  "Heart failure unspecified",                   "Cardiovascular"),
    ("I10",    "Essential hypertension",                      "Cardiovascular"),
    ("J18.9",  "Pneumonia unspecified",                       "Respiratory"),
    ("J44.1",  "COPD with acute exacerbation",                "Respiratory"),
    ("J96.00", "Acute respiratory failure unspecified",       "Respiratory"),
    ("E11.9",  "Type 2 diabetes without complications",       "Endocrine"),
    ("E11.65", "Type 2 diabetes with hyperglycemia",          "Endocrine"),
    ("N18.3",  "Chronic kidney disease stage 3",              "Renal"),
    ("N39.0",  "Urinary tract infection",                     "Renal"),
    ("K92.1",  "Melena",                                      "Gastrointestinal"),
    ("K57.30", "Diverticulosis of large intestine",           "Gastrointestinal"),
    ("A41.9",  "Sepsis unspecified",                          "Infectious"),
    ("B97.29", "Other coronavirus as cause of disease",       "Infectious"),
    ("S72.001","Fracture of femoral head",                    "Musculoskeletal"),
    ("M79.3",  "Panniculitis",                                "Musculoskeletal"),
    ("F32.9",  "Major depressive disorder single episode",    "Mental Health"),
    ("F41.1",  "Generalized anxiety disorder",                "Mental Health"),
    ("G35",    "Multiple sclerosis",                          "Neurological"),
    ("G43.909","Migraine unspecified",                        "Neurological"),
]

BLOOD_TYPES      = ["A+","A-","B+","B-","AB+","AB-","O+","O-"]
INSURANCE_TYPES  = ["Medicare","Medicaid","Blue Cross","Aetna","Cigna","United Health","Self Pay"]
ADMISSION_TYPES  = ["Emergency","Elective","Urgent","Newborn"]
HOSPITAL_TYPES   = ["General","Specialist","Teaching","Community","Trauma Center"]
US_CITIES        = [
    ("New York","NY"), ("Los Angeles","CA"), ("Chicago","IL"),
    ("Houston","TX"),  ("Phoenix","AZ"),     ("Philadelphia","PA"),
    ("San Antonio","TX"),("San Diego","CA"), ("Dallas","TX"),
    ("Jacksonville","FL"),("Austin","TX"),   ("Fort Worth","TX"),
    ("Columbus","OH"), ("Charlotte","NC"),   ("Indianapolis","IN"),
    ("San Francisco","CA"),("Seattle","WA"), ("Denver","CO"),
    ("Boston","MA"),   ("Nashville","TN"),
]

LOAD_DATE = datetime.today().strftime("%Y-%m-%d")

print("Generating data...")

# ── HOSPITALS ────────────────────────────────────────
hospitals = []
for i in range(1, NUM_HOSPITALS + 1):
    city, state = random.choice(US_CITIES)
    hospitals.append({
        "hospital_id":   f"H{i:04d}",
        "hospital_name": f"{fake.last_name()} {random.choice(['Medical Center','General Hospital','Health System','Regional Hospital','Memorial Hospital'])}",
        "hospital_type": random.choice(HOSPITAL_TYPES),
        "city":          city,
        "state":         state,
        "bed_count":     random.randint(50, 800),
        "is_teaching":   random.choice([True, False]),
        "updated_at":    LOAD_DATE,
    })

hospitals_df = pd.DataFrame(hospitals)
hospitals_path = os.path.join(OUTPUT_DIR, 'hospitals.csv')
hospitals_df.to_csv(hospitals_path, index=False)
print(f"  hospitals.csv   — {len(hospitals_df)} rows")

# ── PATIENTS ─────────────────────────────────────────
patients = []
for i in range(1, NUM_PATIENTS + 1):
    city, state = random.choice(US_CITIES)
    dob = fake.date_of_birth(minimum_age=18, maximum_age=95)
    patients.append({
        "patient_id":      f"P{i:06d}",
        "first_name":      fake.first_name(),
        "last_name":       fake.last_name(),
        "date_of_birth":   dob.strftime("%Y-%m-%d"),
        "gender":          random.choice(["Male","Female","Other"]),
        "blood_type":      random.choice(BLOOD_TYPES),
        "city":            city,
        "state":           state,
        "insurance_type":  random.choice(INSURANCE_TYPES),
        "phone":           fake.phone_number(),
        "updated_at":      LOAD_DATE,
    })

patients_df = pd.DataFrame(patients)
patients_path = os.path.join(OUTPUT_DIR, 'patients.csv')
patients_df.to_csv(patients_path, index=False)
print(f"  patients.csv    — {len(patients_df)} rows")

# ── DIAGNOSES ─────────────────────────────────────────
diagnoses = []
for i in range(1, NUM_DIAGNOSES + 1):
    code, desc, category = random.choice(ICD10_CODES)
    diagnoses.append({
        "diagnosis_id":       f"D{i:06d}",
        "icd10_code":         code,
        "diagnosis_desc":     desc,
        "diagnosis_category": category,
        "severity":           random.choice(["Low","Medium","High","Critical"]),
        "updated_at":         LOAD_DATE,
    })

diagnoses_df = pd.DataFrame(diagnoses)
diagnoses_path = os.path.join(OUTPUT_DIR, 'diagnoses.csv')
diagnoses_df.to_csv(diagnoses_path, index=False)
print(f"  diagnoses.csv   — {len(diagnoses_df)} rows")

# ── ADMISSIONS ────────────────────────────────────────
hospital_ids = [h["hospital_id"] for h in hospitals]
patient_ids  = [p["patient_id"]  for p in patients]
diagnosis_ids= [d["diagnosis_id"] for d in diagnoses]

admissions = []
start_date = datetime(2023, 1, 1)
end_date   = datetime(2024, 12, 31)

for i in range(1, NUM_ADMISSIONS + 1):
    admit_date     = fake.date_between(start_date=start_date, end_date=end_date)
    los_days       = random.randint(1, 30)
    discharge_date = admit_date + timedelta(days=los_days)
    created_at     = admit_date.strftime("%Y-%m-%d")

    admissions.append({
        "admission_id":    f"A{i:07d}",
        "patient_id":      random.choice(patient_ids),
        "hospital_id":     random.choice(hospital_ids),
        "diagnosis_id":    random.choice(diagnosis_ids),
        "admission_type":  random.choice(ADMISSION_TYPES),
        "admit_date":      admit_date.strftime("%Y-%m-%d"),
        "discharge_date":  discharge_date.strftime("%Y-%m-%d"),
        "length_of_stay":  los_days,
        "total_cost":      round(random.uniform(500, 150000), 2),
        "readmission_flag":random.choice([True, False]),
        "updated_at":      created_at,
    })

admissions_df = pd.DataFrame(admissions)
admissions_path = os.path.join(OUTPUT_DIR, 'admissions.csv')
admissions_df.to_csv(admissions_path, index=False)
print(f"  admissions.csv  — {len(admissions_df)} rows")

print(f"\nAll files saved to: {os.path.abspath(OUTPUT_DIR)}")
print(f"Load date: {LOAD_DATE}")
print("\nDone! Ready for S3 upload.")