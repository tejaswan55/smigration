package com.sas.parser;

import org.antlr.v4.runtime.tree.ParseTree;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class CustomSASParserListener extends SASParserBaseListener {

    private final ExpressionWriter writer;
    private final Map<String, List<String>> imports;
    private final List<String> variables = new ArrayList<>();
    private  boolean putOn = false;
    private  int counter = -1;

    public CustomSASParserListener(ExpressionWriter writer, Map<String, List<String>> imports) {
        this.writer = writer;
        this.imports = imports;
    }

    private void appendImports(String key, String value) {
        if (value == null) {
            imports.put(key, new ArrayList<>());
            return;
        }
        List<String> list = imports.get(key);
        if (list == null) {
            list = new ArrayList<>();
            imports.put(key, list);
        }
        if (list.contains(value)) {
            return;
        }
        list.add(value);
    }

    @Override
    public void enterProgramStatement(SASParser.ProgramStatementContext ctx) {
        System.out.println("Entering macro statement: " + ctx.getText());

    }


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
        String var = ctx.getChild(1).getText().trim();
        String varWithoutAnd = var.replaceFirst("&", "");
        if (variables.contains(varWithoutAnd)) {
            writer.append("print(" +  varWithoutAnd +")").newlineAndIndent();
        } else {
            for (String s : variables) {
                String withAnd = "&"+s;
                String withBrackets = "{"+s+"}";
                var = var.replaceAll(withAnd + "\\.", withBrackets).replace(withAnd + "\\s*", withBrackets);
            }
            writer.append("print(f'" + var +"')").newlineAndIndent();
        }
    }

    @Override
    public void exitPutStatement(SASParser.PutStatementContext ctx) {
        System.out.println("Exiting PUT statement: " + ctx.getText());
    }

    @Override
    public void enterLetStatement(SASParser.LetStatementContext ctx) {
        System.out.println("Entering LET statement: " + ctx.getText());
        appendImports("os", null);
        variables.add(ctx.getChild(1).getText().replaceAll("'", ""));
        writer.append(ctx.getChild(1).getText() + " = ");
        if (ctx.getChild(3).getText().toLowerCase().contains("%sysfunc")) {
            String path = ctx.getChild(3).getChild(0).getChild(2).getChild(0).getChild(0).getChild(2).getText().replace("\"", "");
            for (String s : variables) {
                String withAnd = "&"+s;
                String withBrackets = "{"+s+"}";
                path = path.replaceAll(withAnd + "\\.", withBrackets).replace(withAnd + "\\s*", withBrackets);
            }
            appendImports("pathlib", "Path");
            writer.append("Path(f'" + path + "').exists()").newlineAndIndent();
        } else if (ctx.getChild(3).getText().toLowerCase().contains("%sysget")) {
           writer.append("os.getenv(\"" +
                    ctx.getChild(3).getChild(0).getChild(2).getText() + "\")").newlineAndIndent();
        } else {
            writer.append("'").append(ctx.getChild(3).getText()).append("'").newlineAndIndent();
        }


        //Path("/path/to/file.dat").exists()
    }

    @Override
    public void enterLibraryStatement(SASParser.LibraryStatementContext ctx) {
        System.out.println("Entering LET statement: " + ctx.getText());
        String library = ctx.getChild(1).getText().replaceAll("'", "");
        String var = ctx.getChild(2).getText().replace("\"", "");
        String varWithoutAnd = var.replaceFirst("&", "");
        variables.add(library);
        writer.append(library).appendAssignment();
        if (variables.contains(varWithoutAnd)) {
            writer.append(varWithoutAnd).newlineAndIndent();
        } else {
            for (String s : variables) {
                String withAnd = "&"+s;
                String withBrackets = "{"+s+"}";
                var = var.replaceAll(withAnd + "\\.", withBrackets).replace(withAnd + "\\s*", withBrackets);
            }
            writer.append("f'" + var +"'").newlineAndIndent();
        }
    }

