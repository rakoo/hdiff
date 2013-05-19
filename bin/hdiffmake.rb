require 'digest/sha1'
require 'trollop'
require 'hdiff'

opts = Trollop::options do
  opt :file, "The source file you wish to distribute", :type => :string
  opt :output, "The output file to give to potential clients", :type => :string
  opt :stdout, "Output to stdout instead of file", :default => false
end

file = opts[:file]
abort("No file given !") unless file

output = File.open(opts[:output] || "#{file}.hdiff", File::APPEND|File::CREAT|File::WRONLY) unless opts[:stdout]

HDiff.roll(File.open(file)) do |summary|
  line = summary.join('-')
  if opts[:stdout]
    puts line
  else
    output << line + "\r\n"
  end
end
