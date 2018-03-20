require File.dirname(__FILE__) + '/../test_helper'

class EmployerControllerTest < ActionController::TestCase

	context "an authenticated :recruiter or :employer_admin" do

		setup do
			@user = Factory(:recruiter)
			@user.add_role("employer_admin")
			@request.session[:user_id] = @user.id
		end

		context "on GET to :show" do
			setup do
				get :show, :id => @user.id
			end

			should_render_template "show"
			should_respond_with :success
		end

		context "on GET to :job_fairs" do
			setup do
				get :job_fairs
			end

			should_render_template "jobfair/index.html.erb"
			should_respond_with :success
			should_assign_to(:display_fees) { true }
		end
	end



	context "an anonymous user" do

		context "on GET to :index" do
			setup do
				get :index
			end

			should_render_template :index
			should_respond_with :success
		end

		context "on GET to :new" do
			setup do
				get :new
			end

			should_assign_to(:employer, :recruiter, :address)
			should_render_template "new"
			should_respond_with :success
		end

		context "on POST to :create with new Employer" do
			setup do
				post :create,  {
								"address" => { "label"=>"primary", "city"=>"New York", "zip"=>"10003", "country"=>"214",
															 "street_address1"=>"21E 2nd St. APT #27", "street_address2"=>"", "mobile"=>"",
															 "phone"=>"212-222-2222", "state"=>"NY"},

								"recruiter"=>{ "title"=>"Mr.", "password_confirmation"=>"test", "username"=>"fkattan-recruiter-test",
															 "last_name"=>"Kattan", "password"=>"test", "employer_id"=>"", "first_name"=>"Federico",
															 "email"=>"fkattan@gmail.com"},

								"employer"=> { "name"=>"Natural Bits Inc.", "track_image_url"=>"", "profile"=>"Natural Bits is a software company",
															 "is_federal_employer"=>"1", "is_replace_all_on_import"=>"1", "website"=>"www.naturalbits.com"}
				}

			end
			should_render_template "create"
			should_respond_with :success
			should_change("the number of employers", :by => 1)  { Employer.count }
			should_change("the number of recruiters", :by => 1) { Recruiter.count }
			should_change("the number of addresses", :by => 1)  { Address.count }

			should "set roles and status of new employer_admin" do
				assert_equal false, assigns(:recruiter).has_role?("recruiter")
				assert_equal true, assigns(:recruiter).has_role?("employer_admin")
				assert_equal true, assigns(:recruiter).is_active?
			end
			should "create a new employer" do
				assert_equal false, assigns(:employer).new_record?
			end
		end


		context "on POST to :create with an existing Employer" do
			setup do
				@employer = Factory(:employer, { "name"=>"Natural Bits Inc.", "track_image_url"=>"", "profile"=>"Natural Bits is a software company",
																				 "is_federal_employer"=>"1", "is_replace_all_on_import"=>"1", "website"=>"www.naturalbits.com"})
				post :create,  {
								"address" => { "label"=>"primary", "city"=>"New York", "zip"=>"10003", "country"=>"214",
															 "street_address1"=>"21E 2nd St. APT #27", "street_address2"=>"", "mobile"=>"",
															 "phone"=>"212-222-2222", "state"=>"NY"},

								"recruiter"=>{ "title"=>"Mr.", "password_confirmation"=>"test", "username"=>"fkattan-recruiter-test",
															 "last_name"=>"Kattan", "password"=>"test", "employer_id"=>@employer.id, "first_name"=>"Federico",
															 "email"=>"fkattan@gmail.com"}


				}

			end
			should_render_template "create"
			should_respond_with :success
			should_change("the number of recruiters", :by => 1) { Recruiter.count }
			should_change("the number of addresses", :by => 1)  { Address.count }

			should "create a new recruiter an set it 'inactive'" do
				assert_equal false, assigns(:recruiter).new_record?
				assert_equal true, assigns(:recruiter).has_role?("recruiter")
				assert_equal false, assigns(:recruiter).has_role?("employer_admin")
				assert_equal false, assigns(:recruiter).is_active?
			end

		end

		context "on GET to :show" do
			setup do
				get :show
			end

			should "redirect to 'new session'" do
					assert_redirected_to "/sessions/new"
			end
		end

		context "on GET to :edit" do
			setup do
				get :edit
			end

			should "redirect to 'new session'" do
					assert_redirected_to "/sessions/new"
			end
		end

		context "on PUT to :update" do
			setup do
				get :put
			end

		
			should "redirect to 'new session'" do
					assert_redirected_to "/sessions/new"
			end
		end
		
	end


end
