class Admin::JobfairsController < ApplicationController
  layout "admin/layouts/application"

  before_filter :login_required
  require_role	:admin

  before_filter :load_model, :except => ["index", "new", "create"]
  
  def index
    respond_to do |format|

      format.html {
        @jobfairs = Jobfair.paginate :page =>params[:page] || 1, :order => "date DESC"
      }

      format.xls {
        @jobfairs = Jobfair.find :all, :order => "date DESC"
        headers['Content-Type'] = "application/vnd.ms-excel"
        headers['Content-Disposition'] = "attachment; filename='jobfairs#{Time.now.to_formatted_s(:mm_dd_yyyy)}.xls'"
      }

    end
  end

  def show
  end

  def new
    @jobfair = Jobfair.new
    @jobfair.sponsor = Jobfair::SPONSORS[:cgray]
    @jobfair.seminars.build
  end

  def create
    @jobfair = Jobfair.new(params[:jobfair]) 
    @jobfair.external_registration_url = "http://#{@jobfair.external_registration_url}" unless @jobfair.external_registration_url =~ /^http:\/\/.*$/   # Normailze
    @jobfair.save!

    flash[:notice] = "Successfully created Job Fair"
    redirect_to :action => "index"

  rescue ActiveRecord::ActiveRecordError
    render :action => "new"
  end

  def edit
  end


  def update
    params[:jobfair][:existing_seminar_attributes] ||= {}

    #normalize
    params[:jobfair][:external_registration_url]="http://#{params[:jobfair][:external_registration_url]}" unless params[:jobfair][:external_registration_url].blank? || params[:jobfair][:external_registration_url] =~ /^http:\/\/.*$/

    @jobfair.update_attributes(params[:jobfair])

    flash[:notice] = "Your changes have been saved"

  rescue
    @jobfair.valid?

  ensure
    render :action => "edit"
  end


  private

  def load_model
    @jobfair = Jobfair.find(params[:id]) || nil
  end
  
end
