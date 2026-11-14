SET NAMES utf8mb4;

-- Create the audit table once. RESTRICT preserves transfer history; CASCADE
-- on key updates keeps the audit references valid if an identifier changes.
CREATE TABLE IF NOT EXISTS `class_transfers` (
    `TransferID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `StudentID` INT UNSIGNED NOT NULL,
    `TermID` INT UNSIGNED NOT NULL,
    `FromClassID` INT UNSIGNED NOT NULL,
    `ToClassID` INT UNSIGNED NOT NULL,
    `TransferredAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`TransferID`),
    KEY `ix_class_transfers_student_term` (`StudentID`, `TermID`),
    KEY `ix_class_transfers_from_class` (`FromClassID`),
    KEY `ix_class_transfers_to_class` (`ToClassID`),
    CONSTRAINT `chk_class_transfer_different_classes`
        CHECK (`FromClassID` <> `ToClassID`),
    CONSTRAINT `fk_class_transfer_student`
        FOREIGN KEY (`StudentID`) REFERENCES `Student` (`StudentID`)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT `fk_class_transfer_term`
        FOREIGN KEY (`TermID`) REFERENCES `Term` (`TermID`)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT `fk_class_transfer_from_class`
        FOREIGN KEY (`FromClassID`) REFERENCES `SchoolClass` (`ClassID`)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT `fk_class_transfer_to_class`
        FOREIGN KEY (`ToClassID`) REFERENCES `SchoolClass` (`ClassID`)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Simple transaction example. It is commented out so importing this file does
-- not move sample data. Uncomment it only after setting an enrolled student,
-- term, and existing target class. The enrollment must have no results yet.
/*
SET @student_admission_no = '2026/001';
SET @term_id = 1;
SET @target_class_name = 'JSS1 B';

SET @student_id = (
    SELECT `StudentID`
    FROM `Student`
    WHERE `AdmissionNo` = @student_admission_no
);
SET @target_class_id = (
    SELECT `ClassID`
    FROM `SchoolClass`
    WHERE `ClassName` = @target_class_name
);

START TRANSACTION;

-- Statement 1: record the old and new class using the current enrollment.
INSERT INTO `class_transfers`
    (`StudentID`, `TermID`, `FromClassID`, `ToClassID`)
SELECT
    e.`StudentID`,
    e.`TermID`,
    e.`ClassID`,
    @target_class_id
FROM `StudentTermEnrollment` AS e
WHERE e.`StudentID` = @student_id
  AND e.`TermID` = @term_id
  AND e.`ClassID` <> @target_class_id;

-- Statement 2: update the student's class for this term.
UPDATE `StudentTermEnrollment`
SET `ClassID` = @target_class_id
WHERE `StudentID` = @student_id
  AND `TermID` = @term_id
  AND `ClassID` <> @target_class_id;

COMMIT;
*/

-- Safer version: procedure validates the target and current enrollment,
-- locks the enrollment, performs exactly the audit INSERT and enrollment UPDATE,
-- refuses transfers after results exist, and rolls back on any SQL error
-- (including a nonexistent target class).
DROP PROCEDURE IF EXISTS `sp_move_student`;

DELIMITER //
CREATE PROCEDURE `sp_move_student`(
    IN p_student_id INT UNSIGNED,
    IN p_term_id INT UNSIGNED,
    IN p_target_class_id INT UNSIGNED
)
BEGIN
    DECLARE v_enrollment_id INT UNSIGNED;
    DECLARE v_from_class_id INT UNSIGNED;
    DECLARE v_target_exists INT UNSIGNED DEFAULT 0;
    DECLARE v_result_count INT UNSIGNED DEFAULT 0;
    DECLARE v_missing_enrollment BOOLEAN DEFAULT FALSE;

    DECLARE CONTINUE HANDLER FOR NOT FOUND
        SET v_missing_enrollment = TRUE;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF p_student_id IS NULL OR p_term_id IS NULL OR p_target_class_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Student, term, and target class are required';
    END IF;

    START TRANSACTION;

    SELECT COUNT(*)
    INTO v_target_exists
    FROM `SchoolClass`
    WHERE `ClassID` = p_target_class_id;

    IF v_target_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Target class does not exist; transfer rolled back';
    END IF;

    SELECT `EnrollmentID`, `ClassID`
    INTO v_enrollment_id, v_from_class_id
    FROM `StudentTermEnrollment`
    WHERE `StudentID` = p_student_id
      AND `TermID` = p_term_id
    FOR UPDATE;

    IF v_missing_enrollment THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'No enrollment exists for this student and term';
    END IF;

    IF v_from_class_id = p_target_class_id THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Student is already enrolled in the target class';
    END IF;

    SELECT COUNT(*)
    INTO v_result_count
    FROM `Result`
    WHERE `EnrollmentID` = v_enrollment_id;

    IF v_result_count > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot transfer after results have been recorded for this term';
    END IF;

    INSERT INTO `class_transfers`
        (`StudentID`, `TermID`, `FromClassID`, `ToClassID`)
    VALUES
        (p_student_id, p_term_id, v_from_class_id, p_target_class_id);

    UPDATE `StudentTermEnrollment`
    SET `ClassID` = p_target_class_id
    WHERE `EnrollmentID` = v_enrollment_id;

    COMMIT;
END//
DELIMITER ;

-- Example call. A nonexistent target ID raises an error and leaves no audit
-- row or enrollment change because the procedure's handler rolls back. The
-- procedure also refuses a move if this enrollment already has result rows.
-- CALL `sp_move_student`(1, 1, 2);
