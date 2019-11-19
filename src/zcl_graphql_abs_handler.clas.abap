class zcl_graphql_abs_handler definition
  public abstract
  create public .

public section.
    type-pools zgrql.
    types: begin of resolver_type,
             type type string,
             class_name type string,
             method_name type string,
           end of resolver_type,
           resolver_type_tab type table of resolver_type with key type.

    data external_model type ref to data.
    data resolvers type resolver_type_tab.
    methods load importing name type string returning value(result) type ref to data.
    methods get_metadata importing name type string returning value(result) type zgrql_all_type.
    class-methods has_path importing path_part type string returning value(result) type boolean.
    methods evaluate importing ast type zcl_graphql_token=>ty_token_tab returning value(result) type ref to data.
    methods evaluate_individual importing token type ref to zcl_graphql_token
                                          parent_token type ref to zcl_graphql_token optional
                                          path type stringtab optional
                                parent type any optional
                                returning value(result) type ref to data.
    methods evaluate_default importing token type ref to zcl_graphql_token
                                       path type stringtab optional
                                       parent type any optional
                                returning value(result) type ref to data.
    methods set_resolvers importing resolvers type resolver_type_tab.
    methods constructor.
    class-methods get_introspect_metadata importing type type ref to zcl_graphql_token
                                                    parent type any
                                                    handler type ref to zcl_graphql_abs_handler
                                          returning value(result) type ref to data.
    methods init.
protected section.
    class-data path type string.
    class-data model_name type string.
    data ast type zcl_graphql_token=>ty_token_tab.
    data internal_model type zgrql_all_type.
    methods validate importing token type ref to zcl_graphql_token
                               parent type ref to zcl_graphql_token optional
                               type type string default 'introspect'.
    methods metadata_schema importing token type ref to zcl_graphql_token
                                      parent_token type ref to zcl_graphql_token
                                      parent type any optional
                               returning value(result) type ref to data.
    methods metadata_type importing token type ref to zcl_graphql_token
                                    parent_token type ref to zcl_graphql_token
                                    parent type any optional
                               returning value(result) type ref to data.
    methods get_type importing graphql_type type zgrql_type_type returning value(result) type ref to cl_abap_datadescr.
    methods get_simple_type importing type type string returning value(result) type ref to cl_abap_datadescr.
    methods to_upper_first importing name type string returning value(result) type string.
private section.
  methods is_table importing data type ref to data returning value(result) type boolean.
  methods convert_to_table importing input type ref to data returning value(result) type ref to data.
  methods to_snake_case importing string type string returning value(result) type string.
  methods name_or_type importing token type ref to zcl_graphql_token returning value(result) type string.
endclass.



class zcl_graphql_abs_handler implementation.
  method has_path.
   if path_part = path.
     result = abap_true.
   endif.
  endmethod.

  method to_upper_first.
    result = to_upper( substring( val = name len = 1 ) ) && substring( val = name off = 1 ).
  endmethod.

  method name_or_type.
    if token->on_type is not initial.
      result = token->on_type.
    else.
      result = token->name.
    endif.
  endmethod.

  method to_snake_case.
    find all occurrences of regex '[A-Z]' in string respecting case in character mode results data(res_tab).
    result = string.
    loop at res_tab into data(res_line).
      result = replace( val = result off = res_line-offset len = res_line-length with = '_' && to_lower( substring( val = result off = res_line-offset len = res_line-length ) ) ).
    endloop.
  endmethod.

  method is_table.
    if cl_abap_typedescr=>describe_by_data_ref( data )->kind = cl_abap_typedescr=>kind_table.
      result = abap_true.
    endif.
  endmethod.

  method convert_to_table.
    field-symbols <table> type standard table.
    if not input is initial.
      if not is_table( input ).
        data(handle) = cl_abap_tabledescr=>create( cast cl_abap_datadescr( cl_abap_typedescr=>describe_by_data_ref( input ) ) ).
        create data result type handle handle.
        assign result->* to <table>.
        assign input->* to field-symbol(<input>).
        append <input> to <table>.
      else.
        result = input.
      endif.
    endif.
  endmethod.

  method metadata_schema.
    create data result type zgrql_all_type.
    assign result->* to field-symbol(<result>).
    <result> = me->internal_model.
  endmethod.

  method metadata_type.
    create data result type zgrql_type_type.
    assign result->* to field-symbol(<result>).
    <result> = me->internal_model-data-__schema-types[ name = token->on_type ].
  endmethod.

  method set_resolvers.
    me->resolvers = resolvers.
  endmethod.

  method evaluate.
    if line_exists( ast[ table_line->type = 'Query' ] ).
      me->ast = ast.
      result = evaluate_individual( exporting token = ast[ table_line->type = 'Query' ] ).
    endif.
  endmethod.

  method evaluate_individual.
    field-symbols <table> type any table.

    data(l_path) = value #( base path ( token->name ) ).
    data(resolve_path) = concat_lines_of( table = l_path sep = '/' ).

    if token->type = 'FragmentRef'.
      data(tok) = me->ast[ table_line->name = token->name ].
    else.
      tok = token.
    endif.
    validate( token ).

    if line_exists( me->internal_model-data-__schema-types[ name = name_or_type( tok ) ] ).
      data(class_name) = me->internal_model-data-__schema-types[ name = name_or_type( tok ) ]-resolver-class_name.
      data(method_name) = me->internal_model-data-__schema-types[ name = name_or_type( tok ) ]-resolver-method_name.

      if class_name is initial and not method_name is initial.
        call method me->(method_name)
        exporting token = tok parent = parent parent_token = parent_token
        receiving result = result.
      endif.

