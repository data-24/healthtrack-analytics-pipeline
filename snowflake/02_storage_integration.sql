
USE DATABASE HEALTHTRACK_DB;
USE SCHEMA RAW;
USE WAREHOUSE HEALTHTRACK_WH;
-- Storage Integration: Snowflake → S3
CREATE STORAGE INTEGRATION s3_healthtrack_integration
    TYPE = EXTERNAL_STAGE
    STORAGE_PROVIDER = 'S3'
    ENABLED = TRUE
    STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::643834517895:role/healthtrack-snowflake-role'
    STORAGE_ALLOWED_LOCATIONS = ('s3://healthtrack-raw-priyankapandey/');

DESC INTEGRATION s3_healthtrack_integration;