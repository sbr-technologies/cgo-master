SELECT
acc_id                           as `id`,
"Applicant"                      as `type`,
acc_username                     as `username`,
acc_password                     as `password`,
acc_status                       as `status`,
"applicant"                      as `roles`,
CURDATE()                        as `activated_at`,
acc_import_date                  as `imported_at`,
""                               as `deleted_at`,
acc_last_login_date              as `last_login_at`,
acc_login_count                  as `login_count`,
acc_title                        as `title`,
acc_first_name                   as `first_name`,
acc_last_name                    as `last_name`,
acc_middle_initial               as `initial`,
adr_email                        as `email`,
acc_source                       as `source`,
"No"                             as `remember_token`,
""                               as `remember_token_expires_at`,
acc_creation_date                as `created_at`,
acc_modification_date            as `updated_at`,
app_job_title                    as `job_title`,
app_ethnicity                    as `ethnicity`,
app_gender                       as `gender`,
app_availability_date            as `availability_date`,
app_branch_of_service            as `branch_of_service`,
app_education_level              as `education_level`,
app_ocupational_preference       as `occupational_preference`,
app_security_clearance           as `security_clearance`,
app_type_of_applicant            as `type_of_applicant`,
app_military_status              as `military_status`,
app_us_citizen                   as `us_citizen`,
app_willing_to_relocate          as `willing_to_relocate`,
""                               as `employer_id`

FROM account, applicant, address

WHERE acc_id = app_acc_id
AND   acc_address = adr_id
AND   acc_status = "active"
AND   acc_status = "active" ;
