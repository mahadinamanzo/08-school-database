-- Example report term used below: 2026/2027 First Term.
-- Change the AcademicYear and TermName literals to report on another term.

-- 1. Business question: Who is enrolled in JSS1 A for 2026/2027 First Term,
--    and who is the class's form teacher?
-- Technique: JOINs connect class to its form teacher and term enrollment to students.
SELECT
    c.`ClassName`,
    CONCAT(ft.`FirstName`, ' ', ft.`LastName`) AS `FormTeacher`,
    s.`AdmissionNo`,
    CONCAT_WS(' ', s.`FirstName`, s.`MiddleName`, s.`LastName`) AS `StudentName`
FROM `SchoolClass` AS c
INNER JOIN `Teacher` AS ft
    ON ft.`TeacherID` = c.`FormTeacherID`
INNER JOIN `Term` AS t
    ON t.`AcademicYear` = '2026/2027'
   AND t.`TermName` = 'First Term'
LEFT JOIN `StudentTermEnrollment` AS e
    ON e.`ClassID` = c.`ClassID`
   AND e.`TermID` = t.`TermID`
LEFT JOIN `Student` AS s
    ON s.`StudentID` = e.`StudentID`
WHERE c.`ClassName` = 'JSS1 A'
ORDER BY s.`LastName`, s.`FirstName`;

-- 2. Business question: What is each student's total score and letter grade
--    for every subject in 2026/2027 First Term?
-- Technique: JOINs assemble the result context; CASE maps the 0-100 total to A-F.
-- Assumed grade bands: A 80-100, B 70-79, C 60-69, D 50-59, E 40-49, F below 40.
SELECT
    s.`AdmissionNo`,
    CONCAT_WS(' ', s.`FirstName`, s.`MiddleName`, s.`LastName`) AS `StudentName`,
    c.`ClassName`,
    sub.`SubjectCode`,
    sub.`SubjectName`,
    t.`AcademicYear`,
    t.`TermName`,
    r.`CA`,
    r.`Exam`,
    r.`CA` + r.`Exam` AS `TotalScore`,
    CASE
        WHEN r.`CA` + r.`Exam` >= 80 THEN 'A'
        WHEN r.`CA` + r.`Exam` >= 70 THEN 'B'
        WHEN r.`CA` + r.`Exam` >= 60 THEN 'C'
        WHEN r.`CA` + r.`Exam` >= 50 THEN 'D'
        WHEN r.`CA` + r.`Exam` >= 40 THEN 'E'
        ELSE 'F'
    END AS `Grade`
FROM `Result` AS r
INNER JOIN `StudentTermEnrollment` AS e
    ON e.`EnrollmentID` = r.`EnrollmentID`
INNER JOIN `Student` AS s
    ON s.`StudentID` = e.`StudentID`
INNER JOIN `SchoolClass` AS c
    ON c.`ClassID` = e.`ClassID`
INNER JOIN `ClassSubjectOffering` AS o
    ON o.`OfferingID` = r.`OfferingID`
INNER JOIN `Subject` AS sub
    ON sub.`SubjectCode` = o.`SubjectCode`
INNER JOIN `Term` AS t
    ON t.`TermID` = e.`TermID`
WHERE t.`AcademicYear` = '2026/2027'
  AND t.`TermName` = 'First Term'
ORDER BY c.`ClassName`, s.`LastName`, s.`FirstName`, sub.`SubjectName`;

-- 3. Business question: What is each student's average subject score and
--    position within their class for 2026/2027 First Term?
-- Technique: A CTE calculates per-student averages; RANK partitions by class
--    and term, keeps ties at the same position, and leaves gaps after ties.
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

-- Alternative for query 3 on MySQL versions before 8.0 (no window functions
-- or CTEs). Run this instead of, not in addition to, query 3:
-- rank is one plus the number of students with a strictly higher average.
-- This preserves RANK() tie and gap behavior.
SELECT
    c.`ClassName`,
    s.`AdmissionNo`,
    CONCAT_WS(' ', s.`FirstName`, s.`MiddleName`, s.`LastName`) AS `StudentName`,
    current_student.`AverageScore`,
    1 + (
        SELECT COUNT(*)
        FROM (
            SELECT
                e2.`ClassID`,
                e2.`TermID`,
                e2.`StudentID`,
                AVG(r2.`CA` + r2.`Exam`) AS `AverageScore`
            FROM `StudentTermEnrollment` AS e2
            INNER JOIN `Result` AS r2
                ON r2.`EnrollmentID` = e2.`EnrollmentID`
            GROUP BY e2.`ClassID`, e2.`TermID`, e2.`StudentID`
        ) AS higher_student
        WHERE higher_student.`ClassID` = current_student.`ClassID`
          AND higher_student.`TermID` = current_student.`TermID`
          AND higher_student.`AverageScore` > current_student.`AverageScore`
    ) AS `ClassPosition`
