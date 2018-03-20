class WelcomeController < ApplicationController

  before_filter :login_required, :except => [:index]

  def index
    @jobfairs = Jobfair.find :all, :conditions => ["date >= ?", Time.now.at_beginning_of_day.to_s(:db)]
    render :layout => "application_full"
  end

end
