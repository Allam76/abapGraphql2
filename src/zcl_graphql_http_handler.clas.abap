class zcl_graphql_http_handler definition
  public
  create public.

public section.
  type-pools zgrql.
  interfaces if_http_extension.
protected section.
  methods get_metadata importing name type string
                       returning value(result) type zgrql_schema_type.
  methods evaluate importing ast type ref to zcl_graphql_token
                       returning value(result) type string.
private section.
  methods get_handler importing path_part type string returning value(result) type ref to zcl_graphql_abs_handler.
  methods serialize importing data type any returning value(result) type string.
  methods deserialize importing json type string changing data type any.
endclass.



class zcl_graphql_http_handler implementation.
  method if_http_extension~handle_request.
    data input type zgrql_input_type.

    server->response->set_content_type( 'application/json' ).

    data headers type tihttpnvp.
    data(method) = server->request->get_method(  ).
    server->request->get_header_fields( changing fields = headers ).
    data(resource) = server->request->get_header_field( if_http_header_fields_sap=>path_info ).
    data(handler) = get_handler( resource ).
    if handler is not initial.
     if method = 'GET'.
*      data(json) = zcl_json=>serialize(
*        data = handler->get_metadata( 'TEST_MODEL' )
*        compress = abap_true
*        pretty_name = zcl_json=>pretty_mode-camel_case
*      ).
      server->response->set_cdata( data = | \{"data":\{ "__schema": { '' } \}\}| ).
     elseif method = 'POST'.
       deserialize( exporting json = server->request->get_cdata(  ) changing data = input ).
       data(ast) = new zcl_graphql_parser( input-query )->parsequery( ).
        data(data) = handler->evaluate( ast ).
        server->response->set_cdata( data = zcl_json2=>serialize(
          data = data
          compress = abap_true
          pretty_name = zcl_json2=>pretty_mode-camel_case

          compress_fields = value #( ( `INTERFACES` ) ( `ARGS` ) ( `FIELDS` ) )

        ) ).
     endif.
     server->response->set_status( code = 200 reason = 'OK' ).
    else.
      server->response->set_status( code = 400 reason = |the resource: { resource } does not have a handler class| ).
    endif.
  endmethod.

  method get_metadata.
  endmethod.

  method evaluate.
  endmethod.

  method get_handler.
    data model_name type string.
    try.
        data(class_names) = cast cl_oo_class( cl_oo_class=>get_instance( 'ZCL_GRAPHQL_ABS_HANDLER' ) )->get_subclasses(  ).
        loop at class_names into data(class_name).
          call method (class_name-clsname)=>has_path
            exporting path_part = path_part
            receiving result = model_name.
          if model_name <> ''.
            create object result type (class_name-clsname).
            result->init(  ).
            return.
          endif.
        endloop.
    catch cx_root into data(error).
    endtry.
  endmethod.

  method serialize.
  endmethod.

  method deserialize.
    zcl_json2=>deserialize( exporting json = json changing data = data ).
  endmethod.
endclass.
