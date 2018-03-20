require File.dirname(__FILE__) + '/../test_helper'

class AddressTest < ActiveSupport::TestCase
  should_have_db_column :label
  should_have_db_column :street_address1
  should_have_db_column :street_address2
  should_have_db_column :city
  should_have_db_column :state
  should_have_db_column :zip
  should_have_db_column :country
  should_have_db_column :email
  should_have_db_column :phone
  should_have_db_column :fax
  should_have_db_column :website

	context "An address instance" do
		setup do
			@address = Factory(:address)
		end

		should "Return city and state on #city_state" do
			assert_equal "New York, NY", @address.city_state
		end
		
	end
end
