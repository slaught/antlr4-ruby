# When we hit an accept state in either the DFA or the ATN, we
#  have to notify the character stream to start buffering characters
#  via {@link IntStream#mark} and record the current state. The current sim state
#  includes the current index into the input, the current line,
#  and current character position in that line. Note that the Lexer is
#  tracking the starting line and characterization of the token. These
#  variables track the "state" of the simulator when it hits an accept state.
#
#  <p>We track these variables separately for the DFA and ATN simulation
#  because the DFA simulation often has to fail over to the ATN
#  simulation. If the ATN simulation fails, we need the DFA to fall
#  back to its previously accepted state, if any. If the ATN succeeds,
#  then the ATN does the accept and the DFA simulator that invoked it
#  can simply return the predicted token type.</p>

class SimState

    attr_accessor :index, :line, :column, :dfaState
    def initialize
        self.reset()
    end

    def reset
        @index = -1
        @line = 0
        @column = -1
        @dfaState = nil
    end
end


class LexerATNSimulator < ATNSimulator
    #include JavaSymbols

    class << self
      attr_reader :debug, :dfa_debug, :match_calls
    end
    @@debug = false
    @@dfa_debug = false
    @@match_calls = 0
    def debug; @@debug ;end
    def dfa_debug; @@dfa_debug ;end
    def match_calls; @@match_calls ;end

    MIN_DFA_EDGE = 0
    MAX_DFA_EDGE = 127 # forces unicode to stay in ATN

    attr_accessor :decisionToDFA, :recog, :startIndex, :line, :column 
    attr_accessor :mode, :prevAccept 

    def initialize(_recog, _atn, decision_to_dfa, shared_context_cache)
        super(_atn, shared_context_cache)
        
        if decision_to_dfa.nil?  then
          raise Exception.new("Error: #{self.class} decisionToDFA is nil.")
        end
        @decisionToDFA = decision_to_dfa
        @recog = _recog
        # The current token's starting index into the character stream.
        #  Shared across DFA to ATN simulation in case the ATN fails and the
        #  DFA did not have a previous accept state. In this case, we use the
        #  ATN-generated exception object.
        @startIndex = -1
        # line number 1..n within the input#/
        @line = 1
        # The index of the character relative to the beginning of the line 0..n-1#/
        @column = 0
        @mode = Lexer::DEFAULT_MODE
        # Used during DFA/ATN exec to record the most recent accept configuration info
        self.prevAccept = SimState.new()
    end


    def copyState(simulator)
        self.column = simulator.column
        self.line = simulator.line
        self.mode = simulator.mode
        self.startIndex = simulator.startIndex
    end
    def match(input, mode)
        @@match_calls =@@match_calls + 1
        self.mode = mode
        mark = input.mark()
        begin
            self.startIndex = input.index
            self.prevAccept.reset()
            dfa = self.decisionToDFA[mode]
            type_check(dfa, DFA)
            if dfa and dfa.s0.nil?  then
                return self.matchATN(input)
            else
                return self.execATN(input, dfa.s0)
            end
        ensure 
            input.release(mark)
        end
    end
    def reset
        self.prevAccept.reset()
        @startIndex = -1
        @line = 1
        @column = 0
        @mode = Lexer::DEFAULT_MODE
    end
    def clearDFA()
      raise Exception.new("not implemented")
    end
    def matchATN(input)
        startState = self.atn.modeToStartState[self.mode]

        if self.debug then
            print "matchATN mode #{self.mode} start: #{startState}"
        end

        old_mode = self.mode
        s0_closure = self.computeStartState(input, startState)
        suppressEdge = s0_closure.hasSemanticContext
        s0_closure.hasSemanticContext = false

        nxt = self.addDFAState(s0_closure)
        if not suppressEdge then
            self.decisionToDFA[self.mode].s0 = nxt
        end

        predict = self.execATN(input, nxt)

        if self.debug then
            print  "DFA after matchATN: #{self.decisionToDFA[old_mode].toLexerString()}"
        end

        return predict
    end
    def execATN(input, ds0)
        if self.debug then
            puts "start state closure=#{ds0.configs.to_s}"
        end

        t = input.LA(1)
        s = ds0 # s is current/from DFA state

        raise Exception.new("s is nil") if s.nil?

        while true do # while more work
            if self.debug then
                puts "execATN loop starting closure: #{s.configs}"
            end

            # As we move src->trg, src->trg, we keep track of the previous trg to
            # avoid looking up the DFA state again, which is expensive.
            # If the previous target was already part of the DFA, we might
            # be able to avoid doing a reach operation upon t. If s!=null,
            # it means that semantic predicates didn't prevent us from
            # creating a DFA state. Once we know s!=null, we check to see if
            # the DFA state has an edge already for t. If so, we can just reuse
            # it's configuration set; there's no point in re-computing it.
            # This is kind of like doing DFA simulation within the ATN
            # simulation because DFA simulation is really just a way to avoid
            # computing reach/closure sets. Technically, once we know that
            # we have a previously added DFA state, we could jump over to
            # the DFA simulator. But, that would mean popping back and forth
            # a lot and making things more complicated algorithmically.
            # This optimization makes a lot of sense for loops within DFA.
            # A character will take us back to an existing DFA state
            # that already has lots of edges out of it. e.g., .* in comments.
            # print("Target for:" + str(s) + " and:" + str(t))
            target = self.getExistingTargetState(s, t)
            # print("Existing:" + str(target))
            if target.nil? then
                target = self.computeTargetState(input, s, t)
            end
                # print("Computed:" + str(target))
            break if target.equal? ATNSimulator::ERROR

            if target.isAcceptState
                self.captureSimState(self.prevAccept, input, target)
                if t == Token::EOF
                    break
                end
            end

            if t != Token::EOF
                self.consume(input)
                t = input.LA(1)
            end

            s = target # flip; current DFA target becomes new src/from state
        end

        return self.failOrAccept(self.prevAccept, input, s.configs, t)
    end

    # Get an existing target state for an edge in the DFA. If the target state
    # for the edge has not yet been computed or is otherwise not available,
    # this method returns {@code null}.
    #
    # @param s The current DFA state
    # @param t The next input symbol
    # @return The existing target DFA state for the given input symbol
    # {@code t}, or {@code null} if the target state for this edge is not
    # already cached
    def getExistingTargetState(s, t)
        if s.edges.nil?  or t < LexerATNSimulator::MIN_DFA_EDGE or t > LexerATNSimulator::MAX_DFA_EDGE
            return nil
        end

        target = s.edges[t - LexerATNSimulator::MIN_DFA_EDGE]
        if self.debug and not target.nil? 
            puts  "reuse state #{s.stateNumber} edge to #{target.stateNumber}"
        end

        return target
    end

    # Compute a target state for an edge in the DFA, and attempt to add the
    # computed state and corresponding edge to the DFA.
    #
    # @param input The input stream
    # @param s The current DFA state
    # @param t The next input symbol
    #
    # @return The computed target DFA state for the given input symbol
    # {@code t}. If {@code t} does not lead to a valid DFA state, this method
    # returns {@link #ERROR}.
    def computeTargetState(input, s, t)
        reach = OrderedATNConfigSet.new()

        # if we don't find an existing DFA state
        # Fill reach starting from closure, following t transitions
        self.getReachableConfigSet(input, s.configs, reach, t)

        if reach.length==0 # we got nowhere on t from s
            if not reach.hasSemanticContext
                # we got nowhere on t, don't throw out this knowledge; it'd
                # cause a failover from DFA later.
               self.addDFAEdge(s, t, ATNSimulator::ERROR)
            end
            # stop when we can't match any more char
            return ATNSimulator::ERROR
        end

        # Add an edge from s to target DFA found/created for reach
        return self.addDFAEdge(s, t, nil, reach)
    end
    def failOrAccept(prevAccept, input, reach, t)
        if not self.prevAccept.dfaState.nil?
            lexerActionExecutor = prevAccept.dfaState.lexerActionExecutor
            self.accept(input, lexerActionExecutor, self.startIndex, prevAccept.index, prevAccept.line, prevAccept.column)
            return prevAccept.dfaState.prediction
        else
            # if no accept and EOF is first char, return EOF
            if t==Token::EOF and input.index==self.startIndex
                return Token::EOF
            end
            raise LexerNoViableAltException.new(self.recog, input, self.startIndex, reach)
        end
    end
    # Given a starting configuration set, figure out all ATN configurations
    #  we can reach upon input {@code t}. Parameter {@code reach} is a return
    #  parameter.
    def getReachableConfigSet(input, closure, reach, t)
        # this is used to skip processing for configs which have a lower priority
        # than a config that already reached an accept state for the same rule
        skipAlt = ATN::INVALID_ALT_NUMBER
        for cfg in closure do
            currentAltReachedAcceptState = ( cfg.alt == skipAlt )
            if currentAltReachedAcceptState and cfg.passedThroughNonGreedyDecision
                next 
            end

            if self.debug
                puts "testing #{self.getTokenName(t)} at #{cfg.toString(self.recog, true)}"
            end

            for trans in cfg.state.transitions do        # for each transition
                target = self.getReachableTarget(trans, t)
                if target
                    lexerActionExecutor = cfg.lexerActionExecutor
                    if lexerActionExecutor 
                        lexerActionExecutor = lexerActionExecutor.fixOffsetBeforeMatch(input.index - self.startIndex)
                    end
                    treatEofAsEpsilon = (t == Token::EOF)
                    config = LexerATNConfig.new(target, nil, nil, nil, lexerActionExecutor, cfg)
                    if self.closure(input, config, reach, currentAltReachedAcceptState, true, treatEofAsEpsilon)
                        # any remaining configs for this alt have a lower priority than
                        # the one that just reached an accept state.
                        skipAlt = cfg.alt
                        break 
                    end
               end

            end
        end
    end
    def accept(input, lexerActionExecutor, start_index, index, _line, charPos)
        if self.debug
            puts "ACTION #{lexerActionExecutor}"
        end

        # seek to after last char in token
        input.seek(index)
        self.line = _line
        self.column = charPos
        if input.LA(1) != Token::EOF
            self.consume(input)
        end
        if lexerActionExecutor and self.recog 
            lexerActionExecutor.execute(self.recog, input, start_index)
        end
    end

    def getReachableTarget(trans, t)
        if trans.matches(t, 0, 0xFFFE)
            return trans.target
        else
            return nil
        end
    end

    def computeStartState(input, p)
        initialContext = PredictionContext.EMPTY
        configs = OrderedATNConfigSet.new()
        p.transitions.each_index do |i|
            target = p.transitions[i].target
            c = LexerATNConfig.new(target, i+1, initialContext)
            self.closure(input, c, configs, false, false, false)
        end
        return configs
    end

    # Since the alternatives within any lexer decision are ordered by
    # preference, this method stops pursuing the closure as soon as an accept
    # state is reached. After the first accept state is reached by depth-first
    # search from {@code config}, all other (potentially reachable) states for
    # this rule would have a lower priority.
    #
    # @return {@code true} if an accept state is reached, otherwise
    # {@code false}.
    def closure(input, config, configs, currentAltReachedAcceptState, speculative, treatEofAsEpsilon)
        if self.debug
          puts "closure(#{config.toString(self.recog, true)})"
        end

        if config.state.kind_of? RuleStopState 
            if self.debug
                if self.recog 
                  puts "closure at #{self.recog.getRuleNames[config.state.ruleIndex]} rule stop #{ config}" 
                else
                  puts "closure at rule stop #{ config}" 
                end
            end

            if config.context.nil? or config.context.hasEmptyPath()
                if config.context.nil? or config.context.isEmpty()
                    configs.add(config)
                    return true
                else
                    configs.add(LexerATNConfig.new(config.state, nil,PredictionContext.EMPTY,nil,nil,config) )
                    currentAltReachedAcceptState = true
                end
            end
            if config.context and not config.context.isEmpty() then
                0.upto(config.context.length - 1) do |i| 
                    if config.context.getReturnState(i) != PredictionContext::EMPTY_RETURN_STATE
                        newContext = config.context.getParent(i) # "pop" return state
                        returnState = self.atn.states[config.context.getReturnState(i)]
                        c = LexerATNConfig.new(returnState,nil,newContext, nil, nil, config )
                        currentAltReachedAcceptState = self.closure(input, c, configs,
                                    currentAltReachedAcceptState, speculative, treatEofAsEpsilon)
                    end
                end
            end
            return currentAltReachedAcceptState
        end
        # optimization
        if not config.state.epsilonOnlyTransitions then
            if not currentAltReachedAcceptState or not config.passedThroughNonGreedyDecision
                configs.add(config)
            end
        end

        #for t in config.state.transitions do
        config.state.transitions.each do |t|
          c = self.getEpsilonTarget(input, config, t, configs, speculative, treatEofAsEpsilon)
          if c then
           currentAltReachedAcceptState = self.closure(input, c, configs, currentAltReachedAcceptState, speculative, treatEofAsEpsilon)
          end
        end
        return currentAltReachedAcceptState
    end
    # side-effect: can alter configs.hasSemanticContext
    def getEpsilonTarget(input, config, t, configs, speculative, treatEofAsEpsilon)
        c = nil
        if t.serializationType==Transition::RULE then
           newContext = SingletonPredictionContext.create(config.context, t.followState.stateNumber)
           c = LexerATNConfig.new(t.target, nil, newContext, nil,nil, config)
        elsif t.serializationType==Transition::PRECEDENCE
            raise UnsupportedOperationException.new("Precedence predicates are not supported in lexers.")
        elsif t.serializationType==Transition::PREDICATE
                #  Track traversing semantic predicates. If we traverse,
                # we cannot add a DFA state for this "reach" computation
                # because the DFA would not test the predicate again in the
                # future. Rather than creating collections of semantic predicates
                # like v3 and testing them on prediction, v4 will test them on the
                # fly all the time using the ATN not the DFA. This is slower but
                # semantically it's not used that often. One of the key elements to
                # this predicate mechanism is not adding DFA states that see
                # predicates immediately afterwards in the ATN. For example,

                # a : ID {p1}? | ID {p2}? ;

                # should create the start state for rule 'a' (to save start state
                # competition), but should not create target of ID state. The
                # collection of ATN states the following ID references includes
                # states reached by traversing predicates. Since this is when we
                # test them, we cannot cash the DFA state target of ID.
                if self.debug
                    print "EVAL rule #{t.ruleIndex}:#{t.predIndex}"
                end
                configs.hasSemanticContext = true
                if self.evaluatePredicate(input, t.ruleIndex, t.predIndex, speculative)
                    c = LexerATNConfig(t.target,nil,nil,nil,nil, config)
                end
        elsif t.serializationType==Transition::ACTION
                if config.context.nil? or config.context.hasEmptyPath()
                    # execute actions anywhere in the start rule for a token.
                    #
                    # TODO: if the entry rule is invoked recursively, some
                    # actions may be executed during the recursive call. The
                    # problem can appear when hasEmptyPath() is true but
                    # isEmpty() is false. In this case, the config needs to be
                    # split into two contexts - one with just the empty path
                    # and another with everything but the empty path.
                    # Unfortunately, the current algorithm does not allow
                    # getEpsilonTarget to return two configurations, so
                    # additional modifications are needed before we can support
                    # the split operation.
                    lexerActionExecutor = LexerActionExecutor.append(config.lexerActionExecutor,
                                    self.atn.lexerActions[t.actionIndex])
                    c = LexerATNConfig.new(t.target,nil,nil,nil, lexerActionExecutor, config)
                else
                    # ignore actions in referenced rules
                    c = LexerATNConfig.new(t.target,nil,nil,nil,nil, config)
                end
        elsif t.serializationType==Transition::EPSILON
              c = LexerATNConfig.new(t.target,nil,nil,nil,nil, config)
        elsif [ Transition::ATOM, Transition::RANGE, Transition::SET ].member? t.serializationType 
            if treatEofAsEpsilon
                if t.matches(Token::EOF, 0, 0xFFFF)
                    c = LexerATNConfig.new(t.target,nil,nil,nil,nil, config)
                end
            end
        end
        return c
    end
    # Evaluate a predicate specified in the lexer.
    #
    # <p>If {@code speculative} is {@code true}, this method was called before
    # {@link #consume} for the matched character. This method should call
    # {@link #consume} before evaluating the predicate to ensure position
    # sensitive values, including {@link Lexer#getText}, {@link Lexer#getLine},
    # and {@link Lexer#getcolumn}, properly reflect the current
    # lexer state. This method should restore {@code input} and the simulator
    # to the original state before returning (i.e. undo the actions made by the
    # call to {@link #consume}.</p>
    #
    # @param input The input stream.
    # @param ruleIndex The rule containing the predicate.
    # @param predIndex The index of the predicate within the rule.
    # @param speculative {@code true} if the current index in {@code input} is
    # one character before the predicate's location.
    #
    # @return {@code true} if the specified predicate evaluates to
    # {@code true}.
    #/
    def evaluatePredicate(input, ruleIndex, predIndex, speculative)
        # assume true if no recognizer was provided
        return true if self.recog.nil? 

        if not speculative then
            return self.recog.sempred(nil, ruleIndex, predIndex)
        end

        savedcolumn = self.column
        savedLine = self.line
        index = input.index
        marker = input.mark()
        begin
            self.consume(input)
            return self.recog.sempred(nil, ruleIndex, predIndex)
        ensure 
            self.column = savedcolumn
            self.line = savedLine
            input.seek(index)
            input.release(marker)
        end
    end
    def captureSimState(settings, input, dfaState)
        settings.index = input.index
        settings.line = self.line
        settings.column = self.column
        settings.dfaState = dfaState
    end

    def addDFAEdge(from_, tk, to=nil, cfgs=nil)

        if to.nil? and cfgs then
            # leading to this call, ATNConfigSet.hasSemanticContext is used as a
            # marker indicating dynamic predicate evaluation makes this edge
            # dependent on the specific input sequence, so the static edge in the
            # DFA should be omitted. The target DFAState is still created since
            # execATN has the ability to resynchronize with the DFA state cache
            # following the predicate evaluation step.
            #
            # TJP notes: next time through the DFA, we see a pred again and eval.
            # If that gets us to a previously created (but dangling) DFA
            # state, we can continue in pure DFA mode from there.
            #/
            suppressEdge = cfgs.hasSemanticContext
            cfgs.hasSemanticContext = false

            to = self.addDFAState(cfgs)

            if suppressEdge then
                return to
            end
        end
        # add the edge
        if tk < LexerATNSimulator::MIN_DFA_EDGE or tk > LexerATNSimulator::MAX_DFA_EDGE
            # Only track edges within the DFA bounds
            return to
        end

        if self.debug
            puts  "EDGE #{from_} -> #{to} upon #{tk.chr}"
        end

        if from_.edges.nil? 
            #  make room for tokens 1..n and -1 masquerading as index 0
            # from_.edges = [nil] * (LexerATNSimulator::MAX_DFA_EDGE -
            # LexerATNSimulator::MIN_DFA_EDGE + 1)
            from_.edges = Array.new 
        end

        from_.edges[tk - LexerATNSimulator::MIN_DFA_EDGE] = to # connect

        return to
    end

    # Add a new DFA state if there isn't one with this set of
    # configurations already. This method also detects the first
    # configuration containing an ATN rule stop state. Later, when
    # traversing the DFA, we will know which rule to accept.
    def addDFAState(configs) # -> DFAState:
        # the lexer evaluates predicates on-the-fly; by this point configs
        # should not contain any configurations with unevaluated predicates.
        # assert not configs.hasSemanticContext
        proposed = DFAState.new(nil,configs)
        firstConfigWithRuleStopState = nil
