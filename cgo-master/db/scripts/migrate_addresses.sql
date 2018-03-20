CREATE TABLE addresses AS (
SELECT 
 adr_id             as `id`, 
 "primary"          as `label`, 
 acc_id             as `addressable_id`, 
 "Applicant"        as `addressable_type`, 
 adr_address1       as `street_address1`, 
 adr_address2       as `street_address2`, 
 adr_city           as `city`, 
 adr_state          as `state`, 
 adr_zip            as `zip`, 
 adr_country        as `country`, 
 adr_email          as `email`, 
 adr_phone          as `phone`, 
 adr_mobile_phone   as `mobile`, 
 adr_fax            as `fax`, 
 adr_website        as `website`, 
 CURDATE()          as `created_at`, 
 NULL               as `updated_at`

FROM  address, account, applicant

WHERE acc_address = adr_id
AND   acc_id = app_acc_id
AND   acc_status = "active");


INSERT INTO addresses 
(`id`,`label`,`addressable_id`,`addressable_type`,`street_address1`,`street_address2`,`city`,`state`,`zip`,`country`,`email`,`phone`,`mobile`,`fax`,`website`,`created_at`,`updated_at`)

VALUES 

(SELECT 
 adr_id             as `id`, 
 "location"         as `label`, 
 job_id             as `addressable_id`, 
 "Job"              as `addressable_type`, 
 adr_address1       as `street_address1`, 
 adr_address2       as `street_address2`, 
 adr_city           as `city`, 
 adr_state          as `state`, 
 adr_zip            as `zip`, 
 adr_country        as `country`, 
 adr_email          as `email`, 
 adr_phone          as `phone`, 
 adr_mobile_phone   as `mobile`, 
 adr_fax            as `fax`, 
 adr_website        as `website`, 
 CURDATE()          as `created_at`, 
 NULL               as `updated_at`

FROM  address, job, publishable

WHERE job_location = adr_id
AND   pub_id = job_id
AND   pub_status = "active")
