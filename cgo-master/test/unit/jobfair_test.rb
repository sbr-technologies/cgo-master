require File.dirname(__FILE__) + '/../test_helper'

class JobfairTest < ActiveSupport::TestCase
		context "A Jobfair Instance" do
				setup do
						@jobfair = Factory(:jobfair)
				end

				should "Have a valid sponsor" do
						@jobfair = Factory(:jobfair, :sponsor => "cgray")
						assert_equal true, Jobfair::SPONSORS.include?(@jobfair.sponsor.to_sym)
						@jobfair = Factory(:jobfair, :sponsor => "not_valid")
						assert_equal false, Jobfair::SPONSORS.include?(@jobfair.sponsor.to_sym)
				end


		end
end
