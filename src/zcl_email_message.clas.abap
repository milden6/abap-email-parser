class zcl_email_message definition
  public
  final
  create public .

  public section.

    constants: begin of mcs_regexs,
                 sig             type string value `(^--|^__|^-\w)|(^Sent from my (\w+\s*){1,3})`,
                 hdr             type string value `On.*wrote:$`,
                 quoted          type string value `(>+)`,
                 header          type string value `^\*?(От|Отправлено|Кому|Тема|From|Sent|To|Subject):\*? .+`,
                 multi_quote_hdr type string value `(?!On.*On\s.+wrote:)(On\s(.+)wrote:)`,
               end of mcs_regexs.

    methods constructor
      importing
        iv_text type string.

    methods read
      returning
        value(ro_message) type ref to zcl_email_message.

    methods reply
      returning value(rv_reply_text) type string.

    methods scan_line
      importing
        iv_text type string.

    methods finish_fragment.

    data: mt_fragments     type standard table of ref to zcl_fragment,
          mo_fragment      type ref to zcl_fragment,
          mv_text          type string,
          mv_found_visible type abap_bool.

  protected section.
  private section.

endclass.

class zcl_email_message implementation.

  method constructor.

    clear mt_fragments.
    clear mo_fragment.

    mv_text = replace( val  = iv_text
                       sub  = `\r\n`
                       with = `\n`
                       occ  =   0 ).

    mv_found_visible = abap_false.

  endmethod.

  method finish_fragment.

    if mo_fragment is bound.

      mo_fragment->finish( ).

      if mo_fragment->mv_headers = abap_true.

        mv_found_visible = abap_false.

        loop at mt_fragments assigning field-symbol(<ls_fragment>).
          <ls_fragment>->mv_hidden = abap_true.
        endloop.

      endif.

      if mv_found_visible = abap_false.

        if mo_fragment->mv_quoted = abap_true or
           mo_fragment->mv_headers = abap_true or
           mo_fragment->mv_signature = abap_true or
           strlen( mo_fragment->content(  ) ) = 0.

          mo_fragment->mv_hidden = abap_true.

        else.

          mv_found_visible = abap_true.

        endif.

      endif.

      append mo_fragment to mt_fragments.

    endif.

    clear mo_fragment.

  endmethod.

  method read.

    me->mv_found_visible = abap_false.

    data(lv_is_multi_quote_header) = match( val = me->mv_text regex = mcs_regexs-multi_quote_hdr ).

    if lv_is_multi_quote_header is not initial.

      data(lv_one_quote_header) = replace( val  = lv_is_multi_quote_header
                                           sub  = |\n|
                                           with = ``
                                           occ  = 0 ).

      mv_text = replace( val  = mv_text
                         sub  = lv_is_multi_quote_header
                         with = lv_one_quote_header ).

    endif.

    mv_text = replace( val   = mv_text
                       regex = `([^\n])(?=\n ?[_-]{7,})`
                       with  = `$1\n`
                       occ   =   0 ).

    split mv_text at cl_abap_char_utilities=>newline into table data(lt_lines).

    zcl_parser_utils=>reverse_table( changing ct_string_table = lt_lines ).

    loop at lt_lines assigning field-symbol(<ls_lines>).
      scan_line( <ls_lines> ).
    endloop.

    finish_fragment( ).

    zcl_parser_utils=>reverse_fragments_table( changing ct_fragment_table = mt_fragments ).

    ro_message = me.

  endmethod.


  method reply.

    loop at mt_fragments assigning field-symbol(<ls_fragment>).

      if <ls_fragment>->mv_hidden = abap_false and
         <ls_fragment>->mv_quoted = abap_false.

        if rv_reply_text is not initial.
          concatenate rv_reply_text cl_abap_char_utilities=>newline <ls_fragment>->mv_content into rv_reply_text.
        else.
          rv_reply_text = <ls_fragment>->mv_content.
        endif.

      endif.

    endloop.

  endmethod.


  method scan_line.

    data(lv_is_quote_header) = cond #( when match( val = iv_text regex = mcs_regexs-hdr ) <> space
                                       then abap_true
                                       else abap_false ).

    data(lv_is_quoted) = cond #( when match( val = iv_text regex = mcs_regexs-quoted ) <> space
                                 then abap_true
                                 else abap_false ).

    data(lv_is_header) = cond #( when match( val = iv_text regex = mcs_regexs-header ) <> space or lv_is_quote_header = abap_true
                                 then abap_true
                                 else abap_false ).

    if mo_fragment is bound and strlen( condense( val = iv_text ) ) = 0.

      if match( val   = condense( val = mo_fragment->mt_lines[ lines( mo_fragment->mt_lines ) ]  )
                regex = mcs_regexs-sig ) <> space.

        mo_fragment->mv_signature = abap_true.
        finish_fragment( ).

      endif.

    endif.

    if mo_fragment is bound and ( ( mo_fragment->mv_headers = lv_is_header and mo_fragment->mv_quoted = lv_is_quoted )
                               or ( mo_fragment->mv_quoted = abap_true and ( lv_is_quote_header = abap_true or strlen( condense( val = iv_text ) ) = 0 ) ) ).

      append iv_text to mo_fragment->mt_lines.

    else.

      finish_fragment(  ).

      mo_fragment = new #( iv_first_line = iv_text
                           iv_headers    = lv_is_header
                           iv_quoted     = lv_is_quoted ).

    endif.

  endmethod.
endclass.