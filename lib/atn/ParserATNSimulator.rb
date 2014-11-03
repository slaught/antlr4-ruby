#
# The embodiment of the adaptive LL(*), ALL(*), parsing strategy.
#
# <p>
# The basic complexity of the adaptive strategy makes it harder to understand.
# We begin with ATN simulation to build paths in a DFA. Subsequent prediction
# requests go through the DFA first. If they reach a state without an edge for
# the current symbol, the algorithm fails over to the ATN simulation to
# complete the DFA path for the current input (until it finds a conflict state
# or uniquely predicting state).</p>
#
# <p>
# All of that is done without using the outer context because we want to create
# a DFA that is not dependent upon the rule invocation stack when we do a
# prediction. One DFA works in all contexts. We avoid using context not
# necessarily because it's slower, although it can be, but because of the DFA
# caching problem. The closure routine only considers the rule invocation stack
# created during prediction beginning in the decision rule. For example, if
# prediction occurs without invoking another rule's ATN, there are no context
# stacks in the configurations. When lack of context leads to a conflict, we
# don't know if it's an ambiguity or a weakness in the strong LL(*) parsing
# strategy (versus full LL(*)).</p>
#
# <p>
# When SLL yields a configuration set with conflict, we rewind the input and
# retry the ATN simulation, this time using full outer context without adding
# to the DFA. Configuration context stacks will be the full invocation stacks
# from the start rule. If we get a conflict using full context, then we can
# definitively say we have a true ambiguity for that input sequence. If we
# don't get a conflict, it implies that the decision is sensitive to the outer
# context. (It is not context-sensitive in the sense of context-sensitive
# grammars.)</p>
#
# <p>
# The next time we reach this DFA state with an SLL conflict, through DFA
# simulation, we will again retry the ATN simulation using full context mode.
# This is slow because we can't save the results and have to "interpret" the
# ATN each time we get that input.</p>
#
# <p>
# <strong>CACHING FULL CONTEXT PREDICTIONS</strong></p>
#
# <p>
# We could cache results from full context to predicted alternative easily and
# that saves a lot of time but doesn't work in presence of predicates. The set
# of visible predicates from the ATN start state changes depending on the
# context, because closure can fall off the end of a rule. I tried to cache
# tuples (stack context, semantic context, predicted alt) but it was slower
# than interpreting and much more complicated. Also required a huge amount of
# memory. The goal is not to create the world's fastest parser anyway. I'd like
# to keep this algorithm simple. By launching multiple threads, we can improve
# the speed of parsing across a large number of files.</p>
#
# <p>
# There is no strict ordering between the amount of input used by SLL vs LL,
# which makes it really hard to build a cache for full context. Let's say that
# we have input A B C that leads to an SLL conflict with full context X. That
# implies that using X we might only use A B but we could also use A B C D to
# resolve conflict. Input A B C D could predict alternative 1 in one position
# in the input and A B C E could predict alternative 2 in another position in
# input. The conflicting SLL configurations could still be non-unique in the
# full context prediction, which would lead us to requiring more input than the
# original A B C.	To make a	prediction cache work, we have to track	the exact
# input	used during the previous prediction. That amounts to a cache that maps
# X to a specific DFA for that context.</p>
#
# <p>
# Something should be done for left-recursive expression predictions. They are
# likely LL(1) + pred eval. Easier to do the whole SLL unless error and retry
# with full LL thing Sam does.</p>
#
# <p>
# <strong>AVOIDING FULL CONTEXT PREDICTION</strong></p>
#
# <p>
# We avoid doing full context retry when the outer context is empty, we did not
# dip into the outer context by falling off the end of the decision state rule,
# or when we force SLL mode.</p>
#
# <p>
# As an example of the not dip into outer context case, consider as super
# constructor calls versus function calls. One grammar might look like
# this:</p>
#
# <pre>
# ctorBody
#   : '{' superCall? stat* '}'
#   ;
# </pre>
#
# <p>
# Or, you might see something like</p>
#
# <pre>
# stat
#   : superCall ';'
#   | expression ';'
#   | ...
#   ;
# </pre>
#
# <p>
# In both cases I believe that no closure operations will dip into the outer
# context. In the first case ctorBody in the worst case will stop at the '}'.
# In the 2nd case it should stop at the ';'. Both cases should stay within the
# entry rule and not dip into the outer context.</p>
#
# <p>
# <strong>PREDICATES</strong></p>
#
# <p>
# Predicates are always evaluated if present in either SLL or LL both. SLL and
# LL simulation deals with predicates differently. SLL collects predicates as
# it performs closure operations like ANTLR v3 did. It delays predicate
# evaluation until it reaches and accept state. This allows us to cache the SLL
# ATN simulation whereas, if we had evaluated predicates on-the-fly during
# closure, the DFA state configuration sets would be different and we couldn't
# build up a suitable DFA.</p>
#
# <p>
# When building a DFA accept state during ATN simulation, we evaluate any
# predicates and return the sole semantically valid alternative. If there is
# more than 1 alternative, we report an ambiguity. If there are 0 alternatives,
# we throw an exception. Alternatives without predicates act like they have
# true predicates. The simple way to think about it is to strip away all
# alternatives with false predicates and choose the minimum alternative that
# remains.</p>
#
# <p>
# When we start in the DFA and reach an accept state that's predicated, we test
# those and return the minimum semantically viable alternative. If no
# alternatives are viable, we throw an exception.</p>
#
# <p>
# During full LL ATN simulation, closure always evaluates predicates and
# on-the-fly. This is crucial to reducing the configuration set size during
# closure. It hits a landmine when parsing with the Java grammar, for example,
# without this on-the-fly evaluation.</p>
#
# <p>
# <strong>SHARING DFA</strong></p>
#
# <p>
# All instances of the same parser share the same decision DFAs through a
# static field. Each instance gets its own ATN simulator but they share the
# same {@link #decisionToDFA} field. They also share a
# {@link PredictionContextCache} object that makes sure that all
# {@link PredictionContext} objects are shared among the DFA states. This makes
# a big size difference.</p>
#
# <p>
# <strong>THREAD SAFETY</strong></p>
#
# <p>
# The {@link ParserATNSimulator} locks on the {@link #decisionToDFA} field when
# it adds a new DFA object to that array. {@link #addDFAEdge}
# locks on the DFA for the current decision when setting the
# {@link DFAState#edges} field. {@link #addDFAState} locks on
# the DFA for the current decision when looking up a DFA state to see if it
# already exists. We must make sure that all requests to add DFA states that
# are equivalent result in the same shared DFA object. This is because lots of
# threads will be trying to update the DFA at once. The
# {@link #addDFAState} method also locks inside the DFA lock
# but this time on the shared context cache when it rebuilds the
# configurations' {@link PredictionContext} objects using cached
# subgraphs/nodes. No other locking occurs, even during DFA simulation. This is
# safe as long as we can guarantee that all threads referencing
# {@code s.edge[t]} get the same physical target {@link DFAState}, or
# {@code null}. Once into the DFA, the DFA simulation does not reference the
# {@link DFA#states} map. It follows the {@link DFAState#edges} field to new
# targets. The DFA simulator will either find {@link DFAState#edges} to be
# {@code null}, to be non-{@code null} and {@code dfa.edges[t]} null, or
# {@code dfa.edges[t]} to be non-null. The
# {@link #addDFAEdge} method could be racing to set the field
# but in either case the DFA simulator works; if {@code null}, and requests ATN
# simulation. It could also race trying to get {@code dfa.edges[t]}, but either
# way it will work because it's not doing a test and set operation.</p>
#
# <p>
# <strong>Starting with SLL then failing to combined SLL/LL (Two-Stage
# Parsing)</strong></p>
#
# <p>
# Sam pointed out that if SLL does not give a syntax error, then there is no
# point in doing full LL, which is slower. We only have to try LL if we get a
# syntax error. For maximum speed, Sam starts the parser set to pure SLL
# mode with the {@link BailErrorStrategy}:</p>
#
# <pre>
# parser.{@link Parser#getInterpreter() getInterpreter()}.{@link #setPredictionMode setPredictionMode}{@code (}{@link PredictionMode#SLL}{@code )};
# parser.{@link Parser#setErrorHandler setErrorHandler}(new {@link BailErrorStrategy}());
# </pre>
#
# <p>
# If it does not get a syntax error, then we're done. If it does get a syntax
# error, we need to retry with the combined SLL/LL strategy.</p>
#
# <p>
# The reason this works is as follows. If there are no SLL conflicts, then the
# grammar is SLL (at least for that input set). If there is an SLL conflict,
# the full LL analysis must yield a set of viable alternatives which is a
# subset of the alternatives reported by SLL. If the LL set is a singleton,
# then the grammar is LL but not SLL. If the LL set is the same size as the SLL
# set, the decision is SLL. If the LL set has size &gt; 1, then that decision
# is truly ambiguous on the current input. If the LL set is smaller, then the
# SLL conflict resolution might choose an alternative that the full LL would
# rule out as a possibility based upon better context information. If that's
# the case, then the SLL parse will definitely get an error because the full LL
# analysis says it's not viable. If SLL conflict resolution chooses an
# alternative within the LL set, them both SLL and LL would choose the same
# alternative because they both choose the minimum of multiple conflicting
# alternatives.</p>
#
# <p>
# Let's say we have a set of SLL conflicting alternatives {@code {1, 2, 3}} and
# a smaller LL set called <em>s</em>. If <em>s</em> is {@code {2, 3}}, then SLL
# parsing will get an error because SLL will pursue alternative 1. If
# <em>s</em> is {@code {1, 2}} or {@code {1, 3}} then both SLL and LL will
# choose the same alternative because alternative one is the minimum of either
# set. If <em>s</em> is {@code {2}} or {@code {3}} then SLL will get a syntax
# error. If <em>s</em> is {@code {1}} then SLL will succeed.</p>
#
# <p>
# Of course, if the input is invalid, then we will get an error for sure in
# both SLL and LL parsing. Erroneous input will therefore require 2 passes over
# the input.</p>
#
require 'dfa/DFA'
require 'PredictionContext'
require 'TokenStream'
require 'Parser'
require 'ParserRuleContext'
require 'RuleContext'
require 'Token'
require 'atn/ATN'
require 'atn/ATNConfig'
require 'atn/ATNConfigSet'
require 'atn/ATNSimulator'
require 'atn/ATNState'
require 'atn/PredictionMode'
require 'atn/SemanticContext'
require 'atn/Transition'
require 'dfa/DFAState'
require 'error'


