require 'test/unit'
require 'note'

module CSnd

class Note_Test < Test::Unit::TestCase
  # def setup
  # end
  # def teardown
  # end
  puts "TESTING Class Note"
  
  def test__getters
    puts "test__getters ENTERED"
    
    note = Note.new
    
    assert(note.instrument == nil)
    assert(note.instr == nil)
    assert(note.start == nil)
    assert(note.duration == nil)
    assert(note.dur == nil)
    assert(note.amplitude == nil)
    assert(note.amp == nil)
    assert(note.pitch == nil)
    
    puts "test__getters COMPLETED"
  end

  def test__setters
    puts "test__setters ENTERED"
    
    note = Note.new

    note.
      instr(1).
      start(2.0).
      dur(3.0).
      amp(4).
      pitch(5.0) 
    
    assert(note.instrument == 1)
    assert(note.instr == 1)
    assert(note.start == 2.0)
    assert(note.duration == 3.0)
    assert(note.dur == 3.0)
    assert(note.amplitude == 4.0)
    assert(note.amp == 4.0)
    assert(note.pitch == 5.0)    

    note.
      instrument(1).
      start(2.0).
      duration(3.0).
      amplitude(4).
      pitch(5.0)
    
    assert(note.instrument == 1)
    assert(note.instr == 1)
    assert(note.start == 2.0)
    assert(note.duration == 3.0)
    assert(note.dur == 3.0)
    assert(note.amplitude == 4.0)
    assert(note.amp == 4.0)
    assert(note.pitch == 5.0)
    
    note.
      instr(note.instr + 1).
      start(note.start + 1.0).
      dur(note.dur + 1.0).
      amp(note.amp + 1).
      pitch(note.pitch + 1.0)  

    assert(note.instrument == 2)
    assert(note.instr == 2)
    assert(note.start == 3.0)
    assert(note.duration == 4.0)
    assert(note.dur == 4.0)
    assert(note.amplitude == 5.0)
    assert(note.amp == 5.0)
    assert(note.pitch == 6.0)
    
    puts "test__setters COMPLETED"
  end
  
  def test__attrs
    puts "test__attrs ENTERED"
    
    note = Note.new
    note.
      instr(1).
      start(2.0).
      dur(3.0).
      amp(4).
      pitch(5.0)
    
    attrs = note.attrs
    keys = note.ordered_keys
    assert(note.instrument == attrs[keys[0]])
    assert(note.instr == attrs[keys[0]])
    assert(note.start == attrs[keys[1]])
    assert(note.duration == attrs[keys[2]])
    assert(note.dur == attrs[keys[2]])
    assert(note.amplitude == attrs[keys[3]])
    assert(note.amp == attrs[keys[3]])
    assert(note.pitch == attrs[keys[4]])
            
    puts keys
    p keys
    
    puts "test__attrs COMPLETED"
  end  

  def test__ordered_vals__keys
    puts "test__ordered_vals__keys ENTERED"
    
    note = Note.new
    note.
      instr(1).
      start(2.0).
      dur(3.0).
      amp(4).
      pitch(5.0)
    
    assert(note.ordered_vals == [1, 2.0, 3.0, 4, 5.0])
            
    puts "test__ordered_vals__keys COMPLETED"
  end
    
  def test__each
    puts "test__each ENTERED"
    
    note = Note.new
    note.
      instr(1).
      start(2.0).
      dur(3.0).
      amp(4).
      pitch(5.0)
    
    j, keys, vals = 0, note.ordered_keys, note.ordered_vals
    note.each do |k, v|
      assert(k = keys[j])
      assert(v == vals[j])
      j += 1
    end
    
    puts "test__each COMPLETED"
  end
  
  def test__add_attr
    puts "test__add_attr ENTERED"
    
    note = Note.new
    note.
      instr(1).
      start(2.0).
      dur(3.0).
      amp(4).
      pitch(5.0)
    
    assert(note.instrument == 1)
    assert(note.instr == 1)
    assert(note.start == 2.0)
    assert(note.duration == 3.0)
    assert(note.dur == 3.0)
    assert(note.amplitude == 4.0)
    assert(note.amp == 4.0)
    assert(note.pitch == 5.0)
    
    # Can add attr as string, class will convert to symbol
    note.add_attr("reverb", 6.0)
    assert(note.reverb == 6.0)
    note.reverb(6.0)
    # Can add attr as symbol
    note.add_attr(:vibrato)
    assert(note.vibrato == nil)
    note.vibrato(7.0)   
    assert(note.vibrato == 7.0)
    
    puts "test__add_attr COMPLETED"
  end

  def test__add_custom_attr
    puts "test__add_custom_attr ENTERED"
    
    note = Note.new
    note.
      instr(1).
      start(2.0).
      dur(3.0).
      amp(4).
      pitch(5.0)
        
    # Can add attr as string, class will convert to symbol
    tst_legato_nxt = lambda {dur(dur * 1.05)}
	note.add_custom_attr("tst_legato_nxt", &tst_legato_nxt)
	assert(note.respond_to?(:tst_legato_nxt))
	note.send :tst_legato_nxt
	assert(note.dur == 3.0 * 1.05)
	new_dur = note.dur

    # Can add attr as symbol
    tst_legato_prv = lambda {start(start - 0.05) if start >= 0}
    note.add_custom_attr(:tst_legato_prv, &tst_legato_prv)
	assert(note.respond_to?(:tst_legato_prv))	
	note.apply_custom_attrs
	assert(note.start == 2.0 - 0.05)
	
    puts "test__add_custom_attr COMPLETED"
  end
  
  def test__size__length
    puts "test__size__length ENTERED"
    
    note = Note.new
    assert(note.size == Note::NUM_DEFAULT_ATTRS)
    
    note.
      instr(1).
      start(2.0).
      dur(3.0).
      amp(4).
      pitch(5.0)
    assert(note.length == 5)
    
    note.add_attr(:vibrato)
    assert(note.length == 6)
    note.vibrato(100)
    assert(note.length == 6)
    
    puts "test__size__length COMPLETED"
  end
      
  def test__dup
    puts "test__dup ENTERED"
    
    note = Note.new
    note.
      instr(1).
      start(2.0).
      dur(3.0).
      amp(4).
      pitch(5.0)
    note.add_attr("reverb", 6.0)
    
    assert(note.instrument == 1)
    assert(note.instr == 1)
    assert(note.start == 2.0)
    assert(note.duration == 3.0)
    assert(note.dur == 3.0)
    assert(note.amplitude == 4.0)
    assert(note.amp == 4.0)
    assert(note.pitch == 5.0)
    assert(note.reverb == 6.0)
    
    note2 = note.dup
    
    assert(note2.instrument == 1)
    assert(note2.instr == 1)
    assert(note2.start == 2.0)
    assert(note2.duration == 3.0)
    assert(note2.dur == 3.0)
    assert(note2.amplitude == 4.0)
    assert(note2.amp == 4.0)
    assert(note2.pitch == 5.0)
    assert(note2.reverb == 6.0)
            
    puts "test__dup COMPLETED"
  end

  def test__to_s
    puts "test__to_s ENTERED"
    
    note = Note.new
    note.
      instr(1).
      start(2.0).
      dur(3.0).
      amp(4).
      pitch(5.0)
    note.add_attr(:reverb, 6.0)
    
    assert(note.to_s == "i 1 2.000 3.000 4 5.000 6.000")
    assert(note.print == "i 1 2.000 3.000 4 5.000 6.000")
            
    puts "test__to_s COMPLETED"
  end

  def test__equals
    puts "test__equals ENTERED"
    
    note1 = Note.new
    note1.
      instr(1).
      start(2.0).
      dur(3.0).
      amp(4).
      pitch(5.0)
    
    note2 = Note.new
    note2.
      instr(1).
      start(2.0).
      dur(3.0).
      amp(4).
      pitch(5.0)
    
    assert(note1 == note2)

    note3 = Note.new
    note3.
      instr(2).
      start(2.0).
      dur(3.0).
      amp(4).
      pitch(5.0)

    assert(note1 != note3 && note2 != note3 && note1 == note2)

    puts "test__equals COMPLETED"
  end  
  
