*&---------------------------------------------------------------------*
*& Include          ZBRFI0060_F01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form GET_DATA1
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM GET_DATA1 .
  DATA: LS_DATA1    TYPE ZVBFI0030,
        LT_DATA1    LIKE TABLE OF LS_DATA1,
        LS_DATA1_IN TYPE ZVBFI0030.

  DATA: LV_COUNT    TYPE I,
        LV_ALLMONEY TYPE ZEB_WRBTR,
        LV_CURRENCY TYPE ZEB_WAERS.

  CLEAR: GT_DISPLAY1, GS_DISPLAY1.

* 조회조건에 해당하는 전표 헤더 & 아이템 데이터 중, 반제처리가 되지 않은 매출전표 데이터 취득.
  SELECT *
    FROM ZVBFI0030
   WHERE BPCODE IN @SO_BPCO
     AND BUDAT IN @SO_BUDT
     AND BLART EQ 'DR'      " 고객 송장에 해당하는 전표유형.
     AND AUGBL EQ @SPACE
     AND ACODE EQ '10005'
   ORDER BY BPCODE
  INTO CORRESPONDING FIELDS OF TABLE @LT_DATA1.

  LOOP AT LT_DATA1 INTO LS_DATA1.
    LV_COUNT = LV_COUNT + 1.

* BPCODE 마다 미결금액 총합을 구해서 데이터 생성.
    IF NOT GS_DISPLAY1-BPCODE EQ LS_DATA1-BPCODE.
      CLEAR LV_ALLMONEY.

      GS_DISPLAY1-BPCODE = LS_DATA1-BPCODE.
      GS_DISPLAY1-CURRENCY = LS_DATA1-CURRENCY_F.

* 고객사명, 국가코드, 국가명 취득.
      SELECT SINGLE A~BPNAME, B~CTRYCODE, C~CTRYNAME
        FROM ZTBSD1051 AS A
        JOIN ZTBSD1050 AS B
          ON A~BPCODE EQ B~BPCODE
        JOIN ZTBSD1040 AS C
          ON B~CTRYCODE EQ C~CTRYCODE
       WHERE B~BPCODE EQ @GS_DISPLAY1-BPCODE
        INTO (@GS_DISPLAY1-BPNAME, @GS_DISPLAY1-CTRYCODE, @GS_DISPLAY1-CTRYNAME).

* 현재 BPCODE의 미결금액 총합을 LV_ALLMONEY에 할당.
      LOOP AT LT_DATA1 INTO LS_DATA1_IN WHERE BPCODE = GS_DISPLAY1-BPCODE.
        LV_ALLMONEY = LV_ALLMONEY + LS_DATA1_IN-HWRBTR.
      ENDLOOP.

      GS_DISPLAY1-ALLMONEY = LV_ALLMONEY.

      APPEND GS_DISPLAY1 TO GT_DISPLAY1.
    ENDIF.
  ENDLOOP.

* 각 화폐단위별 금액 모두 합산.
  LOOP AT GT_DISPLAY1 INTO GS_DISPLAY1 WHERE CURRENCY = 'KRW'.
    ZSBFI0030_BP-WHMONEY1 = ZSBFI0030_BP-WHMONEY1 + GS_DISPLAY1-ALLMONEY.
  ENDLOOP.
  ZSBFI0030_BP-CURRENCY1 = 'KRW'.

  READ TABLE GT_DISPLAY1 INTO GS_DISPLAY1 WITH KEY CURRENCY = 'USD'.
  ZSBFI0030_BP-WHMONEY2 = GS_DISPLAY1-ALLMONEY.
  ZSBFI0030_BP-CURRENCY2 = 'USD'.

  READ TABLE GT_DISPLAY1 INTO GS_DISPLAY1 WITH KEY CURRENCY = 'CNY'.
  ZSBFI0030_BP-WHMONEY3 = GS_DISPLAY1-ALLMONEY.
  ZSBFI0030_BP-CURRENCY3 = 'CNY'.

  READ TABLE GT_DISPLAY1 INTO GS_DISPLAY1 WITH KEY CURRENCY = 'EUR'.
  ZSBFI0030_BP-WHMONEY4 = GS_DISPLAY1-ALLMONEY.
  ZSBFI0030_BP-CURRENCY4 = 'EUR'.

  ZSBFI0030_BP-COUNT = LV_COUNT.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form CREATE_OBJECT_1
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM CREATE_OBJECT_1 .
  CREATE OBJECT GO_CUST1
    EXPORTING
      CONTAINER_NAME              = 'CUST1'
    EXCEPTIONS
      CNTL_ERROR                  = 1
      CNTL_SYSTEM_ERROR           = 2
      CREATE_ERROR                = 3
      LIFETIME_ERROR              = 4
      LIFETIME_DYNPRO_DYNPRO_LINK = 5
      OTHERS                      = 6.
  IF SY-SUBRC <> 0.
  ENDIF.

  CREATE OBJECT GO_ALV1
    EXPORTING
      I_PARENT          = GO_CUST1
    EXCEPTIONS
      ERROR_CNTL_CREATE = 1
      ERROR_CNTL_INIT   = 2
      ERROR_CNTL_LINK   = 3
      ERROR_DP_CREATE   = 4
      OTHERS            = 5.
  IF SY-SUBRC <> 0.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form SET_LAYOUT_ALV1
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SET_LAYOUT_ALV1 .
  CLEAR GS_LAYO1.

*  GS_LAYO1-GRID_TITLE = '인포레코드 자재 리스트'.
  GS_LAYO1-ZEBRA = 'X'.
  GS_LAYO1-CWIDTH_OPT = 'A'.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form SET_FIELDCAT_ALV1
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SET_FIELDCAT_ALV1 .
  CLEAR GS_FCAT1.

  GS_FCAT1-FIELDNAME = 'BPCODE'.
  GS_FCAT1-JUST = 'C'.
  GS_FCAT1-KEY = 'X'.
  GS_FCAT1-COLTEXT = '고객사 코드'.
  APPEND GS_FCAT1 TO GT_FCAT1.
  CLEAR GS_FCAT1.

  GS_FCAT1-FIELDNAME = 'BPNAME'.
  GS_FCAT1-JUST = 'C'.
  GS_FCAT1-COLTEXT = '고객사 명'.
  APPEND GS_FCAT1 TO GT_FCAT1.
  CLEAR GS_FCAT1.

  GS_FCAT1-FIELDNAME = 'CTRYCODE'.
  GS_FCAT1-JUST = 'C'.
  APPEND GS_FCAT1 TO GT_FCAT1.
  CLEAR GS_FCAT1.

  GS_FCAT1-FIELDNAME = 'CTRYNAME'.
  GS_FCAT1-JUST = 'C'.
  APPEND GS_FCAT1 TO GT_FCAT1.
  CLEAR GS_FCAT1.

  GS_FCAT1-FIELDNAME = 'ALLMONEY'.
  GS_FCAT1-JUST = 'R'.
  APPEND GS_FCAT1 TO GT_FCAT1.
  CLEAR GS_FCAT1.

  GS_FCAT1-FIELDNAME = 'CURRENCY'.
  GS_FCAT1-JUST = 'L'.
  APPEND GS_FCAT1 TO GT_FCAT1.
  CLEAR GS_FCAT1.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form SET_EVENT_ALV1
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SET_EVENT_ALV1 .
*  SET HANDLER LCL_EVENT_HANDLER=>ON_TOOLBAR1 FOR GO_ALV1.
*  SET HANDLER LCL_EVENT_HANDLER=>ON_USER_COMMAND1 FOR GO_ALV1.
  SET HANDLER LCL_EVENT_HANDLER=>ON_DOUBLE_CLICK FOR GO_ALV1.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form INIT_ALV1
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM INIT_ALV1 .
  DATA: LS_EXCLUD TYPE UI_FUNC,
        LT_EXCLUD TYPE UI_FUNCTIONS.

  LS_EXCLUD = CL_GUI_ALV_GRID=>MC_FC_EXCL_ALL.
  APPEND LS_EXCLUD TO LT_EXCLUD.

  CALL METHOD GO_ALV1->SET_TABLE_FOR_FIRST_DISPLAY
    EXPORTING
      I_STRUCTURE_NAME              = 'ZSBFI0030_ALV1'
