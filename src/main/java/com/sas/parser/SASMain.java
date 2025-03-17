package com.sas.parser;

import org.antlr.v4.runtime.CharStream;
import org.antlr.v4.runtime.CharStreams;
import org.antlr.v4.runtime.CommonTokenStream;
import org.antlr.v4.runtime.tree.ParseTree;
import org.antlr.v4.runtime.tree.ParseTreeWalker;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;

public class SASMain {
    public static void main(String[] args) throws IOException {
        if (args.length < 1) {
            System.err.println("Please provide a SAS file path");
            System.exit(1);
        }

        String sasCode = new String(Files.readAllBytes(Paths.get(args[0])));
        
        // Create lexer and parser
        CharStream input = CharStreams.fromString(sasCode);
        SASLexer lexer = new SASLexer(input);
        CommonTokenStream tokens = new CommonTokenStream(lexer);
        SASParser parser = new SASParser(tokens);
        
        // Parse the input
        ParseTree tree = parser.program();
        
        // Walk the parse tree with our listener
        ParseTreeWalker walker = new ParseTreeWalker();
        CustomSASParserListener listener = new CustomSASParserListener();
        walker.walk(listener, tree);
    }
}
