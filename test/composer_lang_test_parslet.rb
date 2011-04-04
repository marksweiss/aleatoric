require 'rubygems'
require 'ruby-debug'
require 'pp'
require 'rspec'
require 'parslet'
require 'parslet/rig/rspec'

class BasicParser < Parslet::Parser

  # White space, define for exp rules to use for tokenization
  rule(:sp) { match('\s').repeat(1) }
  rule(:sp?) { sp.maybe }
  # Line handling
  rule(:line_end) { str('\n') | str('\r\n') }
  rule(:eol) { sp? >> line_end } #.repeat(1, 1) } .repeat(1)
  rule (:eol?) { eol.maybe }  
  # Delimiters  
  rule(:delim) { sp | eol }
  rule(:delim?) { delim.maybe }

  # Primitive/scalar types
  # NOTE: repeat(1) means 1 or more.  repeat signature is repeat(min=nil, max=nil)
  #  where min and max are number of times repeat must match, and nil for max
  #  means any number of times.  Hence repeat(1) is min=1, max=nil == one or more times
  rule(:integer) { ((str('+') | str('-')).maybe >> match('[0-9]').repeat(1)).as(:integer) }

  rule(:float) { 
   ((str('+') | str('-')).maybe >> match('[0-9]').repeat(1) >> 
   str('.') >> 
   match('[0-9]').repeat(1)).as(:float)
  }

  rule(:string) {
    (str('"') >> 
    (str('\\') >> any | 
    str('"').absnt? >> any).repeat >> 
    str('"')).as(:string)
  }
  
end


# TODO Move to its own source file
class ComposerParser < BasicParser
  
  REQ_NOTE_ATTRS = ['instrument', 'start', 'duration', 'amplitude', 'pitch']
  
  # Keywords/Expressions
  rule(:name) { string.as(:name) }
  
  rule(:func_name) { match('[A-Za-z0-9|_]').repeat(1) }
  rule(:udf_call) { func_name >> str(':') >> (sp >> arg_list).maybe }
  rule(:udf_call_stmt) { sp? >> udf_call >> eol.as(:udf_call_stmt) }
  rule(:udf_call_arg) { str('(') >> udf_call >> str(')') }

  # float must come first in alternation or matching int breaks float
  rule(:arg) { (float | integer | string | udf_call_arg).as(:arg) }
  rule(:arg_list) { (sp? >> arg >> (sp? >> str(',') >> sp? >> arg).repeat(0)).as(:arg_list) }
  rule(:arg_list?) { arg_list.maybe.as(:arg_list?) }
      
  rule(:kw_note) { str('note').as(:kw_note) }
  rule(:kw_note_stmt) { (sp? >> kw_note >> (sp >> name).maybe >> eol ).as(:kw_note_stmt) } # >> eol  

  # TODO support aliased names, e.g. 'volume' for 'amplitude'
  rule(:kw_note_attr) { 
    (sp? >> 
      (str('instrument') | 
      str('start') | 
      str('duration') | 
      str('amplitude') | 
      str('pitch') | 
      func_name)).
    as(:kw_note_attr) 
  }
  rule(:kw_note_attr_stmt) {
    (kw_note_attr >> (sp >> arg_list).maybe >> eol).as(:kw_note_attr_stmt)
  }

  rule(:kw_note_blk) {
    
    # breakpoint
    
    # TODO Validate that expected five minimum attributes are present
    # 'instrument', 'start', 'duration', 'amplitude', 'pitch'
    # NOTE: using #repeat() makes the entire concatenated expression
    #  return a Parslet sequence: ["note 'note 1 do\n", "insrument 1\n", etc.]
    (kw_note_stmt >> kw_note_attr_stmt.repeat(5)).as(:kw_note_blk)
  }

  # Begin parse at root() rule
  root(:kw_note_stmt)    
end


