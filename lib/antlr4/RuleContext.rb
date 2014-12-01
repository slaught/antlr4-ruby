#  A rule context is a record of a single rule invocation. It knows
#  which context invoked it, if any. If there is no parent context, then
#  naturally the invoking state is not valid.  The parent link
#  provides a chain upwards from the current rule invocation to the root
#  of the invocation tree, forming a stack. We actually carry no
#  information about the rule associated with this context (except
#  when parsing). We keep only the state number of the invoking state from
#  the ATN submachine that invoked this. Contrast this with the s
#  pointer inside ParserRuleContext that tracks the current state
#  being "executed" for the current rule.
#
#  The parent contexts are useful for computing lookahead sets and
#  getting error information.
#
#  These objects are used during parsing and prediction.
#  For the special case of parsers, we use the subclass
#  ParserRuleContext.
#
#  @see ParserRuleContext

class RuleContext < RuleNode

    @@EMPTY = nil
    def self.EMPTY
      if @@EMPTY.nil? then
        @@EMPTY = ParserRuleContext.new()
      end
      @@EMPTY
    end

    attr_accessor :parentCtx, :invokingState 
    def initialize(parent=nil, invoking_state=-1)
        super()
        # What context invoked this rule?
        @parentCtx = parent
        # What state invoked the rule associated with this context?
        #  The "return address" is the followState of invokingState
        #  If parent is null, this should be -1.
        @invokingState = invoking_state
    end

    def depth
        n = 0
        p = self
        while not p.nil? do 
            p = p.parentCtx
            n = n + 1
        end
        return n
    end

    # A context is empty if there is no invoking state; meaning nobody call
    #  current context.
    def isEmpty
        return self.invokingState == -1
    end

    # satisfy the ParseTree / SyntaxTree interface

    def getSourceInterval
        return Antlr4::INVALID_INTERVAL
    end

    def getRuleContext
        return self
    end

    def getPayload
        return self
    end

   # Return the combined text of all child nodes. This method only considers
    #  tokens which have been added to the parse tree.
    #  <p>
    #  Since tokens on hidden channels (e.g. whitespace or comments) are not
    #  added to the parse trees, they will not appear in the output of this
    #  method.
    #/
    def getText
        if self.getChildCount() == 0
            return ""
        end
        StringIO.open  do |builder|
            self.getChildren().each {|child| builder.write(child.getText()) }
            return builder.string()
        end
    end

    def getRuleIndex
        return -1
    end

    def getChild(i)
        return nil
    end

    def getChildCount
        return 0
    end

    def getChildren
       Array.new #  [].map {|c| c } 
    end
    def accept(visitor)
        return visitor.visitChildren(self)
    end

   # # Call this method to view a parse tree in a dialog box visually.#/
   #  public Future<JDialog> inspect(@Nullable Parser parser) {
   #      List<String> ruleNames = parser != null ? Arrays.asList(parser.getRuleNames()) : null;
   #      return inspect(ruleNames);
   #  }
   #
   #  public Future<JDialog> inspect(@Nullable List<String> ruleNames) {
   #      TreeViewer viewer = new TreeViewer(ruleNames, this);
   #      return viewer.open();
   #  }
   #
   # # Save this tree in a postscript file#/
   #  public void save(@Nullable Parser parser, String fileName)
   #      throws IOException, PrintException
   #  {
   #      List<String> ruleNames = parser != null ? Arrays.asList(parser.getRuleNames()) : null;
   #      save(ruleNames, fileName);
   #  }
   #
   # # Save this tree in a postscript file using a particular font name and size#/
   #  public void save(@Nullable Parser parser, String fileName,
   #                   String fontName, int fontSize)
   #      throws IOException
   #  {
   #      List<String> ruleNames = parser != null ? Arrays.asList(parser.getRuleNames()) : null;
   #      save(ruleNames, fileName, fontName, fontSize);
   #  }
   #
   # # Save this tree in a postscript file#/
   #  public void save(@Nullable List<String> ruleNames, String fileName)
   #      throws IOException, PrintException
   #  {
   #      Trees.writePS(this, ruleNames, fileName);
   #  }
   #
   # # Save this tree in a postscript file using a particular font name and size#/
   #  public void save(@Nullable List<String> ruleNames, String fileName,
   #                   String fontName, int fontSize)
   #      throws IOException
   #  {
   #      Trees.writePS(this, ruleNames, fileName, fontName, fontSize);
   #  }
   #
   # # Print out a whole tree, not just a node, in LISP format
   #  #  (root child1 .. childN). Print just a node if this is a leaf.
   #  #  We have to know the recognizer so we can get rule names.
   #  #/
   #  @Override
   #  public String toStringTree(@Nullable Parser recog) {
   #      return Trees.toStringTree(this, recog);
   #  }
   #
   # Print out a whole tree, not just a node, in LISP format
   #  (root child1 .. childN). Print just a node if this is a leaf.
   #
    def toStringTree(ruleNames=nil ,recog=nil)
        return Trees.toStringTree(self, ruleNames, recog)
    end
   #  }
   #
   #  @Override
   #  public String toStringTree() {
   #      return toStringTree((List<String>)null);
   #  }
   #
    def to_s 
        return self.toString(nil, nil)
    end

   #  @Override
   #  public String toString() {
   #      return toString((List<String>)null, (RuleContext)null);
   #  }
   #
   #  public final String toString(@Nullable Recognizer<?,?> recog) {
   #      return toString(recog, ParserRuleContext.EMPTY);
   #  }
   #
   #  public final String toString(@Nullable List<String> ruleNames) {
   #      return toString(ruleNames, null);
   #  }
   #
   #  // recog null unless ParserRuleContext, in which case we use subclass toString(...)
   #  public String toString(@Nullable Recognizer<?,?> recog, @Nullable RuleContext stop) {
   #      String[] ruleNames = recog != null ? recog.getRuleNames() : null;
   #      List<String> ruleNamesList = ruleNames != null ? Arrays.asList(ruleNames) : null;
   #      return toString(ruleNamesList, stop);
   #  }

    def toString(ruleNames, stop) #->str#ruleNames:list, stop:RuleContext)->str:
        StringIO.open  do |buf|
            p = self
            buf.write("[")
            while (not p.nil?) and p != stop do
                if ruleNames.nil? then
                    if not p.isEmpty()
                        buf.write(p.invokingState.to_s)
                    end
                else
                    ri = p.getRuleIndex()
                    if ri >= 0 and ri < ruleNames.length
                        ruleName = ruleNames[ri] 
                    else 
                        ruleName = ri.to_s
                    end
                    # ruleName = ruleNames[ri] if ri >= 0 and ri < len(ruleNames) else str(ri)
                    buf.write(ruleName)
                end
                if p.parentCtx and (ruleNames or not p.parentCtx.isEmpty()) then
                    buf.write(" ")
                end
                p = p.parentCtx
            end
            buf.write("]")
            return buf.string()
        end
    end
end

