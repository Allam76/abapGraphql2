class zcl_graphql_test_model_handler definition
  public inheriting from zcl_graphql_abs_handler
  create public .

public section.

types: begin of flight_type,
         carrier_name type string,
       end of flight_type,
       flight_type_tab type table of flight_type with key carrier_name.
types: begin of join_cond_type,
         source type string,
         source_type type string,
         operator type string,
         target type string,
         target_type type string,
       end of join_cond_type,
       join_cond_type_tab type table of join_cond_type with key source target.
types: begin of rel_out_type,
         name type string,
         number type string,
         label type string,
         source type string,
         target type string,
         cardinality1 type string,
         cardinality2 type string,
         conditions type join_cond_type_tab,
       end of rel_out_type,
       rel_out_type_tab type table of rel_out_type with key name.
types: begin of attribute_out_type,
         name type string,
         type type string,
         label type string,
         domname type string,
         checktable type string,
         decimals type i,
         length type i,
         rollname type string,
       end of attribute_out_type,
       attribute_out_type_tab type table of attribute_out_type with key name.
types: begin of action_out_type,
         name type string,
         type type string,
         arguments type attribute_out_type_tab,
         method_name type string,
       end of action_out_type,
       action_out_tab type table of action_out_type with key name.
types: begin of entity_out_type,
         id type string,
         label type string,
         attributes type attribute_out_type_tab,
         relations type rel_out_type_tab,
         tables type stringtab,
         actions type action_out_tab,
         views type stringtab,
       end of entity_out_type,
       entity_out_type_tab type table of entity_out_type with key id.

  methods load redefinition.
  methods get_metadata redefinition.
  methods set_resolvers redefinition.
  class-methods class_constructor.
  methods constructor.
  methods get_flights importing token type ref to zcl_graphql_token
                                parent_token type ref to zcl_graphql_token
                                  parent type any optional
                           returning value(result) type ref to data.
protected section.
  methods get_field_list importing type type any path type string returning value(result) type stringtab.
private section.
  methods is_relation importing token type ref to zcl_graphql_token
                                parent_token type ref to zcl_graphql_token
                      returning value(result) type boolean.
endclass.



