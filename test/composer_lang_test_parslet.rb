require 'rubygems'
require 'parslet'
require 'rspec'
require 'parslet/rig/rspec'

class BasicParser < Parslet::Parser

  # White space, define for exp rules to use for tokenization
  rule(:sp) { match('\s').repeat(1) }
  rule(:sp?) { sp.maybe }
  # Line handling
  rule(:line_end) { str('\r\n') | str('\n') }
  rule(:eol) { sp? >> line_end.repeat(1, 1) }
  rule (:eol?) { line_end.maybe }  
  # Delimiters  
  rule(:delim) { sp | eol }
  rule(:delim?) { delim.maybe }

  # Primitive/scalar types
  # NOTE: repeat(1) means 1 or more.  repeat signuture is repeat(min=nil, max=nil)
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
  
  def S(s)
    sp >> s >> sp
  end

  def S?(s)
    sp? >> s >> sp?
  end

  def E(s)
    eol? >> s >> eol?
  end
end


# TODO Move to its own source file
class ComposerParser < BasicParser
  
  # Keywords/Expressions
  rule(:name) { string.as(:name) }
  rule(:name?) { string.maybe.as(:name?) }

  # float must come first in alternation or matching int breaks float
  rule(:arg) { (float | integer | string).as(:arg) } # (str('(') >> func_call >> str(')') )
  rule(:arg_list) { (arg >>  (sp? >> str(',') >> sp? >> arg).repeat(0)).as(:arg_list) }
  rule(:arg_list?) { arg_list.maybe.as(:arg_list?) }
    
  rule(:kw_note) { str('note').as(:kw_note) }
  rule(:kw_note_stmt) { (sp? >> kw_note >> sp? >> name? >> eol).as(:kw_note_stmt) }  # (sp? >> kw_note >> name? >> sp? >> eol)
  rule(:kw_note_attr_stmt) {
    # TODO support aliased names, e.g. 'volume' for 'amplitude'
    (sp? >> 
    (str('instrument') | 
     str('start') | 
     str('duration') | 
     str('amplitude') | 
     str('pitch') | 
     match('[A-Za-z0-9|_]').repeat(1)) >> 
    sp >> arg_list >> eol).as(:kw_note_attr_stmt) 
  }
  
  #rule(:kw_note_attr_stmt) { E( kw_note_attr.as(:kw_note_attr) ) }
  #rule(:kw_note_blk) {
    # TODO Validate that expected five minimum attributes are present
    # 'instrument', 'start', 'duration', 'amplitude', 'pitch'
  #  kw_note_stmt >> kw_note_attr_stmt.repeat(5) 
  #}

  # Begin parse at root() rule
  root(:kw_note_stmt)    
end

class BasicTransformer < Parslet::Transform
  SP = ' '
  CRLF = '\r\n'
  DQT = '"'
  SQT = "'"
end

class ComposerTransformer < BasicTransformer
  include Parslet
  
  BLK_OPEN = 'do'
  
  def initialize
    @xform = Parslet::Transform.new
        
    # Primitive and scalar types, output their value
    @xform.rule(:integer => simple(:i)) { Integer(i.to_s.strip) }
    @xform.rule(:float=> simple(:f))  { Float(f.to_s.strip) }
    @xform.rule(:string => simple(:s))  { s.strip }      
    
    # Keywords/Expressions
    # @xform.rule(:name => simple(:name)) { name.nil? ? '' : name }
    # @xform.rule(:kw_note => simple(:kw_note)) { kw_note }
    @xform.rule(:kw_note_stmt => {:kw_note => simple(:kw_note), :string => simple(:string)}) { 
      kw_note + SP + string + SP + BLK_OPEN + CRLF 
    }
    
    # TODO Understanding subtrees is the key to getting all the blocks to work
    @xform.rule(:exp => subtree(:exp)) { exp }
  end
  
  def apply(tree)
    @xform.apply(tree)
  end
end


######### Parser TESTS ##########

# WS, EOL, Delimiters

describe ComposerParser  do
  let(:parser) { ComposerParser.new }
  context 'eol' do
    it 'should consume \n' do
      parser.eol.should parse('\n')
    end 
  end
end

# Literals