FROM (
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
) AS current_student
INNER JOIN `SchoolClass` AS c
    ON c.`ClassID` = current_student.`ClassID`
INNER JOIN `Student` AS s
    ON s.`StudentID` = current_student.`StudentID`
ORDER BY c.`ClassName`, `ClassPosition`, s.`LastName`, s.`FirstName`;

-- 4. Business question: What are the average, highest, and lowest student
--    scores for each subject offered by each class in 2026/2027 First Term?
-- Technique: GROUP BY forms one group per class and subject; AVG, MAX, and MIN
--    summarize the individual CA-plus-exam scores in each group.
SELECT
    c.`ClassName`,
    sub.`SubjectCode`,
    sub.`SubjectName`,
    AVG(r.`CA` + r.`Exam`) AS `AverageScore`,
    MAX(r.`CA` + r.`Exam`) AS `HighestScore`,
    MIN(r.`CA` + r.`Exam`) AS `LowestScore`
FROM `Result` AS r
INNER JOIN `StudentTermEnrollment` AS e
    ON e.`EnrollmentID` = r.`EnrollmentID`
INNER JOIN `ClassSubjectOffering` AS o
    ON o.`OfferingID` = r.`OfferingID`
INNER JOIN `SchoolClass` AS c
    ON c.`ClassID` = e.`ClassID`
INNER JOIN `Subject` AS sub
    ON sub.`SubjectCode` = o.`SubjectCode`
INNER JOIN `Term` AS t
    ON t.`TermID` = e.`TermID`
WHERE t.`AcademicYear` = '2026/2027'
  AND t.`TermName` = 'First Term'
GROUP BY c.`ClassID`, c.`ClassName`, sub.`SubjectCode`, sub.`SubjectName`
ORDER BY c.`ClassName`, sub.`SubjectName`;

-- 5. Business question: Which students failed (scored below 40) in at least
--    two subjects in 2026/2027 First Term?
-- Technique: GROUP BY collects each student's subject rows; HAVING filters the
--    groups by the count of failing scores.
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

-- 6. Business question: How many distinct subjects, classes, and class-subject
--    assignments does each teacher have in 2026/2027 First Term?
-- Technique: LEFT JOIN keeps teachers with no assignments; conditional term
--    filtering is inside the joined derived table so it does not remove them.
SELECT
    tch.`StaffNo`,
    CONCAT_WS(' ', tch.`FirstName`, tch.`LastName`) AS `TeacherName`,
    COUNT(DISTINCT o.`SubjectCode`) AS `NumberOfSubjects`,
    COUNT(DISTINCT o.`ClassID`) AS `NumberOfClasses`,
    COUNT(DISTINCT o.`OfferingID`) AS `ClassSubjectAssignments`
FROM `Teacher` AS tch
LEFT JOIN (
    SELECT o.`OfferingID`, o.`TeacherID`, o.`SubjectCode`, o.`ClassID`
    FROM `ClassSubjectOffering` AS o
    INNER JOIN `Term` AS t
        ON t.`TermID` = o.`TermID`
    WHERE t.`AcademicYear` = '2026/2027'
      AND t.`TermName` = 'First Term'
) AS o
    ON o.`TeacherID` = tch.`TeacherID`
GROUP BY tch.`TeacherID`, tch.`StaffNo`, tch.`FirstName`, tch.`LastName`
ORDER BY tch.`LastName`, tch.`FirstName`;

-- 7. Business question: Which students have attendance below 80% during
--    2026/2027 First Term?
-- Technique: A derived table aggregates attendance per student before the
--    outer query filters it. Present and Late count as attended; only recorded
--    attendance days are in the denominator.
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

-- 8. Business question: Who is the top student (including tied students) in
--    each class for 2026/2027 First Term?
-- Technique: Aggregate each student's subject average, then use RANK partitioned
--    by class and term; filtering rank 1 returns every tied top student.
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
WHERE rs.`ClassPosition` = 1
ORDER BY c.`ClassName`, s.`LastName`, s.`FirstName`;

