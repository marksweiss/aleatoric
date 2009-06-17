$LOAD_PATH << "..\\lib"
require 'composer'
require 'composer_lang_test'
require 'meter_test'
require 'set'
require 'thread'
require 'rubygems'
require 'ruby-debug' ; Debugger.start

include Aleatoric

# Functional tests for composer require a custom testing framework because the code runs from 
#  load(), which is its own process and from which no state is returned.  So conventional test/unit
#  approach won't work, because you can't just call functions and get return values.  So this
#  source file handles this by creating a file I/O based testing framework.  Test scripts are created
#  and run, the output is stowed in files, which are then read back into memory here to test
#  actual results against expected.

class AleatoricTestException < Exception; end

class AleatoricTest
  @@all_pass = true
  @@failed_tests = Set.new []
  
  def AleatoricTest.all_pass?
    @@all_pass
  end
  
  def AleatoricTest.failed_tests
    @@failed_tests
  end

  def initialize(test_name, throw_on_failure=false)
    @test_name = test_name
    @throw_on_failure = throw_on_failure
    @s = "PASS: #{@test_name}"
  end
  
  def assert(assertion)
    @pass = (assertion == true)
    if not @pass
      @@all_pass = false
      @@failed_tests << @test_name
      if @throw_on_failure
        raise AleatoricTestException, "FAILURE: #{@test_name}"
      else
        @s = "FAILURE: #{@test_name}"
      end
    end
    @pass
  end

  def to_s
    @s 
  end

end

def preprocess_script(script)
  File.open("test_preprocess.altc", "w") {|f| script.each {|line| f << line}}
  ComposerAST.new.preprocess_script("test_preprocess.altc").to_s
end

@write_mutex = Mutex.new
def write_test_script(script, lite_syntax=false)
  # TODO Include this in composition.rb preprocessing of load() call
  # Read each line of script, and make necessary modifications to transform "almost Ruby" 
  #  input into legal Ruby
  script = preprocess_script(script) if lite_syntax    
  # NOTE !!!!!!!!!!!!!!!!!!!!!!!
  # We needed a mutex here to guard from multiple method calls writing to the same file
  #  even though each call comes from a separate function, which should complete
  #  operation before the next is called, and each call makes a single call to this function,
  #  and the docs promise that this syntax *closes the file* on block exit, and that block exit
  #  is clearly within the stack scope of the calling function.  i.e. - the Ruby File IO library
  #  has race condition related to not releasing file handles at block exit and can't be trusted 
  #  even in a single-threaded program properly scoping all calls, at least on 1.8.6 on Windows
  @write_mutex.lock
  File.open("test.altc", "w") do |f|
    f << "module Aleatoric\n\n"  
    script.each do |line|
      f << line
    end    
    f << "\n\nend\n"
  end 
  @write_mutex.unlock
end

def run_test_script
  load "test.altc"
end

def read_test_results
  results = File.readlines("composer_test_results.txt")
  results.map! {|r| r = r.strip}
end

def test_runner(test_name, throw_on_failure, script, lite_syntax=false)
  tester = AleatoricTest.new(test_name, throw_on_failure)
  write_test_script(script, lite_syntax)
  run_test_script
  results = read_test_results
  return tester, results
end

##################### TESTS ########################

# TODO Add support for hash/rails style of passing args as hash

def test__stmt_note_with_name
  throw_on_failure = false
  test_name = "test__stmt_note_with_name"
  
  script = 
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__stmt_note_with_name

note "note 1" do
  instrument  1 
  start       0.0 
  duration    0.5
  amplitude   1000
  pitch       7.01
  func_table  1
end
  
# FOR TESTING ONLY
dump_last_note
}
  tester, results = test_runner(test_name, throw_on_failure, script)
  actual = results.first
  expected = "i 1 0.00000 0.50000 1000 7.01000 1 ; note 1"  
  tester.assert(expected == actual)
  puts tester.to_s  
end

def test__stmt_note_without_name
  throw_on_failure = false
  test_name = "test__stmt_note_without_name"
  
  script = 
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__stmt_note_without_name

note do
  instrument  1 
  start       0.0 
  duration    0.5
  amplitude   1000
  pitch       7.01
  func_table  1
