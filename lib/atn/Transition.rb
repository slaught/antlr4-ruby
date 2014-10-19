#  An ATN transition between any two ATN states.  Subclasses define
#  atom, set, epsilon, action, predicate, rule transitions.
#
#  <p>This is a one way link.  It emanates from a state (usually via a list of
#  transitions) and has a target state.</p>
#
#  <p>Since we never have to change the ATN transitions once we construct it,
#  we can fix these transitions as specific classes. The DFA transitions
#  on the other hand need to update the labels as it adds transitions to
#  the states. We'll use the term Edge for the DFA to distinguish them from
#  ATN transitions.</p>
#
#from antlr4.IntervalSet import IntervalSet
#from antlr4.Token import Token
require 'IntervalSet'
require 'Token'

require 'atn/SemanticContext'

require 'java_symbols'

class Transition 
    include JavaSymbols
    # constants for serialization
    EPSILON			= 1
    RANGE			= 2
    RULE			= 3
    PREDICATE		= 4 # e.g., {isType(input.LT(1))}?
    ATOM			= 5
    ACTION			= 6
    SET				= 7 # ~(A|B) or ~atom, wildcard, which convert to next 2
    NOT_SET			= 8
    WILDCARD		= 9
    PRECEDENCE		= 10

    @@serializationNames = [
            "INVALID",
            "EPSILON",
            "RANGE",
            "RULE",
            "PREDICATE",
            "ATOM",
            "ACTION",
            "SET",
            "NOT_SET",
            "WILDCARD",
            "PRECEDENCE"
        ]
    def self.serializationNames 
      @@serializationNames 
    end

    @@serializationTypes = nil
    def self.serializationTypes 
      @@serializationTypes 
    end
    def self.serializationTypes=(newhash)
        @@serializationTypes = newhash
    end

    attr_accessor :target, :isEpsilon, :label, :serializationType 
    def initialize(target)
        # The target of this transition.
        raise Exception.new("target cannot be null.") if target.nil?
        self.target = target
        # Are we epsilon, action, sempred?
        self.isEpsilon = false
        self.label = nil
    end
end


# TODO: make all transitions sets? no, should remove set edges
class AtomTransition < Transition

    attr_accessor :label_
    def initialize(target, label)
        super(target)
        @label_ = label # The token type or character value; or, signifies special label.
        @label = self.makeLabel()
        @serializationType = Transition.ATOM
    end

    def makeLabel
        s = IntervalSet.new()
        s.addOne(self.label_)
        return s
    end

    def matches( symbol, minVocabSymbol,  maxVocabSymbol)
        return self.label_ == symbol
    end

    def to_s
        return self.label_.to_s
    end
end
class RuleTransition < Transition

    attr_accessor :ruleIndex, :precedence, :followState
    def initialize(ruleStart, ruleIndex, precedence, followState)
        super(ruleStart)
        self.ruleIndex = ruleIndex # ptr to the rule definition object for this rule ref
        self.precedence = precedence
        self.followState = followState # what node to begin computations following ref to rule
        self.serializationType = Transition.RULE
        self.isEpsilon = true
    end

    def matches( symbol, minVocabSymbol,  maxVocabSymbol)
        return false
    end
end


class EpsilonTransition < Transition

    def initialize(target)
        super(target)
        self.serializationType = Transition.EPSILON
        self.isEpsilon = true
    end

    def matches(symbol, minVocabSymbol,  maxVocabSymbol)
        return false
    end

    def to_s
        return "epsilon"
    end
end

class RangeTransition < Transition

    attr_accessor :start, :stop
    def initialize(target, start, stop)
        super(target)
        self.serializationType = Transition.RANGE
        self.start = start
        self.stop = stop
        self.label = self.makeLabel()
    end

    def makeLabel()
        s = IntervalSet.new()
        s.addRange(self.start..self.stop + 1)
        return s
    end

    def matches( symbol, minVocabSymbol,  maxVocabSymbol)
        symbol >= self.start and symbol <= self.stop
    end

    def to_s
        return "'#{self.start.chr}'..'#{self.stop.chr}'"
    end
