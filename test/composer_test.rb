# TODO Load from config
$LOAD_PATH << "c:\\projects\\aleatoric\\lib"
require 'composer'
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
  ret = []
  keywords = ["note"]
  stack = []
  script.each do |line|
    keywords.each do |kw|
      kw_bound = kw.length - 1
      line_len = line.strip.length
      # Current line starts with a keyword      
      if line[0..kw_bound] == kw
        stack.push kw
        line = line[0..line_len - 1] + " do\n"
      elsif line_len == 0
        cur_kw = stack.pop
        line = "end\n" if cur_kw != nil
      end
      ret << line
    end
  end  
  ret.join('')
end

def write_test_script(script, lite_syntax=false)
  # TODO Include this in composition.rb preprocessing of load() call
  # Read each line of script, and make necessary modifications to transform "almost Ruby" 
  #  input into legaly Ruby
  script = preprocess_script(script) if lite_syntax  
  # TODO Read from config  
  File.open("c:\\projects\\aleatoric\\test\\test.altc", "w") do |f|
    f << "module Aleatoric\n\n"  
    script.each do |line|
      f << line
    end    
    f << "\n\nend\n"
  end  
end

def run_test_script
  # TODO Read from config
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

def test__stmt_note_with_name
  throw_on_failure = false
  test_name = "test__stmt_note_with"
  
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

def test__stmt_note_with_name_lite_syntax
  throw_on_failure = false
  test_name = "test__stmt_note_with_name_lite_syntax"
  lite_syntax = true
  
  script = 
%Q{
note "note 1"
  instrument  1 
  start       0.0 
  duration    0.5
  amplitude   1000
  pitch       7.01
  func_table  1

  
# FOR TESTING ONLY
dump_last_note
}
  tester, results = test_runner(test_name, throw_on_failure, script, lite_syntax)
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
##################### /TESTS ########################

# Call each test in here
def run_tests
  test__stmt_note_with_name
  test__stmt_note_with_name_lite_syntax
  test__stmt_note_without_name
  test__phrase
  test__phrase_alt_syntax
  test__section
  test__repeat_index
  test__write_format_sections_phrases
  test__render
end

run_tests