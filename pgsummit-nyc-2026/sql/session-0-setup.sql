-- ============================================================
-- SQL examples from: session-0-setup
-- ============================================================
-- -----------------------------------------------------
-- Slide 11: Step 5: Create Database and Load Bluebox
-- -----------------------------------------------------

CREATE DATABASE bluebox;
\c bluebox
CREATE EXTENSION postgis;


-- --------------------------------------
-- Slide 12: Step 6: Verify Your Setup
-- --------------------------------------

SELECT COUNT(*) FROM bluebox.film;