end
  
# FOR TESTING ONLY
dump_last_note
}
  tester, results = test_runner(test_name, throw_on_failure, script)
  actual = results.first
  expected = 'i 1 0.00000 0.50000 1000 7.01000 1 ;'  
  tester.assert(expected == actual)
  puts tester.to_s  
end

def test__stmt_note_alt_syntax
  throw_on_failure = false
  test_name = "test__stmt_note_alt_syntax"
  
  script = 
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__stmt_note_alt_syntax

note do instrument 1; start 0.0; duration 0.5; amplitude 1000; pitch 7.01; func_table 1 end
  
# FOR TESTING ONLY
dump_last_note
}
  tester, results = test_runner(test_name, throw_on_failure, script)
  actual = results.first
  expected = 'i 1 0.00000 0.50000 1000 7.01000 1 ;'  
  tester.assert(expected == actual)
  puts tester.to_s  
end

def test__phrase
  throw_on_failure = false
  test_name = "test__phrase"
  script = 
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__phrase

phrase "Intro Phrase" do

  note "1" do
    instrument  1 
    start       0.0 
    duration    0.5
    amplitude   1000
    pitch       7.01
    func_table  1
  end
  
  note "2" do
    instrument  1
    start       1.0 
    duration    1.0
    amplitude   1100
    pitch       7.02
    func_table  1
  end

end

# FOR TESTING ONLY    
dump_last_phrase
}
  tester, results = test_runner(test_name, throw_on_failure, script)
  actual = results
  expected0 = 'i 1 0.00000 0.50000 1000 7.01000 1 ; 1'
  expected1 = 'i 1 1.00000 1.00000 1100 7.02000 1 ; 2'
  tester.assert(expected0 == actual[0])
  tester.assert(expected1 == actual[1])
  puts tester.to_s  
end

def test__phrase_alt_syntax
  throw_on_failure = false
  test_name = "test__phrase_alt_syntax"
  script = 
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__phrase_alt_syntax

phrase "Stuff in the Middle" do
  note "3" do instrument 1; start 2.0; duration 0.5; amplitude 1000; pitch 7.03; func_table 1 end
  note "4" do instrument 1; start 3.0; duration 0.5; amplitude 1000; pitch 7.04; func_table 1 end
end

# FOR TESTING ONLY    
dump_last_phrase
}
  tester, results = test_runner(test_name, throw_on_failure, script)
  actual = results
  expected0 = 'i 1 2.00000 0.50000 1000 7.03000 1 ; 3'
  expected1 = 'i 1 3.00000 0.50000 1000 7.04000 1 ; 4'
  tester.assert(expected0 == actual[0])
  tester.assert(expected1 == actual[1])
  puts tester.to_s  
end
  
def test__section
  throw_on_failure = false
  test_name = "test__section"
  script = 
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__section

section "Intro Section" do

phrase "Intro Phrase" do

  note "1" do
    instrument  1 
    start       0.0 
    duration    0.5
    amplitude   1000
    pitch       7.01
    func_table  1
  end
  
  note "2" do
    instrument  1
    start       1.0 
    duration    1.0
    amplitude   1100
    pitch       7.02
    func_table  1
  end

end

end

# FOR TESTING ONLY    
dump_last_section
}
  tester, results = test_runner(test_name, throw_on_failure, script)
  actual = results
  expected0 = 'i 1 0.00000 0.50000 1000 7.01000 1 ; 1'
  expected1 = 'i 1 1.00000 1.00000 1100 7.02000 1 ; 2'
  tester.assert(expected0 == actual[0])
  tester.assert(expected1 == actual[1])
  puts tester.to_s  
end

def test__repeat_index
  throw_on_failure = false
  test_name = "test__repeat_index"
  script = 
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__repeat_index

phrase "Loop" do
  repeat 2 do |index|
    note do
      instrument 1
      start       1.0 * index
      duration    0.2
      amplitude   1000 + (100 * index) 
      pitch       7.02
      func_table  1
    end
  end
end