describe ComposerParser  do
  let(:parser) { ComposerParser.new }
  context 'integer' do
    it 'should consume 100' do
      parser.integer.should parse('100')
    end 
  end
end

describe ComposerParser  do
  let(:parser) { ComposerParser.new }
  context 'float' do
    it 'should consume -100.001' do
      parser.float.should parse('-100.001')
    end 
  end
end

describe ComposerParser  do
  let(:parser) { ComposerParser.new }
  context 'string' do
    it 'should consume " sfdkj3432#$#$@"' do
      parser.string.should parse('" sfdkj3432#$#$@"')
    end 
  end
end

# Keyword Terminals

describe ComposerParser  do
  let(:parser) { ComposerParser.new }
  context 'kw_note' do
    it 'should consume note' do
      parser.kw_note.should parse('note')
    end 
  end
end

# Terminals

# 'name'
describe ComposerParser  do
  let(:parser) { ComposerParser.new }
  context 'name' do
    it 'should consume "my_name"' do
      parser.name.should parse('"my_name"')
    end 
  end
end

# arg
describe ComposerParser  do
  let(:parser) { ComposerParser.new }
  context 'arg' do
    it 'should consume "my_name"' do
      parser.arg.should parse('"my_name"')
    end 
  end
end

describe ComposerParser  do
  let(:parser) { ComposerParser.new }
  context 'arg' do
    it 'should consume 42' do
      parser.arg.should parse('42')
    end 
  end
end

describe ComposerParser  do
  let(:parser) { ComposerParser.new }
  context 'arg' do
    it 'should consume 9.42' do
      parser.arg.should parse('9.42')
    end 
  end
end

# arg_list
describe ComposerParser  do
  let(:parser) { ComposerParser.new }
  context 'arg_list?' do
    it 'should consume -9.42' do
      parser.arg_list?.should parse('-9.42')
    end 
  end
end

describe ComposerParser  do
  let(:parser) { ComposerParser.new }
  context 'arg_list?' do
    it 'should consume "my_arg"' do
      parser.arg_list?.should parse('"my_arg"')
    end 
  end
end

describe ComposerParser  do
  let(:parser) { ComposerParser.new }
  context 'arg_list?' do
    it 'should consume -9.42, 100' do
      parser.arg_list?.should parse('-9.42, 100')
    end 
  end
end

describe ComposerParser  do
  let(:parser) { ComposerParser.new }
  context 'arg_list?' do
    it 'should consume -9.42, 100 , "my_arg"' do
      parser.arg_list?.should parse('-9.42, 100 , "my_arg"')
    end 
  end
end

# Non-Terminals (Statements)

# 'note' Statement
describe ComposerParser  do
  let(:parser) { ComposerParser.new }
  context 'kw_note_stmt' do
    it 'should consume note "note 1"\n' do
      parser.kw_note_stmt.should parse(' note "note 1"\n')
   end 
  end
end

# 'note' attributes
describe ComposerParser  do
  let(:parser) { ComposerParser.new }
  context 'kw_note_attr_stmt' do
    it 'should consume instrument 1\n' do
      parser.kw_note_attr_stmt.should parse('instrument 1\n')
   end 
  end
end

describe ComposerParser  do
  let(:parser) { ComposerParser.new }
  context 'kw_note_attr_stmt' do
    it 'should consume start 0.0\n' do
      parser.kw_note_attr_stmt.should parse('start 0.0\n')
   end 
  end
end

describe ComposerParser  do
  let(:parser) { ComposerParser.new }
  context 'kw_note_attr_stmt' do
    it 'should consume duration 1.0\n' do
      parser.kw_note_attr_stmt.should parse('duration 1.0\n')
   end 
  end
end

describe ComposerParser  do
  let(:parser) { ComposerParser.new }
  context 'kw_note_attr_stmt' do
    it 'should consume amplitude 500\n' do
      parser.kw_note_attr_stmt.should parse('amplitude 500\n')
   end 
  end
end

describe ComposerParser  do
  let(:parser) { ComposerParser.new }
  context 'kw_note_attr_stmt' do
    it 'should consume custom_attribute "attr_arg"\n' do
      parser.kw_note_attr_stmt.should parse('custom_attribute "attr_arg"\n')
   end 
  end
end

######### Transform TESTS ##########

