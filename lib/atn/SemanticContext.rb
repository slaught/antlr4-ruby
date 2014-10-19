# A tree structure used to record the semantic context in which
#  an ATN configuration is valid.  It's either a single predicate,
#  a conjunction {@code p1&&p2}, or a sum of products {@code p1||p2}.
#
#  <p>I have scoped the {@link AND}, {@link OR}, and {@link Predicate} subclasses of
#  {@link SemanticContext} within the scope of this outer class.</p>

#from io import StringIO
#from antlr4.Recognizer import Recognizer
#from antlr4.RuleContext import RuleContext
require 'Recognizer'
require 'RuleContext'

class SemanticContext
    # The default {@link SemanticContext}, which is semantically equivalent to
    # a predicate of the form {@code {true}?}.
    @@NONE = nil
    def NONE
      @@NONE = SemanticContext.new if @@NONE.nil?  
      @@NONE
    end
    attr_accessor :opnds
    # For context independent predicates, we evaluate them without a local
    # context (i.e., null context). That way, we can evaluate them without
    # having to create proper rule-specific context during prediction (as
    # opposed to the parser, which creates them naturally). In a practical
    # sense, this avoids a cast exception from RuleContext to myruleContext.
    #
    # <p>For context dependent predicates, we must pass in a local context so that
    # references such as $arg evaluate properly as _localctx.arg. We only
    # capture context dependent predicates in the context in which we begin
    # prediction, so we passed in the outer context here in case of context
    # dependent predicate evaluation.</p>
    #
    def eval(parser, outerContext)
    end
    #
    # Evaluate the precedence predicates for the context and reduce the result.
    #
    # @param parser The parser instance.
    # @param outerContext The current parser context object.
    # @return The simplified semantic context after precedence predicates are
    # evaluated, which will be one of the following values.
    # <ul>
    # <li>{@link #NONE}: if the predicate simplifies to {@code true} after
    # precedence predicates are evaluated.</li>
    # <li>{@code null}: if the predicate simplifies to {@code false} after
    # precedence predicates are evaluated.</li>
    # <li>{@code this}: if the semantic context is not changed as a result of
    # precedence predicate evaluation.</li>
    # <li>A non-{@code null} {@link SemanticContext}: the new simplified
    # semantic context after precedence predicates are evaluated.</li>
    # </ul>
    #
    def evalPrecedence(parser, outerContext)
        return self
    end

    def simplify
        if self.opnds.length == 1 then
          self.opnds.first 
        else
          self
        end
    end

    def andContext(b)
        SemanticContext.andContext(self, b)
    end
    def self.andContext(a, b)
      return b if a.nil? or a === SemanticContext.NONE
      return a if b.nil? or b === SemanticContext.NONE
      result = AND.new(a, b)
      return result.simplify
    end
    def orContext(b)
        SemanticContext.orContext(self, b)
    end
    def self.orContext(a, b)
        return b if a.nil? 
        return a if b.nil? 
        if a === SemanticContext.NONE or b === SemanticContext.NONE
            return SemanticContext.NONE
        end
        result = OR.new(a, b)
        return result.simplify
    end

    def self.filterPrecedencePredicates(collection)
        collection.map {|context|
            if context.kind_of? PrecedencePredicate then
               context
            end
        }.compact
    end
end

class Predicate < SemanticContext

    attr_accessor :ruleIndex, :predIndex, :isCtxDependent 
    def initialize(ruleIndex=-1, predIndex=-1, isCtxDependent=false)
        self.ruleIndex = ruleIndex
        self.predIndex = predIndex
        self.isCtxDependent = isCtxDependent # e.g., $i ref in pred
    end

    def eval(parser, outerContext)
        #localctx = outerContext if self.isCtxDependent else None
        if self.isCtxDependent 
          localctx = outerContext 
        else 
          localctx = nil
        end
        return parser.sempred(localctx, self.ruleIndex, self.predIndex)
    end
    def hash
        StringIO.new() do |buf|
            buf.write(self.ruleIndex.to_s)
            buf.write("/")
            buf.write(self.predIndex.to_s)
            buf.write("/")
            buf.write(self.isCtxDependent.to_s)
            return buf.string().hash 
        end
    end
    def eq?(other)
      self == other
    end
    def ==(other)
        self === other or other.kind_of?(Predicate) and \
              self.ruleIndex == other.ruleIndex and \
               self.predIndex == other.predIndex and \
               self.isCtxDependent == other.isCtxDependent
    end
    def to_s
      "{#{self.ruleIndex}:#{self.predIndex}}?"
    end
end

