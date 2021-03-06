// Copyright 2012 Cloudera Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package com.cloudera.impala.analysis;

import com.cloudera.impala.catalog.RowFormat;
import com.cloudera.impala.catalog.PrimitiveType;
import com.cloudera.impala.analysis.UnionStmt.UnionOperand;
import com.cloudera.impala.analysis.UnionStmt.Qualifier;
import com.cloudera.impala.thrift.TDescribeTableOutputStyle;
import com.cloudera.impala.thrift.THdfsFileFormat;
import com.cloudera.impala.thrift.TTablePropertyType;
import java.math.BigInteger;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java_cup.runtime.Symbol;
import com.google.common.collect.Lists;

parser code {:
  private Symbol errorToken;

  // list of expected tokens ids from current parsing state
  // for generating syntax error message
  private final List<Integer> expectedTokenIds = new ArrayList<Integer>();

  // to avoid reporting trivial tokens as expected tokens in error messages
  private boolean reportExpectedToken(Integer tokenId) {
    if (SqlScanner.isKeyword(tokenId) ||
        tokenId.intValue() == SqlParserSymbols.COMMA ||
        tokenId.intValue() == SqlParserSymbols.IDENT) {
      return true;
    } else {
      return false;
    }
  }

  private String getErrorTypeMessage(int lastTokenId) {
    String msg = null;
    switch(lastTokenId) {
      case SqlParserSymbols.UNMATCHED_STRING_LITERAL:
        msg = "Unmatched string literal";
        break;
      case SqlParserSymbols.NUMERIC_OVERFLOW:
        msg = "Numeric overflow";
        break;
      default:
        msg = "Syntax error";
        break;
    }
    return msg;
  }

  // override to save error token
  public void syntax_error(java_cup.runtime.Symbol token) {
    errorToken = token;

    // derive expected tokens from current parsing state
    expectedTokenIds.clear();
    int state = ((Symbol)stack.peek()).parse_state;
    // get row of actions table corresponding to current parsing state
    // the row consists of pairs of <tokenId, actionId>
    // a pair is stored as row[i] (tokenId) and row[i+1] (actionId)
    // the last pair is a special error action
    short[] row = action_tab[state];
    short tokenId;
    // the expected tokens are all the symbols with a
    // corresponding action from the current parsing state
    for (int i = 0; i < row.length-2; ++i) {
      // get tokenId and skip actionId
      tokenId = row[i++];
      expectedTokenIds.add(Integer.valueOf(tokenId));
    }
  }

  // override to keep it from calling report_fatal_error()
  @Override
  public void unrecovered_syntax_error(Symbol cur_token)
      throws Exception {
    throw new Exception(getErrorTypeMessage(cur_token.sym));
  }

  /**
   * Manually throw a parse error on a given symbol for special circumstances.
   *
   * @symbolName
   *   name of symbol on which to fail parsing
   * @symbolId
   *   id of symbol from SqlParserSymbols on which to fail parsing
   */
  public void parseError(String symbolName, int symbolId) throws Exception {
    Symbol errorToken = getSymbolFactory().newSymbol(symbolName, symbolId,
        ((Symbol) stack.peek()), ((Symbol) stack.peek()), null);
    // Call syntax error to gather information about expected tokens, etc.
    // syntax_error does not throw an exception
    syntax_error(errorToken);
    // Unrecovered_syntax_error throws an exception and will terminate parsing
    unrecovered_syntax_error(errorToken);
  }

  // Returns error string, consisting of a shortened offending line
  // with a '^' under the offending token. Assumes
  // that parse() has been called and threw an exception
  public String getErrorMsg(String stmt) {
    if (errorToken == null || stmt == null) return null;
    String[] lines = stmt.split("\n");
    StringBuffer result = new StringBuffer();
    result.append(getErrorTypeMessage(errorToken.sym) + " in line ");
    result.append(errorToken.left);
    result.append(":\n");

    // errorToken.left is the line number of error.
    // errorToken.right is the column number of the error.
    String errorLine = lines[errorToken.left - 1];
    // If the error is that additional tokens are expected past the end, errorToken.right
    // will be past the end of the string.
    int lastCharIndex = Math.min(errorLine.length(), errorToken.right);
    int maxPrintLength = 60;
    int errorLoc = 0;
    if (errorLine.length() <= maxPrintLength) {
      // The line is short. Print the entire line.
      result.append(errorLine);
      result.append('\n');
      errorLoc = errorToken.right;
    } else {
      // The line is too long. Print maxPrintLength/2 characters before the error and
      // after the error.
      int contextLength = maxPrintLength / 2 - 3;
      String leftSubStr;
      if (errorToken.right > maxPrintLength / 2) {
        leftSubStr = "..." + errorLine.substring(errorToken.right - contextLength,
            lastCharIndex);
      } else {
        leftSubStr = errorLine.substring(0, errorToken.right);
      }
      errorLoc = leftSubStr.length();
      result.append(leftSubStr);
      if (errorLine.length() - errorToken.right > maxPrintLength / 2) {
        result.append(errorLine.substring(errorToken.right,
           errorToken.right + contextLength) + "...");
      } else {
        result.append(errorLine.substring(lastCharIndex));
      }
      result.append("\n");
    }

    // print error indicator
    for (int i = 0; i < errorLoc - 1; ++i) {
      result.append(' ');
    }
    result.append("^\n");

    // only report encountered and expected tokens for syntax errors
    if (errorToken.sym == SqlParserSymbols.UNMATCHED_STRING_LITERAL ||
        errorToken.sym == SqlParserSymbols.NUMERIC_OVERFLOW) {
      return result.toString();
    }

    // append last encountered token
    result.append("Encountered: ");
    String lastToken =
      SqlScanner.tokenIdMap.get(Integer.valueOf(errorToken.sym));
    if (lastToken != null) {
      result.append(lastToken);
    } else {
      result.append("Unknown last token with id: " + errorToken.sym);
    }

    // append expected tokens
    result.append('\n');
    result.append("Expected: ");
    String expectedToken = null;
    Integer tokenId = null;
    for (int i = 0; i < expectedTokenIds.size(); ++i) {
      tokenId = expectedTokenIds.get(i);
      if (reportExpectedToken(tokenId)) {
       expectedToken = SqlScanner.tokenIdMap.get(tokenId);
         result.append(expectedToken + ", ");
      }
    }
    // remove trailing ", "
    result.delete(result.length()-2, result.length());
    result.append('\n');

    return result.toString();
  }
:};

// List of keywords. Please keep them sorted alphabetically.
terminal
  KW_ADD, KW_AGGREGATE, KW_ALL, KW_ALTER, KW_AND, KW_AS, KW_ASC, KW_AVG, KW_AVROFILE,
  KW_BETWEEN, KW_BIGINT, KW_BOOLEAN, KW_BY, KW_CASE, KW_CAST, KW_CHANGE, KW_CHAR,
  KW_COLUMN, KW_COLUMNS, KW_COMMENT, KW_COUNT, KW_CREATE, KW_DATA, KW_DATABASE,
  KW_DATABASES, KW_DATE, KW_DATETIME, KW_DELIMITED, KW_DESC, KW_DESCRIBE, KW_DISTINCT,
  KW_DISTINCTPC, KW_DISTINCTPCSA, KW_DIV, KW_DOUBLE, KW_DROP, KW_ELSE, KW_END, KW_ESCAPED,
  KW_EXISTS, KW_EXPLAIN, KW_EXTERNAL, KW_FALSE, KW_FIELDS, KW_FILEFORMAT, KW_FINALIZE_FN,
  KW_FLOAT, KW_FORMAT, KW_FORMATTED, KW_FROM, KW_FULL, KW_FUNCTION, KW_FUNCTIONS,
  KW_GROUP, KW_GROUP_CONCAT, KW_HAVING, KW_IF, KW_IN, KW_INIT_FN, KW_INNER, KW_INPATH,
  KW_INSERT, KW_INT, KW_INTERMEDIATE, KW_INTERVAL, KW_INTO, KW_INVALIDATE, KW_IS,
  KW_JOIN, KW_LEFT, KW_LIKE, KW_LIMIT, KW_LINES, KW_LOAD, KW_LOCATION, KW_MAX,
  KW_MERGE_FN, KW_METADATA, KW_MIN, KW_NOT, KW_NULL, KW_ON, KW_OR, KW_ORDER, KW_OUTER,
  KW_OVERWRITE, KW_PARQUETFILE, KW_PARTITION, KW_PARTITIONED, KW_RCFILE, KW_REFRESH,
  KW_REGEXP, KW_RENAME, KW_REPLACE, KW_RETURNS, KW_RIGHT, KW_RLIKE, KW_ROW, KW_SCHEMA,
  KW_SCHEMAS, KW_SELECT, KW_SEMI, KW_SEQUENCEFILE, KW_SERDEPROPERTIES, KW_SERIALIZE_FN,
  KW_SET, KW_SHOW, KW_SMALLINT, KW_STORED, KW_STRING, KW_SUM, KW_SYMBOL, KW_TABLE,
  KW_TABLES, KW_TBLPROPERTIES, KW_TERMINATED, KW_TEXTFILE, KW_THEN, KW_TIMESTAMP,
  KW_TINYINT, KW_TO, KW_TRUE, KW_UNION, KW_UPDATE_FN, KW_USE, KW_USING, KW_VALUES,
  KW_VIEW, KW_WHEN, KW_WHERE, KW_WITH;

