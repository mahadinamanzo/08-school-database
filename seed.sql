SET NAMES utf8mb4;

INSERT INTO `Teacher`
    (`TeacherID`, `StaffNo`, `FirstName`, `LastName`, `Email`, `Phone`, `HireDate`)
VALUES
    (1, 'TCH-001', 'Adaeze', 'Okafor', 'adaeze.okafor@example.edu.ng', '+2348035550101', '2018-09-03'),
    (2, 'TCH-002', 'Chinedu', 'Eze', 'chinedu.eze@example.edu.ng', '+2348035550102', '2020-01-13'),
    (3, 'TCH-003', 'Funmi', 'Adebayo', 'funmi.adebayo@example.edu.ng', '+2348035550103', '2017-09-11'),
    (4, 'TCH-004', 'Ibrahim', 'Bello', 'ibrahim.bello@example.edu.ng', '+2348035550104', '2021-02-01'),
    (5, 'TCH-005', 'Ngozi', 'Nwosu', 'ngozi.nwosu@example.edu.ng', '+2348035550105', '2019-04-08'),
    (6, 'TCH-006', 'Tunde', 'Balogun', 'tunde.balogun@example.edu.ng', '+2348035550106', '2016-09-05');

INSERT INTO `SchoolClass` (`ClassID`, `ClassName`, `FormTeacherID`)
VALUES
    (1, 'JSS1 A', 1),
    (2, 'JSS1 B', 2),
    (3, 'JSS2 A', 3);

INSERT INTO `Subject` (`SubjectCode`, `SubjectName`)
VALUES
    ('ENG', 'English Language'),
    ('MTH', 'Mathematics'),
    ('BSC', 'Basic Science'),
    ('BTE', 'Basic Technology'),
    ('SST', 'Social Studies'),
    ('CVE', 'Civic Education'),
    ('CST', 'Computer Studies'),
    ('AGR', 'Agricultural Science');

INSERT INTO `Term` (`TermID`, `AcademicYear`, `TermName`, `StartDate`, `EndDate`)
VALUES (1, '2026/2027', 'First Term', '2026-09-07', '2026-12-18');

INSERT INTO `Student`
    (`StudentID`, `AdmissionNo`, `FirstName`, `LastName`, `MiddleName`,
     `DateOfBirth`, `Gender`, `GuardianName`, `GuardianPhone`)
VALUES
    (1, '2026/001', 'Amara', 'Okeke', 'Ngozi', '2013-04-12', 'Female', 'Chika Okeke', '+2348035551001'),
    (2, '2026/002', 'Daniel', 'Adebayo', NULL, '2013-09-21', 'Male', 'Kemi Adebayo', '+2348035551002'),
    (3, '2026/003', 'Zainab', 'Musa', 'Aisha', '2013-01-08', 'Female', 'Sani Musa', '+2348035551003'),
    (4, '2026/004', 'Emeka', 'Eze', 'Chukwu', '2013-11-17', 'Male', 'Ifeoma Eze', '+2348035551004'),
    (5, '2026/005', 'Mariam', 'Bello', NULL, '2013-06-03', 'Female', 'Abdul Bello', '+2348035551005'),
    (6, '2026/006', 'Tomiwa', 'Balogun', 'Olu', '2013-02-26', 'Male', 'Bisi Balogun', '+2348035551006'),
    (7, '2026/007', 'Ada', 'Nwosu', 'Chiamaka', '2013-08-14', 'Female', 'Peter Nwosu', '+2348035551007'),
    (8, '2026/008', 'Yusuf', 'Garba', NULL, '2013-12-05', 'Male', 'Amina Garba', '+2348035551008'),
    (9, '2026/009', 'Kehinde', 'Ojo', 'Akin', '2013-05-29', 'Female', 'Moses Ojo', '+2348035551009'),
    (10, '2026/010', 'Samuel', 'Umeh', NULL, '2013-03-19', 'Male', 'Grace Umeh', '+2348035551010'),
    (11, '2026/011', 'Fatima', 'Abubakar', NULL, '2013-07-11', 'Female', 'Hauwa Abubakar', '+2348035551011'),
    (12, '2026/012', 'Chisom', 'Ezeani', 'Ada', '2013-10-02', 'Male', 'Nneka Ezeani', '+2348035551012'),
    (13, '2026/013', 'Bola', 'Ogunleye', 'Yetunde', '2013-01-25', 'Female', 'Kunle Ogunleye', '+2348035551013'),
    (14, '2026/014', 'Ibrahim', 'Sule', NULL, '2013-04-30', 'Male', 'Maryam Sule', '+2348035551014'),
    (15, '2026/015', 'Nneka', 'Ekwueme', 'Oluchi', '2013-09-07', 'Female', 'Emeka Ekwueme', '+2348035551015'),
    (16, '2026/016', 'David', 'Yakubu', 'Tunde', '2012-02-16', 'Male', 'Sarah Yakubu', '+2348035551016'),
    (17, '2026/017', 'Aisha', 'Lawal', NULL, '2012-08-22', 'Female', 'Musa Lawal', '+2348035551017'),
    (18, '2026/018', 'Obinna', 'Onyeka', 'Kelechi', '2012-05-09', 'Male', 'Ngozi Onyeka', '+2348035551018'),
    (19, '2026/019', 'Temitope', 'Fashola', NULL, '2012-11-13', 'Female', 'Lanre Fashola', '+2348035551019'),
    (20, '2026/020', 'Musa', 'Danladi', 'Bashir', '2012-01-31', 'Male', 'Aisha Danladi', '+2348035551020'),
    (21, '2026/021', 'Ifunanya', 'Uba', NULL, '2012-07-04', 'Female', 'Chika Uba', '+2348035551021'),
    (22, '2026/022', 'Seyi', 'Adekunle', 'Oluwaseyi', '2012-03-27', 'Male', 'Funke Adekunle', '+2348035551022'),
    (23, '2026/023', 'Hauwa', 'Shehu', NULL, '2012-10-19', 'Female', 'Bala Shehu', '+2348035551023'),
    (24, '2026/024', 'Chukwudi', 'Okoro', 'Ifeanyi', '2012-06-12', 'Male', 'Adaeze Okoro', '+2348035551024'),
    (25, '2026/025', 'Rukayat', 'Sanni', NULL, '2012-12-01', 'Female', 'Azeez Sanni', '+2348035551025'),
    (26, '2026/026', 'Michael', 'Oche', 'John', '2012-04-06', 'Male', 'Esther Oche', '+2348035551026'),
    (27, '2026/027', 'Oluchi', 'Nnamdi', NULL, '2012-09-16', 'Female', 'Paul Nnamdi', '+2348035551027'),
    (28, '2026/028', 'Abdulrahman', 'Yusuf', 'Bello', '2012-02-03', 'Male', 'Zainab Yusuf', '+2348035551028'),
    (29, '2026/029', 'Tolu', 'Oladipo', NULL, '2012-05-24', 'Female', 'Segun Oladipo', '+2348035551029'),
    (30, '2026/030', 'Peter', 'Chukwu', 'Obi', '2012-11-28', 'Male', 'Ijeoma Chukwu', '+2348035551030');

