require 'test_global'

LIB = psub("../lib/")
LOAD = psub("../lib")
$LOAD_PATH << LIB

require 'composer_lang'
require 'composer'

require 'set'
require 'thread'

require 'rubygems'
# TEMP DEBUG
require 'ruby-debug' ; Debugger.start

##
# Set globals normally set by command line args when not running tests
##
$csound_score_include_file_name = 'oscil_sine_ftables_1.txt'


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

@write_mutex = Mutex.new
def write_test_script(script, lite_syntax=false)
  # TODO Include this in composition.rb preprocessing of load() call
  # Read each line of script, and make necessary modifications to transform "almost Ruby" 
  #  input into legal Ruby
  script_name = "test.altc"
  composer = ComposerAST.new  
  script_lines = script.split("\n")
  script_lines = composer.mandatory_preprocess_script(script_lines)  
  if lite_syntax
    script = composer.optional_preprocess_script(script_lines, script_name)
  else
    script = script_lines.join("\n")
  end
  
  # NOTE !!!!!!!!!!!!!!!!!!!!!!!
  # We needed a mutex here to guard from multiple method calls writing to the same file
  #  even though each call comes from a separate function, which should complete
  #  operation before the next is called, and each call makes a single call to this function,
  #  and the docs promise that this syntax *closes the file* on block exit, and that block exit
  #  is clearly within the stack scope of the calling function.  i.e. - the Ruby File IO library
  #  has race condition related to not releasing file handles at block exit and can't be trusted 
  #  even in a single-threaded program properly scoping all calls, at least on 1.8.6 on Windows
  @write_mutex.lock
  File.open(script_name, "w") do |f|
    f << "$LOAD_PATH << \"#{LOAD}\"\nrequire 'composer'\nrequire 'test_user_instruction'\nmodule Aleatoric\n\n" +       
         script +
         "\n\nend\n"   
  end 
  @write_mutex.unlock
end

def run_test_script
  load "test.altc"
end

def read_test_results
  results = portable_readlines("composer_test_results.txt")
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

def test__comment
  throw_on_failure = false
  test_name = "test__comment"
  
  script = 
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__comment

note "note 1" do  # naming notes is optional
  instrument  1 
  start       0.0 
  duration    0.5
  amplitude   1000
  pitch       7.01
  func_table  1
end

# This line has only a comment

# FOR TESTING ONLY
dump_last_note
}
  tester, results = test_runner(test_name, throw_on_failure, script)
  actual = results.first
  expected = "i 1 0.00000 0.50000 1000 7.01000 1 ; note 1"  
  tester.assert(expected == actual)
  puts tester.to_s  
end

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

write "composer_test_results.txt" do
  format    csound
  phrases   "Intro Phrase"
end

render "composer_test.wav" do
  orchestra  "markov_opt_1.orc"
end
}
  tester, results = test_runner(test_name, throw_on_failure, script)
  tester.assert(File.size("composer_test.wav") > 0)
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
  tester.assert(expected0 == actual[2][0...expected0.length])
  tester.assert(expected1 == actual[3][0...expected1.length])
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

def test__tempo
  throw_on_failure = false
  lite_syntax = true
  test_name = "test__tempo"
  script = 
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__tempo

# Define a simple function to test tempo handling complex
#  expression for duration
times_two: x
  2.0 * x

# Tempo is specified in bpm, i.e. 60 == 60 quarter notes/min
#  or a quarter note is 1 sec. or a whole note is 4 secs.
# Default tempo is 60, so if this isn't set above holds
# If it is set, AND durations are specified using duration constants
#  such as WHL, HLF, etc.  The reason for this is that if the score specifies
#  exact tempos in seconds, not just "relative" lengths such as WHL etc. then
#  those exact tempos should be honored
tempo 30

# Test expression rather than simple 2-token line
measure "Measure 1"
  note "1"
    instrument  1 
    start       0.0 
    duration    WHL+HLF  
    amplitude   1000
    pitch       7.01
    func_table  1

  note "2"
    instrument  1 
    start       EITH
    duration    times_two: HLF 
    amplitude   1100
    pitch       7.02
    func_table  1

  note "3"
    instrument  1 
    start       0.0 
    duration    QRTR
    amplitude   1200
    pitch       7.03
    func_table  1

# You can reset tempo whenever you want. Now it's twice as fast as default
tempo 120

# Test expression rather than simple 2-token line
measure "Measure 2"
  note "4"
    instrument  1 
    start       0.0 
    duration    WHL+HLF  
    amplitude   1000
    pitch       7.01
    func_table  1

  note "5"
    instrument  1 
    start       QRTR + QRTR 
    duration    HLF
    amplitude   1100
    pitch       7.02
    func_table  1

  note "6"
    instrument  1 
    start       0.0 
    duration    QRTR
    amplitude   1200
    pitch       7.03
    func_table  1

write "composer_test_results.txt"
  format    csound
  measures   "Measure 1", "Measure 2"
}
  tester, results = test_runner(test_name, throw_on_failure, script, lite_syntax)
  actual = results        
  expected0 = 'i 1 0.00000 12.00000 1000 7.01000 1 ; 1'
  expected1 = 'i 1 1.00000 8.00000 1100 7.02000 1 ; 2'
  expected2 = 'i 1 0.00000 2.00000 1200 7.03000 1 ; 3'
  expected3 = 'i 1 12.00000 3.00000 1000 7.01000 1 ; 4'
  expected4 = 'i 1 13.00000 1.00000 1100 7.02000 1 ; 5'
  expected5 = 'i 1 12.00000 0.50000 1200 7.03000 1 ; 6'
  tester.assert(expected0 == actual[2])
  tester.assert(expected1 == actual[3])
  tester.assert(expected2 == actual[4])
  tester.assert(expected3 == actual[5])
  tester.assert(expected4 == actual[6])
  tester.assert(expected5 == actual[7])
  puts tester.to_s  
end

