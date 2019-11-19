class ZCL_GRAPHQL_CDS_HANDLER definition
  public
  create public .

public section.
 types: begin of name_value,
          name type string,
          value type string,
        end of name_value,
        name_value_tab type table of name_value with key name.

 types data_tab type table of ref to data with default key.
 types sorted_string_tab type sorted table of string with unique key table_line.
 types test type ref to data.

 class-data provider type ref to cl_sadl_entity_provider_cds.
 class-methods class_constructor.

 data parent type ref to if_sadl_entity.
 data entity type ref to if_sadl_entity.

 class-methods read_single importing table type string
                              elements type sorted_string_tab
                              where_elements type name_value_tab
                           returning value(return) type ref to data
              raising cx_static_check.
 class-methods add_field_to_result importing name type string
                                             value type ref to data
                                             data type ref to data
                                   returning value(return) type ref to data.
 methods query importing node type ref to zcl_graphql_token
                         parent_node type ref to zcl_graphql_token optional
                         data type ref to data optional
               returning value(result) type ref to data.
 methods field importing node type ref to zcl_graphql_token
                         parent_node type ref to zcl_graphql_token optional
                         data type ref to data optional
               returning value(result) type ref to data.
  methods constructor.
protected section.
private section.
 class-methods elements importing elements type sorted_string_tab
                        returning value(result) type ref to cl_sadl_sql_statement.
 class-methods where importing element_values type name_value_tab
                      returning value(result) type ref to cl_sadl_sql_statement.
 methods convert importing value type ref to data
                 returning value(result) type string.
ENDCLASS.



CLASS ZCL_GRAPHQL_CDS_HANDLER IMPLEMENTATION.


 method add_field_to_result.

  try.
   if data is not initial.
     data(before_struct) = cast cl_abap_structdescr( cast cl_abap_tabledescr( cl_abap_typedescr=>describe_by_data_ref( data ) )->get_table_line_type( ) ).
     data(components) = before_struct->get_components( ).
   endif.

   data(handle) = cl_abap_structdescr=>create( value abap_component_tab( base components (
      name = name
      type = cast #( cl_abap_typedescr=>describe_by_data_ref( value ) )
   ) ) ).

   create data return type handle handle.
   assign return->* to field-symbol(<after>).
   assign value->* to field-symbol(<value>).
   assign component name of structure <after> to field-symbol(<field>).
   <field> = <value>.
  catch cx_root into data(err).
  endtry.

 endmethod.


 method class_constructor.
   provider = new cl_sadl_entity_provider_cds( ).
 endmethod.


 method constructor.
 endmethod.


 method convert.
*   assign value->* to field-symbol(<fs>).
*   if cl_abap_objectdescr=>describe_by_data_ref( value )->type_kind = cl_abap_objectdescr=>typekind_oref.
*    result = cast zcl_graphql_token( <fs> )->value.
*   else.
*    result = <fs>.
*   endif.

 endmethod.


 method elements.
      result = cl_sadl_sql_statement=>create_for_open_sql( ).
    IF elements IS INITIAL.
      result->asterisk( ).
    ELSE.
      LOOP AT elements INTO DATA(lv_element).
        result->element( lv_element ).
      ENDLOOP.
    ENDIF.
 endmethod.


 method field.
   try.
     if parent_node is bound and parent_node->entity_type is not initial.
       data(parent_entity) = provider->if_sadl_entity_provider~get_entity( iv_type = 'CDS' iv_id = conv #( parent_node->entity_type ) ).
       data(assoc) = parent_entity->get_association( iv_name = conv #( node->name ) ).
       entity = provider->if_sadl_entity_provider~get_entity( iv_type = 'CDS' iv_id = assoc-target_id ).
       node->entity_type = assoc-target_id.
     else.
        entity = provider->if_sadl_entity_provider~get_entity( iv_type = 'CDS' iv_id = conv #( node->name ) ).
        node->entity_type = node->name.
     endif.
     data(db_info) = entity->get_db_info( ).
     data(where_elements) = value name_value_tab( for param in node->params (
       name = param->name
       value = param->get_value_string( )
     ) ).

     data(elements) = reduce sorted_string_tab(
      init res type stringtab
      for field in node->fields
      next res = cond #(
        when field->fields is initial then value #( base res ( field->name ) ) else res
      )
     ).
     result = add_field_to_result(
       exporting name = node->name
                 data = result
                 value = read_single( exporting elements = elements
                                                where_elements = where_elements
                                                table = db_info-artifact_name ) ).

     loop at node->fields assigning field-symbol(<field>) where table_line->fields is not initial.
       result = add_field_to_result(
         exporting name = <field>->name
                   data = result
                   value = zcl_graphql_parser=>travserse( node = <field> parent = node handler = me )
       ).

     endloop.
   catch cx_root into data(lo_err).
    if 1 = 2. endif.
   endtry.
 endmethod.


 method query.
   try.


     data(fields) = value data_tab( for field in node->fields (
           zcl_graphql_parser=>travserse( node = field parent = node handler = me )
     ) ).
   catch cx_root.
   endtry.
 endmethod.


 method read_single.

  data(transaction) = new CL_SADL_ENTITY_TRANSACT_DDIC( iv_entity_type = 'CDS' iv_entity_id = 'DEMO_CDS_ASSOCIATION' ).
  data(struc_ref) = transaction->if_sadl_entity_container_fctry~create_entity_structure_ref( ).
  data(components) = cast cl_abap_structdescr( cl_abap_typedescr=>describe_by_data_ref( struc_ref ) )->get_components( ).
  data(handle) = cl_abap_structdescr=>create( filter #( components in elements where name = table_line ) ).
  create data return type handle handle.
  assign return->* to field-symbol(<data>).
  cl_sadl_sql_statement=>create_for_open_sql( )->select_single( )->concatenate( elements( elements ) )->from( )->entity( table )->concatenate( where( where_elements )
                             )->execute_on_current_client( IMPORTING es_data = <data>  ev_successful = DATA(lv_successful) ).

 endmethod.


 method where.
    result = cl_sadl_sql_statement=>create_for_open_sql( )->where( ).
    DATA(is_key_value) = element_values[ 1 ].
    result->compare_element_to_value( iv_element = is_key_value-name iv_low = is_key_value-value  iv_operator = cl_sadl_sql_statement=>co_operator-eq ).
    DATA(lv_size) = lines( element_values ).
    LOOP AT element_values INTO is_key_value FROM 2.
      IF is_key_value IS INITIAL.
        IF sy-tabix < lv_size.
          result->or( ).
          DATA(lv_or) = abap_true.
        ENDIF.
      ELSE.
        IF lv_or = abap_false.
          result->and( ).
        ENDIF.
        lv_or = abap_false.
        result->compare_element_to_value( iv_element = is_key_value-name iv_low = is_key_value-value  iv_operator = cl_sadl_sql_statement=>co_operator-eq ).
      ENDIF.
    ENDLOOP.
 endmethod.
ENDCLASS.
