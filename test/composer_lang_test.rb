# TODO Load from config
$LOAD_PATH << "..\\lib"
require 'composer'
require 'composer_lang'
require 'test/unit'

# Super-elegant solution for temporarily getting access to private methods to test stolen from here:
#  http://blog.jayfields.com/2007/11/ruby-testing-private-methods.html
class Class
  def publicize_methods
    saved_private_instance_methods = self.private_instance_methods
    self.class_eval {public(*saved_private_instance_methods)}
    yield
    self.class_eval {private(*saved_private_instance_methods)}
  end
end
# Used like this
# Put all calls against the class to be tested in a block in a call to publicize_methods()
# The code above thus wraps the execution of that block, which runs on the yield above
# But first we class_eval() all the private methods in the class and make them public
# Then make them private again after the yield
#
#class Ninja
#  private
#  def kill(num_victims)
#    "#{num_victims} victims are no longer with us."
#  end
#end

#unit_tests do
#  test "kill returns a murder string" do
#    Ninja.publicize_methods do
#      assert_equal '3 victims are no longer with us.', Ninja.new.kill(3)
#    end
#  end
#end

module Aleatoric

class ComposerAST_Test < Test::Unit::TestCase
  # def setup
  # end
  # def teardown
  # end
  
  puts "TESTING Class ComposerAST"
    
  def test__append_completion
    puts "test__append_completion ENTERED"   
    ComposerAST.publicize_methods do
    
    script = ''
    lang = ComposerAST.new(script)
    
    kw = 'note'; expr = 'note'
    assert(lang.append_completion(kw, expr) == "note do\n")
    kw = 'note'; expr = 'note "Note 1"'
    assert(lang.append_completion(kw, expr) == "note \"Note 1\" do\n")
    kw = 'phrase'; expr = 'phrase "Phrase 1"'
    assert(lang.append_completion(kw, expr) == "phrase \"Phrase 1\" do\n")
    kw = 'section'; expr = 'section "Section 1"'
    assert(lang.append_completion(kw, expr) == "section \"Section 1\" do\n")
    kw = 'repeat'; expr = 'repeat 20'
    assert(lang.append_completion(kw, expr) == "repeat 20 do |index|\n")
    kw = 'write'; expr = 'write "In C.sco"'
    assert(lang.append_completion(kw, expr) == "write \"In C.sco\" do\n")
    kw = 'render'; expr = 'render "In C.wav"'
    assert(lang.append_completion(kw, expr) == "render \"In C.wav\" do\n")
    kw = 'format'; expr = 'format csound'
    assert(lang.append_completion(kw, expr) == "format csound\n")
    kw = ''; expr = 'some other random line'
    assert(lang.append_completion(kw, expr) == "some other random line\n")
    
    end
    puts "test__append_completion COMPLETED"
  end
 
  def test__kw?
    puts "test__kw? ENTERED"   
    ComposerAST.publicize_methods do
    
    script = ''
    lang = ComposerAST.new(script)
    
    expr = 'note'    
    actual1, actual2 = lang.kw?(expr)
    assert(actual1 == true && actual2 == 'note')

    expr = 'note "Note 1"'    
    actual1, actual2 = lang.kw?(expr)
    assert(actual1 == true && actual2 == 'note')

    expr = 'phrase "Phrase 1"'    
    actual1, actual2 = lang.kw?(expr)
    assert(actual1 == true && actual2 == 'phrase')
    
    expr = 'section "Section 1"'    
    actual1, actual2 = lang.kw?(expr)
    assert(actual1 == true && actual2 == 'section')

    expr = 'repeat 20'    
    actual1, actual2 = lang.kw?(expr)
    assert(actual1 == true && actual2 == 'repeat')

    expr = 'write "In C.sco"'    
    actual1, actual2 = lang.kw?(expr)
    assert(actual1 == true && actual2 == 'write')
    
    expr = 'render "In C.wav"'    
    actual1, actual2 = lang.kw?(expr)
    assert(actual1 == true && actual2 == 'render')

    expr = 'format csound'    
    actual1, actual2 = lang.kw?(expr)
    assert(actual1 == true && actual2 == 'format')

    expr = 'some other random line'    
    actual1, actual2 = lang.kw?(expr)
    assert(actual1 == false && actual2 == nil)
    
    end
    puts "test__kw? COMPLETED"
  end
  
  def test__integer?
    puts "test__integer? ENTERED"   
    ComposerAST.publicize_methods do
    
    script = ''
    lang = ComposerAST.new(script)  
    
    actual1, actual2 = lang.integer? nil    
    assert(actual1 == false && actual2 == nil)
    actual1, actual2 = lang.integer? 1.5    
    assert(actual1 == false && actual2 == nil)
    actual1, actual2 = lang.integer? "1.5"
    assert(actual1 == false && actual2 == nil)
    actual1, actual2 = lang.integer? "hello"
    assert(actual1 == false && actual2 == nil)
    actual1, actual2 = lang.integer? 1    
    assert(actual1 == true && actual2 == 1)
    actual1, actual2 = lang.integer? -12332
    assert(actual1 == true && actual2 == -12332)
    actual1, actual2 = lang.integer? +12332
    assert(actual1 == true && actual2 == +12332)
    actual1, actual2 = lang.integer? "-12332"
    assert(actual1 == true && actual2 == -12332)
    
    end
    puts "test__integer? COMPLETED"  
  end
  
  def test__valid_kw_arg?
    puts "test__valid_kw_arg? ENTERED"   
    ComposerAST.publicize_methods do
    
    script = ''
    lang = ComposerAST.new(script)
    
    kw = 'note'; expr = 'note'    
    actual1, actual2 = lang.valid_kw_arg?(kw, expr)    
    assert(actual1 == true && actual2 == nil)
    
    kw = 'note'; expr = 'note "Note 1"'    
    actual1, actual2 = lang.valid_kw_arg?(kw, expr)    
    assert(actual1 == true && actual2 == '"Note 1"')

    kw = 'note'; expr = 'note 1'    
    actual1, actual2 = lang.valid_kw_arg?(kw, expr)    
    assert(actual1 == false)    
 
    kw = 'phrase'; expr = 'phrase "Phrase 1"'    
    actual1, actual2 = lang.valid_kw_arg?(kw, expr)    
    assert(actual1 == true && actual2 == '"Phrase 1"')

    kw = 'phrase'; expr = 'phrase 1'    
    actual1, actual2 = lang.valid_kw_arg?(kw, expr)    
    assert(actual1 == false)

    kw = 'section'; expr = 'section "Section 1"'    
    actual1, actual2 = lang.valid_kw_arg?(kw, expr)    
    assert(actual1 == true && actual2 == '"Section 1"')

    kw = 'section'; expr = 'section 1'    
    actual1, actual2 = lang.valid_kw_arg?(kw, expr)    
    assert(actual1 == false)

    kw = 'repeat'; expr = 'repeat'    
    actual1, actual2 = lang.valid_kw_arg?(kw, expr)    
    assert(actual1 == false)

    kw = 'repeat'; expr = 'repeat "1"'    
    actual1, actual2 = lang.valid_kw_arg?(kw, expr)    
    assert(actual1 == false)
    
    kw = 'repeat'; expr = 'repeat 1'    
    actual1, actual2 = lang.valid_kw_arg?(kw, expr)    
    assert(actual1 == true && actual2 == 1)

    kw = 'render'; expr = 'render'    
    actual1, actual2 = lang.valid_kw_arg?(kw, expr)    
    assert(actual1 == false)

    kw = 'render'; expr = 'render 100'    
    actual1, actual2 = lang.valid_kw_arg?(kw, expr)    
    assert(actual1 == false)
    
    kw = 'render'; expr = 'render "In C.sco"'    
    actual1, actual2 = lang.valid_kw_arg?(kw, expr)    
    assert(actual1 == true && actual2 == '"In C.sco"')     
 
    kw = 'write'; expr = 'write'    
    actual1, actual2 = lang.valid_kw_arg?(kw, expr)    
    assert(actual1 == false)

    kw = 'write'; expr = 'write 100'    
    actual1, actual2 = lang.valid_kw_arg?(kw, expr)    
    assert(actual1 == false)
    
    kw = 'write'; expr = 'write "In C.wav"'    
    actual1, actual2 = lang.valid_kw_arg?(kw, expr)    
    assert(actual1 == true && actual2 == '"In C.wav"') 
    
    end
    puts "test__valid_kw_arg? COMPLETED"
  end  
  
  # TODO
  def test__valid_child_kw?
    puts "test__valid_child_kw? ENTERED"   
    ComposerAST.publicize_methods do
        
    end
    puts "test__valid_child_kw? COMPLETED"
  end

  # TODO
  def test__valid_child_kw?
    puts "test__valid_child_kw? ENTERED"   
    ComposerAST.publicize_methods do
        
    end
    puts "test__valid_child_kw? COMPLETED"
  end

  # TODO
  def test__valid_root?
    puts "test__valid_root? ENTERED"   
    ComposerAST.publicize_methods do
        
    end
    puts "test__valid_root? COMPLETED"
  end
  
  # TODO
  def test__valid_grammar?
    puts "test__valid_grammar? ENTERED"   
    ComposerAST.publicize_methods do
        
    end
    puts "test__valid_grammar? COMPLETED"
  end
  
end    
  
# /Note and NoteTest #######################

end  
#/CSnd Module



