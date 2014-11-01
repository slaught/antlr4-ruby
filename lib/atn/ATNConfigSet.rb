# Specialized {@link Set}{@code <}{@link ATNConfig}{@code >} that can track
# info about the set, with support for combining similar configurations using a
# graph-structured stack.

require 'stringio'
require 'PredictionContext'
require 'atn/ATN'
require 'atn/ATNConfig'
#require 'atn/SemanticContext'
require 'error'

class ATNConfigSet
    # The reason that we need this is because we don't want the hash map to use
    # the standard hash code and equals. We need all configurations with the same
    # {@code (s,i,_,semctx)} to be equal. Unfortunately, this key effectively doubles
    # the number of objects associated with ATNConfigs. The other solution is to
    # use a hash table that lets us specify the equals/hashcode operation.

    attr_accessor :configLookup, :fullCtx, :readonly, :configs, :uniqueAlt
    attr_accessor :conflictingAlts, :hasSemanticContext, :dipsIntoOuterContext
    attr_accessor :cachedHashCode

    include PredictionContextFunctions
    def initialize(fullCtx=true)
        # All configs but hashed by (s, i, _, pi) not including context. Wiped out
        # when we go readonly as this set becomes a DFA state.
        self.configLookup = Set.new()
        # Indicates that this configuration set is part of a full context
        #  LL prediction. It will be used to determine how to merge $. With SLL
        #  it's a wildcard whereas it is not for LL context merge.
        self.fullCtx = fullCtx
        # Indicates that the set of configurations is read-only. Do not
        #  allow any code to manipulate the set; DFA states will point at
        #  the sets and they must not change. This does not protect the other
        #  fields; in particular, conflictingAlts is set after
        #  we've made this readonly.
        self.readonly = false
        # Track the elements as they are added to the set; supports get(i)#/
        self.configs = Array.new
        # TODO: these fields make me pretty uncomfortable but nice to pack up info together, saves recomputation
        # TODO: can we track conflicts as they are added to save scanning configs later?
        self.uniqueAlt = 0
        self.conflictingAlts = nil

        # Used in parser and lexer. In lexer, it indicates we hit a pred
        # while computing a closure operation.  Don't make a DFA state from this.
        self.hasSemanticContext = false
        self.dipsIntoOuterContext = false
        self.cachedHashCode = -1
    end
#    def __iter__(self)
#        return self.configs.__iter__()
    # Adding a new config means merging contexts with existing configs for
    # {@code (s, i, pi, _)}, where {@code s} is the
    # {@link ATNConfig#state}, {@code i} is the {@link ATNConfig#alt}, and
    # {@code pi} is the {@link ATNConfig#semanticContext}. We use
    # {@code (s,i,pi)} as key.
    #
    # <p>This method updates {@link #dipsIntoOuterContext} and
    # {@link #hasSemanticContext} when necessary.</p>
    #/
    def add(config, mergeCache=nil)
        raise Exception.new("This set is readonly") if self.readonly
        if config.semanticContext != SemanticContext.NONE
            self.hasSemanticContext = true
        end
        if config.reachesIntoOuterContext > 0
            self.dipsIntoOuterContext = true
        end
        existing = self.getOrAdd(config)
        if existing.equal? config
            self.cachedHashCode = -1
            self.configs.push(config)  # track order here
            return true
        end
        # a previous (s,i,pi,_), merge with it and save result
        rootIsWildcard =  self.fullCtx.nil?
        merged = merge(existing.context, config.context, rootIsWildcard, mergeCache)
        # no need to check for existing.context, config.context in cache
        # since only way to create new graphs is "call rule" and here. We
        # cache at both places.
        existing.reachesIntoOuterContext = [existing.reachesIntoOuterContext, config.reachesIntoOuterContext].max
        existing.context = merged # replace context; no need to alt mapping
        return true
    end
    def getOrAdd(config)
        # how is this not just# self.configLookup.add(config);return config ?
        for c in self.configLookup do
            return c if c == config
        end
        self.configLookup.add(config)
        return config
    end
    def getStates
        states = Set.new()
        self.configs.each {|c| states.add(c.state) }
        return states
    end
    def getPredicates
        preds = Array.new
        self.configs.each{|c|
            if c.semanticContext!=SemanticContext.NONE
                preds.pushd(c.semanticContext)
            end
        }
        return preds
    end
    def get(i)
        return self.configs[i]
    end

    def optimizeConfigs(interpreter)
        raise IllegalStateException.new("This set is readonly") if self.readonly
      
        return if self.configLookup.empty?
        self.configs.each {|config|
            config.context = interpreter.getCachedContext(config.context)
        }
    end

    def addAll(coll)
        coll.each {|c| self.add(c) }
        return false
    end
    def eql?(other)
      self == other
    end
    def ==(other)
        self.equal? other or other.kind_of? ATNConfigSet and \
            self.configs and \
            self.configs==other.configs and \
            self.fullCtx == other.fullCtx and \
            self.uniqueAlt == other.uniqueAlt and \
            self.conflictingAlts == other.conflictingAlts and \
            self.hasSemanticContext == other.hasSemanticContext and \
            self.dipsIntoOuterContext == other.dipsIntoOuterContext
    end
    def hash
        if self.readonly
            if self.cachedHashCode == -1
                self.cachedHashCode = self.hashConfigs()
            end
            return self.cachedHashCode
        end
        return self.hashConfigs()
    end
    def hashConfigs
        StringIO.open  do |buf|
          self.configs.each { |cfg| 
              buf.write(cfg.to_s)
          }
          return buf.string().hash
        end
    end

    def length
        return self.configs.length
    end

    def isEmpty
        return self.configs.empty?
    end

#    def __contains__(self, item)
#        if self.configLookup is None
#            raise UnsupportedOperationException("This method is not implemented for readonly sets.")
#        return item in self.configLookup
#    end
    def containsFast( obj)
        if self.configLookup.nil? 
            raise UnsupportedOperationException.new("This method is not implemented for readonly sets.")
        end
        return self.configLookup.containsFast(obj)
    end

    def clear
        raise IllegalStateException.new("This set is readonly") if self.readonly
        self.configs.clear()
        self.cachedHashCode = -1
        self.configLookup.clear()
    end
    def setReadonly(readonly)
        self.readonly = readonly
        self.configLookup = nil # can't mod, no need for lookup cache
    end
    def to_s
        StringIO.open  do |buf|
            buf.write("[ #{@configs.map{|x| x.class} } ]@#{@configs.length}")
            if self.hasSemanticContext
                buf.write(",hasSemanticContext=")
                buf.write(self.hasSemanticContext.to_s)
            end
            if self.uniqueAlt!=ATN.INVALID_ALT_NUMBER
                buf.write(",uniqueAlt=")
                buf.write(self.uniqueAlt.to_s())
            end
            if self.conflictingAlts then
                buf.write(",conflictingAlts=")
                buf.write(self.conflictingAlts.to_s)
            end
            if self.dipsIntoOuterContext
                buf.write(",dipsIntoOuterContext")
            end
            return buf.string()
        end
    end
end

class OrderedATNConfigSet < ATNConfigSet

    def initialize()
        super()
    end
end

