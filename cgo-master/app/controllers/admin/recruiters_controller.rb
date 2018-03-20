class Admin::RecruitersController < ApplicationController
  layout "admin/layouts/application"

  protect_from_forgery :except => ["auto_complete_for_employer_name", "index_by_employer"]

   def index

     if !params[:recruiter_employer].to_s.blank?
       results = Recruiter.find :all, 
          :include => [:employer], 
          :conditions => ["roles = 'recruiter' AND employers.name like ?", "#{params[:recruiter_employer]}%" ] , 
          :order => "last_name, first_name ASC"

     elsif !params[:recruiter_last_name].to_s.blank?
       results = Recruiter.find :all, 
          :include => [:employer],
          :conditions => ["last_name like ?", "#{params[:recruiter_last_name]}%"],
          :order => "last_name, first_name ASC"
     else
       results = []
     end

     @recruiters = results.select {|r| !r.has_role?("employer_admin") }

     respond_to do |format|
       format.xhr { render :layout => false, :template => "admin/recruiters/index.html.erb" }
     end
     
   end

   def edit_employer
   end

   def update_employer
     new_employer = Employer.find params[:new_employer_id]
     params[:recruiters].each do |recruiter_id|

       recruiter = Recruiter.find(recruiter_id)

       recruiter.employer.registrations.each do |registration|
         new_employer.registrations << registration unless new_employer.registrations.any? { |r| r.jobfair_id == registration.jobfair_id }
       end

       new_employer.recruiters <<  recruiter
     end
  
     redirect_to :action => :edit_employer

   end

   def auto_complete_for_employer_name
     results = Employer.find :all, :include => ["recruiters"], :conditions => ["name like ?", params[:employer][:name]+'%' ]
     @employers = results.select {|e| e.recruiters.any? {|r| r.has_role?("employer_admin")} }
     render :layout => false
   end

   def show
    @employer = Employer.find params[:employer_id]
    @recruiter = @employer.recruiters.find params[:id]
   end


  def new

	   @employer = Employer.find params[:employer_id]

    if @employer.recruiters.size >= @employer.max_recruiters
      logger.info("#{@employer.name} has reached the maximum number of recruiters allowed ")
      flash[:notice]="You have reached the maximum number of recruiters allowed for #{@employer.name}"
      redirect_to admin_employer_path(@employer.id)
    end

    @recruiter = Recruiter.new
    @address =  Address.new(:label => 'primary')
  end


  def create
	   @employer = Employer.find params[:employer_id]

    @recruiter = Recruiter.new(params[:recruiter])
    @recruiter.activated_at = Time.now					# Don't require email activation code for recruiters created through the back-end
    @address = Address.new(params[:address])
    @employer.recruiters << @recruiter

    Recruiter.transaction do
      @recruiter.save!
      @recruiter.addresses << @address
    end

    flash[:notice] = "Your changes have been saved"
    redirect_to admin_employer_path(@employer.id)

  rescue ActiveRecord::ActiveRecordError
    @address.valid?
    render :action => "new"
  end


  def edit
    @employer = Employer.find params[:employer_id]
    @recruiter = @employer.recruiters.find(params[:id])
    @address = @recruiter.addresses[:primary] || Address.new(:label => "primary")
  end


  def update
    @employer = Employer.find params[:employer_id]
    @recruiter = @employer.recruiters.find(params[:id])

    Recruiter.transaction do
	    @recruiter.update_or_create_address(params[:address].merge({:label => "primary"}))
      @recruiter.update_attributes!(params[:recruiter])
    end

    flash[:notice] = "Your changes to #{@recruiter.name}\' profile have been saved"
    redirect_to admin_employer_path(:id => @employer.id)

  rescue ActiveRecord::ActiveRecordError => e
    @recruiter.valid?
    flash[:error] = e.to_s
    render :action => "edit"
  end

  def download_to_excel

			 @employer = Employer.find params[:employer_id]
			 @recruiters = @employer.recruiters

			 headers['Content-Type'] = "application/vnd.ms-excel"
       headers['Content-Disposition'] = "attachment; filename=#{@employer.id}_recruiters_#{Time.now.to_formatted_s(:mm_dd_yyyy)}.xls"

			 render :layout => false
	end

end