class ParserATNSimulator < ATNSimulator
    include PredictionContextFunctions

    class << self
      attr_reader :debug, :dfa_debug, :debug_list_atn_decisions,:retry_debug 
    end
    @@debug = false
    @@dfa_debug = false
    @@debug_list_atn_decisions = false
    @@retry_debug = false

    def debug; @@debug ;end
    def dfa_debug; @@dfa_debug ;end

    def debug_list_atn_decisions; @@debug_list_atn_decisions ; end
    def retry_debug ; @@retry_debug ; end



    attr_accessor :decisionToDFA, :startIndex
    attr_accessor :parser, :predictionMode, :input, :outerContext, :mergeCache
    attr_accessor :_dfa

    def initialize(parser, atn, decisionToDFA, sharedContextCache)
        super(atn, sharedContextCache)
        self.parser = parser
        self.decisionToDFA = decisionToDFA
        # SLL, LL, or LL + exact ambig detection?#
        self.predictionMode = PredictionMode.LL
        # LAME globals to avoid parameters!!!!! I need these down deep in predTransition
        self.input = nil
        self.startIndex = 0
        self.outerContext = nil
        # Each prediction operation uses a cache for merge of prediction contexts.
        #  Don't keep around as it wastes huge amounts of memory. DoubleKeyMap
        #  isn't synchronized but we're ok since two threads shouldn't reuse same
        #  parser/atnsim object because it can only handle one input at a time.
        #  This maps graphs a and b to merged result c. (a,b)&rarr;c. We can avoid
        #  the merge if we ever see a and b again.  Note that (b,a)&rarr;c should
        #  also be examined during cache lookup.
        #
        self.mergeCache = nil
    end


    def reset()
    end

    def adaptivePredict(input, decision, outerContext)
        if self.debug or self.debug_list_atn_decisions then
            s1 = "adaptivePredict decision #{decision} exec LA(1)==" 
            s2 = "#{self.getLookaheadName(input)} line #{input.LT(1).line}:#{input.LT(1).column}"
            puts  "#{s1}#{s2}"
        end
#        type_check(TokenStream, input)
#        type_check(ParserRuleContext, outerContext)
        self.input = input
        self.startIndex = input.index
        self.outerContext = outerContext
        
        dfa = self.decisionToDFA[decision]
        @_dfa = dfa
        m = input.mark()
        index = input.index

        # Now we are certain to have a specific decision's DFA
        # But, do we still need an initial state?
        begin
            if dfa.precedenceDfa then
                # the start state for a precedence DFA depends on the current
                # parser precedence, and is provided by a DFA method.
                s0 = dfa.getPrecedenceStartState(self.parser.getPrecedence())
            else
                # the start state for a "regular" DFA is just s0
                s0 = dfa.s0
            end

            if s0.nil? 
                if outerContext.nil? 
                    outerContext = ParserRuleContext.EMPTY
                end
                if self.debug or self.debug_list_atn_decisions
                    puts  "predictATN decision #{dfa.decision
                       } exec LA(1)==#{self.getLookaheadName(input)
                       }, outerContext=#{outerContext.to_s}"
