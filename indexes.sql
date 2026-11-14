-- Select the database containing schema.sql and seed.sql before running this file.
-- Run the three BEFORE EXPLAIN statements first and save their output.
-- Then run the CREATE INDEX statements and the three AFTER EXPLAIN statements.
-- The BEFORE and AFTER plans are deliberately in execution order.

-- BEFORE INDEXES: Query 3 (class positions for 2026/2027 First Term).
EXPLAIN
WITH `student_averages` AS (
    SELECT
        e.`ClassID`,
        e.`TermID`,
        e.`StudentID`,
        AVG(r.`CA` + r.`Exam`) AS `AverageScore`
    FROM `StudentTermEnrollment` AS e
    INNER JOIN `Result` AS r
        ON r.`EnrollmentID` = e.`EnrollmentID`
    INNER JOIN `Term` AS t
        ON t.`TermID` = e.`TermID`
    WHERE t.`AcademicYear` = '2026/2027'
      AND t.`TermName` = 'First Term'
    GROUP BY e.`ClassID`, e.`TermID`, e.`StudentID`
),
`ranked_students` AS (
    SELECT
        `ClassID`,
        `TermID`,
        `StudentID`,
        `AverageScore`,
        RANK() OVER (
            PARTITION BY `ClassID`, `TermID`
            ORDER BY `AverageScore` DESC
        ) AS `ClassPosition`
    FROM `student_averages`
)
SELECT
    c.`ClassName`,
    s.`AdmissionNo`,
    CONCAT_WS(' ', s.`FirstName`, s.`MiddleName`, s.`LastName`) AS `StudentName`,
    rs.`AverageScore`,
    rs.`ClassPosition`
FROM `ranked_students` AS rs
INNER JOIN `SchoolClass` AS c
    ON c.`ClassID` = rs.`ClassID`
INNER JOIN `Student` AS s
    ON s.`StudentID` = rs.`StudentID`
ORDER BY c.`ClassName`, rs.`ClassPosition`, s.`LastName`, s.`FirstName`;

-- BEFORE INDEXES: Query 5 (students with two or more failed subjects).
EXPLAIN
SELECT
    c.`ClassName`,
    s.`AdmissionNo`,
    CONCAT_WS(' ', s.`FirstName`, s.`MiddleName`, s.`LastName`) AS `StudentName`,
    SUM(CASE WHEN r.`CA` + r.`Exam` < 40 THEN 1 ELSE 0 END) AS `FailedSubjects`
FROM `Result` AS r
INNER JOIN `StudentTermEnrollment` AS e
    ON e.`EnrollmentID` = r.`EnrollmentID`
INNER JOIN `Student` AS s
    ON s.`StudentID` = e.`StudentID`
INNER JOIN `SchoolClass` AS c
    ON c.`ClassID` = e.`ClassID`
INNER JOIN `Term` AS t
    ON t.`TermID` = e.`TermID`
WHERE t.`AcademicYear` = '2026/2027'
  AND t.`TermName` = 'First Term'
GROUP BY c.`ClassID`, c.`ClassName`, s.`StudentID`, s.`AdmissionNo`,
         s.`FirstName`, s.`MiddleName`, s.`LastName`
HAVING SUM(CASE WHEN r.`CA` + r.`Exam` < 40 THEN 1 ELSE 0 END) >= 2
ORDER BY c.`ClassName`, `FailedSubjects` DESC, s.`LastName`, s.`FirstName`;

-- BEFORE INDEXES: Query 7 (attendance percentage over the term date range).
EXPLAIN
SELECT
    attendance_totals.`AdmissionNo`,
    attendance_totals.`StudentName`,
    attendance_totals.`DaysRecorded`,
    attendance_totals.`DaysAttended`,
    attendance_totals.`AttendancePercentage`
FROM (
    SELECT
        s.`StudentID`,
        s.`AdmissionNo`,
        CONCAT_WS(' ', s.`FirstName`, s.`MiddleName`, s.`LastName`) AS `StudentName`,
        COUNT(*) AS `DaysRecorded`,
        SUM(CASE WHEN a.`Status` IN ('Present', 'Late') THEN 1 ELSE 0 END) AS `DaysAttended`,
        100.0 * SUM(CASE WHEN a.`Status` IN ('Present', 'Late') THEN 1 ELSE 0 END)
            / COUNT(*) AS `AttendancePercentage`
    FROM `Attendance` AS a
    INNER JOIN `Student` AS s
        ON s.`StudentID` = a.`StudentID`
    INNER JOIN `Term` AS t
        ON a.`AttendanceDate` BETWEEN t.`StartDate` AND t.`EndDate`
    WHERE t.`AcademicYear` = '2026/2027'
      AND t.`TermName` = 'First Term'
    GROUP BY s.`StudentID`, s.`AdmissionNo`,
             s.`FirstName`, s.`MiddleName`, s.`LastName`
) AS attendance_totals
WHERE attendance_totals.`AttendancePercentage` < 80
ORDER BY attendance_totals.`AttendancePercentage`, attendance_totals.`StudentName`;