# FOR TESTING ONLY    
dump_last_phrase
}
  tester, results = test_runner(test_name, throw_on_failure, script)
  actual = results
  expected0 = 'i 1 1.00000 0.20000 1100 7.02000 1 ;'
  expected1 = 'i 1 2.00000 0.20000 1200 7.02000 1 ;'
  tester.assert(expected0 == actual[0])
  tester.assert(expected1 == actual[1])
  puts tester.to_s  
end

def test__write_format_sections_phrases
  throw_on_failure = false
  test_name = "test__write_format_sections_phrases"
  script = 
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__write_format_sections_phrases

section "Intro Section" do
  phrase "Intro Phrase" do
    note "1" do
      instrument  1 
      start       0.0 
      duration    0.5
      amplitude   1000
      pitch       7.01
      func_table  1
    end
    
    note "2" do
      instrument  1
      start       1.0 
      duration    1.0
      amplitude   1100
      pitch       7.02
      func_table  1
    end
  end
end

phrase "Coda" do
  note "3" do
    instrument  1 
    start       0.0 
    duration    0.5
    amplitude   1000
    pitch       7.01
    func_table  1
  end
  
  note "4" do
    instrument  1
    start       1.0 
    duration    1.0
    amplitude   1100
    pitch       7.02
    func_table  1
  end
end

phrase "Loop" do
  repeat 2 do |index|
    note do
      instrument 1
      start       1.0 * index
      duration    0.2
      amplitude   1000 + (100 * index) 
      pitch       7.02
      func_table  1
    end
  end
end

write "composer_test_results.txt" do
  format    csound
  sections  "Intro Section"
  phrases   "Coda", "Loop"
end
}
  tester, results = test_runner(test_name, throw_on_failure, script)
  actual = results  
  expected0 = 'i 1 0.00000 0.50000 1000 7.01000 1 ; 1'
  expected1 = 'i 1 1.00000 1.00000 1100 7.02000 1 ; 2'
  expected2 = 'i 1 0.00000 0.50000 1000 7.01000 1 ; 3'
  expected3 = 'i 1 1.00000 1.00000 1100 7.02000 1 ; 4'
  expected4 = 'i 1 1.00000 0.20000 1100 7.02000 1 ;'
  expected5 = 'i 1 2.00000 0.20000 1200 7.02000 1 ;'
  tester.assert(expected0 == actual[2])
  tester.assert(expected1 == actual[3])
  tester.assert(expected2 == actual[4])
  tester.assert(expected3 == actual[5])
  tester.assert(expected4 == actual[6])
  tester.assert(expected5 == actual[7])
  puts tester.to_s  
end

def test__render
  throw_on_failure = false
  test_name = "test__render"
  script = 
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__render

phrase "Intro Phrase" do

  note "1" do
    instrument  1 
    start       0.0 
    duration    0.5
    amplitude   1000
    pitch       7.01
    func_table  1
  end
  
  note "2" do
    instrument  1
    start       1.0 
    duration    1.0
    amplitude   1100
    pitch       7.02
    func_table  1
  end

end

write '..\\lib\\composer_test_results.txt' do
  format    csound
  phrases   "Intro Phrase"
end

render '..\\lib\\composer_test.wav' do
  orchestra  '..\\lib\\markov_opt_1.orc'
end
}
  tester, results = test_runner(test_name, throw_on_failure, script)
  tester.assert(File.size("..\\lib\\composer_test.wav") > 0)
  puts tester.to_s  
end

def test__phrase_lite_syntax
  throw_on_failure = true
  lite_syntax = true
  test_name = "test__phrase_lite_syntax"
  script = 
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__phrase_lite_syntax

phrase "Intro Phrase"

  note "1"
    instrument  1 
    start       0.0 
    duration    0.5
    amplitude   1000
    pitch       7.01
    func_table  1

  note "2"
    instrument  1 
    start       1.0 
    duration    1.0
    amplitude   1100
    pitch       7.02
    func_table  1
    
write "composer_test_results.txt"
  format    csound
  phrases   "Intro Phrase"
}
  tester, results = test_runner(test_name, throw_on_failure, script, lite_syntax)
  actual = results
  
  expected0 = 'i 1 0.00000 0.50000 1000 7.01000 1 ; 1'
  expected1 = 'i 1 1.00000 1.00000 1100 7.02000 1 ; 2'
  tester.assert(expected0 == actual[2])
  tester.assert(expected1 == actual[3])
  puts tester.to_s  
