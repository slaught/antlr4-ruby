module JavaSymbols
  def self.included(klass)
    klass.send(:extend, JavaSymbols::ClassMethods)
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
