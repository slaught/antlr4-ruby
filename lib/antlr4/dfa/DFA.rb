
class DFA
    attr_accessor :atnStartState, :decision, :_states, :s0, :precedenceDfa 
    def initialize(_atnStartState, _decision=0)
        raise Exception.new("atnStartState is nil") if _atnStartState.nil?
        type_check(_decision, Fixnum)
        type_check(_atnStartState, ATNState)
        # From which ATN state did we create this DFA?
        @atnStartState = _atnStartState
        @decision = _decision
        # A set of all DFA states. Use {@link Map} so we can get old state back
        #  ({@link Set} only allows you to see if it's there).
        @_states = Hash.new
        @s0 = nil
        # {@code true} if this DFA is for a precedence decision; otherwise,
        # {@code false}. This is the backing field for {@link #isPrecedenceDfa},
        # {@link #setPrecedenceDfa}.
        @precedenceDfa = false
    end
    def isPrecedenceDfa
        @precedenceDfa
    end
    # Get the start state for a specific precedence value.
    #
    # @param precedence The current precedence.
    # @return The start state corresponding to the specified precedence, or
    # {@code null} if no start state exists for the specified precedence.
    #
    # @throws IllegalStateException if this is not a precedence DFA.
    # @see #isPrecedenceDfa()

    def getPrecedenceStartState(precedence)
        if not self.precedenceDfa then
            raise IllegalStateException.new("Only precedence DFAs may contain a precedence start state.")
        end
        # s0.edges is never null for a precedence DFA
        if precedence < 0 or precedence >= self.s0.edges.length then
            return nil
        end
        return self.s0.edges[precedence]
    end

    # Set the start state for a specific precedence value.
    #
    # @param precedence The current precedence.
    # @param startState The start state corresponding to the specified
    # precedence.
    #
    # @throws IllegalStateException if this is not a precedence DFA.
    # @see #isPrecedenceDfa()
    #
    def setPrecedenceStartState(precedence, startState)
        if not self.precedenceDfa then
            raise IllegalStateException.new("Only precedence DFAs may contain a precedence start state.")
        end
        if precedence < 0
            return
        end
        # synchronization on s0 here is ok. when the DFA is turned into a
        # precedence DFA, s0 will be initialized once and not updated again
        # s0.edges is never null for a precedence DFA
        self.s0.edges[precedence] = startState
    end
    #
    # Sets whether this is a precedence DFA. If the specified value differs
    # from the current DFA configuration, the following actions are taken;
    # otherwise no changes are made to the current DFA.
    #
    # <ul>
    # <li>The {@link #states} map is cleared</li>
    # <li>If {@code precedenceDfa} is {@code false}, the initial state
    # {@link #s0} is set to {@code null}; otherwise, it is initialized to a new
    # {@link DFAState} with an empty outgoing {@link DFAState#edges} array to
    # store the start states for individual precedence values.</li>
    # <li>The {@link #precedenceDfa} field is updated</li>
    # </ul>
    #
    # @param precedenceDfa {@code true} if this is a precedence DFA; otherwise,
    # {@code false}

    def setPrecedenceDfa(_precedenceDfa)
        if self.precedenceDfa != _precedenceDfa then
            self._states = Hash.new
            if _precedenceDfa then
                precedenceState = DFAState.new(nil, ATNConfigSet.new())
                precedenceState.edges = Array.new
                precedenceState.isAcceptState = false
                precedenceState.requiresFullContext = false
                self.s0 = precedenceState
            else
                self.s0 = nil
            end
            self.precedenceDfa = _precedenceDfa
        end
    end

    def states()
        self._states
    end

    # Return a list of all states in this DFA, ordered by state number.
    def sortedStates()
        return self._states.keys().sort {|a,b| a.stateNumber <=> b.stateNumber}
    end

    def to_s
       toString()
    end
    def inspect
        "<DFA #{atnStartState.inspect} decision(#{@decision}) states(#{states.length}) >"
    end

    def toString(tokenNames=nil)
        if self.s0.nil? then
            return ''
        end
        serializer = DFASerializer.new(self,tokenNames)
        return serializer.to_s
    end

    def toLexerString
        if self.s0.nil? then
            return ''
        end
        serializer = LexerDFASerializer.new(self)
        return serializer.to_s
    end
end
