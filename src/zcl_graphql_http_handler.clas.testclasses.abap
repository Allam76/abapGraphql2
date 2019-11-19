class test definition for testing risk level harmless.
  public section.
    methods get_handler for testing.
    methods introspection for testing.
endclass.

class test implementation.
  method get_handler.
    data(handler) = new zcl_graphql_http_handler(  )->get_handler( '/test' ).
    cl_abap_unit_assert=>assert_equals( act = handler->has_path( '/test' ) exp = abap_true msg = 'class name should be for test model' ).
  endmethod.
  method introspection.
    data(handler) = new zcl_graphql_http_handler(  )->get_handler( '/test' ).
    cl_mime_repository_api=>get_api( )->get( exporting i_url = '/SAP/PUBLIC/TEST/unit-test/graphql/introspectionQuery.txt' importing e_content = data(content) ).
    data(query) = cl_abap_codepage=>convert_from( source = content codepage = `UTF-8` ).
    data(ast) = new zcl_graphql_parser( query )->parsequery(  ).
    data(data) = handler->evaluate( ast = ast ).

  endmethod.
endclass.
