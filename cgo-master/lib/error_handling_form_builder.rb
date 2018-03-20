class ErrorHandlingFormBuilder < ActionView::Helpers::FormBuilder
  
  helpers = field_helpers + 
            %w(date_select datetime_select time_select collection_select select) - 
            %w(label fields_for hidden_field) 
  
  helpers.each do |name| 
    define_method name do |field, *args| 
      options = {}
      (args.select {|argument| argument.is_a?(Hash)}  || []).each {|h| options.merge!(h)}
      build_shell(name, field, options) do 
        super
      end 
    end 
  end 
  
  

  def build_shell(name, field, options) 
    
    # This depends on validation_reflection plugin
    css_classes = (options[:class].split(" ") rescue [])
    required = "required" if !css_classes.include?("optional") &&
                             object.class.reflect_on_validations_for(field).any? { |validation| validation.macro == :validates_presence_of }
    
    @template.capture do 
      locals = { 
        :element => yield, 
        :label => options[:label] == false ? nil : label(field, options[:label], {:class => required}),
        :field_type => name,
        :required => required
      } 
      
      if name == "radio_button"
        @template.render :partial => "forms/radio_button", :locals => locals

      elsif name == "check_box"
        @template.render :partial => "forms/check_box", :locals => locals
				
      elsif has_errors_on?(field)
        locals.merge!(:error => error_message(field, options)) 
        @template.render :partial => "forms/field_with_errors", :locals => locals 

      else
        @template.render :partial => "forms/field", :locals => locals 
      end
    end 
  end 
  
  def error_message(field, options) 
    if has_errors_on?(field) 
      errors = object.errors[field.to_sym] 
      errors.is_a?(Array) ? errors.to_sentence : errors 
    else 
        '' 
    end 
  end 
  
  def has_errors_on?(field) 
    !(object.nil? || object.errors[field.to_sym].blank?) 
  end 
  
end
