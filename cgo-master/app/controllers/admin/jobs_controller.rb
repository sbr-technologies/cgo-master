class Admin::JobsController < ApplicationController
  layout "admin/layouts/application"

	def index
		@employer = Employer.find params[:employer_id]
		@jobs =  @employer.jobs
	end
end
