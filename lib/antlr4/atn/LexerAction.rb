
class LexerActionType 
    include JavaSymbols
    CHANNEL = 0     #The type of a {@link LexerChannelAction} action.
    CUSTOM = 1      #The type of a {@link LexerCustomAction} action.
    MODE = 2        #The type of a {@link LexerModeAction} action.
    MORE = 3        #The type of a {@link LexerMoreAction} action.
    POP_MODE = 4    #The type of a {@link LexerPopModeAction} action.
    PUSH_MODE = 5   #The type of a {@link LexerPushModeAction} action.
    SKIP = 6        #The type of a {@link LexerSkipAction} action.
    TYPE = 7        #The type of a {@link LexerTypeAction} action.
end 

class LexerAction

    attr_accessor :actionType, :isPositionDependent 
    def initialize(action)
        self.actionType = action
        self.isPositionDependent = false
    end

    def hash
        self.actionType.to_s.hash
    end

    def eql?(other)
      self == other
    end

    def ==(other)
        self.equal? other
    end
end

#
# Implements the {@code skip} lexer action by calling {@link Lexer#skip}.
#
# <p>The {@code skip} command does not have any parameters, so this action is
# implemented as a singleton instance exposed by {@link #INSTANCE}.</p>
class LexerSkipAction < LexerAction 

    # Provides a singleton instance of this parameterless lexer action.
    @@INSTANCE = nil
    def self.INSTANCE 
        if @@INSTANCE.nil?
          @@INSTANCE = LexerSkipAction.new()
        end
        @@INSTANCE 
    end
    def initialize() 
        super(LexerActionType.SKIP)
    end

    def execute(lexer)
        lexer.skip()
    end

    def to_s
        return "skip"
    end
end

#  Implements the {@code type} lexer action by calling {@link Lexer#setType}
# with the assigned type.
class LexerTypeAction < LexerAction

    attr_accessor :type
    def initialize(_type)
        super(LexerActionType.TYPE)
        self.type = _type
    end
    def execute(lexer)
        lexer.type = self.type
    end

    def hash
        return "#{self.actionType}#{self.type}".hash
    end

    def ==(other) 
        self.equal? other or other.kind_of? LexerTypeAction and self.type == other.type
    end
    def to_s
        return "type(#{self.type})"
    end
end

# Implements the {@code pushMode} lexer action by calling
# {@link Lexer#pushMode} with the assigned mode.
class LexerPushModeAction < LexerAction

    attr_accessor :mode
    def initialize(_mode)
        super(LexerActionType.PUSH_MODE)
        self.mode = _mode
    end

    # <p>This action is implemented by calling {@link Lexer#pushMode} with the
    # value provided by {@link #getMode}.</p>
    def execute(lexer)
        lexer.pushMode(self.mode)
    end
    
    def hash
        "#{self.actionType}#{self.mode}".hash
    end

    def ==(other)
        self.equal? other or other.kind_of?  LexerPushModeAction and self.mode == other.mode
    end

    def to_s
        "pushMode(#{self.mode})"
    end
end

# Implements the {@code popMode} lexer action by calling {@link Lexer#popMode}.
#
# <p>The {@code popMode} command does not have any parameters, so this action is
# implemented as a singleton instance exposed by {@link #INSTANCE}.</p>
class LexerPopModeAction < LexerAction

    @@INSTANCE = nil
    def self.INSTANCE 
       @@INSTANCE = new() if @@INSTANCE.nil? 
       @@INSTANCE 
    end

    def initialize 
        super(LexerActionType.POP_MODE)
    end

    # <p>This action is implemented by calling {@link Lexer#popMode}.</p>
    def execute(lexer)
        lexer.popMode()
    end

    def to_s
        return "popMode"
    end
end

# Implements the {@code more} lexer action by calling {@link Lexer#more}.
#
# <p>The {@code more} command does not have any parameters, so this action is
# implemented as a singleton instance exposed by {@link #INSTANCE}.</p>
class LexerMoreAction < LexerAction

    @@INSTANCE = nil
    def self.INSTANCE 
       @@INSTANCE = new() if @@INSTANCE.nil? 
       @@INSTANCE 
    end

    def initialize 
        super(LexerActionType.MORE)
    end

    # <p>This action is implemented by calling {@link Lexer#popMode}.</p>
    def execute(lexer)
        lexer.more()
    end

    def to_s 
        return "more"
    end
end

