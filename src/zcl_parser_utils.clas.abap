class zcl_parser_utils definition
  public
  final
  create public .

  public section.

    types: tt_string_table   type standard table of string with default key,
           tt_fragment_table type standard table of ref to zcl_fragment with default key.

    class-methods reverse_table
      changing
        ct_string_table type tt_string_table.

    class-methods reverse_fragments_table
      changing
        ct_fragment_table type tt_fragment_table.

    class-methods read_file
      importing
        iv_path          type string
      returning
        value(rv_string) type string.

  protected section.
  private section.

endclass.

class zcl_parser_utils implementation.

  method read_file.

    data: lt_line type table of string.

    cl_gui_frontend_services=>gui_upload( exporting filename = iv_path
                                                    codepage = '1504'
                                          changing data_tab = lt_line ).

    loop at lt_line assigning field-symbol(<lv_line>).

      if rv_string is not initial.
        concatenate rv_string cl_abap_char_utilities=>newline <lv_line> into rv_string.
      else.
        rv_string = <lv_line>.
      endif.

    endloop.

  endmethod.

  method reverse_fragments_table.

    data(lt_reverse_table) = value tt_fragment_table( ).
    data(lv_lines_count) = lines( ct_fragment_table ).

    do lines( ct_fragment_table ) times.

      append initial line to lt_reverse_table assigning field-symbol(<ls_reverse_table>).
      <ls_reverse_table> = ct_fragment_table[ lv_lines_count ].
      lv_lines_count = lv_lines_count - 1.

    enddo.

    ct_fragment_table = lt_reverse_table.

  endmethod.


  method reverse_table.

    data(lt_reverse_table) = value tt_string_table( ).
    data(lv_lines_count) = lines( ct_string_table ).

    do lines( ct_string_table ) times.

      append initial line to lt_reverse_table assigning field-symbol(<ls_reverse_table>).
      <ls_reverse_table> = ct_string_table[ lv_lines_count ].
      lv_lines_count = lv_lines_count - 1.

    enddo.

    ct_string_table = lt_reverse_table.

  endmethod.

endclass.