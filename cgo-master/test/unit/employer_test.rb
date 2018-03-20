require File.dirname(__FILE__) + '/../test_helper'

class EmployerTest < ActiveSupport::TestCase

	should "tell if the employer allows job posts or not on #job_post_allowed?" do
	  assert_equal false, Factory(:employer, :job_postings_expire_at => 1.month.ago).job_post_allowed?
	  assert_equal true,  Factory(:employer, :job_postings_expire_at => 1.month.from_now).job_post_allowed?
	end

	should "tell if the employer allows resume searches or not on #resume_search_allowed?" do

		assert_equal false, Factory(:employer, :resume_search_expire_at => 1.month.ago).resume_search_allowed?
		assert_equal true,  Factory(:employer, :resume_search_expire_at => 1.month.from_now).resume_search_allowed?
	end

end
