package com.sas.parser;

import org.antlr.v4.runtime.CharStream;
import org.antlr.v4.runtime.CharStreams;
import org.antlr.v4.runtime.CommonTokenStream;
import org.antlr.v4.runtime.tree.ParseTree;
import org.antlr.v4.runtime.tree.ParseTreeWalker;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

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
        ExpressionWriter writer = new ExpressionWriter();
        Map<String, List<String>> imports = new HashMap<>();
        CustomSASParserListener listener = new CustomSASParserListener(writer, imports);
        walker.walk(listener, tree);
        ExpressionWriter writer1 = new ExpressionWriter();
        for (Map.Entry<String, List<String>> entry : imports.entrySet()) {
            if (entry.getValue().isEmpty()) {
                writer1.append("import");
                writer1.appendSpace();
                writer1.append(entry.getKey());
            } else {
                writer1.append("from");
                writer1.appendSpace();
                writer1.append(entry.getKey());
                writer1.appendSpace();
                writer1.append("import");
                writer1.appendSpace();
                writer1.append(entry.getValue().get(0));
                for (int i = 1; i < entry.getValue().size(); i++) {
                    writer1.append(", ");
                    writer1.append(entry.getValue().get(i));
                }
            }
            writer1.newlineAndIndent();
        }
        writer1.newlineAndIndent();
        writer1.append(writer);
        System.out.println(writer1);
    }
}
