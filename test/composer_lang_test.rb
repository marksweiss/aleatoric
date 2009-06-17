$LOAD_PATH << "..\\lib"
require 'composer_lang'
require 'test/unit'
require 'rubygems'
require 'ruby-debug' ; Debugger.start

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
    
#  def test__append_completion
#    puts "test__append_completion ENTERED"   
#    ComposerAST.publicize_methods do
    
#    script = ''
#    lang = ComposerAST.new
    
#    kw = 'note'; expr = 'note'
#    assert(lang.append_completion(kw, expr) == "note do\n")
#    kw = 'note'; expr = 'note "Note 1"'
#    assert(lang.append_completion(kw, expr) == "note \"Note 1\" do\n")
#    kw = 'phrase'; expr = 'phrase "Phrase 1"'
#    assert(lang.append_completion(kw, expr) == "phrase \"Phrase 1\" do\n")
#    kw = 'section'; expr = 'section "Section 1"'
#    assert(lang.append_completion(kw, expr) == "section \"Section 1\" do\n")
#    kw = 'repeat'; expr = 'repeat 20'
#    assert(lang.append_completion(kw, expr) == "repeat 20 do |index|\n")
#    kw = 'write'; expr = 'write "In C.sco"'
#    assert(lang.append_completion(kw, expr) == "write \"In C.sco\" do\n")
#    kw = 'render'; expr = 'render "In C.wav"'
#    assert(lang.append_completion(kw, expr) == "render \"In C.wav\" do\n")
#    kw = 'format'; expr = 'format csound'
#    assert(lang.append_completion(kw, expr) == "format csound\n")
#    kw = ''; expr = 'some other random line'
#    assert(lang.append_completion(kw, expr) == "some other random line\n")
    