*      call method (class_name)=>(method_name)
*        exporting type = ast parent = parent handler = me
*        receiving result = result.
*
*      assign result->* to field-symbol(<result>).

    else.
      result = evaluate_default( exporting token = tok path = l_path parent = parent ).
    endif.
*    result = convert_to_table( result ).
    if result is bound.
     if is_table( result ).
      assign result->* to <table>.
      loop at <table> assigning field-symbol(<line>).
        loop at tok->fields into data(field).
          assign component to_snake_case( name_or_type( field ) ) of structure <line> to field-symbol(<value>).
          if sy-subrc = 0.
            data(res) = evaluate_individual( exporting token = field path = l_path parent = <line> parent_token = tok ).
            assign res->* to field-symbol(<source>).
            <value> = <source>.
          else.
            if 1 = 2. endif.
          endif.
        endloop.
      endloop.
     else.
      assign result->* to <line>.
      loop at tok->fields into field.
         assign component to_snake_case( field->name ) of structure <line> to <value>.
         if sy-subrc = 0.
           res = evaluate_individual( exporting token = field path = l_path parent = <line> parent_token = tok ).
           if not res is initial.
            assign res->* to <source>.
            <value> = <source>.
           endif.
         endif.
      endloop.
     endif.
    else.
      assign result->* to <line>.
      loop at tok->fields into field.
         result = evaluate_individual( exporting token = field path = l_path parent = parent parent_token = tok ).
      endloop.
    endif.

  endmethod.

  method evaluate_default.
    if not parent is initial.
      assign component to_snake_case( name_or_type( token ) ) of structure parent to field-symbol(<source>).
      if sy-subrc = 0.
       create data result like <source>.
       assign result->* to field-symbol(<result>).
       <result> = <source>.
      else.
       if 1 = 2. endif.
      endif.
    endif.
  endmethod.

  method constructor.
    get_metadata( model_name ).
  endmethod.

  method init.
    me->external_model = load( model_name ).

    append value #( type = 'IntrospectionQuery/__schema' class_name = 'ZCL_GRAPHQL_ABS_HANDLER' method_name = 'GET_INTROSPECT_METADATA' ) to me->resolvers.
  endmethod.

  method get_metadata.
    me->internal_model = basic_types=>get_types(  ).
  endmethod.

  method load.
  endmethod.

  method get_introspect_metadata.

  endmethod.

  method validate.
    if token->type = 'FragmentRef'.
      data(tok) = me->ast[ table_line->name = token->name ].
    else.
      tok = token.
    endif.
    case token->name.
      when 'IntrospectionQuery'.
        if not line_exists( tok->fields[ table_line->name = '__Schema' ] ).
          raise exception type zcx_graphql_error exporting message = 'Should have schema'.
        endif.
      when '__schema'.
        if not line_exists( tok->fields[ table_line->name = 'queryType' ] )
          or not line_exists( tok->fields[ table_line->name = 'mutationType' ] ).
          raise exception type zcx_graphql_error exporting message = 'Should have either query or schema or both'.
        endif.
      when 'queryType'.
    endcase.
*    loop at tok->fields into data(field).
*      validate( token = field parent = tok ).
*    endloop.
  endmethod.

  method get_type.
    data comp_tab type abap_component_tab.
    loop at graphql_type-fields into data(field).
      append initial line to comp_tab assigning field-symbol(<comp>).
      <comp>-name = from_mixed( val = field-name case = 'a' ).
      if field-type-kind = 'OBJECT'.

        <comp>-type = cl_abap_tabledescr=>create( get_type( me->internal_model-data-__schema-types[ name = field-type-name ] ) ).
      else.
       <comp>-type = get_simple_type( field-type-name ).
      endif.
    endloop.
    result = cl_abap_structdescr=>create( comp_tab ).
  endmethod.

  method get_simple_type.
    data(type_upper) = to_upper( type ).
    case type_upper.
      when 'STRING'.
        result = cast cl_abap_datadescr( cl_abap_typedescr=>describe_by_name( 'string' ) ).
      when 'DATE'.
        result = cast cl_abap_datadescr( cl_abap_typedescr=>describe_by_name( 'DATS' ) ).
      when others.
        raise exception type zcx_graphql_error exporting message = |graphql type: { type } does not have an abap type defined|.
   endcase.
  endmethod.
endclass.
