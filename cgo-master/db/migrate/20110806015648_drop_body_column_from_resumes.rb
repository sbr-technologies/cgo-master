class DropBodyColumnFromResumes < ActiveRecord::Migration
  def self.up
    remove_column :resumes, :body
    remove_column :resumes, :summary
  end

  def self.down
    add_column :resumes, :body, :text
    add_column :resumes, :summary, :text
  end
end
