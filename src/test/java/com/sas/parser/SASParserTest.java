package com.sas.parser;

import org.antlr.v4.runtime.CharStreams;
import org.antlr.v4.runtime.CommonTokenStream;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

public class SASParserTest {

    @Test
    public void testMacroStatement() {
        String sasCode = "%LET RUNDATE = %SYSGET(RUNDATE);";
        SASLexer lexer = new SASLexer(CharStreams.fromString(sasCode));
        SASParser parser = new SASParser(new CommonTokenStream(lexer));
        assertNotNull(parser.program());
    }

    @Test
    public void testDataStep() {
        String sasCode = "data test; run;";
        SASLexer lexer = new SASLexer(CharStreams.fromString(sasCode));
        SASParser parser = new SASParser(new CommonTokenStream(lexer));
        assertNotNull(parser.program());
    }

    @Test
    public void testProcStep() {
        String sasCode = "proc print; run;";
        SASLexer lexer = new SASLexer(CharStreams.fromString(sasCode));
        SASParser parser = new SASParser(new CommonTokenStream(lexer));
        assertNotNull(parser.program());
    }

    @Test
    public void testAssignment() {
        String sasCode = "x = 10;";
        SASLexer lexer = new SASLexer(CharStreams.fromString(sasCode));
        SASParser parser = new SASParser(new CommonTokenStream(lexer));
        assertNotNull(parser.program());
    }

    @Test
    public void testPutStatement() {
        String sasCode = "%put Hello World;";
        SASLexer lexer = new SASLexer(CharStreams.fromString(sasCode));
        SASParser parser = new SASParser(new CommonTokenStream(lexer));
        assertNotNull(parser.program());
    }

    @Test
    public void testGenericFunction() {
        String sasCode = "x = myFunction(10, 20);";
        SASLexer lexer = new SASLexer(CharStreams.fromString(sasCode));
        SASParser parser = new SASParser(new CommonTokenStream(lexer));
        assertNotNull(parser.program());
    }

    @Test
    public void testInbuiltFunction() {
        String sasCode = "x = sum(10, 20);";
        SASLexer lexer = new SASLexer(CharStreams.fromString(sasCode));
        SASParser parser = new SASParser(new CommonTokenStream(lexer));
        assertNotNull(parser.program());
    }

    @Test
    public void testLetStatement() {
        String[] testCases = {
            "%LET RUNDATE = %SYSGET(RUNDATE);",
            "%LET myvar = unquoted_value;",
            "%LET quoted = \"quoted value\";",
            "%LET mixed = %sysfunc(today);"
        };
        
        for (String sasCode : testCases) {
            SASLexer lexer = new SASLexer(CharStreams.fromString(sasCode));
            SASParser parser = new SASParser(new CommonTokenStream(lexer));
            assertNotNull(parser.program());
        }
    }

    @Test
    public void testSystemFunction() {
        String[] testCases = {
            "%LET x = %SYSGET(RUNDATE);",
            "%LET x = %SYSGET(\"RUNDATE\");",
            "%LET x = %sysfunc(today);",
            "data _null_; x = %sysfunc(date()); run;"
        };
        
        for (String sasCode : testCases) {
            SASLexer lexer = new SASLexer(CharStreams.fromString(sasCode));
            SASParser parser = new SASParser(new CommonTokenStream(lexer));
            assertNotNull(parser.program());
        }
    }

    @Test
    public void testComments() {
        String[] testCases = {
            "/* This is a comment */\n%LET x = 1;",
            "* This is a line comment;\ndata test; run;",
            "%* This is a macro comment;\n%let x = 1;",
            "data test; /* inline comment */ x = 1; run;",
            "* Multiple;\n* Line;\n* Comments;\nproc print; run;"
        };
        
        for (String sasCode : testCases) {
            SASLexer lexer = new SASLexer(CharStreams.fromString(sasCode));
            SASParser parser = new SASParser(new CommonTokenStream(lexer));
            assertNotNull(parser.program());
        }
    }

    @Test
    public void testNestedComments() {
        String[] testCases = {
            "/* outer /* inner */ comment */ data test; run;",
            "/* multi\nline /* nested\n */ comment */ %let x = 1;",
            "data test; /* comment /* with */ nesting */ run;",
            "/* /* /* deeply */ nested */ comment */ proc print; run;"
        };
        
        for (String sasCode : testCases) {
            SASLexer lexer = new SASLexer(CharStreams.fromString(sasCode));
            SASParser parser = new SASParser(new CommonTokenStream(lexer));
            assertNotNull(parser.program());
        }
    }

