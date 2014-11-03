This is the Ruby runtime and target for Antlr4.

This is based on the Python3 & Java runtime & targets.


Usage
-----
To use the Ruby language codegen for Antlrv4 do the following.

1. Create the jar file.
```bash
% make antlr4-ruby.jar
```
2. Put the jar file in your java class path 


3. Use either the _options_ section  or the -D switch

```
  options {  language = Ruby ; }
```

```
java org.antlr.v4.Tool -Dlanguage=Ruby input.g4
```


Missing Features
----------------
* Ruby runtime is not in a proper module and library setup
* The Ruby test for integration with antlr4 are missin

