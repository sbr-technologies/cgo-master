namespace :sunspot do 

  desc "Reindex jobs to Solr selecting only 'active' non-expired jobs" 
  task :reindex_jobs => :environment do 
    batch_size = 500
    puts "Indexing Jobs, batch size: #{batch_size}"

    puts "Clearing Jobs from Index ..."
    Job.remove_all_from_index!

    Job.find_in_batches(:batch_size => batch_size, :conditions => "expires_at > CURDATE() AND status = 'active'") do |jobs|
      puts "Saving jobs [#{jobs[0].id} .. #{jobs[jobs.length-1].id}]"
      begin 
        Sunspot.index(jobs)
      rescue Exception => e
        puts "Error !!! Saving Jobs: [#{jobs[0].id} ... #{jobs[jobs.length].id}]: #{e}"
      end
    end

    puts "Done!"
  end

  desc "Reindex Applicants (and Resumes) selecting only 'active' records"
  task :reindex_applicants => :environment do 
    batch_size = 250
    puts "Indexing Applicants, batch size: #{batch_size}"

    puts "Clearing Applicants from index ..."
    Applicant.remove_all_from_index!

    Applicant.find_in_batches(:batch_size => batch_size, :conditions => "status = 'active'") do |applicants|
      puts "Saving Applicants [#{applicants[0].id} .. #{applicants[applicants.length-1].id}]"
      begin
        Sunspot.index(applicants)
      rescue Exception => e
        puts "Error!! saving #{applicants[0].id} .. #{applicants[applicants.length-1].id}: #{e}"
      end
    end

  end

end
