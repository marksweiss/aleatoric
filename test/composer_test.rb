# TODO Load from config
$LOAD_PATH << "c:\\projects\\aleatoric\\lib"
require 'composer'
require 'composer_lang'
require 'thread'
include Aleatoric

class AleatoricTestException < Exception; end

class AleatoricTest
  def initialize(test_name, throw_on_failure=false)
    @test_name = test_name
    @throw_on_failure = throw_on_failure
    @s = "PASS: #{@test_name}"
  end
  
  def assert(assertion)
    @pass = (assertion == true)
    if not @pass
      if @throw_on_failure
        raise AleatoricTestException("FAILURE: #{@test_name}")
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
  ComposerAST.new(script).preprocess_script.to_s
end

@mutex = Mutex.new
def write_test_script(script, lite_syntax=false)
  # TODO Include this in composition.rb preprocessing of load() call
  # Read each line of script, and make necessary modifications to transform "almost Ruby" 
  #  input into legaly Ruby
  script = preprocess_script(script) if lite_syntax  

  # TEMP DEBUG
  # puts "\nAFTER preprocess"
  # puts script
  
  # TODO Read from config
  # NOTE !!!!!!!!!!!!!!!!!!!!!!!
  # We needed a mutex here to guard from multiple method calls writing to the same file
  #  even though each call comes from a separate function, which should complete
  #  operation before the next is called, and each call makes a single call to this function,
  #  and the docs promise that this syntax *closes the file* on block exit, and that block exit
  #  is clearly within the stack scope of the calling function.  i.e. - the Ruby File IO library
  #  has serious race condition concurrency problems and can't be trusted even in a single-threaded
  #  program with proper scoping of all calls, at least on 1.8.6 on Windows
  @mutex.lock
  File.open("c:\\projects\\aleatoric\\test\\test.altc", "w") do |f|
    f << "module Aleatoric\n\n"  
    script.each do |line|
      f << line
    end    
    f << "\n\nend\n"
  end 
  @mutex.unlock
end

def run_test_script
  load "c:\\projects\\aleatoric\\test\\test.altc"
end

def read_test_results
  # TODO Read from config
  results = File.readlines("c:\\projects\\aleatoric\\test\\composer_test_results.txt")
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
  expected = "i 1 0.000 0.500 1000 7.010 1 ; note 1"  
  tester.assert(expected == actual)
  puts tester.to_s  
end

def test__stmt_note_without_name
  throw_on_failure = false
  test_name = "test__stmt_note_without_name"
  
  script = 
