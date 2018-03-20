require File.dirname(__FILE__) + '/../test_helper'

class JobTest < ActiveSupport::TestCase
	context "A Job instance" do
		setup do
			@job = Factory(:job)
		end

		should "set status=inactive when recruiter is set to nil" do
			@job.recruiter = nil
			@job.save
			assert_equal "inactive", @job.status
		end

		should "accept a location address on #location=" do
			assert_nothing_raised { @job.location=Factory(:address, :label=>"location") }
		end

		should "return a :location address on #location" do
			assert_instance_of Address, @job.location
			address = @job.location
			assert_equal "location", address.label
		end

		should "return nil when asked for an inexistent address label on #address[]" do
			assert_nil @job.addresses[:not_existent]
		end

		should "return if it's expired on #expired?" do
			not_expired_job = Factory(:job, :expires_at => DateTime.now + 30.day)
			assert_not_nil not_expired_job.expires_at
			assert_equal false, not_expired_job.expired?

			expired_job = Factory(:job, :expires_at => DateTime.now - 30.day)
			assert_not_nil expired_job.expires_at
			assert_equal true, expired_job.expired?
		end

		should "return an employer on #employer" do
			assert_instance_of Employer, @job.employer
		end

		should "return how many months ago it was posted on #posted_months_ago" do

			# factory_girl is not setting correctly the value of 'updated_at', therefore this test is failing
			# as all sample jobs have a updated_at date that matches "today".

			posted_one_month_ago = Factory.create(:job, :created_at => 1.month.ago)

			posted_three_month_ago = Factory.create(:job, :created_at => 3.month.ago)
			posted_three_month_ago.updated_at = 3.months.ago

			posted_six_month_ago = Factory.create(:job, :created_at => 6.month.ago)
			posted_six_month_ago.updated_at = 6.months.ago

			posted_over_six_month_ago = Factory.create(:job, :created_at => 8.month.ago)
			posted_over_six_month_ago.updated_at = 8.months.ago


			assert_equal 'one-month', posted_one_month_ago.posted_months_ago
			assert_equal 'three-months', posted_three_month_ago.posted_months_ago
			assert_equal 'six-months', posted_six_month_ago.posted_months_ago
			assert_equal 'over-six-months', posted_over_six_month_ago.posted_months_ago
						
		end

	end
end
