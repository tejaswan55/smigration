lexer grammar SASLexer;

// Lexer tokens in precedence order
// 1. Special keywords that could be mistaken for identifiers
SYMBOLGEN: [Ss][Yy][Mm][Bb][Oo][Ll][Gg][Ee][Nn];
NOCENTER: [Nn][Oo][Cc][Ee][Nn][Tt][Ee][Rr];
MPRINT: [Mm][Pp][Rr][Ii][Nn][Tt];
MLOGIC: [Mm][Ll][Oo][Gg][Ii][Cc];

// 2. Core SAS keywords
OPTIONS: [Oo][Pp][Tt][Ii][Oo][Nn][Ss];
OPTION: [Oo][Pp][Tt][Ii][Oo][Nn];
DATA: [Dd][Aa][Tt][Aa];
PROC: [Pp][Rr][Oo][Cc];
RUN: [Rr][Uu][Nn];
SET: [Ss][Ee][Tt];
NULL: '_NULL_';
DO: '%'[Dd][Oo];
END: '%'[Ee][Nn][Dd];
TO: [Tt][Oo];
BY: [Bb][Yy];
WHILE: [Ww][Hh][Ii][Ll][Ee];
UNTIL: [Uu][Nn][Tt][Ii][Ll];
INPUT: [Ii][Nn][Pp][Uu][Tt];

// 3. Macro-related tokens
MACRO: '%'[Mm][Aa][Cc][Rr][Oo];
MEND: '%'[Mm][Ee][Nn][Dd];
LET: '%'[Ll][Ee][Tt];
THEN: '%'[Tt][Hh][Ee][Nn];
ELSE: '%'[Ee][Ll][Ss][Ee];
IF: '%'[Ii][Ff];
PUT: '%'[Pp][Uu][Tt] -> pushMode(PUT_MODE);
SYSGET: '%'[Ss][Yy][Ss][Gg][Ee][Tt];
SYSFUNC: '%'[Ss][Yy][Ss][Ff][Uu][Nn][Cc];
SYSEVALF: '%'[Ss][Yy][Ss][Ee][Vv][Aa][Ll][Ff];
SYMEXIST: '%'[Ss][Yy][Mm][Ee][Xx][Ii][Ss][Tt];
INCLUDE: '%'[Ii][Nn][Cc][Ll][Uu][Dd][Ee];
INC: '%'[Ii][Nn][Cc];

// 4. Function and statement keywords
LIBNAME: [Ll][Ii][Bb][Nn][Aa][Mm][Ee];
FORMAT: [Ff][Oo][Rr][Mm][Aa][Tt];
MERGE: [Mm][Ee][Rr][Gg][Ee];
OUTPUT: [Oo][Uu][Tt][Pp][Uu][Tt];
CALL: [Cc][Aa][Ll][Ll];
SYMPUT: [Ss][Yy][Mm][Pp][Uu][Tt];
WHERE: [Ww][Hh][Ee][Rr][Ee];
RENAME: [Rr][Ee][Nn][Aa][Mm][Ee];
INFILE: [Ii][Nn][Ff][Ii][Ll][Ee];
TRUNCOVER: [Tt][Rr][Uu][Nn][Cc][Oo][Vv][Ee][Rr];
FIRSTOBS: [Ff][Ii][Rr][Ss][Tt][Oo][Bb][Ss];
DLM: [Dd][Ll][Mm];
DSD: [Dd][Ss][Dd];
MISSOVER: [Mm][Ii][Ss][Ss][Oo][Vv][Ee][Rr];
LINESIZE: [Ll][Ii][Nn][Ee][Ss][Ii][Zz][Ee];
LS: [Ll][Ss];
MISSING: [Mm][Ii][Ss][Ss][Ii][Nn][Gg];
EXECUTE: [Ee][Xx][Ee][Cc][Uu][Tt];
COLUMN: [Cc][Oo][Ll][Uu][Mm][Nn];
KEEP: [Kk][Ee][Ee][Pp];
DROP: [Dd][Rr][Oo][Pp];

// 5. Operators and special characters
SEMICOLON: ';';
COMMA: ',';
DOT: '.';
EQUALS: '=' | [Ee][Qq];
LPAREN: '(';
RPAREN: ')';
LBRACE: '{';
RBRACE: '}';
PLUS: '+';
MINUS: '-';
MULT: '*';
DIV: '/';
POW: '**';
PERCENT: '%';
AMPERSAND: '&';

// 6. Comparison operators
NE: '<>';
LT: '<';
LE: '<=';
GT: '>';
GE: '>=';

// 7. Logical operators
AND: [Aa][Nn][Dd];
OR: [Oo][Rr];
NOT: [Nn][Oo][Tt];
IN: [Ii][Nn];
CONTAINS: [Cc][Oo][Nn][Tt][Aa][Ii][Nn][Ss];

// 8. Format related tokens
INFORMAT: ([Dd][Aa][Tt][Ee] | [Tt][Ii][Mm][Ee] | [Yy][Yy][Mm][Mm][Dd][Dd] 
         | [Cc][Oo][Mm][Mm][Aa] | [Dd][Oo][Ll][Ll][Aa][Rr] 
         | [Pp][Ee][Rr][Cc][Ee][Nn][Tt])[0-9]+'.'
         | [Ee][8][0][0][1][0-9]+('.' [0-9]+)?
         | [Bb][8][0][0][1][0-9]+('.' [0-9]+)?
         | [Ii][Bb][0-9]+('.' [0-9]+)?;

OUTFORMAT: ([Dd][Aa][Tt][Ee] | [Dd][Aa][Tt][Ee][Tt][Ii][Mm][Ee] 
          | [Tt][Ii][Mm][Ee] | [Yy][Yy][Mm][Mm][Dd][Dd])[0-9]+'.';

FORMAT_STYLE: [Yy][Yy][Mm][Mm][Dd][Dd][Nn]?[0-9]+'.';

// 9. Basic tokens (must come after all keywords)
IDENTIFIER: [a-zA-Z_][a-zA-Z0-9_]*;
STRING: ('"' (~["\r\n])* '"') | ('\'' (~['\r\n])* '\'');
NUMBER: [0-9]+ ('.' [0-9]+)?;

// 10. Comments and whitespace (last)
COMMENT: ('/*' .*? '*/') -> channel(HIDDEN);
LINE_COMMENT: ('*' | '%*') ~[\r\n]* ('\r'? '\n' | EOF) -> channel(HIDDEN);
HEADER_COMMENT: '/*' '-'+ .*? '*/' -> channel(HIDDEN);
WS: [ \t\r\n\f]+ -> skip;
// LINE_CONTINUATION: '\\\r'? '\n' -> skip;

UNDERSCORE: '_';
DOLLAR: '$';
COLON: ':';
AT: '@';

mode PUT_MODE;
TEXT: ~[;]+ -> popMode;

