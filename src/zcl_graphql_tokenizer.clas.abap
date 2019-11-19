class ZCL_GRAPHQL_TOKENIZER definition
  public
  create public .

public section.

  types:
    begin of ty_tokentype,
          short type string,
          klass type string,
          name type string,
        end of ty_tokentype .
  types:
    ty_tokens_type_tab type table of ty_tokentype with key short .
  types:
    begin of ty_match_type,
          name type string,
          regex type string,
        end of ty_match_type .
  types:
    ty_match_type_tab type table of ty_match_type with key name .
  types:
    begin of ty_token,
           type type string,
           name type string,
           klass type string,
           value type string,
           line type i,
           column type i,
           fields type stringtab,
         end of ty_token .

  class-data PUNCTUATORS type TY_TOKENS_TYPE_TAB .
  class-data KEYWORDS type TY_TOKENS_TYPE_TAB .
  class-data MATCHES type TY_MATCH_TYPE_TAB .
  data SOURCE type STRING .
  data COLUMN type I .
  data POS type I .
  data LINE type I .
  data LINE_START type I .
  data LOOKAHEAD type TY_TOKEN .
  data PREV type TY_TOKEN .

  class-methods CLASS_CONSTRUCTOR .
  methods CONSTRUCTOR
    importing
      !SOURCE type STRING .
  methods GET_COLUMN
    returning
      value(RETURN) type I .
  methods GET_KEYWORD
    importing
      !NAME type STRING
    returning
      value(RETURN) type STRING .
  methods END
    returning
      value(RETURN) type STRING .
  methods PEEK
    returning
      value(RETURN) type STRING .
  methods LEX
    returning
      value(RETURN) type TY_TOKEN .
  methods NEXT
    returning
      value(RETURN) type TY_TOKEN .
  methods SCAN
    returning
      value(RETURN) type TY_TOKEN .
  methods SCANPUNCTUATOR
    returning
      value(RETURN) type TY_TOKEN .
  methods SCANWORD
    returning
      value(RETURN) type TY_TOKEN .
  methods SCANTYPE
    returning
      value(RETURN) type TY_TOKEN .
  methods SCANNUMBER
    returning
      value(RETURN) type TY_TOKEN .
  methods SCANSTRING
    returning
      value(RETURN) type TY_TOKEN .
  methods SKIPINTEGER
    returning
      value(RETURN) type STRING .
  methods SKIPWHITESPACE
    returning
      value(RETURN) type STRING .
  methods CREATE_ILLEGAL
    returning
      value(RETURN) type ref to CX_STATIC_CHECK .
  methods CREATEERROR
    importing
      !MESSAGE type STRING
    returning
      value(RETURN) type ref to CX_STATIC_CHECK .
  methods CREATE_UNEXPECTED
    importing
      !TOKEN type TY_TOKEN
    returning
      value(RETURN) type ref to CX_STATIC_CHECK .
protected section.

private section.
ENDCLASS.



