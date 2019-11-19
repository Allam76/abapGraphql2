class test definition for testing risk level harmless.
  public section.
    methods introspection for testing.
    methods query for testing.
endclass.

class test implementation.
  method introspection.
    data(handler) = new zcl_graphql_test_model_handler( ).
    handler->set_resolvers( value #( ( type = 'IntrospectionQuery/__schema/types/FullType' method_name = 'METADATA_GET_TYPES'  ) ) ).
    cl_mime_repository_api=>get_api( )->get( exporting i_url = '/SAP/PUBLIC/TEST/unit-test/graphql/introspectionQuery.txt' importing e_content = data(content) ).
    data(query) = cl_abap_codepage=>convert_from( source = content codepage = `UTF-8` ).
    data(ast) = new zcl_graphql_parser( query )->parsequery(  ).
    data(data) = handler->evaluate( ast = ast ).

  endmethod.

  method query.
    try.
      data(handler) = new zcl_graphql_test_model_handler( ).
      cl_mime_repository_api=>get_api( )->get( exporting i_url = '/SAP/PUBLIC/TEST/unit-test/graphql/basicQuery.txt' importing e_content = data(content) ).
      data(query) = cl_abap_codepage=>convert_from( source = content codepage = `UTF-8` ).
      data(ast) = new zcl_graphql_parser( query )->parsequery(  ).
      data(data) = handler->evaluate( ast = ast ).
      cl_abap_unit_assert=>assert_bound( act = data ).
    catch cx_root into data(error).
      data(text) = error->get_text(  ).
      raise exception error.
    endtry.

  endmethod.
endclass.
