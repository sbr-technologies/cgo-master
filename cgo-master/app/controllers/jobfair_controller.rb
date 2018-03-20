class JobfairController < ApplicationController

  before_filter :login_required, :except =>["index", "show", "registered_employers"]
  # require_role  :applicant,      :except => ["new", "create"]
  before_filter :find_model, :except => ["index"]

  def index
  end

  def show
  end

  def registered_employers
    @employers = @jobfair.registrations.collect {|registration| 
      registration.attendant.employer if registration.attendant.instance_of?(Recruiter)
    }.compact.sort { |x, y| x.name <=> y.name }
  end


  private

  def find_model
    @jobfair = Jobfair.includes(:registrations).find(params[:id])
  end
end