def test__tempo_default
  throw_on_failure = false
  lite_syntax = true
  test_name = "test__tempo_default"
  script = 
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__tempo_default

# Don't set tempo and default is 60 bpm, quarter note == 1 sec
# tempo 30

measure "Measure 1"
  note "1"
    instrument  1 
    start       0.0 
    duration    WHL
    amplitude   1000
    pitch       7.01
    func_table  1

  note "2"
    instrument  1 
    start       1.0 
    duration    HLF
    amplitude   1100
    pitch       7.02
    func_table  1

  note "3"
    instrument  1 
    start       0.0 
    duration    QRTR
    amplitude   1200
    pitch       7.03
    func_table  1

write "composer_test_results.txt"
  format    csound
  measures   "Measure 1"
}
  tester, results = test_runner(test_name, throw_on_failure, script, lite_syntax)
  actual = results        
  expected0 = 'i 1 0.00000 4.00000 1000 7.01000 1 ; 1'
  expected1 = 'i 1 1.00000 2.00000 1100 7.02000 1 ; 2'
  expected2 = 'i 1 0.00000 1.00000 1200 7.03000 1 ; 3'
  tester.assert(expected0 == actual[2])
  tester.assert(expected1 == actual[3])
  tester.assert(expected2 == actual[4])
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

write "composer_test_results.txt"
  format    csound
  phrases   "Intro Phrase"

render "composer_test.wav"
  orchestra  "markov_opt_1.orc"
}
  tester, results = test_runner(test_name, throw_on_failure, script, lite_syntax)
  tester.assert(File.size("composer_test.wav") > 0)
  puts tester.to_s  
end

def test__render_lite_syntax_default_write
  throw_on_failure = false
  lite_syntax = true
  test_name = "test__render_lite_syntax_default_write"
  script = 
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__render_lite_syntax_default_write

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

render "composer_test.wav"
  phrases   "Intro Phrase"
  format    csound
  orchestra  "markov_opt_1.orc"
}
  tester, results = test_runner(test_name, throw_on_failure, script, lite_syntax)
  tester.assert(File.size("composer_test.wav") > 0)
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

def test__assignment_comment
  throw_on_failure = false
  lite_syntax = true
  test_name = "test__assignment_comment"
  script =
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__assignment_comment

note_name_3 = "3"  # comment blah blah
note_name_4 = "4"
instr_num_3 = 3      # comment blah blah
instr_num_4 = 4 # comment blah blah
pitch_3 = 7.03
pitch_4 = 7.04

 # comment blah blah
section "Intro Section"   # comment blah blah
  phrase "Intro Phrase"     # comment blah blah
    note note_name_3    # comment blah blah
      instrument  instr_num_3    # comment blah blah
      start       0.0 
      duration    0.5
      amplitude   1000
      pitch       pitch_3
      func_table  1
# comment blah blah
    note note_name_4
      instrument  instr_num_4
      start       1.0 
      duration    1.0
      amplitude   1100
      pitch       pitch_4
      func_table  1
          # comment blah blah
write "composer_test_results.txt"
  # comment blah blah
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

def test__repeat_until
  throw_on_failure = false
  test_name = "test__repeat_until"
  lite_syntax = true
  script = 
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__repeat_until

player "Player 1"

phrase "Loop"
  repeat until "I want to stop"
    note
      instrument  1
      start       1.0 * 1.0
      duration    0.2
      amplitude   1000 + (100 * 1) 
      pitch       7.02
      func_table  1

instruction "Exit Loop"
  description "call repeat_until ('I want to stop')"
  players     "Player 1"

play
  players "Player 1"

write "composer_test_results.txt"
  format    csound
  phrases   "Loop"
}
  tester, results = test_runner(test_name, throw_on_failure, script, lite_syntax)
  actual = results
  # Instruction is postplay so the loop above produces one note and then exits the loop
  expected0 = 'i 1 1.00000 0.20000 1100 7.02000 1 ;'
  tester.assert(expected0 == actual[2])
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

def test__ensemble
  throw_on_failure = false
  test_name = "test__ensemble"
  lite_syntax = false
  script = 
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__ensemble

# NOTE: CANNOT do non-block "lite" syntax with 'dump*' calls !!!
# The dump call ends up within the block scope because it's not specified
#  in composer_lang as a block closing keyword
ensemble "In C Orchestra" do
  players "Player 1", "Player 2"  
end

# FOR TESTING ONLY    
dump_last_ensemble  
}
  tester, results = test_runner(test_name, throw_on_failure, script, lite_syntax)
  actual = results 
  
  # TODO Have a better test against actual notes and not these bogus 'dump*' methods
  expected0 = 'In C Orchestra'
  expected1 = '2'
  expected2 = 'Player 1'
  expected3 = 'Player 2'
  tester.assert(expected0 == actual[0] && expected1 == actual[1] && expected2 == actual[2] && expected3 == actual[3])
  puts tester.to_s  
end

def test__ensemble_phrase_play_players
  throw_on_failure = false
  test_name = "test__ensemble_phrase_play_players"
  lite_syntax = true
  script = 
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__ensemble_phrase_play_players

ensemble "In C Orchestra"
  players "Player 1", "Player 2"  
  
  phrase "Phrase 1"
    note "1"
      instrument  1 
      start       1.0 
      duration    0.5
      amplitude   1000
      pitch       7.01
      func_table  1
      
    note "2"
      instrument  2 
      start       2.0 
      duration    1.0
      amplitude   1100
      pitch       7.02
      func_table  1

play
  players "Player 1", "Player 2" 
  
