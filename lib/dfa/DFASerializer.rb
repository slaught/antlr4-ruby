
# A DFA walker that knows how to dump them to serialized strings.#/
require 'stringio'
#from antlr4 import DFA
#from antlr4.Utils import str_list
#from antlr4.dfa.DFAState import DFAState

class DFASerializer

    attr_accessor :dfa, :tokenNames
    def initialize(dfa, tokenNames=nil)
        @dfa = dfa
        @tokenNames = tokenNames
    end

    def to_s
        return nil if self.dfa.s0.nil? 
        StringIO.open do |buf|
            for s in self.dfa.sortedStates()
                n = 0
                if not s.edges.nil? 
                    n = s.edges.length
                end
                for i in 0..(n-1) do 
                    t = s.edges[i]
                    if not t.nil? and t.stateNumber != 0x7FFFFFFF then
                        buf.write(self.getStateString(s))
                        label = self.getEdgeLabel(i)
                        buf.write("-")
                        buf.write(label)
                        buf.write("->")
                        buf.write(self.getStateString(t))
                        buf.write("\n")
                    end
                end
            end
            output = buf.string()
            if output.length == 0
                return nil
            else
                return output
            end
        end
    end

    def getEdgeLabel(i)
        return "EOF" if i==0
        if not self.tokenNames.nil? then
            return self.tokenNames[i-1]
        else
            return (i-1).to_s
        end
    end

    def getStateString(s)
#        s_acceptState = nil
#        s_acceptState = ":" if s.isAcceptState 
        s_requireContext = nil
        s_requireContext = "^" if s.requiresFullContext 
        baseStateStr = "s#{s.stateNumber}#{s_requireContext}"
        if s.isAcceptState then
            if not s.predicates.nil? then 
                return ":#{baseStateStr}=>#{s.predicates}"
            else
                return ":#{baseStateStr}=>#{s.prediction}"
            end
        else
            return baseStateStr
        end
    end
end

class LexerDFASerializer < DFASerializer

    def initialize(dfa)
        super(dfa, nil)
    end

    def getEdgeLabel(i)
        return "'#{i.pack('U')}'"
    end
end
