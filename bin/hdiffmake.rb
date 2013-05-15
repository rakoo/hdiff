require 'hdiff'

if __FILE__ == $0
  opts = Trollop::options do
    opt :file, "The source file you wish to distribute", :type => :string
    opt :output, "The output file to give to potential clients", :type => :string
    opt :stdout, "Output data to stdout instead of file", :default => false
  end

  file = opts[:file]
  abort("No file given !") unless file

  output = opts[:output] || "#{file}.hdiff" unless opts[:stdout]

  abort "File is too short" if File.size(file) <= HDiff::BLOCK_SIZE

  if opts[:stdout]
    HDiff.roll(File.open(file, File::RDONLY)) do |summary|
      puts summary
    end
  else
    File.open(output, File::CREAT|File::EXCL|File::TRUNC|File::WRONLY) do |o|
      HDiff.roll(File.open(file, File::RDONLY)) do |summary|
        o.puts summary
      end
    end
  end
end
