class lcl_token definition.
 public section.
    data type type string.
    data name type string.
    data alias type string.
    data value type ref to lcl_token.
    data fields type table of ref to lcl_token with default key.
    data params type table of ref to lcl_token with default key.

  methods constructor importing
    type type string
    name type string
    alias type string
    value type ref to lcl_token
    fields type any table
    params type any table.
endclass.

types ty_token_tab type table of ref to lcl_token with default key.
