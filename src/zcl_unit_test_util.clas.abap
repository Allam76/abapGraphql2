class zcl_unit_test_util definition
  public
  create public .

public section.
  types: begin of file_type,
           url type string,
           content type string,
         end of file_type,
         file_type_tab type table of file_type with key url.

  class-methods load_files_from_mime importing url type string returning value(result) type file_type_tab.
protected section.
private section.
endclass.



class zcl_unit_test_util implementation.
  method load_files_from_mime.
    data(api) = cl_mime_repository_api=>get_api(  ).
    api->file_list( exporting i_url = url importing e_files = data(file_list) ).
    loop at file_list into data(file).
      append initial line to result assigning field-symbol(<result>).
        <result>-url = file.
        api->get( exporting i_url = file importing e_content = data(content) ).
        <result>-content = cl_abap_codepage=>convert_from( source = content codepage = `UTF-8` ).
    endloop.
  endmethod.
endclass.