write "composer_test_results.txt"
  format    csound
  players "Player 1", "Player 2"
  # ensembles "In C Orchestra"
}
  tester, results = test_runner(test_name, throw_on_failure, script, lite_syntax)
  actual = results  
  expected0 = 'i 1 1.00000 0.50000 1000 7.01000 1 ; 1'
  expected1 = 'i 2 2.00000 1.00000 1100 7.02000 1 ; 2'
  expected2 = 'i 1 1.00000 0.50000 1000 7.01000 1 ; 1'
  expected3 = 'i 2 2.00000 1.00000 1100 7.02000 1 ; 2'
  tester.assert(expected0 == actual[2])
  tester.assert(expected1 == actual[3])
  tester.assert(expected2 == actual[4])
  tester.assert(expected3 == actual[5])
  puts tester.to_s  
end

def test__ensemble_phrase_play_ensembles
  throw_on_failure = false
  test_name = "test__ensemble_phrase_play_ensembles"
  lite_syntax = true
  script = 
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__ensemble_phrase_play_ensembles

ensemble "In C Orchestra"
  players "Player 1", "Player 2"  
  
  phrase "Phrase 1"
    note "1"
      instrument  1 
      start       1.0 
      duration    0.5
      amplitude   1000
      pitch       7.01
      func_table  1
      
    note "2"
      instrument  2 
      start       2.0 
      duration    1.0
      amplitude   1100
      pitch       7.02
      func_table  1

play
  ensembles "In C Orchestra"
  
write "composer_test_results.txt"
  format    csound
  ensembles "In C Orchestra"
}
  tester, results = test_runner(test_name, throw_on_failure, script, lite_syntax)
  actual = results  
  expected0 = 'i 1 1.00000 0.50000 1000 7.01000 1 ; 1'
  expected1 = 'i 2 2.00000 1.00000 1100 7.02000 1 ; 2'
  expected2 = 'i 1 1.00000 0.50000 1000 7.01000 1 ; 1'
  expected3 = 'i 2 2.00000 1.00000 1100 7.02000 1 ; 2'
  tester.assert(expected0 == actual[2])
  tester.assert(expected1 == actual[3])
  tester.assert(expected2 == actual[4])
  tester.assert(expected3 == actual[5])
  puts tester.to_s  
end

# - TODO - implement various instructions using the full Player and Ensemble class API
# -- including: preplay hooks, postplay hooks, relying on setting and getting state, improvising

def test__instruction_players
  throw_on_failure = false
  test_name = "test__instruction_players"
  lite_syntax = true
  script = 
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__instruction_players

ensemble "In C Orchestra"
  players "Player 1", "Player 2"  
  
  phrase "Phrase 1"
    note "1"
      instrument  1 
      start       1.0 
      duration    0.5
      amplitude   1000
      pitch       7.01
      func_table  1
      
    note "2"
      instrument  2 
      start       2.0 
      duration    1.0
      amplitude   1100
      pitch       7.02
      func_table  1

# Just tell one player in the ensemble to follow this instruction
# impl. in test_user_instruction.rb
instruction "Fortissimo"
  description "Player should play each note twice as loud as the notated volume of the note."
  players     "Player 1"

# Just tell one player in the ensemble to follow this instruction
# impl. in test_user_instruction.rb
instruction "Pianissimo"
  description "Player should play each note half as loud as the notated volume of the note."
  players     "Player 2"

# Tell all players in the ensemble to play
play
  ensembles "In C Orchestra"
  
# Output notes from all players in the ensemble, generated by 'play' statement
write "composer_test_results.txt"
  format    csound
  ensembles "In C Orchestra"
}
  tester, results = test_runner(test_name, throw_on_failure, script, lite_syntax)
  actual = results    
  # Amplitude double what is notated in 'note' statements because of 'instruction' implementation
  # Player 1's notes
  expected0 = 'i 1 1.00000 0.50000 2000 7.01000 1 ; 1'
  expected1 = 'i 2 2.00000 1.00000 2200 7.02000 1 ; 2'
  # Amplitude half what is notated in 'note' statements because of 'instruction' implementation
  # Player 2's notes
  expected2 = 'i 1 1.00000 0.50000 500 7.01000 1 ; 1'
  expected3 = 'i 2 2.00000 1.00000 550 7.02000 1 ; 2'
  
  tester.assert(expected0 == actual[2])
  tester.assert(expected1 == actual[3])
  tester.assert(expected2 == actual[4])
  tester.assert(expected3 == actual[5])
  puts tester.to_s  
end

def test__instruction_players_ensembles
  throw_on_failure = false
  test_name = "test__instruction_players_ensembles"
  lite_syntax = true
  script = 
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__instruction_players_ensembles

ensemble "In C Orchestra"
  players "Player 1", "Player 2"  

player "Player 1"  
  phrase "Phrase 1"
    note "1"
      instrument  1 
      start       1.0 
      duration    0.5
      amplitude   1000
      pitch       7.01
      func_table  1
      
    note "2"
      instrument  2 
      start       2.0 
      duration    1.0
      amplitude   1100
      pitch       7.02
      func_table  1

player "Player 2"  
  phrase "Phrase 1"
    note "3"
      instrument  3 
      start       3.0 
      duration    1.5
      amplitude   1200
      pitch       7.03
      func_table  1
      
    note "4"
      instrument  4 
      start       4.0 
      duration    2.0
      amplitude   1300
      pitch       7.04
      func_table  1      
      
# Just tell one player in the ensemble to follow this instruction
# impl. in test_user_instruction.rb
instruction "Fortissimo"
  description "Player should play each note twice as loud as the notated volume of the note."
  players     "Player 1"

# Just tell one player in the ensemble to follow this instruction
# impl. in test_user_instruction.rb
instruction "Pianissimo"
  description "Player should play each note half as loud as the notated volume of the note."
  players     "Player 2"
  
# impl. in test_user_instruction.rb
instruction "Each Player Appends Another Player's First Note"
  description "Each member of the ensemble should repeat the first note played by another member of the ensemble as their last note."
  ensembles   "In C Orchestra"

# Tell all players in the ensemble to play
play
  ensembles "In C Orchestra"
  