*     IS_VARIANT                    = GS_VARIANT
*     I_SAVE                        = 'A'
*     I_DEFAULT                     =
      IS_LAYOUT                     = GS_LAYO1
      IT_TOOLBAR_EXCLUDING          = LT_EXCLUD
    CHANGING
      IT_OUTTAB                     = GT_DISPLAY1
      IT_FIELDCATALOG               = GT_FCAT1
*     IT_SORT                       =
*     IT_FILTER                     =
    EXCEPTIONS
      INVALID_PARAMETER_COMBINATION = 1
      PROGRAM_ERROR                 = 2
      TOO_MANY_LINES                = 3
      OTHERS                        = 4.
  IF SY-SUBRC <> 0.
    MESSAGE S205 DISPLAY LIKE 'E'.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form REFRESH_ALV1
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM REFRESH_ALV1 .
* ALV1 DATA 바뀔 시 최적화 및 REFRESH.
  DATA: LS_STABLE TYPE LVC_S_STBL.

  CALL METHOD GO_ALV1->GET_FRONTEND_LAYOUT
    IMPORTING
      ES_LAYOUT = GS_LAYO1.

  GS_LAYO1-CWIDTH_OPT = ABAP_ON.

  CALL METHOD GO_ALV1->SET_FRONTEND_LAYOUT
    EXPORTING
      IS_LAYOUT = GS_LAYO1.

  CALL METHOD GO_ALV1->REFRESH_TABLE_DISPLAY
    EXPORTING
      IS_STABLE = LS_STABLE.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form HANDLE_TOOLBAR
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> E_OBJECT
*&---------------------------------------------------------------------*
FORM HANDLE_TOOLBAR  USING PV_OBJECT TYPE REF TO CL_ALV_EVENT_TOOLBAR_SET.
  DATA LS_BUTTON LIKE LINE OF PV_OBJECT->MT_TOOLBAR.

* 구분자 추가.
  CLEAR LS_BUTTON.
  LS_BUTTON-BUTN_TYPE = 3.
  APPEND LS_BUTTON TO PV_OBJECT->MT_TOOLBAR.
  CLEAR LS_BUTTON.

* 버튼 'DEL' 추가.
  LS_BUTTON-BUTN_TYPE = 0. " 일반 버튼(NORMAL BUTTON)
  LS_BUTTON-TEXT      = ' 미결전표 조회 '.
  LS_BUTTON-FUNCTION  = 'DIS'.
  APPEND LS_BUTTON TO PV_OBJECT->MT_TOOLBAR.
  CLEAR LS_BUTTON.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form USER_COMMAND1
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> E_UCOMM
*&---------------------------------------------------------------------*
FORM USER_COMMAND1  USING    PV_UCOMM.
  CASE PV_UCOMM.
    WHEN 'DIS'.
      PERFORM DISPLAY_BEL.
  ENDCASE.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form DISPLAY_BEL
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM DISPLAY_BEL .
  DATA : LV_ANSWER.

  CLEAR: GT_ROW1, GS_ROW1, GS_DISPLAY1.

  CALL METHOD GO_ALV1->GET_SELECTED_ROWS
    IMPORTING
      ET_ROW_NO = GT_ROW1.

* 선택한 행 정보.
  READ TABLE GT_ROW1 INTO GS_ROW1 INDEX 1.
  READ TABLE GT_DISPLAY1 INTO GS_DISPLAY1 INDEX GS_ROW1-ROW_ID.

  IF GS_DISPLAY1 IS INITIAL. " 데이터 선택안하고 눌렀을 때.
    MESSAGE S431 DISPLAY LIKE 'E'. " 조회할 고객사를 선택해주세요.
    CLEAR: ZSBFI0030_BP-WHMONEY1,
           ZSBFI0030_BP-WHMONEY2,
           ZSBFI0030_BP-WHMONEY3,
           ZSBFI0030_BP-WHMONEY4.

    CALL METHOD CL_GUI_CFW=>SET_NEW_OK_CODE " 삭제 후 PAI-PBO 동작해서 ALV2 REFRESH.
      EXPORTING
        NEW_CODE = 'ENTER'.

  ELSE. " 데이터를 선택하고 눌렀을 때.

    PERFORM DISPLAY_BELL.
    PERFORM DISPLAY_BP.
    GV_MODE = 0.
    CLEAR: ZSBFI0030_BP-WHMONEY1,
           ZSBFI0030_BP-WHMONEY2,
           ZSBFI0030_BP-WHMONEY3,
           ZSBFI0030_BP-WHMONEY4.

    CALL METHOD CL_GUI_CFW=>SET_NEW_OK_CODE " 삭제 후 PAI-PBO 동작해서 ALV2 REFRESH.
      EXPORTING
        NEW_CODE = 'ENTER'.

    MESSAGE S432. " 성공적으로 조회하였습니다.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form DISPLAY_BELL
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM DISPLAY_BELL .
* 조회조건에 해당하는 전표 헤더 & 아이템 데이터 ALV2 ITAB 할당.
  CLEAR: GT_DISPLAY2, GS_DISPLAY2.

  SELECT *
    FROM ZVBFI0030
   WHERE BPCODE EQ @GS_DISPLAY1-BPCODE
     AND BUDAT IN @SO_BUDT
     AND BLART EQ 'DR'      " 고객 송장에 해당하는 전표유형.
     AND AUGBL EQ @SPACE
  INTO CORRESPONDING FIELDS OF TABLE @GT_DISPLAY2.

* DATA 정렬.
  SORT GT_DISPLAY2 BY DDATE BELNR ASCENDING SHKZG DESCENDING.

  LOOP AT GT_DISPLAY2 INTO GS_DISPLAY2.
* 입금예정일 = 전기일 + 지급조건_지급일.
    CASE GS_DISPLAY2-ZTERM.
      WHEN 'Z001'.
        GS_DISPLAY2-DDATE = GS_DISPLAY2-BUDAT + 30.
      WHEN 'Z002'.
        GS_DISPLAY2-DDATE = GS_DISPLAY2-BUDAT + 60.
    ENDCASE.

