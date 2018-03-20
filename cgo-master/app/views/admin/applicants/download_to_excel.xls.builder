# When exporting "all applicants" from the back-end, export only these fields:
# (for all active applicants):  
# First Name, Username, Email Address, Education Level, Security Clearance Level, 
# State, Type of Candidate (rank), Willingness to Relocate, whether they have a resume, and status
#
models_to_excel(xml, @applicants, {
    :include => [
	  "first_name", 
      "username", 
      "email",
      "education_level", 
      "security_clearance", 
      "type_of_applicant", 
      "willing_to_relocate", 
      "resume_posted_date",
      "status"
    ]
})