#    end
#    puts "test__append_completion COMPLETED"
#  end
 
  def test__kw?
    puts "test__kw? ENTERED"   
    ComposerAST.publicize_methods do
    
    script = ''
    lang = ComposerAST.new
    
    expr = 'note'    
    actual1, actual2 = lang.kw?(expr)
    assert(actual1 == true && actual2 == 'note')

    expr = 'phrase'    
    actual1, actual2 = lang.kw?(expr)
    assert(actual1 == true && actual2 == 'phrase')
    
    expr = 'section'    
    actual1, actual2 = lang.kw?(expr)
    assert(actual1 == true && actual2 == 'section')

    expr = 'repeat'    
    actual1, actual2 = lang.kw?(expr)
    assert(actual1 == true && actual2 == 'repeat')

    expr = 'write'    
    actual1, actual2 = lang.kw?(expr)
    assert(actual1 == true && actual2 == 'write')
    
    expr = 'render'    
    actual1, actual2 = lang.kw?(expr)
    assert(actual1 == true && actual2 == 'render')

    expr = 'format'    
    actual1, actual2 = lang.kw?(expr)
    assert(actual1 == true && actual2 == 'format')

    expr = 'def'    
    actual1, actual2 = lang.kw?(expr)
    assert(actual1 == true && actual2 == 'def')    
    
    expr = 'NOT_A_KEYWORD'    
    actual1, actual2 = lang.kw?(expr)
    assert(actual1 == false && actual2 == nil)
    
    end
    puts "test__kw? COMPLETED"
  end
  
  def test__integer?
    puts "test__integer? ENTERED"   
    ComposerAST.publicize_methods do
    
    script = ''
    lang = ComposerAST.new  
    
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
    lang = ComposerAST.new

    kw = 'note'; expr = ['note']    
    actual = lang.valid_kw_arg?(kw, expr)    
    assert(actual == true)
    
    kw = 'note'; expr = ['note', '"Note 1"']    
    actual = lang.valid_kw_arg?(kw, expr)    
    assert(actual == true)

    kw = 'note'; expr = ['note', '1']    
    actual = lang.valid_kw_arg?(kw, expr)    
    assert(actual == false)    
 
    kw = 'phrase'; expr = ['phrase', '"Phrase 1"']    
    actual = lang.valid_kw_arg?(kw, expr)    
    assert(actual == true)

    kw = 'phrase'; expr = ['phrase', '1']   
    actual = lang.valid_kw_arg?(kw, expr)    
    assert(actual == false)

    kw = 'section'; expr = ['section', '"Section 1"']  
    actual = lang.valid_kw_arg?(kw, expr)    
    assert(actual == true)

    kw = 'section'; expr = ['section', '1']   
    actual = lang.valid_kw_arg?(kw, expr)    
    assert(actual == false)

    kw = 'repeat'; expr = ['repeat']    
    actual = lang.valid_kw_arg?(kw, expr)    
    assert(actual == false)

    kw = 'repeat'; expr = ['repeat', '"1"']    
    actual = lang.valid_kw_arg?(kw, expr)    
    assert(actual == false)
    
    kw = 'repeat'; expr = ['repeat', '1']    
    actual = lang.valid_kw_arg?(kw, expr)    
    assert(actual == true)

    kw = 'render'; expr = ['render']    
    actual = lang.valid_kw_arg?(kw, expr)    
    assert(actual == false)

    kw = 'render'; expr = ['render', '100']    
    actual = lang.valid_kw_arg?(kw, expr)    
    assert(actual == false)
    
    kw = 'render'; expr = ['render', '"In C.sco"']    
    actual = lang.valid_kw_arg?(kw, expr)    
    assert(actual == true)     
 
    kw = 'write'; expr = ['write']    
    actual = lang.valid_kw_arg?(kw, expr)    
    assert(actual == false)

    kw = 'write'; expr = ['write', '100']    
    actual = lang.valid_kw_arg?(kw, expr)    
    assert(actual == false)
    
    kw = 'write'; expr = ['write', '"In C.wav"']    
    actual = lang.valid_kw_arg?(kw, expr)    
    assert(actual == true) 
    
    kw = 'def'; expr = ['def', 'start_f(factor, idx)']    
    actual = lang.valid_kw_arg?(kw, expr)    
    assert(actual == true)    
       
    end
    puts "test__valid_kw_arg? COMPLETED"
  end  
  
  def test__root?
    puts "test__valid_child_kw? ENTERED"   
    ComposerAST.publicize_methods do
		
    lang = ComposerAST.new
		assert(lang.root?(lang.root))
        
    end
    puts "test__valid_child_kw? COMPLETED"
  end
  
  def test__valid_child_kw?
    puts "test__valid_child_kw? ENTERED"   
    ComposerAST.publicize_methods do
    
    script = ''
    lang = ComposerAST.new		
		
		# parent == 'root'
    assert(lang.valid_child_kw?('root', 'note'))
    assert(lang.valid_child_kw?('root', 'phrase')) 
    assert(lang.valid_child_kw?('root', 'section'))
    assert(lang.valid_child_kw?('root', 'repeat'))
    assert(lang.valid_child_kw?('root', 'write'))
    assert(lang.valid_child_kw?('root', 'render'))
    assert(! lang.valid_child_kw?('root', 'format'))
		
		# parent == 'note'
    assert(! lang.valid_child_kw?('note', 'note'))
    assert(! lang.valid_child_kw?('note', 'phrase')) 
    assert(! lang.valid_child_kw?('note', 'section'))
    assert(! lang.valid_child_kw?('note', 'repeat'))
    assert(! lang.valid_child_kw?('note', 'write'))
    assert(! lang.valid_child_kw?('note', 'render'))		
    assert(! lang.valid_child_kw?('note', 'format'))		

		# parent == 'phrase'
    assert(lang.valid_child_kw?('phrase', 'note'))
    assert(! lang.valid_child_kw?('phrase', 'phrase')) 
    assert(! lang.valid_child_kw?('phrase', 'section'))
    assert(lang.valid_child_kw?('phrase', 'repeat'))
    assert(! lang.valid_child_kw?('phrase', 'write'))
    assert(! lang.valid_child_kw?('phrase', 'render'))
    assert(! lang.valid_child_kw?('phrase', 'format'))

		# parent == 'section'
    assert(! lang.valid_child_kw?('section', 'note'))
    assert(lang.valid_child_kw?('section', 'phrase')) 
    assert(! lang.valid_child_kw?('section', 'section'))
    assert(! lang.valid_child_kw?('section', 'repeat'))
    assert(! lang.valid_child_kw?('section', 'write'))
    assert(! lang.valid_child_kw?('section', 'render'))
    assert(! lang.valid_child_kw?('section', 'format'))
		
		# parent == 'repeat'
    assert(lang.valid_child_kw?('repeat', 'note'))
    assert(! lang.valid_child_kw?('repeat', 'phrase')) 
    assert(! lang.valid_child_kw?('repeat', 'section'))
    assert(! lang.valid_child_kw?('repeat', 'repeat'))
    assert(! lang.valid_child_kw?('repeat', 'write'))
    assert(! lang.valid_child_kw?('repeat', 'render'))
    assert(! lang.valid_child_kw?('repeat', 'format'))
		
		# parent == 'write'
    assert(! lang.valid_child_kw?('write', 'note'))
    assert(! lang.valid_child_kw?('write', 'phrase')) 
    assert(! lang.valid_child_kw?('write', 'section'))
    assert(! lang.valid_child_kw?('write', 'repeat'))
    assert(! lang.valid_child_kw?('write', 'write'))
    assert(! lang.valid_child_kw?('write', 'render'))		
    assert(lang.valid_child_kw?('write', 'format'))

		# parent == 'render'
    assert(! lang.valid_child_kw?('render', 'note'))
    assert(! lang.valid_child_kw?('render', 'phrase')) 
    assert(! lang.valid_child_kw?('render', 'section'))
    assert(! lang.valid_child_kw?('render', 'repeat'))
    assert(! lang.valid_child_kw?('render', 'write'))
    assert(! lang.valid_child_kw?('render', 'render'))
    assert(! lang.valid_child_kw?('render', 'format'))

		# parent == 'format'
    assert(! lang.valid_child_kw?('format', 'note'))
    assert(! lang.valid_child_kw?('format', 'phrase')) 
    assert(! lang.valid_child_kw?('format', 'section'))
    assert(! lang.valid_child_kw?('format', 'repeat'))
    assert(! lang.valid_child_kw?('format', 'write'))
    assert(! lang.valid_child_kw?('format', 'render'))
    assert(! lang.valid_child_kw?('format', 'format'))
		
    end
    puts "test__valid_child_kw? COMPLETED"
  end

  def test__tokenize
    puts "test__tokenize ENTERED"   
    ComposerAST.publicize_methods do
		
    lang = ComposerAST.new

    actual = lang.tokenize("foo: a, b, c\n")    
    expected = [['foo:', 'a', ',', 'b', ',', 'c']]
    assert(actual == expected)

    actual = lang.tokenize("instrument foo: a, b, c\n")
    expected = [['instrument', 'foo:', 'a', ',', 'b', ',', 'c']]
    assert(actual == expected)
    
    actual = lang.tokenize("instrument 100\n")
    expected = [['instrument', '100']]
    assert(actual == expected)

    actual = lang.tokenize("note \"intro\"\n")    
    expected = [['note', '"intro"']]
    assert(actual == expected)

    actual = lang.tokenize("instrument 100*5+2; amplitude 200\n")
    expected = [['instrument', '100', '*', '5', '+', '2', ';', 'amplitude', '200']]
    assert(actual == expected)

    actual = lang.tokenize("note \"Note 1\"\n")
    expected = [['note', '"Note 1"']]
    assert(actual == expected)
    
    end
    puts "test__tokenize COMPLETED"  
  end  
  
  def test__preprocess_func_helper
    puts "test__preprocess_func_helper ENTERED"   
    ComposerAST.publicize_methods do
		
    lang = ComposerAST.new

    actual = lang.preprocess_func_helper(lang.tokenize("foo: a, b, c\n")[0])        
    expected = ['def', 'foo(', 'a', ',', 'b', ',', 'c', ')']    
    assert(actual == expected)
    
    actual = lang.preprocess_func_helper(lang.tokenize('foo: a, b, bar: c, d')[0])
    expected = ['def', 'foo(', 'a', ',', 'b', ',', 'bar(', 'c', ',', 'd', ')', ')']  
    assert(actual == expected)    

    actual = lang.preprocess_func_helper(lang.tokenize('foo: a, b, bar: c, baz: d')[0])    
    expected = ['def', 'foo(', 'a', ',', 'b', ',', 'bar(', 'c', ',', 'baz(', 'd', ')', ')', ')']  
    assert(actual == expected)

    actual = lang.preprocess_func_helper(lang.tokenize('instrument foo: a, b, bar: c, baz: d')[0])
    expected = ['instrument', 'foo(', 'a', ',', 'b', ',', 'bar(', 'c', ',', 'baz(', 'd', ')', ')', ')']  
    assert(actual == expected)
    
    actual = lang.preprocess_func_helper(lang.tokenize('instrument 1, 2, 3')[0])    
    expected = ['instrument', '1', ',', '2', ',', '3']  
    assert(actual == expected)    
    
    end
    puts "test__preprocess_func_helper COMPLETED"  
  end  
  
end   

end
