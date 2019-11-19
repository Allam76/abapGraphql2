class basic_types definition.
  public section.
    type-pools zgrql.
    class-methods get_types returning value(result) type zgrql_all_type.
    class-methods get_fields importing name type string returning value(result) type zgrql_field_type_tab.
endclass.

class basic_types implementation.
  method get_types.
    result = value #( data = value #( __schema = value #(
      mutation_type = value #( name = 'Mutation' )
      query_type = value #( name = 'Query' )
      subscription_type = value #(  )
      types = value #(
      ( name = '__Schema' kind = 'OBJECT' fields = get_fields( 'zgrql_schema_type' ) resolver = value #( method_name = 'METADATA_SCHEMA' ) )
      ( name = '__Type' kind = 'OBJECT' fields =  get_fields( 'zgrql_type_type' ) resolver = value #( method_name = 'METADATA_TYPE' ) )
      ( name = '__TypeKind' kind = 'OBJECT' fields =  get_fields( 'zgrql_schema_type' ) resolver = value #( method_name = 'METADATA_TYPEKIND' ) )
      ( name = '__Field' kind = 'OBJECT' fields = value #(  ) resolver = value #( method_name = 'METADATA_FIELD' ) )
      ( name = '__InputValue' kind = 'OBJECT' fields = value #(  ) )
      ( name = '__EnumValue' kind = 'OBJECT' fields = value #(  ) )
      ( name = '__Directive' kind = 'OBJECT' fields = value #(  ) )
      ( name = '__DirectiveLocation' kind = 'ENUM' fields = value #(  ) enum_values = value #(
        ( name = 'QUERY' )
        ( name = 'MUTATION' )
        ( name = 'SUBSCRIPTION' )
        ( name = 'FIELD' )
        ( name = 'FRAGMENT_DEFINITION' )
        ( name = 'FRAGMENT_SPREAD' )
        ( name = 'INLINE_FRAGMENT' )
        ( name = 'SCHEMA' )
        ( name = 'SCALAR' )
        ( name = 'OBJECT' )
        ( name = 'FIELD_DEFINITION' )
        ( name = 'ARGUMENT_DEFINITION' )
        ( name = 'INTERFACE' )
        ( name = 'UNION' )
        ( name = 'ENUM' )
        ( name = 'ENUM_VALUE' )
        ( name = 'INPUT_OBJECT' )
        ( name = 'INPUT_FIELD_DEFINITION' )

      ) )
      ( name = 'Int' kind = 'SCALAR' )
      ( name = 'Boolean' kind = 'SCALAR' )
      ( name = 'String' kind = 'SCALAR' )
      ( name = 'ID' kind = 'SCALAR' )
      ( name = 'Date' kind = 'SCALAR' )
    ) ) ) ).
  endmethod.

  method get_fields.
    data(comps) = cast cl_abap_structdescr( cl_abap_typedescr=>describe_by_name( name ) )->get_components(  ).
    loop at comps into data(comp).
      append initial line to result assigning field-symbol(<result>).
      <result>-name = comp-name.
    endloop.
  endmethod.
endclass.
