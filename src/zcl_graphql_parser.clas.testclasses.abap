CLASS lcl_test DEFINITION FOR TESTING risk level harmless.
  PUBLIC SECTION.
    data source type string.
    methods constructor.
    methods test_from_files for testing.
    METHODS: basic for testing.
    methods traverse.
ENDCLASS.
*
CLASS lcl_test IMPLEMENTATION.
  method constructor.
    concatenate
  ' {'
  '  DEMO_CDS_ASSOCIATION(ID: "AA") {'
  '    ID,'
  '    DEPARTURE,'
  '    _spfli_scarr(CURRCODE: "USD") as flights {'
  '      CURRCODE,'
  '      URL'
  '    }'
  '  }'
  '}'
    into source separated by ' '.
  endmethod.
  METHOD basic.
    data(parser) = new zcl_graphql_parser( source ).
    data(ast) = parser->parsequery( ).
  ENDMETHOD.
  method traverse.
    data(parser) = new zcl_graphql_parser( source ).
    data(ast) = parser->parsequery( ).
    data(handler) = new zcl_graphql_cds_handler( ).
    data(ref) = parser->travserse( node = ast[ 1 ] handler = handler ).
  endmethod.
  method test_from_files.
    data(files) = zcl_unit_test_util=>load_files_from_mime( '/SAP/PUBLIC/TEST/unit-test/graphql' ).
    loop at files into data(file).
      data(parser) = new zcl_graphql_parser( file-content ).
      data(ast) = parser->parsequery( ).
      data(json) = zcl_json2=>serialize( data = ast pretty_name = zcl_json2=>pretty_mode-extended compress = abap_true ).
      cl_mime_repository_api=>get_api( )->put(
        i_url = '/SAP/PUBLIC/TEST/dump.json'
        i_content = cl_abap_codepage=>convert_to( source = json )
        i_suppress_dialogs = abap_true
      ).
      cl_abap_unit_assert=>assert_not_initial( act = ast msg = 'ast should not be initial' ).
    endloop.
  endmethod.
ENDCLASS.
