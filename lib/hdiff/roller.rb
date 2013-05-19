require 'digest/sha1'
require 'trollop'

module HDiff
  BLOCK_SIZE = 128

  class RollingChecksum

    BOUNDARY = 1023

    attr_reader :found_boundary

    def initialize first_block

      @r = first_block.each_byte.inject do |sum, byte|
        sum += byte
      end & BOUNDARY

      @buffer = first_block.bytes

      determine_found!

      @digest = Digest::SHA1.new
      @digest << first_block
    end

    def eat next_byte
      next_byte_int = next_byte.unpack('C').first
      @buffer << next_byte_int
      @digest << next_byte

      out = @buffer[-(1 + BLOCK_SIZE)]

      @r += next_byte_int - out
      @r &= BOUNDARY

      determine_found!
    end

    # Called when found boundary
    def summary
      [hexdigest, @buffer.size]
    end

    private

    def determine_found!
      @found_boundary = @r == BOUNDARY
    end

    def hexdigest
      @digest.hexdigest
    end

  end

  def self.roll io

    total_sum = Digest::SHA1.new

    block = io.read(BLOCK_SIZE)
    roll = RollingChecksum.new block
    old_block = block

    total_sum << block

    until io.eof?

      if roll.found_boundary
        yield roll.summary

        block = io.read(BLOCK_SIZE)
        total_sum << block
        if block.size == BLOCK_SIZE
          roll = RollingChecksum.new block
          old_block = block
        else
          yield [Digest::SHA1.hexdigest(block), block.bytesize]
        end
      else
        next_byte = io.read(1)
        total_sum << next_byte
        roll.eat next_byte
      end


    end

    yield [total_sum.hexdigest, io.size]
  end

end
