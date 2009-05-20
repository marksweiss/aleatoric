module Aleatoric

class Note
  @@format = :csound
  attr_accessor :name

  def initialize(name=nil, attrs=nil, format=nil)
    @name = name
    @note_attrs = {}
    @ordered_keys = [:instrument, :start, :duration, :amplitude, :pitch]
    # Default formatter is csound. :midi formatter will eventually be supported also
    format ||= :csound
    @@format = format
    attrs ||= {}
    attrs.each {|name, val| self.method_missing(name, val)}  
  end
  
  def dup
    ret = Note.new
    ret.name = self.name
    @note_attrs.each {|name, val| ret.method_missing(name, val)}
    ret
  end  
  
  # Ugly conditional code to set to_s appropriately based on output format
  # Adds a to_s definition to the class based on format value passed to class method
  def Note.to_s_format=(format)
    @@format = format.to_sym
  end
  def Note.to_s_format
    @@format
  end
  
  def to_s
    case @@format
    when :csound
      ret = "i "
      @ordered_keys.each do |key|
        val = @note_attrs[key].to_s.strip	
        # NOTE: This is a pretty terrible check for a float
        if val.include? '.'
          ret.concat(sprintf("%.5f", val) + " ")
        else
          ret.concat("#{val} ")
        end	  
      end          
      ret.concat("; #{@name}")          
      ret
    # TODO Actually support MIDI
    when :midi
      ret = ""
      @ordered_keys.each do |key|
        val = @note_attrs[key].to_s.strip	
        ret.concat("#{val} ")
      end
      ret
    end
    
  end

  def method_missing(name, val)
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
