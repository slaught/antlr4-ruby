#* A rule invocation record for parsing.
#
#  Contains all of the information about the current rule not stored in the
#  RuleContext. It handles parse tree children list, Any ATN state
#  tracing, and the default values available for rule indications:
#  start, stop, rule index, current alt number, current
#  ATN state.
#
#  Subclasses made for each rule and grammar track the parameters,
#  return values, locals, and labels specific to that rule. These
#  are the objects that are returned from rules.
#
#  Note text is not an actual field of a rule return value; it is computed
#  from start and stop using the input stream's toString() method.  I
#  could add a ctor to this so that we can pass in and store the input
#  stream, but I'm not sure we want to do that.  It would seem to be undefined
#  to get the .text property anyway if the rule matches tokens from multiple
#  input streams.
#
#  I do not use getters for fields of objects that are used simply to
#  group values such as this aggregate.  The getters/setters are there to
#  satisfy the superclass interface.

require 'RuleContext'
require 'Token'
require 'tree/Tree'

#from antlr4.RuleContext import RuleContext
#from antlr4.Token import Token
#from antlr4.tree.Tree import ParseTreeListener, ParseTree, TerminalNodeImpl, ErrorNodeImpl, TerminalNode, \
#    INVALID_INTERVAL

class ParserRuleContext < RuleContext

    attr_accessor :children, :start, :stop, :exception
    attr_accessor :parser
    def initialize(parent= nil, invoking_state_number= nil)
        super(parent, invoking_state_number)
        #* If we are debugging or building a parse tree for a visitor,
        #  we need to track all of the tokens and rule invocations associated
        #  with this rule's context. This is empty for parsing w/o tree constr.
        #  operation because we don't the need to track the details about
        #  how we parse this rule.
        #/
        @children = Array.new
        @start = nil
        @stop = nil
        # The exception that forced this rule to return. If the rule successfully
        # completed, this is {@code null}.
        @exception =nil
    end

    #* COPY a ctx (I'm deliberately not using copy constructor)#/
    def copyFrom(ctx)
        # from RuleContext
        self.parentCtx = ctx.parentCtx
        self.invokingState = ctx.invokingState
        self.children = Array.new
        self.start = ctx.start
        self.stop = ctx.stop
    end

    # Double dispatch methods for listeners
    def enterRule(listener)
    end
    def exitRule(listener)
    end

    #* Does not set parent link; other add methods do that#/
    def addChild(child)
        self.children.push(child)
        return child
    end
    #* Used by enterOuterAlt to toss out a RuleContext previously added as
    #  we entered a rule. If we have # label, we will need to remove
    #  generic ruleContext object.
    #/
    def removeLastChild()
       self.children.delete_at(-1) 
    end
    def addTokenNode(token)
        node = TerminalNodeImpl.new(token) #XXX
        self.addChild(node)
        node.parentCtx = self
        return node
    end

    def addErrorNode(badToken)
        node = ErrorNodeImpl.new(badToken)
        self.addChild(node)
        node.parentCtx = self
        return node
    end

    def getChild(i, type=nil )
        if type.nil? 
            if self.children.length >= i then
                return self.children[i] 
            end
        else
            for child in self.getChildren() do
                next if not child.kind_of?  type
                return child if i==0
                i = i - 1
            end
        end
        return nil
    end
    def getChildren
       @children
    end
    def getToken(ttype, i)
        self.getChildren().each  do |child|
            next if not child.kind_of? TerminalNode
            next if child.symbol.type != ttype
            return child if i==0
            i -= 1
                i = i - 1
        end
        return nil
    end
    def getTokens(ttype)
        return [] if self.getChildren().empty? 
        tokens = self.getChildren().map do |child|
            next if not child.kind_of? TerminalNode
            next if child.symbol.type != ttype
            child
        end.compact
        return tokens
    end

    def getTypedRuleContext(ctxType, i)
        return self.getChild(i, ctxType)
    end
    def getTypedRuleContexts(ctxType)
        return [] if self.getChildren().empty?
        contexts = self.getChildren.map do |child| 
            next if not child.kind_of? ctxType
            child
        end.compact
        return contexts
    end
    def getChildCount
        return self.children.length
    end

    def getSourceInterval
        if self.start.nil? or self.stop.nil? then
            return INVALID_INTERVAL
        else
            return [self.start.tokenIndex, self.stop.tokenIndex]
        end
    end
end

# RuleContext.set_empty(ParserRuleContext.new())

class InterpreterRuleContext < ParserRuleContext

    attr_accessor :ruleIndex
    def initialize(parent, invokingStateNumber, rule_index)
        super(parent, invokingStateNumber)
        @ruleIndex = rule_index
    end
end