terminal COMMA, DOT, DOTDOTDOT, STAR, LPAREN, RPAREN, LBRACKET, RBRACKET,
  DIVIDE, MOD, ADD, SUBTRACT;
terminal BITAND, BITOR, BITXOR, BITNOT;
terminal EQUAL, NOT, LESSTHAN, GREATERTHAN;
terminal String IDENT;
terminal String NUMERIC_OVERFLOW;
terminal BigInteger INTEGER_LITERAL;
terminal Double FLOATINGPOINT_LITERAL;
terminal String STRING_LITERAL;
terminal String UNMATCHED_STRING_LITERAL;

nonterminal StatementBase stmt;
// Single select statement.
nonterminal SelectStmt select_stmt;
// Single values statement.
nonterminal ValuesStmt values_stmt;
// Select or union statement.
nonterminal QueryStmt query_stmt;
nonterminal QueryStmt optional_query_stmt;
// Single select_stmt or parenthesized query_stmt.
nonterminal QueryStmt union_operand;
// List of select or union blocks connected by UNION operators or a single select block.
nonterminal List<UnionOperand> union_operand_list;
// List of union operands consisting of constant selects.
nonterminal List<UnionOperand> values_operand_list;
// USE stmt
nonterminal UseStmt use_stmt;
nonterminal ShowTablesStmt show_tables_stmt;
nonterminal ShowDbsStmt show_dbs_stmt;
nonterminal String show_pattern;
nonterminal DescribeStmt describe_stmt;
nonterminal TDescribeTableOutputStyle describe_output_style;
nonterminal LoadDataStmt load_stmt;
nonterminal ResetMetadataStmt reset_metadata_stmt;
// List of select blocks connected by UNION operators, with order by or limit.
nonterminal QueryStmt union_with_order_by_or_limit;
nonterminal SelectList select_clause;
nonterminal SelectList select_list;
nonterminal SelectListItem select_list_item;
nonterminal SelectListItem star_expr;
nonterminal Expr expr, non_pred_expr, arithmetic_expr, timestamp_arithmetic_expr;
nonterminal ArrayList<Expr> expr_list;
nonterminal String alias_clause;
nonterminal ArrayList<String> ident_list;
nonterminal ArrayList<String> optional_ident_list;
nonterminal TableName table_name;
nonterminal FunctionName function_name;
nonterminal Expr where_clause;
nonterminal Predicate predicate, between_predicate, comparison_predicate,
  compound_predicate, in_predicate, like_predicate;
nonterminal ArrayList<Expr> group_by_clause;
nonterminal Expr having_clause;
nonterminal ArrayList<OrderByElement> order_by_elements, order_by_clause;
nonterminal OrderByElement order_by_element;
nonterminal Number limit_clause;
nonterminal Expr cast_expr, case_else_clause, aggregate_expr;
nonterminal LiteralExpr literal;
nonterminal CaseExpr case_expr;
nonterminal ArrayList<CaseWhenClause> case_when_clause_list;
nonterminal FunctionParams function_params;
nonterminal BuiltinAggregateFunction.Operator aggregate_operator;
nonterminal SlotRef column_ref;
nonterminal ArrayList<TableRef> from_clause, table_ref_list;
nonterminal ArrayList<ViewRef> with_table_ref_list;
nonterminal WithClause with_clause;
nonterminal TableRef table_ref;
nonterminal BaseTableRef base_table_ref;
nonterminal InlineViewRef inline_view_ref;
nonterminal ViewRef with_table_ref;
nonterminal JoinOperator join_operator;
nonterminal opt_inner, opt_outer;
nonterminal ArrayList<String> opt_join_hints;
nonterminal PrimitiveType primitive_type;
nonterminal Expr sign_chain_expr;
nonterminal InsertStmt insert_stmt;
nonterminal StatementBase explain_stmt;
nonterminal PartitionSpec partition_spec;
nonterminal ArrayList<PartitionKeyValue> partition_clause;
nonterminal ArrayList<PartitionKeyValue> static_partition_key_value_list;
nonterminal ArrayList<PartitionKeyValue> partition_key_value_list;
nonterminal PartitionKeyValue partition_key_value;
nonterminal PartitionKeyValue static_partition_key_value;
nonterminal Qualifier union_op;

nonterminal AlterTableStmt alter_tbl_stmt;
nonterminal StatementBase alter_view_stmt;
nonterminal DropDbStmt drop_db_stmt;
nonterminal DropTableOrViewStmt drop_tbl_or_view_stmt;
nonterminal CreateDbStmt create_db_stmt;
nonterminal CreateTableAsSelectStmt create_tbl_as_select_stmt;
nonterminal CreateTableLikeStmt create_tbl_like_stmt;
nonterminal CreateTableStmt create_tbl_stmt;
nonterminal CreateViewStmt create_view_stmt;
nonterminal ColumnDesc column_def, view_column_def;
nonterminal ArrayList<ColumnDesc> column_def_list, view_column_def_list;
nonterminal ArrayList<ColumnDesc> partition_column_defs, view_column_defs;
// Options for DDL commands - CREATE/DROP/ALTER
nonterminal String comment_val;
nonterminal Boolean external_val;
nonterminal THdfsFileFormat file_format_val;
nonterminal THdfsFileFormat file_format_create_table_val;
nonterminal Boolean if_exists_val;
nonterminal Boolean if_not_exists_val;
nonterminal Boolean replace_existing_cols_val;
nonterminal HdfsURI location_val;
nonterminal RowFormat row_format_val;
nonterminal String field_terminator_val;
nonterminal String line_terminator_val;
nonterminal String escaped_by_val;
nonterminal String terminator_val;
nonterminal TTablePropertyType table_property_type;
nonterminal HashMap serde_properties;
nonterminal HashMap tbl_properties;
nonterminal HashMap properties_map;
// Used to simplify commands that accept either KW_DATABASE(S) or KW_SCHEMA(S)
nonterminal String db_or_schema_kw;
nonterminal String dbs_or_schemas_kw;
// Used to simplify commands where KW_COLUMN is optional
nonterminal String optional_kw_column;
// Used to simplify commands where KW_TABLE is optional
nonterminal String optional_kw_table;
nonterminal Boolean overwrite_val;

// For Create/Drop/Show function ddl
nonterminal FunctionArgs function_def_args;
nonterminal FunctionArgs function_def_arg_list;
nonterminal Boolean opt_is_aggregate_fn;
nonterminal Boolean opt_is_varargs;
nonterminal ColumnType opt_aggregate_fn_intermediate_type;
nonterminal CreateUdfStmt create_udf_stmt;
nonterminal CreateUdaStmt create_uda_stmt;
nonterminal ShowFunctionsStmt show_functions_stmt;
nonterminal DropFunctionStmt drop_function_stmt;
nonterminal ColumnType aggregate_intermediate_type;
// Accepts space separated key='v' arguments.
nonterminal HashMap create_function_args_map;
nonterminal CreateFunctionStmtBase.OptArg create_function_arg_key;

precedence left KW_OR;
precedence left KW_AND;
precedence left KW_NOT, NOT;
precedence left KW_BETWEEN, KW_IN, KW_IS;
precedence left KW_LIKE, KW_RLIKE, KW_REGEXP;
precedence left EQUAL, LESSTHAN, GREATERTHAN;
precedence left ADD, SUBTRACT;
precedence left STAR, DIVIDE, MOD, KW_DIV;
precedence left BITAND, BITOR, BITXOR, BITNOT;
precedence left KW_ORDER, KW_BY, KW_LIMIT;
precedence left LPAREN, RPAREN;
// Support chaining of timestamp arithmetic exprs.
precedence left KW_INTERVAL;

// These tokens need to be at the end for create_function_args_map to accept
// no keys. Otherwise, the grammar has shift/reduce conflicts.
precedence left KW_COMMENT;
precedence left KW_SYMBOL;
precedence left KW_UPDATE_FN;
precedence left KW_FINALIZE_FN;
precedence left KW_INIT_FN;
precedence left KW_MERGE_FN;
precedence left KW_SERIALIZE_FN;

start with stmt;

