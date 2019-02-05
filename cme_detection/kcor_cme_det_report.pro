; docformat = 'rst'

;+
; Send an email report about a completed CME.
;
; :Params:
;   time : in, required, type=double
;     Atomic International Time (TAI), seconds from midnight 1 January 1958
;
; :Keywords:
;   widget : in, optional, type=boolean
;     set to run in the widget GUI
;-
pro kcor_cme_det_report, time, widget=widget
  compile_opt strictarr
  @kcor_cme_det_common

  if (n_elements(speed_history) gt 0L) then begin
    addresses = run->config('cme/email')
    if (n_elements(addresses) eq 0L) then begin
      mg_log, 'no cme.email specified, not sending email', $
              name='kcor/cme', /warn
      return
    endif

    ; create filename for plot file
    if (~file_test(run->config('engineering/dir'), /directory)) then begin
      file_mkdir, run->config('engineering/dir')
    endif

    eng_dir = filepath('', $
                       subdir=kcor_decompose_date(simple_date), $
                       root=run->config('engineering/dir'))
    if (~file_test(eng_dir, /directory)) then file_mkdir, eng_dir

    plot_file = filepath(string(simple_date, format='(%"%s.cme.plot.png")'), $
                         root=eng_dir)

    ; create plot to attach to email
    original_device = !d.name
    set_plot, 'Z'
    loadct, 0

    n_plots = 3
    device, decomposed=1, set_pixel_depth=24, set_resolution=[800, n_plots * 360]

    !p.multi = [0, 1, n_plots]

    ; speed plot
    velocity = reform(speed_history)
    ind = where(speed_history lt 0.0, n_nan)
    if (n_nan gt 0L) then velocity[ind] = !values.f_nan

    utplot, date_diff.date_avg, velocity, $
            color='000000'x, background='ffffff'x, charsize=1.5, $
            psym=1, symsize=0.5, $
            ytitle='velocity (km/s)', $
            title='Speed', $
            yrange=[0.0, max(velocity, /nan)]

    ; angle plot
    position = reform(angle_history)
    ind = where(angle_history lt 0.0, n_nan)
    if (n_nan gt 0L) then position[ind] = !values.f_nan

    utplot, date_diff.date_avg, position, $
            color='000000'x, background='ffffff'x, charsize=1.5, $
            psym=1, symsize=0.5, $
            ytitle='Angle (degrees)', $
            title='Position angle', $
            ystyle=1, yrange=[0.0, 360.0]

    ; leading edge plot
    date0 = date_diff[-1L].date_avg
    rsun = (pb0r(date0))[2]
    radius = 60 * (lat[leadingedge] + 90) / rsun

    ind = where(leadingedge lt 0.0, n_nan)
    if (n_nan gt 0L) then radius[ind] = !values.f_nan

    utplot, date_diff.date_avg, radius, $
            color='000000'x, background='ffffff'x, charsize=1.5, $
            psym=1, symsize=0.5, $
            ytitle='Solar radii', $
            title='Leading edge', $
            yrange=[1.0, 2.0]

    im = tvrd(true=1)
    set_plot, original_device
    write_png, plot_file, im

    !p.multi = 0

    ; create file of data values from plot
    plotvalues_file = filepath(string(simple_date, format='(%"%s.cme.plot.csv")'), $
                               root=eng_dir)
    openw, lun, plotvalues_file, /get_lun
    printf, lun, 'date (seconds from 79/1/1), velocity, position, radius'
    for i = 0L, n_elements(date_diff.date_avg) - 1L do begin
      printf, lun, date_diff.date_avg, velocity, position, radius, $
              format='(%"%f, %f, %f, %f")'
    endfor
    free_lun, lun

    ; create a temporary file for the message
    mailfile = mk_temp_file(dir=get_temp_dir(), 'cme_mail.txt', /random)

    ; Write out the message to the temporary file. Different messages are sent
    ; depending on whether the alert was automatic or generated by the operator.
    openw, out, mailfile, /get_lun

    printf, out, 'The Mauna Loa K-coronagraph has detected a possible CME ending at ' + $
            time + ' UT with the below parameters.'
    printf, out

    spawn, 'echo $(whoami)@$(hostname)', who, error_result, exit_status=status
    if (status eq 0L) then begin
      who = who[0]
    endif else begin
      who = 'unknown'
    endelse

    printf, out
    printf, out, mg_src_root(/filename), who, format='(%"Sent from %s (%s)")'
    version = kcor_find_code_version(revision=revision, branch=branch)
    printf, out, version, revision, branch, format='(%"kcor-pipeline %s (%s) [%s]")'
    printf, out

    free_lun, out

    ; form a subject line for the email
    subject = string(simple_date, time, $
                     format='(%"MLSO K-Cor report for CME on %s ending at %s UT")')

    from_email = n_elements(run->config('cme/from_email')) eq 0L $
                   ? '$(whoami)@ucar.edu' $
                   : run->config('cme/from_email')
    cmd = string(subject, $
                 from_email, $
                 plot_file, $
                 plotvalues_file, $
                 addresses, $
                 mailfile, $
                 format='(%"mail -s \"%s\" -r %s -a %s -a %s %s < %s")')
    spawn, cmd, result, error_result, exit_status=status
    if (status eq 0L) then begin
      mg_log, 'report sent to %s', addresses, name='kcor/cme', /info
    endif else begin
      mg_log, 'problem with mail command: %s', cmd, name='kcor/cme', /error
      mg_log, strjoin(error_result, ' '), name='kcor/cme', /error
    endelse

    ; delete the temporary files
    file_delete, mailfile

    delvarx, speed_history
  endif
end
