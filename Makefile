
RUBY=rbx 
RUBY_SYNTAX=$(RUBY) -c

JAVA_SRC=tool/src/org/antlr/v4/codegen/RubyTarget.java 
STG_SRC=tool/resources/org/antlr/v4/tool/templates/codegen/Ruby/Ruby.stg
BUILD_DIR=BUILD
PKG=pkg
JAR_FILE=$(PKG)/antlr4-ruby.jar
ANTLR=java -cp $(JAR_FILE):$(CLASSPATH) org.antlr.v4.Tool -Dlanguage=Ruby 

all:
	@echo "build            build jar file with Antlr4 Ruby support"
	@echo "test             build, gen_test, syntax_check, run_test"

$(BUILD_DIR): 
	mkdir $(BUILD_DIR)

$(PKG):
	mkdir $@ 
  
  
$(JAR_FILE): $(PKG) $(BUILD_DIR) $(JAVA_SRC) $(STG_SRC)
	javac -d $(BUILD_DIR) $(JAVA_SRC)
	cp -r tool/resources/ $(BUILD_DIR)
	jar cf $@  -C $(BUILD_DIR) org

build: $(JAR_FILE)

oldbuild:
	javac -d ~/lib tool/src/org/antlr/v4/codegen/RubyTarget.java
	cp -r tool/resources/ ~/lib/

test: build gen_test_tnt syntax_check_tnt run_test_tnt

gen_test_tnt: $(JAR_FILE)
	(cd tnt; $(ANTLR) Tnt.g4)

syntax_check_tnt: 
	$(RUBY_SYNTAX) tnt/TntLexer.rb   
	$(RUBY_SYNTAX) tnt/TntListener.rb 
	$(RUBY_SYNTAX) tnt/TntParser.rb

run_test_tnt:
	$(RUBY) -Ilib:tnt tnt/TntLexer.rb   
	$(RUBY) -Ilib:tnt tnt/TntListener.rb 
	$(RUBY) -Ilib:tnt tnt/TntParser.rb

