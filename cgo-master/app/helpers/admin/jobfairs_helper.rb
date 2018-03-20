module Admin::JobfairsHelper

def fields_for_seminar(seminar, &block)
  prefix = seminar.new_record? ? "new" : "existing"
	fields_for("jobfair[#{prefix}_seminar_attributes][]", seminar, &block)
end

def add_seminar_link(name)
  link_to_function name do |page|
		page.insert_html :bottom, :seminars, :partial => "seminar_form", :object => Seminar.new
	end
end


end
