# Represents an executor for a sequence of lexer actions which traversed during
# the matching operation of a lexer rule (token).
#
# <p>The executor tracks position information for position-dependent lexer actions
# efficiently, ensuring that actions appearing only at the end of the rule do
# not cause bloating of the {@link DFA} created for the lexer.</p>

class LexerActionExecutor

    attr_accessor :hashCode, :lexerActions
    def initialize(lexerActions=nil)
        if lexerActions.nil? then
         self.lexerActions = Array.new
        else
          self.lexerActions = lexerActions
        end
        # Caches the result of {@link #hashCode} since the hash code is an element
        # of the performance-critical {@link LexerATNConfig#hashCode} operation.
        self.hashCode = self.lexerActions.map(&:to_s).join('').hash
    end

    # Creates a {@link LexerActionExecutor} which executes the actions for
    # the input {@code lexerActionExecutor} followed by a specified
    # {@code lexerAction}.
    #
    # @param lexerActionExecutor The executor for actions already traversed by
    # the lexer while matching a token within a particular
    # {@link LexerATNConfig}. If this is {@code null}, the method behaves as
    # though it were an empty executor.
    # @param lexerAction The lexer action to execute after the actions
    # specified in {@code lexerActionExecutor}.
    #
    # @return A {@link LexerActionExecutor} for executing the combine actions
    # of {@code lexerActionExecutor} and {@code lexerAction}.
    def self.append(lexerActionExecutor, lexerAction)
        if lexerActionExecutor.nil? 
            return LexerActionExecutor.new([ lexerAction ])
        end
        lexerActions = lexerActionExecutor.lexerActions.concat(lexerAction )
        return LexerActionExecutor.new(lexerActions)
    end

    # Creates a {@link LexerActionExecutor} which encodes the current offset
    # for position-dependent lexer actions.
    #
    # <p>Normally, when the executor encounters lexer actions where
    # {@link LexerAction#isPositionDependent} returns {@code true}, it calls
    # {@link IntStream#seek} on the input {@link CharStream} to set the input
    # position to the <em>end</em> of the current token. This behavior provides
    # for efficient DFA representation of lexer actions which appear at the end
    # of a lexer rule, even when the lexer rule matches a variable number of
    # characters.</p>
    #
    # <p>Prior to traversing a match transition in the ATN, the current offset
    # from the token start index is assigned to all position-dependent lexer
    # actions which have not already been assigned a fixed offset. By storing
    # the offsets relative to the token start index, the DFA representation of
    # lexer actions which appear in the middle of tokens remains efficient due
    # to sharing among tokens of the same length, regardless of their absolute
    # position in the input stream.</p>
    #
    # <p>If the current executor already has offsets assigned to all
    # position-dependent lexer actions, the method returns {@code this}.</p>
    #
    # @param offset The current offset to assign to all position-dependent
    # lexer actions which do not already have offsets assigned.
    #
    # @return A {@link LexerActionExecutor} which stores input stream offsets
    # for all position-dependent lexer actions.
    #/
    def fixOffsetBeforeMatch(offset)
        updatedLexerActions = nil
        @lexerActions.each_index {|i|
            if @lexerActions[i].isPositionDependent and not @lexerActions[i].kind_of? LexerIndexedCustomAction
                if updatedLexerActions.nil? 
                    updatedLexerActions = @lexerActions.map{|x| x} 
                end
                updatedLexerActions[i] = LexerIndexedCustomAction.new(offset, @lexerActions[i])
            end
        }
        if updatedLexerActions.nil? 
            return self
        else
            return LexerActionExecutor.new(updatedLexerActions)
        end
    end


    # Execute the actions encapsulated by this executor within the context of a
    # particular {@link Lexer}.
    #
    # <p>This method calls {@link IntStream#seek} to set the position of the
    # {@code input} {@link CharStream} prior to calling
    # {@link LexerAction#execute} on a position-dependent action. Before the
    # method returns, the input position will be restored to the same position
    # it was in when the method was invoked.</p>
    #
    # @param lexer The lexer instance.
    # @param input The input stream which is the source for the current token.
    # When this method is called, the current {@link IntStream#index} for
    # {@code input} should be the start of the following token, i.e. 1
    # character past the end of the current token.
    # @param startIndex The token start index. This value may be passed to
    # {@link IntStream#seek} to set the {@code input} position to the beginning
    # of the token.
    #/
    def execute(lexer, input, startIndex)
        requiresSeek = false
        stopIndex = input.index
        begin
            self.lexerActions.each { |lexerAction|
                if lexerAction.kind_of? LexerIndexedCustomAction
                    offset = lexerAction.offset
                    input.seek(startIndex + offset)
                    lexerAction = lexerAction.action
                    requiresSeek = (startIndex + offset) != stopIndex
                elsif lexerAction.isPositionDependent
                    input.seek(stopIndex)
                    requiresSeek = false
                end
                lexerAction.execute(lexer)
            }
        ensure 
            input.seek(stopIndex) if requiresSeek
        end
    end
    def hash
        return self.hashCode
    end

    def eql?(other)
        self == other
    end
    def ==( other)
        self.equal? other or other.kind_of? LexerActionExecutor and 
            self.hashCode == other.hashCode and self.lexerActions == other.lexerActions
     end
end