# Output notes from all players in the ensemble, generated by 'play' statement
write "composer_test_results.txt"
  format    csound
  ensembles "In C Orchestra"
}
  tester, results = test_runner(test_name, throw_on_failure, script, lite_syntax)
  actual = results
  
  # Amplitude double what is notated in 'note' statements because of 'instruction' implementation
  # Player 1's notes
  expected0 = 'i 1 1.00000 0.50000 2000 7.01000 1 ; 1'
  expected1 = 'i 2 2.00000 1.00000 2200 7.02000 1 ; 2'
  expected2 = 'i 3 3.00000 1.50000 600 7.03000 1 ; 3'
  # Amplitude half what is notated in 'note' statements because of 'instruction' implementation
  # Player 2's notes
  expected3 = 'i 3 3.00000 1.50000 600 7.03000 1 ; 3'
  expected4 = 'i 4 4.00000 2.00000 650 7.04000 1 ; 4'
  expected5 = 'i 1 1.00000 0.50000 2000 7.01000 1 ; 1'
  
  tester.assert(expected0 == actual[2])
  tester.assert(expected1 == actual[3])
  tester.assert(expected2 == actual[4])
  tester.assert(expected3 == actual[5])
  tester.assert(expected4 == actual[6])
  tester.assert(expected5 == actual[7])
  puts tester.to_s  
end

def test__instruction_players_state
  throw_on_failure = false
  test_name = "test__instruction_players_state"
  lite_syntax = true
  script = 
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__instruction_players_state

ensemble "In C Orchestra"
  players "Player 1", "Player 2"  

player "Player 1"  
  phrase "Phrase 1"
    note "1"
      instrument  1 
      start       1.0 
      duration    0.5
      amplitude   1000
      pitch       7.01
      func_table  1
      
    note "2"
      instrument  2 
      start       2.0 
      duration    1.0
      amplitude   1100
      pitch       7.02
      func_table  1

player "Player 2"  
  phrase "Phrase 1"
    note "3"
      instrument  3 
      start       3.0 
      duration    1.5
      amplitude   1200
      pitch       7.03
      func_table  1
      
    note "4"
      instrument  4 
      start       4.0 
      duration    2.0
      amplitude   1300
      pitch       7.04
      func_table  1      
      
# NOTE: This is an artificial and useless use of state-checking, since it amounts to just
#  alternating playing and not playing, but it's deterministic and so testable
# Requires setting state after playing and checking it before
# impl. in test_user_instruction.rb
instruction "Alternate"
  description "Player should play with a 0% chance if they played last time, and a 100% chance if they didn't play last time."
  players "Player 1", "Player 2"

# Play three times, each Player should output twice (skipping the middle iteration)
repeat 3
  play
    ensembles "In C Orchestra"
  
# Output notes from all players in the ensemble, generated by 'play' statement
write "composer_test_results.txt"
  format    csound
  ensembles "In C Orchestra"
}
  tester, results = test_runner(test_name, throw_on_failure, script, lite_syntax)
  actual = results
  # TODO THIS NEEDS TO BE IN ONLINE DOCUMENTATION
  # NOTE: These start times advance to start at the next current starting time for each Player
  #  because players are set to work this way, because otherwise they are painful to use in a 
  #  real composition.  The behavior can be overriddent with attribute player.auto_next_start_off
  expected0 = 'i 1 1.00000 0.50000 0 7.01000 1 ; 1'
  expected1 = 'i 2 2.00000 1.00000 0 7.02000 1 ; 2'
  expected2 = 'i 1 2.50000 0.50000 1000 7.01000 1 ; 1'
  expected3 = 'i 2 2.00000 1.00000 1100 7.02000 1 ; 2'
  expected4 = 'i 1 4.00000 0.50000 0 7.01000 1 ; 1'
  expected5 = 'i 2 5.50000 1.00000 0 7.02000 1 ; 2'
  expected6 = 'i 3 3.00000 1.50000 0 7.03000 1 ; 3'
  expected7 = 'i 4 4.00000 2.00000 0 7.04000 1 ; 4'
  expected8 = 'i 3 6.50000 1.50000 1200 7.03000 1 ; 3'
  expected9 = 'i 4 9.00000 2.00000 1300 7.04000 1 ; 4'
  expected10 = 'i 3 10.00000 1.50000 0 7.03000 1 ; 3'
  expected11 = 'i 4 12.50000 2.00000 0 7.04000 1 ; 4'
  
  tester.assert(expected0 == actual[2])
  tester.assert(expected1 == actual[3])
  tester.assert(expected2 == actual[4])
  tester.assert(expected3 == actual[5])
  tester.assert(expected4 == actual[6])
  tester.assert(expected5 == actual[7])
  tester.assert(expected6 == actual[8])
  tester.assert(expected7 == actual[9])
  tester.assert(expected8 == actual[10])
  tester.assert(expected9 == actual[11])
  tester.assert(expected10 == actual[12])
  tester.assert(expected11 == actual[13])

  puts tester.to_s  
end

def test__instruction_ensemble_state
  throw_on_failure = false
  test_name = "test__instruction_ensemble_state"
  lite_syntax = true
  script = 
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__instruction_ensemble_state

ensemble "In C Orchestra"
  players "Player 1", "Player 2"  

player "Player 1"  
  phrase "Phrase 1 1"
    note "1"
      instrument  1 
      start       1.0 
      duration    0.5
      amplitude   1000
      pitch       7.01
      func_table  1
      
    note "2"
      instrument  2 
      start       2.0 
      duration    1.0
      amplitude   1100
      pitch       7.02
      func_table  1

player "Player 2"  
  phrase "Phrase 2 1"
    note "3"
      instrument  3 
      start       3.0 
      duration    1.5
      amplitude   1200
      pitch       7.03
      func_table  1
      
    note "4"
      instrument  4 
      start       4.0 
      duration    2.0
      amplitude   1300
      pitch       7.04
      func_table  1      
      
