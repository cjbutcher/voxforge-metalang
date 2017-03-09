class FileFunctions

	def initialize(folder_name)
		@folder_name = folder_name
	end

	def unzip_folder
		`tar -xvzf "#{@folder_name}.tgz"`
	end

	def create_index_file(file_name='index.txt')
		`touch "#{@folder_name}/#{file_name}"`
	end

	def copy_prompts(src='etc/prompts-original', destination='index.txt')
		`cat "#{@folder_name}/#{src}" >> "#{@folder_name}/#{destination}"`
	end

	def format_prompts(index_file_name='index.txt')
		# read lines from source prompts
		a = File.readlines("#{@folder_name}/#{index_file_name}")
		# remove punctuation except apostaphes and downcase
		a = a.map{ |line| line.gsub(/\p{P}(?<!')/, '').downcase }
		# format the metalang way
		a = a.map do |line|
			if line.length > 4 # incase there is a blank line
				line.insert(5, '.flac').sub(" ", "\t")
			end
		end
		# write this to index.txt
		File.open("#{@folder_name}/#{index_file_name}", 'w') do |file| 
			file.puts(a)
		end
	end

	def convert_wav_files(src='wav')
		Dir.glob("#{@folder_name}/#{src}/*.wav") do |file|
	  	filename = File.basename(file, ".wav")
	 		`sox "#{@folder_name}/#{src}/#{filename}.wav" "#{@folder_name}/#{filename}.flac"`
		end
	end

	def clean_up_files
		`rm -R "#{@folder_name}/etc"`
		`rm -R "#{@folder_name}/wav"`
		`rm "#{@folder_name}/LICENSE"`
	end

end

Dir.glob('./*.tgz') do |file|
	folder_name = File.basename(file, ".tgz")
	f = FileFunctions.new(folder_name)

	f.unzip_folder
	f.create_index_file
	f.copy_prompts
	f.format_prompts
	f.convert_wav_files
	f.clean_up_files
end