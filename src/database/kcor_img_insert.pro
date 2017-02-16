; docformat = 'rst'

;+
; Utility to insert values into the MLSO database table: kcor_img.
;
; Reads a list of L1 files for a specified date and inserts a row of data into
; 'kcor_img'.
;
; :Params:
;   date : in, required, type=string
;     date in the form 'YYYYMMDD'
;	filelist: in, required, type=array of strings
;
; :Keywords:
;   run : in, required, type=object
;     `kcor_run` object
;
; :Examples:
;   For example::
;	  date = '20170204'
;     filelist = ['20170204_205610_kcor_l1_nrgf.fts.gz','20170204_205625_kcor_l1.fts.gz','20170204_205640_kcor_l1.fts.gz','20170204_205656_kcor_l1.fts.gz','20170204_205711_kcor_l1.fts.gz']
;     kcor_img_insert, date, filelist;
;
; :Author: 
;   Andrew Stanger
;   HAO/NCAR  K-coronagraph
;
; :History:
;   11 Sep 2015 IDL procedure created.  
;               Use /hao/mlsodata1/Data/raw/yyyymmdd/level1 directory.
;   14 Sep 2015 Use /hao/acos/year/month/day directory.
;   28 Sep 2015 Add date_end field.
;   7 Feb 2017 DJK - Starting to edit for new table fields and noting new changes to come (search for TODO)
;
;-
pro kcor_img_insert, date, fits_list, run=run
  compile_opt strictarr
  on_error, 2

  np = n_params() 
  if (np ne 2) then begin
    print, 'missing date or filelist parameters'
    mg_log, 'missing date or filelist parameters', name='kcor/dbinsert', /error
    return
  end

  ;--------------------------
  ; Connect to MLSO database.
  ;--------------------------

  ; Note: The connect procedure accesses DB connection information in the file
  ;       .mysqldb. The "config_section" parameter specifies
  ;       which group of data to use.

  db = mgdbmysql()
  db->connect, config_filename=run.database_config_filename, $
               config_section=run.database_config_section

  db->getProperty, host_name=host
  mg_log, 'connected to %s...', host, name='kcor/dbinsert', /info

  db->setProperty, database='MLSO'

  ;-------------------------------------------------------------------------------
  ; Delete all pre-existing rows with date_obs = designated date to be processed.
  ;-------------------------------------------------------------------------------

  year    = strmid (date, 0, 4)	; yyyy
  month   = strmid (date, 4, 2)	; mm
  day     = strmid (date, 6, 2)	; dd
  odate_dash = year + '-' + month + '-' + day + '%'
  