# Transformer Helper Methods
# TODO Move into 'lib' for my wrap of Parslet test framework
# Free functions in module scope, so they can be called with lower-case
#  syntax matching the rule names in Parser, sp, eol, etc., and are in scope
#  inside any @xform.rule() in any Transformer, and within any RSpec Transform test
def sp
 ' '
end

def eol
  '\n'
end

def blk_open
  'do'
end

def blk_close
  'end'
end


class ComposerProcessor # < BasicTransformer
  include Parslet
  
  attr_reader :xform
         
  def initialize
    @xform = Parslet::Transform.new
    @validate = Parslet::Validate.new
            
    # Primitive and scalar types, output their value
    @xform.rule(:integer => simple(:i)) { Integer(i.to_s.strip) }
    @xform.rule(:float => simple(:f))  { Float(f.to_s.strip) }
    @xform.rule(:string => simple(:s))  { s.strip }      

    @xform.rule(:arg => simple(:arg)) { arg }
    @xform.rule(:arg_list => sequence(:args)) { 
      ret = ''
      if args.length > 0
        ret += args[0].to_s
        (1..args.length-1).each { |j|
          ret += (', ' + args[j].to_s)
        }
      end
      ret
    }
    
    # Keyword Expressions
    @xform.rule(:kw_note_stmt => subtree(:stmt)) {       
      stmt[:kw_note] + sp + stmt[:name] + sp + blk_open + eol 
    }
    @xform.rule(:kw_note_attr_stmt => subtree(:stmt)) {         
      stmt[:kw_note_attr] + sp + stmt[:arg_list].to_s + eol
    }
    
    @validate.rule(:kw_note_blk => subtree(:stmt)) {      
      # Sequence is the 'note' stmt and then the attribute statements
      # Structure of each note attr subtree looks like this:
      # {:kw_note_attr_stmt=>{:kw_note_attr=>"instrument", :arg_list=>{:arg=>{:integer=>"1"}}}}
      # So values gets each child map with the kw_note_attr and arg_list keys
      #   and [ ] then gets the value for the kw_note_attr key
      attrs = stmt[1..stmt.length].collect {|e| e.values[0][:kw_note_attr].strip}      
      # Now test the attrs, list against the required attrs list using set difference      
      (ComposerParser::REQ_NOTE_ATTRS - attrs).empty?
    }
    @xform.rule(:kw_note_blk => sequence(:stmt)) {
      ret = stmt.join + blk_close + eol 
      ret
    }
    
  end

  def validate(tree)
    @validate.validate(tree)
  end
  def transform(tree)
    @xform.apply(tree)
  end
end


######### Parser TESTS ##########

# WS, EOL, Delimiters

describe ComposerParser do
  let(:parser) { ComposerParser.new }
  context 'eol' do
    it 'should consume \n' do
      parser.eol.should parse('\n')
    end 
  end
end

# Literals
describe ComposerParser do
  let(:parser) { ComposerParser.new }
  context 'integer' do
    it 'should consume 100' do
      parser.integer.should parse('100')
    end 
  end
end

describe ComposerParser do
  let(:parser) { ComposerParser.new }
  context 'float' do
    it 'should consume -100.001' do
      parser.float.should parse('-100.001', :trace => true)
    end 
  end
end

describe ComposerParser do
  let(:parser) { ComposerParser.new }
  context 'string' do
    it 'should consume " sfdkj3432#$#$@"' do
      parser.string.should parse('" sfdkj3432#$#$@"')
    end 
  end
end

# Keyword Terminals

describe ComposerParser do
  let(:parser) { ComposerParser.new }
  context 'kw_note' do
    it 'should consume note' do
      parser.kw_note.should parse('note')
    end 
  end
end

# Terminals

# "name"
describe ComposerParser do
  let(:parser) { ComposerParser.new }
  context 'name' do
    it 'should consume "my_name"' do
      parser.name.should parse('"my_name"')
    end 
  end
end

