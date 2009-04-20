# Parse Rules
#
# 1. Note can be child of Root
# 2. Phrase can be child of Root
# 3. Section can be child or Root
# 4. Note can be child of Phrase
# 5. Phrase can be child of Section
# 6. Repeat can be child of Root
# 7. Repeat can be child of Phrase
# 8. Repeat can be child of Section
# 9. Note can be child of Repeat
#10. Phrase can be child of 
# 9. Write can be child of Root
#10. Render can be child of Root

# Data structure needed here
# So, legal parent child relationships are:
#
# Root
#  Note
#  Section
#   Phrase
#  Phrase
#   Note
#   Repeat
#  Repeat
#   Note
#  Write
#  Render

# Keyword completions
# note : "do\n"
# phrase : "do\n"
# section : "do\n"
# repeat : "do |index|\n"
# write : "do\n"
# render : "do\n"

# AST building rules
#
# Script is processed one line at a time
# If first word is a keyword
#   New ASTNode is created
#     Parent is ComposerAST.cur_parent
#     Expression is the line
#     Keyword is parsed and @keyword set
#     Expression is appended with completion for the keyword
#   ComposerAST.cur_parent adds new ASTNode with keyword 'end' as child, add_child
#   NOTE: This insures that each block gets an END before next sibling, and all its children
#     nest in a valid do/end block
#   ComposerAST.cur_parent adds new END ASTNode as child, add_child

# Grammar Rules
#--------------
# If keyword is lower precedence then ComposerAST.cur_parent, then this is new child of cur_parent
#  and parse is now nested under this new child which thus becomes new cur_parent
# If keyword is equal precedence to ComposerAST.cur_parent, then new child is assigned as sibling
#  of cur_parent, to cur_parent.parent, and cur_parent assigned to new node
# If keyword is higher precedence than ComposerAST.cur_parent then we are backing out of current scope
#  and we don't know how far so back up until valid parent of new node is found, attach new
#  as child, and set new node as cur_parent
#
# Syntax Rules
#-------------
# If keyword is 'repeat' then next token must be a positive integer, Else RAISE ERROR
# If keyword is 'render' then next token must be present (not newline) and must be a string
# If keyword is 'write' then next token must be present (not newline) and must be a string
# If keyword is 'write' then it must contain a child 'format' keyword node
# If keyword is 'format' then it must have 'write' parent
# If keyword is 'format' then it must have a valid argument: {csound, midi}

module Aleatoric

class ComposerASTException < Exception; end