stmt ::=
  query_stmt:query
  {: RESULT = query; :}
  | insert_stmt:insert
  {: RESULT = insert; :}
  | use_stmt:use
  {: RESULT = use; :}
  | show_tables_stmt:show_tables
  {: RESULT = show_tables; :}
  | show_dbs_stmt:show_dbs
  {: RESULT = show_dbs; :}
  | show_functions_stmt:show_functions
  {: RESULT = show_functions; :}
  | describe_stmt:describe
  {: RESULT = describe; :}
  | alter_tbl_stmt:alter_tbl
  {: RESULT = alter_tbl; :}
  | alter_view_stmt:alter_view
  {: RESULT = alter_view; :}
  | create_tbl_as_select_stmt:create_tbl_as_select
  {: RESULT = create_tbl_as_select; :}
  | create_tbl_like_stmt:create_tbl_like
  {: RESULT = create_tbl_like; :}
  | create_tbl_stmt:create_tbl
  {: RESULT = create_tbl; :}
  | create_view_stmt:create_view
  {: RESULT = create_view; :}
  | create_db_stmt:create_db
  {: RESULT = create_db; :}
  | create_udf_stmt:create_udf
  {: RESULT = create_udf; :}
  | create_uda_stmt:create_uda
  {: RESULT = create_uda; :}
  | drop_db_stmt:drop_db
  {: RESULT = drop_db; :}
  | drop_tbl_or_view_stmt:drop_tbl
  {: RESULT = drop_tbl; :}
  | drop_function_stmt:drop_function
  {: RESULT = drop_function; :}
  | explain_stmt: explain
  {: RESULT = explain; :}
  | load_stmt: load
  {: RESULT = load; :}
  | reset_metadata_stmt: reset_metadata
  {: RESULT = reset_metadata; :}
  ;

load_stmt ::=
  KW_LOAD KW_DATA KW_INPATH STRING_LITERAL:path overwrite_val:overwrite KW_INTO KW_TABLE
  table_name:table partition_spec:partition
  {: RESULT = new LoadDataStmt(table, new HdfsURI(path), overwrite, partition); :}
  ;

overwrite_val ::=
  KW_OVERWRITE
  {: RESULT = Boolean.TRUE; :}
  | /* empty */
  {: RESULT = Boolean.FALSE; :}
  ;

reset_metadata_stmt ::=
  KW_INVALIDATE KW_METADATA
  {: RESULT = new ResetMetadataStmt(null, false); :}
  | KW_INVALIDATE KW_METADATA table_name:table
  {: RESULT = new ResetMetadataStmt(table, false); :}
  | KW_REFRESH table_name:table
  {: RESULT = new ResetMetadataStmt(table, true); :}
  ;

explain_stmt ::=
  KW_EXPLAIN query_stmt:query
  {:
     query.setIsExplain(true);
     RESULT = query;
  :}
  | KW_EXPLAIN insert_stmt:insert
  {:
     insert.setIsExplain(true);
     RESULT = insert;
  :}
  ;

// Insert statements have two optional clauses: the column permutation (INSERT into
// tbl(col1,...) etc) and the PARTITION clause. If the column permutation is present, the
// query statement clause is optional as well.
insert_stmt ::=
  with_clause:w KW_INSERT KW_OVERWRITE optional_kw_table table_name:table LPAREN
  optional_ident_list:col_perm RPAREN partition_clause:list optional_query_stmt:query
  {: RESULT = new InsertStmt(w, table, true, list, query, col_perm); :}
  | with_clause:w KW_INSERT KW_OVERWRITE optional_kw_table table_name:table
  partition_clause:list query_stmt:query
  {: RESULT = new InsertStmt(w, table, true, list, query, null); :}
  | with_clause:w KW_INSERT KW_INTO optional_kw_table table_name:table LPAREN
  optional_ident_list:col_perm RPAREN partition_clause:list optional_query_stmt:query
  {: RESULT = new InsertStmt(w, table, false, list, query, col_perm); :}
  | with_clause:w KW_INSERT KW_INTO optional_kw_table table_name:table
  partition_clause:list query_stmt:query
  {: RESULT = new InsertStmt(w, table, false, list, query, null); :}
  ;

optional_query_stmt ::=
  query_stmt:query
  {: RESULT = query; :}
  | /* empty */
  {: RESULT = null; :}
  ;

optional_ident_list ::=
  ident_list:ident
  {: RESULT = ident; :}
  | /* empty */
  {: RESULT = Lists.newArrayList(); :}
  ;

optional_kw_table ::=
  KW_TABLE
  | /* empty */
  ;

alter_tbl_stmt ::=
  KW_ALTER KW_TABLE table_name:table replace_existing_cols_val:replace KW_COLUMNS
  LPAREN column_def_list:col_defs RPAREN
  {: RESULT = new AlterTableAddReplaceColsStmt(table, col_defs, replace); :}
  | KW_ALTER KW_TABLE table_name:table KW_ADD if_not_exists_val:if_not_exists
    partition_spec:partition location_val:location
  {:
    RESULT = new AlterTableAddPartitionStmt(table, partition,
        location, if_not_exists);
  :}
  | KW_ALTER KW_TABLE table_name:table KW_DROP optional_kw_column IDENT:col_name
  {: RESULT = new AlterTableDropColStmt(table, col_name); :}
  | KW_ALTER KW_TABLE table_name:table KW_CHANGE optional_kw_column IDENT:col_name
    column_def:col_def
  {: RESULT = new AlterTableChangeColStmt(table, col_name, col_def); :}
  | KW_ALTER KW_TABLE table_name:table KW_DROP if_exists_val:if_exists
    partition_spec:partition
  {: RESULT = new AlterTableDropPartitionStmt(table, partition, if_exists); :}
  | KW_ALTER KW_TABLE table_name:table partition_spec:partition KW_SET KW_FILEFORMAT
    file_format_val:file_format
  {: RESULT = new AlterTableSetFileFormatStmt(table, partition, file_format); :}
  | KW_ALTER KW_TABLE table_name:table partition_spec:partition KW_SET
    KW_LOCATION STRING_LITERAL:location
  {: RESULT = new AlterTableSetLocationStmt(table, partition, new HdfsURI(location)); :}
  | KW_ALTER KW_TABLE table_name:table KW_RENAME KW_TO table_name:new_table
  {: RESULT = new AlterTableOrViewRenameStmt(table, new_table, true); :}
  | KW_ALTER KW_TABLE table_name:table partition_spec:partition KW_SET
    table_property_type:target LPAREN properties_map:properties RPAREN
  {:
    // Include unnecessary partition_spec to avoid a shift/reduce conflict on KW_SET.
    if (partition != null) {
      parser.parseError("partition", SqlParserSymbols.KW_PARTITION);
    }
    RESULT = new AlterTableSetTblProperties(table, target, properties);
  :}
  ;

table_property_type ::=
  KW_TBLPROPERTIES
  {: RESULT = TTablePropertyType.TBL_PROPERTY; :}
  | KW_SERDEPROPERTIES
  {: RESULT = TTablePropertyType.SERDE_PROPERTY; :}
  ;

optional_kw_column ::=
  KW_COLUMN
  | /* empty */
  ;

replace_existing_cols_val ::=
  KW_REPLACE
  {: RESULT = true; :}
  | KW_ADD
  {: RESULT = false; :}
  ;

create_db_stmt ::=
  KW_CREATE db_or_schema_kw if_not_exists_val:if_not_exists IDENT:db_name
  comment_val:comment location_val:location
  {: RESULT = new CreateDbStmt(db_name, comment, location, if_not_exists); :}
  ;

create_tbl_like_stmt ::=
  KW_CREATE external_val:external KW_TABLE if_not_exists_val:if_not_exists
  table_name:table KW_LIKE table_name:other_table comment_val:comment
  KW_STORED KW_AS file_format_val:file_format location_val:location
  {:
    RESULT = new CreateTableLikeStmt(table, other_table, external, comment,
        file_format, location, if_not_exists);
  :}
  | KW_CREATE external_val:external KW_TABLE if_not_exists_val:if_not_exists
    table_name:table KW_LIKE table_name:other_table comment_val:comment
    location_val:location
  {:
    RESULT = new CreateTableLikeStmt(table, other_table, external, comment,
        null, location, if_not_exists);
  :}
  ;

create_tbl_as_select_stmt ::=
  KW_CREATE external_val:external KW_TABLE if_not_exists_val:if_not_exists
  table_name:table comment_val:comment row_format_val:row_format
  serde_properties:serde_props file_format_create_table_val:file_format
  location_val:location tbl_properties:tbl_props
  KW_AS query_stmt:query
  {:
    // Initialize with empty List of columns and partition columns. The
    // columns will be added from the query statement during analysis
    CreateTableStmt create_stmt = new CreateTableStmt(table, new ArrayList<ColumnDesc>(),
        new ArrayList<ColumnDesc>(), external, comment, row_format,
        file_format, location, if_not_exists, tbl_props, serde_props);
    RESULT = new CreateTableAsSelectStmt(create_stmt, query);
  :}
  ;

