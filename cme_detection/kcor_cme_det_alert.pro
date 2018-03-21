;+
; Project     :	MLSO - KCOR
;
; Name        :	KCOR_CME_DET_ALERT
;
; Purpose     :	Generates an alert when a CME is detected
;
; Category    :	KCOR, CME, Detection
;
; Explanation :	This routine handles the actions involved in alerting users
;               that a CME has been detected.  At the moment this involves
;               writing a message to a widget, but future actions could include
;               generating movies and sending emails.
;
; Syntax      :	KCOR_CME_DET_ALERT, ITIME, RSUN
;               KCOR_CME_DET_ALERT, ITIME, /OPERATOR
;
; Examples    :	See KCOR_CME_DET_MEASURE, KCOR_CME_DET_EVENT
;
; Inputs      :	ITIME   = Current time index into LEADINGEDGE array
;               RSUN    = Solar radii in arcminutes.  Ignored if /OPERATOR
;                         keyword is set.
;
; Opt. Inputs :	None
;
; Outputs     :	None
;
; Opt. Outputs:	None
;
; Keywords    :	OPERATOR = Flags that this is an operator alert, and not all
;                          the CME parameters are available.
;
; Calls       :	TAI2UTC, KCOR_CME_DET_MOVIE, KCOR_CME_DET_EMAIL
;
; Common      :	KCOR_CME_DETECTION defined in kcor_cme_detection.pro
;
; Restrictions:	None
;
; Side effects:	None
;
; Prev. Hist. :	None
;
; History     :	Version 1, 05-Jan-2017, William Thompson, GSFC
;               Version 2, 22-Mar-2017, WTT, call KCOR_CME_DET_MOVIE,
;                       KCOR_CME_DET_EMAIL.  Add OPERATOR keyword.
;
; Contact     :	WTHOMPSON
;-
pro kcor_cme_det_alert, itime, rsun, operator=operator
  compile_opt strictarr
  @kcor_cme_det_common

  ; Format the message based on whether the alert was automatic, or generated by
  ; the operator.
  if (keyword_set(operator)) then begin
    tairef = date_diff[itime].tai_avg
    time = tai2utc(tairef, /time, /truncate, /ccsds)
    mg_log, 'Operator-generated alert at ' + time + ' UT', name='kcor/cme', /info
  endif else begin
    time = tai2utc(tairef, /time, /truncate, /ccsds)
    edge = 60 * (lat[leadingedge[itime]] + 90) / rsun
    format = '(F0.2)'
    mg_log, 'CME detected at ' + time + ' UT', name='kcor/cme', /info
    mg_log, '  Rsun           : %s', ntrim(edge, format), name='kcor/cme', /info
    mg_log, '  position angle : %s deg', ntrim(angle, format), name='kcor/cme', /info
    mg_log, '  initial speed  : %s km/s', ntrim(speed, format), name='kcor/cme', /info
  endelse

  kcor_cme_det_movie
  kcor_cme_det_email, time, edge, operator=operator

  ; If called with /OPERATOR, then delete the temporary definition of TAIREF to
  ; allow automatic CME detection to continue.
  if (keyword_set(operator)) then delvarx, tairef
end
