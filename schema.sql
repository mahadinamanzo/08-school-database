SET NAMES utf8mb4;

DROP TRIGGER IF EXISTS trg_result_validate_offering_update;
DROP TRIGGER IF EXISTS trg_result_validate_offering_insert;

DROP TABLE IF EXISTS `Result`;
DROP TABLE IF EXISTS `Attendance`;
DROP TABLE IF EXISTS `ClassSubjectOffering`;
DROP TABLE IF EXISTS `StudentTermEnrollment`;
DROP TABLE IF EXISTS `SchoolClass`;
DROP TABLE IF EXISTS `Subject`;
DROP TABLE IF EXISTS `Term`;
DROP TABLE IF EXISTS `Teacher`;
DROP TABLE IF EXISTS `Student`;

CREATE TABLE `Student` (
    `StudentID` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `AdmissionNo` VARCHAR(20) NOT NULL,
    `FirstName` VARCHAR(60) NOT NULL,
    `LastName` VARCHAR(60) NOT NULL,
    `MiddleName` VARCHAR(60) NULL,
    `DateOfBirth` DATE NOT NULL,
    `Gender` ENUM('Female', 'Male', 'Other') NOT NULL,
    `GuardianName` VARCHAR(120) NOT NULL,
    `GuardianPhone` VARCHAR(20) NOT NULL,
    PRIMARY KEY (`StudentID`),
    UNIQUE KEY `uq_student_admission_no` (`AdmissionNo`)
) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `Teacher` (
    `TeacherID` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `StaffNo` VARCHAR(20) NOT NULL,
    `FirstName` VARCHAR(60) NOT NULL,
    `LastName` VARCHAR(60) NOT NULL,
    `Email` VARCHAR(254) NOT NULL,
    `Phone` VARCHAR(20) NOT NULL,
    `HireDate` DATE NOT NULL,
    PRIMARY KEY (`TeacherID`),
    UNIQUE KEY `uq_teacher_staff_no` (`StaffNo`),
    UNIQUE KEY `uq_teacher_email` (`Email`)
) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `Term` (
    `TermID` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `AcademicYear` VARCHAR(9) NOT NULL,
    `TermName` ENUM('First Term', 'Second Term', 'Third Term') NOT NULL,
    `StartDate` DATE NOT NULL,
    `EndDate` DATE NOT NULL,
    PRIMARY KEY (`TermID`),
    UNIQUE KEY `uq_term_academic_year_name` (`AcademicYear`, `TermName`),
    CONSTRAINT `chk_term_date_order` CHECK (`EndDate` >= `StartDate`)
) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `Subject` (
    `SubjectCode` VARCHAR(12) NOT NULL,
    `SubjectName` VARCHAR(100) NOT NULL,
    PRIMARY KEY (`SubjectCode`),
    UNIQUE KEY `uq_subject_name` (`SubjectName`)
) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `SchoolClass` (
    `ClassID` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `ClassName` VARCHAR(30) NOT NULL,
    `FormTeacherID` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`ClassID`),
    UNIQUE KEY `uq_school_class_name` (`ClassName`),
    KEY `ix_school_class_form_teacher` (`FormTeacherID`),
    -- RESTRICT prevents deleting a teacher who is still assigned to a class; CASCADE keeps references valid if a teacher ID changes.
    CONSTRAINT `fk_school_class_form_teacher`
        FOREIGN KEY (`FormTeacherID`) REFERENCES `Teacher` (`TeacherID`)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `StudentTermEnrollment` (
    `EnrollmentID` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `StudentID` INT UNSIGNED NOT NULL,
    `TermID` INT UNSIGNED NOT NULL,
    `ClassID` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`EnrollmentID`),
    UNIQUE KEY `uq_enrollment_student_term` (`StudentID`, `TermID`),
    UNIQUE KEY `uq_enrollment_id_term_class` (`EnrollmentID`, `TermID`, `ClassID`),
    KEY `ix_enrollment_term_class` (`TermID`, `ClassID`),
    -- RESTRICT preserves enrollment history; CASCADE propagates intentional key changes.
    CONSTRAINT `fk_enrollment_student`
        FOREIGN KEY (`StudentID`) REFERENCES `Student` (`StudentID`)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    -- RESTRICT preserves term records used by enrollments; CASCADE propagates intentional key changes.
    CONSTRAINT `fk_enrollment_term`
        FOREIGN KEY (`TermID`) REFERENCES `Term` (`TermID`)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    -- RESTRICT prevents removal of a class with enrollment history; CASCADE propagates intentional key changes.
    CONSTRAINT `fk_enrollment_class`
        FOREIGN KEY (`ClassID`) REFERENCES `SchoolClass` (`ClassID`)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `ClassSubjectOffering` (
    `OfferingID` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `ClassID` INT UNSIGNED NOT NULL,
    `TermID` INT UNSIGNED NOT NULL,
    `SubjectCode` VARCHAR(12) NOT NULL,
    `TeacherID` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`OfferingID`),
    UNIQUE KEY `uq_offering_class_term_subject` (`ClassID`, `TermID`, `SubjectCode`),
    KEY `ix_offering_term` (`TermID`),
    KEY `ix_offering_subject` (`SubjectCode`),
    KEY `ix_offering_teacher` (`TeacherID`),
    -- RESTRICT preserves offerings referenced by results; CASCADE propagates intentional key changes.
    CONSTRAINT `fk_offering_class`
        FOREIGN KEY (`ClassID`) REFERENCES `SchoolClass` (`ClassID`)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    -- RESTRICT preserves term history; CASCADE propagates intentional key changes.
    CONSTRAINT `fk_offering_term`
        FOREIGN KEY (`TermID`) REFERENCES `Term` (`TermID`)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    -- RESTRICT prevents deleting a subject still on a class curriculum; CASCADE propagates intentional key changes.
    CONSTRAINT `fk_offering_subject`
        FOREIGN KEY (`SubjectCode`) REFERENCES `Subject` (`SubjectCode`)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    -- RESTRICT preserves teacher assignments in the offering; CASCADE propagates intentional key changes.
    CONSTRAINT `fk_offering_teacher`
        FOREIGN KEY (`TeacherID`) REFERENCES `Teacher` (`TeacherID`)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `Result` (
    `EnrollmentID` INT UNSIGNED NOT NULL,
    `OfferingID` INT UNSIGNED NOT NULL,
    `CA` DECIMAL(5,2) NOT NULL,
    `Exam` DECIMAL(5,2) NOT NULL,
    PRIMARY KEY (`EnrollmentID`, `OfferingID`),
    KEY `ix_result_offering` (`OfferingID`),
    CONSTRAINT `chk_result_ca_range` CHECK (`CA` >= 0.00 AND `CA` <= 40.00),
    CONSTRAINT `chk_result_exam_range` CHECK (`Exam` >= 0.00 AND `Exam` <= 60.00),
    -- CASCADE removes scores that have no enrollment; CASCADE on update keeps result references valid.
    CONSTRAINT `fk_result_enrollment`
        FOREIGN KEY (`EnrollmentID`) REFERENCES `StudentTermEnrollment` (`EnrollmentID`)
        ON DELETE CASCADE ON UPDATE CASCADE,
    -- CASCADE removes scores that have no subject offering; CASCADE on update keeps result references valid.
    CONSTRAINT `fk_result_offering`
        FOREIGN KEY (`OfferingID`) REFERENCES `ClassSubjectOffering` (`OfferingID`)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `Attendance` (
    `StudentID` INT UNSIGNED NOT NULL,
    `AttendanceDate` DATE NOT NULL,
    `Status` ENUM('Present', 'Absent', 'Late') NOT NULL,
    PRIMARY KEY (`StudentID`, `AttendanceDate`),
    -- RESTRICT retains attendance history; CASCADE propagates intentional student ID changes.
    CONSTRAINT `fk_attendance_student`
        FOREIGN KEY (`StudentID`) REFERENCES `Student` (`StudentID`)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- A result's enrollment and offering must describe the same class and term.
-- With uq_enrollment_student_term and uq_offering_class_term_subject, this also
-- guarantees at most one result per student, subject, and term.
DELIMITER //
CREATE TRIGGER `trg_result_validate_offering_insert`
BEFORE INSERT ON `Result`
FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM `StudentTermEnrollment` AS e
        INNER JOIN `ClassSubjectOffering` AS o
            ON o.`ClassID` = e.`ClassID`
           AND o.`TermID` = e.`TermID`
        WHERE e.`EnrollmentID` = NEW.`EnrollmentID`
          AND o.`OfferingID` = NEW.`OfferingID`
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Result enrollment and offering must have the same class and term';
    END IF;
END//

CREATE TRIGGER `trg_result_validate_offering_update`
BEFORE UPDATE ON `Result`
FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM `StudentTermEnrollment` AS e
        INNER JOIN `ClassSubjectOffering` AS o
            ON o.`ClassID` = e.`ClassID`
           AND o.`TermID` = e.`TermID`
        WHERE e.`EnrollmentID` = NEW.`EnrollmentID`
          AND o.`OfferingID` = NEW.`OfferingID`
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Result enrollment and offering must have the same class and term';
    END IF;
END//
DELIMITER ;