* BPNAME DATA.
    SELECT SINGLE BPNAME
      FROM ZTBSD1051
     WHERE BPCODE EQ @GS_DISPLAY2-BPCODE
      INTO @GS_DISPLAY2-BPNAME.

* 입금예정일 날짜가 지난건 빨간색 상태표시.
    IF GS_DISPLAY2-DDATE < SY-DATUM.
      GS_DISPLAY2-EXCP = '1'.
    ENDIF.

    MODIFY GT_DISPLAY2 FROM GS_DISPLAY2.
    CLEAR GS_DISPLAY2.
  ENDLOOP.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form SET_ALV2
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SET_ALV2 .
  IF GO_CUST2 IS INITIAL.
    PERFORM CREATE_OBJECT_2.
    PERFORM SET_LAYOUT_ALV2.
    PERFORM SET_FIELDCAT_ALV2.
*    PERFORM SET_EVENT_ALV2.
    PERFORM INIT_ALV2.

  ELSE.
    PERFORM REFRESH_ALV2.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form CREATE_OBJECT_2
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM CREATE_OBJECT_2 .
  CREATE OBJECT GO_CUST2
    EXPORTING
      CONTAINER_NAME              = 'CUST2'
    EXCEPTIONS
      CNTL_ERROR                  = 1
      CNTL_SYSTEM_ERROR           = 2
      CREATE_ERROR                = 3
      LIFETIME_ERROR              = 4
      LIFETIME_DYNPRO_DYNPRO_LINK = 5
      OTHERS                      = 6.
  IF SY-SUBRC <> 0.
  ENDIF.

  CREATE OBJECT GO_ALV2
    EXPORTING
      I_PARENT          = GO_CUST2
    EXCEPTIONS
      ERROR_CNTL_CREATE = 1
      ERROR_CNTL_INIT   = 2
      ERROR_CNTL_LINK   = 3
      ERROR_DP_CREATE   = 4
      OTHERS            = 5.
  IF SY-SUBRC <> 0.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form SET_LAYOUT_ALV2
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SET_LAYOUT_ALV2 .
  CLEAR: GS_LAYO2.

  GS_LAYO2-GRID_TITLE = '미결전표 리스트'.
  GS_LAYO2-ZEBRA = 'X'.
  GS_LAYO2-CWIDTH_OPT = 'A'.
  GS_LAYO2-EXCP_FNAME = 'EXCP'.
  GS_LAYO2-EXCP_LED = 'X'.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form SET_FIELDCAT_ALV2
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SET_FIELDCAT_ALV2 .
  CLEAR GS_FCAT2.

  GS_FCAT2-FIELDNAME = 'EXCP'.
  GS_FCAT2-JUST = 'C'.
  GS_FCAT2-COLTEXT = '입금지연'.
  APPEND GS_FCAT2 TO GT_FCAT2.
  CLEAR GS_FCAT2.

  GS_FCAT2-FIELDNAME = 'DDATE'.
  GS_FCAT2-JUST = 'C'.
  GS_FCAT2-COLTEXT = '입금 예정일'.
  APPEND GS_FCAT2 TO GT_FCAT2.
  CLEAR GS_FCAT2.

  GS_FCAT2-FIELDNAME = 'BELNR'.
  GS_FCAT2-JUST = 'C'.
  GS_FCAT2-KEY = 'X'.
  APPEND GS_FCAT2 TO GT_FCAT2.
  CLEAR GS_FCAT2.

  GS_FCAT2-FIELDNAME = 'BUDAT'.
  GS_FCAT2-JUST = 'C'.
  APPEND GS_FCAT2 TO GT_FCAT2.
  CLEAR GS_FCAT2.

  GS_FCAT2-FIELDNAME = 'BPCODE'.
  GS_FCAT2-JUST = 'C'.
  GS_FCAT2-COLTEXT = '고객사 코드'.
  APPEND GS_FCAT2 TO GT_FCAT2.
  CLEAR GS_FCAT2.

  GS_FCAT2-FIELDNAME = 'BPNAME'.
  GS_FCAT2-JUST = 'C'.
  GS_FCAT2-COLTEXT = '고객사 명'.
  APPEND GS_FCAT2 TO GT_FCAT2.
  CLEAR GS_FCAT2.

  GS_FCAT2-FIELDNAME = 'ZTERM'.
  GS_FCAT2-JUST = 'C'.
  APPEND GS_FCAT2 TO GT_FCAT2.
  CLEAR GS_FCAT2.

  GS_FCAT2-FIELDNAME = 'BUZEI'.
  GS_FCAT2-JUST = 'C'.
  GS_FCAT2-KEY = 'X'.
  APPEND GS_FCAT2 TO GT_FCAT2.
  CLEAR GS_FCAT2.

  GS_FCAT2-FIELDNAME = 'SHKZG'.
  GS_FCAT2-JUST = 'C'.
  GS_FCAT2-COLTEXT = '차변/대변'.
  APPEND GS_FCAT2 TO GT_FCAT2.
  CLEAR GS_FCAT2.

  GS_FCAT2-FIELDNAME = 'ACODE'.
  GS_FCAT2-JUST = 'C'.
  APPEND GS_FCAT2 TO GT_FCAT2.
  CLEAR GS_FCAT2.

  GS_FCAT2-FIELDNAME = 'ANAME'.
  GS_FCAT2-JUST = 'C'.
  APPEND GS_FCAT2 TO GT_FCAT2.
  CLEAR GS_FCAT2.

  GS_FCAT2-FIELDNAME = 'WRBTR'.
  GS_FCAT2-JUST = 'R'.
  APPEND GS_FCAT2 TO GT_FCAT2.
  CLEAR GS_FCAT2.

  GS_FCAT2-FIELDNAME = 'CURRENCY'.
  GS_FCAT2-JUST = 'L'.
  APPEND GS_FCAT2 TO GT_FCAT2.
  CLEAR GS_FCAT2.

  GS_FCAT2-FIELDNAME = 'HWRBTR'.
  GS_FCAT2-JUST = 'R'.
  APPEND GS_FCAT2 TO GT_FCAT2.
  CLEAR GS_FCAT2.

  GS_FCAT2-FIELDNAME = 'CURRENCY_F'.
  GS_FCAT2-JUST = 'L'.
  APPEND GS_FCAT2 TO GT_FCAT2.
  CLEAR GS_FCAT2.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form INIT_ALV2
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM INIT_ALV2 .
* DIALOG ALV DISPLAY.
  GS_VARIANT-REPORT = SY-CPROG.
  GS_VARIANT-VARIANT = '/LAYOUT2'.

  CALL METHOD GO_ALV2->SET_TABLE_FOR_FIRST_DISPLAY
    EXPORTING
      I_STRUCTURE_NAME              = 'ZSBFI0030_ALV2'
      IS_VARIANT                    = GS_VARIANT
      I_SAVE                        = 'A'
*     I_DEFAULT                     = 'X'
      IS_LAYOUT                     = GS_LAYO2
