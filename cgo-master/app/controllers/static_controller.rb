class StaticController < ApplicationController

  skip_before_filter :login_required

  def index
    path = params[:path]
    if /employer/i =~ request.env['REQUEST_URI']
      path = 'static/employer/' + path 
    else
      path = 'static/' + path
    end

    render path
  end


  def download_docx
    filename = request.fullpath.gsub(/^\/static\/download_docx\//, '')
    send_file("#{Rails.root}/public/resume_samples/#{filename}", :filename => filename, :type => Mime::Type.lookup_by_extension("docx").to_s)
  end


  def enewsletter
    render :layout =>  "application_full"
  end

  def contact_info
    render :layout => "application_full"
  end

  def blog
    render :layout => "application_full"
  end


  # Carl's Newsletter Linked Files

  def general_dynamics
    render :layout => false
  end

  def unisys_descriptions
    render :layout => false
  end

  def bnsf_hot_job
    render :layout => false
  end

  # --------------------------------

end