end

def test__measure_lite_syntax
  throw_on_failure = false
  lite_syntax = true
  test_name = "test__measure_lite_syntax"
  script = 
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__measure_lite_syntax

measure "Measure 1"

  note "1"
    instrument  1 
    start       0.0 
    duration    0.5
    amplitude   1000
    pitch       7.01
    func_table  1

  note "2"
    instrument  1 
    start       1.0 
    duration    1.0
    amplitude   1100
    pitch       7.02
    func_table  1

measure "Measure 2"

  note "3"
    instrument  1 
    start       0.0 
    duration    0.5
    amplitude   1200
    pitch       7.03
    func_table  1

  note "4"
    instrument  1 
    start       1.0 
    duration    1.0
    amplitude   1300
    pitch       7.04
    func_table  1
    
write "composer_test_results.txt"
  format    csound
  measures   "Measure 1", "Measure 2"
}
  tester, results = test_runner(test_name, throw_on_failure, script, lite_syntax)
  actual = results  
  expected0 = 'i 1 0.00000 0.50000 1000 7.01000 1 ; 1'
  expected1 = 'i 1 1.00000 1.00000 1100 7.02000 1 ; 2'
  expected2 = 'i 1 2.00000 0.50000 1200 7.03000 1 ; 3'
  expected3 = 'i 1 3.00000 1.00000 1300 7.04000 1 ; 4'
  tester.assert(expected0 == actual[2])
  tester.assert(expected1 == actual[3])
  tester.assert(expected2 == actual[4])
  tester.assert(expected3 == actual[5])
  puts tester.to_s  
end

def test__copy_measure_lite_syntax
  throw_on_failure = true
  lite_syntax = true
  test_name = "test__copy_measure_lite_syntax"
  script = 
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__copy_measure_lite_syntax

measure "Measure 1"

  note "1"
    instrument  1 
    start       0.0 
    duration    0.5
    amplitude   1000
    pitch       7.01
    func_table  1

  note "2"
    instrument  1 
    start       1.0 
    duration    1.0
    amplitude   1100
    pitch       7.02
    func_table  1

# NOTE: copy_measure automatically adjusts start times of new measure to be in NEXT position
#  after end of last note in measure being copied, intended for sequence of notes
# TODO: IS THIS USEFUL? MODERATELY, but only serves that one use case, NOT a really useful general
#  cloning mechanism
copy_measure "Measure 1", "Measure 2"
    
write "composer_test_results.txt"
  format    csound
  measures
}
  tester, results = test_runner(test_name, throw_on_failure, script, lite_syntax)
  actual = results  
  expected0 = 'i 1 0.00000 0.50000 1000 7.01000 1 ; 1'
  expected1 = 'i 1 1.00000 1.00000 1100 7.02000 1 ; 2'
  expected2 = 'i 1 2.00000 0.50000 1000 7.01000 1 ; 1'
  expected3 = 'i 1 3.00000 1.00000 1100 7.02000 1 ; 2'
  tester.assert(expected0 == actual[2])
  tester.assert(expected1 == actual[3])
  tester.assert(expected2 == actual[4])
  tester.assert(expected3 == actual[5])
  puts tester.to_s  
end

def test__meter_lite_syntax
  throw_on_failure = true
  lite_syntax = true
  test_name = "test__meter_lite_syntax"
  script = 
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__meter_lite_syntax
meter 4,4
  quantize on

# This tests case of not needing to quantize. Two HLF notes at correct start times that
#  take up exactly the correct length of the measure
measure "Measure 1"

  note "1"
    instrument  1 
    start       0.0 
    duration    HLF
    amplitude   1000
    pitch       7.01
    func_table  1

  note "2"
    instrument  1 
    start       HLF 
    duration    HLF
    amplitude   1100
    pitch       7.02
    func_table  1