create_tbl_stmt ::=
  KW_CREATE external_val:external KW_TABLE if_not_exists_val:if_not_exists
  table_name:table LPAREN column_def_list:col_defs RPAREN
  partition_column_defs:partition_col_defs comment_val:comment
  row_format_val:row_format serde_properties:serde_props
  file_format_create_table_val:file_format location_val:location tbl_properties:tbl_props
  {:
    RESULT = new CreateTableStmt(table, col_defs, partition_col_defs, external, comment,
        row_format, file_format, location, if_not_exists, tbl_props, serde_props);
  :}
  ;

create_udf_stmt ::=
  KW_CREATE KW_FUNCTION if_not_exists_val:if_not_exists
  function_name:fn_name function_def_args:fn_args
  KW_RETURNS primitive_type:return_type
  KW_LOCATION STRING_LITERAL:binary_path
  create_function_args_map:arg_map
  {:
    RESULT = new CreateUdfStmt(fn_name, fn_args, return_type, new HdfsURI(binary_path),
        if_not_exists, arg_map);
  :}
  ;

create_uda_stmt ::=
  KW_CREATE KW_AGGREGATE KW_FUNCTION if_not_exists_val:if_not_exists
  function_name:fn_name function_def_args:fn_args
  KW_RETURNS primitive_type:return_type
  opt_aggregate_fn_intermediate_type:intermediate_type
  KW_LOCATION STRING_LITERAL:binary_path
  create_function_args_map:arg_map
  {:
    RESULT = new CreateUdaStmt(fn_name, fn_args, return_type, intermediate_type,
        new HdfsURI(binary_path), if_not_exists, arg_map);
  :}
  ;

comment_val ::=
  KW_COMMENT STRING_LITERAL:comment
  {: RESULT = comment; :}
  | /* empty */
  {: RESULT = null; :}
  ;

location_val ::=
  KW_LOCATION STRING_LITERAL:location
  {: RESULT = new HdfsURI(location); :}
  | /* empty */
  {: RESULT = null; :}
  ;

external_val ::=
  KW_EXTERNAL
  {: RESULT = true; :}
  |
  {: RESULT = false; :}
  ;

if_not_exists_val ::=
  KW_IF KW_NOT KW_EXISTS
  {: RESULT = true; :}
  |
  {: RESULT = false; :}
  ;

row_format_val ::=
  KW_ROW KW_FORMAT KW_DELIMITED field_terminator_val:field_terminator
  escaped_by_val:escaped_by line_terminator_val:line_terminator
  {: RESULT = new RowFormat(field_terminator, line_terminator, escaped_by); :}
  |/* empty */
  {: RESULT = RowFormat.DEFAULT_ROW_FORMAT; :}
  ;

escaped_by_val ::=
  KW_ESCAPED KW_BY STRING_LITERAL:escaped_by
  {: RESULT = escaped_by; :}
  | /* empty */
  {: RESULT = null; :}
  ;

line_terminator_val ::=
  KW_LINES terminator_val:line_terminator
  {: RESULT = line_terminator; :}
  | /* empty */
  {: RESULT = null; :}
  ;

field_terminator_val ::=
  KW_FIELDS terminator_val:field_terminator
  {: RESULT = field_terminator; :}
  | /* empty */
  {: RESULT = null; :}
  ;

terminator_val ::=
  KW_TERMINATED KW_BY STRING_LITERAL:terminator
  {: RESULT = terminator; :}
  ;

file_format_create_table_val ::=
  KW_STORED KW_AS file_format_val:file_format
  {: RESULT = file_format; :}
  | /* empty - default to TEXT */
  {: RESULT = THdfsFileFormat.TEXT; :}
  ;

file_format_val ::=
  KW_PARQUETFILE
  {: RESULT = THdfsFileFormat.PARQUET; :}
  | KW_TEXTFILE
  {: RESULT = THdfsFileFormat.TEXT; :}
  | KW_SEQUENCEFILE
  {: RESULT = THdfsFileFormat.SEQUENCE_FILE; :}
  | KW_RCFILE
  {: RESULT = THdfsFileFormat.RC_FILE; :}
  | KW_AVROFILE
  {: RESULT = THdfsFileFormat.AVRO; :}
  ;

tbl_properties ::=
  KW_TBLPROPERTIES LPAREN properties_map:map RPAREN
  {: RESULT = map; :}
  | /* empty */
  {: RESULT = null; :}
  ;

serde_properties ::=
  KW_WITH KW_SERDEPROPERTIES LPAREN properties_map:map RPAREN
  {: RESULT = map; :}
  | /* empty */
  {: RESULT = null; :}
  ;

properties_map ::=
  STRING_LITERAL:key EQUAL STRING_LITERAL:value
  {:
    HashMap<String, String> properties = new HashMap<String, String>();
    properties.put(key, value);
    RESULT = properties;
  :}
  | properties_map:properties COMMA STRING_LITERAL:key EQUAL STRING_LITERAL:value
  {:
    properties.put(key, value);
    RESULT = properties;
  :}
  ;

partition_column_defs ::=
  KW_PARTITIONED KW_BY LPAREN column_def_list:col_defs RPAREN
  {: RESULT = col_defs; :}
  | /* Empty - not a partitioned table */
  {: RESULT = new ArrayList<ColumnDesc>(); :}
  ;

column_def_list ::=
  column_def:col_def
  {:
    ArrayList<ColumnDesc> list = new ArrayList<ColumnDesc>();
    list.add(col_def);
    RESULT = list;
  :}
  | column_def_list:list COMMA column_def:col_def
  {:
    list.add(col_def);
    RESULT = list;
  :}
  ;

column_def ::=
  IDENT:col_name primitive_type:targetType comment_val:comment
  {: RESULT = new ColumnDesc(col_name, targetType, comment); :}
  ;

create_view_stmt ::=
  KW_CREATE KW_VIEW if_not_exists_val:if_not_exists table_name:view_name
  view_column_defs:col_defs comment_val:comment KW_AS query_stmt:view_def
  {:
    RESULT = new CreateViewStmt(if_not_exists, view_name, col_defs, comment, view_def);
  :}
  ;

view_column_defs ::=
  LPAREN view_column_def_list:view_col_defs RPAREN
  {: RESULT = view_col_defs; :}
  | /* empty */
  {: RESULT = null; :}
  ;

view_column_def_list ::=
  view_column_def:col_def
  {:
    ArrayList<ColumnDesc> list = new ArrayList<ColumnDesc>();
    list.add(col_def);
    RESULT = list;
  :}
  | view_column_def_list:list COMMA view_column_def:col_def
  {:
    list.add(col_def);
    RESULT = list;
  :}
  ;

view_column_def ::=
  IDENT:col_name comment_val:comment
  {: RESULT = new ColumnDesc(col_name, null, comment); :}
  ;

alter_view_stmt ::=
  KW_ALTER KW_VIEW table_name:table KW_AS query_stmt:view_def
  {: RESULT = new AlterViewStmt(table, view_def); :}
  | KW_ALTER KW_VIEW table_name:before_table KW_RENAME KW_TO table_name:new_table
  {: RESULT = new AlterTableOrViewRenameStmt(before_table, new_table, false); :}
  ;

drop_db_stmt ::=
  KW_DROP db_or_schema_kw if_exists_val:if_exists IDENT:db_name
  {: RESULT = new DropDbStmt(db_name, if_exists); :}
  ;

drop_tbl_or_view_stmt ::=
  KW_DROP KW_TABLE if_exists_val:if_exists table_name:table
  {: RESULT = new DropTableOrViewStmt(table, if_exists, true); :}
  | KW_DROP KW_VIEW if_exists_val:if_exists table_name:table
  {: RESULT = new DropTableOrViewStmt(table, if_exists, false); :}
  ;

drop_function_stmt ::=
  KW_DROP opt_is_aggregate_fn:is_aggregate KW_FUNCTION
      if_exists_val:if_exists function_name:fn_name
  function_def_args:fn_args
  {: RESULT = new DropFunctionStmt(fn_name, fn_args, if_exists); :}
  ;

db_or_schema_kw ::=
  KW_DATABASE
  | KW_SCHEMA
  ;

dbs_or_schemas_kw ::=
  KW_DATABASES
  | KW_SCHEMAS
  ;

if_exists_val ::=
  KW_IF KW_EXISTS
  {: RESULT = true; :}
  |
  {: RESULT = false; :}
  ;

partition_clause ::=
  KW_PARTITION LPAREN partition_key_value_list:list RPAREN
  {: RESULT = list; :}
  |
  {: RESULT = null; :}
  ;

partition_key_value_list ::=
  partition_key_value:item
  {:
    ArrayList<PartitionKeyValue> list = new ArrayList<PartitionKeyValue>();
    list.add(item);
    RESULT = list;
  :}
  | partition_key_value_list:list COMMA partition_key_value:item
  {:
    list.add(item);
    RESULT = list;
  :}
  ;

// A partition spec is a set of static partition key/value pairs. This is a bit
// different than a partition clause in an INSERT statement because that allows
// for dynamic and static partition key/values.
partition_spec ::=
  KW_PARTITION LPAREN static_partition_key_value_list:list RPAREN
  {: RESULT = new PartitionSpec(list); :}
  | /* Empty */
  {: RESULT = null; :}
  ;

