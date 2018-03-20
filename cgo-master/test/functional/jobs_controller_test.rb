require File.dirname(__FILE__) + '/../test_helper'

class JobsControllerTest < ActionController::TestCase
		context "an authenticated user" do
				setup do
						@request.session[:user_id] = Factory(:recruiter).id
				end

				context "on GET to :search.js" do
						setup do
								get :search, { "format" => "js", "q" => {"keywords" => "java"} }
						end

						should_respond_with :success

						should "have a solr query that only includes active jobs" do
								assert_equal false, assigns(:solr_query).match(/\+status\:active/).nil?
						end
				end
		end

		context "an annonymous user" do
				setup do
				end

				context "on GET to quick_search" do
						setup do
								get :quick_search, { "format" => "js", "q" => {"keyword" => "java"} } 
						end

						should_respond_with :success

						should "have a solr query that only includes active jobs" do
								assert_equal false, assigns(:solr_query).match(/\+status\:active/).nil?
						end
				end
		end
end