INSERT INTO `StudentTermEnrollment` (`StudentID`, `TermID`, `ClassID`)
SELECT
    s.`StudentID`,
    1,
    CASE
        WHEN s.`StudentID` <= 10 THEN 1
        WHEN s.`StudentID` <= 20 THEN 2
        ELSE 3
    END
FROM `Student` AS s
WHERE s.`StudentID` BETWEEN 1 AND 30
ORDER BY s.`StudentID`;

INSERT INTO `ClassSubjectOffering`
    (`OfferingID`, `ClassID`, `TermID`, `SubjectCode`, `TeacherID`)
VALUES
    (1, 1, 1, 'ENG', 4), (2, 1, 1, 'MTH', 5),
    (3, 1, 1, 'BSC', 6), (4, 1, 1, 'BTE', 1),
    (5, 1, 1, 'SST', 2), (6, 1, 1, 'CVE', 3),
    (7, 1, 1, 'CST', 4), (8, 1, 1, 'AGR', 5),
    (9, 2, 1, 'ENG', 5), (10, 2, 1, 'MTH', 6),
    (11, 2, 1, 'BSC', 1), (12, 2, 1, 'BTE', 2),
    (13, 2, 1, 'SST', 3), (14, 2, 1, 'CVE', 4),
    (15, 2, 1, 'CST', 5), (16, 2, 1, 'AGR', 6),
    (17, 3, 1, 'ENG', 6), (18, 3, 1, 'MTH', 1),
    (19, 3, 1, 'BSC', 2), (20, 3, 1, 'BTE', 3),
    (21, 3, 1, 'SST', 4), (22, 3, 1, 'CVE', 5),
    (23, 3, 1, 'CST', 6), (24, 3, 1, 'AGR', 1);

-- Enrollment and offering keys, together with the schema triggers, ensure each
-- student gets at most one result per subject in their enrolled class and term.
INSERT INTO `Result` (`EnrollmentID`, `OfferingID`, `CA`, `Exam`)
SELECT
    e.`EnrollmentID`,
    o.`OfferingID`,
    20 + MOD((e.`StudentID` * 3) + (o.`OfferingID` * 7), 21),
    35 + MOD((e.`StudentID` * 11) + (o.`OfferingID` * 13), 26)
FROM `StudentTermEnrollment` AS e
INNER JOIN `ClassSubjectOffering` AS o
    ON o.`ClassID` = e.`ClassID`
   AND o.`TermID` = e.`TermID`
WHERE e.`TermID` = 1
  AND e.`StudentID` BETWEEN 1 AND 30;

INSERT INTO `Attendance` (`StudentID`, `AttendanceDate`, `Status`)
SELECT
    s.`StudentID`,
    DATE_ADD(t.`StartDate`, INTERVAL days.`DayOffset` DAY),
    CASE MOD(s.`StudentID` + days.`DayOffset`, 10)
        WHEN 0 THEN 'Absent'
        WHEN 1 THEN 'Late'
        ELSE 'Present'
    END
FROM `Student` AS s
CROSS JOIN `Term` AS t
CROSS JOIN (
    SELECT 0 AS `DayOffset`
    UNION ALL SELECT 1
    UNION ALL SELECT 2
    UNION ALL SELECT 3
    UNION ALL SELECT 4
) AS days
WHERE t.`TermID` = 1
  AND s.`StudentID` BETWEEN 1 AND 30;
