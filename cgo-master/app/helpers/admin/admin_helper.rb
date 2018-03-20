module Admin::AdminHelper
  def jobfair_select(name, options={})
    options_set = options[:include_blank] ? [["All", ""]] : []
    select_tag :jobfair_id,
      options_for_select(options_set + Jobfair.find(:all, :order => 'date DESC').collect {|x| ["#{x.date.to_s(:short_with_year)} -- #{x.city}", x.id.to_s]}, params[name.to_sym]),
      options
  end
end
