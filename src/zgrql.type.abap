type-pool zgrql.

types: begin of zgrql_output_type,
            kind type string,
            name type string,
            ofType type ref to data,
            isDeprecated  type boolean,
            deprecationReason type string,
       end of zgrql_output_type.

types: begin of zgrql_argument,
        name type string,
        description type string,
        type type zgrql_output_type,
        defaultValue type string,
       end of zgrql_argument,
       zgrql_argument_tab type table of zgrql_argument with key name.

types: begin of zgrql_graphql_fieldconfig,
          type type zgrql_output_type,
          args type zgrql_argument_tab,
          resolve type string,
          deprecation_reason type string,
          description type string,
       end of zgrql_graphql_fieldconfig,
       zgrql_graphql_fieldconfig_tab type table of zgrql_graphql_fieldconfig with default key.

types: begin of zgrql_graphql_interface_type,
          name type string,
       end of zgrql_graphql_interface_type.

types: begin of zgrql_resolve_type,
          class_name type string,
          method_name type string,
       end of zgrql_resolve_type.

types: begin of zgrql_graphql_object_type,
          name type string,
          interfaces type zgrql_graphql_interface_type,
          fields type zgrql_graphql_fieldconfig_tab,
          is_type_of type string,
          description type string,
       end of zgrql_graphql_object_type.

types: begin of zgrql_field_type,
          name type string,
          type type zgrql_type,
          args type zgrql_argument_type_tab,
          resolver type zgrql_resolve_type,
          deprecation_reason type string,
          is_deprecated type boolean,
          description type string,
       end of zgrql_field_type,
       zgrql_field_type_tab type table of zgrql_field_type with key name.

types: begin of zgrql_enum_type,
         name type string,
       end of zgrql_enum_type,
       zgrql_enum_type_tab type table of zgrql_enum_type with key name.

types: begin of zgrql_type_type,
        description type string,
        enum_values type zgrql_enum_type_tab,
        fields type zgrql_field_type_tab,
        inputFields type stringtab,
        interfaces type stringtab,
        kind type string,
        name type string,
        of_type type zgrql_type,
        possible_types type stringtab,
        subscription_type type zgrql_type,
        types type zgrql_type_tab,
        resolver type zgrql_resolve_type,
       end of zgrql_type_type,
       zgrql_type_type_tab type table of zgrql_type_type with key name.

types: begin of zgrql_type,
        kind type string,
        name type string,
        of_type type ref to data,  "zgrql_type
       end of zgrql_type,
       zgrql_type_tab type table of zgrql_type with default key.

types: begin of zgrql_argument_type,
        defaultValue type ref to data,
        deprecationReason type string,
        description type string,
        is_deprecated type boolean,
        name type string,
        type type zgrql_type,
       end of zgrql_argument_type,
       zgrql_argument_type_tab type table of zgrql_argument_type with default key.

types: begin of zgrql_directive_type,
         name type string,
         args type zgrql_argument_type_tab,
         description type string,
         locations type stringtab,
       end of zgrql_directive_type,
       zgrql_directive_type_tab type table of zgrql_directive_type with default key.

types: begin of zgrql_schema_type,
          directives type zgrql_directive_type_tab,
          mutation_type type zgrql_type_type,
          query_type type zgrql_type_type,
          subscription_type type zgrql_type_type,
          types type zgrql_type_type_tab,
       end of zgrql_schema_type.
types: begin of zgrql_data_type,
         __schema type zgrql_schema_type,
       end of zgrql_data_type.
types: begin of zgrql_all_type,
         data type zgrql_data_type,
       end of zgrql_all_type.

types: begin of zgrql_input_type,
          query type string,
          mutation type string,
       end of zgrql_input_type.