*     IT_TOOLBAR_EXCLUDING          = LT_EXCLUD
    CHANGING
      IT_OUTTAB                     = GT_DISPLAY2
      IT_FIELDCATALOG               = GT_FCAT2
*     IT_SORT                       = GT_SORT2
*     IT_FILTER                     =
    EXCEPTIONS
      INVALID_PARAMETER_COMBINATION = 1
      PROGRAM_ERROR                 = 2
      TOO_MANY_LINES                = 3
      OTHERS                        = 4.
  IF SY-SUBRC <> 0.
    MESSAGE S205 DISPLAY LIKE 'E'.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form REFRESH_ALV2
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM REFRESH_ALV2 .
  DATA: LS_STABLE TYPE LVC_S_STBL.

  CALL METHOD GO_ALV2->GET_FRONTEND_LAYOUT
    IMPORTING
      ES_LAYOUT = GS_LAYO2.


  GS_LAYO2-CWIDTH_OPT = ABAP_ON.

  CALL METHOD GO_ALV2->SET_FRONTEND_LAYOUT
    EXPORTING
      IS_LAYOUT = GS_LAYO2.

  CALL METHOD GO_ALV2->REFRESH_TABLE_DISPLAY
    EXPORTING
      IS_STABLE = LS_STABLE.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form DISPLAY_BP
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM DISPLAY_BP .
*  GS_DISPLAY1-BPCODE

  SELECT SINGLE *
    FROM ZTBSD1050 AS A
    JOIN ZTBSD1051 AS B
      ON A~BPCODE EQ B~BPCODE
    JOIN ZTBSD1040 AS C
      ON A~CTRYCODE EQ C~CTRYCODE
    JOIN ZTBFI0040 AS D
      ON A~ZTERM EQ D~ZTERM
   WHERE A~BPCODE EQ @GS_DISPLAY1-BPCODE
    INTO CORRESPONDING FIELDS OF @ZSBFI0030_BP.

  SELECT SINGLE CURRENCY
    FROM ZTBSD1040
   WHERE CTRYCODE EQ @GS_DISPLAY1-CTRYCODE
    INTO @ZSBFI0030_BP-CURRCODE.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form CLEAR_BEL
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM CLEAR_BEL .
  DATA : LV_ANSWER.

  CLEAR: GT_ROW2, GS_ROW2, GS_DISPLAY2.

  IF GO_CUST2 IS INITIAL. " 미결전표 조회 안하고 눌렀을 때.
    MESSAGE S434 DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  CALL METHOD GO_ALV2->GET_SELECTED_ROWS
    IMPORTING
      ET_ROW_NO = GT_ROW2.

* 선택한 행 정보.
  READ TABLE GT_ROW2 INTO GS_ROW2 INDEX 1.
  READ TABLE GT_DISPLAY2 INTO GS_DISPLAY2 INDEX GS_ROW2-ROW_ID.

  IF GS_DISPLAY2 IS INITIAL. " 행 선택 안하고 버튼 눌렀을 때.
    MESSAGE S434 DISPLAY LIKE 'E'.
    RETURN.

  ELSE. " 행 선택 하고 버튼 눌렀을 때.
    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
        TITLEBAR              = TEXT-T02 " 반제처리 확인
        TEXT_QUESTION         = TEXT-Q02 " 반제처리를 진행하시겠습니까?
        TEXT_BUTTON_1         = 'YES'
        ICON_BUTTON_1         = 'ICON_OKAY'
        TEXT_BUTTON_2         = 'NO'
        ICON_BUTTON_2         = 'ICON_CANCEL'
        DEFAULT_BUTTON        = '1'
        DISPLAY_CANCEL_BUTTON = ''
      IMPORTING
        ANSWER                = LV_ANSWER.

    IF LV_ANSWER = '1'. " 반제처리 진행 YES
      MESSAGE S436. " 반제처리 내용을 확인해주세요.

      IF GS_DISPLAY2-CURRENCY_F = 'KRW'. " 국내 고객사 일때.
        CALL SCREEN 110
          STARTING AT 30 10.

      ELSE. " 해외 고객사 일때.
        CALL SCREEN 120
          STARTING AT 30 10.
      ENDIF.
    ELSE. " 반제처리 진행 NO
      MESSAGE S435. " 반제처리를 취소하였습니다.

    ENDIF.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form SAVE_BEL1
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SAVE_BEL1 .
  DATA: LS_DATA3  TYPE ZVBFI0030,
        LT_DATA3  LIKE TABLE OF LS_DATA3,
        LV_NR     TYPE NUM10,
        LV_ANSWER.

  DATA: LS_DATA4 TYPE ZVBFI0030,
        LT_DATA4 LIKE TABLE OF LS_DATA4.

  DATA: LS_ZTBFI0030 TYPE ZTBFI0030,
        LS_ZTBFI0031 TYPE ZTBFI0031.

  CLEAR: GT_DISPLAY3, GS_DISPLAY3.


  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      TITLEBAR              = TEXT-T03 " 반제처리 확인.
      TEXT_QUESTION         = TEXT-Q03 " 반제처리를 하시겠습니까?
      TEXT_BUTTON_1         = 'YES'
      ICON_BUTTON_1         = 'ICON_OKAY'
      TEXT_BUTTON_2         = 'NO'
      ICON_BUTTON_2         = 'ICON_CANCEL'
      DEFAULT_BUTTON        = '1'
      DISPLAY_CANCEL_BUTTON = ''
    IMPORTING
      ANSWER                = LV_ANSWER.

  IF LV_ANSWER = '1'. " 반제처리 YES
* 반제처리하는 전표번호에 해당하는 전표 헤더 & 아이템 데이터 취득.
    SELECT *
    FROM ZVBFI0030
   WHERE BELNR EQ @GS_DISPLAY2-BELNR
    INTO CORRESPONDING FIELDS OF TABLE @LT_DATA3.

    SORT LT_DATA3 BY SHKZG DESCENDING. " 외상매출금이 위로 오게.

* NUMBER RANGE 호출.
    CALL FUNCTION 'NUMBER_GET_NEXT'
      EXPORTING
        NR_RANGE_NR             = '01'
        OBJECT                  = 'ZBBFI0030'
      IMPORTING
        NUMBER                  = LV_NR
      EXCEPTIONS
        INTERVAL_NOT_FOUND      = 1
        NUMBER_RANGE_NOT_INTERN = 2
        OBJECT_NOT_FOUND        = 3
        QUANTITY_IS_0           = 4
        QUANTITY_IS_NOT_1       = 5
        INTERVAL_OVERFLOW       = 6
        BUFFER_OVERFLOW         = 7
        OTHERS                  = 8.
    IF SY-SUBRC <> 0.
    ENDIF.

* 반제처리하는 전표번호의 아이템들에 반제전표, 반제처리일 UPDATE.
* TP TABLE, LT_DATA3 에 UPDATE.
    LOOP AT LT_DATA3 INTO LS_DATA3.
      LS_DATA3-AUGBL = LV_NR.
      LS_DATA3-AUGDT = SY-DATUM.

      MOVE-CORRESPONDING LS_DATA3 TO LS_ZTBFI0031.