class zcl_graphql_test_model_handler implementation.
  method constructor.
    super->constructor(  ).
    me->internal_model-data-__schema-query_type = value #( name = 'Query' ).
    me->external_model = load( 'test-model' ).
    data(metadata) = get_metadata( '' ).
    append lines of metadata-data-__schema-types to me->internal_model-data-__schema-types.
  endmethod.
  method load.
    data entities type entity_out_type_tab.
    cl_mime_repository_api=>get_api( )->get( exporting i_url = |/SAP/PUBLIC/TEST/{ name }.json| importing e_content = data(content) ).
    data(json_string) = cl_abap_codepage=>convert_from( source = content codepage = `UTF-8` ).
    /ui2/cl_json=>deserialize( exporting json = json_string changing data = entities ).
    create data result type entity_out_type_tab.
    assign result->* to field-symbol(<result>).
    <result> = entities.
  endmethod.

  method class_constructor.
    path = '/test'.
    model_name = 'test-model'.
  endmethod.

  method get_metadata.
    field-symbols <model> type entity_out_type_tab.
    assign me->external_model->* to <model>.
    result = value #( data = value #( __schema = value #(
      query_type = value #(
        name = 'Query'
      )
      mutation_type = value #(
        name = 'Mutation'
      )
      types = value #(
        (
           name = 'Query'
           kind = 'OBJECT'
           fields = value #( for ent in <model> (
             name = ent-label
             type = value #( kind = 'OBJECT' name = ent-label )
             args = value #( for att in ent-attributes (
               name = att-label
               type = value #( name = to_upper_first( att-type ) kind = 'SCALAR' )
             ) )
           ) )
        )
        (
          name = 'Mutation'
          kind = 'OBJECT'
          fields = value #( for ent in <model> for action in ent-actions (
            name = action-name
            type = value #( name = 'flights' kind = 'OBJECT' )
            args = value #( for arg in action-arguments ( name = arg-name type = value #( name = to_upper_first( arg-type ) kind = 'SCALAR' ) ) )
          ) )
        )
      )
    ) ) ).
    append lines of value zgrql_type_type_tab( for entity in <model> (
      name = entity-label
      kind = 'OBJECT'
      resolver = value #( method_name = 'GET_FLIGHTS' )
      fields = value #( for att in entity-attributes (
        name = att-label
        type = value #( name = to_upper_first( att-type ) kind = 'SCALAR' )
      ) )
    ) ) to result-data-__schema-types.
    loop at result-data-__schema-types assigning field-symbol(<type>).
      loop at <model> into data(model) where label = <type>-name.
        loop at model-relations into data(rel).
          data(target) = <model>[ id = rel-target ].
          append value #( name = rel-name type = value #( kind = 'OBJECT' name = target-label ) ) to <type>-fields.
        endloop.
      endloop.
    endloop.
  endmethod.

  method set_resolvers.
    super->set_resolvers( resolvers = resolvers ).
  endmethod.

  method get_flights.
    field-symbols <model> type entity_out_type_tab.
    field-symbols <token_value> type ref to zcl_graphql_token.
    assign me->external_model->* to <model>.

    data(type) = me->internal_model-data-__schema-types[ name = token->name ].
    data(ext_type) = <model>[ label = type-name ].
    data(table_name) = ext_type-id.

    data(struc_handle) = get_type( type ).
    data(table_handle) = cl_abap_tabledescr=>create( struc_handle ).
    field-symbols <flight_tab> type any table.
    create data result type handle table_handle.
    assign result->* to <flight_tab>.
    data(db_fld_names) = get_field_list( type = ext_type path = 'ATTRIBUTES/NAME').
    data(alias_fld_names) = get_field_list( type = type path = 'FIELDS/NAME').
    data(statement) = cl_sadl_sql_statement=>create_for_open_sql(  ).
    statement->select(  ).

    loop at db_fld_names into data(db_fld).
     data(inx) = sy-tabix.
     statement->element( iv_element = db_fld iv_entity_alias = table_name )->as( iv_alias = from_mixed( val = alias_fld_names[ inx ] case = 'a' ) ).
    endloop.
    statement->from(  )->element( iv_element = table_name ).
    if is_relation(  token = token parent_token = parent_token ) = abap_true or lines( token->arguments ) > 0.
      statement->where(  ).
    endif.
    loop at token->arguments into data(argument).
      inx = sy-tabix.
      assign argument->value->* to <token_value>.
      assign <token_value>->value->* to field-symbol(<end_value>).
      statement->compare_element_to_value(
        iv_element = ext_type-attributes[ label = argument->name ]-name
        iv_entity_alias = table_name
        iv_operator = 'EQ'
        iv_low = <end_value> ).
      if lines( token->arguments ) <> inx.
        statement->and(  ).
      endif.
    endloop.
    if is_relation(  token = token parent_token = parent_token ).
      data(relation) = <model>[ label = parent_token->name ]-relations[ name = token->name ].
      loop at relation-conditions into data(condition).
        data(comp_name) = from_mixed( val = <model>[ label = parent_token->name ]-attributes[ name = condition-source ]-label case = 'a' ).
        assign component comp_name of structure parent to field-symbol(<source>).
        statement->compare_element_to_value( iv_element = condition-target iv_operator = 'EQ' iv_low = <source> ).
      endloop.
    endif.
    statement->execute_on_current_client( importing et_data = <flight_tab> ).
  endmethod.

  method get_field_list.
    field-symbols <table> type any table.
    split path at '/' into data(table) data(field).
    assign component table of structure type to <table>.
    loop at <table> assigning field-symbol(<line>).
      append initial line to result assigning field-symbol(<target>).
       assign component field of structure <line> to field-symbol(<source>).
       <target> = <source>.
    endloop.
  endmethod.

  method is_relation.
    field-symbols <model> type entity_out_type_tab.
    assign me->external_model->* to <model>.
    if line_exists( <model>[ label = parent_token->name ] ).
      if line_exists( <model>[ label = parent_token->name ]-relations[ name = token->name ] ).
        result = abap_true.
      endif.
    endif.
  endmethod.


endclass.
