create schema dbms_assign1;
SET search_path TO dbms_assign1;

CREATE Table Department (
	Dept_id int Primary Key Not Null,
	Dept_name varchar(20),
	Operating_hours_start time Not Null,
	Operating_hours_end time Not Null,
	CONSTRAINT chk_operating_hours CHECK (
        (Dept_name = 'Emergency' AND Operating_hours_start = '00:00:00' AND Operating_hours_end = '23:59:59')
        OR 
        (Dept_name = 'General' AND Operating_hours_start = '10:00:00' AND Operating_hours_end = '20:00:00')
		OR
		(Dept_name NOT IN ('Emergency', 'General'))
    )
);

CREATE TABLE Operating_Theatre (
    Theatre_id INT PRIMARY KEY,
	Theatre_name VARCHAR(50) NOT NULL,
    Dept_id INT REFERENCES Department(Dept_id)
);

CREATE TABLE Ward (
    Ward_id INT PRIMARY KEY NOT NULL,
    Ward_type VARCHAR(20),
    Dept_id INT,
    FOREIGN KEY (Dept_id) REFERENCES Department(Dept_id)
);

CREATE TABLE Bed (
    Bed_id INT PRIMARY KEY NOT NULL,
    Bed_cost money,
	mattress_thickness int,
	bed_length int,
	bed_width int,
	comfort_level varchar(20),
    Ward_id INT,
    FOREIGN KEY (Ward_id) REFERENCES Ward(Ward_id)
);

CREATE TABLE Staff (
    Staff_id INT PRIMARY KEY NOT NULL,
    Full_name VARCHAR(50),
    Mobile int,
    Salary money,
	address varchar(100),
	Staff_Position VARCHAR(50),
    Headcount INT,
	Dept_id int,
    FOREIGN KEY (Dept_id) REFERENCES Department(Dept_id)
);

CREATE TABLE Dietician (
    Staff_ID int PRIMARY KEY,  -- One-to-one relationship with Staff
    Training_date date,
    FOREIGN KEY (Staff_ID) REFERENCES Staff(Staff_id)
);

CREATE TABLE Doctor (
    Staff_ID int PRIMARY KEY,  -- One-to-one relationship with Staff
    Training_date date,
    Prof_level VARCHAR(20),
    FOREIGN KEY (Staff_ID) REFERENCES Staff(Staff_id)
);

CREATE TABLE Speciality (
    Staff_ID INT,
    Speciality VARCHAR(20),
    PRIMARY KEY (Staff_ID, Speciality),  -- Composite primary key
    FOREIGN KEY (Staff_ID) REFERENCES Doctor(Staff_ID)
);

CREATE OR REPLACE FUNCTION check_speciality_count()
RETURNS TRIGGER AS $$
BEGIN
    -- Count the number of specialities for the doctor
    IF (SELECT COUNT(*) FROM Speciality WHERE Staff_ID = NEW.Staff_ID) >= 5 THEN
        RAISE EXCEPTION 'Each doctor can have a maximum of 5 specialities';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_speciality_count_trigger
BEFORE INSERT ON Speciality
FOR EACH ROW
EXECUTE FUNCTION check_speciality_count();

CREATE TABLE Interpreter (
    Staff_ID INT PRIMARY KEY,  -- One-to-one relationship with Staff
    Training_date DATE,
    FOREIGN KEY (Staff_ID) REFERENCES Staff(Staff_id)
);

CREATE TABLE Nurse (
    Staff_ID int PRIMARY KEY,  -- One-to-one relationship with Staff
    WorkWithChildren boolean,
	WWCC_IssueDate date,
    WWCC_ExpiryDate date,
    FOREIGN KEY (Staff_ID) REFERENCES Staff(Staff_id),
	CONSTRAINT chk_wwcc_required CHECK (
        WorkWithChildren = FALSE 
        OR (WorkWithChildren = TRUE 
			AND WWCC_IssueDate IS NOT NULL 
			AND WWCC_ExpiryDate IS NOT NULL
			AND WWCC_ExpiryDate - WWCC_IssueDate < 1095 --(3 years = 1095 days)
    		)
	)
);

