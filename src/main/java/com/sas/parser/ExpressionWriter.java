package com.sas.parser;

import org.apache.calcite.avatica.util.Spacer;

/**
 * Converts an expression to code.
 */
public class ExpressionWriter {
  public ExpressionWriter() {
  }

  public int getCurrentIndent() {
    return spacer.get();
  }

  @Override
  public String toString() {
    return buf.toString();
  }

  public ExpressionWriter newlineAndIndent() {
    buf.append("\n");
    indentPending = true;
    return getThis();
  }

  public ExpressionWriter newline() {
    buf.append("\n");
    return getThis();
  }

  public ExpressionWriter indent() {
    spacer.spaces(buf);
    return getThis();
  }

  public ExpressionWriter begin(String s) {
    append(s);
    begin();
    indentPending = s.endsWith("\n");
    return getThis();
  }

  public ExpressionWriter end(String s) {
    end();
    append(s);
    indentPending = s.endsWith("\n");
    return getThis();
  }

  /**
   * Increases the indentation level.
   */
  public void begin() {
    spacer.add(INDENT);
  }

  /**
   * Decreases the indentation level.
   */
  public void end() {
    spacer.subtract(INDENT);
  }

  public ExpressionWriter append(char c) {
    checkIndent();
    buf.append(c);
    return getThis();
  }

  public ExpressionWriter appendSpace() {
    buf.append(" ");
    return getThis();
  }

  public ExpressionWriter append(Object o) {
    checkIndent();
    buf.append(o);
    return getThis();
  }

  public ExpressionWriter append(String s) {
    checkIndent();
    buf.append(s);
    return getThis();
  }

  public ExpressionWriter appendSingleQuote() {
    checkIndent();
    buf.append("'");
    return getThis();
  }

  public ExpressionWriter appendSingleQuotes() {
    checkIndent();
    buf.append("'");
    return getThis();
  }

  public ExpressionWriter appendDoubleQuotes() {
    checkIndent();
    buf.append("\"");
    return getThis();
  }

  public ExpressionWriter appendTripleDoubleQuotes() {
    checkIndent();
    buf.append("\"\"\"");
    return getThis();
  }

  public ExpressionWriter appendAssignment() {
    checkIndent();
    buf.append(" = ");
    return getThis();
  }

  public ExpressionWriter appendColonAssignment() {
    checkIndent();
    buf.append(":=");
    return getThis();
  }

  public ExpressionWriter appendDot() {
    checkIndent();
    buf.append(".");
    return getThis();
  }

  public ExpressionWriter startParentheses() {
    checkIndent();
    buf.append("(");
    return getThis();
  }

  public ExpressionWriter closeParentheses() {
    checkIndent();
    buf.append(")");
    return getThis();
  }

  public ExpressionWriter startConicalBrackets() {
    checkIndent();
    buf.append("<");
    return getThis();
  }

  public ExpressionWriter closeConicalBrackets() {
    checkIndent();
    buf.append(">");
    return getThis();
  }

  public ExpressionWriter appendComma() {
    checkIndent();
    buf.append(", ");
    return getThis();
  }

  public ExpressionWriter appendSemiColon() {
    checkIndent();
    buf.append(";");
    return getThis();
  }

  public void removeSemicolon(int idx) {
    if (String.valueOf(buf.charAt(idx)).equals(";")) {
      buf.deleteCharAt(idx);
    }

  }

  public void removeComma(int idx) {
    if (String.valueOf(buf.charAt(idx)).equals(",")) {
      buf.deleteCharAt(idx);
    }

  }

  public void removeSpace(int idx) {
    if (String.valueOf(buf.charAt(idx)).equals(" ")) {
      buf.deleteCharAt(idx);
    }

  }

  public void removeNewline() {
    if (buf.toString().endsWith("\n")) {
      buf.deleteCharAt(buf.length() - 1);
    }

  }

  public void checkIndent() {
    if (indentPending) {
      spacer.spaces(buf);
      indentPending = false;
    }

  }

  public StringBuilder getBuf() {
    checkIndent();
    return buf;
  }

  public void backUp() {
    if (buf.lastIndexOf("\n") == buf.length() - 1) {
      buf.delete(buf.length() - 1, buf.length());
      indentPending = false;
    }

  }

  public void removeIndent() {
    indentPending = false;
  }

  private ExpressionWriter getThis() {
    return this;
  }

  private static final int INDENT = 4;
  private final Spacer spacer = new Spacer(0);
  private final StringBuilder buf = new StringBuilder();
  private boolean indentPending;
}