CLASS ZCL_GRAPHQL_TOKENIZER IMPLEMENTATION.


 method class_constructor.
   punctuators = value ty_tokens_type_tab(
     ( short = 'LT' klass = 'Punctuator' name = '<')
     ( short = 'GT' klass = 'Punctuator' name = '>')
     ( short = 'LBRACE' klass = 'Punctuator' name = '{')
     ( short = 'RBRACE' klass = 'Punctuator' name = '}')
     ( short = 'LPAREN' klass = 'Punctuator' name = '(')
     ( short = 'RPAREN' klass = 'Punctuator' name = ')')
     ( short = 'COLON' klass = 'Punctuator' name = ':')
     ( short = 'COMMA' klass = 'Punctuator' name = ',')
     ( short = 'AMP' klass = 'Punctuator' name = '&')
     ( short = 'END' klass = 'End' name = 'end')
     ( short = 'IDENTIFIER' klass = 'Identifier' name = 'identifier')
     ( short = 'NUMBER' klass = 'NumberLiteral' name = 'number')
     ( short = 'STRING' klass = 'StringLiteral' name = 'string')
    ).

   keywords = value ty_tokens_type_tab(
    ( short = 'NULL' klass = 'Keyword' name = 'null' )
    ( short = 'TRUE' klass = 'Keyword' name = 'true' )
    ( short = 'FALSE' klass = 'Keyword' name = 'false' )
    ( short = 'AS' klass = 'Keyword' name = 'as' )
    ( short = 'QUERY' klass = 'Keyword' name = 'Query' )
   ).
   matches = value ty_match_type_tab(
     ( name = 'LBRACE' regex = '^\{')
     ( name = 'RBRACE' regex = '^\}')
     ( name = 'LPAREN' regex = '^\(')
     ( name = 'RPAREN' regex = '^\)')
     ( name = 'COLON' regex = '^\:')
     ( name = 'COMMA' regex = '^\,')
     ( name = 'AMP' regex = '^\&')
     ( name = 'STRING' regex = '^"[a-z_A-Z0-9]+"')
     ( name = 'QUERY' regex = '^query(\s|\{)')
     ( name = 'ON' regex = '^on')
     ( name = 'FRAGMENT' regex = '^fragment')
     ( name = 'FRAGMENTTYPE' regex = '^\.{3}[a-z_A-Z]+')
     ( name = 'NUMBER' regex = '^[0-9]+')
     ( name = 'IDENTIFIER' regex = '^[a-z_A-Z0-9]+')
   ).


 endmethod.


  METHOD CONSTRUCTOR.
    me->source = source.
    me->pos = 0.
    me->line = 1.
    me->line_start = 0.
    me->lookahead = me->next( ).
  ENDMETHOD.


  method createerror.
    return = new zcx_graphql_error( message && | ({ me->line }:{ me->column })| ).
  endmethod.


  method create_illegal.
    if me->pos < strlen( me->source ).
      return = new zcx_graphql_error( |Unexpected { me->source+me->pos }| ).
    else.
      return = new zcx_graphql_error( 'Unexpected end of input' ).
    endif.
  endmethod.


  method create_unexpected.
    case token-klass.
        when 'End'. return = me->createError('Unexpected end of input').
        when 'NumberLiteral'. return = me->createError('Unexpected number').
        when 'StringLiteral'. return = me->createError('Unexpected string').
        when 'Identifier'. return = me->createError('Unexpected identifier').
        when 'Keyword'. return = me->createError(`Unexpected token ${token.value}`).
        when 'Punctuator'. return = me->createError(`Unexpected token ${token.type.name}`).
        when others.
          return = me->createError( |Unexpected Identifier { token-type }{ token-value }| ).
    endcase.
  endmethod.


  method end.
    return = xsdbool( me->lookahead-type = 'END' ).
  endmethod.


  method get_column.
    return = me->pos - me->line_start.
  endmethod.


  method get_keyword.
    case name.
      when 'null'.
        return = 'NULL'.
      when 'true'. return = 'TRUE'.
      when 'false'. return = 'FALSE'.
      when 'as'. return = 'AS'.
      when 'query'. return = 'QUERY'.
      when others. return = 'IDENTIFIER'.
     endcase.

  endmethod.


  method lex.
   prev = me->lookahead.
   me->lookahead = me->next( ).
   return = prev.
  endmethod.


  method next.
      me->skipWhitespace( ).

    data(line) = me->line.
    data(lineStart) = me->line_start.
    return = me->scan( ).

    return-line = line.
    return-column = me->pos - lineStart.

  endmethod.


  method peek.
  endmethod.


  method scan.
   if me->pos >= strlen( me->source ).
      return = value ty_token( ).
   else.
    data(test) = substring(  val = me->source off = me->pos ).
    data(sub) = replace( val = substring( val = me->source off = me->pos ) regex = `\n` with = '' occ = 0 ).
    loop at matches into data(match).

      data(matched) = match( val = sub regex = match-regex occ = 1 ).
      if matched is not initial.
        return = value #( type = match-name value = matched ).
        me->pos = me->pos + strlen( matched ).
        return.
      endif.
    endloop.