CREATE TABLE Patient (
    Patient_id int PRIMARY KEY NOT NULL,
    Dob date,
    Full_name varchar(30),
    Email varchar(30),
    Address varchar(30),
    EC_Phone int,
    EC_Name varchar(30),
    Insurance_No int,
    Mobile int
);

CREATE TABLE Admission (
    admission_id INT PRIMARY KEY NOT NULL,
    admission_date DATE,
    admission_time TIME,
    nurse_name VARCHAR(50),
    doctor_name VARCHAR(50),
    admission_type VARCHAR(30),
	ref_no int,
	ref_practitioner varchar(20),
    staff_id INT UNIQUE, -- Establishing a one-to-one relationship
	Patient_id INT,
    FOREIGN KEY (staff_id) REFERENCES Staff(Staff_id),
	FOREIGN KEY (Patient_id) REFERENCES Patient(Patient_id),
	CONSTRAINT chk_planned_admission CHECK (
        (admission_type = 'Planned' AND ref_practitioner IS NOT NULL AND ref_no IS NOT NULL)
        OR 
        (admission_type = 'Emergency' AND ref_practitioner IS NULL AND ref_no IS NULL)
    )
);

CREATE TABLE Billing (
    billing_id INT PRIMARY KEY NOT NULL,
	discharge_date DATE,
    total_cost money,
    insurance_coverage money,
    remaining_balance money,
    service_description VARCHAR(200),
	payment_status VARCHAR(50) CHECK (payment_status IN ('Pending', 'Paid')),
	admission_id INT,
    FOREIGN KEY (admission_id) REFERENCES Admission(admission_id),
    UNIQUE (admission_id)  -- Ensures the one-to-one relationship
);

CREATE TABLE Credit_Card (
    card_no BIGINT PRIMARY KEY NOT NULL,
    cvv INT NOT NULL,
    cardholder_name VARCHAR(50),
    exp_date DATE,
	billing_id INT,
	FOREIGN KEY (billing_id) REFERENCES Billing(billing_id),
	UNIQUE (billing_id),  -- Ensures the one-to-one relationship
	CONSTRAINT chk_valid_card CHECK (exp_date > current_date)
);

INSERT INTO Department (Dept_id, Dept_name, Operating_hours_start, Operating_hours_end) VALUES (1001,'Emergency', '00:00:00', '23:59:59'),  
(1002,'General', '10:00:00', '20:00:00'),    
(1003,'Surgery', '08:00:00', '13:00:00'),    
(1004,'Emergency', '00:00:00', '23:59:59'),  
(1005,'Pediatrics', '00:00:00', '20:00:00');
select * from department;

INSERT INTO Operating_Theatre VALUES(1000001, 'Surgery Theatre 1', 1001),
	(1000002, 'Surgery Theatre 2', 1004),
	(1000003, 'Pediatrician Theatre 1', 1003);
select * from Operating_Theatre;

INSERT INTO Ward (Ward_id, Ward_type, Dept_id) VALUES
(201, 'General',1001),
(202, 'Specialised ICU',1001),
(203, 'Specialised ICU',1003),
(204, 'General',1004),
(205, 'Specialised ICU',1005);
select * from Ward;

INSERT INTO Bed (Bed_id, Bed_cost, mattress_thickness, bed_length, bed_width, comfort_level, Ward_id) VALUES
(401, 100.00, 12, 200, 90, 'High', 201),
(402, 150.00, 15, 210, 95, 'Medium', 202),
(403, 120.00, 10, 195, 85, 'Low', 203),
(404, 180.00, 18, 220, 100, 'High', 204),
(405, 130.00, 13, 205, 92, 'Medium', 205);
select * from Bed;

