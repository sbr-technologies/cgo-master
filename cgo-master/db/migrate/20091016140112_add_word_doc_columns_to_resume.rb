class AddWordDocColumnsToResume < ActiveRecord::Migration
  def self.up
						add_column :resumes, :attached_resume_file_name,    :string
      add_column :resumes, :attached_resume_content_type, :string
      add_column :resumes, :attached_resume_file_size,    :integer
      add_column :resumes, :attached_resume_updated_at,   :datetime

						add_column :resumes, :input_method,    :string
  end

  def self.down
						remove_column :resumes, :attached_resume_file_name
      remove_column :resumes, :attached_resume_content_type
      remove_column :resumes, :attached_resume_file_size
      remove_column :resumes, :attached_resume_updated_at

      remove_column :resumes, :input_method
  end
end
