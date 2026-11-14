SET NAMES utf8mb4;

DROP PROCEDURE IF EXISTS `sp_record_result`;

DELIMITER //
CREATE PROCEDURE `sp_record_result`(
    IN p_student_id INT UNSIGNED,
    IN p_subject_code VARCHAR(12),
    IN p_term_id INT UNSIGNED,
    IN p_ca DECIMAL(5,2),
    IN p_exam DECIMAL(5,2)
)
BEGIN
    DECLARE v_enrollment_id INT UNSIGNED;
    DECLARE v_class_id INT UNSIGNED;
    DECLARE v_offering_id INT UNSIGNED;
    DECLARE v_missing_row BOOLEAN DEFAULT FALSE;

    DECLARE CONTINUE HANDLER FOR NOT FOUND
        SET v_missing_row = TRUE;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF p_student_id IS NULL OR p_term_id IS NULL
       OR p_subject_code IS NULL OR TRIM(p_subject_code) = '' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Student, subject, and term are required';
    END IF;

    IF p_ca IS NULL OR p_ca < 0 OR p_ca > 40 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'CA must be between 0 and 40';
    END IF;

    IF p_exam IS NULL OR p_exam < 0 OR p_exam > 60 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Exam must be between 0 and 60';
    END IF;

    START TRANSACTION;

    SET v_missing_row = FALSE;
    SELECT `EnrollmentID`, `ClassID`
    INTO v_enrollment_id, v_class_id
    FROM `StudentTermEnrollment`
    WHERE `StudentID` = p_student_id
      AND `TermID` = p_term_id
    FOR UPDATE;

    IF v_missing_row THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Student has no enrollment in this term';
    END IF;

    SET v_missing_row = FALSE;
    SELECT `OfferingID`
    INTO v_offering_id
    FROM `ClassSubjectOffering`
    WHERE `ClassID` = v_class_id
      AND `TermID` = p_term_id
      AND `SubjectCode` = p_subject_code
    FOR UPDATE;

    IF v_missing_row THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Subject is not offered to the student class in this term';
    END IF;

    INSERT INTO `Result` (`EnrollmentID`, `OfferingID`, `CA`, `Exam`)
    VALUES (v_enrollment_id, v_offering_id, p_ca, p_exam)
    ON DUPLICATE KEY UPDATE
        `CA` = VALUES(`CA`),
        `Exam` = VALUES(`Exam`);

    COMMIT;
END//
DELIMITER ;

-- Example: insert a new score or replace the score for this student's existing
-- subject result. The procedure manages its own transaction; call it outside
-- any application-managed transaction.
-- CALL `sp_record_result`(1, 'ENG', 1, 32.50, 51.00);
