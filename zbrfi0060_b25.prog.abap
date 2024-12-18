*&---------------------------------------------------------------------*
*& Report ZBRFI0060
*&---------------------------------------------------------------------*
*&  [FI]
*&  개발자         : CL2 KDT-B-25 하정훈
*&  프로그램 개요    : 매출내역 반제처리 프로그램
*&  개발 시작일     : 2024.11.16
*&  개발 완료일     : 2024.11.17
*&  개발상태       : 개발 완료.
*&  단위테스트 여부  :
*&---------------------------------------------------------------------*
REPORT ZBRFI0060_B25 MESSAGE-ID ZCOMMON_MSG.

INCLUDE ZBRFI0060_B25_TOP.
INCLUDE ZBRFI0060_B25_C01.
INCLUDE ZBRFI0060_B25_S01.
INCLUDE ZBRFI0060_B25_O01.
INCLUDE ZBRFI0060_B25_I01.
INCLUDE ZBRFI0060_B25_F01.

INITIALIZATION.

AT SELECTION-SCREEN.

START-OF-SELECTION.
  PERFORM CHECK_DATA. " 조회 조건에 해당하는 미결전표가 존재하는지 확인.
  CALL SCREEN 100.