# NOTE: This is an artificial and useless use of state-checking, since it amounts to just
#  alternating playing and not playing, but it's deterministic and so testable
# Requires setting state after playing and checking it before
# impl. in test_user_instruction.rb
instruction "Alternate Ensemble"
  description "Ensemble should play with a 0% chance if they played last time, and a 100% chance if they didn't play last time."
  ensembles "In C Orchestra"

# Play three times, each Player should output twice (skipping the middle iteration)
repeat 3
  play
    ensembles "In C Orchestra"
  
# Output notes from all players in the ensemble, generated by 'play' statement
write "composer_test_results.txt"
  format    csound
  ensembles "In C Orchestra"
}
  tester, results = test_runner(test_name, throw_on_failure, script, lite_syntax)
  actual = results
        
  expected0 = 'i 1 1.00000 0.50000 0 7.01000 1 ; 1'
  expected1 = 'i 2 2.00000 1.00000 0 7.02000 1 ; 2'
  expected2 = 'i 1 2.50000 0.50000 1000 7.01000 1 ; 1'
  expected3 = 'i 2 2.00000 1.00000 1100 7.02000 1 ; 2'
  expected4 = 'i 1 4.00000 0.50000 0 7.01000 1 ; 1'
  expected5 = 'i 2 5.50000 1.00000 0 7.02000 1 ; 2'
  expected6 = 'i 3 3.00000 1.50000 0 7.03000 1 ; 3'
  expected7 = 'i 4 4.00000 2.00000 0 7.04000 1 ; 4'
  expected8 = 'i 3 6.50000 1.50000 1200 7.03000 1 ; 3'
  expected9 = 'i 4 9.00000 2.00000 1300 7.04000 1 ; 4'
  expected10 = 'i 3 10.00000 1.50000 0 7.03000 1 ; 3'
  expected11 = 'i 4 12.50000 2.00000 0 7.04000 1 ; 4'
  
  tester.assert(expected0 == actual[2])
  tester.assert(expected1 == actual[3])
  tester.assert(expected2 == actual[4])
  tester.assert(expected3 == actual[5])
  tester.assert(expected4 == actual[6])
  tester.assert(expected5 == actual[7])
  tester.assert(expected6 == actual[8])
  tester.assert(expected7 == actual[9])
  tester.assert(expected8 == actual[10])
  tester.assert(expected9 == actual[11])
  tester.assert(expected10 == actual[12])
  tester.assert(expected11 == actual[13])

  puts tester.to_s  
end

def test__improvise_player
  throw_on_failure = false
  test_name = "test__improvise_player"
  lite_syntax = true
  script = 
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__improvise_player

format csound

player "Player 1"

# NOTE: This is an artificial improv that always returns the same thing, for testing
# impl. in test_user_instruction.rb
improvisation "Play a whole note on Middle C"
  description "Test improvisation"
  players "Player 1"
  
improvise 
  players "Player 1"

# Output notes from all players in the ensemble, generated by 'play' statement
write "composer_test_results.txt"
  players "Player 1"
}
  tester, results = test_runner(test_name, throw_on_failure, script, lite_syntax)
  actual = results    
  expected0 = 'i 1 0.00000 4.00000 1000 8.01000 1 ;'  
  tester.assert(expected0 == actual[2])

  puts tester.to_s  
end

def test__improvise2_player
  throw_on_failure = false
  test_name = "test__improvise2_player"
  lite_syntax = true
  script = 
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__improvise2_player

format csound

player "Player 1"
player "Player 2"

improvisation "Play a whole note on Middle C"
  description "Test improvisation"
  players "Player 1"
improvisation "Play a whole note on Middle D"
  description "Test improvisation"
  players "Player 2"
  
improvise "Play a whole note on Middle C"
  players "Player 1"
improvise "Play a whole note on Middle D"
  players "Player 2"

write "composer_test_results.txt"
  players "Player 1", "Player 2"
}
  tester, results = test_runner(test_name, throw_on_failure, script, lite_syntax)
  actual = results  
  expected0 = 'i 1 0.00000 4.00000 1000 8.01000 1 ;'
  expected1 = 'i 1 0.00000 4.00000 1000 8.02000 1 ;'
  tester.assert(expected0 == actual[2])
  tester.assert(expected1 == actual[3])

  puts tester.to_s  
end

def test__phrase_midi_lite_syntax
  throw_on_failure = true
  lite_syntax = true
  test_name = "test__phrase_midi_lite_syntax"
  script = 
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__phrase_midi_lite_syntax

phrase "Intro Phrase"
  
  # Using aliased MIDI property names for note. Note 'channel' is midi-only
  note "1"
    instrument  1  
    time       0.0
    duration    1.0
    velocity    100
    pitch       64 
    channel     1 

  # Using csound and "Aleatoric normal" property names for a note. Note 'channel' is midi-only
  note "2"
    instrument  1
    start       1.0
    duration    1.0
    amplitude   100
    pitch       65 
    channel     1
    
  # Using csound and "Aleatoric normal" property names for a note, but switch to use 'volume' for 'velocity.' Note 'channel' is midi-only
  note "3"
    instrument  1
    start       2.0
    duration    1.0
    volume      100
    pitch       66 
    channel     1     
    
write "composer_test_results.txt"
  format    midi
  phrases   "Intro Phrase"
}
  tester, results = test_runner(test_name, throw_on_failure, script, lite_syntax)
  actual = results   
  expected0 = 'instrument 1  start 0.00000  duration 1.00000  amplitude 100  pitch 64  channel 1 ; 1'
  expected1 = 'instrument 1  start 1.00000  duration 1.00000  amplitude 100  pitch 65  channel 1 ; 2'
  expected2 = 'instrument 1  start 2.00000  duration 1.00000  amplitude 100  pitch 66  channel 1 ; 3'
  tester.assert(expected0 == actual[0])
  tester.assert(expected1 == actual[1])
  tester.assert(expected2 == actual[2])
  puts tester.to_s  
end