static_partition_key_value_list ::=
  static_partition_key_value:item
  {:
    ArrayList<PartitionKeyValue> list = new ArrayList<PartitionKeyValue>();
    list.add(item);
    RESULT = list;
  :}
  | static_partition_key_value_list:list COMMA static_partition_key_value:item
  {:
    list.add(item);
    RESULT = list;
  :}
  ;

partition_key_value ::=
  // Dynamic partition key values.
  IDENT:column
  {: RESULT = new PartitionKeyValue(column, null); :}
  | static_partition_key_value:partition
  {: RESULT = partition; :}
  ;

static_partition_key_value ::=
  // Static partition key values.
  IDENT:column EQUAL expr:e
  {: RESULT = new PartitionKeyValue(column, e); :}
  ;

function_def_args ::=
  LPAREN RPAREN
  {: RESULT = new FunctionArgs(); :}
  | LPAREN function_def_arg_list:args opt_is_varargs:var_args RPAREN
  {:
    args.setHasVarArgs(var_args);
    RESULT = args;
  :}
  ;

function_def_arg_list ::=
  primitive_type:type
  {:
    FunctionArgs args = new FunctionArgs();
    args.argTypes.add(type);
    RESULT = args;
  :}
  | function_def_arg_list:args COMMA primitive_type:type
  {:
    args.argTypes.add(type);
    RESULT = args;
  :}
  ;

opt_is_aggregate_fn ::=
  KW_AGGREGATE
  {: RESULT = true; :}
  |
  {: RESULT = false; :}
  ;

opt_is_varargs ::=
  DOTDOTDOT
  {: RESULT = true; :}
  |
  {: RESULT = false; :}
  ;

// TODO: remove this when the char(n) type is supported everywhere.
aggregate_intermediate_type ::=
  primitive_type:type
  {: RESULT = ColumnType.createType(type); :}
  | KW_CHAR LPAREN INTEGER_LITERAL:len RPAREN
  {: RESULT = ColumnType.createCharType(len.intValue()); :}
  ;

opt_aggregate_fn_intermediate_type ::=
  KW_INTERMEDIATE aggregate_intermediate_type:type
  {: RESULT = type; :}
  |
  {: RESULT = null; :}
  ;

create_function_args_map ::=
  create_function_arg_key:key EQUAL STRING_LITERAL:value
  {:
    HashMap<CreateFunctionStmtBase.OptArg, String> args =
        new HashMap<CreateFunctionStmtBase.OptArg, String>();
    args.put(key, value);
    RESULT = args;
  :}
  | create_function_args_map:args create_function_arg_key:key EQUAL STRING_LITERAL:value
  {:
    if (args.containsKey(key)) throw new Exception("Duplicate argument key: " + key);
    args.put(key, value);
    RESULT = args;
  :}
  |
  {: RESULT = new HashMap<CreateFunctionStmtBase.OptArg, String>(); :}
  ;

// Any keys added here must also be added to the end of the precedence list.
create_function_arg_key ::=
  KW_COMMENT
  {: RESULT = CreateFunctionStmtBase.OptArg.COMMENT; :}
  | KW_SYMBOL
  {: RESULT = CreateFunctionStmtBase.OptArg.SYMBOL; :}
  | KW_UPDATE_FN
  {: RESULT = CreateFunctionStmtBase.OptArg.UPDATE_FN; :}
  | KW_INIT_FN
  {: RESULT = CreateFunctionStmtBase.OptArg.INIT_FN; :}
  | KW_SERIALIZE_FN
  {: RESULT = CreateFunctionStmtBase.OptArg.SERIALIZE_FN; :}
  | KW_MERGE_FN
  {: RESULT = CreateFunctionStmtBase.OptArg.MERGE_FN; :}
  | KW_FINALIZE_FN
  {: RESULT = CreateFunctionStmtBase.OptArg.FINALIZE_FN; :}
  ;

// Our parsing of UNION is slightly different from MySQL's:
// http://dev.mysql.com/doc/refman/5.5/en/union.html
//
// Imo, MySQL's parsing of union is not very clear.
// For example, MySQL cannot parse this query:
// select 3 order by 1 limit 1 union all select 1;
//
// On the other hand, MySQL does parse this query, but associates
// the order by and limit with the union, not the select:
// select 3 as g union all select 1 order by 1 limit 2;
//
// MySQL also allows some combinations of select blocks
// with and without parenthesis, but also disallows others.
//
// Our parsing:
// Select blocks may or may not be in parenthesis,
// even if the union has order by and limit.
// ORDER BY and LIMIT bind to the preceding select statement by default.
query_stmt ::=
  with_clause:w union_operand_list:operands
  {:
    QueryStmt queryStmt = null;
    if (operands.size() == 1) {
      queryStmt = operands.get(0).getQueryStmt();
    } else {
      queryStmt = new UnionStmt(operands, null, -1);
    }
    queryStmt.setWithClause(w);
    RESULT = queryStmt;
  :}
  | with_clause:w union_with_order_by_or_limit:union
  {:
    union.setWithClause(w);
    RESULT = union;
  :}
  ;

with_clause ::=
  KW_WITH with_table_ref_list:list
  {: RESULT = new WithClause(list); :}
  | /* empty */
  {: RESULT = null; :}
  ;

with_table_ref ::=
  IDENT:alias KW_AS LPAREN query_stmt:query RPAREN
  {: RESULT = new ViewRef(alias, query); :}
  | STRING_LITERAL:alias KW_AS LPAREN query_stmt:query RPAREN
  {: RESULT = new ViewRef(alias, query); :}
  ;

with_table_ref_list ::=
  with_table_ref:t
  {:
    ArrayList<ViewRef> list = new ArrayList<ViewRef>();
    list.add(t);
    RESULT = list;
  :}
  | with_table_ref_list:list COMMA with_table_ref:t
  {:
    list.add(t);
    RESULT = list;
  :}
  ;

// We must have a non-empty order by or limit for them to bind to the union.
// We cannot reuse the existing order_by_clause or
// limit_clause because they would introduce conflicts with EOF,
// which, unfortunately, cannot be accessed in the parser as a nonterminal
// making this issue unresolvable.
// We rely on the left precedence of KW_ORDER, KW_BY, and KW_LIMIT,
// to resolve the ambiguity with select_stmt in favor of select_stmt
// (i.e., ORDER BY and LIMIT bind to the select_stmt by default, and not the union).
// There must be at least two union operands for ORDER BY or LIMIT to bind to a union,
// and we manually throw a parse error if we reach this production
// with only a single operand.
union_with_order_by_or_limit ::=
    union_operand_list:operands
    KW_ORDER KW_BY order_by_elements:orderByClause
  {:
    if (operands.size() == 1) {
      parser.parseError("order", SqlParserSymbols.KW_ORDER);
    }
    RESULT = new UnionStmt(operands, orderByClause, -1);
  :}
  |
    union_operand_list:operands
    KW_LIMIT INTEGER_LITERAL:limitClause
  {:
    if (operands.size() == 1) {
      parser.parseError("limit", SqlParserSymbols.KW_LIMIT);
    }
    RESULT = new UnionStmt(operands, null, limitClause.longValue());
  :}
  |
    union_operand_list:operands
    KW_ORDER KW_BY order_by_elements:orderByClause
    KW_LIMIT INTEGER_LITERAL:limitClause
  {:
    if (operands.size() == 1) {
      parser.parseError("order", SqlParserSymbols.KW_ORDER);
    }
    RESULT = new UnionStmt(operands, orderByClause, limitClause.longValue());
  :}
  ;

union_operand ::=
  select_stmt:select
  {: RESULT = select; :}
  | values_stmt:values
  {: RESULT = values; :}
  | LPAREN query_stmt:query RPAREN
  {: RESULT = query; :}
  ;

union_operand_list ::=
  union_operand:operand
  {:
    List<UnionOperand> operands = new ArrayList<UnionOperand>();
    operands.add(new UnionOperand(operand, null));
    RESULT = operands;
  :}
  | union_operand_list:operands union_op:op union_operand:operand
  {:
    operands.add(new UnionOperand(operand, op));
    RESULT = operands;
  :}
  ;

union_op ::=
  KW_UNION
  {: RESULT = Qualifier.DISTINCT; :}
  | KW_UNION KW_DISTINCT
  {: RESULT = Qualifier.DISTINCT; :}
  | KW_UNION KW_ALL
  {: RESULT = Qualifier.ALL; :}
  ;

values_stmt ::=
  KW_VALUES values_operand_list:operands
  order_by_clause:orderByClause
  limit_clause:limitClause
  {:
    RESULT = new ValuesStmt(operands, orderByClause,
                            (limitClause == null ? -1 : limitClause.longValue()));
  :}
  | KW_VALUES LPAREN values_operand_list:operands RPAREN
    order_by_clause:orderByClause
    limit_clause:limitClause
  {:
    RESULT = new ValuesStmt(operands, orderByClause,
                            (limitClause == null ? -1 : limitClause.longValue()));
  :}
  ;

