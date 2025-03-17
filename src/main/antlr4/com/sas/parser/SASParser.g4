parser grammar SASParser;

options {
    tokenVocab = SASLexer;
}

// Program structure
program: (programStatement | comment)+ EOF;

programStatement
    : basicStatement
    | dataStepStatement
    | procStepStatement 
    | macroDefStatement
    | macroCall
    ;

basicStatement
    : letStatement
    | putStatement
    | ifStatement
    | setStatement
    | includeStatement
    | incStatement
    | libraryStatement
    | callStatement
    | optionsStatement
    | assignment
    | infileStatement
    | inputStatement
    ;

dataStepStatement
    : DATA (datasetName | NULL) (dataOptions)? SEMICOLON
      (dataStepContent)*
      RUN SEMICOLON
    ;

dataStepContent
    : programStatement
    ;

// Add IF statement rules
ifStatement
    : IF condition THEN macroStatement (ELSE macroStatement)?
    | IF condition THEN doStatement (ELSE doStatement)?
    ;

doStatement
    : simpleDo
    | iterativeDo
    | whileDo
    | untilDo
    ;

simpleDo
    : DO SEMICOLON
      (dataStepContent)*
      END SEMICOLON
    ;

iterativeDo
    : DO identifier EQUALS expression TO expression (BY expression)? SEMICOLON
      (dataStepContent)*
      END SEMICOLON
    ;

whileDo
    : DO WHILE LPAREN condition RPAREN SEMICOLON
      (dataStepContent)*
      END SEMICOLON
    ;

untilDo
    : DO UNTIL LPAREN condition RPAREN SEMICOLON
      (dataStepContent)*
      END SEMICOLON
    ;

procStepStatement
    : PROC identifier procOptions? SEMICOLON
      (procStepContent)*
      RUN SEMICOLON
    ;

procStepContent
    : basicStatement
    ;

macroDefStatement
    : MACRO identifier (LPAREN macroParams? RPAREN)? SEMICOLON
      (programStatement)*
      MEND (identifier)? SEMICOLON
    ;

// Macro handling
macroStatement
    : macroDefinition
    | macroCall
    ;

macroDefinition
    : MACRO identifier ('(' macroParams? ')')?
      basicStatement*
      MEND (identifier)?
    ;

macroCall
    : PERCENT identifier (LPAREN macroArgList? RPAREN)? SEMICOLON
    ;

macroArgList
    : macroArg (COMMA macroArg)*
    ;

macroArg
    : identifier EQUALS macroArgValue
    ;

macroArgValue
    : (identifier | literal) (identifier | literal)*
    | expression
    ;

// Expression handling
expression
    : LPAREN expression RPAREN
    | (PLUS | MINUS) expression
    | expression POW expression
    | expression (MULT | DIV) expression
    | expression (PLUS | MINUS) expression
    | functionExpression
    | macroFunction
    | variable
    | literal
    ;

// Function handling
functionExpression
    : standardFunction
    | inputFunction
    ;

standardFunction
    : identifier LPAREN functionArgList? RPAREN
    ;

inputFunction
    : INPUT LPAREN functionArgList RPAREN
    ;

// Format handling
format
    : IDENTIFIER ('.' NUMBER?)?
    | DOLLAR IDENTIFIER ('.' NUMBER?)?
    | (OUTFORMAT | INFORMAT | FORMAT_STYLE)
    ;

inputFormat
    : format
    | COLON (NUMBER | DOLLAR NUMBER)? ('.' identifier?)?
    ;

// Common elements
macroVariable: AMPERSAND identifier (DOT | DOT (UNDERSCORE identifier) | DOT identifier)?;
datasetName: (variable DOT)? variable;
identifier: IDENTIFIER;
literal: STRING | NUMBER;

// Options and parameters
optionsAndParameters
    : '(' option (COMMA? option)* ')'
    ;

option
    : identifier (EQUALS (expression | STRING))?
     ;

// Missing statement definitions
letStatement: LET identifier EQUALS letValue SEMICOLON;

letValue
    : macroFunction
    | expression
    | STRING
    ;

// Update putStatement rule
putStatement: PUT (TEXT | assignment | expression | macroVariable | STRING) SEMICOLON;

