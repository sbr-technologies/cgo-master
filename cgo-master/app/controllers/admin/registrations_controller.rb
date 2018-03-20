require "will_paginate/collection"

class Admin::RegistrationsController < ApplicationController
  layout "admin/layouts/application"

	before_filter :login_required
	require_role  :admin
	
	before_filter :load_model, :except => ["index", "new", "create"]


	def index
		query = []
		@page = params[:page] || 1
		@jobfair_id = params[:jobfair_id] || ""
		@attendant_type = params[:attendant_type] || ""

		unless @attendant_type.empty?
          query << "r.jobfair_id=#{@jobfair_id}" unless @jobfair_id.empty?
          query << "u.id=r.attendant_id"
          query << "u.type='#{params[:attendant_type]}'"

          @registrations = WillPaginate::Collection.create(@page, 30) do |pager|
            result = Registration.find_by_sql "SELECT r.* FROM users u, registrations r WHERE #{query.join(' AND ')} ORDER BY created_at DESC LIMIT #{pager.offset}, #{pager.per_page} "
            pager.replace(result)

            unless pager.total_entries
              pager.total_entries = Registration.count_by_sql "SELECT COUNT(*) FROM users u, registrations r WHERE #{query.join(' AND ')}"
            end
          end
		else
          query << "jobfair_id='#{@jobfair_id}'" unless @jobfair_id.empty?
          @registrations = Registration.paginate :page =>params[:page] || 1, :conditions => [query.join(" AND ")], :order => "created_at DESC"
		end

	end

	def show
	end

	def new
      attendant = User.find params[:attendant_id]
      jobfair = Jobfair.find params[:jobfair_id]

      if attendant.instance_of?(Recruiter)
        @registration = Registration.new(:jobfair => jobfair, :attendant => attendant)
        @registration.banner_company_name = attendant.employer.name
        @registration.fax = attendant.addresses[:primary].fax
        @registration.url = attendant.employer.website
        @registration.lunches_required = 2;
        @registration.available_positions = attendant.employer.profile
      else
        attendant.register_for(jobfair)
        redirect_to(admin_applicants_path) && return
      end
	end

	def create
      attendant = User.find params[:attendant_id]
      jobfair = Jobfair.find(params[:jobfair_id])

      # Applicants don't need a form, their registration is created in Admin::RegistrationController#new (see above)
      if attendant.instance_of?(Recruiter)
          @registration = Registration.new(params[:registration])
          @registration.attendant = attendant
          @registration.jobfair = jobfair

          if(@registration.attendant.register_for(jobfair, params[:registration]))
            flash[:notice] = "Registration for #{jobfair.name} created."
          else
            flash[:notice] = "Recruiter is already registered for #{jobfair.name}. New Registration Ignored. Use Edit from the Registrations Section"
          end

          redirect_to admin_employer_recruiter_path(:employer_id => @registration.attendant.employer.id, :id => @registration.attendant.id)
      end

	end
	
	def edit
	end

	def update
      @registration.update_attributes(params[:registration])
      flash[:notice] = "Your changes have been saved"
      redirect_to edit_admin_registration_path(@registration.id)
	end

    def destroy
      if @registration
        respond_to do |format|
          Registration.delete(@registration)
          format.html {
            flash[:notice] = "Registration Deleted"
            redirect_to admin_jobfair_path(@registration.jobfair.id)
          }
          format.js
        end
      end
    end


#	def destroy
#		registration = Registration.find params[:id]
#		Registration.delete(registration)
#
#		render :nothing => true
#	end
	

	def enable_search
      @registration.enable_search = params[:enable] == "yes" ? true : false
      @registration.save!

      render :nothing => true
	end

	private

	def load_model
      @registration = Registration.find params[:id]
	end
end
