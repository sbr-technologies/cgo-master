# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20140503025836) do

  create_table "addresses", :force => true do |t|
    t.string   "label",            :default => "primary", :null => false
    t.integer  "addressable_id"
    t.string   "addressable_type"
    t.string   "street_address1"
    t.string   "street_address2"
    t.string   "city"
    t.string   "state"
    t.string   "zip"
    t.string   "country"
    t.string   "email"
    t.string   "phone"
    t.string   "mobile"
    t.string   "fax"
    t.string   "website"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "applicants_jobs", :force => true do |t|
    t.integer  "applicant_id"
    t.integer  "job_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "authentications", :force => true do |t|
    t.string   "provider"
    t.string   "uid"
    t.string   "access_token"
    t.string   "token_secret"
    t.string   "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "authsub_tokens", :force => true do |t|
    t.string   "token",      :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "bdrb_job_queues", :force => true do |t|
    t.binary   "args"
    t.string   "worker_name"
    t.string   "worker_method"
    t.string   "job_key"
    t.integer  "taken"
    t.integer  "finished"
    t.integer  "timeout"
    t.integer  "priority"
    t.datetime "submitted_at"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.datetime "archived_at"
    t.datetime "scheduled_at"
    t.string   "tag"
    t.string   "submitter_info"
    t.string   "runner_info"
    t.string   "worker_key"
  end

  create_table "connections", :force => true do |t|
    t.string   "provider"
    t.string   "unique_identifier"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "company"
    t.string   "headline"
    t.string   "industry"
    t.string   "location"
    t.string   "profile_url"
    t.string   "picture_url"
    t.string   "photo_file_name"
    t.string   "photo_content_type"
    t.integer  "photo_file_size"
    t.datetime "photo_updated_at"
    t.integer  "applicant_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.string   "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.string   "locked_by"
    t.datetime "failed_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "educations", :force => true do |t|
    t.string   "school_name"
    t.string   "field_of_study"
    t.string   "degree"
    t.string   "start_date"
    t.string   "end_date"
    t.text     "notes"
    t.integer  "applicant_id"
    t.string   "unique_identifier"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "employer_stats", :force => true do |t|
    t.integer  "employer_id"
    t.integer  "profile_views",  :default => 0
    t.integer  "job_views",      :default => 0
    t.integer  "banner_clicks",  :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "job_applicants", :default => 0
  end

  create_table "employers", :force => true do |t|
    t.string   "name"
    t.text     "profile"
    t.text     "comments"
    t.string   "website"
    t.boolean  "is_federal_employer"
    t.string   "referal_source"
    t.integer  "max_recruiters",                         :default => 10, :null => false
    t.integer  "number_job_postings_remaining"
    t.datetime "job_postings_expire_at"
    t.integer  "number_resume_searches_remaining"
    t.datetime "resume_search_expire_at"
    t.integer  "number_trial_resume_searches_remaining"
    t.datetime "trial_resume_search_expire_at"
    t.boolean  "is_replace_all_on_import"
    t.boolean  "is_notify_job_postings"
    t.string   "banner_option"
    t.datetime "banner_option_start_at"
    t.string   "service_option"
    t.datetime "service_option_start_at"
    t.integer  "sales_person_id"
    t.string   "track_image_url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "linkedin_handler"
    t.string   "facebook_handler"
    t.string   "ticker_symbol"
    t.string   "twitter_handler"
  end

  create_table "inbox_entries", :force => true do |t|
    t.integer  "user_id"
    t.integer  "resource_id"
    t.string   "resource_type"
    t.string   "added_by",      :default => "user"
    t.string   "status"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "job_applications", :force => true do |t|
    t.integer  "applicant_id"
    t.integer  "job_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "jobfairs", :force => true do |t|
    t.string   "category"
    t.string   "sponsor"
    t.date     "date"
    t.string   "start_time"
    t.string   "end_time"
    t.integer  "fees"
    t.string   "city"
    t.string   "location"
    t.string   "location_url"
    t.string   "external_registration_url"
    t.string   "recommended_hotel"
    t.string   "recommended_hotel_url"
    t.boolean  "security_clearance_required"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "applicant_registration_url"
    t.string   "applicant_external_registration_url"
  end

  create_table "jobs", :force => true do |t|
    t.string   "status",                              :default => "active"
    t.string   "code"
    t.string   "title",                                                     :null => false
    t.text     "description",                                               :null => false
    t.string   "input_method"
    t.text     "requirements"
    t.datetime "expires_at"
    t.string   "company_name"
    t.integer  "recruiter_id"
    t.string   "education_level"
    t.integer  "experience_required",    :limit => 1
    t.string   "payrate"
    t.string   "hr_website_url"
    t.string   "online_application_url"
    t.string   "security_clearance"
    t.string   "travel_requirements"
    t.string   "relocation_cost_paid"
    t.boolean  "show_company_profile",                :default => true,     :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "messages", :force => true do |t|
    t.string   "category"
    t.text     "body"
    t.string   "action"
    t.string   "action_url"
    t.integer  "recipient_id"
    t.string   "recipient_type"
    t.integer  "sender_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "ofccp", :force => true do |t|
    t.string   "query_string"
    t.string   "job_code"
    t.string   "job_title"
    t.string   "job_description"
    t.string   "applicant_name"
    t.date     "applicant_modification_date"
    t.string   "applicant_ethnicity"
    t.string   "applicant_gender"
    t.date     "resume_post_date"
    t.text     "resume"
    t.string   "employer_name"
    t.string   "recruiter_name"
    t.string   "recruiter_email"
    t.integer  "employer_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "ofccp_resumes", :id => false, :force => true do |t|
    t.integer "id",     :default => 0, :null => false
    t.text    "resume"
    t.text    "body"
  end

  create_table "positions", :force => true do |t|
    t.integer  "employmenable_id"
    t.string   "employmenable_type"
    t.string   "company"
    t.string   "industry"
    t.string   "title"
    t.string   "start_date"
    t.string   "end_date"
    t.text     "summary"
    t.string   "unique_identifier"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "ticker"
  end

  create_table "recruiter_stats", :force => true do |t|
    t.integer  "recruiter_id"
    t.integer  "resume_views",    :default => 0
    t.integer  "resume_searches", :default => 0
    t.integer  "login_count",     :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "registrations", :force => true do |t|
    t.string   "attendant_type"
    t.integer  "attendant_id"
    t.integer  "jobfair_id"
    t.integer  "lunches_required"
    t.text     "available_positions"
    t.boolean  "include_in_employer_directory"
    t.boolean  "outlet_required"
    t.boolean  "resume_search_access"
    t.boolean  "paid"
    t.string   "banner_company_name"
    t.string   "fax"
    t.string   "url"
    t.string   "security_clearance"
    t.boolean  "attending"
    t.boolean  "enable_search"
    t.string   "ad_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "resumes", :force => true do |t|
    t.string   "visibility",                   :default => "public", :null => false
    t.integer  "applicant_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "attached_resume_file_name"
    t.string   "attached_resume_content_type"
    t.integer  "attached_resume_file_size"
    t.datetime "attached_resume_updated_at"
    t.string   "input_method"
  end

  add_index "resumes", ["applicant_id"], :name => "applicant_id_resume", :unique => true

  create_table "schema_info", :id => false, :force => true do |t|
    t.integer "version"
  end

  create_table "seminars", :force => true do |t|
    t.string   "description"
    t.string   "duration"
    t.string   "time"
    t.integer  "jobfair_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id",                       :null => false
    t.text     "data",       :limit => 2147483647
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "users", :force => true do |t|
    t.string   "type"
    t.string   "username"
    t.string   "password"
    t.string   "status",                    :default => "active", :null => false
    t.string   "roles"
    t.string   "activation_code"
    t.datetime "activated_at"
    t.datetime "imported_at"
    t.datetime "deleted_at"
    t.datetime "last_login_at"
    t.integer  "login_count",               :default => 0,        :null => false
    t.string   "title"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "initial"
    t.string   "email"
    t.string   "source"
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "job_title"
    t.string   "ethnicity"
    t.string   "gender"
    t.datetime "availability_date"
    t.string   "branch_of_service"
    t.string   "education_level"
    t.string   "occupational_preference"
    t.string   "security_clearance"
    t.string   "type_of_applicant"
    t.string   "military_status"
    t.boolean  "us_citizen"
    t.boolean  "willing_to_relocate"
    t.integer  "employer_id"
    t.boolean  "is_display_email",          :default => true
    t.string   "twitter_handler"
    t.string   "facebook_handler"
    t.boolean  "social_login_enabled",      :default => true
    t.string   "picture_url"
    t.text     "summary"
    t.datetime "last_resume_search_date"
    t.integer  "count_resume_searches"
    t.integer  "count_resume_views"
    t.string   "linkedin_handler"
  end

end