    @Test
    public void testHeaderComments() {
        String[] testCases = {
            "/*----------------------------------------------------------------------------------------------*/\n" +
            "/*   PROGRAM:   Test.sas                                                                         */\n" +
            "/*   VERSION:   1.0                                                                             */\n" +
            "%let x = 1;",
            
            "/*----------------------------------------*/\n" +
            "/* Simple header comment                   */\n" +
            "/*----------------------------------------*/\n" +
            "data test; run;"
        };
        
        for (String sasCode : testCases) {
            SASLexer lexer = new SASLexer(CharStreams.fromString(sasCode));
            SASParser parser = new SASParser(new CommonTokenStream(lexer));
            assertNotNull(parser.program());
        }
    }

    @Test
    public void testCaseInsensitiveIdentifiers() {
        String[] testCases = {
            "DATA test; run;",
            "data TEST; RUN;",
            "Data Test; Run;",
            "%let MyVar = value;",
            "proc PRINT; run;",
            "LIBNAME myLib 'path';",
            "data _null_; x = MyFunction(1,2); run;"
        };
        
        for (String sasCode : testCases) {
            SASLexer lexer = new SASLexer(CharStreams.fromString(sasCode));
            SASParser parser = new SASParser(new CommonTokenStream(lexer));
            assertNotNull(parser.program());
        }
    }

    @Test
    public void testOptionsStatement() {
        String[] testCases = {
            "options missing=' ';",
            "OPTIONS MISSING=' ';",
            "options nocenter;",
            "options missing=' ' nocenter;",
            "option missing=' ';"
        };
        
        for (String sasCode : testCases) {
            SASLexer lexer = new SASLexer(CharStreams.fromString(sasCode));
            SASParser parser = new SASParser(new CommonTokenStream(lexer));
            assertNotNull(parser.program());
        }
    }

    @Test
    public void testLibraryStatement() {
        String[] testCases = {
            "libname mylib '/path/to/data';",
            "LIBNAME MYLIB 'path' access=readonly;",
            "libname mylib oracle path='db' schema='dbo';",
            "libname mylib '/path' (compress=yes engine=v9);",
            "libname mylib base '/path' encoding=utf8;"
        };
        
        for (String sasCode : testCases) {
            SASLexer lexer = new SASLexer(CharStreams.fromString(sasCode));
            SASParser parser = new SASParser(new CommonTokenStream(lexer));
            assertNotNull(parser.program());
        }
    }

    @Test
    public void testCallStatement() {
        String[] testCases = {
            "call symput('var', 'value');",
            "call execute('%macro1()');",
            "call missing(var1);",
            "call myFunction(param1, param2);",
            "call symput(cats('prefix_', var1), sum(10, 20));",
            "call execute('%macro1(' || var1 || ')');",
            "data _null_; call symput('date',put(today(),date9.)); run;"
        };
        
        for (String sasCode : testCases) {
            SASLexer lexer = new SASLexer(CharStreams.fromString(sasCode));
            SASParser parser = new SASParser(new CommonTokenStream(lexer));
            assertNotNull(parser.program());
        }
    }

    @Test
    public void testComplexCallSymput() {
        String[] testCases = {
            "call symput('RUNDATEP',put(input('&rundate',yymmdd8.)-1,yymmddn8.));",
            "call symput('RUNDATEN',put(input('&rundate',yymmdd8.)+1,yymmddn8.));",
            "call symput('date',put(today(),yymmddn8.));",
            "call symput('val', put(input(substr(var,1,4),8.)));"
        };
        
        for (String sasCode : testCases) {
            SASLexer lexer = new SASLexer(CharStreams.fromString(sasCode));
            SASParser parser = new SASParser(new CommonTokenStream(lexer));
            assertNotNull(parser.program());
        }
    }

    @Test
    public void testInputFunction() {
        String[] testCases = {
            "x = input(date_str, date9.);",
            "time = input(time_str, time8.);",
            "num = input(str, 8.2);",
            "text = input(str, $char8.);",
            "dt = input(dt_str, datetime20.);",
            "money = input(amount, dollar12.);",
            "pct = input(rate, percent8.);",
            "call symput('date',input(substr(put(today(),yymmdd10.),1,4), 8.));",
            "x = input('01JAN2023', date9.);",
            "num = input(string_var, best12.);",
            "amount = input(text, dollar10.2);",
            "percent = input(rate_str, percent6.);",
            "data _null_; x = input(scan(date,1), yymmdd10.); run;"
        };
        
        for (String sasCode : testCases) {
            SASLexer lexer = new SASLexer(CharStreams.fromString(sasCode));
            SASParser parser = new SASParser(new CommonTokenStream(lexer));
            assertNotNull(parser.program());
        }
    }

