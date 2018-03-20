require File.dirname(__FILE__) + '/../test_helper'

class ApplicantControllerTest < ActionController::TestCase

		context "an authenticated applicant" do 
				setup do
						@user = Factory(:applicant)
						@request.session[:user_id] = @user.id
				end

				context "on GET to :index" do
						setup do
								get :index
						end

						should_render_template :index
						should_respond_with :success
				end


				context "on GET to :edit" do
						setup do
								@app = Factory(:applicant)
								get :edit, :id => @app.id
						end

						should_render_template :edit
						should_respond_with :success

						should "find the applicant to edit" do
								assert_not_nil assigns(:applicant)
						end
				end

				context "on PUT to :update" do
						setup do
								@app = Factory(:applicant)
								put :update, { "address"   => {"label"=>"primary", "city"=>"Frankfurt", "zip"=>"99901", "country"=>"214", "street_address1"=>"13 Garfield Street", "street_address2"=>"", "mobile"=>"", "phone"=>"607-123-4567", "state"=>"CO"},
																"applicant" => {"title"=>"Mr.", "education_level"=>"4", "ethnicity"=>"", "password_confirmation"=>"BMW325I", 
																								"availability_date(1i)"=>"", "gender"=>"", "occupational_preference"=>"X8", "willing_to_relocate"=>"0",
																								"availability_date(2i)"=>"", "last_name"=>"Tucci", "security_clearance"=>"1", "availability_date(3i)"=>"",
																								"password"=>"BMW325I", "type_of_applicant"=>"7", "us_citizen"=>"1", "first_name"=>"Sam",
																								"email"=>"TucciSam@aol.com", "branch_of_service"=>"13"},
																"id" => @app.id,
								}
						end


						should "update current_user and redirect back to edit" do
								assert_not_nil assigns(:applicant)
								assert_not_nil assigns(:address)

								assert_equal "primary", assigns(:address).label
								assert_equal "13 Garfield Street", assigns(:address).street_address1
								assert_equal "", assigns(:address).street_address2
								assert_equal "Frankfurt", assigns(:address).city
								assert_equal "CO", assigns(:address).state
								assert_equal "99901", assigns(:address).zip
								assert_equal "214", assigns(:address).country
								assert_equal "", assigns(:address).mobile
								assert_equal "607-123-4567", assigns(:address).phone

								assert_equal "Mr.", assigns(:applicant).title
								assert_equal "Sam", assigns(:applicant).first_name
								assert_equal "Tucci", assigns(:applicant).last_name
								assert_equal "BMW325I", assigns(:applicant).password
								assert_equal "TucciSam@aol.com", assigns(:applicant).email
								assert_equal "1", assigns(:applicant).security_clearance
								assert_equal "7", assigns(:applicant).type_of_applicant
								assert_equal "4", assigns(:applicant).education_level
								assert_equal "13", assigns(:applicant).branch_of_service
								assert_equal "X8", assigns(:applicant).occupational_preference
								assert_equal "", assigns(:applicant).ethnicity
								assert_equal "", assigns(:applicant).gender
								assert_equal nil, assigns(:applicant).availability_date
								assert_equal false, assigns(:applicant).willing_to_relocate

								assert_not_nil flash[:notice]
								assert_redirected_to edit_applicant_path(assigns(:applicant).id)
						end


				end


				context "on GET to :apply" do
						setup do
							 @job = Factory(:job)
							 get :apply, :job_id => @job.id
						end
						
						should_respond_with :success

						should "create a job seeker's job application" do
							assert_equal @job.id, assigns(:current_user).job_applications[0].id
						end
				end
				
		end



		# Not Authenticated tests

		context "on GET to :new" do
			  setup do
					get :new
			  end

				should_render_template :new
				should_respond_with :success

				should "setup a new applicant" do
						assert_not_nil assigns(:applicant)
						assert_equal true, assigns(:applicant).us_citizen?
						assert_equal true, assigns(:applicant).willing_to_relocate?
						assert_equal true, assigns(:applicant).addresses.any? {|a| a.label == "primary"}
				end

		end


		context "on POST to :create" do
						setup do
								post :create, { "address"   => {"label"=>"primary", "city"=>"Frankfurt", "zip"=>"99901", "country"=>"214", "street_address1"=>"13 Garfield Street", "street_address2"=>"", "mobile"=>"", "phone"=>"607-123-4567", "state"=>"CO"},
																"applicant" => {"username" => Factory.next(:username), "title"=>"Mr.", "education_level"=>"4", "ethnicity"=>"", "password_confirmation"=>"BMW325I",
																								"availability_date(1i)"=>"", "gender"=>"", "occupational_preference"=>"X8", "willing_to_relocate"=>"0",
																								"availability_date(2i)"=>"", "last_name"=>"Tucci", "security_clearance"=>"1", "availability_date(3i)"=>"",
																								"password"=>"BMW325I", "type_of_applicant"=>"7", "us_citizen"=>"1", "first_name"=>"Sam",
																								"email"=>"TucciSam@aol.com", "branch_of_service"=>"13"}
								}
						end

						should_render_template :create
						should_respond_with :success

						should "create a new applicant" do
								assert_not_nil assigns(:applicant)
								assert_not_nil assigns(:address)

								assert_not_nil assigns(:applicant).activation_code
								assert_equal true, assigns(:applicant).has_role?("applicant")
								assert_valid assigns(:applicant)
								assert_equal false, assigns(:applicant).new_record?
								assert_equal false, assigns(:applicant).addresses.select {|a| a.label == "primary"}.empty?
								assert_not_nil flash[:notice]

						end
		end


end
