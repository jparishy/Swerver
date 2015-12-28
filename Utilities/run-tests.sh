#!/usr/bin/env ruby

# Config

TEST_DIR = "Tests"
DEBUG = true
PRIMARY_TARGET_NAME = "Swerver"
DEPENDENCIES = [ "CryptoSwift" ]
SKIP_DIRS = [ ]
VERBOSE = ARGV[0] == "-v"

# Private

require 'open3'

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
		out_name = "#{dir.split("/").last.downcase}"
		imports = import_paths.map { |ip| "-I #{ip}" }.join(" ")
		linked_libs = DEPENDENCIES.map { |d| "-l:#{d}.a" }.join(" ")

		compile_str = "swiftc #{swift_files.join(" ")} -I /home/jparishy/code/swerver/.build/debug/ #{imports} -I #{BUILD_DIR} -L #{BUILD_DIR} -l:#{PRIMARY_TARGET_NAME}.a #{linked_libs} -lswiftGlibc -lFoundation -o ./#{out_name}"
		
		vputs "\t> #{compile_str}"
		puts `#{compile_str}`

		if $?.exitstatus != 0
			puts "Failed to compile tests. Bailing."
			exit 1
		end
		
		stdout, stderr, status = Open3.capture3("./#{out_name}")

		puts stdout if stdout.length > 0
		puts stderr if stderr.length > 0

		if status != 0
			puts "#{dir} failed: #{status}. Leaving test executable `./#{dir}/#{out_name}` for reproducing purposes."
			exit 1
		else
			puts `rm ./#{out_name}`
		end
	end
end

`swift build #{VERBOSE ? "-v" : ""}`

if $?.exitstatus != 0
	puts "Build failed. Bailing."
	exit 1
end

if ARGV[0] != nil && ARGV[0] != "-v" && ARGV[0].length > 0
	single_test = "#{TEST_DIR}/#{ARGV[0]}"
	if File.directory?(File.join(PWD, single_test)) == false
		puts "Single test directory #{single_test} does not exist."
		exit 1
	end

	puts "Running single tests in directory: #{single_test}"
	run_tests_for_dir(single_test)
	print "\n"
else 
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
end

puts "Finished."
exit 0