* 전표 아이템 TP TABLE UPDATE.
      UPDATE ZTBFI0031 FROM LS_ZTBFI0031.

      MODIFY LT_DATA3 FROM LS_DATA3.
    ENDLOOP.

    MOVE-CORRESPONDING LT_DATA3 TO GT_DISPLAY3. " 미결전표 2줄 GT_DISPLAY3에 할당.
    MOVE-CORRESPONDING LT_DATA3 TO LT_DATA4.

* BPNAME 취득.
    SELECT SINGLE BPNAME
    FROM ZTBSD1051
   WHERE BPCODE EQ @LS_DATA3-BPCODE
    INTO @DATA(LV_BPNAME).

    LOOP AT GT_DISPLAY3 INTO GS_DISPLAY3.
      GS_DISPLAY3-BPNAME = LV_BPNAME.
      MODIFY GT_DISPLAY3 FROM GS_DISPLAY3.
    ENDLOOP.

* EMPID 취득.
    SELECT SINGLE EMPID
      FROM ZTBSD1030
     WHERE LOGID EQ @SY-UNAME
      INTO @DATA(LV_EMPID).

* 반제전표 DATA CREATE.
    LOOP AT LT_DATA4 INTO LS_DATA4.
      CLEAR GS_DISPLAY3.

      IF SY-TABIX = 1. " 보통예금에 해당하는 DATA CREATE
        LS_DATA4-BELNR = LV_NR. " 전표번호 채번된 번호로 할당.
        LS_DATA4-ACODE = '10003'.
        LS_DATA4-ANAME = '보통예금'.
        LS_DATA4-ITTXT = |{ LV_BPNAME }| && '매출대금 입금'.
        LS_DATA4-AUGBL = SPACE.
        LS_DATA4-AUGDT = SPACE.
        LS_DATA4-BLART = 'DZ'.
        LS_DATA4-BUDAT = SY-DATUM.
        LS_DATA4-BLDAT = SY-DATUM.
        LS_DATA4-USNAM = LV_EMPID.

      ELSEIF SY-TABIX = 2. " 외상매출금에 해당하는 DATA CREATE
        LS_DATA4-BELNR = LV_NR. " 전표번호 채번된 번호로 할당.
        LS_DATA4-ACODE = '10005'.
        LS_DATA4-ANAME = '외상매출금'.
        LS_DATA4-ITTXT = |{ LV_BPNAME }| && '매출대금 입금'.
        LS_DATA4-AUGBL = SPACE.
        LS_DATA4-AUGDT = SPACE.
        LS_DATA4-BLART = 'DZ'.
        LS_DATA4-BUDAT = SY-DATUM.
        LS_DATA4-BLDAT = SY-DATUM.
        LS_DATA4-USNAM = LV_EMPID.
      ENDIF.

      MOVE-CORRESPONDING LS_DATA4 TO GS_DISPLAY3.
      GS_DISPLAY3-BPNAME = LV_BPNAME.
      APPEND GS_DISPLAY3 TO GT_DISPLAY3. " 반제전표 2줄 GT_DISPLAY3에 생성.

      MOVE-CORRESPONDING LS_DATA4 TO LS_ZTBFI0030.
      MOVE-CORRESPONDING LS_DATA4 TO LS_ZTBFI0031.

      LS_ZTBFI0030-STAMP_DATE_F = SY-DATUM.
      LS_ZTBFI0030-STAMP_TIME_F = SY-UZEIT.
      LS_ZTBFI0030-STAMP_USER_F = LV_EMPID.

      INSERT ZTBFI0030 FROM LS_ZTBFI0030.

      LS_ZTBFI0031-STAMP_DATE_F = SY-DATUM.
      LS_ZTBFI0031-STAMP_TIME_F = SY-UZEIT.
      LS_ZTBFI0031-STAMP_USER_F = LV_EMPID.

      INSERT ZTBFI0031 FROM LS_ZTBFI0031.

      MODIFY LT_DATA4 FROM LS_DATA4.

    ENDLOOP.

    PERFORM DISPLAY_BELL2. " 반제처리 완료한 미결전표들을 ALV2 에서 삭제.
    PERFORM REFRESH_ALV2. " ALV2 REFRESH.
    PERFORM SET_ALV3.
    MESSAGE S437 WITH LV_NR. " 반제를 성공적으로 처리하였습니다.

  ELSE. " 반제처리 NO.
    MESSAGE S435. " 반제처리를 취소하였습니다.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form SET_ALV3
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SET_ALV3 .
  IF GO_CUST3 IS INITIAL.
    PERFORM CREATE_OBJECT_3.
    PERFORM SET_LAYOUT_ALV3.
    PERFORM SET_FIELDCAT_ALV3.
