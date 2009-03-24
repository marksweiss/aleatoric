module Aleatoric

class Note
  attr_accessor :name   

  def initialize(name=nil, attrs=nil)
    @name = name
    # TODO enforce contract of required args in hash? But we allow properties to be set later
    @note_attrs = {}
    @ordered_keys = [:instrument, :start, :duration, :amplitude, :pitch]    
    attrs ||= {}
    attrs.each {|name, val| self.method_missing(name, val)}
    
  end
  
  def dup
    ret = Note.new
    ret.name = self.name
    @note_attrs.each {|name, val| ret.method_missing(name, val)}
    ret
  end  
  
  # TODO Change to use adapters for specific output formats. Some kind of NoteWriter ...
  # Which is presumably a singleton that is dependency injected into each note without
  #  the client code needing to do more than set it once globally.  Every note passes itself
  #  to the writer to write  
  def to_s
    ret = "i "
    
    # TEMP DEBUG
    puts "Note.name = #{@name}"
    
    @ordered_keys.each do |key|
      val = @note_attrs[key].to_s.strip	

      # TEMP DEBUG
      puts val
      
      if val.include? '.'
        ret.concat(sprintf("%.3f", val) + " ")
      else
        ret.concat("#{val} ")
      end	  
    end
    
    ret.concat("; #{@name}")
    
    ret
  end    
  
  def method_missing(name, val) 
   # TEMP DEBUG
   # puts "Note name #{name}"
   # puts "Note val #{val}"
  
    @note_attrs[name] = val
    @ordered_keys << name unless @ordered_keys.include? name
    def_accessor name
  end
  
  private
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
  public
  
end

end
