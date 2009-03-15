
class Note    
  def initialize(attrs=nil)
    # TODO enforce contract of required args in hash? But we allow properties to be set later
    @note_attrs = {}
    @ordered_keys = [:instrument, :start, :duration, :amplitude, :pitch]       
    attrs ||= {}
    attrs.each {|name, val| self.method_missing(name, val)}
  end
    
  def to_s
    s = ""
    @ordered_keys.each {|k| s << "#{k.to_s} = #{@note_attrs[k]}\n"}
    s
  end

  private

  def method_missing(name, val)  
    @note_attrs[name] = val
    @ordered_keys << name unless @ordered_keys.include? name
    def_accessor name
  end
  
  def def_accessor(name)
    self.class.class_eval %Q{
      def #{name}(val=nil)
        if val == nil then
          @note_attrs[:#{name}]
        else
          @note_attrs[:#{name}] = val
          self
        end
      end
    }
  end  
end

class Score
  attr_reader :notes

  def initialize
    @notes = []
  end
  
  def <<(note)
    @notes << note
  end
  
  def last_note
    @notes.last
  end
  
  def method_missing_handler(name, val)
    last_note.method_missing(name, val)
  end
  
  def to_s
    s = ""
    @notes.each {|note| s << note.to_s}
    s
  end
end

$Score = Score.new

def note(attrs=nil)
  $Score << Note.new(attrs)
end

def method_missing(name, val)
  $Score.method_missing_handler(name, val)
end

load("note2.in")
puts $Score
