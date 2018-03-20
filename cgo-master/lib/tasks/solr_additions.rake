namespace :solr do

  task :optimize => :environment do
    Sunspot.optimize()
  end
  
  task :reindex_resumes => :environment do

     cutoff_date = Date.new(2010, 1, 1)
     batch_size = 0

     # Clear Index First
     puts "Clearing Resume's index ..."
     ActsAsSolr::Post.execute(Solr::Request::Delete.new(:query => "type_s:Resume")) 
     ActsAsSolr::Post.execute(Solr::Request::Commit.new)

     puts "Reindexing ... "
     Resume.find(:all, :conditions => ["(created_at > :cutoff_date OR updated_at > :cutoff_date)", {:cutoff_date => cutoff_date.to_s(:db)}]).each do |res|

       unless(res.applicant.to_s.blank? || res.applicant.status != 'active') 
         begin
           res.solr_save
           puts "Saved resume #{res.id}"
         rescue Exception => e
           puts "Unable to save resume #{res.id} to Solr: #{e.message}"
         end
       end

     end
     puts "Done."

  end


  task :reindex_jobs => :environment do

      batch_size = 500
    
     # Clear Index First
     puts "Clearing Jobs's index ..."
     ActsAsSolr::Post.execute(Solr::Request::Delete.new(:query => "type_s:Job")) 
     ActsAsSolr::Post.execute(Solr::Request::Commit.new)

     puts "Reindexing ... "
     Job.rebuild_solr_index(batch_size) do |model, options|
        model.find(:all, options.merge({:conditions => ["status='active' AND expires_at > #{Date.new.to_s(:db)}"]}) )
     end
     puts "Done."

  end



  desc %{Reindexes data for all acts_as_solr models. Clears index first to get rid of orphaned records and optimizes index afterwards. RAILS_ENV=your_env to set environment. ONLY=book,person,magazine to only reindex those models; EXCEPT=book,magazine to exclude those models. START_SERVER=true to solr:start before and solr:stop after. BATCH=123 to post/commit in batches of that size: default is 300. CLEAR=false to not clear the index first; OPTIMIZE=false to not optimize the index afterwards.}
  task :reindex => :environment do
    
    includes = env_array_to_constants('ONLY')
    if includes.empty?
      includes = Dir.glob("#{Rails.root}/app/models/*.rb").map { |path| File.basename(path, ".rb").camelize.constantize }
    end
    excludes = env_array_to_constants('EXCEPT')
    includes -= excludes
    
    optimize     = env_to_bool('OPTIMIZE',     true)
    start_server = env_to_bool('START_SERVER', false)
    clear_first   = env_to_bool('CLEAR',       true)
    batch_size   = ENV['BATCH'].to_i.nonzero? || 300

    if start_server
      puts "Starting Solr server..."
      Rake::Task["solr:start"].invoke 
    end
    
    # Disable solr_optimize
    module ActsAsSolr::CommonMethods
      def blank() end
      alias_method :deferred_solr_optimize, :solr_optimize
      alias_method :solr_optimize, :blank
    end
    
    models = includes.select { |m| m.respond_to?(:rebuild_solr_index) }    
    models.each do |model|
  
      if clear_first
        puts "Clearing index for #{model}..."
        ActsAsSolr::Post.execute(Solr::Request::Delete.new(:query => "type_t:#{model}")) 
        ActsAsSolr::Post.execute(Solr::Request::Commit.new)
      end
      
      puts "Rebuilding index for #{model}..."
      model.rebuild_solr_index(batch_size)

    end 

    if models.empty?
      puts "There were no models to reindex."
    elsif optimize
      puts "Optimizing..."
      models.last.deferred_solr_optimize
    end

    if start_server
      puts "Shutting down Solr server..."
      Rake::Task["solr:stop"].invoke 
    end
    
  end
  
  def env_array_to_constants(env)
    env = ENV[env] || ''
    env.split(/\s*,\s*/).map { |m| m.singularize.camelize.constantize }.uniq
  end
  
  def env_to_bool(env, default)
    env = ENV[env] || ''
    case env
      when /^true$/i  then true
      when /^false$/i then false
      else default
    end
  end

end

