require 'net/http'
require 'rubygems'
require 'zip/zip'

SERVER_URL='xmlfeed.jobcentral.com'
RESOURCE_NAME = '/members.zip'
FTP_UPLOAD_DIR = "/home/joblistings/ftp"
TEMP_DIR = "/tmp"

TODAY_MMDDYYYY = Time.now.strftime("%d%m%Y")
ZIP_FILENAME = TEMP_DIR + "/jobcentral_" + TODAY_MMDDYYYY + ".zip"


http = Net::HTTP.start(SERVER_URL)

puts "Downloading: #{SERVER_URL}#{RESOURCE_NAME}"

File.open(ZIP_FILENAME, 'w') { |f|
	http.get(RESOURCE_NAME) do |str|
		f.write str
	end
}

puts "Extracting Job Files"
Zip::ZipInputStream::open(ZIP_FILENAME) { |io|
	while(entry = io.get_next_entry) 
		if( ["amex.xml", "dcp.xml", "ups.xml", "bearingpoint.xml", "exelon.xml",
             "bnsf.xml", "mantech.xml", "ceridian.xml",
             "l3other.xml","aramark.xml",
             "aramarkhourly.xml","tiaa.xml","ihg.xml"].include?(entry.name) )

			  puts "Extracting #{entry.name}"
			  entry.extract("#{FTP_UPLOAD_DIR}/jobcentral_#{TODAY_MMDDYYYY}_#{entry.name}")
		end
	end
}

File.delete(ZIP_FILENAME)
