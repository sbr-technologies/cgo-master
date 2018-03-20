class Admin::UsersController < ApplicationController
  layout "admin/layouts/application"


  before_filter :login_required
  require_role(:admin)

  before_filter :load_model, :except => ["index", "new", "create"]


	def index
		@users = User.administrators
	end

	def edit
	end

	def update
		@user = User.find params[:id]
		@user.update_attributes(params[:user])
		@user.save!

		flash[:notice] = "Your Changes have been saved"
		render :action => "edit"

	rescue
	  @user.valid?
		render :action => "edit"

	end

	def new
		@user = User.new
	end

	def create
		@user = User.new(params[:user])
		@user.save!

		redirect_to(admin_users_path)

	rescue
		@user.valid?
		render :action => "new"
	end

	def destroy
		@user.destroy
		redirect_to admin_users_path
	end

	def skip_email_verification
        @user.activate if params[:enable] == "yes"
        render :nothing => true
	end

  private 

  def load_model
    @user = User.find params[:id]
  end
end