*    PERFORM SET_SORT_ALV3.
*    PERFORM SET_EVENT_ALV3.
    PERFORM INIT_ALV3.

  ELSE.
    PERFORM REFRESH_ALV3.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form CREATE_OBJECT_3
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM CREATE_OBJECT_3 .
  CREATE OBJECT GO_CUST3
    EXPORTING
      CONTAINER_NAME              = 'CUST3'
    EXCEPTIONS
      CNTL_ERROR                  = 1
      CNTL_SYSTEM_ERROR           = 2
      CREATE_ERROR                = 3
      LIFETIME_ERROR              = 4
      LIFETIME_DYNPRO_DYNPRO_LINK = 5
      OTHERS                      = 6.
  IF SY-SUBRC <> 0.
  ENDIF.

  CREATE OBJECT GO_ALV3
    EXPORTING
      I_PARENT          = GO_CUST3
    EXCEPTIONS
      ERROR_CNTL_CREATE = 1
      ERROR_CNTL_INIT   = 2
      ERROR_CNTL_LINK   = 3
      ERROR_DP_CREATE   = 4
      OTHERS            = 5.
  IF SY-SUBRC <> 0.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form SET_LAYOUT_ALV3
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SET_LAYOUT_ALV3 .
  CLEAR GS_LAYO3.

  GS_LAYO3-GRID_TITLE = '반제처리 결과 확인'.
  GS_LAYO3-ZEBRA = 'X'.
  GS_LAYO3-CWIDTH_OPT = 'A'.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form SET_FIELDCAT_ALV3
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SET_FIELDCAT_ALV3 .
  CLEAR GS_FCAT3.

  GS_FCAT3-FIELDNAME = 'BELNR'.
  GS_FCAT3-JUST = 'C'.
  GS_FCAT3-KEY = 'X'.
  APPEND GS_FCAT3 TO GT_FCAT3.
  CLEAR GS_FCAT3.

  GS_FCAT3-FIELDNAME = 'BUDAT'.
  GS_FCAT3-JUST = 'C'.
  APPEND GS_FCAT3 TO GT_FCAT3.
  CLEAR GS_FCAT3.

  GS_FCAT3-FIELDNAME = 'BPCODE'.
  GS_FCAT3-JUST = 'C'.
  GS_FCAT3-COLTEXT = '고객사 코드'.
  APPEND GS_FCAT3 TO GT_FCAT3.
  CLEAR GS_FCAT3.

  GS_FCAT3-FIELDNAME = 'BPNAME'.
  GS_FCAT3-JUST = 'C'.
  GS_FCAT3-COLTEXT = '고객사 명'.
  APPEND GS_FCAT3 TO GT_FCAT3.
  CLEAR GS_FCAT3.

  GS_FCAT3-FIELDNAME = 'ZTERM'.
  GS_FCAT3-JUST = 'C'.
  APPEND GS_FCAT3 TO GT_FCAT3.
  CLEAR GS_FCAT3.

  GS_FCAT3-FIELDNAME = 'BUZEI'.
  GS_FCAT3-JUST = 'C'.
  GS_FCAT3-KEY = 'X'.
  APPEND GS_FCAT3 TO GT_FCAT3.
  CLEAR GS_FCAT3.

  GS_FCAT3-FIELDNAME = 'SHKZG'.
  GS_FCAT3-JUST = 'C'.
  APPEND GS_FCAT3 TO GT_FCAT3.
  CLEAR GS_FCAT3.

  GS_FCAT3-FIELDNAME = 'ACODE'.
  GS_FCAT3-JUST = 'C'.
  APPEND GS_FCAT3 TO GT_FCAT3.
  CLEAR GS_FCAT3.

  GS_FCAT3-FIELDNAME = 'ANAME'.
  GS_FCAT3-JUST = 'C'.
  APPEND GS_FCAT3 TO GT_FCAT3.
  CLEAR GS_FCAT3.

  GS_FCAT3-FIELDNAME = 'WRBTR'.
  GS_FCAT3-JUST = 'R'.
  APPEND GS_FCAT3 TO GT_FCAT3.
  CLEAR GS_FCAT3.

  GS_FCAT3-FIELDNAME = 'CURRENCY'.
  GS_FCAT3-JUST = 'L'.
  APPEND GS_FCAT3 TO GT_FCAT3.
  CLEAR GS_FCAT3.

  GS_FCAT3-FIELDNAME = 'HWRBTR'.
  GS_FCAT3-JUST = 'R'.
  APPEND GS_FCAT3 TO GT_FCAT3.
  CLEAR GS_FCAT3.

  GS_FCAT3-FIELDNAME = 'CURRENCY_F'.
  GS_FCAT3-JUST = 'L'.
  APPEND GS_FCAT3 TO GT_FCAT3.
  CLEAR GS_FCAT3.

  GS_FCAT3-FIELDNAME = 'AUGBL'.
  GS_FCAT3-JUST = 'C'.
  APPEND GS_FCAT3 TO GT_FCAT3.
  CLEAR GS_FCAT3.

  GS_FCAT3-FIELDNAME = 'AUGDT'.
  GS_FCAT3-JUST = 'C'.
  APPEND GS_FCAT3 TO GT_FCAT3.
  CLEAR GS_FCAT3.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form INIT_ALV3
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM INIT_ALV3 .
  " DIALOG ALV DISPLAY.
  GS_VARIANT-REPORT = SY-CPROG.
  GS_VARIANT-VARIANT = '/LAYOUT3'.

  CALL METHOD GO_ALV3->SET_TABLE_FOR_FIRST_DISPLAY
    EXPORTING
      I_STRUCTURE_NAME              = 'ZSBFI0030_ALV3'
      IS_VARIANT                    = GS_VARIANT
      I_SAVE                        = 'A'
*     I_DEFAULT                     = 'X'
      IS_LAYOUT                     = GS_LAYO3
*     IT_TOOLBAR_EXCLUDING          = LT_EXCLUD
    CHANGING
      IT_OUTTAB                     = GT_DISPLAY3
      IT_FIELDCATALOG               = GT_FCAT3
*     IT_SORT                       = GT_SORT3
*     IT_FILTER                     =
    EXCEPTIONS
      INVALID_PARAMETER_COMBINATION = 1
      PROGRAM_ERROR                 = 2
      TOO_MANY_LINES                = 3
      OTHERS                        = 4.
  IF SY-SUBRC <> 0.
    MESSAGE S205 DISPLAY LIKE 'E'.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form REFRESH_ALV3
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM REFRESH_ALV3 .
  DATA: LS_STABLE TYPE LVC_S_STBL.

  CALL METHOD GO_ALV3->GET_FRONTEND_LAYOUT
    IMPORTING
      ES_LAYOUT = GS_LAYO3.

  GS_LAYO3-CWIDTH_OPT = ABAP_ON.

  CALL METHOD GO_ALV3->SET_FRONTEND_LAYOUT
    EXPORTING
      IS_LAYOUT = GS_LAYO3.

  CALL METHOD GO_ALV3->REFRESH_TABLE_DISPLAY
    EXPORTING
      IS_STABLE = LS_STABLE.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form CLEAR_BP
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM CLEAR_BP .
  CLEAR: ZSBFI0030_BP-COUNT,
         ZSBFI0030_BP-WHMONEY1,
         ZSBFI0030_BP-WHMONEY2,
         ZSBFI0030_BP-WHMONEY3,
         ZSBFI0030_BP-WHMONEY4,
         ZSBFI0030_BP-CURRENCY1,
         ZSBFI0030_BP-CURRENCY2,
         ZSBFI0030_BP-CURRENCY3,
         ZSBFI0030_BP-CURRENCY4.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form DISPLAY_BELL2
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM DISPLAY_BELL2 .
  DATA: LV_BELNR TYPE C LENGTH 10.

  READ TABLE GT_DISPLAY3 INTO GS_DISPLAY3 INDEX 1.

  LV_BELNR = GS_DISPLAY3-BELNR.

  LOOP AT GT_DISPLAY2 INTO GS_DISPLAY2.
    DELETE GT_DISPLAY2 WHERE BELNR = LV_BELNR.
  ENDLOOP.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form SAVE_BEL2
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SAVE_BEL2 .
  DATA: LS_DATA3  TYPE ZVBFI0030,
        LT_DATA3  LIKE TABLE OF LS_DATA3,
        LV_NR     TYPE NUM10,
        LV_ANSWER.

  DATA: LS_DATA4 TYPE ZVBFI0030,
        LT_DATA4 LIKE TABLE OF LS_DATA4.

  DATA: LV_SHKZG TYPE ZEB_SHKZG,
        LV_ACODE TYPE ZEB_ACODE,
        LV_ANAME TYPE ZEB_ANAME,
        LV_TTB1  TYPE NUM10,
        LV_TTB2  TYPE NUM10.


  DATA: LS_ZTBFI0030 TYPE ZTBFI0030,
        LS_ZTBFI0031 TYPE ZTBFI0031.

  CLEAR: GT_DISPLAY3, GS_DISPLAY3.


  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      TITLEBAR              = TEXT-T03 " 반제처리 확인.
      TEXT_QUESTION         = TEXT-Q03 " 반제처리를 하시겠습니까?
      TEXT_BUTTON_1         = 'YES'
      ICON_BUTTON_1         = 'ICON_OKAY'
      TEXT_BUTTON_2         = 'NO'
      ICON_BUTTON_2         = 'ICON_CANCEL'
      DEFAULT_BUTTON        = '1'
      DISPLAY_CANCEL_BUTTON = ''
    IMPORTING
      ANSWER                = LV_ANSWER.

  IF LV_ANSWER = '1'. " 반제처리 YES
