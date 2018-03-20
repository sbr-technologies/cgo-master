class EducationsController < ApplicationController
  layout "application_full"

  def validate
    true
  end

  def index
    @educations = current_user.educations
  end

  def show
    @education = current_user.educations.find params[:id]
  end

  def new
    @education = Education.new
  end

  def create
    @education = Education.new params[:education]

    @education.save! && current_user.educations << @education
    flash[:notice] = "#{@education.school_name} added to your profile"
    redirect_to :action => :index

  rescue ActiveRecord::ActiveRecordError
    render :new
  end

  def edit
    @education = current_user.educations.find params[:id]
  end

  def update

    @education = current_user.educations.find params[:id]

    if !@education.nil? && @education.update_attributes(params[:education])
      flash[:notice] = "Successfully updated #{@education.school_name}"
      redirect_to(educations_path) && return
    end

    render :edit
  end

  def destroy
    education = current_user.educations.find params[:id]

    unless education.nil? 
      current_user.educations.destroy education
      flash[:notice] = "Your education at #{education.school_name} has been deleted"
    end

    redirect_to educations_path
  end

end
