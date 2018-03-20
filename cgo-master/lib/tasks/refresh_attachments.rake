namespace :attachments do

  task :refresh=> :environment do

    Resume.find(:all).each do |resume| 

      file = nil
      ["doc", "docx", "html", "text"] .each do |ext|
          file = File.open("paperclip/attached_resumes/#{resume.id}_resume.#{ext}", "rb") rescue next
          break
      end 

      puts "Processing resume:#{resume.id} with file: #{file.nil? ? 'none' : file.path}"

      unless file.nil?
        begin
          resume.attached_resume = file 
          resume.save
        rescue Exception => e
          puts "Could not Save Resume:#{resume.id}, error: #{e.to_s}"
        end
      end

    end

  end

end