# This tests quantize
# Each note is first mapped to QRTR, but that is only half the beat length of the meter
#  so then each is increased to reach the total necessary duration, and each maintains the same
#  percentage of the total duration, so then each is moved from QRTR to HLF, since the meter
#  is 4/4, which is 4 beats of QRTR notes, or one WHL note. Note this adjusts start time of second
#  note correctly also
measure "Measure 2"

  note "1"
    instrument  1 
    start       0.0 
    duration    QRTR
    amplitude   1000
    pitch       7.01
    func_table  1

  note "2"
    instrument  1 
    start       QRTR 
    duration    QRTR
    amplitude   1100
    pitch       7.02
    func_table  1    

write "composer_test_results.txt"
  format    csound
  measures
}
  tester, results = test_runner(test_name, throw_on_failure, script, lite_syntax)
  actual = results
  expected0 = 'i 1 0.00000 2.00000 1000 7.01000 1 ; 1'
  expected1 = 'i 1 2.00000 2.00000 1100 7.02000 1 ; 2'
  expected2 = 'i 1 0.00000 2.00000 1000 7.01000 1 ; 1'
  expected3 = 'i 1 2.00000 2.00000 1100 7.02000 1 ; 2'
  tester.assert(expected0 == actual[2])
  tester.assert(expected1 == actual[3])
  puts tester.to_s  
end

def test__section_lite_syntax
  throw_on_failure = false
  lite_syntax = true
  test_name = "test__section_lite_syntax"
  script = 
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__section_lite_syntax

section "Intro Section"

phrase "Intro Phrase"

  note "3"
    instrument  3 
    start       0.0 
    duration    0.5
    amplitude   1000
    pitch       7.03
    func_table  1
  
  note "4"
    instrument  4
    start       1.0 
    duration    1.0
    amplitude   1100
    pitch       7.04
    func_table  1

write "composer_test_results.txt"
  format    csound
  sections   "Intro Section"
}
  tester, results = test_runner(test_name, throw_on_failure, script, lite_syntax)
  actual = results   
  expected0 = 'i 3 0.00000 0.50000 1000 7.03000 1 ; 3'
  expected1 = 'i 4 1.00000 1.00000 1100 7.04000 1 ; 4'
  tester.assert(expected0 == actual[2])
  tester.assert(expected1 == actual[3])
  puts tester.to_s  
end

def test__sections_phrases_lite_syntax
  throw_on_failure = false
  lite_syntax = true
  test_name = "test__sections_phrases_lite_syntax"
  script = 
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__sections_phrases_lite_syntax

section "Intro Section"
  phrase "Intro Phrase"
    note "5"
      instrument  1 
      start       0.0 
      duration    0.5
      amplitude   1000
      pitch       7.01
      func_table  1
    
    note "6"
      instrument  1
      start       1.0 
      duration    1.0
      amplitude   1100
      pitch       7.02
      func_table  1

  phrase "Coda"
    note "7"
      instrument  1 
      start       0.0 
      duration    0.5
      amplitude   1000
      pitch       7.01
      func_table  1

    note "8"
      instrument  1
      start       1.0 
      duration    1.0
      amplitude   1100
      pitch       7.02
      func_table  1

write "composer_test_results.txt"
  format    csound
  sections  "Intro Section"
}
  tester, results = test_runner(test_name, throw_on_failure, script, lite_syntax)
  actual = results
  expected0 = 'i 1 0.00000 0.50000 1000 7.01000 1 ; 5'
  expected1 = 'i 1 1.00000 1.00000 1100 7.02000 1 ; 6'
  expected2 = 'i 1 0.00000 0.50000 1000 7.01000 1 ; 7'
  expected3 = 'i 1 1.00000 1.00000 1100 7.02000 1 ; 8'
  tester.assert(expected0 == actual[2])
  tester.assert(expected1 == actual[3])
  tester.assert(expected2 == actual[4])
  tester.assert(expected3 == actual[5])
  puts tester.to_s  
end

def test__repeat_index_lite_syntax
  throw_on_failure = false
  lite_syntax = true
  test_name = "test__repeat_index_lite_syntax"
  script = 
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__repeat_index_lite_syntax