; TODO: This DELETE statement will need to be removed from this script.  In the new
;   pipeline, kcor data will be processed and added to the database in realtime through 
;   the day, so we don't want to delete previous entries.  However, the statement will 
;   likely be used in an 'update_database' script later. Be sure to note date change to next
;   day.
;  db->execute, 'DELETE FROM kcor_img_test WHERE date_obs like ''%s''', odate_dash, $
;               status=status, error_message=error_message, sql_statement=sql_cmd
;  mg_log, 'sql_cmd: %s', sql_cmd, name='kcor/dbinsert', /info
;  mg_log, 'status: %d, error message: %s', status, error_message, $
;          name='kcor/dbinsert', /info

  ;-----------------------
  ; Directory definitions.
  ;-----------------------

  ; TODO: Set to processing directory (confer with Mike and Joan)
  fts_dir = filepath('', subdir=[year, month, day], root=run.archive_dir)

  ;----------------
  ; Move to fts_dir.
  ;----------------

  cd, current=start_dir
  cd, fts_dir

  ;------------------------------------------------
  ; Step through list of fits files passed in parameter
  ;------------------------------------------------

  nfiles = n_elements(fits_list)

  if (nfiles eq 0) then begin
    print, 'no images in fits_list'
    mg_log, 'no images in fits list', name='kcor/dbinsert', /info
    goto, done
  end

  i = -1
  fts_file = 'img.fts'
  while (++i lt nfiles) do begin
    fts_file = fits_list[i]
    finfo = file_info(fts_file)   ; Get file information.

    ;----- Extract desired items from header.
	
	hdu   = headfits(fts_file, /silent)   ; Read FITS header.

    date_obs   = sxpar(hdu, 'DATE-OBS', count=qdate_obs)
    date_end   = sxpar(hdu, 'DATE-END', count=qdate_end)
	exptime    = sxpar(hdu, 'EXPTIME',  count=qexptime)
    numsum     = sxpar(hdu, 'NUMSUM',   count=qnumsum)
	quality	   = sxpar(hdu, 'QUALITY',    count=qquality)
	if (strtrim(quality, 2) eq 'ok') then begin 
		quality    = 75
	endif
	
    level      = strtrim(sxpar(hdu, 'LEVEL',    count=qlevel),2)
	; TODO: Older NRGF headers have 'NRGF' appended to level string, but newer headers
	;   will have another keyword added to header for producttype
	os = strpos(level, "NRGF")  
	if (os ne -1) then begin
		level = strmid(level, 0, os)
	endif	
	
	; Get product type from filename; TODO: are there any more? Parse from header when new producttype keyword is added.
	p = strpos(fts_file, "nrgf")
	if (p ne -1) then begin	
		producttype = 'nrgf'
	endif else begin
		producttype = 'pB'
	endelse
	
	; The decision is to not include non-fits in the database because raster files (GIFS)
	;  will be created for every image in database.  However, since we may add them later,
	;  or other file types, we'll keep the field in the kcor_img database table.
    filetype   = 'fits'

	fits_file = file_basename(fts_file, '.gz') ; remove '.gz' from file name.
	
	mg_log, 'file_name: %s', fits_file, name='kcor/dbinsert', /debug
    mg_log, 'date_obs: %s', date_obs, name='kcor/dbinsert', /debug
    mg_log, 'date_end: %s', date_end, name='kcor/dbinsert', /debug
	mg_log, 'level:    %s', level, name='kcor/dbinsert', /debug
	mg_log, 'quality:    %s', quality, name='kcor/dbinsert', /debug
	mg_log, 'numsum:   %s', numsum, name='kcor/dbinsert', /debug
	mg_log, 'exptime:  %s', exptime, name='kcor/dbinsert', /debug
    mg_log, 'producttype: %s', producttype, name='kcor/dbinsert', /debug
	mg_log, 'filetype: %s', filetype, name='kcor/dbinsert', /debug    

	; Get IDs from relational tables.

	producttype_results = db->query('SELECT * FROM producttype WHERE producttype=''%s''', $
                                 producttype, fields=fields)
    producttype_num = producttype_results.id
    mg_log, 'producttype_num: %s', producttype_num, name='kcor/dbinsert', /debug	

    filetype_results = db->query('SELECT * FROM filetype WHERE filetype=''%s''', $
                                 filetype, fields=fields)
    filetype_num = filetype_results.id
    mg_log, 'filetype_num: %s', filetype_num, name='kcor/dbinsert', /debug

    level_results = db->query('SELECT * FROM kcor_level WHERE level=''%s''', $
							   level, fields=fields)
    level_num = level_results.level_id
    mg_log, 'level_num:    %s', level_num, name='kcor/dbinsert', /debug

    ;----- DB insert command.
; TODO: remove _test from table name
    db->execute, 'INSERT INTO kcor_img_test (file_name, date_obs, date_end, level, quality, producttype, filetype, numsum, exptime) VALUES (''%s'', ''%s'', ''%s'', %d, %d, %d, %d, %d, %f) ', $
                 fits_file, date_obs, date_end, level_num, quality, producttype_num, filetype_num, numsum, exptime, $
                 status=status, error_message=error_message, sql_statement=sql_cmd

    mg_log, '%d, error message: %s', status, error_message, $
            name='kcor/dbinsert', /debug
    mg_log, 'sql_cmd: %s', sql_cmd, name='kcor/dbinsert', /debug

  endwhile

  done:
  obj_destroy, db

  mg_log, '*** end of kcor_img_insert ***', name='kcor/dbinsert', /info
end


; main-level example program

date = '20170204'
filelist = ['20170204_205610_kcor_l1_nrgf.fts.gz','20170204_205625_kcor_l1.fts.gz','20170204_205640_kcor_l1.fts.gz','20170204_205656_kcor_l1.fts.gz','20170204_205711_kcor_l1.fts.gz']
run = kcor_run(date, $
               config_filename=filepath('kcor.kolinski.mahi.latest.cfg', $
                                        subdir=['..', '..', 'config'], $
                                        root=mg_src_root()))
kcor_img_insert, date, filelist, run=run

end
