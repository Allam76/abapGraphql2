CLASS lcl_test DEFINITION FOR TESTING risk level harmless.
  PUBLIC SECTION.
    methods test_regex for testing.
ENDCLASS.
*
CLASS lcl_test IMPLEMENTATION.
  method test_regex.
    data(text) = |...testFrag|.
    data(match) = match( val = text occ = 1 regex = '\.{3}[a-zA-Z]+' ).
    data(sub) = find_end( val = text occ = 1 regex = '\.{3}[a-zA-Z]+' ).
    cl_abap_unit_assert=>assert_not_initial( act = match msg = |should not be equal| ).
  endmethod.
ENDCLASS.