phrase "Loop"
  repeat 2
    note "1"
      instrument 1
      start       1.0 * index
      duration    0.2
      amplitude   1000 + (100 * index) 
      pitch       7.02
      func_table  1
      
    note "2"
      instrument 1
      start       1.0 * index
      duration    0.2
      amplitude   1000 + (100 * index) 
      pitch       7.02
      func_table  1
      
write "composer_test_results.txt"
  format    csound
  phrases   "Loop"
}
  tester, results = test_runner(test_name, throw_on_failure, script, lite_syntax)
  actual = results
  expected0 = 'i 1 1.00000 0.20000 1100 7.02000 1 ; 1'
  expected1 = 'i 1 1.00000 0.20000 1100 7.02000 1 ; 2'
  expected2 = 'i 1 2.00000 0.20000 1200 7.02000 1 ; 1'
  expected3 = 'i 1 2.00000 0.20000 1200 7.02000 1 ; 2'
  tester.assert(expected0 == actual[2])
  tester.assert(expected1 == actual[3])
  tester.assert(expected2 == actual[4])
  tester.assert(expected3 == actual[5])
  puts tester.to_s  
end

def test__render_lite_syntax
  throw_on_failure = false
  lite_syntax = true
  test_name = "test__render_lite_syntax"
  script = 
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__render_lite_syntax

phrase "Intro Phrase"

  note "1"
    instrument  1 
    start       0.0 
    duration    0.5
    amplitude   1000
    pitch       7.01
    func_table  1
  
  note "2"
    instrument  1
    start       1.0 
    duration    1.0
    amplitude   1100
    pitch       7.02
    func_table  1

write '..\\lib\\composer_test_results.txt'
  format    csound
  phrases   "Intro Phrase"

render '..\\lib\\composer_test.wav'
  orchestra  '..\\lib\\markov_opt_1.orc'
}
  tester, results = test_runner(test_name, throw_on_failure, script, lite_syntax)
  tester.assert(File.size("C:\\projects\\aleatoric\\lib\\composer_test.wav") > 0)
  puts tester.to_s  
end

def test__assignment
  throw_on_failure = false
  lite_syntax = true
  test_name = "test__assignment"
  script =
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__assignment

note_name_3 = "3"
note_name_4 = "4"
instr_num_3 = 3
instr_num_4 = 4
pitch_3 = 7.03
pitch_4 = 7.04

section "Intro Section"
  phrase "Intro Phrase"
    note note_name_3
      instrument  instr_num_3 
      start       0.0 
      duration    0.5
      amplitude   1000
      pitch       pitch_3
      func_table  1
      
    note note_name_4
      instrument  instr_num_4
      start       1.0 
      duration    1.0
      amplitude   1100
      pitch       pitch_4
      func_table  1

write "composer_test_results.txt"
  format    csound
  sections   "Intro Section"
}
  tester, results = test_runner(test_name, throw_on_failure, script, lite_syntax)
  actual = results
  expected0 = 'i 3 0.00000 0.50000 1000 7.03000 1 ; 3'
  expected1 = 'i 4 1.00000 1.00000 1100 7.04000 1 ; 4'
  tester.assert(expected0 == actual[2])
  tester.assert(expected1 == actual[3])
  puts tester.to_s  
end

def test__assignment_2
  throw_on_failure = false
  lite_syntax = true
  test_name = "test__assignment_2"
  script = 
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__assignment_2

note_name_3 = "3"

phrase "Intro Phrase"

  note note_name_3
    instrument  1
    start       0.0 
    duration    0.5
    amplitude   1000
    pitch       7.01
    func_table  1

write "composer_test_results.txt"
  format    csound
  phrases   "Intro Phrase"
}
  tester, results = test_runner(test_name, throw_on_failure, script, lite_syntax)
  actual = results    
  expected0 = 'i 1 0.00000 0.50000 1000 7.01000 1 ; 3'
  tester.assert(expected0 == actual[2])
  puts tester.to_s  
end

def test__repeat_assignment
  throw_on_failure = false
  test_name = "test__repeat_assignment"
  lite_syntax = true
  script = 
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__repeat_assignment

loop_len = 2

phrase "Loop"
  repeat loop_len
    note
      instrument  1
      start       1.0 * index
      duration    0.2
      amplitude   1000 + (100 * index) 
      pitch       7.02
      func_table  1