end

class AbstractPredicateTransition < Transition

    def initialize(target)
        super(target)
    end

end

class PredicateTransition < AbstractPredicateTransition

    attr_accessor :ruleIndex, :predIndex, :isCtxDependent 
    def initialize(target, ruleIndex, predIndex, isCtxDependent)
        super(target)
        self.serializationType = Transition.PREDICATE
        self.ruleIndex = ruleIndex
        self.predIndex = predIndex
        self.isCtxDependent = isCtxDependent # e.g., $i ref in pred
        self.isEpsilon = true
    end

    def matches( symbol, minVocabSymbol,  maxVocabSymbol)
        return false
    end

    def getPredicate()
        return Predicate.new(self.ruleIndex, self.predIndex, self.isCtxDependent)
    end

    def to_s
        return "pred_#{self.ruleIndex}:#{self.predIndex}"
    end
end

class ActionTransition < Transition

    
    attr_accessor :ruleIndex, :actionIndex, :isCtxDependent 
    def initialize(target, ruleIndex, actionIndex=-1, isCtxDependent=false)
        super(target)
        self.serializationType = Transition.ACTION
        self.ruleIndex = ruleIndex
        self.actionIndex = actionIndex
        self.isCtxDependent = isCtxDependent # e.g., $i ref in pred
        self.isEpsilon = true
    end
    def matches( symbol, minVocabSymbol,  maxVocabSymbol)
        return false
    end

    def to_s
        return "action_#{self.ruleIndex}:#{self.actionIndex}"
    end
end
# A transition containing a set of values.
class SetTransition < Transition

    def initialize(target, set)
        super(target)
        self.serializationType = self.SET
        if not set.nil? 
            self.label = set
        else
            self.label = IntervalSet.new()
            self.label.addRange(Token.INVALID_TYPE..Token.INVALID_TYPE)
        end
    end
    def matches(symbol, minVocabSymbol,  maxVocabSymbol)
        self.label.member? symbol
    end

    def to_s
        self.label.to_s
    end
end

class NotSetTransition < SetTransition

    def initialize(target, set)
        super(target, set)
        self.serializationType = Transition.NOT_SET
    end

    def matches( symbol, minVocabSymbol,  maxVocabSymbol)
        symbol >= minVocabSymbol \
            and symbol <= maxVocabSymbol \
            and not super.matches(symbol, minVocabSymbol, maxVocabSymbol)
    end

    def to_s
        return '~' + super.to_s
    end
end

class WildcardTransition < Transition

    def initialize(target)
        super(target)
        self.serializationType = Transition.WILDCARD
    end

    def matches( symbol, minVocabSymbol,  maxVocabSymbol)
        symbol >= minVocabSymbol and symbol <= maxVocabSymbol
    end

    def to_s
        return "."
    end
end

class PrecedencePredicateTransition < AbstractPredicateTransition

    attr_accessor :precedence 
    def initialize(target, precedence)
        super(target)
        self.serializationType = Transition.PRECEDENCE
        self.precedence = precedence
        self.isEpsilon = True
    end

    def matches( symbol, minVocabSymbol,  maxVocabSymbol)
        return false
    end


    def getPredicate()
        return PrecedencePredicate.new(self.precedence)
    end

    def to_s
        return "#{self.precedence} >= _p"
    end
end

Transition.serializationTypes = {
             EpsilonTransition => Transition.EPSILON,
             RangeTransition => Transition.RANGE,
             RuleTransition => Transition.RULE,
             PredicateTransition => Transition.PREDICATE,
             AtomTransition => Transition.ATOM,
             ActionTransition => Transition.ACTION,
             SetTransition => Transition.SET,
             NotSetTransition => Transition.NOT_SET,
             WildcardTransition => Transition.WILDCARD,
             PrecedencePredicateTransition => Transition.PRECEDENCE
}
