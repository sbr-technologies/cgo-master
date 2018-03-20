# To change this template, choose Tools | Templates
# and open the template in the editor.
require File.join(File.dirname(__FILE__) + "/../bdrb_test_helper")
require "job_import_worker"

  
#    1) Check that the job upload process triggers at the correct time
#    
#    2) Check that aborting a file due to parse errors does not abort the
#    rest of the files.
#    
#    3) Check that files are correctly moved to ftp_errors or ftp_archives
#    
#    4) Fix Job model: The current strategy to delete old jobs is to blank
#    recruiter_id. This was forbidden through validation.
#    
#    5) Fix for Solr Job Search: Now a new observer will add an "inactive"
#    flag when recruiter_id is set to blank. Solr will use this flag to
#    correctly return only active jobs.
# 
#
class JobImportWorkerTest < ActiveSupport::TestCase

  context "When job_import_worker starts it should find all XML files for upload" do

  end

end