* 반제처리하는 전표번호에 해당하는 전표 헤더 & 아이템 데이터 취득.
    SELECT *
    FROM ZVBFI0030
   WHERE BELNR EQ @GS_DISPLAY2-BELNR
    INTO CORRESPONDING FIELDS OF TABLE @LT_DATA3.

    SORT LT_DATA3 BY SHKZG DESCENDING. " 외상매출금이 위로 오게.

* NUMBER RANGE 호출.
    CALL FUNCTION 'NUMBER_GET_NEXT'
      EXPORTING
        NR_RANGE_NR             = '01'
        OBJECT                  = 'ZBBFI0030'
      IMPORTING
        NUMBER                  = LV_NR
      EXCEPTIONS
        INTERVAL_NOT_FOUND      = 1
        NUMBER_RANGE_NOT_INTERN = 2
        OBJECT_NOT_FOUND        = 3
        QUANTITY_IS_0           = 4
        QUANTITY_IS_NOT_1       = 5
        INTERVAL_OVERFLOW       = 6
        BUFFER_OVERFLOW         = 7
        OTHERS                  = 8.
    IF SY-SUBRC <> 0.
    ENDIF.

* 반제처리하는 전표번호의 아이템들에 반제전표, 반제처리일 UPDATE.
* TP TABLE, LT_DATA3 에 UPDATE.
    LOOP AT LT_DATA3 INTO LS_DATA3.
      LS_DATA3-AUGBL = LV_NR.
      LS_DATA3-AUGDT = SY-DATUM.

      MOVE-CORRESPONDING LS_DATA3 TO LS_ZTBFI0031.

* 전표 아이템 TP TABLE UPDATE.
      UPDATE ZTBFI0031 FROM LS_ZTBFI0031.

      MODIFY LT_DATA3 FROM LS_DATA3.
    ENDLOOP.

    MOVE-CORRESPONDING LT_DATA3 TO GT_DISPLAY3. " 미결전표 2줄 GT_DISPLAY3에 할당.
    MOVE-CORRESPONDING LT_DATA3 TO LT_DATA4.

* BPNAME 취득.
    SELECT SINGLE BPNAME
    FROM ZTBSD1051
   WHERE BPCODE EQ @LS_DATA3-BPCODE
    INTO @DATA(LV_BPNAME).

    LOOP AT GT_DISPLAY3 INTO GS_DISPLAY3.
      GS_DISPLAY3-BPNAME = LV_BPNAME.
      MODIFY GT_DISPLAY3 FROM GS_DISPLAY3.
    ENDLOOP.

* EMPID 취득.
    SELECT SINGLE EMPID
      FROM ZTBSD1030
     WHERE LOGID EQ @SY-UNAME
      INTO @DATA(LV_EMPID).

* 환율 DATA TYPE CHAR -> NUMERIC.
    LV_TTB1 = ZSBFI0030_POP2-TTB1.
    LV_TTB2 = ZSBFI0030_POP2-TTB2.

* 반제전표 DATA CREATE.
    LOOP AT LT_DATA4 INTO LS_DATA4.
      CLEAR GS_DISPLAY3.

      IF SY-TABIX = 1. " 보통예금에 해당하는 DATA CREATE
        LS_DATA4-BELNR = LV_NR. " 전표번호 채번된 번호로 할당.
        LS_DATA4-ACODE = '10003'. " 계정과목코드
        LS_DATA4-ANAME = '보통예금'. " 계정과목명
        LS_DATA4-ITTXT = |{ LV_BPNAME }| && '매출대금 입금'. " 항목 적요
        LS_DATA4-AUGBL = SPACE. " 반제전표번호
        LS_DATA4-AUGDT = SPACE. " 반제일
        LS_DATA4-BLART = 'DZ'. " 전표유형
        LS_DATA4-BUDAT = SY-DATUM. " 전기일
        LS_DATA4-BLDAT = SY-DATUM. " 증빙일
        LS_DATA4-USNAM = LV_EMPID. " 전표작성자
        LS_DATA4-WRBTR = ( ( LS_DATA4-HWRBTR * LV_TTB2 ) / 100 ) / 100. " 금액

      ELSEIF SY-TABIX = 2. " 외상매출금에 해당하는 DATA CREATE
        LS_DATA4-BELNR = LV_NR.
        LS_DATA4-ACODE = '10005'.
        LS_DATA4-ANAME = '외상매출금'.
        LS_DATA4-ITTXT = |{ LV_BPNAME }| && '매출대금 입금'.
        LS_DATA4-AUGBL = SPACE.
        LS_DATA4-AUGDT = SPACE.
        LS_DATA4-BLART = 'DZ'.
        LS_DATA4-BUDAT = SY-DATUM.
        LS_DATA4-BLDAT = SY-DATUM.
        LS_DATA4-USNAM = LV_EMPID.
        LS_DATA4-WRBTR = ( LS_DATA4-HWRBTR * LV_TTB1 ) / 100.
      ENDIF.

      MOVE-CORRESPONDING LS_DATA4 TO GS_DISPLAY3.
      GS_DISPLAY3-BPNAME = LV_BPNAME.
      APPEND GS_DISPLAY3 TO GT_DISPLAY3. " 반제전표 2줄 GT_DISPLAY3에 생성.

      MOVE-CORRESPONDING LS_DATA4 TO LS_ZTBFI0030.
      MOVE-CORRESPONDING LS_DATA4 TO LS_ZTBFI0031.

      INSERT ZTBFI0030 FROM LS_ZTBFI0030. " 전표 헤더 테이블 DB 반영
      INSERT ZTBFI0031 FROM LS_ZTBFI0031. " 전표 아이템 테이블 DB 반영
    ENDLOOP.

