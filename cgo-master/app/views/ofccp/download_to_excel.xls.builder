models_to_excel(xml, @ofccp, {
    :include => [
				"query_string",
				"job_code",
				"job_title",
				"job_description",
				"applicant_name",
				"applicant_modification_date",
				"applicant_ethnicity",
				"applicant_gender",
				"resume_post_date",
				"employer_name",
				"recruiter_name",
				"recruiter_email",
				"created_at",
				"updated_at",
    "resume"
    ]
})
