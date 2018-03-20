class Admin::OfccpController < ApplicationController
	layout "/admin/layouts/application"


  def index
		@search_criteria = SearchCriteria.new()

		@ofccp = Ofccp.paginate :page => params[:page] || 1, :order => "created_at DESC"
  end


	def download_to_excel
		@search_criteria = SearchCriteria.new(params[:search_criteria])

		query = []
		query << "created_at >= '#{@search_criteria.date_from}'"
		query << "created_at <= '#{@search_criteria.date_to}'"

		@ofccp = Ofccp.paginate :page => params[:page] || 1, :conditions => [query.join(" AND ")], :order => "created_at DESC"

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
