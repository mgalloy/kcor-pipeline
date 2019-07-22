; docformat = 'rst'

;+
; Produce plots for the daily science image.
;
; :Params:
;   date : in, required, type=string
;     date in the form 'YYYYMMDD'
;   daily_science_file : in, required, type=string
;     filename of science image to produce plot for
;
; :Keywords:
;   run : in, required, type=object
;     `kcor_run` object
;-
pro kcor_plotsci, date, daily_science_file, run=run
  compile_opt strictarr

  mg_log, 'starting', name='kcor/eod', /info
  mg_log, '%s', file_basename(daily_science_file), name='kcor/eod', /info

  cd, current=orig_dir
  cd, filepath('', subdir=[date, 'level1'], root=run->config('processing/raw_basedir'))

  time = strmid(file_basename(daily_science_file), 9, 6)

  intensity = kcor_extract_radial_intensity(daily_science_file, $
                                            run->epoch('plate_scale'), $
                                            radii=radii, $
                                            standard_deviation=intensity_stddev)

  ; save original plotting environment to restore later
  orig_device = !d.name

  ; set up plotting environment
  set_plot, 'Z'
  device, get_decomposed=orig_decomposed
  tvlct, orig_rgb, /get

  device, set_resolution=[772, 772], decomposed=0, set_colors=256, z_buffering=0
  loadct, 0, /silent
  tvlct, red, green, blue, /get

  title_fmt = '(%"Azimuthally averaged radial pB intensity for %s @ %s UT")'
  plot, radii, intensity, $
        title=string(date, time, format=title_fmt), $
        xtitle='radius [R_sun]', xstyle=1, xrange=[1.0, 3.0], $
        ytitle='calibrarted pB [B/B_sun]', /ylog, yrange=[1.0e-9, 2.0e-6], ystyle=1, $
        color=0, background=255
  oplot, radii, intensity + intensity_stddev, linestyle=1, color=0
  oplot, radii, intensity - intensity_stddev, linestyle=1, color=0

  legend_x = 0.6
  legend_y = 0.9
  line_height = 0.025
  gap = 0.015
  line_length = 0.04
  plots, legend_x + [0.0, line_length], fltarr(2) + legend_y + 0.25 * line_height, $
         linestyle=0, /normal, color=0
  plots, legend_x + [0.0, line_length], fltarr(2) + legend_y - 0.75 * line_height, $
         linestyle=1, /normal, color=0
  xyouts, legend_x + line_length + gap, legend_y, /normal, $
          'intensity', $
          color=0
  xyouts, legend_x + line_length + gap, legend_y - line_height, /normal, $
          'intensity ' + string(177B) + ' standard deviation', $
          color=0

;  mg_legend, item_linestyles=[0, 1], item_name=['mean', 'mean +- std. dev.'], $
;             position=[0.5, 0.5, 0.5, 0.5], /normal, $
;             frame=1, color=0

  plot_image = tvrd()

  sci_intensity_plot_basename = string(date, format='(%"%s.kcor.radial.intensity.gif")')
  sci_intensity_plot_filename = filepath(sci_intensity_plot_basename, $
                                         subdir=[date, 'p'], $
                                         root=run->config('processing/raw_basedir'))
  write_gif, sci_intensity_plot_filename, plot_image, red, green, blue

  done:

  cd, orig_dir

  ; restore original plotting environment
  device, decomposed=orig_decomposed
  tvlct, orig_rgb
  set_plot, orig_device

  mg_log, 'done', name='kcor/eod', /info
end


; main-level example program

date = '20160603'
filename = '20160603_205347_kcor_l1.5.fts.gz'
config_filename = filepath('kcor.latest.cfg', $
                           subdir=['..', '..', 'config'], $
                           root=mg_src_root())
run = kcor_run(date, config_filename=config_filename)

kcor_plotsci, date, filename, run=run

obj_destroy, run

end