def test__phrase_midi_format_top
  throw_on_failure = true
  lite_syntax = true
  test_name = "test__phrase_midi_format_top"
  script = 
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__phrase_midi_format_top

format midi

phrase "Intro Phrase"
  
  # Using aliased MIDI property names for note. Note 'channel' is midi-only
  note "1"
    instrument  1  
    time       0.0
    duration    1.0
    velocity    100
    pitch       64 
    channel     1 

  # Using csound and "Aleatoric normal" property names for a note. Note 'channel' is midi-only
  note "2"
    instrument  1
    start       1.0
    duration    1.0
    amplitude   100
    pitch       65 
    channel     1
    
  # Using csound and "Aleatoric normal" property names for a note, but switch to use 'volume' for 'velocity.' Note 'channel' is midi-only
  note "3"
    instrument  1
    start       2.0
    duration    1.0
    volume      100
    pitch       66 
    channel     1     
    
write "composer_test_results.txt"
  phrases   "Intro Phrase"
}
  tester, results = test_runner(test_name, throw_on_failure, script, lite_syntax)
  actual = results   
  expected0 = 'instrument 1  start 0.00000  duration 1.00000  amplitude 100  pitch 64  channel 1 ; 1'
  expected1 = 'instrument 1  start 1.00000  duration 1.00000  amplitude 100  pitch 65  channel 1 ; 2'
  expected2 = 'instrument 1  start 2.00000  duration 1.00000  amplitude 100  pitch 66  channel 1 ; 3'
  tester.assert(expected0 == actual[0])
  tester.assert(expected1 == actual[1])
  tester.assert(expected2 == actual[2])
  puts tester.to_s  
end

def test__ensemble_instrument_channel_midi_render
  throw_on_failure = true
  lite_syntax = true
  test_name = "test__ensemble_instrument_channel_midi_render"
  script = 
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__ensemble_instrument_channel_midi_render

format midi

player "Player 1"
  instrument 1
  channel 1
player "Player 2"  
  instrument 2
  channel 2

ensemble "In C Orchestra"
  players "Player 1", "Player 2"  

  phrase "Intro Phrase"
  
    note "1"
      time       0.0
      duration    1.0
      velocity    100
      pitch       64 

    note "2"
      start       1.0
      duration    1.0
      amplitude   100
      pitch       65 
    
    note "3"
      start       2.0
      duration    1.0
      volume      100
      pitch       66 

play
  ensembles "In C Orchestra"
  
write "composer_test_results.txt"
  ensembles "In C Orchestra"
}
  tester, results = test_runner(test_name, throw_on_failure, script, lite_syntax)
  actual = results     
  expected0 = 'instrument 1  start 0.00000  duration 1.00000  amplitude 100  pitch 64  channel 1 ; 1'
  expected1 = 'instrument 1  start 1.00000  duration 1.00000  amplitude 100  pitch 65  channel 1 ; 2'
  expected2 = 'instrument 1  start 2.00000  duration 1.00000  amplitude 100  pitch 66  channel 1 ; 3'
  expected3 = 'instrument 2  start 0.00000  duration 1.00000  amplitude 100  pitch 64  channel 2 ; 1'
  expected4 = 'instrument 2  start 1.00000  duration 1.00000  amplitude 100  pitch 65  channel 2 ; 2'
  expected5 = 'instrument 2  start 2.00000  duration 1.00000  amplitude 100  pitch 66  channel 2 ; 3'
  tester.assert(expected0 == actual[0])
  tester.assert(expected1 == actual[1])
  tester.assert(expected2 == actual[2])
  tester.assert(expected3 == actual[3])
  tester.assert(expected4 == actual[4])
  tester.assert(expected5 == actual[5])
  puts tester.to_s  
end

def test__phrase_midi_format_consts
  throw_on_failure = true
  lite_syntax = true
  test_name = "test__phrase_midi_format_consts"
  script = 
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__phrase_midi_format_consts

format midi

phrase "Intro Phrase"
  
  # Using aliased MIDI property names for note. Note 'channel' is midi-only
  note "1"
    instrument  MIDI_Acoustic_Grand_Piano  
    time       0.0
    duration    1.0
    velocity    100
    pitch       Bneg1 
    channel     1 

  # Using csound and "Aleatoric normal" property names for a note. Note 'channel' is midi-only
  note "2"
    instrument  MIDI_Bright_Acoustic_Piano
    start       1.0
    duration    1.0
    amplitude   100
    pitch       C4 
    channel     1
    
  # Using csound and "Aleatoric normal" property names for a note, but switch to use 'volume' for 'velocity.' Note 'channel' is midi-only
  note "3"
    instrument  MIDI_Electric_Grand_Piano
    start       2.0
    duration    1.0
    volume      100
    pitch       B5 
    channel     1     
    
write "composer_test_results.txt"
  phrases "Intro Phrase"
}
  tester, results = test_runner(test_name, throw_on_failure, script, lite_syntax)
  actual = results
  expected0 = 'instrument 0  start 0.00000  duration 1.00000  amplitude 100  pitch 11  channel 1 ; 1'
  expected1 = 'instrument 1  start 1.00000  duration 1.00000  amplitude 100  pitch 60  channel 1 ; 2'
  expected2 = 'instrument 2  start 2.00000  duration 1.00000  amplitude 100  pitch 83  channel 1 ; 3'
  
  tester.assert(expected0 == actual[0])
  tester.assert(expected1 == actual[1])
  tester.assert(expected2 == actual[2])
  puts tester.to_s  
end

def test__phrase_csound_format_consts
  throw_on_failure = true
  lite_syntax = true
  test_name = "test__phrase_csound_format_consts"
  script = 
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__phrase_csound_format_consts

format csound

phrase "Intro Phrase"
  
  note "1"
    instrument  1  
    start       0.0
    duration    1.0
    amplitude   100
    pitch       C4 
    func_table  1 

  note "2"
    instrument  2
    start       1.0
    duration    1.0
    amplitude   100
    pitch       C5 
    func_table  1
    
  note "3"
    instrument  3
    start       2.0
    duration    1.0
    amplitude   100
    pitch       C6 
    func_table  1     
    
