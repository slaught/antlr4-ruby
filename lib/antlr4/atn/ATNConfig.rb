# A tuple: (ATN state, predicted alt, syntactic, semantic context).
#  The syntactic context is a graph-structured stack node whose
#  path(s) to the root is the rule invocation(s)
#  chain used to arrive at the state.  The semantic context is
#  the tree of semantic predicates encountered before reaching
#  an ATN state.

class ATNConfig

    def self.createConfigState(config, state)
        new(state,nil,nil,nil,config)
    end
    attr_accessor :reachesIntoOuterContext
    attr_accessor :state, :alt, :context, :semanticContext
    def initialize(state=nil, alt=nil, context=nil, semantic=nil, config=nil)
        if not config.nil?  then
            state = config.state if state.nil?
            alt = config.alt if alt.nil?
            context = config.context if context.nil? 
            semantic = config.semanticContext if semantic.nil?
            semantic = SemanticContext.NONE if semantic.nil?
        end

        #if not isinstance(state, ATNState):
        #    pass
        # The ATN state associated with this configuration#/
        @state = state
        # What alt (or lexer rule) is predicted by this configuration#/
        @alt = alt
        # The stack of invoking states leading to the rule/states associated
        #  with this config.  We track only those contexts pushed during
        #  execution of the ATN simulator.
        @context = context
        @semanticContext = semantic
        # We cannot execute predicates dependent upon local context unless
        # we know for sure we are in the correct context. Because there is
        # no way to do this efficiently, we simply cannot evaluate
        # dependent predicates unless we are in the rule that initially
        # invokes the ATN simulator.
        #
        # closure() tracks the depth of how far we dip into the
        # outer context: depth &gt; 0.  Note that it may not be totally
        # accurate depth since I don't ever decrement. TODO: make it a boolean then
        if config.nil? then
          @reachesIntoOuterContext = 0 
        else 
          @reachesIntoOuterContext = config.reachesIntoOuterContext
        end
    end

    # An ATN configuration is equal to another if both have
    #  the same state, they predict the same alternative, and
    #  syntactic/semantic contexts are the same.
    #/
    def eql?(other)
        self == other
    end
    def ==(other)
#        return true if self.equal? other
        self.equal?(other) or  \
        other.kind_of?(ATNConfig) and \
        (@state.stateNumber==other.state.stateNumber      and  
              @alt==other.alt and (@context==other.context) and 
              @semanticContext==other.semanticContext )
    end

    def hash
        "#{@state.stateNumber}/#{@alt}/#{@context}/#{@semanticContext}".hash
    end
    def toString(recog=nil, showAlt=true)
        to_s(recog,showAlt)
    end
    def to_s(recog=nil, showAlt=true) 
        StringIO.open  do |buf|
            buf.write('(')
            buf.write(self.state.to_s)
            if showAlt then
              buf.write(",")
              buf.write(self.alt.to_s)
            end
            if not self.context.nil? then
                buf.write(",[")
                buf.write(self.context.to_s)
                buf.write("]")
            end
            if self.semanticContext and (! self.semanticContext.equal?  SemanticContext.NONE) then
                buf.write(",")
                buf.write(self.semanticContext.to_s)
            end
            if self.reachesIntoOuterContext>0 then
                buf.write(",up=")
                buf.write(self.reachesIntoOuterContext.to_s)
            end
            buf.write(')')
            return buf.string()
        end
    end
end
# need a forward declaration

class LexerATNConfig < ATNConfig

    attr_accessor :passedThroughNonGreedyDecision, :lexerActionExecutor 
    def initialize(state, alt=nil, context=nil, semantic=SemanticContext.NONE, _lexerActionExecutor=nil, config=nil)
        super(state, alt, context, semantic, config)
        if not config.nil? then 
            _lexerActionExecutor = config.lexerActionExecutor if _lexerActionExecutor.nil? 
            @passedThroughNonGreedyDecision = self.checkNonGreedyDecision(config, state)
        else
           @passedThroughNonGreedyDecision = false 
        end
        # This is the backing field for {@link #getLexerActionExecutor}.
        @lexerActionExecutor = _lexerActionExecutor
    end

    def hash
        b = 0
        b = 1 if self.passedThroughNonGreedyDecision 
        [self.state.stateNumber, self.alt, self.context, 
          self.semanticContext, b, self.lexerActionExecutor
        ].map(&:to_s).join('').hash
    end
    def eql?(other)
        self == other
    end
    def ==(other)
        return true if self.equal? other
        return false unless other.kind_of? LexerATNConfig
        if self.passedThroughNonGreedyDecision != other.passedThroughNonGreedyDecision
            return false
        end
        if self.lexerActionExecutor == other.lexerActionExecutor
              super(other)
        else
            false
        end
    end
    def checkNonGreedyDecision(source, target)
        source.passedThroughNonGreedyDecision or (target.kind_of?(DecisionState) and target.nonGreedy )
    end
end
