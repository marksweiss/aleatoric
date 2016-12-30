require_relative 'test_global'
$LOAD_PATH << psub("../lib")

require 'meter'
require 'minitest/autorun'
# require 'ruby-debug' ; Debugger.start

module Aleatoric

class MockNote
  attr_accessor :duration, :start
  
  def initialize()
    @duration = 0.0
    @start = 0.0
  end
  
  def duration(val=nil)
    @duration = val if val != nil
    @duration
  end
  
  def start(val=nil)
    @start = val if val != nil
    @start
  end
end

class Meter_Test < MiniTest::Unit::TestCase
  # def setup
  # end
  # def teardown
  # end

  def test__quantize
    puts "test__quantize ENTERED"

    meter = Meter.new(quantize=true, beats_per_measure=4, beat_length=D_4)
    
    note1 = MockNote.new
    note1.duration = D_4
    note1.start = 0.0
    note2 = MockNote.new
    note2.duration = D_4
    note2.start = D_4
    
    expected_note1 = MockNote.new
    expected_note1.start(0.0)
    expected_note1.duration(D_2)
    expected_note2 = MockNote.new
    expected_note2.start(D_2)
    expected_note2.duration(D_2)

    actual = meter.quantize([note1, note2])    
    expected = [expected_note1, expected_note2]
    assert(expected[0].start == actual[0].start && expected[1].start == actual[1].start && 
           expected[0].duration == actual[0].duration && expected[1].duration == actual[1].duration)
  
    puts "test__quantize COMPLETED"
  end
  
end

end
