require 'digest/md5'

class VoxforgeOperations
	def initialize(destination, folder_name)
		@destination = destination
		@folder_name = folder_name
	end

	def unzip_folder
		`tar -xvzf "#{@destination}/#{@folder_name}.tgz" -C "#{@destination}"`
	end

	def copy_prompts
		`cat "#{@destination}/#{@folder_name}/etc/prompts-original" >> "#{@destination}/index.txt"`
	end

	def convert_wav_files
		Dir.glob("#{@destination}/#{@folder_name}/wav/*.wav") do |file|
	  	filename = File.basename(file, ".wav")
	 		`sox "#{@destination}/#{@folder_name}/wav/#{filename}.wav" "#{@destination}/#{filename}.flac"`
		end
	end

	def clean_up_folder
		`rm -R "#{@destination}/#{@folder_name}"`
		`rm "#{@destination}/#{@folder_name}.tgz"`
	end
end

class MetalangOperations
	def initialize(folder_name)
		@folder_name = folder_name
	end

	def format_prompts
		# read lines from source prompts
		a = File.readlines("#{@folder_name}/index.txt")
		# format the metalang way
		a = a.map do |line|
			next if line.length < 4
			l = line.gsub(/\p{P}(?<!')/, '').downcase # remove punctuation except apostraphes and downcase
			l.sub(" ", "<TAB>") # incase there is a blank line
		end
		# write this to index.txt
		File.open("#{@folder_name}/index.txt", 'w') do |file| 
			file.puts(a)
		end
	end
end


FOLDERS = ['voxforge-dev', 'voxforge-test', 'voxforge-train']

# set up voxforge folders
FOLDERS.each do |folder|
	`mkdir "#{folder}"`
	`touch "#{folder}/index.txt"`
end

# sort archives into respective folders
FOLDERS.each do |folder|
	Dir.glob("./*.tgz") do |file|
		file_name = File.basename(file)
		speaker_id = file_name.partition('-').first
		allocation = (Digest::MD5.hexdigest(speaker_id).to_i(16)).digits.first
		if (0..7).include? allocation
			`mv "#{file_name}" voxforge-train`
		elsif [8].include? allocation
			`mv "#{file_name}" voxforge-dev`
		else
			`mv "#{file_name}" voxforge-test`
		end
	end
end

# process each of the folders
FOLDERS.each do |folder|
	m = MetalangOperations.new(folder)
	Dir.glob("#{folder}/*.tgz") do |file|
		file_name = File.basename(file, ".tgz")
		f = VoxforgeOperations.new(folder, file_name)
		f.unzip_folder
		f.copy_prompts
		f.convert_wav_files
		f.clean_up_folder
	end
	m.format_prompts
end