write "composer_test_results.txt"
  format    csound
  phrases   "Loop"
}
  tester, results = test_runner(test_name, throw_on_failure, script, lite_syntax)
  actual = results  
  expected0 = 'i 1 1.00000 0.20000 1100 7.02000 1 ;'
  expected1 = 'i 1 2.00000 0.20000 1200 7.02000 1 ;'
  tester.assert(expected0 == actual[2])
  tester.assert(expected1 == actual[3])
  puts tester.to_s  
end

def test__func
  throw_on_failure = false
  test_name = "test__func"
  lite_syntax = true
  script = 
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__func

start_f: factor, idx
  factor * idx

amp_f: base, factor, idx
  base + (factor * idx)

phrase "Loop"
  repeat 2
    note
      instrument 1
      start       start_f: 1.0, index
      duration    0.2
      amplitude   amp_f: 1000, 100, index
      pitch       7.02
      func_table  1

write "composer_test_results.txt"
  format    csound
  phrases   "Loop"
}
  tester, results = test_runner(test_name, throw_on_failure, script, lite_syntax)
  actual = results  
  expected0 = 'i 1 1.00000 0.20000 1100 7.02000 1 ;'
  expected1 = 'i 1 2.00000 0.20000 1200 7.02000 1 ;'
  tester.assert(expected0 == actual[2])
  tester.assert(expected1 == actual[3])
  puts tester.to_s  
end

def test__next
  throw_on_failure = false
  test_name = "test__next"
  lite_syntax = true
  script = 
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__next

measure "Loop"
    note
      instrument 1
      start       0.0
      duration    1.0
      amplitude   1000
      pitch       7.01
      func_table  1

    note
      instrument 1
      start       NEXT
      duration    1.0
      amplitude   1100
      pitch       7.02
      func_table  1
      
write "composer_test_results.txt"
  format    csound
  measures   "Loop"
}
  tester, results = test_runner(test_name, throw_on_failure, script, lite_syntax)
  actual = results    
  expected0 = 'i 1 0.00000 1.00000 1000 7.01000 1 ;'
  expected1 = 'i 1 1.00000 1.00000 1100 7.02000 1 ;'
  tester.assert(expected0 == actual[2])
  tester.assert(expected1 == actual[3])
  puts tester.to_s  
end
##################### /TESTS ########################

# Call each test in here
def run_tests(flags)  
  # TODO - shore this up someday
  # Right now just a way to run just the tests in the else block below
  # Should eventually be able to take a list of tests or 'all' or something like that
  run_only = 'run_only' if flags.length > 0 # just needs to be non-nil for now
    
  if run_only == nil
  
    all_pass = true
    begin
      #
      test__stmt_note_with_name
      test__stmt_note_without_name
      test__stmt_note_alt_syntax
      test__phrase
      test__phrase_alt_syntax
      test__section
      test__repeat_index
      test__write_format_sections_phrases
      test__render
      #  
      test__phrase_lite_syntax
      test__measure_lite_syntax
      test__copy_measure_lite_syntax
      test__section_lite_syntax
      test__repeat_index_lite_syntax
      test__sections_phrases_lite_syntax
      test__assignment
      test__assignment_2
      test__repeat_assignment
      test__func
      test__next
      test__render_lite_syntax
      #    
      test__meter_lite_syntax
    rescue AleatoricTestException => e
      puts e.to_s
      all_pass = false
    end

  # else if run_only != nil, then run the run_only block
  else # run_only
    
    all_pass = true
    begin    
      
      # run_only tests go here
    
    rescue AleatoricTestException => e
      puts e.to_s
      all_pass = false
    end 
    
  end
  
  if AleatoricTest.all_pass? and all_pass
    puts "\n\n***** composer_test: ALL TESTS PASSED *****\n\n"
  else
    puts "\n\n***** composer_test: TESTS FAILED *****\n\n"
    AleatoricTest.failed_tests.each {|test| puts test}
    puts "\n\n"
  end
  puts "composer_lang_test: UNIT TESTING composer_lang\n\n"
end

run_tests ARGV