class PrecedencePredicate < SemanticContext

    attr_accessor :precedence 
    def initialize(precedence=0)
        self.precedence = precedence
    end

    def eval(parser, outerContext)
        return parser.precpred(outerContext, self.precedence)
    end

    def evalPrecedence(parser, outerContext)
        if parser.precpred(outerContext, self.precedence)
            return SemanticContext.NONE
        else
            return nil
        end
    end
    def <=>(other)
        return self.precedence - other.precedence
    end

    def hash
        return 31
    end

    def eql?(other)
        self == other
    end
    def ==(other)
        self === other or other.kind_of?(PrecedencePredicate) and self.precedence == other.precedence
    end
end
# A semantic context which is true whenever none of the contained contexts
# is false.
#
class AND < SemanticContext

    def initialize(a, b)
        operands = Set.new()
        if a.kind_of? AND then
            a.opnds.each {|o| operands.add(o) }
        else
            operands.add(a)
        end
        if b.kind_of? AND then
            b.opnds.each {|o| operands.add(o) }
        else
            operands.add(b)
        end
        precedencePredicates = filterPrecedencePredicates(operands)
        if precedencePredicates.length>0 then
            # interested in the transition with the lowest precedence
            reduced = precedencePredicates.min
            operands.add(reduced)
        end
        @opnds = operands.to_a
    end

    def eql?(other)
      self == other
    end
    def ==(other)
        self === other or \
        other.kind_of? AND and self.opnds == other.opnds
    end
    
    def hash 
       "#{self.opnds}/AND".hash
    end

    #
    # {@inheritDoc}
    #
    # <p>
    # The evaluation of predicates by this context is short-circuiting, but
    # unordered.</p>
    #
    def eval(parser, outerContext)
        self.opnds.each {|opnd|
            if not opnd.eval(parser, outerContext)
                return false
            end
        }
        return true
    end

    def evalPrecedence(parser, outerContext)
        differs = false
        operands = Array.new
        self.opnds.each {|context|
            evaluated = context.evalPrecedence(parser, outerContext)
            if evaluated === context then
                differs = false
            else
                differs = true
            end
#            differs = differs || (! (evaluated === context))
            # The AND context is false if any element is false
            return nil if evaluated.nil? 
            if evaluated === SemanticContext.NONE
                # Reduce the result by skipping true elements
                operands.append(evaluated)
            end
        }
        if not differs
            return self
        end

        if operands.length()==0
            # all elements were true, so the AND context is true
            return SemanticContext.NONE
        end

        result = nil
        operands.each {|o| 
            if result.nil? 
                result = o 
            else 
              result = result.andContext(o)
            end
        }
        return result
    end
    def  to_s
        self.opnds.map(&:to_s).join("&&") 
    end
end
#
# A semantic context which is true whenever at least one of the contained
# contexts is true.
#
class OR < SemanticContext

    def initialize(a, b)
        operands = Set.new()
        if a.kind_of? OR then
            a.opnds.each {|o| operands.add(o) }
        else
            operands.add(a)
        end
        if b.kind_of? OR then
            b.opnds.each {|o| operands.add(o) }
        else
            operands.add(b)
        end
        precedencePredicates = filterPrecedencePredicates(operands)
        if precedencePredicates.length() > 0 then
            # interested in the transition with the highest precedence
            s = precedencePredicates.sort()
            reduced = s[-1]
            operands.add(reduced)
        end
        self.opnds = operands.to_a
    end

    def eql?(other)
        self == other
    end
    def ==(other)
        self ===other or other.kind_of? OR and self.opnds == other.opnds
    end
    def hash
        "#{self.opnds}/OR".hash
    end

    # <p>
    # The evaluation of predicates by this context is short-circuiting, but
    # unordered.</p>
    #
    def eval(parser, outerContext)
      
        self.opnds.each {|opnd|
            if opnd.eval(parser, outerContext)
                return true
            end
        }
        return false
    end

    def evalPrecedence(parser, outerContext)
        differs = false
        operands = []
        operands = self.opnds.map {|context|
            evaluated = context.evalPrecedence(parser, outerContext)
            if evaluated === context then
                differs = false
            else
                differs = true
            end
            #differs = differs || not (evaluated === context)
            # The OR context is true if any element is true
            return SemanticContext.NONE if evaluate === SemanticContext.NONE
            if not evaluated.nil? then 
                # Reduce the result by skipping false elements
                evaluated
            end
        }.compact
        return self unless differs

        if operands.empty?
            # all elements were false, so the OR context is false
            return nil
        end

        result = nil
        operands.each {|o| 
            if result.nil? 
                result = o 
            else 
              result = result.orContext(o)
            end
        }
        return result
    end
    def to_s
        self.opnds.map(&:to_s).join("||")
    end
end
# SemanticContext.NONE = Predicate()
