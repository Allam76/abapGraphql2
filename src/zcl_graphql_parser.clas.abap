class ZCL_GRAPHQL_PARSER definition
  public
  final
  inheriting from zcl_graphql_tokenizer
  create public .

public section.
 types ty_reftab type table of ref to data with default key.
 types token_tab type table of ref to zcl_graphql_token with key table_line.
 class-methods class_constructor.
 class-methods travserse importing node type ref to zcl_graphql_token
                             parent type ref to zcl_graphql_token optional
                             handler type ref to zcl_graphql_cds_handler
                             data type ref to data optional
                   returning value(result) type ref to data.

 methods match importing type type string returning value(return) type abap_bool.
 methods eat importing type type string returning value(return) type zcl_graphql_tokenizer=>ty_token.
 methods expect importing type type string returning value(return) type zcl_graphql_tokenizer=>ty_token.
 methods expect_or importing types type stringtab returning value(return) type zcl_graphql_tokenizer=>ty_token.
 methods parseQuery returning value(return) type token_tab.
 methods parseIdentifier returning value(return) type string.
 methods parseFieldList returning value(return) type zcl_graphql_token=>ty_token_tab.
 methods parseField returning value(return) type ref to zcl_graphql_token.
 methods parseArgumentList returning value(return) type zcl_graphql_token=>ty_token_tab.
 methods parseArgument returning value(return) type ref to zcl_graphql_token.
 methods parseValue returning value(return) type ref to zcl_graphql_token.
 methods parseReference returning value(return) type ref to zcl_graphql_token.
 methods parseVariable returning value(return) type ref to zcl_graphql_token.

 methods to_ref importing input type any returning value(return) type ref to data.
 methods to_ref_tab importing input type any table returning value(return) type ty_reftab.
protected section.
private section.
ENDCLASS.



