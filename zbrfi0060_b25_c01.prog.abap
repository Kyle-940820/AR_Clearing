*&---------------------------------------------------------------------*
*& Include          ZBRFI0060_C01
*&---------------------------------------------------------------------*

CLASS LCL_EVENT_HANDLER DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS:
*      ON_TOOLBAR1 FOR EVENT TOOLBAR OF CL_GUI_ALV_GRID
*        IMPORTING E_OBJECT,
*
*      ON_USER_COMMAND1 FOR EVENT USER_COMMAND OF CL_GUI_ALV_GRID
*        IMPORTING E_UCOMM,

      ON_DOUBLE_CLICK FOR EVENT DOUBLE_CLICK OF CL_GUI_ALV_GRID
        IMPORTING ES_ROW_NO.
ENDCLASS.

CLASS LCL_EVENT_HANDLER IMPLEMENTATION.
*  METHOD ON_TOOLBAR1.
*    PERFORM HANDLE_TOOLBAR USING E_OBJECT.
*  ENDMETHOD.
*
*  METHOD ON_USER_COMMAND1.
*    PERFORM USER_COMMAND1 USING E_UCOMM.
*  ENDMETHOD.

  METHOD ON_DOUBLE_CLICK.
     PERFORM DISPLAY_BEL. " AVL1에서 행 더블클릭 시, 해당 고객사의 미결전표 리스트 취득.
  ENDMETHOD.
ENDCLASS.
