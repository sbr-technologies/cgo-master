Factory.define :address do |a|
  a.street_address1			"21W 2nd St. APT. 27"
	a.city								"New York"
	a.state								"NY"
	a.zip									"10003"
	a.country							"U.S."
	a.phone								"+1 (212) 222-2222"
end

Factory.sequence :username do |n|
  "test-username-#{n}"
end

Factory.define :user do |u|
	u.username  { Factory.next(:username) }
	u.password  "test"
	u.status "active"
	u.title  "Mr."
	u.first_name "John"
	u.last_name  "Doe"
	u.email {|a| "#{a.username}@gmail.com"}
	u.addresses {|a| [a.association(:address, :label => 'primary')]}
end

Factory.sequence :employer_name do |n|
	"employer_name_#{n}"
end

Factory.define :employer do |e|
	e.name																{Factory.next(:employer_name) }
	e.profile															"Empty Profile"
	e.comments														"Empty"
	e.website															"website"
	e.is_federal_employer									false
	e.max_recruiters											10
	e.job_postings_expire_at							3.months.from_now
	e.resume_search_expire_at							3.months.from_now
	e.is_replace_all_on_import						true
	e.is_notify_job_postings							true
end


Factory.define :recruiter do |r|
	r.roles "recruiter"
	r.username  { Factory.next(:username) }
	r.password  "test"
	r.status "active"
	r.title  "Mr."
	r.first_name "John"
	r.last_name  "Doe"
	r.email {|a| "#{a.username}@gmail.com"}
	r.addresses {|a| [a.association(:address, :label => 'primary')]}
	r.employer {|a| a.association(:employer)}
end


Factory.define :applicant do |r|
	r.roles "applicant"
	r.username  { Factory.next(:username) }
	r.password  "test"
	r.status "active"
	r.title  "Mr."
	r.first_name "John"
	r.last_name  "Doe"
	r.email {|a| "#{a.username}@gmail.com"}
	r.addresses {|a| [a.association(:address, :label => 'primary')]}

  r.branch_of_service						0
  r.education_level							0
  r.occupational_preference			0
  r.security_clearance					0
  r.type_of_applicant						0
  r.us_citizen									true
  r.willing_to_relocate					false
end




Factory.sequence :job_code do |n|
	"JOBCODE-#{n}"
end

Factory.sequence :title do |n|
	"Job Title #{n}"
end

Factory.define :job do |j|
	j.code {Factory.next(:job_code)}
	j.title {Factory.next(:title)}
	j.description "Job Description"
	j.requirements "Job Requirements"
	j.expires_at {DateTime.now + 30.day}
	j.company_name "Emirca Technologies"
	j.experience_required false
	j.payrate 0
	j.education_level 0
	j.security_clearance 0
	j.travel_requirements 0
	j.relocation_cost_paid false
	j.show_company_profile false
	j.recruiter {|a| a.association(:recruiter)}
	j.addresses {|a| [a.association(:address, :label => 'location')]}
end


Factory.define :jobfair do |j|
	j.category										"military friendly"
	j.sponsor											"cgray"
	j.date												"05/25/2009"
	j.start_time									"10:00 AM"
	j.end_time										"3:00 PM"
	j.fees												800
	j.city												"New York"
	j.location										"Javitz Conventions Center"
	j.location_url								"www.javitzcc.com"
	j.recommended_hotel						"Holliday Inn"
	j.recommended_hotel_url				"www.hollidayinn.com"
	j.security_clearance_required	false
end