%Q{
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
  expected = 'i 1 0.000 0.500 1000 7.010 1 ;'  
  tester.assert(expected == actual)
  puts tester.to_s  
end

def test__phrase
  throw_on_failure = false
  test_name = "test__phrase"
  script = 
%Q{
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
  expected0 = 'i 1 0.000 0.500 1000 7.010 1 ; 1'
  expected1 = 'i 1 1.000 1.000 1100 7.020 1 ; 2'
  tester.assert(expected0 == actual[0])
  tester.assert(expected1 == actual[1])
  puts tester.to_s  
end

def test__phrase_alt_syntax
  throw_on_failure = false
  test_name = "test__phrase_alt_syntax"
  script = 
%Q{
phrase "Stuff in the Middle" do
  note "3" do instrument 1; start 2.0; duration 0.5; amplitude 1000; pitch 7.03; func_table 1 end
  note "4" do instrument 1; start 3.0; duration 0.5; amplitude 1000; pitch 7.04; func_table 1 end
end

# FOR TESTING ONLY    
dump_last_phrase
}
  tester, results = test_runner(test_name, throw_on_failure, script)
  actual = results
  expected0 = 'i 1 2.000 0.500 1000 7.030 1 ; 3'
  expected1 = 'i 1 3.000 0.500 1000 7.040 1 ; 4'
  tester.assert(expected0 == actual[0])
  tester.assert(expected1 == actual[1])
  puts tester.to_s  
end
  
def test__section
  throw_on_failure = false
  test_name = "test__section"
  script = 
%Q{
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
  expected0 = 'i 1 0.000 0.500 1000 7.010 1 ; 1'
  expected1 = 'i 1 1.000 1.000 1100 7.020 1 ; 2'
  tester.assert(expected0 == actual[0])
  tester.assert(expected1 == actual[1])
  puts tester.to_s  
end

def test__repeat_index
  throw_on_failure = false
  test_name = "test__repeat_index"
  script = 
%Q{
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
  expected0 = 'i 1 1.000 0.200 1100 7.020 1 ;'
  expected1 = 'i 1 2.000 0.200 1200 7.020 1 ;'
  tester.assert(expected0 == actual[0])
  tester.assert(expected1 == actual[1])
  puts tester.to_s  
end

def test__write_format_sections_phrases
  throw_on_failure = false
  test_name = "test__write_format_sections_phrases"
  script = 
%Q{
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

# TODO From config
write "composer_test_results.txt" do
  format    csound
  sections  "Intro Section"
  phrases   "Coda", "Loop"
end
}
  tester, results = test_runner(test_name, throw_on_failure, script)
  actual = results
  expected0 = 'i 1 0.000 0.500 1000 7.010 1 ; 1'
  expected1 = 'i 1 1.000 1.000 1100 7.020 1 ; 2'
  expected2 = 'i 1 0.000 0.500 1000 7.010 1 ; 3'
  expected3 = 'i 1 1.000 1.000 1100 7.020 1 ; 4'
  expected4 = 'i 1 1.000 0.200 1100 7.020 1 ;'
  expected5 = 'i 1 2.000 0.200 1200 7.020 1 ;'
  tester.assert(expected0 == actual[2])
  tester.assert(expected1 == actual[3])
  tester.assert(expected2 == actual[5])
  tester.assert(expected3 == actual[6])
  tester.assert(expected4 == actual[7])
  tester.assert(expected5 == actual[8])
  puts tester.to_s  
end

def test__render
  throw_on_failure = false
  test_name = "test__render"
  script = 
%Q{
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

# TODO From config
write '..\\lib\\composer_test_results.txt' do
  format    csound
  sections  "Intro Section"
  phrases   "Coda", "Loop"
end

render '..\\lib\\composer_test.wav' do
  orchestra  '..\\lib\\markov_opt_1.orc'
end
}
  tester, results = test_runner(test_name, throw_on_failure, script)
  tester.assert(File.size("C:\\projects\\aleatoric\\lib\\composer_test.wav") > 0)
  puts tester.to_s  
end

def test__phrase_lite_syntax
  throw_on_failure = false
  lite_syntax = true
  test_name = "test__phrase_lite_syntax"
  script = 
%Q{
# TESTING PURPOSES ONLY
reset_script_state

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

write %q{c:\\projects\\aleatoric\\test\\composer_test_results.txt}
  format    csound
  phrases   "Intro Phrase"
}
  tester, results = test_runner(test_name, throw_on_failure, script, lite_syntax)
  actual = results
  
  expected0 = 'i 1 0.000 0.500 1000 7.010 1 ; 1'
  expected1 = 'i 1 1.000 1.000 1100 7.020 1 ; 2'
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

write %q{c:\\projects\\aleatoric\\test\\composer_test_results.txt}
  format    csound
  sections   "Intro Section"
}
  tester, results = test_runner(test_name, throw_on_failure, script, lite_syntax)
  actual = results
  
  # TEMP DEBUG
  # puts actual
  
  expected0 = 'i 3 0.000 0.500 1000 7.030 1 ; 3'
  expected1 = 'i 4 1.000 1.000 1100 7.040 1 ; 4'
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

section "Intro Section"
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

  phrase "Coda"
    note "3"
      instrument  1 
      start       0.0 
      duration    0.5
      amplitude   1000
      pitch       7.01
      func_table  1

    note "4"
      instrument  1
      start       1.0 
      duration    1.0
      amplitude   1100
      pitch       7.02
      func_table  1

# TODO From config
write %q{c:\\projects\\aleatoric\\test\\composer_test_results.txt}
  format    csound
  sections  "Intro Section"
}
  tester, results = test_runner(test_name, throw_on_failure, script, lite_syntax)
  actual = results
  expected0 = 'i 1 0.000 0.500 1000 7.010 1 ; 1'
  expected1 = 'i 1 1.000 1.000 1100 7.020 1 ; 2'
  expected2 = 'i 1 0.000 0.500 1000 7.010 1 ; 3'
  expected3 = 'i 1 1.000 1.000 1100 7.020 1 ; 4'
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

phrase "Loop"
  repeat 2
    note
      instrument 1
      start       1.0 * index
      duration    0.2
      amplitude   1000 + (100 * index) 
      pitch       7.02
      func_table  1
      
# TODO From config
write %q{c:\\projects\\aleatoric\\test\\composer_test_results.txt}
  format    csound
  phrases   "Loop"
}
  tester, results = test_runner(test_name, throw_on_failure, script, lite_syntax)
  actual = results
  expected0 = 'i 1 1.000 0.200 1100 7.020 1 ;'
  expected1 = 'i 1 2.000 0.200 1200 7.020 1 ;'
  tester.assert(expected0 == actual[2])
  tester.assert(expected1 == actual[3])
  puts tester.to_s  
end
##################### /TESTS ########################

# Call each test in here
def run_tests
  # test__stmt_note_with_name
  # test__stmt_note_without_name
  # test__phrase
  # test__phrase_alt_syntax
  # test__section
  # test__repeat_index
  # test__write_format_sections_phrases
  # test__render
  
  test__phrase_lite_syntax
  test__section_lite_syntax
  test__sections_phrases_lite_syntax
  test__repeat_index_lite_syntax
end

run_tests