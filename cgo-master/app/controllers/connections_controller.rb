class ConnectionsController < ApplicationController

  before_filter :login_required

  def show
    connection = current_user.connections.find params[:id]
    render :json => connection.to_json
  end

  def photo
    connection = current_user.connections.find params[:id]

    send_data File.new(connection.photo.path, "r").read, 
      :disposition => "inline", 
      :content_type => connection.photo.content_type

  rescue
    send_data "", :status => 403
  end

 
end