CLASS ZCL_GRAPHQL_PARSER IMPLEMENTATION.


 method class_constructor.
 endmethod.


 method eat.
  if me->match( type ).
    return = me->lex( ).
  else.
  endif.
 endmethod.


 method expect.
    if me->match( type ).
      return = me->lex( ).
    else.

     data(lo_err) = me->create_unexpected( me->lookahead ).
     raise exception lo_err.
    endif.
 endmethod.

  method expect_or.
    loop at types into data(type).
     if me->match( type ).
      return = me->lex( ).
      return.
     endif.
    endloop.

    if return is initial.
     data(lo_err) = me->create_unexpected( me->lookahead ).
     raise exception lo_err.
    endif.
 endmethod.


 method match.
   return = xsdbool( me->lookahead-type = type ).
 endmethod.


 method parseargument.
    data data_ref type ref to data.

    if me->match( 'FRAGMENTTYPE' ).
      data(token) = me->eat( 'FRAGMENTTYPE' ).
      return = new zcl_graphql_token( type = 'FragmentRef' name = replace( val = token-value sub = '...' with = '' ) ).
    else.
      data(name) = me->parseIdentifier( ).
      me->expect( 'COLON' ).

      create data data_ref type ref to zcl_graphql_token.
      assign data_ref->* to field-symbol(<ref>).

      <ref> = me->parseValue( ).

      return = new zcl_graphql_token( type = 'Argument' name = name value = data_ref ).
    endif.
 endmethod.


 method parseargumentlist.
    data(first) = abap_true.

    me->expect( 'LPAREN' ).

    while not me->match( 'RPAREN' ) and  not me->end( ).
      if first = abap_true.
        first = abap_false.
      else.
        me->expect( 'COMMA' ).
      endif.

      append me->parseArgument( ) to return.
    endwhile.

    me->expect( 'RPAREN' ).
 endmethod.


 method parsefield.
    if me->match( 'FRAGMENTTYPE' ).
      data(token) = me->eat( 'FRAGMENTTYPE' ).
      return = new zcl_graphql_token( type = 'FragmentRef' name = replace( val = token-value sub = '...' with = '' ) ).
    else.
      data(name) = me->parseIdentifier( ).
      data(arguments) = cond #( when me->match( 'LPAREN' ) then me->parseArgumentList( ) ).
      data(alias) = cond #( when me->eat( 'AS' ) then me->parseIdentifier( ) ).
      data(fields) = cond #( when me->match( 'LBRACE' ) then me->parseFieldList( ) ).
      return = new zcl_graphql_token( type = 'Field' name = name alias = alias arguments = arguments fields = fields ).
    endif.
 endmethod.


 method parsefieldlist.
    me->expect( 'LBRACE' ).

    data fields type zcl_graphql_token=>ty_token_tab.
    data(first) = abap_true.

    while not me->match( 'RBRACE' ) and  not me->end( ).
      if first = abap_true.
        first = abap_false.
      else.
        me->eat( 'COMMA' ).
      endif.

      if me->match('AMP' ).
        append me->parseReference( ) to fields.
      else.
        append me->parseField( ) to fields.
      endif.
    endwhile.

    me->expect( 'RBRACE' ).
    return = fields.
 endmethod.


 method parseidentifier.
   data(value) = me->expect( 'IDENTIFIER' )-value.
   if value = '__schema'.
     return = '__Schema'.
   else.
     return = value.
   endif.
 endmethod.


 method parsequery.
  while me->pos < strlen( me->source ).
    if me->match( 'QUERY' ).
     me->expect( 'QUERY' ).
     data(name) = me->parseidentifier( ).
     data(arguments) = cond #( when me->match( 'LPAREN' ) then me->parseArgumentList( ) ).
     data(fields) = cond #( when me->match( 'LBRACE' ) then me->parseFieldList( ) ).

     append new zcl_graphql_token( type = 'Query' name = name arguments = arguments fields =  fields ) to return.
    elseif me->match( 'FRAGMENT' ).
     me->expect( 'FRAGMENT' ).
     name = me->parseidentifier( ).
     me->expect( 'ON' ).
     data(on_type) = me->parseidentifier( ).
     append new zcl_graphql_token( type = 'Fragment' name = name on_type = on_type fields =  me->parseFieldList( ) ) to return.
    else.
     append new zcl_graphql_token( type = 'Query' fields =  me->parseFieldList( ) ) to return.
    endif.

  endwhile.
 endmethod.


 method parsereference.
    me->expect( 'AMP' ).

    if me->match( 'NUMBER' ) or me->match( 'IDENTIFIER' ).
      return = new zcl_graphql_token( type = 'Reference' name = me->lex( )-value ).
    endif.

    if return is initial.
      data(lo_err) = me->create_unexpected( me->lookahead ).
      raise exception lo_err.
    endif.
 endmethod.


 method parsevalue.
    data value_ref type ref to data.
    field-symbols <val> type string.

    case me->lookahead-type.
      when 'AMP'.
        return = me->parseReference( ).

      when 'LT'.
        return = me->parseVariable( ).

      when 'NUMBER' or 'STRING'.
        create data value_ref type string.
        assign value_ref->* to <val>.
        <val> = replace( val = me->lex( )-value sub = '"' with = '' occ = 0 ).

        return = new zcl_graphql_token( type = 'Literal' value = value_ref ).

      when 'NULL' or 'TRUE' or 'FALSE'.
        create data value_ref type string.
        assign value_ref->* to <val>.
        <val> = me->lex( )-value.
        return = new zcl_graphql_token( type = 'Literal' value = value_ref ).
      when 'IDENTIFIER'.
        create data value_ref type string.
        assign value_ref->* to <val>.
        <val> = me->lex( )-value.
        return = new zcl_graphql_token( type = 'Identifier' value = value_ref ).
    endcase.

    if return is initial.
      data(lo_err) = me->create_unexpected( me->lookahead ).
      raise exception lo_err.
    endif.
 endmethod.


 method parsevariable.
    me->expect( 'LT' ).
    data(name) = me->expect( 'IDENTIFIER' )-value.
    me->expect( 'GT' ).

    return = new zcl_graphql_token( type = 'Variable' name = name ).
 endmethod.


 method to_ref.
*  return = ref ty_data( input ).
 endmethod.


 method to_ref_tab.
  loop at input assigning field-symbol(<item>).
*   append ref ty_data( <item> ) to return.
  endloop.
 endmethod.


 method travserse.
  data name type string.

  case node->type.
    when 'Query'.
     name = 'QUERY'.
    when 'Field'.
     name = 'FIELD'.
    when ''.
  endcase.

  call method handler->(name)
  exporting node = node
            parent_node = parent
            data = data
  receiving result = result.
 endmethod.
ENDCLASS.
