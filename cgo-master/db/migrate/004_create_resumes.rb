class CreateResumes < ActiveRecord::Migration
  def self.up
    create_table :resumes do |t|
      
      t.text  :body
      t.text  :summary
      t.string :visibility, :null => false, :default => "public"
      
      t.integer :applicant_id  

      t.timestamps
    end
  end

  def self.down
    drop_table :resumes
  end
end
