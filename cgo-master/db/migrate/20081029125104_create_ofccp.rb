class CreateOfccp < ActiveRecord::Migration
  def self.up
    create_table :ofccp do |t|
      t.string	:query_string
      t.string	:job_code
      t.string	:job_title
      t.string	:job_description
      t.string	:applicant_name
      t.date		:applicant_modification_date
      t.string	:applicant_name
      t.string	:applicant_ethnicity
      t.string	:applicant_gender
      t.date		:resume_post_date
			t.text		:resume
      t.string	:employer_name
      t.string	:recruiter_name
      t.string	:recruiter_email

			t.integer :employer_id

      t.timestamps
    end
  end

  def self.down
    drop_table :ofccps
  end
end