    @Test
    public void testPutFunction() {
        String[] testCases = {
            "x = put(date, date9.);",
            "str = put(timestamp, datetime20.);",
            "timestr = put(time_var, time8.);",
            "datestr = put(today(), yymmdd10.);",
            "numstr = put(number, comma10.);",
            "moneystr = put(amount, dollar12.2);",
            "data _null_; call symput('date',put(today(),yymmddn8.)); run;",
            "formatted = put(cats(var1, var2), $char20.);"
        };
        
        for (String sasCode : testCases) {
            SASLexer lexer = new SASLexer(CharStreams.fromString(sasCode));
            SASParser parser = new SASParser(new CommonTokenStream(lexer));
            assertNotNull(parser.program());
        }
    }

    @Test
    public void testArithmeticOperations() {
        String[] testCases = {
            "x = 1 + 2;",
            "y = 10 - 5;",
            "z = 3 * 4;",
            "a = 20 / 5;",
            "b = 2 ** 3;",
            "c = (1 + 2) * 3;",
            "d = -5 + 10;",
            "e = x + y * (z - 2);",
            "result = (revenue - cost) / units;",
            "power = base ** (exponent + 1);"
        };
        
        for (String sasCode : testCases) {
            SASLexer lexer = new SASLexer(CharStreams.fromString(sasCode));
            SASParser parser = new SASParser(new CommonTokenStream(lexer));
            assertNotNull(parser.program());
        }
    }

    @Test
    public void testFunctionChaining() {
        String[] testCases = {
            "call symput('RUNDATEP',put(input('&rundate',yymmdd8.)-1,yymmddn8.));",
            "x = put(input(substr(put(today(),yymmdd10.),1,4),8.),date9.);",
            "y = cats(put(input(trim(var),8.),date9.));",
            "z = %sysfunc(input(%sysfunc(date()),yymmdd10.));",
            "data _null_; call symput('val',put(input(scan(str,1),8.),comma10.)); run;"
        };
        
        for (String sasCode : testCases) {
            SASLexer lexer = new SASLexer(CharStreams.fromString(sasCode));
            SASParser parser = new SASParser(new CommonTokenStream(lexer));
            assertNotNull(parser.program());
        }
    }

    @Test
    public void testLiteralStrings() {
        String[] testCases = {
            "%let var = unquoted_literal_value;",
            "data _null_; x = literal_value; run;",
            "call symput('var', unquoted_value);",
            "%let path = /path/to/file;",
            "libname mylib path_value access=readonly;"
        };
        
        for (String sasCode : testCases) {
            SASLexer lexer = new SASLexer(CharStreams.fromString(sasCode));
            SASParser parser = new SASParser(new CommonTokenStream(lexer));
            assertNotNull(parser.program());
        }
    }

    @Test
    public void testSetStatementWithOptions() {
        String[] testCases = {
            "set stgn.GCMMP (keep= IND_USER: account_nbr CUSTOMER_NBR COLL_ORG ORGANIZATION);",
            "set mylib.data (drop= temp1 temp2);",
            "set input.data (keep=id name rename=(id=customer_id));",
            "set source.data (where=(date > '01JAN2023'd));",
            "set temp/*(obs=1000)*/;",
            "set work.tmp (firstobs=100 obs=1000);"
        };
        
        for (String sasCode : testCases) {
            SASLexer lexer = new SASLexer(CharStreams.fromString(sasCode));
            SASParser parser = new SASParser(new CommonTokenStream(lexer));
            assertNotNull(parser.program());
        }
    }

    @Test
    public void testInputStatement() {
        String[] testCases = {
            "input @1 id $8. name $20.;",
            "input @10 date yymmdd10. @20 amount 8.2;",
            "input @1 var1 $1. @3 var2 2. @6 var3 $4.;",
            "input id $ name $ age;",
            "input @'ID:' id $8. @'NAME:' name $20.;"
        };
        
        for (String sasCode : testCases) {
            SASLexer lexer = new SASLexer(CharStreams.fromString(sasCode));
            SASParser parser = new SASParser(new CommonTokenStream(lexer));
            assertNotNull(parser.program());
        }
    }

    @Test
    public void testComplexDataStep() {
        String[] testCases = {
            "data output;\n" +
            "  set input (keep=id name salary);\n" +
            "  where salary > 50000;\n" +
            "  if name = ' ' then delete;\n" +
            "run;",
            
            "data _null_;\n" +
            "  set source.data (keep=IND_USER: account_nbr);\n" +
            "  call symput('total', put(sum(of account_nbr), 12.2));\n" +
            "run;"
        };
        
        for (String sasCode : testCases) {
            SASLexer lexer = new SASLexer(CharStreams.fromString(sasCode));
            SASParser parser = new SASParser(new CommonTokenStream(lexer));
            assertNotNull(parser.program());
        }
    }
}