values_operand_list ::=
  LPAREN select_list:selectList RPAREN
  {:
    List<UnionOperand> operands = new ArrayList<UnionOperand>();
    operands.add(new UnionOperand(
        new SelectStmt(selectList, null, null, null, null, null, -1), null));
    RESULT = operands;
  :}
  | values_operand_list:operands COMMA LPAREN select_list:selectList RPAREN
  {:
    operands.add(new UnionOperand(
        new SelectStmt(selectList, null, null, null, null, null, -1), Qualifier.ALL));
    RESULT = operands;
  :}
  ;

use_stmt ::=
  KW_USE IDENT:db
  {: RESULT = new UseStmt(db); :}
  ;

show_tables_stmt ::=
  KW_SHOW KW_TABLES
  {: RESULT = new ShowTablesStmt(); :}
  | KW_SHOW KW_TABLES show_pattern:showPattern
  {: RESULT = new ShowTablesStmt(showPattern); :}
  | KW_SHOW KW_TABLES KW_IN IDENT:db
  {: RESULT = new ShowTablesStmt(db, null); :}
  | KW_SHOW KW_TABLES KW_IN IDENT:db show_pattern:showPattern
  {: RESULT = new ShowTablesStmt(db, showPattern); :}
  ;

show_dbs_stmt ::=
  KW_SHOW dbs_or_schemas_kw
  {: RESULT = new ShowDbsStmt(); :}
  | KW_SHOW dbs_or_schemas_kw show_pattern:showPattern
  {: RESULT = new ShowDbsStmt(showPattern); :}
  ;

show_functions_stmt ::=
  KW_SHOW opt_is_aggregate_fn:is_aggregate KW_FUNCTIONS
  {: RESULT = new ShowFunctionsStmt(null, null, is_aggregate); :}
  | KW_SHOW opt_is_aggregate_fn:is_aggregate KW_FUNCTIONS show_pattern:showPattern
  {: RESULT = new ShowFunctionsStmt(null, showPattern, is_aggregate); :}
  | KW_SHOW opt_is_aggregate_fn:is_aggregate KW_FUNCTIONS KW_IN IDENT:db
  {: RESULT = new ShowFunctionsStmt(db, null, is_aggregate); :}
  | KW_SHOW opt_is_aggregate_fn:is_aggregate KW_FUNCTIONS KW_IN IDENT:db
      show_pattern:showPattern
  {: RESULT = new ShowFunctionsStmt(db, showPattern, is_aggregate); :}
  ;

show_pattern ::=
  STRING_LITERAL:showPattern
  {: RESULT = showPattern; :}
  | KW_LIKE STRING_LITERAL:showPattern
  {: RESULT = showPattern; :}
  ;

describe_stmt ::=
  KW_DESCRIBE describe_output_style:style table_name:table
  {: RESULT = new DescribeStmt(table, style); :}
  ;

describe_output_style ::=
  KW_FORMATTED
  {: RESULT = TDescribeTableOutputStyle.FORMATTED; :}
  | /* empty */
  {: RESULT = TDescribeTableOutputStyle.MINIMAL; :}
  ;

select_stmt ::=
    select_clause:selectList
  {:
    RESULT = new SelectStmt(selectList, null, null, null, null, null, -1);
  :}
  |
    select_clause:selectList
    from_clause:tableRefList
    where_clause:wherePredicate
    group_by_clause:groupingExprs
    having_clause:havingPredicate
    order_by_clause:orderByClause
    limit_clause:limitClause
  {:
    RESULT = new SelectStmt(selectList, tableRefList, wherePredicate,
                            groupingExprs, havingPredicate, orderByClause,
                            (limitClause == null ? -1 : limitClause.longValue()));
  :}
  ;

select_clause ::=
  KW_SELECT select_list:l
  {: RESULT = l; :}
  | KW_SELECT KW_ALL select_list:l
  {: RESULT = l; :}
  | KW_SELECT KW_DISTINCT select_list:l
  {:
    l.setIsDistinct(true);
    RESULT = l;
  :}
  ;

select_list ::=
  select_list_item:item
  {:
    SelectList list = new SelectList();
    list.getItems().add(item);
    RESULT = list;
  :}
  | select_list:list COMMA select_list_item:item
  {:
    list.getItems().add(item);
    RESULT = list;
  :}
  ;

select_list_item ::=
  expr:expr alias_clause:alias
  {: RESULT = new SelectListItem(expr, alias); :}
  | expr:expr
  {: RESULT = new SelectListItem(expr, null); :}
  | star_expr:expr
  {: RESULT = expr; :}
  ;

alias_clause ::=
  KW_AS IDENT:ident
  {: RESULT = ident; :}
  | IDENT:ident
  {: RESULT = ident; :}
  | KW_AS STRING_LITERAL:l
  {: RESULT = l; :}
  | STRING_LITERAL:l
  {: RESULT = l; :}
  ;

star_expr ::=
  STAR
  // table_name DOT STAR doesn't work because of a reduce-reduce conflict
  // on IDENT [DOT]
  {: RESULT = SelectListItem.createStarItem(null); :}
  | IDENT:tbl DOT STAR
  {: RESULT = SelectListItem.createStarItem(new TableName(null, tbl)); :}
  | IDENT:db DOT IDENT:tbl DOT STAR
  {: RESULT = SelectListItem.createStarItem(new TableName(db, tbl)); :}
  ;

table_name ::=
  IDENT:tbl
  {: RESULT = new TableName(null, tbl); :}
  | IDENT:db DOT IDENT:tbl
  {: RESULT = new TableName(db, tbl); :}
  ;

function_name ::=
  IDENT:fn
  {: RESULT = new FunctionName(null, fn); :}
  | IDENT:db DOT IDENT:fn
  {: RESULT = new FunctionName(db, fn); :}
  ;

from_clause ::=
  KW_FROM table_ref_list:l
  {: RESULT = l; :}
  ;

table_ref_list ::=
  table_ref:t
  {:
    ArrayList<TableRef> list = new ArrayList<TableRef>();
    list.add(t);
    RESULT = list;
  :}
  | table_ref_list:list COMMA table_ref:t
  {:
    list.add(t);
    RESULT = list;
  :}
  | table_ref_list:list join_operator:op opt_join_hints:h table_ref:t
  {:
    t.setJoinOp((JoinOperator) op);
    t.setJoinHints(h);
    list.add(t);
    RESULT = list;
  :}
  | table_ref_list:list join_operator:op opt_join_hints:h table_ref:t
    KW_ON expr:e
  {:
    t.setJoinOp((JoinOperator) op);
    t.setJoinHints(h);
    t.setOnClause(e);
    list.add(t);
    RESULT = list;
  :}
  | table_ref_list:list join_operator:op opt_join_hints:h table_ref:t
    KW_USING LPAREN ident_list:colNames RPAREN
  {:
    t.setJoinOp((JoinOperator) op);
    t.setJoinHints(h);
    t.setUsingClause(colNames);
    list.add(t);
    RESULT = list;
  :}
  ;

table_ref ::=
  base_table_ref:b
  {: RESULT = b; :}
  | inline_view_ref:s
  {: RESULT = s; :}
  ;

inline_view_ref ::=
  LPAREN query_stmt:query RPAREN alias_clause:alias
  {: RESULT = new InlineViewRef(alias, query); :}
  ;

base_table_ref ::=
  table_name:name alias_clause:alias
  {: RESULT = new BaseTableRef(name, alias); :}
  | table_name:name
  {: RESULT = new BaseTableRef(name, null); :}
  ;

join_operator ::=
  opt_inner KW_JOIN
  {: RESULT = JoinOperator.INNER_JOIN; :}
  | KW_LEFT opt_outer KW_JOIN
  {: RESULT = JoinOperator.LEFT_OUTER_JOIN; :}
  | KW_RIGHT opt_outer KW_JOIN
  {: RESULT = JoinOperator.RIGHT_OUTER_JOIN; :}
  | KW_FULL opt_outer KW_JOIN
  {: RESULT = JoinOperator.FULL_OUTER_JOIN; :}
  | KW_LEFT KW_SEMI KW_JOIN
  {: RESULT = JoinOperator.LEFT_SEMI_JOIN; :}
  ;

opt_inner ::=
  KW_INNER
  |
  ;

opt_outer ::=
  KW_OUTER
  |
  ;

opt_join_hints ::=
  LBRACKET ident_list:l RBRACKET
  {: RESULT = l; :}
  |
  {: RESULT = null; :}
  ;

ident_list ::=
  IDENT:ident
  {:
    ArrayList<String> list = new ArrayList<String>();
    list.add(ident);
    RESULT = list;
  :}
  | ident_list:list COMMA IDENT:ident
  {:
    list.add(ident);
    RESULT = list;
  :}
  ;

