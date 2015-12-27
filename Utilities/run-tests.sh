#!/usr/bin/env ruby

# Config

TEST_DIR = "Tests"
DEBUG = true
PRIMARY_TARGET_NAME = "Swerver"
SKIP_DIRS = [ ]
VERBOSE = ARGV[0] == "-v"

# Private

PWD = `pwd`.strip
BUILD_DIR = "#{PWD}/.build/#{DEBUG ? "debug" : "release"}/"

def vputs(str)
	puts(str) if VERBOSE
end

def run_tests_for_dir(dir)
	import_paths = []
	
	packages = "#{PWD + "/Packages"}"
	Dir.chdir(packages) do
		Dir.glob("*").each do |p|
			if !File.directory?(p) || p[0] == "." then
				next
			end
		
			import_paths << "#{packages}/#{p}"
		end
	end

	Dir.chdir(dir) do
		swift_files = Dir.glob("*.swift")
		out_name = "./#{dir.split("/").last.downcase}"
		imports = import_paths.map { |ip| "-I #{ip}" }.join(" ")
		compile_str = "swiftc #{swift_files.join(" ")} -I /home/jparishy/code/swerver/.build/debug/ #{imports} -I #{BUILD_DIR} -L #{BUILD_DIR} -l:#{PRIMARY_TARGET_NAME}.a -lswiftGlibc -lFoundation -o #{out_name}"
		vputs "\t> #{compile_str}"
		puts `#{compile_str}`
		if $?.exitstatus != 0
			puts "Failed to compile tests. Bailing."
			exit 1
		end
		
		puts `./#{out_name}`
		
		if $?.exitstatus != 0
			puts "#{dir} failed."
			exit 1
		end		

		puts `rm ./#{out_name}`
	end
end

`swift build #{VERBOSE ? "-v" : ""}`

if $?.exitstatus != 0
	puts "Build failed. Bailing."
	exit 1
end

Dir.glob("#{TEST_DIR}/*").each do |entry|

	full_path = File.join(PWD, entry)
	if !File.directory?(full_path) then
		next
	end

	if SKIP_DIRS.include?(entry.split("/").last) then
		puts "Skipping #{entry}\n\n"
		next
	end
	
	puts "Running tests in #{entry}"
	
	run_tests_for_dir(entry)
	print "\n"
end

puts "Finished."
exit 0