//    @Override
//    public void enterDataStepStatement(SASParser.DataStepStatementContext ctx) {
//        System.out.println("Entering LET statement: " + ctx.getText());
////        writer.append(ctx.getChild(1).getText() + " = os.getenv(\"" +
////                ctx.getChild(3).getChild(0).getChild(2).getText() + "\")").newlineAndIndent();
//    }

//    @Override
//    public void enterDataStepContent(SASParser.DataStepContentContext ctx) {
//        System.out.println("Entering LET statement: " + ctx.getText());
////        writer.append(ctx.getChild(1).getText() + " = os.getenv(\"" +
////                ctx.getChild(3).getChild(0).getChild(2).getText() + "\")").newlineAndIndent();
//    }

@Override
public void enterCallStatement(SASParser.CallStatementContext ctx) {
    System.out.println("Entering LET statement: " + ctx.getText());
//        writer.append(ctx.getChild(1).getText() + " = os.getenv(\"" +
//                ctx.getChild(3).getChild(0).getChild(2).getText() + "\")").newlineAndIndent();
}

    @Override
    public void enterSymputArgs(SASParser.SymputArgsContext ctx) {
        System.out.println("Entering LET statement: " + ctx.getText());
        variables.add(ctx.getChild(0).getText().replaceAll("'", ""));
        writer.append(ctx.getChild(0).getText().replaceAll("'", "")).appendAssignment();
//        writer.append(ctx.getChild(1).getText() + " = os.getenv(\"" +
//                ctx.getChild(3).getChild(0).getChild(2).getText() + "\")").newlineAndIndent();
    }

    @Override
    public void exitSymputArgs(SASParser.SymputArgsContext ctx) {
        System.out.println("Entering LET statement: " + ctx.getText());
        writer.newlineAndIndent();
//        writer.append(ctx.getChild(0).getText().replaceAll("'", "")).appendAssignment();
//        writer.append(ctx.getChild(1).getText() + " = os.getenv(\"" +
//                ctx.getChild(3).getChild(0).getChild(2).getText() + "\")").newlineAndIndent();
    }

    @Override
    public void enterFunctionExpression(SASParser.FunctionExpressionContext ctx) {
        System.out.println("Entering LET statement: " + ctx.getText());
        if (ctx.getChild(0).getChild(0).getText().equalsIgnoreCase("put")) {
            putOn = true;
            appendImports("datetime", "datetime");
            appendImports("datetime", "timedelta");
            String operator = ctx.getChild(0).getChild(2).getChild(0).getChild(0).getChild(1).getText();
            String varName = ctx.getChild(0).getChild(2).getChild(0).getChild(0).getChild(0).getChild(0).getChild(0).getChild(2).getChild(0).getText().replaceAll("\"", "").replaceFirst("&", "").toUpperCase();
            writer.append("datetime.fromtimestamp(int((datetime.fromtimestamp(int(datetime.strptime(" +
                    varName + ", \"%Y%m%d\").timestamp())) "+ operator + " timedelta(days = 1)).timestamp())).strftime(\"%Y%m%d\")");
        }
        if (!putOn && ctx.getChild(0).getChild(0).getText().equalsIgnoreCase("input")) {
            appendImports("datetime", "datetime");
            appendImports("datetime", "timedelta");
            String varName = ctx.getChild(0).getChild(2).getChild(0).getText().replaceAll("\"", "").replaceFirst("&", "").toUpperCase();
            writer.append("int(datetime.strptime(" + varName + ", \"%Y%m%d\").timestamp())");
        }
        if (ctx.getChild(0).getChild(0).getText().equalsIgnoreCase("run")) {
            ctx.getChild(0).getChild(2).getChild(0).getChild(0).getText().replaceAll("\"", "").replaceFirst("&", "").toUpperCase();
        }
//        writer.append(ctx.getChild(1).getText() + " = os.getenv(\"" +
//                ctx.getChild(3).getChild(0).getChild(2).getText() + "\")").newlineAndIndent();
    }

    @Override
    public void exitFunctionExpression(SASParser.FunctionExpressionContext ctx) {
        System.out.println("Entering LET statement: " + ctx.getText());
        if (ctx.getChild(0).getChild(0).getText().equalsIgnoreCase("put")) {
            putOn = false;
        }
    }

    @Override
    public void enterIncludeStatement(SASParser.IncludeStatementContext ctx) {
        System.out.println("Entering LET statement: " + ctx.getText());
        String path = ctx.getChild(1).getText().replaceAll("'", "").replaceAll("\"", "");
        String[] paths = path.split("\\.");
        paths[paths.length - 1] = "PY";
        appendImports("importlib.util", null);
        String[] names = path.split("[\\\\/]");
        String name = names[names.length - 1].split("\\.")[0];
        writer.append(name + "_file_path").appendAssignment().appendSingleQuote().append(String.join(".", paths)).appendSingleQuote().newlineAndIndent();
        variables.add(name + "_file_path");
        variables.add(name + "_spec");
        writer.append(name + "_spec = importlib.util.spec_from_file_location(\"module\", " + name + "_file_path)").newlineAndIndent();
        writer.append(name + " = importlib.util.module_from_spec(" + name + "_spec)").newlineAndIndent();
        writer.append(name + "_spec.loader.exec_module(" + name + ")").newlineAndIndent();
    }

    @Override
    public void enterMacroDefStatement(SASParser.MacroDefStatementContext ctx) {
        System.out.println("Entering LET statement: " + ctx.getText());
        String methodName = ctx.getChild(1).getText().replaceAll("'", "");
        writer.newlineAndIndent();
        writer.append("def ").append(methodName).append("(");
        if (ctx.getChild(2).getText().equalsIgnoreCase(";")) {
            writer.append("):").newlineAndIndent();
            writer.begin();
            return;
        }
        int paramCount = ctx.getChild(3).getChildCount();
        for (int i = 0; i < paramCount; i++) {
            ParseTree tree = ctx.getChild(3).getChild(i);
            if (i%2 == 0) {
                writer.append(tree.getChild(0).getText());
//                if (tree.getChildCount() <= 2) {
//                    writer.append("None");
//                } else {
//                    writer.append(tree.getChild(2).getText());
//                }
            } else {
                if (i != paramCount - 1) {
                    writer.append(tree.getText()).appendSpace();
                }
            }
        }
        writer.append("):").newlineAndIndent();
        writer.begin();
       // writer.append(")").newlineAndIndent();
    }

    @Override
    public void enterMacroCall(SASParser.MacroCallContext ctx) {
        System.out.println("Entering LET statement: " + ctx.getText());
        String methodName = ctx.getChild(1).getText().replaceAll("'", "");
        writer.append(methodName).append("(");
        if (ctx.getChild(2).getText().equalsIgnoreCase(";")) {
            writer.append(")");
            return;
        }
        int paramCount = ctx.getChild(3).getChildCount();
        for (int i = 0; i < paramCount; i++) {
            ParseTree tree = ctx.getChild(3).getChild(i);
            if (i%2 == 0) {
                writer.append(tree.getChild(0).getText()).appendAssignment();
                if (tree.getChildCount() <= 2) {
                    writer.append("None");
                } else {
                    vv(tree.getChild(2).getText());
                }
            } else {
                if (i != paramCount - 1) {
                    writer.append(tree.getText()).appendSpace();
                }
            }
        }
         writer.append(")").newlineAndIndent();
    }

    private void vv(String var) {
        String varWithoutAnd = var.replaceFirst("&", "");
        if (variables.contains(varWithoutAnd)) {
            writer.append(varWithoutAnd);
        } else {
            for (String s : variables) {
                String withAnd = "&"+s;
                String withBrackets = "{"+s+"}";
                var = var.replaceAll(withAnd + "\\.", withBrackets).replace(withAnd + "\\s*", withBrackets);
            }
            writer.append("f'" + var +"'");
        }
    }

    @Override
    public void exitMacroDefStatement(SASParser.MacroDefStatementContext ctx) {
        System.out.println("Entering LET statement: " + ctx.getText());
       writer.newlineAndIndent();
        writer.end();

    }

