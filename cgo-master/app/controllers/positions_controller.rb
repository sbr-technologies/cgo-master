class PositionsController < ApplicationController

  layout "application_full"

  def validate
    true
  end

  def index
    @positions = current_user.positions
  end

  def show
    @position = current_user.positions.find params[:id]
  end

  def new
    @position = Position.new
  end

  def create
    @position = Position.new params[:position]

    @position.save! && current_user.positions << @position
    flash[:notice] = "New position #{@position.title} saved successfuly"
    redirect_to :action => :index

  rescue ActiveRecord::ActiveRecordError
    render :new

  end

  def edit
    @position = current_user.positions.find params[:id]
  end

  def update

    @position = current_user.positions.find params[:id]

    if !@position.nil? && @position.update_attributes(params[:position])
      flash[:notice] = "Succesfully updated #{@position.title} at #{@position.company}"
      redirect_to(positions_path) && return
    end

    render :edit
  end

  def destroy 
    position = current_user.positions.find params[:id]

    unless position.nil? 
      current_user.positions.destroy position
      flash[:notice] = "Your position: #{position.title} has been deleted"
    end

    redirect_to positions_path
  end

end
