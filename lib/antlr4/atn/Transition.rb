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

class Transition 
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

    attr_accessor :target, :isEpsilon, :serializationType, :ruleIndex
    def initialize(target)
        # The target of this transition.
        raise Exception.new("target cannot be null.") if target.nil?
        self.target = target
        # Are we epsilon, action, sempred?
        self.isEpsilon = false
        @ruleIndex = 0
    end
    def label
        nil
    end
end


# TODO: make all transitions sets? no, should remove set edges
class AtomTransition < Transition

    attr_accessor :label_
    def initialize(_target, _label)
        super(_target)
        @label_ = _label # The token type or character value; or, signifies special label.
        @serializationType = Transition::ATOM
    end

    def label
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
    def initialize(rule_start, rule_index, _precedence, follow_state)
        super(rule_start)
        self.ruleIndex = rule_index # ptr to the rule definition object for this rule ref
        self.precedence = _precedence
        self.followState = follow_state # what node to begin computations following ref to rule
        @serializationType = Transition::RULE
        @isEpsilon = true
    end

    def matches( symbol, minVocabSymbol,  maxVocabSymbol)
        return false
    end
end


class EpsilonTransition < Transition

    def initialize(_target)
        super(_target)
        self.serializationType = Transition::EPSILON
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
    def initialize(_target, _start, _stop)
        super(_target)
        self.serializationType = Transition::RANGE
        self.start = _start
        self.stop = _stop
    end

    def label()
        s = IntervalSet.new()
        s.addRange(self.start..self.stop)
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

    def initialize(_target)
        super(_target)
    end

end

class PredicateTransition < AbstractPredicateTransition

    attr_accessor :ruleIndex, :predIndex, :isCtxDependent 
    def initialize(_target, rule_index, pred_index, is_ctx_dependent)
        super(_target)
        self.serializationType = Transition::PREDICATE
        self.ruleIndex = rule_index
        self.predIndex = pred_index
        self.isCtxDependent = is_ctx_dependent # e.g., $i ref in pred
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
    def initialize(_target, rule_index, action_index=-1, is_ctx_dependent=false)
        super(_target)
        self.serializationType = Transition::ACTION
        self.ruleIndex = rule_index
        self.actionIndex = action_index
        self.isCtxDependent = is_ctx_dependent # e.g., $i ref in pred
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

    attr_accessor :set
    def initialize(_target, _set)
        super(_target)
        self.serializationType = Transition::SET
        if _set then
           @set = _set
        else
            @set = IntervalSet.of(Token::INVALID_TYPE)
        end
    end
    def label
        self.set
    end
    def matches(symbol, minVocabSymbol,  maxVocabSymbol)
        self.set.member? symbol
    end

    def to_s
        self.set.to_s
    end
end

class NotSetTransition < SetTransition

    def initialize(_target, _set)
        super(_target, _set)
        self.serializationType = Transition::NOT_SET
    end

    def matches( symbol, minVocabSymbol,  maxVocabSymbol)
        symbol >= minVocabSymbol \
            and symbol <= maxVocabSymbol \
            and not (self.set.member? symbol)
    end

    def to_s
        return '~' + super()
    end
end

class WildcardTransition < Transition

    def initialize(_target)
        super(_target)
        self.serializationType = Transition::WILDCARD
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
    def initialize(_target, precedence)
        super(_target)
        self.serializationType = Transition::PRECEDENCE
        self.precedence = precedence
        self.isEpsilon = true
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
             EpsilonTransition => Transition::EPSILON,
             RangeTransition => Transition::RANGE,
             RuleTransition => Transition::RULE,
             PredicateTransition => Transition::PREDICATE,
             AtomTransition => Transition::ATOM,
             ActionTransition => Transition::ACTION,
             SetTransition => Transition::SET,
             NotSetTransition => Transition::NOT_SET,
             WildcardTransition => Transition::WILDCARD,
             PrecedencePredicateTransition => Transition::PRECEDENCE
}