#                       }, outerContext=#{outerContext.toString(self.parser)}"
                end
                # If this is not a precedence DFA, we check the ATN start state
                # to determine if this ATN start state is the decision for the
                # closure block that determines whether a precedence rule
                # should continue or complete.
                #
                if not dfa.precedenceDfa and dfa.atnStartState.kind_of?  StarLoopEntryState then
                    if dfa.atnStartState.precedenceRuleDecision 
                        dfa.setPrecedenceDfa(true)
                    end
                end

                fullCtx = false
                type_check(ParserRuleContext.EMPTY(), ParserRuleContext)
                s0_closure = self.computeStartState(dfa.atnStartState, ParserRuleContext.EMPTY, fullCtx)

                if dfa.precedenceDfa
                    # If this is a precedence DFA, we use applyPrecedenceFilter
                    # to convert the computed start state to a precedence start
                    # state. We then use DFA.setPrecedenceStartState to set the
                    # appropriate start state for the precedence level rather
                    # than simply setting DFA.s0.
                    #
                    s0_closure = self.applyPrecedenceFilter(s0_closure)
                    s0 = self.addDFAState(dfa, DFAState.new(nil,s0_closure))
                    dfa.setPrecedenceStartState(self.parser.getPrecedence(), s0)
                else
                    s0 = self.addDFAState(dfa, DFAState.new(nil,s0_closure))
                    dfa.s0 = s0
                end
            end
            alt = self.execATN(dfa, s0, input, index, outerContext)
            if self.debug
                puts "DFA after predictATN: #{dfa.toString(self.parser.tokenNames)}"
            end
            return alt
        ensure
            self.mergeCache = nil# wack cache after each prediction
            input.seek(index)
            input.release(m)
            @_dfa = nil
        end
    end
    # Performs ATN simulation to compute a predicted alternative based
    #  upon the remaining input, but also updates the DFA cache to avoid
    #  having to traverse the ATN again for the same input sequence.

    # There are some key conditions we're looking for after computing a new
    # set of ATN configs (proposed DFA state):
          # if the set is empty, there is no viable alternative for current symbol
          # does the state uniquely predict an alternative?
          # does the state have a conflict that would prevent us from
          #   putting it on the work list?

    # We also have some key operations to do:
          # add an edge from previous DFA state to potentially new DFA state, D,
          #   upon current symbol but only if adding to work list, which means in all
          #   cases except no viable alternative (and possibly non-greedy decisions?)
          # collecting predicates and adding semantic context to DFA accept states
          # adding rule context to context-sensitive DFA accept states
          # consuming an input symbol
          # reporting a conflict
          # reporting an ambiguity
          # reporting a context sensitivity
          # reporting insufficient predicates

    # cover these cases:
    #    dead end
    #    single alt
    #    single alt + preds
    #    conflict
    #    conflict + preds
    #
    def execATN(dfa, s0, input, startIndex, outerContext)
        type_check( outerContext, ParserRuleContext )
        if self.debug or self.debug_list_atn_decisions
            print "execATN decision #{dfa.decision
                  } exec LA(1)==#{self.getLookaheadName(input) 
                  } line #{input.LT(1).line}:#{input.LT(1).column}"
        end
        previousD = s0

        if self.debug
            print "s0 = #{s0}"
        end
        t = input.LA(1)
        while true do # while more work
            cD = self.getExistingTargetState(previousD, t)
            if cD.nil? 
                cD = self.computeTargetState(dfa, previousD, t)
            end
            if cD ==  ATNSimulator.ERROR
                # if any configs in previous dipped into outer context, that
                # means that input up to t actually finished entry rule
                # at least for SLL decision. Full LL doesn't dip into outer
                # so don't need special case.
                # We will get an error no matter what so delay until after
                # decision; better error message. Also, no reachable target
                # ATN states in SLL implies LL will also get nowhere.
                # If conflict in states that dip out, choose min since we
                # will get error no matter what.
                e = self.noViableAlt(input, outerContext, previousD.configs, startIndex)
                input.seek(startIndex)
                alt = self.getSynValidOrSemInvalidAltThatFinishedDecisionEntryRule(previousD.configs, outerContext)
                if alt!=ATN.INVALID_ALT_NUMBER
                    return alt
                end
                raise e
            end
            if cD.requiresFullContext and self.predictionMode != PredictionMode.SLL
                # IF PREDS, MIGHT RESOLVE TO SINGLE ALT => SLL (or syntax error)
                conflictingAlts = nil
                if cD.predicates then
                    if self.debug
                        print("DFA state has preds in DFA sim LL failover")
                    end
                    conflictIndex = input.index
                    if conflictIndex != startIndex
                        input.seek(startIndex)
                    end
                    conflictingAlts = self.evalSemanticContext(cD.predicates, outerContext, true)
                    if conflictingAlts.length==1
                        if self.debug
                            print("Full LL avoided")
                        end
                        return conflictingAlts.min
                    end
                    if conflictIndex != startIndex
                        # restore the index so reporting the fallback to full
                        # context occurs with the index at the correct spot
                        input.seek(conflictIndex)
                    end
                end
                if self.dfa_debug
                    print "ctx sensitive state #{outerContext} in #{cD}" 
                end
                fullCtx = true
                s0_closure = self.computeStartState(dfa.atnStartState, outerContext, fullCtx)
                self.reportAttemptingFullContext(dfa, conflictingAlts, cD.configs, startIndex, input.index)
                alt = self.execATNWithFullContext(dfa, cD, s0_closure, input, startIndex, outerContext)
                return alt
            end

            if cD.isAcceptState
                if cD.predicates.nil? 
                    return cD.prediction
                end
                stopIndex = input.index
                input.seek(startIndex)
                alts = self.evalSemanticContext(cD.predicates, outerContext, true)
                if alts.length==0
                    raise self.noViableAlt(input, outerContext, cD.configs, startIndex)
                elsif alts.length==1
                    return alts.min
                else
                    # report ambiguity after predicate evaluation to make sure the correct
                    # set of ambig alts is reported.
                    self.reportAmbiguity(dfa, cD, startIndex, stopIndex, false, alts, cD.configs)
                    return alts.min
                end
            end
            previousD = cD

            if t != Token.EOF
                input.consume()
                t = input.LA(1)
            end
        end
    end
    #
    # Get an existing target state for an edge in the DFA. If the target state
    # for the edge has not yet been computed or is otherwise not available,
    # this method returns {@code null}.
    #
    # @param previousD The current DFA state
    # @param t The next input symbol
    # @return The existing target DFA state for the given input symbol
    # {@code t}, or {@code null} if the target state for this edge is not
    # already cached
    #
    def getExistingTargetState(previousD, t)
        edges = previousD.edges
        if edges.nil? or t + 1 < 0 or t + 1 >= edges.length
            return nil
        else
            return edges[t + 1]
        end
    end
    #
    # Compute a target state for an edge in the DFA, and attempt to add the
    # computed state and corresponding edge to the DFA.
    #
    # @param dfa The DFA
    # @param previousD The current DFA state
    # @param t The next input symbol
    #
    # @return The computed target DFA state for the given input symbol
    # {@code t}. If {@code t} does not lead to a valid DFA state, this method
    # returns {@link #ERROR}.
    #
    def computeTargetState(dfa, previousD, t)
        reach = self.computeReachSet(previousD.configs, t, false)
        if reach.nil?
            self.addDFAEdge(dfa, previousD, t, ATNSimulator.ERROR)
            return ATNSimulator.ERROR
        end

        # create new target state; we'll add to DFA after it's complete
        cD = DFAState.new(nil,reach)

        predictedAlt = self.getUniqueAlt(reach)

        if self.debug
            altSubSets = PredictionMode.getConflictingAltSubsets(reach)
            puts "SLL altSubSets=#{altSubSets}, configs=#{reach
                }, predict=#{predictedAlt
                }, allSubsetsConflict=#{PredictionMode.allSubsetsConflict(altSubSets)
                }, conflictingAlts=#{self.getConflictingAlts(reach)}"
        end
        if predictedAlt!=ATN.INVALID_ALT_NUMBER
            # NO CONFLICT, UNIQUELY PREDICTED ALT
            cD.isAcceptState = true
            cD.configs.uniqueAlt = predictedAlt
            cD.prediction = predictedAlt
        elsif PredictionMode.hasSLLConflictTerminatingPrediction(self.predictionMode, reach)
            # MORE THAN ONE VIABLE ALTERNATIVE
            cD.configs.conflictingAlts = self.getConflictingAlts(reach)
            cD.requiresFullContext = true
            # in SLL-only mode, we will stop at this state and return the minimum alt
            cD.isAcceptState = true
            cD.prediction = cD.configs.conflictingAlts.min
        end
        if cD.isAcceptState and cD.configs.hasSemanticContext
            self.predicateDFAState(cD, self.atn.getDecisionState(dfa.decision))
            if cD.predicates then
                cD.prediction = ATN.INVALID_ALT_NUMBER
            end
        end

        # all adds to dfa are done after we've created full D state
        cD = self.addDFAEdge(dfa, previousD, t, cD)
        return cD
    end
    def predicateDFAState(dfaState, decisionState)
        # We need to test all predicates, even in DFA states that
        # uniquely predict alternative.
        nalts = decisionState.transitions.length
        # Update DFA so reach becomes accept state with (predicate,alt)
        # pairs if preds found for conflicting alts
        altsToCollectPredsFrom = self.getConflictingAltsOrUniqueAlt(dfaState.configs)
        altToPred = self.getPredsForAmbigAlts(altsToCollectPredsFrom, dfaState.configs, nalts)
        if altToPred 
            dfaState.predicates = self.getPredicatePredictions(altsToCollectPredsFrom, altToPred)
            dfaState.prediction = ATN.INVALID_ALT_NUMBER # make sure we use preds
        else
            # There are preds in configs but they might go away
            # when OR'd together like {p}? || NONE == NONE. If neither
            # alt has preds, resolve to min alt
            dfaState.prediction = altsToCollectPredsFrom.min
        end
    end
    # comes back with reach.uniqueAlt set to a valid alt
    def execATNWithFullContext(dfa, cD, # how far we got before failing over
                                     s0, input, startIndex, outerContext)
        if self.debug or self.debug_list_atn_decisions
            print "execATNWithFullContext #{s0}"
        end
        fullCtx = true
        foundExactAmbig = false
        reach = nil
        previous = s0
        input.seek(startIndex)
        t = input.LA(1)
        predictedAlt = -1
        while true do
            reach = self.computeReachSet(previous, t, fullCtx)
            if reach.nil?
                # if any configs in previous dipped into outer context, that
                # means that input up to t actually finished entry rule
                # at least for LL decision. Full LL doesn't dip into outer
                # so don't need special case.
                # We will get an error no matter what so delay until after
                # decision; better error message. Also, no reachable target
                # ATN states in SLL implies LL will also get nowhere.
                # If conflict in states that dip out, choose min since we
                # will get error no matter what.
                e = self.noViableAlt(input, outerContext, previous, startIndex)
                input.seek(startIndex)
                alt = self.getSynValidOrSemInvalidAltThatFinishedDecisionEntryRule(previous, outerContext)
                if alt!=ATN.INVALID_ALT_NUMBER
                    return alt
                else
                    raise e
                end
            end
            altSubSets = PredictionMode.getConflictingAltSubsets(reach)
            if self.debug
                print "LL altSubSets=#{altSubSets}, predict=#{PredictionMode.getUniqueAlt(altSubSets)
                      }, resolvesToJustOneViableAlt=#{PredictionMode.resolvesToJustOneViableAlt(altSubSets)}"
            end
            reach.uniqueAlt = self.getUniqueAlt(reach)
            # unique prediction?
            if reach.uniqueAlt!=ATN.INVALID_ALT_NUMBER
                predictedAlt = reach.uniqueAlt
                break
            elsif self.predictionMode != PredictionMode.LL_EXACT_AMBIG_DETECTION
                predictedAlt = PredictionMode.resolvesToJustOneViableAlt(altSubSets)
                if predictedAlt != ATN.INVALID_ALT_NUMBER
                    break
                end
            else
                # In exact ambiguity mode, we never try to terminate early.
                # Just keeps scarfing until we know what the conflict is
                if PredictionMode.allSubsetsConflict(altSubSets) and PredictionMode.allSubsetsEqual(altSubSets)
                    foundExactAmbig = true
                    predictedAlt = PredictionMode.getSingleViableAlt(altSubSets)
                    break
                end
                # else there are multiple non-conflicting subsets or
                # we're not sure what the ambiguity is yet.
                # So, keep going.
            end
            previous = reach
            if t != Token.EOF
                input.consume()
                t = input.LA(1)
            end
        end
        # If the configuration set uniquely predicts an alternative,
        # without conflict, then we know that it's a full LL decision
        # not SLL.
        if reach.uniqueAlt != ATN.INVALID_ALT_NUMBER 
            self.reportContextSensitivity(dfa, predictedAlt, reach, startIndex, input.index)
            return predictedAlt
        end
        # We do not check predicates here because we have checked them
        # on-the-fly when doing full context prediction.

        #
        # In non-exact ambiguity detection mode, we might	actually be able to
        # detect an exact ambiguity, but I'm not going to spend the cycles
        # needed to check. We only emit ambiguity warnings in exact ambiguity
        # mode.
        #
        # For example, we might know that we have conflicting configurations.
        # But, that does not mean that there is no way forward without a
        # conflict. It's possible to have nonconflicting alt subsets as in:

        # altSubSets=[{1, 2}, {1, 2}, {1}, {1, 2}]

        # from
        #
        #    [(17,1,[5 $]), (13,1,[5 10 $]), (21,1,[5 10 $]), (11,1,[$]),
        #     (13,2,[5 10 $]), (21,2,[5 10 $]), (11,2,[$])]
        #
        # In this case, (17,1,[5 $]) indicates there is some next sequence that
        # would resolve this without conflict to alternative 1. Any other viable
        # next sequence, however, is associated with a conflict.  We stop
        # looking for input because no amount of further lookahead will alter
        # the fact that we should predict alternative 1.  We just can't say for
        # sure that there is an ambiguity without looking further.

        self.reportAmbiguity(dfa, cD, startIndex, input.index, foundExactAmbig, nil, reach)

        return predictedAlt
    end
    def computeReachSet(closure, t, fullCtx)
        if self.debug
            print "in computeReachSet, starting closure: #{closure}"
        end

        if self.mergeCache.nil?
            self.mergeCache = Hash.new
        end

        intermediate = ATNConfigSet.new(fullCtx)

        # Configurations already in a rule stop state indicate reaching the end
        # of the decision rule (local context) or end of the start rule (full
        # context). Once reached, these configurations are never updated by a
        # closure operation, so they are handled separately for the performance
        # advantage of having a smaller intermediate set when calling closure.
        #
        # For full-context reach operations, separate handling is required to
        # ensure that the alternative matching the longest overall sequence is
        # chosen when multiple such configurations can match the input.
        
        skippedStopStates = nil

        # First figure out where we can reach on input t
        closure.each do |c|
            if self.debug
                puts "testing #{self.getTokenName(t)} at #{c}"
            end

            if c.state.kind_of? RuleStopState then
                #assert c.context.isEmpty()
                if fullCtx or t == Token.EOF
                    if skippedStopStates.nil?
                        skippedStopStates = Array.new
                    end
                    skippedStopStates.push(c)
                end
                next
            end
            #for trans in c.state.transitions do 
            c.state.transitions.each do |trans|
                target = self.getReachableTarget(trans, t)
                if target 
                  puts "computeReachSet: add reachable target"
                    intermediate.add(ATNConfig.createConfigState(c,target), self.mergeCache)
                end
            end
        end
        # Now figure out where the reach operation can take us...

        reach = nil

        # This block optimizes the reach operation for intermediate sets which
        # trivially indicate a termination state for the overall
        # adaptivePredict operation.
        #
        # The conditions assume that intermediate
        # contains all configurations relevant to the reach set, but this
        # condition is not true when one or more configurations have been
        # withheld in skippedStopStates.
        #
        if skippedStopStates.nil? 
            if intermediate.length==1
                # Don't pursue the closure if there is just one state.
                # It can only have one alternative; just add to result
                # Also don't pursue the closure if there is unique alternative
                # among the configurations.
                reach = intermediate
            elsif self.getUniqueAlt(intermediate)!=ATN.INVALID_ALT_NUMBER
                # Also don't pursue the closure if there is unique alternative
                # among the configurations.
                reach = intermediate
            end
        end
        # If the reach set could not be trivially determined, perform a closure
        # operation on the intermediate set to compute its initial value.
        #
        if reach.nil? 
            reach = ATNConfigSet.new(fullCtx)
            closureBusy = Set.new()
            treatEofAsEpsilon = t == Token.EOF
            intermediate.each {|c|
                self.closure(c, reach, closureBusy, false, fullCtx, treatEofAsEpsilon)
            }
        end
        if t == Token.EOF
            # After consuming EOF no additional input is possible, so we are
            # only interested in configurations which reached the end of the
            # decision rule (local context) or end of the start rule (full
            # context). Update reach to contain only these configurations. This
            # handles both explicit EOF transitions in the grammar and implicit
            # EOF transitions following the end of the decision or start rule.
            #
            # When reach==intermediate, no closure operation was performed. In
            # this case, removeAllConfigsNotInRuleStopState needs to check for
            # reachable rule stop states as well as configurations already in
            # a rule stop state.
            #
            # This is handled before the configurations in skippedStopStates,
            # because any configurations potentially added from that list are
            # already guaranteed to meet this condition whether or not it's
            # required.
            #
            reach = self.removeAllConfigsNotInRuleStopState(reach, reach.equal?(intermediate))
        end
        # If skippedStopStates is not null, then it contains at least one
        # configuration. For full-context reach operations, these
        # configurations reached the end of the start rule, in which case we
        # only add them back to reach if no configuration during the current
        # closure operation reached such a state. This ensures adaptivePredict
        # chooses an alternative matching the longest overall sequence when
        # multiple alternatives are viable.
        #
        if skippedStopStates and ( (not fullCtx) or (not PredictionMode.hasConfigInRuleStopState(reach)))
            #assert len(skippedStopStates)>0
            skippedStopStates.each {|c| reach.add(c, self.mergeCache) }
        end
        if reach.empty? 
            return nil
        else
            return reach
        end
    end
    #
    # Return a configuration set containing only the configurations from
    # {@code configs} which are in a {@link RuleStopState}. If all
    # configurations in {@code configs} are already in a rule stop state, this
    # method simply returns {@code configs}.
    #
    # <p>When {@code lookToEndOfRule} is true, this method uses
    # {@link ATN#nextTokens} for each configuration in {@code configs} which is
    # not already in a rule stop state to see if a rule stop state is reachable
    # from the configuration via epsilon-only transitions.</p>
    #
    # @param configs the configuration set to update
    # @param lookToEndOfRule when true, this method checks for rule stop states
    # reachable by epsilon-only transitions from each configuration in
    # {@code configs}.
    #
    # @return {@code configs} if all configurations in {@code configs} are in a
    # rule stop state, otherwise return a new configuration set containing only
    # the configurations from {@code configs} which are in a rule stop state
    #
    def removeAllConfigsNotInRuleStopState(configs, lookToEndOfRule)
        if PredictionMode.allConfigsInRuleStopStates(configs)
            return configs
        end
        result = ATNConfigSet.new(configs.fullCtx)
        configs.each do |config|
            if config.state.kind_of? RuleStopState then
                result.add(config, self.mergeCache)
                next 
            end
            if lookToEndOfRule and config.state.epsilonOnlyTransitions
                nextTokens = self.atn.nextTokens(config.state)
                if nextTokens.member? Token.EPSILON then
                    endOfRuleState = self.atn.ruleToStopState[config.state.ruleIndex]
                    result.add(ATNConfig.new(endOfRuleState, nil, nil, nil, config), self.mergeCache)
                end
            end
        end
        return result
    end
    def computeStartState(p, ctx, fullCtx)
        type_check(p, ATNState)
        type_check(ctx, RuleContext)

        # always at least the implicit call to start rule
        initialContext = PredictionContextFromRuleContext(self.atn, ctx)
        configs = ATNConfigSet.new(fullCtx)

        p.transitions.each_index do |i|
            target = p.transitions[i].target
            c = ATNConfig.new(target, i+1, initialContext)
            closureBusy = Set.new
            self.closure(c, configs, closureBusy, true, fullCtx, false)
        end
        return configs
    end
    #
    # This method transforms the start state computed by
    # {@link #computeStartState} to the special start state used by a
    # precedence DFA for a particular precedence value. The transformation
    # process applies the following changes to the start state's configuration
    # set.
    #
    # <ol>
    # <li>Evaluate the precedence predicates for each configuration using
    # {@link SemanticContext#evalPrecedence}.</li>
    # <li>Remove all configurations which predict an alternative greater than
    # 1, for which another configuration that predicts alternative 1 is in the
    # same ATN state with the same prediction context. This transformation is
    # valid for the following reasons:
    # <ul>
    # <li>The closure block cannot contain any epsilon transitions which bypass
    # the body of the closure, so all states reachable via alternative 1 are
    # part of the precedence alternatives of the transformed left-recursive
    # rule.</li>
    # <li>The "primary" portion of a left recursive rule cannot contain an
    # epsilon transition, so the only way an alternative other than 1 can exist
    # in a state that is also reachable via alternative 1 is by nesting calls
    # to the left-recursive rule, with the outer calls not being at the
    # preferred precedence level.</li>
    # </ul>
    # </li>
    # </ol>
    #
    # <p>
    # The prediction context must be considered by this filter to address
    # situations like the following.
    # </p>
    # <code>
    # <pre>
    # grammar TA;
    # prog: statement* EOF;
    # statement: letterA | statement letterA 'b' ;
    # letterA: 'a';
    # </pre>
    # </code>
    # <p>
    # If the above grammar, the ATN state immediately before the token
    # reference {@code 'a'} in {@code letterA} is reachable from the left edge
    # of both the primary and closure blocks of the left-recursive rule
    # {@code statement}. The prediction context associated with each of these
    # configurations distinguishes between them, and prevents the alternative
    # which stepped out to {@code prog} (and then back in to {@code statement}
    # from being eliminated by the filter.
    # </p>
    #
    # @param configs The configuration set computed by
    # {@link #computeStartState} as the start state for the DFA.
    # @return The transformed configuration set representing the start state
    # for a precedence DFA at a particular precedence level (determined by
    # calling {@link Parser#getPrecedence}).
    #
    def applyPrecedenceFilter(configs)
        statesFromAlt1 = Hash.new
        configSet = ATNConfigSet.new(configs.fullCtx)
        configs.each do |config|
            # handle alt 1 first
            next if config.alt != 1
                
            updatedContext = config.semanticContext.evalPrecedence(self.parser, self.outerContext)
            next if updatedContext.nil?  # the configuration was eliminated

            statesFromAlt1[config.state.stateNumber] = config.context
            if updatedContext != config.semanticContext
                configSet.add(ATNConfig.new(nil,nil,nil, updatedContext, config), self.mergeCache)
            else
                configSet.add(config, self.mergeCache)
            end
        end
        configs.each do |config|
            next if config.alt == 1 # already handled

            # In the future, this elimination step could be updated to also
            # filter the prediction context for alternatives predicting alt>1
            # (basically a graph subtraction algorithm).
            #
            context = statesFromAlt1[config.state.stateNumber]
            next if context==config.context # eliminated

            configSet.add(config, self.mergeCache)
        end
        return configSet
    end
    def getReachableTarget(trans, ttype)
        if trans.matches(ttype, 0, self.atn.maxTokenType)
            return trans.target
        else
            return nil
        end
    end

    def getPredsForAmbigAlts(ambigAlts, configs, nalts)
        # REACH=[1|1|[]|0:0, 1|2|[]|0:1]
        # altToPred starts as an array of all null contexts. The entry at index i
        # corresponds to alternative i. altToPred[i] may have one of three values:
        #   1. null: no ATNConfig c is found such that c.alt==i
        #   2. SemanticContext.NONE: At least one ATNConfig c exists such that
        #      c.alt==i and c.semanticContext==SemanticContext.NONE. In other words,
        #      alt i has at least one unpredicated config.
        #   3. Non-NONE Semantic Context: There exists at least one, and for all
        #      ATNConfig c such that c.alt==i, c.semanticContext!=SemanticContext.NONE.
        #
        # From this, it is clear that NONE||anything==NONE.
        #
        altToPred = [nil] * (nalts + 1)
        configs.each do |c|
            if ambigAlts.member? c.alt 
                altToPred[c.alt] = SemanticContext.orContext(altToPred[c.alt], c.semanticContext)
            end
        end

        nPredAlts = 0
        for i in 1..nalts do
            if altToPred[i].nil?
                altToPred[i] = SemanticContext.NONE
            elsif ! altToPred[i].equal? SemanticContext.NONE
                nPredAlts = nPredAlts + 1
            end
        end
        # nonambig alts are null in altToPred
        if nPredAlts==0
            altToPred = nil
        end
        if self.debug
            puts "getPredsForAmbigAlts result #{altToPred}"
        end
        return altToPred
    end
    def getPredicatePredictions(ambigAlts, altToPred)
        pairs = Array.new
        containsPredicate = false

        altToPred.each_index do |i|
            pred = altToPred[i]
            # unpredicated is indicated by SemanticContext.NONE
            # assert pred is not None
            if ambigAlts and ambigAlts.member? i
                pairs.push(PredPrediction.new(pred, i))
            end
            if pred != SemanticContext.NONE
                containsPredicate = true
            end
        end
        if not containsPredicate
            return nil
        end
        return pairs
    end
    #
    # This method is used to improve the localization of error messages by
    # choosing an alternative rather than throwing a
    # {@link NoViableAltException} in particular prediction scenarios where the
    # {@link #ERROR} state was reached during ATN simulation.
    #
    # <p>
    # The default implementation of this method uses the following
    # algorithm to identify an ATN configuration which successfully parsed the
    # decision entry rule. Choosing such an alternative ensures that the
    # {@link ParserRuleContext} returned by the calling rule will be complete
    # and valid, and the syntax error will be reported later at a more
    # localized location.</p>
    #
    # <ul>
    # <li>If a syntactically valid path or paths reach the end of the decision rule and
    # they are semantically valid if predicated, return the min associated alt.</li>
    # <li>Else, if a semantically invalid but syntactically valid path exist
    # or paths exist, return the minimum associated alt.
    # </li>
    # <li>Otherwise, return {@link ATN#INVALID_ALT_NUMBER}.</li>
    # </ul>
    #
    # <p>
    # In some scenarios, the algorithm described above could predict an
    # alternative which will result in a {@link FailedPredicateException} in
    # the parser. Specifically, this could occur if the <em>only</em> configuration
    # capable of successfully parsing to the end of the decision rule is
    # blocked by a semantic predicate. By choosing this alternative within
    # {@link #adaptivePredict} instead of throwing a
    # {@link NoViableAltException}, the resulting
    # {@link FailedPredicateException} in the parser will identify the specific
    # predicate which is preventing the parser from successfully parsing the
    # decision rule, which helps developers identify and correct logic errors
    # in semantic predicates.
    # </p>
    #
    # @param configs The ATN configurations which were valid immediately before
    # the {@link #ERROR} state was reached
    # @param outerContext The is the \gamma_0 initial parser context from the paper
    # or the parser stack at the instant before prediction commences.
    #
    # @return The value to return from {@link #adaptivePredict}, or
    # {@link ATN#INVALID_ALT_NUMBER} if a suitable alternative was not
    # identified and {@link #adaptivePredict} should report an error instead.
    #
    def getSynValidOrSemInvalidAltThatFinishedDecisionEntryRule(configs, outerContext)
        semValidConfigs, semInvalidConfigs = self.splitAccordingToSemanticValidity(configs, outerContext)
        alt = self.getAltThatFinishedDecisionEntryRule(semValidConfigs)
        if alt!=ATN.INVALID_ALT_NUMBER # semantically/syntactically viable path exists
            return alt
        end
        # Is there a syntactically valid path with a failed pred?
        if semInvalidConfigs.length>0
            alt = self.getAltThatFinishedDecisionEntryRule(semInvalidConfigs)
            if alt!=ATN.INVALID_ALT_NUMBER  # syntactically viable path exists
                return alt
            end
        end
        return ATN.INVALID_ALT_NUMBER
    end
    def getAltThatFinishedDecisionEntryRule(configs)
        alts = Set.new()
        configs.each do |c|
            if c.reachesIntoOuterContext>0 or (c.state.kind_of? RuleStopState and c.context.hasEmptyPath() )
                alts.add(c.alt)
            end
        end
        if alts.empty?
            return ATN.INVALID_ALT_NUMBER
        else
            return alts.min
        end
    end
    # Walk the list of configurations and split them according to
    #  those that have preds evaluating to true/false.  If no pred, assume
    #  true pred and include in succeeded set.  Returns Pair of sets.
    #
    #  Create a new set so as not to alter the incoming parameter.
    #
    #  Assumption: the input stream has been restored to the starting point
    #  prediction, which is where predicates need to evaluate.
    #
    def splitAccordingToSemanticValidity(configs, outerContext)
        succeeded = ATNConfigSet.new(configs.fullCtx)
        failed = ATNConfigSet.new(configs.fullCtx)
        configs.each do |c|
            if c.semanticContext != SemanticContext.NONE
                predicateEvaluationResult = c.semanticContext.eval(self.parser, outerContext)
                if predicateEvaluationResult
                    succeeded.add(c)
                else
                    failed.add(c)
                end
            else
                succeeded.add(c)
            end
        end
        return [succeeded,failed]
    end
    # Look through a list of predicate/alt pairs, returning alts for the
    #  pairs that win. A {@code NONE} predicate indicates an alt containing an
    #  unpredicated config which behaves as "always true." If !complete
    #  then we stop at the first predicate that evaluates to true. This
    #  includes pairs with null predicates.
    #
    def evalSemanticContext( predPredictions, outerContext, complete)
        predictions = Set.new()

        predPredictions.each do |pair|
            if pair.pred.equal? SemanticContext.NONE
                predictions.add(pair.alt)
                break if not complete
                next
            end
            predicateEvaluationResult = pair.pred.eval(self.parser, outerContext)
            if self.debug or self.dfa_debug
                puts "eval pred #{pair}=#{predicateEvaluationResult}"
            end
            if predicateEvaluationResult
                if self.debug or self.dfa_debug
                    puts "PREDICT #{pair.alt}"
                end
                predictions.add(pair.alt)
                break if not complete
            end
        end
        return predictions
    end
    # TODO: If we are doing predicates, there is no point in pursuing
    #     closure operations if we reach a DFA state that uniquely predicts
    #     alternative. We will not be caching that DFA state and it is a
    #     waste to pursue the closure. Might have to advance when we do
    #     ambig detection thought :(
    #

    def closure(config, configs, closureBusy, collectPredicates, fullCtx, treatEofAsEpsilon)
        initialDepth = 0
        self.closureCheckingStopState(config, configs, closureBusy, collectPredicates,
                                 fullCtx, initialDepth, treatEofAsEpsilon)
        #assert not fullCtx or not configs.dipsIntoOuterContext
    end


    def closureCheckingStopState(config, configs, closureBusy, collectPredicates, fullCtx, depth, treatEofAsEpsilon)
        if self.debug
            puts "closure(#{config.toString(self.parser,true)})"
        end

        if config.state.kind_of? RuleStopState then
            # We hit rule end. If we have context info, use it
            # run thru all possible stack tops in ctx
            if not config.context.isEmpty() then
                config.context.each_index do |i|
                    if config.context.getReturnState(i).equal? PredictionContext.EMPTY_RETURN_STATE
                        if fullCtx
                            configs.add(ATNConfig.new(config.state,nil,PredictionContext.EMPTY,nil,config), self.mergeCache)
                            next
                        else
                            # we have no context info, just chase follow links (if greedy)
                            if self.debug
                                puts "FALLING off rule " + self.getRuleName(config.state.ruleIndex)
                            end
                            self.closure_(config, configs, closureBusy, collectPredicates,
                                     fullCtx, depth, treatEofAsEpsilon)
                        end
                        next
                    end
                    returnState = self.atn.states[config.context.getReturnState(i)]
                    newContext = config.context.getParent(i) # "pop" return state
                    c = ATNConfig.new(returnState, config.alt, newContext, config.semanticContext)
                    # While we have context to pop back from, we may have
                    # gotten that context AFTER having falling off a rule.
                    # Make sure we track that we are now out of context.
                    c.reachesIntoOuterContext = config.reachesIntoOuterContext
                    # assert depth > - 2**63
                    self.closureCheckingStopState(c, configs, closureBusy, collectPredicates, fullCtx, depth - 1, treatEofAsEpsilon)
                end
                return
            elsif fullCtx
                # reached end of start rule
                configs.add(config, self.mergeCache)
                return
            else
                # else if we have no context info, just chase follow links (if greedy)
                if self.debug
                    puts "FALLING off rule #{self.getRuleName(config.state.ruleIndex)}"
                end
            end
        end
        self.closure_(config, configs, closureBusy, collectPredicates, fullCtx, depth, treatEofAsEpsilon)
    end
    # Do the actual work of walking epsilon edges#
    def closure_(config, configs, closureBusy, collectPredicates, fullCtx, depth, treatEofAsEpsilon)
        p = config.state
        # optimization
        if not p.epsilonOnlyTransitions
            configs.add(config, self.mergeCache)
            # make sure to not return here, because EOF transitions can act as
            # both epsilon transitions and non-epsilon transitions.
        end
        p.transitions.each do |t|
            continueCollecting = collectPredicates and not t.kind_of? ActionTransition
            c = self.getEpsilonTarget(config, t, continueCollecting, depth == 0, fullCtx, treatEofAsEpsilon)
            if c 
                newDepth = depth
                if config.state.kind_of? RuleStopState
                    #assert not fullCtx
                    # target fell off end of rule; mark resulting c as having dipped into outer context
                    # We can't get here if incoming config was rule stop and we had context
                    # track how far we dip into outer context.  Might
                    # come in handy and we avoid evaluating context dependent
                    # preds if this is > 0.
                    if closureBusy.member? c
                        # avoid infinite recursion for right-recursive rules
                        next
                    end
                    closureBusy.add(c)

                    if @_dfa && @_dfa.isPrecedenceDfa() then
                      outermostPrecedenceReturn = t.outermostPrecedenceReturn()
                      if outermostPrecedenceReturn == @_dfa.atnStartState.ruleIndex then
                         c.setPrecedenceFilterSuppressed(true)
                      end
                    end