end    
  
# /Note and NoteTest #######################

end  
#/CSnd Module

# Define module level method to hide object reference to a Note, call Note
#  methods generically, and return the result. This allows expression of
#  of function names directly without any object syntaxt.  So ... DSL
# Idea taken from here: http://blog.8thlight.com/articles/2007/05/20/ruby-dls-blocks
# 
# # This block gets passed to self.order. It's the set of all the commands
# #  we want to run against the actual object of the actual type we're working with
# # Notice the dot syntax is actually a DSL, not object syntax, and that it's
# #  read left to right in Ruby, and that this works in the actual suppporting
# #  code because the methods on the left of dots all return self
# 
# Starbucks.order do
#    grande.coffee
#    short.americano
#    venti.breve.half_caff
# end
#
# # This is the magic function, which defines a module level call taking a
# #  a block -- the do..end above -- and passing it to a new instance to be
# #  evaluated, generate state in the instance, and then to return that state
# #  from the instance
# 
# def self.order(&block)
#    order = Order.new
#    order.instance_eval(&block)
#    return order.drinks
# end
#
#  class Order
#
#    # The state being built up in the instance
#    attr_reader :drinks
#
#    def initialize
#      @drinks = []
#    end
#
#    # A "left-side" method which sets an instance attr and returns self
#    def short
#      @size = "small"
#      return self
#    end
# ...
#    # A "right-side" method which sets an instance attr and then calls the
#    #  private helper that composes the final state in :drinks which is what
#    #  the module level method returns 
#    
#    def coffee
#      @drink = "coffee"
#      build_drink
#    end
#    
#    private
#
#    # This helper appends composed return objects into the return :drinks
#    #  instance attr returned to the caller from the module-level wrapper
#    
#    def build_drink
#      drink = "#{@size} cup of #{@drink}"
#      drink << " #{@adjective}" if @adjective
#      @drinks << drink

#      @size = @drink = @adjective = nil
#    end
#  end
#
# end
