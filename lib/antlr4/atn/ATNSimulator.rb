#from antlr4.PredictionContext import PredictionContextCache, PredictionContext, getCachedPredictionContext
#from antlr4.atn.ATN import ATN
#from antlr4.atn.ATNConfigSet import ATNConfigSet
#from antlr4.dfa.DFAState import DFAState

require 'PredictionContext'
require 'atn/ATN'
require 'atn/ATNConfigSet'
require 'dfa/DFAState'

class ATNSimulator

    # Must distinguish between missing edge and edge we know leads nowhere#/
    @@ERROR = nil
    def self.ERROR
      if @@ERROR.nil?
       @@ERROR = DFAState.new(ATNConfigSet.new()) 
       @@ERROR.stateNumber = 0x7FFFFFFF
      end
      @@ERROR
    end

    # The context cache maps all PredictionContext objects that are ==
    #  to a single cached copy. This cache is shared across all contexts
    #  in all ATNConfigs in all DFA states.  We rebuild each ATNConfigSet
    #  to use only cached nodes/graphs in addDFAState(). We don't want to
    #  fill this during closure() since there are lots of contexts that
    #  pop up but are not used ever again. It also greatly slows down closure().
    #
    #  <p>This cache makes a huge difference in memory and a little bit in speed.
    #  For the Java grammar on java.*, it dropped the memory requirements
    #  at the end from 25M to 16M. We don't store any of the full context
    #  graphs in the DFA because they are limited to local context only,
    #  but apparently there's a lot of repetition there as well. We optimize
    #  the config contexts before storing the config set in the DFA states
    #  by literally rebuilding them with cached subgraphs only.</p>
    #
    #  <p>I tried a cache for use during closure operations, that was
    #  whacked after each adaptivePredict(). It cost a little bit
    #  more time I think and doesn't save on the overall footprint
    #  so it's not worth the complexity.</p>
    #/
    include PredictionContextFunctions

    attr_accessor :atn, :sharedContextCache
    def initialize(atn, sharedContextCache)
        raise Exception.new("ATN is nil") if atn.nil?
        self.atn = atn
        self.sharedContextCache = sharedContextCache
    end
    def getCachedContext(context)
        if self.sharedContextCache.nil? then
            return context
        end
        visited = Hash.new
        return getCachedPredictionContext(context, self.sharedContextCache, visited)
    end
end