# Implements the {@code mode} lexer action by calling {@link Lexer#mode} with
# the assigned mode.
class LexerModeAction < LexerAction

    def initialize(_mode)
        super(LexerActionType.MODE)
        self.mode = _mode
    end

    # <p>This action is implemented by calling {@link Lexer#mode} with the
    # value provided by {@link #getMode}.</p>
    def execute(lexer)
        lexer.mode = self.mode
    end

    def hash
        "#{self.actionType}#{self.mode}".hash
    end

    def ==(other)
        self.equal? other or other.kind_of? LexerModeAction and self.mode == other.mode
    end

    def to_s
        "mode(#{self.mode})"
    end
end
# Executes a custom lexer action by calling {@link Recognizer#action} with the
# rule and action indexes assigned to the custom action. The implementation of
# a custom action is added to the generated code for the lexer in an override
# of {@link Recognizer#action} when the grammar is compiled.
#
# <p>This class may represent embedded actions created with the <code>{...}</code>
# syntax in ANTLR 4, as well as actions created for lexer commands where the
# command argument could not be evaluated when the grammar was compiled.</p>

class LexerCustomAction < LexerAction

    # Constructs a custom lexer action with the specified rule and action
    # indexes.
    #
    # @param ruleIndex The rule index to use for calls to
    # {@link Recognizer#action}.
    # @param actionIndex The action index to use for calls to
    # {@link Recognizer#action}.
    #/
    attr_accessor :ruleIndex, :actionIndex, :isPositionDependent 
    def initialize(rule_index, action_index)
        super(LexerActionType.CUSTOM)
        @ruleIndex = rule_index
        @actionIndex = action_index
        @isPositionDependent = true
    end
    # <p>Custom actions are implemented by calling {@link Lexer#action} with the
    # appropriate rule and action indexes.</p>
    def execute(lexer)
        lexer.action(nil, self.ruleIndex, self.actionIndex)
    end
    def hash
       "#{self.actionType}#{self.ruleIndex}#{self.actionIndex}".hash
    end

    def ==( other)
        self.equal? other or other.kind_of?  LexerCustomAction \
        and self.ruleIndex == other.ruleIndex and self.actionIndex == other.actionIndex
    end
end
# Implements the {@code channel} lexer action by calling
# {@link Lexer#setChannel} with the assigned channel.
class LexerChannelAction < LexerAction

    # Constructs a new {@code channel} action with the specified channel value.
    # @param channel The channel value to pass to {@link Lexer#setChannel}.
    attr_accessor :channel
    def initialize(_channel)
        super(LexerActionType.CHANNEL)
        self.channel = _channel
    end

    # <p>This action is implemented by calling {@link Lexer#setChannel} with the
    # value provided by {@link #getChannel}.</p>
    def execute(lexer)
        lexer.channel = self.channel
    end
    def hash
        "#{self.actionType}#{self.channel}".hash
    end

    def ==(other)
        self.equal? other or other.kind_of? LexerChannelAction \
          and self.channel == other.channel
    end

    def to_s
        return "channel(#{self.channel})"
    end
end
# This implementation of {@link LexerAction} is used for tracking input offsets
# for position-dependent actions within a {@link LexerActionExecutor}.
#
# <p>This action is not serialized as part of the ATN, and is only required for
# position-dependent lexer actions which appear at a location other than the
# end of a rule. For more information about DFA optimizations employed for
# lexer actions, see {@link LexerActionExecutor#append} and
# {@link LexerActionExecutor#fixOffsetBeforeMatch}.</p>
class LexerIndexedCustomAction < LexerAction

    # Constructs a new indexed custom action by associating a character offset
    # with a {@link LexerAction}.
    #
    # <p>Note: This class is only required for lexer actions for which
    # {@link LexerAction#isPositionDependent} returns {@code true}.</p>
    #
    # @param offset The offset into the input {@link CharStream}, relative to
    # the token start index, at which the specified lexer action should be
    # executed.
    # @param action The lexer action to execute at a particular offset in the
    # input {@link CharStream}.
    attr_accessor :offset, :action, :isPositionDependent 
    def initialize(_offset, _action)
        super(action.actionType)
        self.offset = _offset
        self.action = _action
        self.isPositionDependent = true
    end

    # <p>This method calls {@link #execute} on the result of {@link #getAction}
    # using the provided {@code lexer}.</p>
    def execute(lexer)
        # assume the input stream position was properly set by the calling code
        self.action.execute(lexer)
    end

    def hash
        "#{self.actionType}#{self.offset}#{self.action}".hash
    end

    def ==(other)
        self.equal? other or other.kind_of? LexerIndexedCustomAction \
            and self.offset == other.offset and self.action == other.action
    end
end