write "composer_test_results.txt"
  phrases "Intro Phrase"
}
  tester, results = test_runner(test_name, throw_on_failure, script, lite_syntax)
  actual = results    
  expected0 = 'i 1 0.00000 1.00000 100 8.00000 1 ; 1'
  expected1 = 'i 2 1.00000 1.00000 100 9.00000 1 ; 2'
  expected2 = 'i 3 2.00000 1.00000 100 10.00000 1 ; 3'
  
  tester.assert(expected0 == actual[2])
  tester.assert(expected1 == actual[3])
  tester.assert(expected2 == actual[4])
  puts tester.to_s  
end

def test__player_instrument
  throw_on_failure = false
  test_name = "test__player_instrument"
  lite_syntax = true
  script = 
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__player_instrument

format csound

player "Player 1"
  instrument 1
player "Player 2"
  instrument 2

ensemble "In C Orchestra"
  players "Player 1", "Player 2"  
  
  phrase "Phrase 1"
    note "1"
      start       1.0 
      duration    0.5
      amplitude   1000
      pitch       7.01
      func_table  1
      
    note "2"
      start       2.0 
      duration    1.0
      amplitude   1100
      pitch       7.02
      func_table  1

play
  players "Player 1", "Player 2" 
  
write "composer_test_results.txt"
  players "Player 1", "Player 2"
}
  tester, results = test_runner(test_name, throw_on_failure, script, lite_syntax)
  actual = results    
  expected0 = 'i 1 1.00000 0.50000 1000 7.01000 1 ; 1'
  expected1 = 'i 1 2.00000 1.00000 1100 7.02000 1 ; 2'
  expected2 = 'i 2 1.00000 0.50000 1000 7.01000 1 ; 1'
  expected3 = 'i 2 2.00000 1.00000 1100 7.02000 1 ; 2'    
  tester.assert(expected0 == actual[2])
  tester.assert(expected1 == actual[3])
  tester.assert(expected2 == actual[4])
  tester.assert(expected3 == actual[5])
  puts tester.to_s  
end

def test__player_instrument_channel
  throw_on_failure = false
  test_name = "test__player_instrument_channel"
  lite_syntax = true
  script = 
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__player_instrument_channel

format midi

player "Player 1"
  instrument 1, channel=0
player "Player 2"
  instrument 2, channel=1

ensemble "In C Orchestra"
  players "Player 1", "Player 2"  
  
  phrase "Phrase 1"
    note "1"
      start       1.0 
      duration    0.5
      volume      100
      pitch       60
      
    note "2"
      start       2.0 
      duration    1.0
      volume     110
      pitch       61

play
  players "Player 1", "Player 2" 
  
write "composer_test_results.txt"
  players "Player 1", "Player 2"
}
  tester, results = test_runner(test_name, throw_on_failure, script, lite_syntax)
  actual = results      
  expected0 = 'instrument 1  start 1.00000  duration 0.50000  amplitude 100  pitch 60  channel 0 ; 1'
  expected1 = 'instrument 1  start 2.00000  duration 1.00000  amplitude 110  pitch 61  channel 0 ; 2'
  expected2 = 'instrument 2  start 1.00000  duration 0.50000  amplitude 100  pitch 60  channel 1 ; 1'
  expected3 = 'instrument 2  start 2.00000  duration 1.00000  amplitude 110  pitch 61  channel 1 ; 2'
  # NOTE: MIDI tests don't have '#include' line like CSound tests, so comp starts at line 0, not line 2
  tester.assert(expected0 == actual[0])
  tester.assert(expected1 == actual[1])
  tester.assert(expected2 == actual[2])
  tester.assert(expected3 == actual[3])
  puts tester.to_s  
end

# TODO Fix documentation to indicate the omitting start has NEXT behavior
#  but that NEXT kw is not supported
def test__no_start_auto_next
  throw_on_failure = false
  test_name = "test__no_start_auto_next"
  lite_syntax = true
  script = 
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__no_start_auto_next

format csound

player "Player 1"
  instrument 1
player "Player 2"
  instrument 2

ensemble "In C Orchestra"
  players "Player 1", "Player 2"  
  
  phrase "Phrase 1"
    note "1"
      start       1.0 
      duration    0.5
      amplitude   1000
      pitch       7.01
      func_table  1
      
    note "2"
      duration    1.0
      amplitude   1100
      pitch       7.02
      func_table  1

play
  players "Player 1", "Player 2" 
  
write "composer_test_results.txt"
  players "Player 1", "Player 2"
}
  tester, results = test_runner(test_name, throw_on_failure, script, lite_syntax)
  actual = results 
  expected0 = 'i 1 1.00000 0.50000 1000 7.01000 1 ; 1'
  expected1 = 'i 1 1.50000 1.00000 1100 7.02000 1 ; 2'
  expected2 = 'i 2 1.00000 0.50000 1000 7.01000 1 ; 1'
  expected3 = 'i 2 1.50000 1.00000 1100 7.02000 1 ; 2'
  tester.assert(expected0 == actual[2])
  tester.assert(expected1 == actual[3])
  tester.assert(expected2 == actual[4])
  tester.assert(expected3 == actual[5])
  puts tester.to_s  
end

def test__import_phrase
  throw_on_failure = false
  test_name = "test__import_phrase"
  lite_syntax = true
  script = 
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__import_phrase

format midi

phrase "Phrase 1"
  import "composer_lang_ut.mid"

write "composer_test_results.txt"
  phrases "Phrase 1"
}
  tester, results = test_runner(test_name, throw_on_failure, script, lite_syntax)
  actual = results  
  expected0 = 'instrument 1  start 0.00000  duration 4.00000  amplitude 100  pitch 64  channel 0 ; 0'
  expected1 = 'instrument 20  start 0.00000  duration 4.00000  amplitude 100  pitch 65  channel 1 ; 1'
  tester.assert(expected0 == actual[0])
  tester.assert(expected1 == actual[1])
  puts tester.to_s