#          if (_dfa != null && _dfa.isPrecedenceDfa()) {
#            int outermostPrecedenceReturn = ((EpsilonTransition)t).outermostPrecedenceReturn();
#            if (outermostPrecedenceReturn == _dfa.atnStartState.ruleIndex) {
#              c.setPrecedenceFilterSuppressed(true);
#            }
#          }



                    c.reachesIntoOuterContext =c.reachesIntoOuterContext + 1
                    configs.dipsIntoOuterContext = true # TODO: can remove? only care when we add to set per middle of this method
                    # !assert newDepth > - 2**63
                    newDepth = newDepth - 1
                    puts  "dips into outer ctx: #{c}" if self.debug
                elsif t.kind_of? RuleTransition
                    # latch when newDepth goes negative - once we step out of the entry context we can't return
                    if newDepth >= 0
                        newDepth =newDepth + 1
                    end
                end
        
                self.closureCheckingStopState(c, configs, closureBusy, continueCollecting, fullCtx, newDepth, treatEofAsEpsilon)
            end
        end
    end

    def getRuleName(index)
        if self.parser and index>=0
            return self.parser.ruleNames[index]
        else
            return "<rule #{index}>"
        end
    end

    def getEpsilonTarget(config, t, collectPredicates, inContext, fullCtx, treatEofAsEpsilon)
        tt = t.serializationType
        if tt==Transition.RULE
            return self.ruleTransition(config, t)
        elsif tt==Transition.PRECEDENCE
            return self.precedenceTransition(config, t, collectPredicates, inContext, fullCtx)
        elsif tt==Transition.PREDICATE
            return self.predTransition(config, t, collectPredicates, inContext, fullCtx)
        elsif tt==Transition.ACTION
            return self.actionTransition(config, t)
        elsif tt==Transition.EPSILON
            return ATNConfig.new(t.target,nil,nil,nil, config)
        elsif [ Transition.ATOM, Transition.RANGE, Transition.SET ].member? tt
            # EOF transitions act like epsilon transitions after the first EOF
            # transition is traversed
            if treatEofAsEpsilon
                if t.matches(Token.EOF, 0, 1)
                    return ATNConfig.createConfigState(config, t.target)
                end
            end
            return nil
        else
            return nil
        end
    end
    def actionTransition(config, t)
        if self.debug
            puts  "ACTION edge #{t.ruleIndex}:#{t.actionIndex}"
        end
        return ATNConfig.new(t.target,nil,nil,nil, config)
    end
    def precedenceTransition(config, pt,  collectPredicates, inContext, fullCtx)
        if self.debug
            puts "PRED (collectPredicates=#{collectPredicates}) #{pt.precedence}>=_p, ctx dependent=true"
            if self.parser 
              puts "context surrounding pred is #{self.parser.getRuleInvocationStack()}"
            end
        end
        c = nil
        if collectPredicates and inContext
            if fullCtx
                # In full context mode, we can evaluate predicates on-the-fly
                # during closure, which dramatically reduces the size of
                # the config sets. It also obviates the need to test predicates
                # later during conflict resolution.
                currentPosition = self.input.index
                self.input.seek(self.startIndex)
                predSucceeds = pt.getPredicate().eval(self.parser, self.outerContext)
                self.input.seek(currentPosition)
                if predSucceeds
                    c = ATNConfig.new(pt.target,nil,nil,nil,config) # no pred context
                end
            else
                newSemCtx = SemanticContext.andContext(config.semanticContext, pt.getPredicate())
                c = ATNConfig.new(pt.target, nil,nil,newSemCtx, config)
            end
        else
            c = ATNConfig.new(pt.target,nil,nil,nil,config)
        end

        if self.debug
            puts "config from pred transition=#{c}"
        end
        return c
    end
    def predTransition(config, pt, collectPredicates, inContext, fullCtx)
        if self.debug
            puts "PRED (collectPredicates=#{collectPredicates}) #{pt.ruleIndex}:#{pt.predIndex}, ctx dependent=#{pt.isCtxDependent}"
            if self.parser 
                  puts "context surrounding pred is #{self.parser.getRuleInvocationStack()}"
            end
        end
        c = nil
        if collectPredicates and (not pt.isCtxDependent or (pt.isCtxDependent and inContext))
            if fullCtx
                # In full context mode, we can evaluate predicates on-the-fly
                # during closure, which dramatically reduces the size of
                # the config sets. It also obviates the need to test predicates
                # later during conflict resolution.
                currentPosition = self.input.index
                self.input.seek(self.startIndex)
                predSucceeds = pt.getPredicate().eval(self.parser, self.outerContext)
                self.input.seek(currentPosition)
                if predSucceeds
                    c = ATNConfig.new(pt.target,nil,nil,nil, config) # no pred context
                end
            else
                newSemCtx = SemanticContext.andContext(config.semanticContext, pt.getPredicate())
                c = ATNConfig.new(pt.target, nil,nil,newSemCtx, config)
            end
        else
            c = ATNConfig.new(pt.target, nil,nil,nil,config)
        end

        if self.debug
            puts "config from pred transition=#{c}"
        end
        return c
    end
    def ruleTransition(config, t)
        if self.debug
            puts  "CALL rule #{self.getRuleName(t.target.ruleIndex) }, ctx=#{config.context}"
        end
        returnState = t.followState
        newContext = SingletonPredictionContext.create(config.context, returnState.stateNumber)
        return ATNConfig.new(t.target, nil,newContext, nil,config )
    end
    def getConflictingAlts(configs)
        altsets = PredictionMode.getConflictingAltSubsets(configs)
        return PredictionMode.getAlts(altsets)
    end
     # Sam pointed out a problem with the previous definition, v3, of
     # ambiguous states. If we have another state associated with conflicting
     # alternatives, we should keep going. For example, the following grammar
     #
     # s : (ID | ID ID?) ';' ;
     #
     # When the ATN simulation reaches the state before ';', it has a DFA
     # state that looks like: [12|1|[], 6|2|[], 12|2|[]]. Naturally
     # 12|1|[] and 12|2|[] conflict, but we cannot stop processing this node
     # because alternative to has another way to continue, via [6|2|[]].
     # The key is that we have a single state that has config's only associated
     # with a single alternative, 2, and crucially the state transitions
     # among the configurations are all non-epsilon transitions. That means
     # we don't consider any conflicts that include alternative 2. So, we
     # ignore the conflict between alts 1 and 2. We ignore a set of
     # conflicting alts when there is an intersection with an alternative
     # associated with a single alt state in the state&rarr;config-list map.
     #
     # It's also the case that we might have two conflicting configurations but
     # also a 3rd nonconflicting configuration for a different alternative:
     # [1|1|[], 1|2|[], 8|3|[]]. This can come about from grammar:
     #
     # a : A | A | A B ;
     #
     # After matching input A, we reach the stop state for rule A, state 1.
     # State 8 is the state right before B. Clearly alternatives 1 and 2
     # conflict and no amount of further lookahead will separate the two.
     # However, alternative 3 will be able to continue and so we do not
     # stop working on this state. In the previous example, we're concerned
     # with states associated with the conflicting alternatives. Here alt
     # 3 is not associated with the conflicting configs, but since we can continue
     # looking for input reasonably, I don't declare the state done. We
     # ignore a set of conflicting alts when we have an alternative
     # that we still need to pursue.
    #

    def getConflictingAltsOrUniqueAlt(configs)
        conflictingAlts = nil
        if configs.uniqueAlt!= ATN.INVALID_ALT_NUMBER
            conflictingAlts = Set.new()
            conflictingAlts.add(configs.uniqueAlt)
        else
            conflictingAlts = configs.conflictingAlts
        end
        return conflictingAlts
    end
    def getTokenName(t)
        if t==Token.EOF
            return "EOF"
        end
        if self.parser and self.parser.tokenNames then
            if t >= self.parser.tokenNames.length() then
                puts "#{t} ttype out of range: #{self.parser.tokenNames}"
                puts self.parser.getInputStream().getTokens().to_s
            else
                return self.parser.tokenNames[t] + "<#{t}>"
            end
        end
        return t.to_s
    end
    def getLookaheadName(input)
        return getTokenName(input.LA(1))
    end
    # Used for debugging in adaptivePredict around execATN but I cut
    #  it out for clarity now that alg. works well. We can leave this
    #  "dead" code for a bit.
    #
    def dumpDeadEndConfigs(nvae)
        print "dead end configs: "
        nvae.getDeadEndConfigs().each do |c|
            trans = "no edges"
            if c.state.transitions.length>0 then
                t = c.state.transitions[0]
                if t.kind_of? AtomTransition then
                    trans = "Atom #{self.getTokenName(t.label)}"
                elsif t.kind_of? SetTransition then
                    #trans = ("~" if neg else "")+"Set "+ str(t.set)
                    if t.kind_of? NotSetTransition then
                        neg = "~" 
                    else 
                        neg = ""
                    end
                    trans = "#{neg}Set #{t.set}"
                end
            end
            # STDERR.puts "#{c.toString(self.parser, true)}:#{trans}"
        end
    end
    def noViableAlt(input, outerContext, configs, startIndex)
        return NoViableAltException.new(self.parser, input, input.get(startIndex), input.LT(1), configs, outerContext)
    end

    def getUniqueAlt(configs)
        alt = ATN.INVALID_ALT_NUMBER
        configs.each do |c|
            if alt == ATN.INVALID_ALT_NUMBER
                alt = c.alt # found first alt
            elsif c.alt!=alt
                return ATN.INVALID_ALT_NUMBER
            end
        end
        return alt
    end
    #
    # Add an edge to the DFA, if possible. This method calls
    # {@link #addDFAState} to ensure the {@code to} state is present in the
    # DFA. If {@code from} is {@code null}, or if {@code t} is outside the
    # range of edges that can be represented in the DFA tables, this method
    # returns without adding the edge to the DFA.
    #
    # <p>If {@code to} is {@code null}, this method returns {@code null}.
    # Otherwise, this method returns the {@link DFAState} returned by calling
    # {@link #addDFAState} for the {@code to} state.</p>
    #
    # @param dfa The DFA
    # @param from The source state for the edge
    # @param t The input symbol
    # @param to The target state for the edge
    #
    # @return If {@code to} is {@code null}, this method returns {@code null};
    # otherwise this method returns the result of calling {@link #addDFAState}
    # on {@code to}
    #
    def addDFAEdge(dfa, from_, t, to)
        if self.debug
            puts "EDGE #{from_} -> #{to} upon #{self.getTokenName(t)}"
        end

        if to.nil? 
            return nil
        end

        to = self.addDFAState(dfa, to) # used existing if possible not incoming
        if from_.nil? or t < -1 or t > self.atn.maxTokenType
            return to
        end

        if from_.edges.nil? then
            from_.edges = [nil] * (self.atn.maxTokenType + 2)
        end
        from_.edges[t+1] = to # connect

        if self.debug
            if self.parser.nil?
                names = nil
            else 
              names = self.parser.tokenNames
            end
            print "DFA=\n#{dfa.toString(names)}"
        end
        return to
    end
    #
    # Add state {@code D} to the DFA if it is not already present, and return
    # the actual instance stored in the DFA. If a state equivalent to {@code D}
    # is already in the DFA, the existing state is returned. Otherwise this
    # method returns {@code D} after adding it to the DFA.
    #
    # <p>If {@code D} is {@link #ERROR}, this method returns {@link #ERROR} and
    # does not change the DFA.</p>
    #
    # @param dfa The dfa
    # @param D The DFA state to add
    # @return The state stored in the DFA. This will be either the existing
    # state if {@code D} is already in the DFA, or {@code D} itself if the
    # state was not already present.
    #
    def addDFAState(dfa, cD)
        if cD.equal? ParserATNSimulator.ERROR
            return cD
        end

        existing = dfa.states[cD]
        if existing 
            return existing
        end

        cD.stateNumber = dfa.states.length
        if not cD.configs.readonly
            cD.configs.optimizeConfigs(self)
            cD.configs.setReadonly(true)
        end
        dfa.states[cD] = cD
        if self.debug
            puts "adding new DFA state: #{cD}"
        end
        return cD
    end
    def reportAttemptingFullContext(dfa, conflictingAlts, configs, startIndex, stopIndex)
        if self.debug or self.retry_debug
            interval = startIndex..stopIndex 
            puts "reportAttemptingFullContext decision=#{dfa.decision}:#{configs}, input=#{ 
                  self.parser.getTokenStream().getText(interval)}"
        end
        if self.parser 
          self.parser.getErrorListenerDispatch().reportAttemptingFullContext(self.parser, dfa, startIndex, stopIndex, conflictingAlts, configs)
        end
    end
    def reportContextSensitivity(dfa, prediction, configs, startIndex, stopIndex)
        if self.debug or self.retry_debug
            interval = startIndex..stopIndex 
            puts "reportContextSensitivity decision=#{dfa.decision}:#{configs}, input=#{ 
                  self.parser.getTokenStream().getText(interval)}"
        end
        if self.parser 
          self.parser.getErrorListenerDispatch().reportContextSensitivity(self.parser, dfa, startIndex, stopIndex, prediction, configs)
        end
    end

    # If context sensitive parsing, we know it's ambiguity not conflict#
    def reportAmbiguity(dfa, cD, startIndex, stopIndex, exact, ambigAlts, configs)
        if self.debug or self.retry_debug
#			ParserATNPathFinder finder = new ParserATNPathFinder(parser, atn);
#			int i = 1;
#			for (Transition t : dfa.atnStartState.transitions) {
#				print("ALT "+i+"=");
#				print(startIndex+".."+stopIndex+", len(input)="+parser.getInputStream().size());
#				TraceTree path = finder.trace(t.target, parser.getContext(), (TokenStream)parser.getInputStream(),
#											  startIndex, stopIndex);
#				if ( path!=null ) {
#					print("path = "+path.toStringTree());
#					for (TraceTree leaf : path.leaves) {
#						List<ATNState> states = path.getPathToNode(leaf);
#						print("states="+states);
#					}
#				}
#				i++;
#			}
            interval = startIndex..stopIndex 
            puts "reportAmbiguity #{ambigAlts}:#{configs}, input=#{
                    self.parser.getTokenStream().getText(interval)}"
        end
        if self.parser 
          self.parser.getErrorListenerDispatch().reportAmbiguity(self.parser, dfa, startIndex, stopIndex, exact, ambigAlts, configs)
        end
    end
end