includeStatement: INCLUDE STRING SEMICOLON;

libraryStatement: LIBNAME variable (STRING | identifier) libOptions? SEMICOLON;

callStatement
    : (CALL identifier LPAREN callArgs? RPAREN
    | CALL SYMPUT LPAREN symputArgs RPAREN
    | CALL EXECUTE LPAREN STRING RPAREN) SEMICOLON
    ;

// Missing option definitions
libOptions: optionsAndParameters;
procOptions: optionsAndParameters;
dataOptions
    : optionsAndParameters
    | formatOption
    | whereClause
    ;

formatOption: FORMAT formatList;
formatList: formatItem (COMMA formatItem)*;
formatItem: identifier format;

whereClause: WHERE condition;
condition
    : expression comparison expression
    | condition (AND | OR) condition
    | NOT condition
    | LPAREN condition RPAREN
    ;

comparison: EQUALS | NE | LT | LE | GT | GE | IN | CONTAINS;

// Missing parameter definitions
callArgs: functionArgList;
symputArgs: (STRING | expression) COMMA (expression | functionExpression);
functionArgList: functionArg (COMMA functionArg)*;
functionArg: (expression | format | inputFormat);
macroParams: macroParam (COMMA macroParam)* (COMMA)?;
macroParam: identifier (EQUALS | EQUALS expression)?;

// Data step specific statements
setStatement: SET datasetName setOptions? SEMICOLON;

setOptions
    : DIV LPAREN setOptionsList RPAREN
    | dataOptions
    | LPAREN datasetOption RPAREN
    ;

datasetOption
    : keepOption
    | dropOption
    | renameClause
    | whereClause
    ;

keepOption
    : KEEP EQUALS? keepList
    ;

keepList
    : keepItem (keepItem)*
    ;

keepItem
    : identifier COLON?    // For prefix matches like IND_USER:
    | identifier
    ;

dropOption
    : DROP EQUALS? identifierList
    ;

setOptionsList
    : setOption (COMMA setOption)*
    ;

setOption
    : renameClause
    | option
    ;

renameClause
    : RENAME EQUALS LPAREN renameList RPAREN
    ;

renameList
    : renameItem (COMMA renameItem)*
    ;

renameItem
    : identifier EQUALS identifier
    ;

mergeStatement: MERGE datasetList;
byStatement: BY identifierList;
outputStatement: OUTPUT datasetName?;
datasetList: datasetName (COMMA datasetName)*;
identifierList: identifier (COMMA identifier)*;

// Add missing assignment definition
assignment
    : (identifier EQUALS expression
    | datasetName EQUALS expression) SEMICOLON
    ;

inputStatement
    : INPUT datasetFields SEMICOLON
    ;

datasetFields
    : datasetField (datasetField)*
    ;

datasetField
    : identifier inputFormat?
    | AT COLUMN identifier inputFormat?
    | pointer identifier inputFormat?
    ;

pointer
    : AT NUMBER
    | PLUS NUMBER
    ;

infileStatement
    : INFILE (STRING | identifier) infileOptions* SEMICOLON
    ;

infileOptions
    : option (COMMA? option)*
    | TRUNCOVER
    | FIRSTOBS EQUALS NUMBER
    | DLM EQUALS STRING
    | DSD
    | MISSOVER
    | (LINESIZE | LS) EQUALS NUMBER
    ;

// Add missing option statement
optionsStatement
    : (OPTIONS optionsList
    | OPTION identifier EQUALS expression) SEMICOLON
    ;

optionsList
    : optionsItem (COMMA? optionsItem)*
    ;

optionsItem
    : MISSING EQUALS STRING
    | NOCENTER
    | identifier (EQUALS expression)?
     ;

// Add comment type definitions
comment
    : blockComment
    | lineComment
    | headerComment
    ;

blockComment: COMMENT;
lineComment: LINE_COMMENT;
headerComment: HEADER_COMMENT;

// Add macro function definition
macroFunction
    : (SYSGET | SYSFUNC | SYSEVALF | SYMEXIST) LPAREN (expression) RPAREN
    ;
 
variable
    : macroVariable
    | identifier (identifier)*
    ;

incStatement
    : INC (STRING | IDENTIFIER) SEMICOLON
    ;