end

def test__import_root_map_players
  throw_on_failure = false
  test_name = "test__import_root_map_players"
  lite_syntax = true
  script = 
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__import_root_map_players

format midi

player "Player 1"
  channel 1
player "Player 2"
  channel 20

# Loads the midi file, gets all notes from each channel, assigns the notes and the instrument
#  and channel to the player in the same ordinal position as the midi track.
# capture measures also gets all the measure boundaries and makes each a separate phrase which is
#  assigned to the player in sequence
import "composer_lang_ut.mid"
  capture measures
  players "Player 1", "Player 2"

# So this test should only show the note in Channel 1
play
  players "Player 1" 

write "composer_test_results.txt"
  players "Player 1", "Player 2"
}
  tester, results = test_runner(test_name, throw_on_failure, script, lite_syntax)
  actual = results        
  expected0 = 'instrument 1  start 4.00000  duration 4.00000  amplitude 100  pitch 64  channel 1 ; 0'
  tester.assert(expected0 == actual[0])
  puts tester.to_s

script = 
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__import_root_map_players

format midi

player "Player 1"
  channel 1
player "Player 2"
  channel 20

# Loads the midi file, gets all notes from each channel, assigns the notes and the instrument
#  and channel to the player in the same ordinal position as the midi track.
# capture measures also gets all the measure boundaries and makes each a separate phrase which is
#  assigned to the player in sequence
import "composer_lang_ut.mid"
  capture measures
  players "Player 1", "Player 2"

# So this test should only show the note in Channel 20
play
  players "Player 2" 

write "composer_test_results.txt"
  players "Player 1", "Player 2"
}
  tester, results = test_runner(test_name, throw_on_failure, script, lite_syntax)
  actual = results
  expected1 = 'instrument 20  start 4.00000  duration 4.00000  amplitude 100  pitch 65  channel 20 ; 1'
  tester.assert(expected1 == actual[0])
  puts tester.to_s
end


##################### /TESTS ########################

# Call each test in here
def run_tests(flags='run_all')    
  # TODO - shore this up someday
  # Right now just a way to run just the tests in the else block below
  # Should eventually be able to take a list of tests or 'all' or something like that
  run_only = false
  run_only = true if flags[0].include? 'run_only' or flags[0].include? 'run_selected'
    
  num_tests = 0
  if not run_only
  
    all_pass = true
    begin
      #
      test__comment ; num_tests += 1 
      test__stmt_note_with_name ; num_tests += 1 
      test__stmt_note_without_name ; num_tests += 1
      test__stmt_note_alt_syntax ; num_tests += 1
      test__phrase ; num_tests += 1
      test__phrase_alt_syntax ; num_tests += 1
      test__section ; num_tests += 1
      test__repeat_index ; num_tests += 1
      test__write_format_sections_phrases ; num_tests += 1
      test__render ; num_tests += 1
      test__phrase_lite_syntax ; num_tests += 1
      test__measure_lite_syntax ; num_tests += 1
      test__copy_measure_lite_syntax ; num_tests += 1
      test__section_lite_syntax ; num_tests += 1
      test__repeat_index_lite_syntax ; num_tests += 1
      test__sections_phrases_lite_syntax ; num_tests += 1
      test__assignment ; num_tests += 1
      test__assignment_comment ; num_tests += 1
      test__assignment_2 ; num_tests += 1
      test__repeat_until; num_tests += 1
      test__repeat_assignment ; num_tests += 1
      test__func ; num_tests += 1
      test__next ; num_tests += 1
      test__render_lite_syntax ; num_tests += 1
      test__meter_lite_syntax ; num_tests += 1
      test__tempo ; num_tests += 1
      test__tempo_default ; num_tests += 1
      test__ensemble ; num_tests += 1
      test__ensemble_phrase_play_players ; num_tests += 1
      test__ensemble_phrase_play_ensembles ; num_tests += 1
      test__instruction_players ; num_tests += 1
      test__instruction_players_ensembles ; num_tests += 1
      test__instruction_players_state ; num_tests += 1
      test__instruction_ensemble_state ; num_tests += 1
      test__improvise_player ; num_tests += 1
      test__improvise2_player ; num_tests += 1
      test__render_lite_syntax_default_write ; num_tests += 1
      test__phrase_midi_lite_syntax ; num_tests += 1
      test__phrase_midi_format_top ; num_tests += 1
      test__ensemble_instrument_channel_midi_render ; num_tests += 1
      test__phrase_midi_format_consts ; num_tests += 1
      test__phrase_csound_format_consts ; num_tests += 1
      test__player_instrument ; num_tests += 1
      test__no_start_auto_next ; num_tests += 1
      test__import_phrase ; num_tests += 1
      test__import_root_map_players; num_tests += 1
      
    rescue AleatoricTestException => e
      puts e.to_s
      all_pass = false
    end

  else # if run_only
    
    all_pass = true
    begin    
      
      # *** run_only TESTS GO HERE ***
      test__import_root_map_players; num_tests += 1
      # *** run_only TESTS GO HERE ***
    
    rescue AleatoricTestException => e      
      puts e.to_s
      all_pass = false
    end 
    
  end
  
  puts "\n\n***** composer_test: #{num_tests} run *****\n\n"
  if AleatoricTest.all_pass? and all_pass    
    puts "***** composer_test: ALL TESTS PASSED *****\n\n"
  else
    puts "***** composer_test: #{AleatoricTest.failed_tests.length} TESTS FAILED *****\n\n"
    AleatoricTest.failed_tests.each {|test| puts test}
    puts "\n\n"
  end
  puts "composer_lang_test: UNIT TESTING composer_lang\n\n"
end

run_tests ARGV