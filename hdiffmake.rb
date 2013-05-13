require 'digest/sha1'
require 'trollop'

BLOCK_SIZE = 1024
BOUNDARY = 1023

class RollingChecksum

  MODULO = 1 << 32

  attr_reader :found_boundary

  def initialize first_block

    @r1 = first_block.each_byte.inject do |sum, byte|
      sum += byte
    end % MODULO

    # byte_index is an array of [byte, index]
    @r2 = first_block.each_byte.with_index.inject(0) do |sum, byte_index|
      sum += (first_block.bytesize - byte_index[1]) * byte_index[0]
    end % MODULO

    @buffer = first_block.bytes

    @found_boundary = rolldigest & BOUNDARY == BOUNDARY

    @digest = Digest::SHA1.new
    @digest << first_block
  end

  def eat next_byte
    @buffer << next_byte

    out = @buffer[-(1 + BLOCK_SIZE)]

    @r1 += next_byte - out
    @r1 %= MODULO

    @r2 += @r1 - BLOCK_SIZE * out
    @r2 %= MODULO

    @found_boundary = rolldigest & BOUNDARY == BOUNDARY
  end

  # Called when found boundary
  def summary
    "#{hexdigest} #{@buffer.size}"
  end

  private

  def hexdigest
    @digest.hexdigest
  end

  def rolldigest
    @r1 + MODULO * @r2
  end
end

def roll_file filename
  File.open(filename, File::RDONLY) do |f|

    roll = nil
    until f.eof?
      if roll.nil?
        block = f.read(BLOCK_SIZE)
        roll = RollingChecksum.new block
        old_block = block
      else

        if roll.found_boundary
          yield roll.summary

          block = f.read(BLOCK_SIZE)
          if block.size == BLOCK_SIZE
            roll = RollingChecksum.new block
            old_block = block
          else
            yield "#{Digest::SHA1.hexdigest(block)} #{block.bytesize}"
          end
        else
          roll.eat f.read(1).unpack('C').first
        end

      end

    end

  end
end

if __FILE__ == $0
  opts = Trollop::options do
    opt :file, "The source file you wish to distribute", :type => :string
    opt :output, "The output file to give to potential clients", :type => :string
  end

  file = opts[:file]
  abort("No file given !") unless file

  output = opts[:output] || "#{file}.hdiff"

  abort "File is too short" if File.size(file) <= BLOCK_SIZE

  roll_file file do |summary|
    puts summary
  end
#  File.open(output, File::CREAT|File::EXCL|File::TRUNC|File::WRONLY) do |o|
#    roll_file file do |summary|
#      o.puts summary
#    end
#  end
end