* 해외매출 반제전표 전표라인 3번째 DATA CREATE.
    CASE ZSBFI0030_POP2-TXT1.
      WHEN '외환차익'.
        LV_SHKZG = 'H'.
        LV_ACODE = '40003'.
        LV_ANAME = '외환차익'.

      WHEN '외환차손'.
        LV_SHKZG = 'S'.
        LV_ACODE = '50024'.
        LV_ANAME = '외환차손'.
    ENDCASE.

    LS_ZTBFI0031-BUZEI = '3'. " 전표라인번호.
    LS_ZTBFI0031-SHKZG = LV_SHKZG.    " 차변/대변 표시. 익일때 H, 손일때 S.
    LS_ZTBFI0031-ACODE = LV_ACODE.    "계정과목코드. 익일때 40003, 손일때 50024.
    LS_ZTBFI0031-ANAME = LV_ANAME.    " 계정과목명. 익일때 '외환차익', 손일때 '외환차손'.
    LS_ZTBFI0031-WRBTR = ZSBFI0030_POP2-HWRBTR1 / 100. " 금액.
    LS_ZTBFI0031-ITTXT = |{ LV_BPNAME }| && '매출대금 입금에 대한' && |{ LV_ANAME }|. " 항목 적요. 매출대금 입금에 대한 외환차익, 매출대금 입금에 대한 외환차손.
    LS_ZTBFI0031-HWRBTR = LS_ZTBFI0031-WRBTR.
    LS_ZTBFI0031-CURRENCY_F = LS_ZTBFI0031-CURRENCY.

    MOVE-CORRESPONDING LS_ZTBFI0031 TO GS_DISPLAY3.
    APPEND GS_DISPLAY3 TO GT_DISPLAY3.

    INSERT ZTBFI0031 FROM LS_ZTBFI0031.

    PERFORM DISPLAY_BELL2. " 반제처리 완료한 미결전표들을 ALV2 에서 삭제.
    PERFORM REFRESH_ALV2. " ALV2 REFRESH.
    PERFORM SET_ALV3.
    MESSAGE S437 WITH LV_NR. " 반제를 성공적으로 처리하였습니다.

  ELSE. " 반제처리 NO.
    MESSAGE S435. " 반제처리를 취소하였습니다.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form GET_DATA120
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM GET_DATA120 .
  DATA: LV_BLDAT    TYPE ZTBFI0030-BLDAT,
        LV_CUR_UNIT TYPE STRING,
        LV_BLDATT   TYPE ZTBFI0030-BLDAT,
        LV_KRW1     TYPE ZEB_HWRBTR,
        LV_KRW2     TYPE ZEB_HWRBTR,
        LV_KRW3     TYPE ZEB_HWRBTR,
        LV_TTB1     TYPE NUM10,
        LV_TTB2     TYPE NUM10.

  CLEAR ZSBFI0030_POP2. " 팝업 필드들 CLEAR

* 거래처정보 데이터에서 필드명이 같은 필드에 대해서 값 가져오기.
  MOVE-CORRESPONDING ZSBFI0030_BP TO ZSBFI0030_POP2.
  ZSBFI0030_POP2-BELNR = GS_DISPLAY2-BELNR.
  ZSBFI0030_POP2-AUGDT = SY-DATUM.
  ZSBFI0030_POP2-HWRBTR = GS_DISPLAY2-HWRBTR.
  ZSBFI0030_POP2-CUR_UNIT = GS_DISPLAY2-CURRENCY_F.

* 은행코드, 계죄번호 취득.
  SELECT SINGLE BANKCODE, ACCNUM
    FROM ZTBFI0060
   WHERE CTRYCODE EQ @ZSBFI0030_BP-CTRYCODE
    INTO (@ZSBFI0030_POP2-BANKCODE, @ZSBFI0030_POP2-ACCNUM).

* 증빙일 취득.
  SELECT SINGLE BLDAT
    FROM ZTBFI0030
   WHERE BELNR EQ @GS_DISPLAY2-BELNR
    INTO @LV_BLDAT.

  LV_BLDATT = LV_BLDAT + 1.

* 통화코드에 대한 환율 취득.
  CASE GS_DISPLAY2-CURRENCY_F.
    WHEN 'USD'.
      ZSBFI0030_POP2-CUR_UNIT = 'USD'.
      SELECT SINGLE BKPR
       FROM ZTBFI0050
      WHERE CUR_DATE EQ @LV_BLDAT
        AND CUR_UNIT EQ 'USD'
       INTO @ZSBFI0030_POP2-TTB1.

      SELECT SINGLE TTB
     FROM ZTBFI0050
    WHERE CUR_DATE EQ @SY-DATUM
      AND CUR_UNIT EQ 'USD'
     INTO @ZSBFI0030_POP2-TTB2.

    WHEN 'CNY'.
      ZSBFI0030_POP2-CUR_UNIT = 'CNY'.
      SELECT SINGLE BKPR
        FROM ZTBFI0050
       WHERE CUR_DATE EQ @LV_BLDAT
         AND CUR_UNIT EQ 'CNH'
        INTO @ZSBFI0030_POP2-TTB1.

      SELECT SINGLE TTB
        FROM ZTBFI0050
       WHERE CUR_DATE EQ @SY-DATUM
         AND CUR_UNIT EQ 'CNH'
        INTO @ZSBFI0030_POP2-TTB2.

    WHEN 'EUR'.
      ZSBFI0030_POP2-CUR_UNIT = 'EUR'.
      SELECT SINGLE BKPR
        FROM ZTBFI0050
       WHERE CUR_DATE EQ @LV_BLDAT
         AND CUR_UNIT EQ 'EUR'
        INTO @ZSBFI0030_POP2-TTB1.

      SELECT SINGLE TTB
        FROM ZTBFI0050
       WHERE CUR_DATE EQ @SY-DATUM
         AND CUR_UNIT EQ 'EUR'
        INTO @ZSBFI0030_POP2-TTB2.
  ENDCASE.

* 환율 API 데이터 타입은 CHAR이므로, 계산을 위해서 데이터타입 NUM 로컬변수에 할당.
  LV_TTB1 = ZSBFI0030_POP2-TTB1.
  LV_TTB2 = ZSBFI0030_POP2-TTB2.

  LV_KRW1 = ZSBFI0030_POP2-HWRBTR * LV_TTB1. " 증빙일 기준.
  LV_KRW2 = ZSBFI0030_POP2-HWRBTR * LV_TTB2 / 100. " 결제일 기준.
  LV_KRW3 = LV_KRW2 - LV_KRW1. " 결제일 - 증빙일 환율 차익.
  ZSBFI0030_POP2-HWRBTR1 = ABS( LV_KRW3 ). " 절댓값으로 반환.

  IF LV_KRW2 > LV_KRW1.
    ZSBFI0030_POP2-TXT1 = '외환차익'.
  ELSEIF LV_KRW2 < LV_KRW1.
    ZSBFI0030_POP2-TXT1 = '외환차손'.
  ELSE.
    ZSBFI0030_POP2-TXT1 = SPACE.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form GET_DATA110
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM GET_DATA110 .
  CLEAR ZSBFI0030_POP1.

  MOVE-CORRESPONDING ZSBFI0030_BP TO ZSBFI0030_POP1.
  ZSBFI0030_POP1-BELNR = GS_DISPLAY2-BELNR.
  ZSBFI0030_POP1-AUGDT = SY-DATUM.
  ZSBFI0030_POP1-BANKCODE = 'IBK'.
  ZSBFI0030_POP1-ACCNUM = '468-234567-89-010'.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form CHECK_DATA
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM CHECK_DATA .
  DATA: LS_DATA1 TYPE ZVBFI0030,
        LT_DATA1 LIKE TABLE OF LS_DATA1.

* 조회조건에 해당하는 전표 헤더 & 아이템 데이터 중, 반제처리가 되지 않은 매출전표 데이터 취득.
  SELECT *
    FROM ZVBFI0030
   WHERE BPCODE IN @SO_BPCO
     AND BUDAT IN @SO_BUDT
     AND BLART EQ 'DR'      " 고객 송장에 해당하는 전표유형.
     AND AUGBL EQ @SPACE
     AND ACODE EQ '10005'
   ORDER BY BPCODE
  INTO CORRESPONDING FIELDS OF TABLE @LT_DATA1.

  IF SY-SUBRC <> 0.
    MESSAGE S440 DISPLAY LIKE 'E'.
    STOP.
  ENDIF.
ENDFORM.