expr_list ::=
  expr:e
  {:
    ArrayList<Expr> list = new ArrayList<Expr>();
    list.add(e);
    RESULT = list;
  :}
  | expr_list:list COMMA expr:e
  {:
    list.add(e);
    RESULT = list;
  :}
  ;

where_clause ::=
  KW_WHERE expr:e
  {: RESULT = e; :}
  | /* empty */
  {: RESULT = null; :}
  ;

group_by_clause ::=
  KW_GROUP KW_BY expr_list:l
  {: RESULT = l; :}
  | /* empty */
  {: RESULT = null; :}
  ;

having_clause ::=
  KW_HAVING expr:e
  {: RESULT = e; :}
  | /* empty */
  {: RESULT = null; :}
  ;

order_by_clause ::=
  KW_ORDER KW_BY order_by_elements:l
  {: RESULT = l; :}
  | /* empty */
  {: RESULT = null; :}
  ;

order_by_elements ::=
  order_by_element:e
  {:
    ArrayList<OrderByElement> list = new ArrayList<OrderByElement>();
    list.add(e);
    RESULT = list;
  :}
  | order_by_elements:list COMMA order_by_element:e
  {:
    list.add(e);
    RESULT = list;
  :}
  ;

order_by_element ::=
  expr:e
  {: RESULT = new OrderByElement(e, true); :}
  | expr:e KW_ASC
  {: RESULT = new OrderByElement(e, true); :}
  | expr:e KW_DESC
  {: RESULT = new OrderByElement(e, false); :}
  ;

limit_clause ::=
  KW_LIMIT INTEGER_LITERAL:l
  {: RESULT = l; :}
  | /* empty */
  {: RESULT = null; :}
  ;

cast_expr ::=
  KW_CAST LPAREN expr:e KW_AS primitive_type:targetType RPAREN
  {: RESULT = new CastExpr((PrimitiveType) targetType, e, false); :}
  ;

case_expr ::=
  KW_CASE expr:caseExpr
    case_when_clause_list:whenClauseList
    case_else_clause:elseExpr
    KW_END
  {: RESULT = new CaseExpr(caseExpr, whenClauseList, elseExpr); :}
  | KW_CASE
    case_when_clause_list:whenClauseList
    case_else_clause:elseExpr
    KW_END
  {: RESULT = new CaseExpr(null, whenClauseList, elseExpr); :}
  ;

case_when_clause_list ::=
  KW_WHEN expr:whenExpr KW_THEN expr:thenExpr
  {:
    ArrayList<CaseWhenClause> list = new ArrayList<CaseWhenClause>();
    list.add(new CaseWhenClause(whenExpr, thenExpr));
    RESULT = list;
  :}
  | case_when_clause_list:list KW_WHEN expr:whenExpr
    KW_THEN expr:thenExpr
  {:
    list.add(new CaseWhenClause(whenExpr, thenExpr));
    RESULT = list;
  :}
  ;

case_else_clause ::=
  KW_ELSE expr:e
  {: RESULT = e; :}
  | /* emtpy */
  {: RESULT = null; :}
  ;

sign_chain_expr ::=
  SUBTRACT expr:e
  {:
    // integrate signs into literals
    // integer literals require analysis to set their type, so the instance check below
    // is not equivalent to e.getType().isNumericType()
    if (e.isLiteral() &&
       (e instanceof IntLiteral || e instanceof FloatLiteral)) {
      ((LiteralExpr)e).swapSign();
      RESULT = e;
    } else {
      RESULT = new ArithmeticExpr(ArithmeticExpr.Operator.MULTIPLY,
                                  new IntLiteral(BigInteger.valueOf(-1)), e);
    }
  :}
  | ADD expr:e
  {: RESULT = e; :}
  ;

expr ::=
  non_pred_expr:e
  {: RESULT = e; :}
  | predicate:p
  {: RESULT = p; :}
  ;

non_pred_expr ::=
  sign_chain_expr:e
  {: RESULT = e; :}
  | literal:l
  {: RESULT = l; :}
  | function_name:fn_name LPAREN RPAREN
  {: RESULT = new FunctionCallExpr(fn_name, new ArrayList<Expr>()); :}
  | function_name:fn_name LPAREN function_params:params RPAREN
  {: RESULT = new FunctionCallExpr(fn_name, params); :}
  /* Since "IF" is a keyword, need to special case this function */
  | KW_IF LPAREN expr_list:exprs RPAREN
  {: RESULT = new FunctionCallExpr("if", exprs); :}
  | cast_expr:c
  {: RESULT = c; :}
  | case_expr:c
  {: RESULT = c; :}
  | aggregate_expr:a
  {: RESULT = a; :}
  | column_ref:c
  {: RESULT = c; :}
  | timestamp_arithmetic_expr:e
  {: RESULT = e; :}
  | arithmetic_expr:e
  {: RESULT = e; :}
  | LPAREN non_pred_expr:e RPAREN
  {:
    e.setPrintSqlInParens(true);
    RESULT = e;
  :}
  ;

arithmetic_expr ::=
  expr:e1 STAR expr:e2
  {: RESULT = new ArithmeticExpr(ArithmeticExpr.Operator.MULTIPLY, e1, e2); :}
  | expr:e1 DIVIDE expr:e2
  {: RESULT = new ArithmeticExpr(ArithmeticExpr.Operator.DIVIDE, e1, e2); :}
  | expr:e1 MOD expr:e2
  {: RESULT = new ArithmeticExpr(ArithmeticExpr.Operator.MOD, e1, e2); :}
  | expr:e1 KW_DIV expr:e2
  {: RESULT = new ArithmeticExpr(ArithmeticExpr.Operator.INT_DIVIDE, e1, e2); :}
  | expr:e1 ADD expr:e2
  {: RESULT = new ArithmeticExpr(ArithmeticExpr.Operator.ADD, e1, e2); :}
  | expr:e1 SUBTRACT expr:e2
  {: RESULT = new ArithmeticExpr(ArithmeticExpr.Operator.SUBTRACT, e1, e2); :}
  | expr:e1 BITAND expr:e2
  {: RESULT = new ArithmeticExpr(ArithmeticExpr.Operator.BITAND, e1, e2); :}
  | expr:e1 BITOR expr:e2
  {: RESULT = new ArithmeticExpr(ArithmeticExpr.Operator.BITOR, e1, e2); :}
  | expr:e1 BITXOR expr:e2
  {: RESULT = new ArithmeticExpr(ArithmeticExpr.Operator.BITXOR, e1, e2); :}
  | BITNOT expr:e
  {: RESULT = new ArithmeticExpr(ArithmeticExpr.Operator.BITNOT, e, null); :}
  ;

// We use IDENT for the temporal unit to avoid making DAY, YEAR, etc. keywords.
// This way we do not need to change existing uses of IDENT.
// We chose not to make DATE_ADD and DATE_SUB keywords for the same reason.
timestamp_arithmetic_expr ::=
  KW_INTERVAL expr:v IDENT:u ADD expr:t
  {: RESULT = new TimestampArithmeticExpr(ArithmeticExpr.Operator.ADD, t, v, u, true); :}
  | expr:t ADD KW_INTERVAL expr:v IDENT:u
  {:
    RESULT = new TimestampArithmeticExpr(ArithmeticExpr.Operator.ADD, t, v, u, false);
  :}
  // Set precedence to KW_INTERVAL (which is higher than ADD) for chaining.
  %prec KW_INTERVAL
  | expr:t SUBTRACT KW_INTERVAL expr:v IDENT:u
  {:
    RESULT =
        new TimestampArithmeticExpr(ArithmeticExpr.Operator.SUBTRACT, t, v, u, false);
  :}
  // Set precedence to KW_INTERVAL (which is higher than ADD) for chaining.
  %prec KW_INTERVAL
  // Timestamp arithmetic expr that looks like a function call.
  // We use func_arg_list instead of expr to avoid a shift/reduce conflict with
  // func_arg_list on COMMA, and report an error if the list contains more than one expr.
  // Although we don't want to accept function names as the expr, we can't parse it
  // it as just an IDENT due to the precedence conflict with function_name.
  | function_name:functionName LPAREN expr_list:l COMMA
    KW_INTERVAL expr:v IDENT:u RPAREN
  {:
    if (l.size() > 1) {
      // Report parsing failure on keyword interval.
      parser.parseError("interval", SqlParserSymbols.KW_INTERVAL);
    }
    if (functionName.getDb() != null) {
      // This function should not fully qualified
      throw new Exception("interval should not be qualified by database name");
    }
    RESULT = new TimestampArithmeticExpr(functionName.getFunction(), l.get(0), v, u);
  :}
  ;