class ComposerAST

  # Node nested class
  class ASTNode
    attr_reader :kw, :expr, :parent, :children
    
    def initialize(expr, kw='', parent=nil)
      @kw = kw
      @expr = expr
      @parent = parent
      @children = []
    end
    
    def add_child(node)
      @children << node
    end
    
    def to_s
      @expr
    end
  end  
  # /Node nested class
  
  # Class attributes that are the state and rules of the parse
  @@root = ASTNode.new(expr='root', kw='root', parent=nil)
  
  @@kw_completions = {
    'note' => " do\n",
    'phrase' => " do\n",
    'section' => " do\n",
    'repeat' => " do |index|\n",
    'write' => " do\n",
    'render' => " do\n",
    'format' => "\n"
  }
  
  @@kw_block_close_completions= {
    'note' => "end\n",
    'phrase' => "end\n",
    'section' => "end\n",
    'repeat' => "end\n",
    'write' => "end\n",
    'render' => "end\n",
    'format' => ""
  }
  
  @@kw_children = {
    'root' => ['note', 'phrase', 'section', 'repeat', 'write', 'render'],
    'note' => [],
    'phrase' => ['note', 'repeat'],
    'section' => ['phrase'],
    'repeat' => ['note'],
    'write' => ['format'],
    'render' => [],
    'format' => []
  }
  @@kw_parents = {
    'root' => [],
    'note' => ['root', 'phrase', 'repeat'],
    'phrase' => ['root', 'section'],
    'section' => ['root'],
    'repeat' => ['root', 'phrase'],
    'write' => ['root'],
    'render' => ['root'],
    'format' => ['write']
  }
  @@kw = @@kw_children.keys

  @@syntax_rules = {
    'note' => lambda {|x| x == nil or x.kind_of? String},             # 1st arg optional, valid type
    'phrase' => lambda {|x| x == nil or x.kind_of? String},           # 1st arg optional, valid type
    'section' => lambda {|x| x == nil or x.kind_of? String},          # 1st arg optional, valid type
    'repeat' => lambda {|x| x.kind_of? Fixnum},                       # 1st arg required, valid type
    'render' => lambda {|x| x.kind_of? String and x.length > 0},      # 1st arg required, valid type
    'write' => lambda {|x| x.kind_of? String and x.length > 0},       # 1st arg required, valid type
    'format' => lambda {|x| x != nil and (x.to_s == 'csound' or x.to_s == 'midi')}   # 1st arg required, valid value
  }
  
  @@grammar_rules = {
    'write' => lambda do |node|
      child_kws = node.children.collect {|child| child.kw}      
      child_kws.include? 'format'
    end, # 'write' has 'format' child
    'format' => lambda do |node|
      node.parent.kw == 'write'
    end # 'format' has 'write' parent
  }
  # /Class attributes that are the state and rules of the parse
   
  # Public parse interface
  def initialize(script)
    @parent = @@root
    @script = script
  end

  def preprocess_script(src_file_name)
    line_no = 0
    @script.each do |expr|
      begin
        line_no += 1
        process_expr(expr, src_file_name, line_no)
      rescue Exception => e
        @parent.add_child(ASTNode.new(expr=e.to_s, kw='Composer_ERROR', parent=@parent))
        break      
      end
    end
    self
  end
  
  # DFS the tree and print nodes pre-order.  This prints each line in order at
  #  each level of nesting, with all children printing after the opening line of their
  #  parent block and before the closing line of their parent block
  # note "note 1" do      # print block open, recurse
  #   amplitude 100       # print, recurse, leaf, back up, next
  #   pitch 150           # print, recurse, leaf, back up, next
  #   ...                 # back up
  # end                   # print block close, continue at this level of nesting
  def to_s  
    out_lines = []
    out_lines = to_s_helper_validate_grammar(node=@@root, out_lines=[], line_no=0)
    out_lines.join('')
  end
  # /Public parse interface
  
  # HELPERS
  private
  
  def process_expr(expr, src_file_name, line_no)
    expr = expr.strip
    return if expr == nil or expr.length == 0 or expr[0,1] == '#'
  
    # Test for keyword starting line or not, kw lines processed differently because they
    #  create grammar structure of script, non-kw lines just appended to current parent as attrs of it
    is_kw, kw = kw? expr      
    # Add the kw completion to the line
    expr = append_completion(kw, expr)
    
    if is_kw
      # Validate special rules for this kw, raise error if violated
      is_valid, kw_arg = valid_kw_arg?(kw, expr)
      if not is_valid
        raise ComposerASTException, "Source File Name: #{src_file_name}. Line Number: #{line_no}. Illegal argument '#{kw_arg}' passed to function '#{kw}'."
      end
      
      # If kw is valid child of @parent, new more nested parent, add_new node as child of @parent
      #  and make it the new @parent
      if valid_child_kw?(parent=@parent.kw, child=kw)
        new_node = insert_node(expr, kw, @parent)
        @parent = new_node
      # If same as @parent or valid child of @parent.parent, add new_node 
      #  as next child of @parent.parent and make new_node the new @parent
      elsif @parent.kw == kw or valid_child_kw?(parent=@parent.parent.kw, child=kw)
        new_node = insert_node(expr, kw, @parent.parent)
        @parent = new_node
      # Otherwise previous block ends and new block starts at a higher level. Nodes can be children 
      #  at multiple levels, and all can be child of root, so pop until first valid parent of new_node
      else
        found_parent = false
        cur_parent = @parent.parent
        while cur_parent != nil
          if valid_child_kw?(parent=cur_parent.kw, child=kw)
            new_node = insert_node(expr, kw, cur_parent)
            @parent = new_node 
            found_parent = true
            break
          end
          cur_parent = cur_parent.parent
        end
        # If we get here, then we unwound to root, new node is new child of root, and new cur_parent
        if not found_parent
          if not root? cur_parent
            raise ComposerASTException, "Source File Name: #{src_file_name}. Line Number: #{line_no}. Illegal argument '#{kw_arg}' passed to function '#{kw}'."
          end
          new_node = insert_node(expr, kw, cur_parent)
          @parent = new_node          
        end        
      end
    # Note a new grammar node, just an attribute node of the current parent, so just add child
    else    
      @parent.add_child(ASTNode.new(expr=expr, kw='', parent=@parent))
    end    
  end
  
  # process_expr() Helpers
  def append_completion(kw, expr)
    append_expr = @@kw_completions[kw]
    append_expr = "\n" if append_expr == nil
    expr + append_expr
  end
        
  def kw?(expr)
    kw = parse_kw expr    
    if @@kw.include? kw
      return true, kw
    else
      return false, nil
    end
  end

  def parse_kw(expr)
    return nil if expr == nil or expr.length == 0
    bound = expr.index(' ')
    bound = expr.length if bound == nil      
    return expr[0, bound]
  end
  
  def valid_kw_arg?(kw, expr)
    is_valid = true
    # Get next token after kw, all syntax rules validate next token
    kw_arg = second_tkn expr
    
    # So, some validation rules test for proper type or args passed, e.g. the loop bound
    #  value passed to 'repeat' which only makes sense as an Integer.  But all the args are
    #  being read in from a text file and not evaled so they look like strings.  So test
    #  if we can convert and do so and pass the Int if we can to the validation calls
    is_int, kw_arg_int = integer? kw_arg
    kw_arg = kw_arg_int if is_int 
    syntax_rule = @@syntax_rules[kw]
    is_valid = syntax_rule.call(kw_arg) if syntax_rule != nil
    
    return is_valid, kw_arg
  end
  
  def integer?(arg)
    if arg == nil
      return false, nil
    end

    # Integer() only throws on *strings* that aren't actually ints, e.g. Floats
    arg = arg.to_s    
    # Not the empty string and capable of being coerced by Integer()
    ret = nil
    is_int = false
    begin
      ret = Integer(arg)
      is_int = true
    rescue
      ret = nil
      is_int = false
    end

    return is_int, ret
  end

  def second_tkn(expr)
    lidx = expr.index(' ')    
    return nil if lidx == nil
    # Rebase lbound of string range working with
    expr = expr[lidx, expr.length - lidx]
    expr = expr.strip
    lidx = 0
    # Append marker as delmiter of end of string to match on if needed
    expr = expr + "!"
    # If the arg is a string, then spaces within the string are not delimiting token
    #  but rather the the quote and whitespace at the end of the string are
    if expr[0,1] == '"'
      ridx = expr.index('"', 1) 
      # If we matched on a right-hand end of string quote, ridx += 1 so that the arg includes the quote
      if ridx != nil and ridx > lidx
        ridx += 1
      end
    end
    ridx = expr.index(' ', 1) if (ridx == nil or ridx == lidx)
    # If we got to here the only delmiter is the marker appended above, tokenize on that
    ridx = expr.rindex('!') if (ridx == nil or ridx == lidx)
    expr[lidx, ridx - lidx].strip
  end  
  
  def valid_child_kw?(parent, child)
    @@kw_children[parent].include? child
  end
  
  def insert_node(expr, kw, parent)
    new_node = ASTNode.new(expr, kw, parent)
    parent.add_child(new_node)
    block_close_node = create_block_close_node(kw, parent)
    parent.add_child(block_close_node) unless block_close_node == nil
    new_node
  end  
  
  def root?(node)
    node.kw == 'root'
  end
  
  def create_block_close_node(kw, parent)
    # NOTE: This breaks if anything other than 'end\n' or something similar is block closer
    # Perhaps make more robust someday
    close_expr = @@kw_block_close_completions[kw]    
    if close_expr.length > 0
      close_kw = close_expr.strip
      ASTNode.new(expr=close_expr, kw=close_kw, parent=parent)
    else
      nil
    end
  end
  
  # /process_expr() Helpers
    
  # DFS the tree and print nodes pre-order. ... See comment above on to_s()
  # Also validate_grammar() called on each node because we are traversing finished tree
  #  and semantically cleaner code would mean traversing twice, once to validate and once to output
  def to_s_helper_validate_grammar(node, out_lines, line_no)
    # Poat-order append node to output
    s_out = node.to_s
    out_lines << s_out if s_out != 'root'
    # Loop over node's children
    node.children.each do |child|
      # TEMP DEBUG
      # puts child.expr    
      line_no += 1
      # Toss job if grammar rules violated      
      if not valid_grammar? child
        # TEMP DEBUG
        pp(@@root, [], 0)
        
        raise ComposerASTException, "Line Number: #{line_no}. Illegal structure. Node '#{child.kw}' has an illegal parent or child"
      end
      
      # Else recurse on each child, DFS
      to_s_helper_validate_grammar(child, out_lines, line_no)
    end
    # Return list of output lines
    out_lines
  end
  
  def valid_grammar?(node)
    is_valid = true
    grammar_rule = @@grammar_rules[node.kw]
    is_valid = grammar_rule.call(node) if grammar_rule != nil
    is_valid
  end
  
  def pp(node, out_lines, depth)
    # Return list of output lines
    outlines = pp_helper(node, out_lines, depth)
    puts "\n\nTREE"
    puts out_lines
    puts "\TREE\n\n"
  end
  
  def pp_helper(node, out_lines, depth)
    # Preorder append node to output
    pad = ''
    depth.times {pad = pad + '-'}
    out_lines << pad + node.to_s
    node.children.each do |child|
      pp_helper(child, out_lines, depth + 1)
    end
  end

  # /HELPERS

end

end

# TODO UNIT TEST THE HELPERS