//    @Override
//    public void exitFunctionExpression(SASParser.FunctionExpressionContext ctx) {
//        System.out.println("Entering LET statement: " + ctx.getText());
//        if (ctx.getChild(0).getChild(0).getText().equalsIgnoreCase("put")) {
//            writer.append(").strftime(\"%Y%m%d\")").newlineAndIndent();
//        }
////        writer.append(ctx.getChild(1).getText() + " = os.getenv(\"" +
////                ctx.getChild(3).getChild(0).getChild(2).getText() + "\")").newlineAndIndent();
//    }

    @Override
    public void enterStandardFunction(SASParser.StandardFunctionContext ctx) {
        System.out.println("Entering LET statement: " + ctx.getText());
//        writer.append(ctx.getChild(1).getText() + " = os.getenv(\"" +
//                ctx.getChild(3).getChild(0).getChild(2).getText() + "\")").newlineAndIndent();
    }

    @Override
    public void enterIfStatement(SASParser.IfStatementContext ctx) {
        System.out.println("Entering LET statement: " + ctx.getText());
        ParseTree conditionTree = ctx.getChild(1);
        Map<String, String> operators = new HashMap<>();
        operators.put("eq", " == ");
        operators.put("=", " == ");
        operators.put("gt", " > ");
        operators.put("lt", " < ");
        operators.put("gte", " >= ");
        operators.put("lte", " <= ");
        writer.append("if ");
        writer.append(conditionTree.getChild(0).getText().replace("&", "").replace(".", ""))
                .append(operators.get(conditionTree.getChild(1).getText().trim()));
        if (!conditionTree.getChild(2).getText().startsWith("&")) {
            writer.append("'" + conditionTree.getChild(2).getText() + "'");
        } else {
            writer.append(conditionTree.getChild(2).getText().replace("&", ""));
        }
        writer.append(":").newlineAndIndent();
        writer.begin();
        appendImports("pyspark.shell", "spark");
        writer.append("file_path = f'{SRC_LANDING}/{in_dataset}-{RUNDATE}.dat'").newlineAndIndent();
        writer.append("df = spark.read.csv(file_path, header=True, inferSchema=True)").newlineAndIndent();
        writer.end();
        writer.append("else:").newlineAndIndent();
        writer.begin();
        writer.append("df = spark.read.format(\"sas7bdat\").load(f\"{INLIB}/{in_dataset}\")").newlineAndIndent();
        writer.end();
       // writer.append("    ").append("df = df.withColumnRenamed(\"ACCT\", \"ACCT_NBR\")").newlineAndIndent();
//        writer.append(ctx.getChild(1).getText() + " = os.getenv(\"" +
//                ctx.getChild(3).getChild(0).getChild(2).getText() + "\")").newlineAndIndent();
    }

    @Override
    public void exitStandardFunction(SASParser.StandardFunctionContext ctx) {
        System.out.println("Entering LET statement: " + ctx.getText());
//        writer.append(ctx.getChild(1).getText() + " = os.getenv(\"" +
//                ctx.getChild(3).getChild(0).getChild(2).getText() + "\")").newlineAndIndent();
    }

    @Override
    public void enterInputFunction(SASParser.InputFunctionContext ctx) {
        System.out.println("Entering LET statement: " + ctx.getText());
//        if (ctx.getChild(0).getText().equalsIgnoreCase("put")) {
//            writer.append("datetime.fromtimestamp(");
//        }
//        writer.append(ctx.getChild(1).getText() + " = os.getenv(\"" +
//                ctx.getChild(3).getChild(0).getChild(2).getText() + "\")").newlineAndIndent();
    }

    @Override
    public void exitInputFunction(SASParser.InputFunctionContext ctx) {
        System.out.println("Entering LET statement: " + ctx.getText());
//        if (ctx.getChild(0).getText().equalsIgnoreCase("put")) {
//            writer.append(").strftime(\"%Y%m%d\")").newlineAndIndent();
//        }
//        writer.append(ctx.getChild(1).getText() + " = os.getenv(\"" +
//                ctx.getChild(3).getChild(0).getChild(2).getText() + "\")").newlineAndIndent();
    }

    @Override
    public void exitLetStatement(SASParser.LetStatementContext ctx) {
        System.out.println("Exiting LET statement: " + ctx.getText());
    }
}