-- View: one row per student-subject result, including term, class, scores, total,
-- and the same assumed A-F grade bands used in query 2.
CREATE OR REPLACE VIEW `v_student_results` AS
SELECT
    s.`StudentID`,
    s.`AdmissionNo`,
    CONCAT_WS(' ', s.`FirstName`, s.`MiddleName`, s.`LastName`) AS `StudentName`,
    c.`ClassID`,
    c.`ClassName`,
    t.`TermID`,
    t.`AcademicYear`,
    t.`TermName`,
    sub.`SubjectCode`,
    sub.`SubjectName`,
    r.`CA`,
    r.`Exam`,
    r.`CA` + r.`Exam` AS `TotalScore`,
    CASE
        WHEN r.`CA` + r.`Exam` >= 80 THEN 'A'
        WHEN r.`CA` + r.`Exam` >= 70 THEN 'B'
        WHEN r.`CA` + r.`Exam` >= 60 THEN 'C'
        WHEN r.`CA` + r.`Exam` >= 50 THEN 'D'
        WHEN r.`CA` + r.`Exam` >= 40 THEN 'E'
        ELSE 'F'
    END AS `Grade`
FROM `Result` AS r
INNER JOIN `StudentTermEnrollment` AS e
    ON e.`EnrollmentID` = r.`EnrollmentID`
INNER JOIN `Student` AS s
    ON s.`StudentID` = e.`StudentID`
INNER JOIN `SchoolClass` AS c
    ON c.`ClassID` = e.`ClassID`
INNER JOIN `Term` AS t
    ON t.`TermID` = e.`TermID`
INNER JOIN `ClassSubjectOffering` AS o
    ON o.`OfferingID` = r.`OfferingID`
INNER JOIN `Subject` AS sub
    ON sub.`SubjectCode` = o.`SubjectCode`;

-- View: one summary row per class-term with enrollment, curriculum, and result
-- statistics. Separate aggregates avoid inflated counts from joining results
-- directly to offerings and enrollments.
CREATE OR REPLACE VIEW `v_class_summary` AS
SELECT
    c.`ClassID`,
    c.`ClassName`,
    t.`TermID`,
    t.`AcademicYear`,
    t.`TermName`,
    CONCAT_WS(' ', ft.`FirstName`, ft.`LastName`) AS `FormTeacher`,
    enrollment_counts.`StudentCount`,
    COALESCE(offering_counts.`SubjectCount`, 0) AS `SubjectCount`,
    result_stats.`ResultCount`,
    result_stats.`AverageScore`,
    result_stats.`HighestScore`,
    result_stats.`LowestScore`
FROM (
    SELECT
        `ClassID`,
        `TermID`,
        COUNT(*) AS `StudentCount`
    FROM `StudentTermEnrollment`
    GROUP BY `ClassID`, `TermID`
) AS enrollment_counts
INNER JOIN `SchoolClass` AS c
    ON c.`ClassID` = enrollment_counts.`ClassID`
INNER JOIN `Term` AS t
    ON t.`TermID` = enrollment_counts.`TermID`
INNER JOIN `Teacher` AS ft
    ON ft.`TeacherID` = c.`FormTeacherID`
LEFT JOIN (
    SELECT
        `ClassID`,
        `TermID`,
        COUNT(*) AS `SubjectCount`
    FROM `ClassSubjectOffering`
    GROUP BY `ClassID`, `TermID`
) AS offering_counts
    ON offering_counts.`ClassID` = enrollment_counts.`ClassID`
   AND offering_counts.`TermID` = enrollment_counts.`TermID`
LEFT JOIN (
    SELECT
        e.`ClassID`,
        e.`TermID`,
        COUNT(*) AS `ResultCount`,
        AVG(r.`CA` + r.`Exam`) AS `AverageScore`,
        MAX(r.`CA` + r.`Exam`) AS `HighestScore`,
        MIN(r.`CA` + r.`Exam`) AS `LowestScore`
    FROM `Result` AS r
    INNER JOIN `StudentTermEnrollment` AS e
        ON e.`EnrollmentID` = r.`EnrollmentID`
    GROUP BY e.`ClassID`, e.`TermID`
) AS result_stats
    ON result_stats.`ClassID` = enrollment_counts.`ClassID`
   AND result_stats.`TermID` = enrollment_counts.`TermID`;
