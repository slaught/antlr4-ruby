#from antlr4.IntervalSet import IntervalSet
#from antlr4.Token import Token
require 'Token'
#from antlr4.PredictionContext import PredictionContext, SingletonPredictionContext, PredictionContextFromRuleContext
#from antlr4.RuleContext import RuleContext
#from antlr4.atn.ATN import ATN
#from antlr4.atn.ATNConfig import ATNConfig
#from antlr4.atn.ATNState import ATNState, RuleStopState
#from antlr4.atn.Transition import WildcardTransition, NotSetTransition, AbstractPredicateTransition, RuleTransition

require 'set'


class LL1Analyzer 
    #  Special value added to the lookahead sets to indicate that we hit
    #  a predicate during analysis if {@code seeThruPreds==false}.
    HIT_PRED = Token.INVALID_TYPE

    attr_accessor :atn, 
    def initialize(atn)
        @atn = atn
    end

    #*
    # Calculates the SLL(1) expected lookahead set for each outgoing transition
    # of an {@link ATNState}. The returned array has one element for each
    # outgoing transition in {@code s}. If the closure from transition
    # <em>i</em> leads to a semantic predicate before matching a symbol, the
    # element at index <em>i</em> of the result will be {@code null}.
    #
    # @param s the ATN state
    # @return the expected symbols for each outgoing transition of {@code s}.
    #/
    def getDecisionLookahead(s)
        return nil if s.nil? 

        count = s.transitions.length()
        look = Array.new
        for alt in 0..count-1
            look[alt] = Set.new()
            lookBusy = Set.new()
            seeThruPreds = false # fail to get lookahead upon pred
            self._LOOK(s.transition(alt).target, nil, PredictionContext.EMPTY, \
                  look[alt], lookBusy, Set.new(), seeThruPreds, false)
            # Wipe out lookahead for this alternative if we found nothing
            # or we had a predicate when we !seeThruPreds
            if look[alt].length==0 or look[alt].member? self.HIT_PRED then
                look[alt] = nil
            end
        end
        return look
    end

    #*
    # Compute set of tokens that can follow {@code s} in the ATN in the
    # specified {@code ctx}.
    #
    # <p>If {@code ctx} is {@code null} and the end of the rule containing
    # {@code s} is reached, {@link Token#EPSILON} is added to the result set.
    # If {@code ctx} is not {@code null} and the end of the outermost rule is
    # reached, {@link Token#EOF} is added to the result set.</p>
    #
    # @param s the ATN state
    # @param stopState the ATN state to stop at. This can be a
    # {@link BlockEndState} to detect epsilon paths through a closure.
    # @param ctx the complete parser context, or {@code null} if the context
    # should be ignored
    #
    # @return The set of tokens that can follow {@code s} in the ATN in the
    # specified {@code ctx}.
    #/
    def LOOK(s, stopState=nil, ctx=nil )
        r = IntervalSet.new()
        seeThruPreds = true # ignore preds; get all lookahead
        if not ctx.nil? then
            lookContext = PredictionContextFromRuleContext.new(s.atn, ctx) 
        else 
            lookContext = nil
        end
        # lookContext = PredictionContextFromRuleContext(s.atn, ctx) if ctx is not None else None
        self._LOOK(s, stopState, lookContext, r, Set.new(), Set.new(), seeThruPreds, true)
        return r
    end

    #*
    # Compute set of tokens that can follow {@code s} in the ATN in the
    # specified {@code ctx}.
    #
    # <p>If {@code ctx} is {@code null} and {@code stopState} or the end of the
    # rule containing {@code s} is reached, {@link Token#EPSILON} is added to
    # the result set. If {@code ctx} is not {@code null} and {@code addEOF} is
    # {@code true} and {@code stopState} or the end of the outermost rule is
    # reached, {@link Token#EOF} is added to the result set.</p>
    #
    # @param s the ATN state.
    # @param stopState the ATN state to stop at. This can be a
    # {@link BlockEndState} to detect epsilon paths through a closure.
    # @param ctx The outer context, or {@code null} if the outer context should
    # not be used.
    # @param look The result lookahead set.
    # @param lookBusy A set used for preventing epsilon closures in the ATN
    # from causing a stack overflow. Outside code should pass
    # {@code new HashSet<ATNConfig>} for this argument.
    # @param calledRuleStack A set used for preventing left recursion in the
    # ATN from causing a stack overflow. Outside code should pass
    # {@code new BitSet()} for this argument.
    # @param seeThruPreds {@code true} to true semantic predicates as
    # implicitly {@code true} and "see through them", otherwise {@code false}
    # to treat semantic predicates as opaque and add {@link #HIT_PRED} to the
    # result if one is encountered.
    # @param addEOF Add {@link Token#EOF} to the result if the end of the
    # outermost context is reached. This parameter has no effect if {@code ctx}
    # is {@code null}.
    #/
    def _LOOK(s, stopState, ctx, look, lookBusy, \
                     calledRuleStack, seeThruPreds, addEOF)
        c = ATNConfig.new(s, 0, ctx)

        return if lookBusy.member? c
      
        lookBusy.add(c)

        if s == stopState then
            if ctx.nil?  then
                look.addOne(Token.EPSILON)
                return
            elsif ctx.isEmpty() and addEOF
                look.addOne(Token.EOF)
                return
            end
        end

        if s.kind_of? RuleStopState then
            if ctx.nil? then 
                look.addOne(Token.EPSILON)
                return
            elsif ctx.isEmpty() and addEOF
                look.addOne(Token.EOF)
                return
            end
            if ctx != PredictionContext.EMPTY
                # run thru all possible stack tops in ctx
                for i in 0..ctx.length-1  do
                    returnState = self.atn.states[ctx.getReturnState(i)]
                    removed = calledRuleStack.member? returnState.ruleIndex 
                    begin
                        calledRuleStack.discard(returnState.ruleIndex)
                        self._LOOK(returnState, stopState, ctx.getParent(i), look, lookBusy, calledRuleStack, seeThruPreds, addEOF)
                    ensure 
                        calledRuleStack.add(returnState.ruleIndex) if removed
                    end
                end
                return
            end
        end
        for t in s.transitions do 
            if t.class == RuleTransition then
                next if calledRuleStack.member? t.target.ruleIndex 

                newContext = SingletonPredictionContext.create(ctx, t.followState.stateNumber)

                begin
                    calledRuleStack.add(t.target.ruleIndex)
                    self._LOOK(t.target, stopState, newContext, look, lookBusy, calledRuleStack, seeThruPreds, addEOF)
                ensure  
                    calledRuleStack.remove(t.target.ruleIndex)
                end
            elsif t.kind_of? AbstractPredicateTransition then
                if seeThruPreds
                    self._LOOK(t.target, stopState, ctx, look, lookBusy, calledRuleStack, seeThruPreds, addEOF)
                else
                    look.addOne(self.HIT_PRED)
                end
            elsif t.isEpsilon
                self._LOOK(t.target, stopState, ctx, look, lookBusy, calledRuleStack, seeThruPreds, addEOF)
            elsif t.class == WildcardTransition
                look.addRange( Token.MIN_USER_TOKEN_TYPE..self.atn.maxTokenType )
            else
                set = t.label
                if not set.nil? 
                    if t.kind_of? NotSetTransition then
                        set = Set.complement(Token.MIN_USER_TOKEN_TYPE, self.atn.maxTokenType)
                    end
                    look.addSet(set)
                end
            end
        end
    end
end
