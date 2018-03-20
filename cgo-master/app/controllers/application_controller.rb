# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
require 'lib/authenticated_system.rb'

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time

  include AuthenticatedSystem

  before_filter :determine_current_subdomain
  before_filter :block_inactive_account
  before_filter :login_required
  before_filter :redirect_administrator
  before_filter :fix_accept		 # IE sends an incorrect HTTP_ACCEPT, this causes strange behavior in respond_to. 

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery :secret => '2b3debaa1ed0b0b05d8c857321a270aa'

	def redirect_administrator
		redirect_to Constants::ADMIN_URL if current_user && current_user.has_role?(:admin) && !request.path.match(/^\/admin/) && !request.path.match(/^\/logout/)
	end
  
  def block_inactive_account
    (flash[:notice]="
	Your account is 'inactive'; Please contact customer service at 
	<a href='mailto:custormer_service@corporategrayonline.com'>customer_service@corporategrayonline.com</a>"
     )  && (redirect_to Constants::HOME_URL) if current_user and current_user.status == 'inactive'
  end
  
  def current_employer
    current_user.employer
  end
  
  def source_website
    request.host.split('.')[0] || "cgray"
  end

  def self.dont_require_role(roles, options={})
    roles_array = [roles].flatten
    method_name = "#{roles_array.collect {|x| x.to_s}.sort.join('_')}_required"
    skip_before_filter method_name.to_sym, options
  end
 
	
  def self.require_role(roles, options={})
    roles_array = [roles].flatten
    method_name = "#{roles_array.collect {|x| x.to_s}.sort.join('_')}_required"
    define_method method_name do
      (redirect_to(login_path) and return false) if current_user.nil?
      (flash[:error]="We are sorry; You are not authorized to access this function (redirected to 'homepage')" and redirect_to(welcome_path) and return false) unless roles_array.any? {|role| current_user.has_role?(role)}
    end

    protected method_name
    before_filter method_name.to_sym, options
  end


  def require_menu(menu)
    @menu = menu
  end

  def require_applicant_menu
    require_menu(:applicant)
  end

  def require_employer_menu
    require_menu(:employer)
  end



  #def self.require_plan(plan, options = {})
  #  define_method "#{plan}_required" do
  #    redirect_to '/' and return false unless @account.plan.send("#{plan}?")
  #  end
  #  protected "#{plan}_required"
  #  before_filterdef "#{plan}_required".to_sym, options
  #end


  def valid_lookup?(lookup, id)
    lookup.any? {|item| item[:id] == id}
  end

  def get_lookup_by_label(lookup, label)
    return (lookup.first { |item| item[:label] == label }[:id]  rescue nil)
  end

  def fix_accept
    params[:format] ||= "html" 
  end

	def determine_current_subdomain
			@current_subdomain = self.request.subdomains.join('.')
	end

# Reconstruct a date object from date_select helper form params
def build_date_from_params(field_name, params)
  Date.new(params["#{field_name.to_s}(1i)"].to_i, 
           params["#{field_name.to_s}(2i)"].to_i, 
           1)
end
 

end
