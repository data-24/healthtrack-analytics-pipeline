
USE DATABASE HEALTHTRACK_DB;
USE SCHEMA RAW;
USE WAREHOUSE HEALTHTRACK_WH;
-- External Stage pointing to S3
CREATE STAGE s3_healthtrack_stage
    STORAGE_INTEGRATION = s3_healthtrack_integration
    URL = 's3://healthtrack-raw-priyankapandey/'
    FILE_FORMAT = (
        TYPE = CSV 
        FIELD_OPTIONALLY_ENCLOSED_BY = '"' 
        SKIP_HEADER = 1
    );

-- Test connection
LIST @s3_healthtrack_stage;