*    data(ch) = substring( val = me->source off = me->pos len = 1 ).
*    case ch.
*      when '('. me->pos = me->pos + 1. return = value #( type = 'LPAREN' ).
*      when ')'. me->pos = me->pos + 1. return = value #( type = 'RPAREN' ).
*      when '{'. me->pos = me->pos + 1. return = value #( type = 'LBRACE' ).
*      when '}'. me->pos = me->pos + 1. return = value #( type = 'RBRACE' ).
*      when '<'. me->pos = me->pos + 1. return = value #( type = 'LT' ).
*      when '>'. me->pos = me->pos + 1. return = value #( type = 'GT' ).
*      when '&'. me->pos = me->pos + 1. return = value #( type = 'AMP' ).
*      when ','. me->pos = me->pos + 1. return = value #( type = 'COMMA' ).
*      when ':'. me->pos = me->pos + 1. return = value #( type = 'COLON' ).
*    endcase.
*
*    if ch = '.'.
*      return = me->scanType( ).
*    endif.
*    if ch = '_' or ch = '$' or 'a' <= ch and ch <= 'z' or 'A' <= ch and ch <= 'Z'.
*      return = me->scanWord( ).
*    endif.
*
*    if ch = '-' or '0' <= ch and ch <= '9'.
*      return = me->scanNumber( ).
*    endif.
*
*    if ch = '"'.
*      return = me->scanString( ).
*    endif.

     if return is initial.
       data(lo_err) = me->create_illegal( ).
       raise exception lo_err.
     endif.
    endif.
  endmethod.


  method scannumber.
    data(start) = me->pos.

    if substring( val = me->source off = me->pos ) = '-'.
      me->pos = me->pos + 1.
    endif.

    me->skipInteger( ).

    if substring( val = me->source off = me->pos ) = '.'.
      me->pos = me->pos + 1.
      me->skipInteger( ).
    endif.

    data(ch) = substring( val = me->source off = me->pos ).
    if ch = 'e' or ch = 'E'.
      me->pos = me->pos + 1.

      ch = substring( val = me->source off = me->pos ).
      if ch = '+' or ch = '-'.
        me->pos = me->pos + 1.
      endif.

      me->skipInteger( ).
    endif.

    data(value) = substring( val = me->source off = start len = me->pos - start ).
    return = value #( type = 'NUMBER' value = value ).
  endmethod.


  method scanpunctuator.
   data(glyph) = substring( val = me->source off = me->pos + 1 ).
    return = value #(  type = glyph ).
  endmethod.


  method scanstring.
    me->pos = me->pos + 1.

    data value type string.
    data ch type c length 1.
    while me->pos < strlen( me->source ).
      ch = substring( val = me->source off = me->pos len = 1 ).
      if ch = '"'.
        me->pos = me->pos + 1.
        return = value #( type = 'STRING' value = value ).
        exit.
      endif.

      if ch = |\r| or ch = |\n|.
        exit.
      endif.

      concatenate value ch into value.
      me->pos = me->pos + 1.
    endwhile.

    if return is initial.
     data(lo_err) =  me->create_illegal( ).
     raise exception lo_err.
    endif.
  endmethod.


  method scanType.
    data(start) = me->pos.
    me->pos = me->pos + 1.


    data(value) = substring( val = me->source off = start len = me->pos - start ).
    return = value #( type = me->get_keyword( value ) value = value ).
  endmethod.


  method scanword.
    data(start) = me->pos.
    me->pos = me->pos + 1.

    while me->pos < strlen( me->source ).
      data(ch) = substring( val = me->source off = me->pos len = 1 ).
      if ch = '_' or ch = '$' or 'a' <= ch and ch <= 'z' or 'A' <= ch and ch <= 'Z' or '0' <= ch and ch <= '9'.
        me->pos = me->pos + 1.
      else.
        exit.
      endif.
    endwhile.

    data(value) = substring( val = me->source off = start len = me->pos - start ).
    return = value #( type = me->get_keyword( value ) value = value ).
  endmethod.


  method skipinteger.
    data(start) = me->pos.

    while me->pos < strlen( me->source ).
      data(ch) = substring( val = me->source off = me->pos ).
      if '0' <= ch and ch <= '9'.
        me->pos = me->pos + 1.
      else.
        exit.
      endif.
    endwhile.

    if me->pos - start = 0.
      data(lo_err) = me->create_illegal( ).
      raise exception lo_err.
    endif.
  endmethod.


  method skipwhitespace.
    data ch type c length 1.
    while me->pos < strlen( me->source ).
      ch = me->source+me->pos.
      if ch = space or ch = |\t|.
        me->pos = me->pos + 1.
      elseif ch = |\r|.
        me->pos = me->pos + 1.
        if substring( val = me->source off = me->pos ) = '\n'.
          me->pos = me->pos + 1.
        endif.
        me->line = me->line + 1.
        me->line_start = me->pos.
      elseif ch = |\n|.
        me->pos = me->pos + 1.
        me->line = me->line + 1.
        me->line_start = me->pos.
      else.
        exit.
      endif.
    endwhile..
  endmethod.
ENDCLASS.