INSERT INTO Staff VALUES(101, 'Anuj Bhole', 0450511728, 120000, '31-35 Third Ave', 'Neurologist Surgeon', 7, 1001);
INSERT INTO Staff VALUES(102, 'Aashish Patnaik', 0452467982, 75000, '65-68 Pattrick Street', 'Nurse', 7, 1001);
INSERT INTO Staff VALUES(103, 'Aditya Raj', 0452908221, 90000, '12-17 Gibson Lane', 'Cardiologist', 5, 1002);
INSERT INTO Staff VALUES(104, 'Jason Roy', 0451674321, 100000, '45-46 Lawrence road', 'Pediatrician', 5, 1003);
INSERT INTO Staff VALUES(105, 'Kevin Lewis', 0451789561, 60000, '90-100 City Scape', 'Nurse', 7, 1004);
INSERT INTO Staff VALUES(106, 'Jonty Rhodes', 0450766780, 80000, '56-57 Fremont Street', 'Dietician', 5, 1001);
INSERT INTO Staff VALUES(107, 'Abby Buess', 0455671296, 80000, '38-41 Sunnyholt Road', 'Dietician', 5, 1001);
INSERT INTO Staff VALUES(108, 'Logan Paul', 0453756901, 70000, '56-57 Fremont Street', 'Interpreter', 5, 1001);
INSERT INTO Staff VALUES(109, 'Kraig Carter', 0453671204, 70000, '38-41 Sunnyholt Road', 'Interpreter', 5, 1001);
select * from staff;

INSERT INTO Dietician VALUES(106, '2017-06-23');
INSERT INTO Dietician VALUES(107, '2015-04-15');
select * from Dietician;

INSERT INTO Doctor VALUES(101, '1997-12-17', 'Veteran'),
	(103, '1999-12-27', 'Experienced'),
	(104, '2000-12-10', 'Trainee');
select * from Doctor;

INSERT INTO Speciality VALUES(101, 'Neurology'),
	(103, 'Cardiology'),
	(104, 'Pediatric');
select * from Speciality;

INSERT INTO Interpreter VALUES(108, '2017-02-01');
INSERT INTO Interpreter VALUES(109, '2016-11-30');
select * from Interpreter;

--INSERT INTO Nurse VALUES(107, TRUE, '1984-05-21', '2002-05-20'); --it gives error since WWCC is expired(more than 3 years)
INSERT INTO Nurse VALUES(108, FALSE, '2006-09-04', '2024-09-03');
INSERT INTO Nurse VALUES(109, TRUE, '2015-03-14', '2016-03-13');
select * from Nurse;

INSERT INTO Patient VALUES(10001, '1984-05-21', 'John Rim', 'john.rim@gmail.com', 'NSW, Australia', 04478424, 'Hanna Bill', 94357284, 04348342),
	(10002, '1997-11-16', 'Diya Sharma', 'Diya.sharma@gmail.com', 'ACT, Australia', 04924295, 'Ayush Nigam', 89250843, 04795935),
	(10003, '1990-12-10', 'Jannat Khan', 'jannat.khan@gmail.com', 'VIC, Australia', 049347359, 'Isha Kulkarni', 62857084, 04964833);
select * from Patient;

INSERT INTO Admission VALUES(10001, '2024-05-20', '21:31:56', 'Kevin Lewis', 'Anuj Bhole', 'Planned', 1000001, 'John Jacob', 101, 10001);
INSERT INTO Admission VALUES(10002, '2024-06-30', '17:25:34', 'Kevin Lewis', 'Aditya Raj', 'Emergency', null, null, 103, 10002);
INSERT INTO Admission VALUES(10003, '2024-06-05', '09:29:47', 'Aashish Patnaik', 'Jason roy', 'Planned', 1000002, 'Sophia Johnson', 104, 10003);
select * from Admission;

INSERT INTO Billing (billing_id, discharge_date, total_cost, insurance_coverage, remaining_balance, service_description, payment_status, admission_id) VALUES
(501, '2024-05-22', 5000.00, 4000.00, 1000.00, 'Emergency treatment', 'Paid', 10001),
(502, '2024-07-01', 3000.00, 2000.00, 1000.00, 'Routine check-up', 'Pending', 10002),
(503, '2024-06-15', 8000.00, 6000.00, 2000.00, 'Surgery', 'Paid', 10003);
select * from Billing;

INSERT INTO Credit_Card (card_no, cvv, cardholder_name, exp_date, billing_id) VALUES
(6011111111111111, 123, 'John Rim', '2025-12-31', 501),
(6022222222222222, 456, 'Diya Sharma', '2026-06-30', 502),
(6033333333333333, 789, 'Jannat Khan', '2027-09-15', 503);
select * from Credit_card;