-- Add targeted indexes. The enrollment and result indexes support the term
-- report's grouping and score aggregation; the attendance index supports its
-- date-range scan and covers the student/status values needed by the aggregate.
CREATE INDEX `ix_enrollment_term_class_student`
    ON `StudentTermEnrollment` (`TermID`, `ClassID`, `StudentID`);

CREATE INDEX `ix_result_enrollment_scores`
    ON `Result` (`EnrollmentID`, `CA`, `Exam`);

CREATE INDEX `ix_attendance_date_student_status`
    ON `Attendance` (`AttendanceDate`, `StudentID`, `Status`);

-- AFTER INDEXES: re-run query 3.
EXPLAIN
WITH `student_averages` AS (
    SELECT
        e.`ClassID`,
        e.`TermID`,
        e.`StudentID`,
        AVG(r.`CA` + r.`Exam`) AS `AverageScore`
    FROM `StudentTermEnrollment` AS e
    INNER JOIN `Result` AS r
        ON r.`EnrollmentID` = e.`EnrollmentID`
    INNER JOIN `Term` AS t
        ON t.`TermID` = e.`TermID`
    WHERE t.`AcademicYear` = '2026/2027'
      AND t.`TermName` = 'First Term'
    GROUP BY e.`ClassID`, e.`TermID`, e.`StudentID`
),
`ranked_students` AS (
    SELECT
        `ClassID`,
        `TermID`,
        `StudentID`,
        `AverageScore`,
        RANK() OVER (
            PARTITION BY `ClassID`, `TermID`
            ORDER BY `AverageScore` DESC
        ) AS `ClassPosition`
    FROM `student_averages`
)
SELECT
    c.`ClassName`,
    s.`AdmissionNo`,
    CONCAT_WS(' ', s.`FirstName`, s.`MiddleName`, s.`LastName`) AS `StudentName`,
    rs.`AverageScore`,
    rs.`ClassPosition`
FROM `ranked_students` AS rs
INNER JOIN `SchoolClass` AS c
    ON c.`ClassID` = rs.`ClassID`
INNER JOIN `Student` AS s
    ON s.`StudentID` = rs.`StudentID`
ORDER BY c.`ClassName`, rs.`ClassPosition`, s.`LastName`, s.`FirstName`;

-- AFTER INDEXES: re-run query 5.
EXPLAIN
SELECT
    c.`ClassName`,
    s.`AdmissionNo`,
    CONCAT_WS(' ', s.`FirstName`, s.`MiddleName`, s.`LastName`) AS `StudentName`,
    SUM(CASE WHEN r.`CA` + r.`Exam` < 40 THEN 1 ELSE 0 END) AS `FailedSubjects`
FROM `Result` AS r
INNER JOIN `StudentTermEnrollment` AS e
    ON e.`EnrollmentID` = r.`EnrollmentID`
INNER JOIN `Student` AS s
    ON s.`StudentID` = e.`StudentID`
INNER JOIN `SchoolClass` AS c
    ON c.`ClassID` = e.`ClassID`
INNER JOIN `Term` AS t
    ON t.`TermID` = e.`TermID`
WHERE t.`AcademicYear` = '2026/2027'
  AND t.`TermName` = 'First Term'
GROUP BY c.`ClassID`, c.`ClassName`, s.`StudentID`, s.`AdmissionNo`,
         s.`FirstName`, s.`MiddleName`, s.`LastName`
HAVING SUM(CASE WHEN r.`CA` + r.`Exam` < 40 THEN 1 ELSE 0 END) >= 2
ORDER BY c.`ClassName`, `FailedSubjects` DESC, s.`LastName`, s.`FirstName`;

-- AFTER INDEXES: re-run query 7.
EXPLAIN
SELECT
    attendance_totals.`AdmissionNo`,
    attendance_totals.`StudentName`,
    attendance_totals.`DaysRecorded`,
    attendance_totals.`DaysAttended`,
    attendance_totals.`AttendancePercentage`
FROM (
    SELECT
        s.`StudentID`,
        s.`AdmissionNo`,
        CONCAT_WS(' ', s.`FirstName`, s.`MiddleName`, s.`LastName`) AS `StudentName`,
        COUNT(*) AS `DaysRecorded`,
        SUM(CASE WHEN a.`Status` IN ('Present', 'Late') THEN 1 ELSE 0 END) AS `DaysAttended`,
        100.0 * SUM(CASE WHEN a.`Status` IN ('Present', 'Late') THEN 1 ELSE 0 END)
            / COUNT(*) AS `AttendancePercentage`
    FROM `Attendance` AS a
    INNER JOIN `Student` AS s
        ON s.`StudentID` = a.`StudentID`
    INNER JOIN `Term` AS t
        ON a.`AttendanceDate` BETWEEN t.`StartDate` AND t.`EndDate`
    WHERE t.`AcademicYear` = '2026/2027'
      AND t.`TermName` = 'First Term'
    GROUP BY s.`StudentID`, s.`AdmissionNo`,
             s.`FirstName`, s.`MiddleName`, s.`LastName`
) AS attendance_totals
WHERE attendance_totals.`AttendancePercentage` < 80
ORDER BY attendance_totals.`AttendancePercentage`, attendance_totals.`StudentName`;
