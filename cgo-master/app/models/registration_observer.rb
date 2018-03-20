class RegistrationObserver < ActiveRecord::Observer

  def after_create(registration)

    if registration.attendant.is_a?(Recruiter)

      UserMailer.new_employer_jobfair_registration(registration).deliver
    
      # from	savinoc@aol.com
      # to	fkattan@gmail.com
      # date	Wed, Dec 2, 2009 at 11:25 AM
      # subject	Question
      # 
      # Federico,
      #  
      # Can you do this . . .
      #  
      # When a company registers for a Corporate Gray "Military Friendly" Job Fair, 
      # in addition to sending the job fair registration email to CorporateGray@aol.com, 
      # can we also send it to amandab@moaa.org?
      #  
      # Important to note, I would not want the job fair registration email going to 
      # amandab@moaa.org if it's for a Security Clearance Job Fair or the West Point 
      # Job Fair -- just the "Military Friendly" Job Fairs.
      
      # Suspend by Carl request 12/14/10
      # UserMailer.deliver_new_employer_jobfair_registration(registration, ["amandab@moaa.org"]) if registration.jobfair.category == "military_friendly"
      
      # Notify Administrator of new Job Fair Registrations
      Administrator.root_admin.messages << Message.new(
       :body => "#{registration.attendant.name} (#{registration.attendant.employer.name}) registered to #{registration.jobfair.name} Job Fair.",
       :action => "View",
       :action_url =>  "/admin/registrations/#{registration.id}" 
      )

    # Don't send email to an applicant, if the jobfair is in the past; A past jobfair date means that 
    # the applicant account is being created (resume upload) and it's registrations updated. 
    elsif registration.attendant.is_a?(Applicant) && Date.today <= registration.jobfair.date
      UserMailer.deliver_new_applicant_jobfair_registration(registration, registration.attendant.email.to_a)
    end

  end
end
