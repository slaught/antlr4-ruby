

class ATNDeserializationOptions 

    @@defaultOptions = nil
    def self.defaultOptions 
#      if @@defaultOptions.nil?
         @@defaultOptions = new 
         @@defaultOptions.makeReadOnly() 
#      end
     @@defaultOptions  
    end

    attr_accessor :readonly, :verifyATN ,:generateRuleBypassTransitions
    def initialize(options=nil )
        if options.nil?
          @verifyATN = true 
          @generateRuleBypassTransitions = false
        else
          @verifyATN = options.verifyATN
          @generateRuleBypassTransitions = options.generateRuleBypassTransitions
        end

    end
    def self.getDefaultOptions() 
		      self.defaultOptions
    end
    def isReadOnly
        self.readonly
    end
	  def makeReadOnly() 
    		self.readonly = true
    end

    def verifyATN=(verifyATN)
  		throwIfReadOnly()
  		@verifyATN = verifyATN
    end
	  def isVerifyATN() 
		    self.verifyATN
    end
    def setVerifyATN(verifyATN) 
        self.verifyATN = verifyATN
	  end

	  def isGenerateRuleBypassTransitions() 
		  self.generateRuleBypassTransitions
    end
    def setGenerateRuleBypassTransitions(generateRuleBypassTransitions) 
      self.generateRuleBypassTransitions = generateRuleBypassTransitions
	  end
    def generateRuleBypassTransitions=(generateRuleBypassTransitions)
  		throwIfReadOnly()
      @generateRuleBypassTransitions = generateRuleBypassTransitions
	  end
    protected 
    def throwIfReadOnly() 
    		if isReadOnly() then
          raise IllegalStateException.new("The object is read only.")
        end
    end
end