literal ::=
  INTEGER_LITERAL:l
  {: RESULT = new IntLiteral(l); :}
  | FLOATINGPOINT_LITERAL:l
  {: RESULT = new FloatLiteral(l); :}
  | STRING_LITERAL:l
  {: RESULT = new StringLiteral(l); :}
  | KW_TRUE
  {: RESULT = new BoolLiteral(true); :}
  | KW_FALSE
  {: RESULT = new BoolLiteral(false); :}
  | KW_NULL
  {: RESULT = new NullLiteral(); :}
  | UNMATCHED_STRING_LITERAL:l expr:e
  {:
    // we have an unmatched string literal.
    // to correctly report the root cause of this syntax error
    // we must force parsing to fail at this point,
    // and generate an unmatched string literal symbol
    // to be passed as the last seen token in the
    // error handling routine (otherwise some other token could be reported)
    parser.parseError("literal", SqlParserSymbols.UNMATCHED_STRING_LITERAL);
  :}
  | NUMERIC_OVERFLOW:l
  {:
    // similar to the unmatched string literal case
    // we must terminate parsing at this point
    // and generate a corresponding symbol to be reported
    parser.parseError("literal", SqlParserSymbols.NUMERIC_OVERFLOW);
  :}
  ;

aggregate_expr ::=
  aggregate_operator:op LPAREN function_params:params RPAREN
  {:
    RESULT = new FunctionCallExpr(op, params);
  :}
  ;

aggregate_operator ::=
  KW_COUNT
  {: RESULT = BuiltinAggregateFunction.Operator.COUNT; :}
  | KW_MIN
  {: RESULT = BuiltinAggregateFunction.Operator.MIN; :}
  | KW_MAX
  {: RESULT = BuiltinAggregateFunction.Operator.MAX; :}
  | KW_DISTINCTPC
  {: RESULT = BuiltinAggregateFunction.Operator.DISTINCT_PC; :}
  | KW_DISTINCTPCSA
  {: RESULT = BuiltinAggregateFunction.Operator.DISTINCT_PCSA; :}
  | KW_SUM
  {: RESULT = BuiltinAggregateFunction.Operator.SUM; :}
  | KW_AVG
  {: RESULT = BuiltinAggregateFunction.Operator.AVG; :}
  | KW_GROUP_CONCAT
  {: RESULT = BuiltinAggregateFunction.Operator.GROUP_CONCAT; :}
  ;

function_params ::=
  STAR
  {: RESULT = FunctionParams.createStarParam(); :}
  | KW_ALL STAR
  {: RESULT = FunctionParams.createStarParam(); :}
  | expr_list:exprs
  {: RESULT = new FunctionParams(false, exprs); :}
  | KW_ALL expr_list:exprs
  {: RESULT = new FunctionParams(false, exprs); :}
  | KW_DISTINCT:distinct expr_list:exprs
  {: RESULT = new FunctionParams(true, exprs); :}
  ;

predicate ::=
  expr:e KW_IS KW_NULL
  {: RESULT = new IsNullPredicate(e, false); :}
  | expr:e KW_IS KW_NOT KW_NULL
  {: RESULT = new IsNullPredicate(e, true); :}
  | between_predicate:p
  {: RESULT = p; :}
  | comparison_predicate:p
  {: RESULT = p; :}
  | compound_predicate:p
  {: RESULT = p; :}
  | in_predicate:p
  {: RESULT = p; :}
  | like_predicate:p
  {: RESULT = p; :}
  | LPAREN predicate:p RPAREN
  {:
    p.setPrintSqlInParens(true);
    RESULT = p;
  :}
  ;

comparison_predicate ::=
  expr:e1 EQUAL:op expr:e2
  {: RESULT = new BinaryPredicate(BinaryPredicate.Operator.EQ, e1, e2); :}
  | expr:e1 NOT EQUAL:op expr:e2
  {: RESULT = new BinaryPredicate(BinaryPredicate.Operator.NE, e1, e2); :}
  | expr:e1 LESSTHAN GREATERTHAN:op expr:e2
  {: RESULT = new BinaryPredicate(BinaryPredicate.Operator.NE, e1, e2); :}
  | expr:e1 LESSTHAN EQUAL:op expr:e2
  {: RESULT = new BinaryPredicate(BinaryPredicate.Operator.LE, e1, e2); :}
  | expr:e1 GREATERTHAN EQUAL:op expr:e2
  {: RESULT = new BinaryPredicate(BinaryPredicate.Operator.GE, e1, e2); :}
  | expr:e1 LESSTHAN:op expr:e2
  {: RESULT = new BinaryPredicate(BinaryPredicate.Operator.LT, e1, e2); :}
  | expr:e1 GREATERTHAN:op expr:e2
  {: RESULT = new BinaryPredicate(BinaryPredicate.Operator.GT, e1, e2); :}
  ;

like_predicate ::=
  expr:e1 KW_LIKE expr:e2
  {: RESULT = new LikePredicate(LikePredicate.Operator.LIKE, e1, e2); :}
  | expr:e1 KW_RLIKE expr:e2
  {: RESULT = new LikePredicate(LikePredicate.Operator.RLIKE, e1, e2); :}
  | expr:e1 KW_REGEXP expr:e2
  {: RESULT = new LikePredicate(LikePredicate.Operator.REGEXP, e1, e2); :}
  | expr:e1 KW_NOT KW_LIKE expr:e2
  {: RESULT = new CompoundPredicate(CompoundPredicate.Operator.NOT,
    new LikePredicate(LikePredicate.Operator.LIKE, e1, e2), null); :}
  | expr:e1 KW_NOT KW_RLIKE expr:e2
  {: RESULT = new CompoundPredicate(CompoundPredicate.Operator.NOT,
    new LikePredicate(LikePredicate.Operator.RLIKE, e1, e2), null); :}
  | expr:e1 KW_NOT KW_REGEXP expr:e2
  {: RESULT = new CompoundPredicate(CompoundPredicate.Operator.NOT,
    new LikePredicate(LikePredicate.Operator.REGEXP, e1, e2), null); :}
  ;

// Avoid a reduce/reduce conflict with compound_predicate by explicitly
// using non_pred_expr and predicate separately instead of expr.
between_predicate ::=
  expr:e1 KW_BETWEEN non_pred_expr:e2 KW_AND expr:e3
  {: RESULT = new BetweenPredicate(e1, e2, e3, false); :}
  | expr:e1 KW_BETWEEN predicate:e2 KW_AND expr:e3
  {: RESULT = new BetweenPredicate(e1, e2, e3, false); :}
  | expr:e1 KW_NOT KW_BETWEEN non_pred_expr:e2 KW_AND expr:e3
  {: RESULT = new BetweenPredicate(e1, e2, e3, true); :}
  | expr:e1 KW_NOT KW_BETWEEN predicate:e2 KW_AND expr:e3
  {: RESULT = new BetweenPredicate(e1, e2, e3, true); :}
  ;

in_predicate ::=
  expr:e KW_IN LPAREN expr_list:l RPAREN
  {: RESULT = new InPredicate(e, l, false); :}
  | expr:e KW_NOT KW_IN LPAREN expr_list:l RPAREN
  {: RESULT = new InPredicate(e, l, true); :}
  ;

compound_predicate ::=
  expr:e1 KW_AND expr:e2
  {: RESULT = new CompoundPredicate(CompoundPredicate.Operator.AND, e1, e2); :}
  | expr:e1 KW_OR expr:e2
  {: RESULT = new CompoundPredicate(CompoundPredicate.Operator.OR, e1, e2); :}
  | KW_NOT expr:e
  {: RESULT = new CompoundPredicate(CompoundPredicate.Operator.NOT, e, null); :}
  | NOT expr:e
  {: RESULT = new CompoundPredicate(CompoundPredicate.Operator.NOT, e, null); :}
  ;

column_ref ::=
  IDENT:col
  {: RESULT = new SlotRef(null, col); :}
  // table_name:tblName DOT IDENT:col causes reduce/reduce conflicts
  | IDENT:tbl DOT IDENT:col
  {: RESULT = new SlotRef(new TableName(null, tbl), col); :}
  | IDENT:db DOT IDENT:tbl DOT IDENT:col
  {: RESULT = new SlotRef(new TableName(db, tbl), col); :}
  ;

primitive_type ::=
  KW_TINYINT
  {: RESULT = PrimitiveType.TINYINT; :}
  | KW_SMALLINT
  {: RESULT = PrimitiveType.SMALLINT; :}
  | KW_INT
  {: RESULT = PrimitiveType.INT; :}
  | KW_BIGINT
  {: RESULT = PrimitiveType.BIGINT; :}
  | KW_BOOLEAN
  {: RESULT = PrimitiveType.BOOLEAN; :}
  | KW_FLOAT
  {: RESULT = PrimitiveType.FLOAT; :}
  | KW_DOUBLE
  {: RESULT = PrimitiveType.DOUBLE; :}
  | KW_DATE
  {: RESULT = PrimitiveType.DATE; :}
  | KW_DATETIME
  {: RESULT = PrimitiveType.DATETIME; :}
  | KW_TIMESTAMP
  {: RESULT = PrimitiveType.TIMESTAMP; :}
  | KW_STRING
  {: RESULT = PrimitiveType.STRING; :}
  ;
