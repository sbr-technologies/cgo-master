models_to_excel(xml, @applicants, {
    :include => [
      "id",
      "first_name", 
      "last_name", 
      "email", 
      "state", 
      "type_of_applicant", 
      "security_clearance"
    ]
})
