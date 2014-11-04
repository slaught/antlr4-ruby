
# A parser simulator that mimics what ANTLR's generated
#  parser code does. A ParserATNSimulator is used to make
#  predictions via adaptivePredict but this class moves a pointer through the
#  ATN to simulate parsing. ParserATNSimulator just
#  makes us efficient rather than having to backtrack, for example.
#
#  This properly creates parse trees even for left recursive rules.
#
#  We rely on the left recursive rule invocation and special predicate
#  transitions to make left recursive rules work.
#
#  See TestParserInterpreter for examples.
#
#from antlr4.dfa.DFA import DFA
#from antlr4.BufferedTokenStream import TokenStream
#from antlr4.Parser import Parser
#from antlr4.ParserRuleContext import InterpreterRuleContext, ParserRuleContext
#from antlr4.Token import Token
#from antlr4.atn.ATN import ATN
#from antlr4.atn.ATNState import StarLoopEntryState, ATNState, LoopEndState
#from antlr4.atn.ParserATNSimulator import ParserATNSimulator
#from antlr4.atn.PredictionContextCache import PredictionContextCache
#from antlr4.atn.Transition import Transition
#from antlr4.error.Errors import RecognitionException, UnsupportedOperationException, FailedPredicateException

require 'TokenStream'
require 'Parser'
require 'ParserRuleContext'
require 'Token'
require 'error'

require 'set'

class ParserInterpreter < Parser

    attr_accessor :parentContextStack, :atn, :grammarFileName
    attr_accessor :tokenNames, :ruleNames, :decisionToDFA,:sharedContextCache 
    attr_accessor :parentContextStack ,:pushRecursionContextStates , :interp
    def initialize(grammarFileName, tokenNames, ruleNames, atn, input)
        super(input)
        self.grammarFileName = grammarFileName
        self.atn = atn
        self.tokenNames = tokenNames
        self.ruleNames = ruleNames
        self.decisionToDFA = atn.decisionToState.map {|state| DFA.new(state) }
        self.sharedContextCache = PredictionContextCache.new()
        self.parentContextStack = Array.new
        # identify the ATN states where pushNewRecursionContext must be called
        self.pushRecursionContextStates = Set.new()
        atn.states.each do |state|
            next if not state.kind_of? StarLoopEntryState
            if state.precedenceRuleDecision
                self.pushRecursionContextStates.add(state.stateNumber)
            end
        end
        # get atn simulator that knows how to do predictions
        self.interp = ParserATNSimulator.new(self, atn, self.decisionToDFA, self.sharedContextCache)
    end
    # Begin parsing at startRuleIndex#
    def parse(startRuleIndex)
        startRuleStartState = self.atn.ruleToStartState[startRuleIndex]
        rootContext = InterpreterRuleContext.new(nil, ATNState::INVALID_STATE_NUMBER, startRuleIndex)
        if startRuleStartState.isPrecedenceRule
            self.enterRecursionRule(rootContext, startRuleStartState.stateNumber, startRuleIndex, 0)
        else
            self.enterRule(rootContext, startRuleStartState.stateNumber, startRuleIndex)
        end
        while true
            p = self.getATNState()
            if p.stateType==ATNState::RULE_STOP 
                # pop; return from rule
                if self.ctx.length==0
                    if startRuleStartState.isPrecedenceRule
                        result = self.ctx
                        parentContext = self.parentContextStack.pop()
                        self.unrollRecursionContexts(parentContext.a)
                        return result
                    else
                        self.exitRule()
                        return rootContext
                    end
                end
                self.visitRuleStopState(p)
            else
                begin
                    self.visitState(p)
                rescue RecognitionException => e
                    self.state = self.atn.ruleToStopState[p.ruleIndex].stateNumber
                    self.ctx.exception = e
                    self.errHandler.reportError(self, e)
                    self.errHandler.recover(self, e)
                end
            end
        end
    end
    def enterRecursionRule(localctx, state, ruleIndex, precedence)
        self.parentContextStack.push([self.ctx, localctx.invokingState])
        super.enterRecursionRule(localctx, state, ruleIndex, precedence)
    end
    def getATNState
        return self.atn.states[self.state]
    end

    def visitState(p)
        edge = 0
        if p.transitions.length() > 1
            self.errHandler.sync(self)
            edge = self.interp.adaptivePredict(self.input, p.decision, self.ctx)
        else
            edge = 1
        end

        transition = p.transitions[edge - 1]
        tt = transition.serializationType
        if tt==Transition.EPSILON then

            if self.pushRecursionContextStates[p.stateNumber] and not transition.target.kind_of? LoopEndState
                t = self.parentContextStack[-1]
                ctx = InterpreterRuleContext.new(t[0], t[1], self.ctx.ruleIndex)
                self.pushNewRecursionContext(ctx, self.atn.ruleToStartState[p.ruleIndex].stateNumber, self.ctx.ruleIndex)
            end
        elsif tt==Transition.ATOM
            self.match(transition.label)
        elsif [ Transition.RANGE, Transition.SET, Transition.NOT_SET].member? tt 
            if not transition.matches(self.input.LA(1), Token.MIN_USER_TOKEN_TYPE, 0xFFFF)
                self.errHandler.recoverInline(self)
            end
            self.matchWildcard()
        elsif tt==Transition.WILDCARD
            self.matchWildcard()
        elsif tt==Transition.RULE
            ruleStartState = transition.target
            ruleIndex = ruleStartState.ruleIndex
            ctx = InterpreterRuleContext(self.ctx, p.stateNumber, ruleIndex)
            if ruleStartState.isPrecedenceRule
                self.enterRecursionRule(ctx, ruleStartState.stateNumber, ruleIndex, transition.precedence)
            else
                self.enterRule(ctx, transition.target.stateNumber, ruleIndex)
            end
        elsif tt==Transition.PREDICATE
            if not self.sempred(self.ctx, transition.ruleIndex, transition.predIndex)
                raise FailedPredicateException.new(self)
            end
        elsif tt==Transition.ACTION
            self.action(self.ctx, transition.ruleIndex, transition.actionIndex)
        elsif tt==Transition.PRECEDENCE
            if not self.precpred(self.ctx, transition.precedence)
                msg = "precpred(ctx, #{transition.precedence})"
                raise FailedPredicateException.new(self, msg)
            end
        else
            raise UnsupportedOperationException.new("Unrecognized ATN transition type.")
        end
        self.state = transition.target.stateNumber
    end
    def visitRuleStopState(p) # p:ATNState)
        ruleStartState = self.atn.ruleToStartState[p.ruleIndex]
        if ruleStartState.isPrecedenceRule then
            parentContext = self.parentContextStack.pop()
            self.unrollRecursionContexts(parentContext.a)
            self.state = parentContext[1]
        else
            self.exitRule()
        end
        ruleTransition = self.atn.states[self.state].transitions[0]
        self.state = ruleTransition.followState.stateNumber
    end
end