#        for c in configs.each do |c|:
        configs.each do |c|
            if c.state.kind_of? RuleStopState then
                firstConfigWithRuleStopState = c
                break
            end
        end

        if firstConfigWithRuleStopState then
            proposed.isAcceptState = true
            proposed.lexerActionExecutor = firstConfigWithRuleStopState.lexerActionExecutor
            proposed.prediction = self.atn.ruleToTokenType[firstConfigWithRuleStopState.state.ruleIndex]
        end

        dfa = self.decisionToDFA[self.mode]
        existing = dfa.states[proposed]
        if existing  then
            return existing
        end

        newState = proposed

        newState.stateNumber = dfa.states.length
        configs.setReadonly(true)
        newState.configs = configs
        dfa.states[newState] = newState
        return newState
    end
    def getDFA(mode)
        return self.decisionToDFA[mode]
    end
    # Get the text matched so far for the current token.
    def getText(input)
        # index is first lookahead char, don't include.
        return input.getText(self.startIndex, input.index-1)
    end
    def consume(input)
        curChar = input.LA(1)
        if curChar=="\n".ord then
            self.line = self.line + 1
            self.column = 0
        else
            self.column = self.column + 1
        end
        input.consume()
    end
    def getTokenName(t)
        if t==-1
            return "EOF"
        else
            return "'#{t.chr}'"
        end
    end
end
