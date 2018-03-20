class OfccpController < ApplicationController

				before_filter :login_required
				require_role :employer_admin

				def index
								@search_criteria = SearchCriteria.new()									# Initialize search form
								@ofccp = current_user.employer.ofccp.paginate :page => params[:page] || 1, :order => "created_at DESC"
				end

    def download

								@search_criteria = SearchCriteria.new(params[:search_criteria])

								query = []
								query << "created_at >= '#{@search_criteria.date_from}'"
								query << "created_at <= '#{@search_criteria.date_to}'"

								@ofccp = current_user.employer.ofccp.find(:all, :conditions => [query.join(" AND ")], :order => "created_at DESC") 

        if @ofccp.to_s.blank? 
          flash[:notice] = "No records match your query; please change 'from' and 'to' dates and try again"; 
          redirect_to :action => :index
          return
        end

								headers['Content-Type'] = "text/plain"
								headers['Content-Disposition'] = "attachment; filename=ofccp_report_#{Time.now.to_formatted_s(:mm_dd_yyyy)}.txt"

								render  :layout => false

    end


    # DEPRECATED: Used when only format was .xls (see method above: OfccpController#download)
				def download_to_excel
								@search_criteria = SearchCriteria.new(params[:search_criteria])

								query = []
								query << "created_at >= '#{@search_criteria.date_from}'"
								query << "created_at <= '#{@search_criteria.date_to}'"

								@ofccp = current_user.employer.ofccp.find(:all, :conditions => [query.join(" AND ")], :order => "created_at DESC") 

        if @ofccp.to_s.blank? 
          flash[:notice] = "No records match your query; please change 'from' and 'to' dates and try again"; 
          redirect_to :action => :index
          return
        end

								headers['Content-Type'] = "application/vnd.ms-excel"
								headers['Content-Disposition'] = "attachment; filename=ofccp_report_#{Time.now.to_formatted_s(:mm_dd_yyyy)}.xls"

								render  :layout => false

				end

end


class SearchCriteria
				attr_accessor :date_from, :date_to

				def initialize(value={})
								@date_from = (Date.civil(value[:"date_from(1i)"].to_i, value[:"date_from(2i)"].to_i, value[:"date_from(3i)"].to_i) rescue Date.today.ago(6.months))
								@date_to   = (Date.civil(value[:"date_to(1i)"].to_i, value[:"date_to(2i)"].to_i, value[:"date_to(3i)"].to_i)  rescue Date.today)
				end
end
