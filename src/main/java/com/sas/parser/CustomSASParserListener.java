package com.sas.parser;

public class CustomSASParserListener extends SASParserBaseListener {

    @Override
    public void enterMacroStatement(SASParser.MacroStatementContext ctx) {
        System.out.println("Entering macro statement: " + ctx.getText());
    }

    @Override
    public void exitMacroStatement(SASParser.MacroStatementContext ctx) {
        System.out.println("Exiting macro statement: " + ctx.getText());
    }

    @Override
    public void enterAssignment(SASParser.AssignmentContext ctx) {
        System.out.println("Entering assignment: " + ctx.getText());
    }

    @Override
    public void exitAssignment(SASParser.AssignmentContext ctx) {
        System.out.println("Exiting assignment: " + ctx.getText());
    }

    @Override
    public void enterPutStatement(SASParser.PutStatementContext ctx) {
        System.out.println("Entering PUT statement: " + ctx.getText());
    }

    @Override
    public void exitPutStatement(SASParser.PutStatementContext ctx) {
        System.out.println("Exiting PUT statement: " + ctx.getText());
    }

    @Override
    public void enterLetStatement(SASParser.LetStatementContext ctx) {
        System.out.println("Entering LET statement: " + ctx.getText());
    }

    @Override
    public void exitLetStatement(SASParser.LetStatementContext ctx) {
        System.out.println("Exiting LET statement: " + ctx.getText());
    }
}
