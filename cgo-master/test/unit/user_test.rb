require File.dirname(__FILE__) + '/../test_helper'

class UserTest < ActiveSupport::TestCase

	context "A User Intance" do

		setup do
		  @user = Factory(:user)
			@admin = User.new(:first_name => "Carl", :last_name=> "Savino", :username => "administrator", :password => "test", :roles => "administrator").save!
		end

		should "Return and address by its label on #addresses[]" do
			assert_instance_of Address, @user.addresses[:primary]
		end

		should "Tell if the user has a role or not on #has_role?" do
			@user.add_role("recruiter")
			assert_equal true, @user.has_role?("recruiter")
			assert_equal false, @user.has_role?("applicant")
		end

		should "Tell if the user has an Array of roles or not on #has_role?" do
			@user.add_role("recruiter")
			@user.add_role("applicant")
			assert_equal true, @user.has_role?(["recruiter", "applicant"])
		end

		should "Accept a new role on #add_role" do
			assert_nothing_raised { @user.add_role("recruiter") }
			assert_equal true, @user.has_role?("recruiter")
		end

		should "Not accept invalid roles on #add_role" do
			assert_raise(ArgumentError) { @user.add_role("not_valid_role") }
			assert_equal false, @user.has_role?("not_valid_role")
		end

		should "Remove a role on #remove_role" do
			@user.add_role("recruiter")
			@user.remove_role("recruiter")
			assert_equal false, @user.has_role?("recruiter")
		end

		should "Return humanized names for roles on #humanized_roles" do
			@user.add_role("recruiter")
			@user.add_role("applicant")
			assert_equal "Recruiter, Applicant", @user.humanized_roles

		end


		should "Return its name on #name" do
			assert_equal "Mr. John Doe", @user.name
		end

		should "Have a virtual attribute #password_confirmation that returns the same value as #password" do
			assert_equal @user.password, @user.password_confirmation
		end

		should "Authenticate when provided with username and password on #authenticate" do
			assert_equal @user, User.authenticate(@user.username, @user.password)
		end


		should "Tell if it's active or not on #is_active?" do
			@user.status = "active"
			assert_equal true, @user.is_active?

			@user.status = "inactive"
			assert_equal false, @user.is_active?
		end

		should "Return its primary address on #address" do
			assert_instance_of Address, @user.address
			assert_equal "primary", @user.address.label
		end

	end





end
