class ZCL_GRAPHQL_TOKEN definition
  public
  create public .

public section.
    data type type string.
    data name type string.
    data alias type string.
    data on_type type string.
    data entity_type type string.
    data entity_id type string.
    data value type ref to data.
    data fields type table of ref to ZCL_GRAPHQL_TOKEN with default key.
    data arguments type table of ref to ZCL_GRAPHQL_TOKEN with default key.

  methods constructor importing
    type type string
    name type string optional
    alias type string optional
    on_type type string optional
    value type ref to data optional
    fields type any table optional
    arguments type any table optional.
  methods get_value_string returning value(return) type string.

  types ty_token_tab type table of ref to ZCL_GRAPHQL_TOKEN with default key.
protected section.
private section.
ENDCLASS.



CLASS ZCL_GRAPHQL_TOKEN IMPLEMENTATION.


 method constructor.
  me->type = type.
  me->name = name.
  me->alias = alias.
  me->on_type = on_type.
  if fields is not initial.
   me->fields = fields.
  endif.
  if arguments is not initial.
   me->arguments = arguments.
  endif.
  me->value = value.
 endmethod.


 method get_value_string.
  if cl_abap_typedescr=>describe_by_data_ref( value )->type_kind = cl_abap_typedescr=>typekind_oref.
   assign value->* to field-symbol(<fs>).
   return = cast string( cast zcl_graphql_token( <fs> )->value )->*.
  else.
   return = cast string( value )->*.
  endif.
 endmethod.
ENDCLASS.
