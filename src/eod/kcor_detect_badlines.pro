; docformat = 'rst'

;+
; Find bad lines raw images.
;
; :Keywords:
;   run : in, required, type=object
;     KCor run object
;-
pro kcor_detect_badlines, run=run
  compile_opt strictarr

  logger_name = string(run.mode, format='(%"kcor/%s")')

  mg_log, 'starting', name=logger_name, /info

  basename = '*_kcor_l1.5.fts.gz'

  raw_basedir = run->config('processing/raw_basedir')

  pattern = filepath(basename, subdir=[run.date, 'level1'], root=raw_basedir)
  times = strmid(file_basename(file_search(pattern, count=n_filenames)), 0, 15)

  cam0_badlines = mg_defaulthash(default=0L)
  cam1_badlines = mg_defaulthash(default=0L)
  n_checked_images = 0L

  for f = 0L, n_filenames - 1L do begin
    filename = filepath(string(times[f], format='(%"%s_kcor.fts.gz")'), $
                        subdir=[run.date, 'level0'], $
                        root=raw_basedir)
    im = readfits(filename, /silent)

    n_checked_images += 1L

    difference_threshold = run->epoch('badlines_diff_threshold')
    kcor_find_badlines, im, $
                        cam0_badlines=cam0, $
                        cam1_badlines=cam1, $
                        difference_threshold=difference_threshold

    for i = 0L, n_elements(cam0) - 1L do cam0_badlines[cam0[i]] += 1
    for i = 0L, n_elements(cam1) - 1L do cam1_badlines[cam1[i]] += 1
  endfor

  mg_log, 'checked %d out of %d OK L0 files', n_checked_images, n_filenames, $
          name=logger_name, /info

  if (cam0_badlines->count() gt 0L) then begin
    mg_log, 'cam0 bad lines:', name=logger_name, /warn
    lines = cam0_badlines->keys()
    lines_array = lines->toArray()
    counts = cam0_badlines->values()
    counts_array = counts->toArray()
    obj_destroy, [lines, counts]
    lines_array = lines_array[sort(-counts_array)]
    for l = 0L, n_elements(lines_array) - 1L do begin
      count = cam0_badlines[lines_array[l]]
      mg_log, '%d: %d times (%0.1f%%)', $
              lines_array[l], count, 100.0 * count / n_checked_images, $
              name=logger_name, /warn      
    endfor
  endif

  if (cam1_badlines->count() gt 0L) then begin
    mg_log, 'cam1 bad lines:', name=logger_name, /warn
    lines = cam1_badlines->keys()
    lines_array = lines->toArray()
    counts = cam1_badlines->values()
    counts_array = counts->toArray()
    obj_destroy, [lines, counts]
    lines_array = lines_array[sort(-counts_array)]
    for l = 0L, n_elements(lines_array) - 1L do begin
      count = cam1_badlines[lines_array[l]]
      mg_log, '%d: %d times (%0.1f%%)', $
              lines_array[l], count, 100.0 * count / n_checked_images, $
              name=logger_name, /warn      
    endfor
  endif

  obj_destroy, [cam0_badlines, cam1_badlines]
  mg_log, 'done', name=logger_name, /info
end


; main-level example program

date = '20190625'

run = kcor_run(date, $
               config_filename=filepath('kcor.latest.cfg', $
                                        subdir=['..', '..', 'config'], $
                                        root=mg_src_root()), $
               mode='badlines')
kcor_detect_badlines, run=run

obj_destroy, run

end
