#from uuid import UUID
require 'stringio'
require 'Token'
require 'atn/ATN'
require 'atn/ATNType'
require 'atn/ATNState'
require 'atn/Transition'
require 'atn/LexerAction'
require 'atn/ATNDeserializationOptions'

require 'uuid'
# This is the earliest supported serialized UUID.
BASE_SERIALIZED_UUID = UUID.new("AADB8D7E-AEEF-4415-AD2B-8204D6CF042E")

# This list contains all of the currently supported UUIDs, ordered by when
# the feature first appeared in this branch.
SUPPORTED_UUIDS = [ BASE_SERIALIZED_UUID ]

SERIALIZED_VERSION = 3

# This is the current serialized UUID.
SERIALIZED_UUID = BASE_SERIALIZED_UUID

class ATNDeserializer

    attr_accessor :deserializationOptions
    attr_accessor :edgeFactories,:stateFactories,:actionFactories 
    attr_accessor :data, :pos,:uuid
    def initialize(options=nil)
        if options.nil?
            options = ATNDeserializationOptions.defaultOptions
        end
        self.deserializationOptions = options
        self.edgeFactories = nil
        self.stateFactories = nil
        self.actionFactories = nil
    end

    # Determines if a particular serialized representation of an ATN supports
    # a particular feature, identified by the {@link UUID} used for serializing
    # the ATN at the time the feature was first introduced.
    #
    # @param feature The {@link UUID} marking the first time the feature was
    # supported in the serialized ATN.
    # @param actualUuid The {@link UUID} of the actual serialized ATN which is
    # currently being deserialized.
    # @return {@code true} if the {@code actualUuid} value represents a
    # serialized ATN at or after the feature identified by {@code feature} was
    # introduced; otherwise, {@code false}.

    def isFeatureSupported(feature, actualUuid)
        idx1 = SUPPORTED_UUIDS.index(feature)
        if idx1<0
            return false
        end
        idx2 = SUPPORTED_UUIDS.index(actualUuid)
        return idx2 >= idx1
    end

    def deserialize(data )
        self.reset(data)
        self.checkVersion()
        self.checkUUID()
        atn = self.readATN()
        self.readStates(atn)
        self.readRules(atn)
        self.readModes(atn)
        sets = self.readSets(atn)
        self.readEdges(atn, sets)
        self.readDecisions(atn)
        self.readLexerActions(atn)
        self.markPrecedenceDecisions(atn)
        self.verifyATN(atn)
        if self.deserializationOptions.generateRuleBypassTransitions \
                and atn.grammarType == ATNType.PARSER
            self.generateRuleBypassTransitions(atn)
            # re-verify after modification
            self.verifyATN(atn)
        end
        return atn
    end
    def reset(data)
       #for (int i = 1; i < data.length; i++) {
       #     data[i] = (char)(data[i] - 2);
       # don't adjust the first value since that's the version number
       temp  = data.map{|c| c.ord - 2 }
       temp[0] = data[0].ord
       self.data = temp
       self.pos = 0
    end

    def checkVersion()
      version = self.readInt()
      if version != SERIALIZED_VERSION
          raise Exception.new("Could not deserialize ATN with version #{version} (expected #{SERIALIZED_VERSION}).")
      end
    end

    def checkUUID()
        uuid = self.readUUID()
        if not SUPPORTED_UUIDS.member? uuid then
            raise Exception.new("Could not deserialize ATN with UUID: #{uuid} (expected #{SERIALIZED_UUID} or a legacy UUID).")
        end
        self.uuid = uuid
    end
    def readATN()
        idx = self.readInt()
        grammarType = ATNType.fromOrdinal(idx)
        maxTokenType = self.readInt()
        return ATN.new(grammarType, maxTokenType)
    end

    def readStates(atn)
        loopBackStateNumbers = Array.new
        endStateNumbers = Array.new
        nstates = self.readInt()
        1.upto(nstates) do |i| 
            stype = self.readInt()
            # ignore bad type of states
            if stype==ATNState.INVALID_TYPE
                atn.addState(nil)
                next
            end
            ruleIndex = self.readInt()
            if ruleIndex == 0xFFFF
                ruleIndex = -1
            end
            s = self.stateFactory(stype, ruleIndex)
            if stype == ATNState.LOOP_END # special case
                loopBackStateNumber = self.readInt()
                loopBackStateNumbers.push([s, loopBackStateNumber])
            elsif s.kind_of? BlockStartState
                endStateNumber = self.readInt()
                endStateNumbers.push([s, endStateNumber])
            end

            atn.addState(s)
        end
        # delay the assignment of loop back and end states until we know all the state instances have been initialized
        for pair in loopBackStateNumbers do
            pair[0].loopBackState = atn.states[pair[1]]
        end
        for pair in endStateNumbers do
            pair[0].endState = atn.states[pair[1]]
        end

        numNonGreedyStates = self.readInt()
        1.upto(numNonGreedyStates) do |i|
            stateNumber = self.readInt()
            atn.states[stateNumber].nonGreedy = true
        end
        numPrecedenceStates = self.readInt()
        1.upto(numPrecedenceStates) do |i|
            stateNumber = self.readInt()
            atn.states[stateNumber].isPrecedenceRule = true
        end
    end             
    def readRules(atn)        
        nrules = self.readInt()
        if atn.grammarType == ATNType.LEXER
            atn.ruleToTokenType = [0] * nrules
        end

        atn.ruleToStartState = [0] * nrules
        0.upto(nrules - 1) do |i| #for i in range(0, nrules)
            s = self.readInt()
            startState = atn.states[s]
            atn.ruleToStartState[i] = startState
            if atn.grammarType == ATNType.LEXER
                tokenType = self.readInt()
                if tokenType == 0xFFFF
                    tokenType = Token.EOF
                end
                atn.ruleToTokenType[i] = tokenType
            end
        end
        atn.ruleToStopState = [0] * nrules
        for state in atn.states do
            if not state.kind_of? RuleStopState
                next
            end
            atn.ruleToStopState[state.ruleIndex] = state
            atn.ruleToStartState[state.ruleIndex].stopState = state
        end
    end

    def readModes(atn)
        nmodes = self.readInt()
        1.upto(nmodes) do  #for i in range(0, nmodes)
            s = self.readInt()
            atn.modeToStartState.push(atn.states[s])
        end
    end
