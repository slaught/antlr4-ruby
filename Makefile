
RUBY=rbx 
RUBY_SYNTAX=$(RUBY) -c

BUILD_DIR=BUILD
JAVA_SRC=tool/src/org/antlr/v4/codegen/RubyTarget.java 
STG_SRC=tool/resources/org/antlr/v4/tool/templates/codegen/Ruby/Ruby.stg
JAR_FILE=antlr4-ruby.jar
ANTLR=java -cp ~/lib:$(CLASSPATH) org.antlr.v4.Tool -Dlanguage=Ruby 

all:
	@echo "$(JAR_FILE)      build jar file with Antlr4 Ruby support"
	@echo "test             build, gen_test, syntax_check, run_test"

$(BUILD_DIR): 
	mkdir $(BUILD_DIR)

  
$(JAR_FILE): $(BUILD_DIR) $(JAVA_SRC) $(STG_SRC)
	javac -d $(BUILD_DIR) $(JAVA_SRC)
	cp -r tool/resources/ $(BUILD_DIR)
	jar cf $@  -C $(BUILD_DIR) org

build: antlr4-ruby.jar

oldbuild:
	javac -d ~/lib tool/src/org/antlr/v4/codegen/RubyTarget.java
	cp -r tool/resources/ ~/lib/

test_pjm: build gen_test_pjm syntax_check_pjm run_test_pjm

gen_test_pjm:
	(cd t; java -cp ../$(JAR_FILE):$(CLASSPATH) org.antlr.v4.Tool -Dlanguage=Ruby PjmInvoice.g4)

syntax_check_pjm: 
	$(RUBY_SYNTAX) t/PjmInvoiceLexer.rb   
	$(RUBY_SYNTAX) t/PjmInvoiceListener.rb 
	$(RUBY_SYNTAX) t/PjmInvoiceParser.rb

run_test_pjm:
	$(RUBY) -Ilib:t t/PjmInvoiceLexer.rb   
	$(RUBY) -Ilib:t t/PjmInvoiceListener.rb 
	$(RUBY) -Ilib:t t/PjmInvoiceParser.rb

test: oldbuild gen_test_tnt syntax_check_tnt run_test_tnt

gen_test_tnt:
	(cd tnt; $(ANTLR) Tnt.g4)

syntax_check_tnt: 
	$(RUBY_SYNTAX) tnt/TntLexer.rb   
	$(RUBY_SYNTAX) tnt/TntListener.rb 
	$(RUBY_SYNTAX) tnt/TntParser.rb

run_test_tnt:
	$(RUBY) -Ilib:tnt tnt/TntLexer.rb   
	$(RUBY) -Ilib:tnt tnt/TntListener.rb 
	$(RUBY) -Ilib:tnt tnt/TntParser.rb

add:
	git add tool/resources/org/antlr/v4/tool/templates/codegen/Ruby/Ruby.stg
	git add tool/src/org/antlr/v4/codegen/RubyTarget.java

test1:
	rbx -It -Ilib RubyTest.rb pjm_msrs_Week_Bill_L_2014-07-26.pjmcsv

test2: 
	rbx -It:lib t1.rb

test3:
	rbx -It -Ilib RubyTest.rb test1 pjm_msrs_Week_Bill_L_2014-07-26.pjmcsv





