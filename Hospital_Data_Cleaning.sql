USE hospital;

/* Data Cleaning
---- Remove Patient rows where FirstName is missing
---- Standardize FirstName and LastName to proper case and create a new FullName Column
---- Gender values should be either Male or Female
---- Split CityStateCountry into City, State and Country Columns
*/

DROP TABLE IF EXISTS Dim_Patient_Clean;
DROP TABLE IF EXISTS Dim_Department_Clean;
DROP TABLE IF EXISTS Dim_Patient_Clean;

CREATE TABLE Dim_Patient_Clean(
	PatientID varchar(20) PRIMARY KEY,
    FullName varchar(120),
    Gender varchar(10),
    DOB date,
    City varchar(50),
    State varchar(50),
    Country varchar(50)
);

INSERT INTO Dim_Patient_Clean (
	PatientID, FullName, Gender, DOB, City, State, Country
)

SELECT 
	p.PatientID , 
    CONCAT(
    UPPER(LEFT(LTRIM(RTRIM(p.FirstName)), 1)),
    LOWER(SUBSTRING(LTRIM(RTRIM(p.FirstName)), 2, LENGTH(LTRIM(RTRIM(p.FirstName))))),
    ' ',
    UPPER(LEFT(LTRIM(RTRIM(p.LastName)), 1)),
    LOWER(SUBSTRING(LTRIM(RTRIM(p.LastName)), 2, LENGTH(LTRIM(RTRIM(p.LastName)))))
    )
    AS FullName,
    CASE 
		WHEN p.Gender = 'M' THEN 'Male'
        WHEN p.Gender = 'F' THEN 'Female'
        ELSE p.Gender
	END AS Gender,
    p.DOB,
    SUBSTRING_INDEX(p.CityStateCountry, ',', 1) AS City,
	SUBSTRING_INDEX(SUBSTRING_INDEX(p.CityStateCountry, ',', 2), ',', -1) AS State,
    SUBSTRING_INDEX(p.CityStateCountry, ',', -1) AS Country
    FROM Dim_Patient AS p 
    WHERE p.FirstName IS NOT NULL;

/* Data Cleaning (Department Table)
---- Remove Departments where DepartmentCategory is missing
---- Drop HOD and DepartmentName columns
---- Use Specialization as DepartmentName column
*/

CREATE TABLE Dim_Department_Clean (
	DepartmentID varchar(20) PRIMARY KEY,
    DepartmentName varchar(100),
    DepartmentCategory varchar(100)
);

INSERT INTO Dim_Department_Clean (
	DepartmentID, DepartmentName, DepartmentCategory
)
SELECT d.DepartmentID, d.Specialization, d.DepartmentCategory
FROM Dim_Department AS d
WHERE d.DepartmentCategory IS NOT NULL;

/* Data Cleaning (Patient Visits Table)
---- Merge all yearly visit tables (2020-2025 into one consolidated PatientVisits table
*/

CREATE TABLE PatientVisits(
	VisitID varchar(20) PRIMARY KEY,
    PatientID varchar(20),
    DoctorID varchar(20),
    DiagnosisID varchar(20),
    TreatmentID varchar(20),
    PaymentMethodID varchar(20),
    DepartmentID varchar(20),
    VisitDate date,
    VisitTime time,
    DischargeDate date,
    BillAmount decimal(18,2),
    InsuranceAmount decimal(18,2),
    SatisfactionScore int,
    WaitTimeMinutes int,
    
    FOREIGN KEY(PatientID) REFERENCES Dim_Patient_Clean(PatientID),
    FOREIGN KEY(DoctorID) REFERENCES Dim_Doctor(DoctorID),
    FOREIGN KEY(DepartmentID) REFERENCES Dim_Department_Clean(DepartmentID),
    FOREIGN KEY(DiagnosisID) REFERENCES Dim_Diagnosis(DiagnosisID),
    FOREIGN KEY(TreatmentID) REFERENCES Dim_Treatment(TreatmentID),
    FOREIGN KEY(PaymentMethodID) REFERENCES Dim_PaymentMethod(PaymentMethodID)
);

INSERT INTO PatientVisits (
	VisitID, PatientID, DoctorID, DiagnosisID, TreatmentID, PaymentMethodID, VisitDate,
	VisitTime, DischargeDate, BillAmount, InsuranceAmount, SatisfactionScore, WaitTimeMinutes
)

SELECT
	VisitID, PatientID, DoctorID, DiagnosisID, TreatmentID, PaymentMethodID, VisitDate,
	VisitTime, DischargeDate, BillAmount, InsuranceAmount, SatisfactionScore, WaitTimeMinutes
FROM PatientVisits_2020_2021

UNION ALL

SELECT
	VisitID, PatientID, DoctorID, DiagnosisID, TreatmentID, PaymentMethodID, VisitDate,
	VisitTime, DischargeDate, BillAmount, InsuranceAmount, SatisfactionScore, WaitTimeMinutes
FROM PatientVisits_2022_2023

UNION ALL

SELECT
	VisitID, PatientID, DoctorID, DiagnosisID, TreatmentID, PaymentMethodID, VisitDate,
	VisitTime, DischargeDate, BillAmount, InsuranceAmount, SatisfactionScore, WaitTimeMinutes
FROM PatientVisits_2025;