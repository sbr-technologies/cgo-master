require File.dirname(__FILE__) + '/../test_helper'

class ApplicantTest < ActiveSupport::TestCase
 context "An Applicant Intance" do

		setup do
		  @applicant = Factory(:applicant)
		end

		should "have a primary Address" do
			assert_instance_of Address, @applicant.addresses[:primary]
		end

		should "be able to register to a jobfair" do
			@jobfair = Factory(:jobfair)
			assert_nothing_raised { @applicant.register_for(@jobfair) }
			@applicant.reload
			assert_equal true, @applicant.registered?(@jobfair)
		end

 end
end