# func_name
describe ComposerParser do
  let(:parser) { ComposerParser.new }
  context 'func_name' do
    it 'should consume _my_name123' do
      parser.func_name.should parse('_my_name123')
    end 
  end
end

# arg
describe ComposerParser do
  let(:parser) { ComposerParser.new }
  context 'arg' do
    it 'should consume "my_name"' do
      parser.arg.should parse('"my_name"')
    end
    it 'should consume 42' do
      parser.arg.should parse('42')
    end
    it 'should consume 9.42' do
      parser.arg.should parse('9.42')
    end 
  end
end

# arg_list
describe ComposerParser do
  let(:parser) { ComposerParser.new }
  context 'arg_list?' do
    it 'should consume -9.42' do
      parser.arg_list?.should parse('-9.42')
    end 
    it 'should consume "my_arg"' do
      parser.arg_list?.should parse('"my_arg"')
    end 
    it 'should consume -9.42, 100' do
      parser.arg_list?.should parse('-9.42, 100')
    end 
    it 'should consume -9.42, 100 , "my_arg"' do
      parser.arg_list?.should parse('-9.42, 100 , "my_arg"')
    end 
  end
end

# Non-Terminals (Statements)

# udf_call
describe ComposerParser do
  let(:parser) { ComposerParser.new }
  context 'udf_call' do
    it 'should consume my_func:' do
      parser.udf_call.should parse('my_func:')
    end 
    it 'should consume my_func: -9.42, 100 , "my_arg"' do
      parser.udf_call.should parse('my_func: -9.42, 100 , "my_arg"')
    end 
    it 'should consume my_func: -9.42, 100 , "my_arg", (my_func_arg: 100)' do
      parser.udf_call.should parse('my_func: -9.42, 100 , "my_arg", (my_func_arg: 100)')
    end
  end
end

# udf_call_stmt
describe ComposerParser do
  let(:parser) { ComposerParser.new }
  context 'udf_call_stmt' do
    it 'should consume my_func: -9.42, 100 , "my_arg"' do
      parser.udf_call_stmt.should parse('  my_func: -9.42, 100 , "my_arg"\n')
    end 
  end
end

# udf_call_arg
describe ComposerParser do
  let(:parser) { ComposerParser.new }
  context 'udf_call_arg' do
    it 'should consume (my_func: -9.42, 100 , "my_arg")' do
      parser.udf_call_arg.should parse('(my_func: -9.42, 100 , "my_arg")')
    end 
  end
end

# 'note' Statement
describe ComposerParser do
  let(:parser) { ComposerParser.new }
  context 'kw_note_stmt' do
    it 'should consume note "note 1"\n' do
      parser.kw_note_stmt.should parse(' note "note 1"\n')
   end 
  end
end

# 'note' attributes
describe ComposerParser do
  let(:parser) { ComposerParser.new }
  context 'kw_note_attr_stmt' do
    it 'should consume instrument 1\n' do
      parser.kw_note_attr_stmt.should parse('instrument 1\n')
    end 
    it 'should consume start 0.0\n' do
      parser.kw_note_attr_stmt.should parse('start 0.0\n')
    end 
    it 'should consume duration 1.0\n' do
      parser.kw_note_attr_stmt.should parse('duration 1.0\n')
    end 
    it 'should consume amplitude 500\n' do
      parser.kw_note_attr_stmt.should parse('amplitude 500\n')
    end 
    it 'should consume custom_attribute "attr_arg"\n' do
      parser.kw_note_attr_stmt.should parse('custom_attribute "attr_arg"\n')
    end 
  end
end

# kw_note_blk
describe ComposerParser do
  let(:parser) { ComposerParser.new }
  context 'kw_note_blk' do
    stmt = 'note "note 1"\n instrument 1\n  start 0.0\n  duration 1.0\n  amplitude 500\n  pitch 8.3\n'
    it 'should consume ' + stmt do
      parser.kw_note_blk.should parse(stmt, :trace => true)
    end 
  end
end

