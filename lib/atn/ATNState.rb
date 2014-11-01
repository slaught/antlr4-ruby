
#from antlr4.atn.Transition import Transition
INITIAL_NUM_TRANSITIONS = 4

require 'java_symbols'


class ATNState
    include JavaSymbols

    # constants for serialization
    INVALID_TYPE = 0
    BASIC = 1
    RULE_START = 2
    BLOCK_START = 3
    PLUS_BLOCK_START = 4
    STAR_BLOCK_START = 5
    TOKEN_START = 6
    RULE_STOP = 7
    BLOCK_END = 8
    STAR_LOOP_BACK = 9
    STAR_LOOP_ENTRY = 10
    PLUS_LOOP_BACK = 11
    LOOP_END = 12

    serializationNames = [
            "INVALID",
            "BASIC",
            "RULE_START",
            "BLOCK_START",
            "PLUS_BLOCK_START",
            "STAR_BLOCK_START",
            "TOKEN_START",
            "RULE_STOP",
            "BLOCK_END",
            "STAR_LOOP_BACK",
            "STAR_LOOP_ENTRY",
            "PLUS_LOOP_BACK",
            "LOOP_END" ]

    INVALID_STATE_NUMBER = -1

    attr_accessor :atn, :stateNumber, :stateType, :ruleIndex
    attr_accessor :epsilonOnlyTransitions ,:transitions, :nextTokenWithinRule 
    def initialize() 
        # Which ATN are we in?
        self.atn = nil
        self.stateNumber = ATNState.INVALID_STATE_NUMBER
        self.stateType = nil
        self.ruleIndex = 0 # at runtime, we don't have Rule objects
        self.epsilonOnlyTransitions = false
        # Track the transitions emanating from this ATN state.
        self.transitions = Array.new
        # Used to cache lookahead during parsing, not used during construction
        self.nextTokenWithinRule = nil
    end

    def hash
        return self.stateNumber
    end

    def ==(other)
        if other.kind_of? ATNState then
            self.stateNumber==other.stateNumber
        else
            false
        end
    end
    def onlyHasEpsilonTransitions
        self.epsilonOnlyTransitions
    end
    def isNonGreedyExitState
        return false
    end

    def to_s 
        self.stateNumber.to_s
    end

    def addTransition(trans, index=-1)
        if self.transitions.length==0
            self.epsilonOnlyTransitions = trans.isEpsilon
        elsif self.epsilonOnlyTransitions != trans.isEpsilon
            self.epsilonOnlyTransitions = false
            # TODO System.err.format(Locale.getDefault(), "ATN state %d has both epsilon and non-epsilon transitions.\n", stateNumber);
        end
        if index==-1
            self.transitions.push(trans)
        else
            self.transitions.insert(index, trans)
        end
    end
end

class BasicState < ATNState
    def initialize 
        super()
        self.stateType = self.BASIC
    end
end

class DecisionState < ATNState

    def initialize 
        super()
        self.decision = -1
        self.nonGreedy = false
    end
end
#  The start of a regular {@code (...)} block.
class BlockStartState < DecisionState

    def initialize 
        super()
        self.endState = nil
    end
end

class BasicBlockStartState < BlockStartState

    def initialize 
        super()
        self.stateType = self.BLOCK_START
    end
end

# Terminal node of a simple {@code (a|b|c)} block.
class BlockEndState < ATNState

    def initialize 
        super()
        self.stateType = self.BLOCK_END
        self.startState = nil
    end
end

# The last node in the ATN for a rule, unless that rule is the start symbol.
#  In that case, there is one transition to EOF. Later, we might encode
#  references to all calls to this rule to compute FOLLOW sets for
#  error handling.
#
class RuleStopState < ATNState

    def initialize 
        super()
        self.stateType = self.RULE_STOP
    end
end

class RuleStartState < ATNState

    def initialize 
        super()
        self.stateType = self.RULE_START
        self.stopState = nil
        self.isPrecedenceRule = false
    end
end

# Decision state for {@code A+} and {@code (A|B)+}.  It has two transitions:
#  one to the loop back to start of the block and one to exit.
#
class PlusLoopbackState < DecisionState

    def initialize 
        super()
        self.stateType = self.PLUS_LOOP_BACK
    end
end

# Start of {@code (A|B|...)+} loop. Technically a decision state, but
#  we don't use for code generation; somebody might need it, so I'm defining
#  it for completeness. In reality, the {@link PlusLoopbackState} node is the
#  real decision-making note for {@code A+}.
#
class PlusBlockStartState < BlockStartState

    def initialize 
        super()
        self.stateType = self.PLUS_BLOCK_START
        self.loopBackState = nil
    end
end

# The block that begins a closure loop.
class StarBlockStartState < BlockStartState

    def initialize 
        super()
        self.stateType = self.STAR_BLOCK_START
    end
end

class StarLoopbackState < ATNState

    def initialize 
        super()
        self.stateType = self.STAR_LOOP_BACK
    end
end


class StarLoopEntryState < DecisionState

    def initialize 
        super()
        self.stateType = self.STAR_LOOP_ENTRY
        self.loopBackState = nil
        # Indicates whether this state can benefit from a precedence DFA during SLL decision making.
        self.precedenceRuleDecision = nil
    end
end

# Mark the end of a * or + loop.
class LoopEndState < ATNState

    def initialize 
        super()
        self.stateType = self.LOOP_END
        self.loopBackState = nil
    end
end

# The Tokens rule start state linking to each lexer rule start state */
class TokensStartState < DecisionState

    def initialize 
        super()
        self.stateType = self.TOKEN_START
    end
end
