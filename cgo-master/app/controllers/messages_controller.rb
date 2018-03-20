class MessagesController < ApplicationController

  before_filter :login_required

  def index
    @messages = current_user.messages(:order => "created_at desc", :limit => 100)
  end

  def new
    @recipient = User.find params[:recipient]
    @job_id = params[:job_id]
  end

  def create
    @job_id = params[:message][:job_id]
    user = User.find params[:message][:recipient]
    unless user.nil?
      user.messages << Message.new(:body => params[:message][:body], :sender => current_user)
      UserMailer.new_message_notification(user).deliver
    end
  end
end
