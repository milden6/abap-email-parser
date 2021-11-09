class zcl_fragment definition
  public
  final
  create public .

  public section.

    methods constructor
      importing
        iv_quoted     type abap_bool
        iv_first_line type string
        iv_headers    type abap_bool default abap_false.

    data: mv_signature type abap_bool value abap_false,
          mv_headers   type abap_bool,
          mv_hidden    type abap_bool value abap_false,
          mv_quoted    type abap_bool,
          mv_content   type string,
          mt_lines     type table of string.

    methods finish.

    methods content
      returning value(rv_content) type string.

  protected section.
  private section.

endclass.

class zcl_fragment implementation.

  method constructor.

    mv_signature = abap_false.
    mv_headers = iv_headers.
    mv_hidden = abap_false.
    mv_quoted = iv_quoted.
    mt_lines = value #( ( iv_first_line ) ).

  endmethod.

  method content.

    mv_content = condense( val  = mv_content
                           del  = |{ space }{ cl_abap_char_utilities=>newline }|
                           from = ``
                           to   = `` ).

    rv_content = mv_content.

  endmethod.

  method finish.

    zcl_parser_utils=>reverse_table( changing ct_string_table = mt_lines ).

    mv_content = concat_lines_of( table = mt_lines
                                  sep   = cl_abap_char_utilities=>newline ).
    clear mt_lines.

  endmethod.

endclass.