require File.expand_path('../boot', __FILE__)

require 'rails/all'

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env) if defined?(Bundler)

module Cgray
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)
    config.autoload_paths += %W(#{config.root}/lib)

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer
    config.active_record.observers = :user_observer, :employer_observer, :registration_observer, 
								     :job_application_observer, :job_observer, :inbox_entry_observer, 
                                     :delayed_job_observer, :resume_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # JavaScript files you want as :defaults (application.js is always included).
    # config.action_view.javascript_expansions[:defaults] = %w(jquery rails)

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]


    require 'will_paginate'

    #TODO: Replace the explicit extension by a call to "array_extensions"
    #require 'array_extensions' # Depends on will_paginate
    Array.class_eval do
      def paginate(page = 1, per_page = 15)
        WillPaginate::Collection.create(page, per_page, size) do |pager|
          pager.replace self[pager.offset, pager.per_page].to_a
        end
      end
    end

    ActionView::Base.field_error_proc = Proc.new { |html_tag, instance| html_tag }

    Time::DATE_FORMATS[:default] = '%Y-%m-%d %H:%M:%S'
    Time::DATE_FORMATS[:excel] = '%Y-%m-%dT%H:%M:%S.000'
    Time::DATE_FORMATS[:tstamp] = '%Y%m%d%H%M%S'
    Time::DATE_FORMATS[:mmddyyyy] = '%m/%d/%Y'
    Time::DATE_FORMATS[:mm_dd_yyyy] = '%m_%d_%Y'
    Time::DATE_FORMATS[:yyyy_mm_dd] = '%Y-%m-%d'
    Time::DATE_FORMATS[:hh_mm] = '%H:%M'
    Time::DATE_FORMATS[:human] = '%B %d, %Y %H:%M'
        
    Date::DATE_FORMATS[:excel] = '%Y-%m-%dT%H:%M:%S.000'
    Date::DATE_FORMATS[:default] = '%Y-%m-%d'
    Date::DATE_FORMATS[:short_with_year] = '%b %d, %y'
    Date::DATE_FORMATS[:mmddyyyy] = '%m/%d/%Y'
    Date::DATE_FORMATS[:yyyymmdd] = '%Y%m%d'
    Date::DATE_FORMATS[:human] = '%b %d, %Y'
    Date::DATE_FORMATS[:human_short] = '%b %d'
    Date::DATE_FORMATS[:human_long] = '%B %d, %Y'
    Date::DATE_FORMATS[:human_no_year] = '%B %-d'
    Date::DATE_FORMATS[:hh_mm] = '%H:%M'
    
#    config.middleware.use ExceptionNotifier,
#        :email_prefix => "[Exception Notifier] ",
#        :sender_address => %{"exception notifier" <do_not_reply@example.com>},
#        :exception_recipients => %w(fkattan@gmail.com, carl@corporategray.com)

    Paperclip::Railtie.insert
    Paperclip.options[:swallow_stderr] = false 
    Paperclip.interpolates(:content_type_extension) do |attachment, style_name|
      style_name.to_s == "original" ? File.extname(attachment.original_filename).gsub(/^\.+/, "") : style_name.to_s 
    end
        
  end
end
