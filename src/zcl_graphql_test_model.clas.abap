class zcl_graphql_test_model definition
  public
  create public .

public section.
type-pools zgrql.
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
types: begin of entity_out_type,
         id type string,
         label type string,
         attributes type attribute_out_type_tab,
         relations type rel_out_type_tab,
         tables type stringtab,
         views type stringtab,
       end of entity_out_type,
       entity_out_type_tab type table of entity_out_type with key id.

  data entities type entity_out_type_tab.
  methods load_model_from_mime importing name type string.
  methods convert_2_graphql_metadata returning value(result) type zgrql_schema_type.
protected section.
private section.
endclass.

class zcl_graphql_test_model implementation.
  method load_model_from_mime.
    cl_mime_repository_api=>get_api( )->get( exporting i_url = |/SAP/PUBLIC/TEST/{ name }.json| importing e_content = data(content) ).
    data(json_string) = cl_abap_codepage=>convert_from( source = content codepage = `UTF-8` ).
    /ui2/cl_json=>deserialize( exporting json = json_string changing data = me->entities ).

  endmethod.

  method convert_2_graphql_metadata.
*    data(types) = value zgrql_type_type_tab( for entity in me->entities (
*         name = entity-label
*         kind = 'OBJECT'
*         of_type = value #(  )
*    ) ).
*    result = value #(
*      query_type = value #( name = 'QueryType' kind = 'OBJECT' description = '' )
*      types = value #( for entity in me->entities (
*         name = ''
*         kind = ''
*         of_type = value #(  )
*         fields = value #( for att in entity-attributes (
*           name = ''
*           kind = ''
*           type = att-type,
*
*         ) )
*    ) ) ).
  endmethod.
endclass.