# 'note' block
describe ComposerParser do
  let(:parser) { ComposerParser.new }
  context 'kw_note_blk' do
    it 'should consume note "my note 1"\n  instrument 1\n  start 0.0\n  duration 1.0\n  amplitude 500\n  pitch 8.3\n' do
      parser.kw_note_blk.should parse('note "my note 1"\n  instrument 1\n  start 0.0\n  duration 1.0\n  amplitude 500\n  pitch 8.3\n')
   end 
  end
end

# NOTE: Will not parse exact same string enclosed in %Q{} block even though
#  that is supposed to be identical under the language. In other words, if 
#  you take below string and replace newlines with actual hard returns and have
#  the same whitespace, the parse fails

######### Validate TESTS ##########
# kw_note_blk
describe ComposerProcessor do
  let(:validator) { ComposerProcessor.new }
  context 'kw_note_blk' do
    stmt = 'note "note 1"'
    stmt_args = 'instrument 1\n  start 0.0\n  duration 1.0\n  amplitude 500\n  pitch 8.3\n'
    parst_stmt = stmt + eol + stmt_args
    it 'should transform kw_note_blk' do
      parser = ComposerParser.new
      parse_tree = parser.kw_note_blk.parse(parst_stmt)      
      validator.should validate(parse_tree, :trace => false)
      validator.validate(parse_tree).should == true
   end 
  end
end


######### Transform TESTS ##########

# kw_note_stmt
# arg_list
# describe ComposerProcessor do
#   let(:transformer) { ComposerProcessor.new }
#   context 'arg_list' do
#     expected = in_stmt = '1, 2'
#     it 'should transform ' + in_stmt + ' to ' + expected do
#       parse_tree = ComposerParser.new.arg_list.parse(in_stmt)
#       transformer.should transform(parse_tree, :trace => false)
#       transformer.transform(parse_tree).should == expected
#    end 
#   end
# end

# describe ComposerProcessor do
#   let(:transformer) { ComposerProcessor.new }
#   context 'kw_note_stmt' do
#     stmt = 'note "note 1"'
#     in_stmt = stmt + eol
#     expected = stmt + sp + blk_open + eol
#     it 'should transform ' + in_stmt + ' to ' + expected do
#       parse_tree = ComposerParser.new.parse(in_stmt)
#       transformer.should transform(parse_tree, :trace => false)
#       transformer.transform(parse_tree).should == expected
#    end 
#   end
# end

# kw_note_attr_stmt
# describe ComposerProcessor do
#   let(:transformer) { ComposerProcessor.new }
#   context 'kw_note_attr_stmt' do
#     in_stmt = expected = 'instrument 1' + eol
#     it 'should transform ' + in_stmt + ' to ' + expected do
#       # Reset root of ComposerParser to test this rule individually
#       ComposerParser.root('kw_note_attr_stmt')
#       parse_tree = ComposerParser.new.parse(in_stmt)
#       # Now transform the result of the parse, this is the actual xform unit test
#       transformer.should transform(parse_tree, :trace => false)            
#       transformer.transform(parse_tree).should == expected
#    end 
#   end
# end

# kw_note_blk
# describe ComposerProcessor do
#   let(:transformer) { ComposerProcessor.new }
#   context 'kw_note_blk' do
#     stmt = 'note "note 1"'
#     stmt_args = 'instrument 1\n  start 0.0\n  duration 1.0\n  amplitude 500\n  pitch 8.3\n'
#     parst_stmt = stmt + eol + stmt_args
#     note_stmt_expected = stmt + sp + blk_open + eol + 
#                          stmt_args + 
#                          blk_close + eol
#     it 'should transform kw_note_blk' do
#       parser = ComposerParser.new
#       parse_tree = parser.kw_note_blk.parse(parst_stmt)      
#       transformer.should transform(parse_tree, :trace => false)
#       transformer.transform(parse_tree).should == note_stmt_expected
#    end 
#   end
# end
