class zcl_email_reply_parser definition
  public
  final
  create public .

  public section.

    class-methods read
      importing
        iv_text        type string
      returning
        value(rv_text) type string.

    class-methods parse_reply
      importing
        iv_text        type string
      returning
        value(rv_text) type string.

  protected section.
  private section.

endclass.

class zcl_email_reply_parser implementation.

  method parse_reply.
    rv_text = new zcl_email_message( iv_text )->read( )->reply( ).
  endmethod.

  method read.
    rv_text = new zcl_email_message( iv_text )->read( )->mv_text.
  endmethod.

endclass.