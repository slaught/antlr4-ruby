module JavaSymbols
  def self.included(klass)
    klass.send(:extend, JavaSymbols::ClassMethods)
    klass.send(:include, JavaSymbols::Methods)
  end
  module Methods
    alias_method :old_method_missing, :method_missing
    def method_missing(name, *args)
      if self.class.const_defined?(name) then
        return self.class.const_get(name)
      end
      old_method_missing(name, args)
    end
  end
  module ClassMethods
    alias_method :old_method_missing, :method_missing
    def method_missing(name, *args)
      if const_defined?(name) then
        return const_get(name)
      end
      old_method_missing(name, args)
    end
  end
end