#######
#    List<IntervalSet> sets = new ArrayList<IntervalSet>();
#    int nsets = toInt(data[p++]);
#    for (int i=0; i<nsets; i++) {
#      int nintervals = toInt(data[p]);
#      p++;
#      IntervalSet set = new IntervalSet();
#      sets.add(set);
#
#      boolean containsEof = toInt(data[p++]) != 0;
#      if (containsEof) {
#        set.add(-1);
#      }
#
#      for (int j=0; j<nintervals; j++) {
#        set.add(toInt(data[p]), toInt(data[p + 1]));
#        p += 2;
#      }
#    }
###############

    def readSets(atn)
        sets = Array.new
        m = self.readInt()
        1.upto(m) do |i|  #for i in range(0, m)
            iset = IntervalSet.new()
            sets.push(iset)
            n = self.readInt()
            containsEof = self.readInt()
            if containsEof !=0 then
                iset.addOne(-1)
            end
            1.upto(n) do |j| # for j in range(0, n)
                i1 = self.readInt()
                i2 = self.readInt()
                iset.addRange(i1..i2) 
            end
        end
        return sets
    end
    def readEdges(atn, sets)
        nedges = self.readInt()
        1.upto(nedges) do |i| #for i in range(0, nedges)
            src = self.readInt()
            trg = self.readInt()
            ttype = self.readInt()
            arg1 = self.readInt()
            arg2 = self.readInt()
            arg3 = self.readInt()
            trans = self.edgeFactory(atn, ttype, src, trg, arg1, arg2, arg3, sets)
            srcState = atn.states[src]
            srcState.addTransition(trans)
        end
        # edges for rule stop states can be derived, so they aren't serialized
        for state in atn.states do 
            state.transitions.each_index do |i| # for i in range(0, len(state.transitions))
                t = state.transitions[i]
                next if not t.kind_of?  RuleTransition
                atn.ruleToStopState[t.target.ruleIndex].addTransition(EpsilonTransition.new(t.followState))
            end
        end
        for state in atn.states do
            if state.kind_of? BlockStartState then
                # we need to know the end state to set its start state
                if state.endState.nil? then 
                    raise Exception.new("IllegalState")
                end
                # block end states can only be associated to a single block start state
                if state.endState.startState 
                    raise Exception.new("IllegalState")
                end
                state.endState.startState = state
            end
            if state.kind_of? PlusLoopbackState then
                state.transitions.each_index do |i| #for i in range(0, len(state.transitions))
                    target = state.transitions[i].target
                    if target.kind_of? PlusBlockStartState
                        target.loopBackState = state
                    end
                end
            elsif state.kind_of? StarLoopbackState
                state.transitions.each_index do |i| #for i in range(0, len(state.transitions))
                    target = state.transitions[i].target
                    if target.kind_of? StarLoopEntryState
                        target.loopBackState = state
                    end
                end
            end
        end
    end
    def readDecisions(atn)
        ndecisions = self.readInt()
        1.upto(ndecisions) do |i| # for i in range(0, ndecisions)
            s = self.readInt()
            decState = atn.states[s]
            atn.decisionToState.push(decState)
            decState.decision = i
        end
    end
    def readLexerActions(atn)
        if atn.grammarType == ATNType.LEXER
            count = self.readInt()
            atn.lexerActions = [ nil ] * count
            0.upto(count-1) do |i|  # for i in range(0, count)
                actionType = self.readInt()
                data1 = self.readInt()
                if data1 == 0xFFFF
                    data1 = -1
                end
                data2 = self.readInt()
                if data2 == 0xFFFF
                    data2 = -1
                end
                lexerAction = self.lexerActionFactory(actionType, data1, data2)
                atn.lexerActions[i] = lexerAction
            end
        end
    end
    def generateRuleBypassTransitions(atn)
        count = atn.ruleToStartState.length()
        atn.ruleToTokenType = [ 0 ] * count
        0.upto(count-1) do |i| # for i in range(0, count)
            atn.ruleToTokenType[i] = atn.maxTokenType + i + 1
        end

        0.upto(count-1) do |i| # for i in range(0, count)
            self.generateRuleBypassTransition(atn, i)
        end
    end

    def generateRuleBypassTransition(atn, idx)
        bypassStart = BasicBlockStartState()
        bypassStart.ruleIndex = idx
        atn.addState(bypassStart)

        bypassStop = BlockEndState()
        bypassStop.ruleIndex = idx
        atn.addState(bypassStop)

        bypassStart.endState = bypassStop
        atn.defineDecisionState(bypassStart)

        bypassStop.startState = bypassStart

        excludeTransition = nil

        if atn.ruleToStartState[idx].isPrecedenceRule
            # wrap from the beginning of the rule to the StarLoopEntryState
            endState = nil
            for state in atn.states do
                if self.stateIsEndStateFor(state, idx) then
                    endState = state
                    excludeTransition = state.loopBackState.transitions[0]
                    break
                end
            end
            if excludeTransition.nil? 
                raise Exception.new("Couldn't identify final state of the precedence rule prefix section.")
            end
        else
            endState = atn.ruleToStopState[idx]
        end

        # all non-excluded transitions that currently target end state need to target blockEnd instead
        for state in atn.states
            for transition in state.transitions
                if transition == excludeTransition
                    next
                end
                if transition.target == endState
                    transition.target = bypassStop
                end
            end
        end
        # all transitions leaving the rule start state need to leave blockStart instead
        ruleToStartState = atn.ruleToStartState[idx]
        count = ruleToStartState.transitions.length() 
        0.upto(ruleToStartState.transitions.length()  -1) do |i|
            transition = ruleToStartState.removeTransition(i)
            bypassStart.addTransition(transition)
        end
        # link the new states
        atn.ruleToStartState[idx].addTransition(EpsilonTransition.new(bypassStart))
        bypassStop.addTransition(EpsilonTransition.new(endState))

        matchState = BasicState.new()
        atn.addState(matchState)
        matchState.addTransition(AtomTransition.new(bypassStop, atn.ruleToTokenType[idx]))
        bypassStart.addTransition(EpsilonTransition.new(matchState))
    end

    def stateIsEndStateFor(state, idx)
        return nil if state.ruleIndex != idx
        return nil if not state.kind_of? StarLoopEntryState

        maybeLoopEndState = state.transitions[-1].target
        return nil if not maybeLoopEndState.kind_of? LoopEndState

        if maybeLoopEndState.epsilonOnlyTransitions and  maybeLoopEndState.transitions[0].target.kind_of? RuleStopState
            return state
        else
            return nil
        end
    end

    #
    # Analyze the {@link StarLoopEntryState} states in the specified ATN to set
    # the {@link StarLoopEntryState#precedenceRuleDecision} field to the
    # correct value.
    #
    # @param atn The ATN.
    #
    def markPrecedenceDecisions(atn)
        for state in atn.states do
            next if not state.kind_of? StarLoopEntryState

            # We analyze the ATN to determine if this ATN decision state is the
            # decision for the closure block that determines whether a
            # precedence rule should continue or complete.
            #
            if atn.ruleToStartState[state.ruleIndex].isPrecedenceRule
                maybeLoopEndState = state.transitions[-1].target
                if maybeLoopEndState.kind_of? LoopEndState
                    if maybeLoopEndState.epsilonOnlyTransitions and \
                            maybeLoopEndState.transitions[0].target.kind_of? RuleStopState
                        state.precedenceRuleDecision = true
                    end
                end
            end
        end
    end

    def verifyATN(atn)
      return if not self.deserializationOptions.verifyATN
      # verify assumptions
      for state in atn.states do
        next if state.nil? 
        self.checkCondition((state.epsilonOnlyTransitions or state.transitions.length <= 1))
        if state.kind_of? PlusBlockStartState then
           self.checkCondition( !state.loopBackState.nil?)

           if state.kind_of? StarLoopEntryState then
                self.checkCondition( !state.loopBackState.nil? )
                self.checkCondition(state.transitions.length() == 2)

                if state.transitions[0].target.kind_of? StarBlockStartState then
                    self.checkCondition(state.transitions[1].target.kind_of?(LoopEndState))
                    self.checkCondition(!state.nonGreedy)
                elsif state.transitions[0].target.kind_of? LoopEndState
                    self.checkCondition(state.transitions[1].target.kind_of?(StarBlockStartState))
                    self.checkCondition(state.nonGreedy)
                else
                    raise Exception.new("IllegalState")
                end
            end
            if state.kind_of? StarLoopbackState then
                self.checkCondition(state.transitions.length() == 1)
                self.checkCondition(state.transitions[0].target.kind_of?(StarLoopEntryState))
            end
            if state.kind_of? LoopEndState
                self.checkCondition(! state.loopBackState.nil?) 
            end

            if state.kind_of? RuleStartState then
                self.checkCondition( !state.stopState.nil? )
            end

            if state.kind_of? BlockStartState then
                self.checkCondition(!state.endState.nil? )
            end

            if state.kind_of? BlockEndState then
                self.checkCondition(!state.startState.nil? )
            end

            if state.kind_of? DecisionState then
                self.checkCondition(state.transitions.length() <= 1 || state.decision >= 0)
            else
                self.checkCondition(state.transitions.lenth() <= 1 || state.kind_of?(RuleStopState) )
            end
        end
      end
    end
    def checkCondition(condition, message=nil)
        unless condition then
            if message.nil? 
                message = "IllegalState"
            end
            raise Exception.new(message)
        end
    end
    def readInt()
        i = self.data[self.pos]
        self.pos = self.pos + 1
        return i
    end

    def readInt32()
        low = self.readInt()
        high = self.readInt()
        return low | (high << 16)
    end
    def readLong()
        low = self.readInt32()
        high = self.readInt32()
        return (low & 0x00000000FFFFFFFF) | (high << 32)
    end

    def readUUID()
        low = self.readLong()
        high = self.readLong()
        allBits = (low & 0xFFFFFFFFFFFFFFFF) | (high << 64)
        return UUID.create_from_bytes(allBits)
    end

    def edgeFactory(atn, type, src, trg, arg1, arg2, arg3, sets)
      target = atn.states[trg]
      if self.edgeFactories.nil? then
          ef = [nil] * 11
          ef[0] = lambda {|atn, src, trg, arg1, arg2, arg3, sets, target| raise Exception.new("The specified state type 0 is not valid.") }
          ef[Transition.EPSILON] = lambda {|atn, src, trg, arg1, arg2, arg3, sets, target|  EpsilonTransition.new(target) }
          ef[Transition.RANGE] = lambda {|atn, src, trg, arg1, arg2, arg3, sets, target|
              if arg3 != 0 
                  RangeTransition.new(target, Token.EOF, arg2) 
              else 
                RangeTransition.new(target, arg1, arg2)
              end
          }
          ef[Transition.RULE] = lambda {|atn, src, trg, arg1, arg2, arg3, sets, target | 
                RuleTransition.new(atn.states[arg1], arg2, arg3, target) }
          ef[Transition.PREDICATE] = lambda {|atn, src, trg, arg1, arg2, arg3, sets, target |
                PredicateTransition.new(target, arg1, arg2, arg3 != 0) }
          ef[Transition.PRECEDENCE] = lambda {|atn, src, trg, arg1, arg2, arg3, sets, target |
                PrecedencePredicateTransition.new(target, arg1) }
          ef[Transition.ATOM] = lambda {|atn, src, trg, arg1, arg2, arg3, sets, target | 
                if arg3 != 0 
                    AtomTransition.new(target, Token.EOF) 
                else 
                    AtomTransition.new(target, arg1)
                end
          }
          ef[Transition.ACTION] = lambda {|atn, src, trg, arg1, arg2, arg3, sets, target |
                ActionTransition.new(target, arg1, arg2, arg3 != 0)  }
          ef[Transition.SET] = lambda {|atn, src, trg, arg1, arg2, arg3, sets, target|
                SetTransition.new(target, sets[arg1]) }
          ef[Transition.NOT_SET] = lambda {|atn, src, trg, arg1, arg2, arg3, sets, target |  
                NotSetTransition.new(target, sets[arg1]) }
          ef[Transition.WILDCARD] = lambda {|atn, src, trg, arg1, arg2, arg3, sets, target |
                WildcardTransition.new(target) }
          self.edgeFactories = ef
        end
        if type > self.edgeFactories.length() or self.edgeFactories[type].nil?  then
            raise Exception.new("The specified transition type: #{type} is not valid.")
        else
            return self.edgeFactories[type].call(atn, src, trg, arg1, arg2, arg3, sets, target)
        end
    end
    def stateFactory(type, ruleIndex)
        if self.stateFactories.nil? 
            sf = [nil] * 13
            sf[ATNState.INVALID_TYPE] = lambda {  nil }
            sf[ATNState.BASIC] = lambda { BasicState.new } 
            sf[ATNState.RULE_START] = lambda { RuleStartState.new }
            sf[ATNState.BLOCK_START] = lambda { BasicBlockStartState.new }
            sf[ATNState.PLUS_BLOCK_START] = lambda { PlusBlockStartState.new }
            sf[ATNState.STAR_BLOCK_START] = lambda { StarBlockStartState.new }
            sf[ATNState.TOKEN_START] = lambda { TokensStartState.new }
            sf[ATNState.RULE_STOP] = lambda { RuleStopState.new }
            sf[ATNState.BLOCK_END] = lambda { BlockEndState.new }
            sf[ATNState.STAR_LOOP_BACK] = lambda { StarLoopbackState.new }
            sf[ATNState.STAR_LOOP_ENTRY] = lambda { StarLoopEntryState.new }
            sf[ATNState.PLUS_LOOP_BACK] = lambda { PlusLoopbackState.new }
            sf[ATNState.LOOP_END] = lambda { LoopEndState.new }
            self.stateFactories = sf
        end
        if type> self.stateFactories.length() or self.stateFactories[type].nil?
            raise Exceptionn.new("The specified state type #{type} is not valid.")
        else
            s = self.stateFactories[type].call()
            if s 
                s.ruleIndex = ruleIndex
            end
        end
        return s
    end
    def lexerActionFactory(type, data1, data2)
        if self.actionFactories.nil? then
            af = [ nil ] * 8
            af[LexerActionType.CHANNEL] = lambda {|data1, data2| LexerChannelAction.new(data1) }
            af[LexerActionType.CUSTOM] = lambda {|data1, data2| LexerCustomAction.new(data1, data2) }
            af[LexerActionType.MODE] = lambda {|data1, data2| LexerModeAction.new(data1) } 
            af[LexerActionType.MORE] = lambda {|data1, data2| LexerMoreAction.INSTANCE } 
            af[LexerActionType.POP_MODE] = lambda {|data1, data2| LexerPopModeAction.INSTANCE }
            af[LexerActionType.PUSH_MODE] = lambda {|data1, data2| LexerPushModeAction.new(data1) }
            af[LexerActionType.SKIP] = lambda {|data1, data2| LexerSkipAction.INSTANCE }
            af[LexerActionType.TYPE] = lambda {|data1, data2| LexerTypeAction.new(data1) }
            self.actionFactories = af
        end
        if type> self.actionFactories.length() or self.actionFactories[type].nil?
            raise Exception("The specified lexer action type #{type} is not valid.")
        else
            return self.actionFactories[type].call(data1, data2)
        end
    end
end
