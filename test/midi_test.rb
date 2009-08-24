$LOAD_PATH << "..\\lib"
require 'midi'
require 'test/unit'
require 'rubygems'
require 'ruby-debug' ; Debugger.start

class Midi_Test < Test::Unit::TestCase
  # def setup
  # end
  # def teardown
  # end

  def test__filemidi_initialize
    puts "test__filemidi_initialize ENTERED"

    midi = FileMIDI.new

    assert(midi != nil)
  
    puts "test__filemidi_initialize COMPLETED"
  end
  
end