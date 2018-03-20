require "error_handling_form_builder"

# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper


  # error_messages_for was removed in rails 3.0
  # this is my own implementation to mimic the 
  # original rails 2 helper. 
  def error_messages_for(*args)
    html = ""

    total_number_of_errors = args.inject(nil) {|sum, x| sum ? sum + (x.errors.length rescue 0) : x.errors.length}

    if(total_number_of_errors > 0)
      html << "<div id='errorExplanation' class='errorExplanation'>"
      html << "<h2>Errors prohibited this record from being saved.</h2>"
      html << "<p>There were problems with the following fields:</p><br/>"

      args.each do |model|
        html << "<ul>"
        model.errors.full_messages.each do |msg|
          html << "<li>#{msg}</li>"
        end
        html << "</ul>"
      end
      html << "</div>"
    end

    return html.html_safe
  end
    

  # Use this when printing attributes, this method avoids getting exceptions when
  # trying to print attributes of an unexpected "nil"
  def try(&block)
    (yield block rescue nil)
  end

 
  def lm(model_name, attribute_name)
    eval("#{model_name}.human_attribute_name(:#{attribute_name.to_s})").humanize
  end
  
  def lc(word)
    eval("l(:#{word.to_s})").capitalize
  end
  
  
  def or_unspecified(value, default = "Unspecified")
    !value.nil? && !value.empty? ? value : default
  end
  
  # Translate true / false to Yes / No
  def to_yes_no(value)
    value && "yes" || "no"
  end

  def to_y_n(value)
    value && "y" || "n"
  end
  
  def to_label(value, hash)
    hash.find {|item| item[:id] == value}[:label] rescue ""
  end
  
  def to_css_class(value, hash)
    to_label(value, hash).downcase.gsub(/\s/, '-').gsub(/\//, '').gsub(/(-){2}/,'-')
  end
  
  def tagged_form_for(name, *args, &block)
    options = args.last.is_a?(Hash) ? args.pop : {}
    options = options.merge(:builder => TaggedBuilder)
    args = (args << options)
    form_for(name, *args, &block)
  end
  
  def give_focus_to(id)
    "<script>$('#{id}').focus();</script>"
  end
  
  # Show flashers wrapped around the right class, for error, or notice. 
  def flashers
    if flash[:notice]
      "<div style='padding-top:8px; padding-bottom:10px;'><div class='round-corners notice-highlight' id='flasher'><img style='padding-left:5px;padding-right:10px;' src='/images/icns/crystal/16x16/actions/ok.png'/><span style='height:16px;vertical-align:top;'>#{flash[:notice]}</span></div></div>"

    elsif flash[:error]
      "<div class='round-corners error-highlight' id='flasher' style='margin: 0 4px 20px 4px'><div style='border-radius:3px;padding:10px;padding-left:12px;margin-right:0px;'>#{flash[:error]}</div></div>"
    end
  end
  
  def error_message_for(object)
    objects = Array.new([object]).flatten
    "<p id='errorExplanation'>#{lc(:oops_enter_correct_info)}</p>" if objects.any? {|o| error_messages_for(o).size > 0 }
  end
  
  
  def tr_for(model, options={}, &block)
    options[:tag] = "tr"
    model_tag_for(model, options, &proc)
  end


    
  def model_tag_for(model, options={}, &block)
    if block_given?
      content = capture(&proc)
      concat("<#{options[:tag] || 'tr'} id=\"#{model.class.name.downcase}_#{model.id}\" class=\"#{model.class.name.downcase} #{options[:class].to_a.join(' ') rescue ""}\">", proc.binding)
      concat(content, proc.binding)
      concat("</div>", proc.binding)
    end
  end
  
  
  def link_to_tagged_current(name, options = {}, html_options = {}, &block)
    current = false
    highlights = html_options[:highlights_on] ? html_options[:highlights_on] + [options] : [options]
    
    highlights.each do |h|
      if (h[:controller] == controller.controller_name and !h[:action]) or
          (h[:controller] == controller.controller_name and h[:action] == controller.action_name and !h[:id]) or
          (!h.kind_of?(Hash) and current_page?(h))
        current = true
        break
      end
    end
    
    if current
      html_options[:class] = "#{html_options[:class].to_s} current".strip
    end
    
    html_options[:highlights_on] = nil
    link_to name, options, html_options, &block
  end
   
  
  # This helper crates an options array from CGO's various lookup tables. 
  # like: branch_of_service, type_of_applicant, etc. 
  def options_from_hash(collection, options={})
    opts = (options[:include_blank] && [["Please Choose", ""]]) || (options[:select_all] && [["Select All", ""]]) || (options[:dont_care] && [["Don't Care", ""]]) || []
    opts += collection.select {|x| x[:user_select]}.sort {|a,b| a[:sort]<=>b[:sort]}.collect {|option| [option[:label], option[:id]]}
  end

  def options_from_jobfairs(options={})
				opts = (options[:select_all] && [["Select All", ""]]) || []
    opts += Jobfair.find(:all, :conditions => ["date < ?", Time.now]).collect { |x| ["#{x.date.to_s(:short_with_year)} -- #{x.city}", options[:for_css] ? "jobfair-#{x.id}" : x.id]}
				options_for_select(opts)
  end
  
  # This helper is used to create most (if not all) the forms in the
  # application, will handle weak model objecs, labels, optional and 
  # required markers, and form layout. 
  def error_handling_form_for(record_or_name_or_array, *args, &proc) 
    options = args.detect { |argument| argument.is_a?(Hash) } 
    if options.nil? 
      options = {:builder => ErrorHandlingFormBuilder} 
      args << options 
    end 
    options[:builder] = ErrorHandlingFormBuilder unless options.nil? 
    form_for(record_or_name_or_array, *args, &proc) 
  end 
  
  # Used along error_handling_form_for
  def error_handling_fields_for(record_or_name_or_array, *args, &proc)
    options = args.detect { |argument| argument.is_a?(Hash) } 
    if options.nil? 
      options = {:builder => ErrorHandlingFormBuilder} 
      args << options 
    end 
    options[:builder] = ErrorHandlingFormBuilder unless options.nil? 
    fields_for(record_or_name_or_array, *args, &proc) 
  end
  


  def excel_document(xml, &block)
    
    if block_given?
      
      # Write Excel's document header
      xml.instruct! :xml, :version=>"1.0", :encoding=>"UTF-8" 
	  
      xml.ss :Workbook, {'xmlns:ss' => "urn:schemas-microsoft-com:office:spreadsheet"} do
        xml.ss :Styles do
          xml.ss :Style, {'ss:ID' => 'Default', 'ss:Name' => 'Normal'} do
            xml.ss :Alignment, {'ss:Vertical' => 'Top'}
            xml.ss :Borders
            xml.ss :Font
            xml.ss :Interior
            xml.ss :NumberFormat
            xml.ss :Protection
          end

          xml.ss :Style, {'ss:ID' => 'HeadTitle'} do
            xml.ss :Alignment, {'ss:Horizontal' => 'Center'}
            xml.ss :Font, {'ss:Bold' => '1'}
          end

          xml.ss :Style, {'ss:ID' => 'DateLiteral'} do
            xml.ss :NumberFormat, {'ss:Format' => 'mm/dd/yyyy hh:mm;@'}
          end

          xml.ss :Style, {'ss:ID' => 'Text'} do
            xml.ss :Alignment, {'ss:Vertical' => 'Top', 'ss:WrapText' => '1'}
          end
        end

        xml.ss :Worksheet, 'ss:Name' => "Sheet1" do
          xml.ss :Table do
            yield block
          end
        end
      end
	  
    else
      raise ArgumentError.new("A block is expected")
    end
  end
  
  
  
  
  def models_to_excel(xml, objects, options={})
    
    # Continue only if we got a collection, it is not empty, and it contains ActiveRecord instances.
    raise ArgumentError.new("Invalid Arguments") if objects.nil? || !objects.is_a?(Array) 
    
    excel_document(xml) do

      #columns = objects[0].class.columns
      #columns = columns.select { |column| options[:include].include?(column.name) } if options[:include]
      
      columns = []
      if options[:include].to_s.blank? 
        columns = objects[0].class.columns
      else
        options[:include].each { |cname|
          columns << (objects[0].column_for_attribute(cname) || cname)
        }
      end

      # Column Headers
      xml.ss :Row do
        columns.each do |col|
          xml.ss :Cell, {'ss:StyleID' => 'HeadTitle'} do
            xml.ss :Data, "#{(col.name.titleize rescue col.titleize)}", 'ss:Type' => 'String'
          end
        end
      end
      
      # Data Dump
      for item in objects
        xml.ss :Row do
          columns.each do |col|
            col_name = (col.name rescue col)
            value = !col.respond_to?("name") ? ['String', (item.send(col_name.to_sym) rescue "")] : to_excel_format(item.attributes[col.name], col.type)
            xml.ss :Cell, !item.attributes[col_name].nil? ? {"ss:StyleID" => value[2]} : {} do
              xml.ss :Data, value[1], 'ss:Type' => value[0]
            end
          end
        end
      end
    end

  end

  
  def to_excel_format(value, ruby_type)

    return ["String", ""] if value.nil?

    return case ruby_type
    when :datetime	 then ["DateTime", value.to_formatted_s(:excel), 'DateLiteral' ]
    when :date		 then ["DateTime", value.to_formatted_s(:excel), 'DateLiteral' ]
    when :time		 then ["DateTime", value.to_formatted_s(:excel), 'DateLiteral' ]
    when :text		 then ["String",   value.to_s, 'Text' ]
    when :string	 then ["String",   value.to_s, 'Default' ]
    when :integer	 then ["Number",   value, 'Default'  ]
    when :boolean	 then ["String",   to_yes_no(value), 'Default' ]  
    else ["String", value.to_s, 'Default' ]  
    end
  end




  #
  # $Id: sanitize.rb 3 2005-04-05 12:51:14Z dwight $
  #
  # Copyright (c) 2005 Dwight Shih
  # A derived work of the Perl version:
  # Copyright (c) 2002 Brad Choate, bradchoate.com
  #
  # Permission is hereby granted, free of charge, to
  # any person obtaining a copy of this software and
  # associated documentation files (the "Software"), to
  # deal in the Software without restriction, including
  # without limitation the rights to use, copy, modify,
  # merge, publish, distribute, sublicense, and/or sell
  # copies of the Software, and to permit persons to
  # whom the Software is furnished to do so, subject to
  # the following conditions:
  #
  # The above copyright notice and this permission
  # notice shall be included in all copies or
  # substantial portions of the Software.
  #
  # THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY
  # OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
  # LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  # FITNESS FOR A PARTICULAR PURPOSE AND
  # NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
  # COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
  # OR OTHER LIABILITY, WHETHER IN AN ACTION OF
  # CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
  # OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
  # OTHER DEALINGS IN THE SOFTWARE.
  #

  def sanitize_html( html, okTags='' )
    
    # no closing tag necessary for these
    soloTags = ["br","hr"]

    # Build hash of allowed tags with allowed attributes
    tags = okTags.downcase().split(',').collect!{ |s| s.split(' ') }
    allowed = Hash.new
    tags.each do |s|
      key = s.shift
      allowed[key] = s
    end

    # Analyze all <> elements
    stack = Array.new
    result = html.gsub( /(<.*?>)/m ) do | element |
      if element =~ /\A<\/(\w+)/ then
        # </tag>
        tag = $1.downcase
        if allowed.include?(tag) && stack.include?(tag) then
          # If allowed and on the stack
          # Then pop down the stack
          top = stack.pop
          out = "</#{top}>"
          until top == tag do
            top = stack.pop
            out << "</#{top}>"
          end
          out
        end
      elsif element =~ /\A<(\w+)\s*\/>/
        # <tag />
        tag = $1.downcase
        if allowed.include?(tag) then
          "<#{tag} />"
        end
      elsif element =~ /\A<(\w+)/ then
        # <tag ...>
        tag = $1.downcase
        if allowed.include?(tag) then
          if ! soloTags.include?(tag) then
            stack.push(tag)
          end
          if allowed[tag].length == 0 then
            # no allowed attributes
            "<#{tag}>"
          else
            # allowed attributes?
            out = "<#{tag}"
            while ( $' =~ /(\w+)=("[^"]+")/ )
              attr = $1.downcase
              valu = $2
              if allowed[tag].include?(attr) then
                out << " #{attr}=#{valu}"
              end
            end
            out << ">"
          end
        end
      end
    end

    # eat up unmatched leading >
    while result.sub!(/\A([^<]*)>/m) { $1 } do end

    # eat up unmatched trailing <
    while result.sub!(/<([^>]*)\Z/m) { $1 } do end

    # clean up the stack
    if stack.length > 0 then
      result << "</#{stack.reverse.join('></')}>"
    end

    result
  end




end





  
