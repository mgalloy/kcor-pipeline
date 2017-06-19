;+
; Project     :	MLSO - KCOR
;
; Name        :	KCOR_CME_DET_ALERT
;
; Purpose     :	Generates a movie from the most recent KCOR data.
;
; Category    :	KCOR, CME, Detection
;
; Explanation : This routine is called from KCOR_CME_DET_ALERT to create a
;               running difference movie from the last 20 minutes of data.  Two
;               different versions of the movie are produced, one animated GIF
;               and the other MPEG-4.
;
; Syntax      :	KCOR_CME_DET_MOVIE
;
; Examples    :	See KCOR_CME_DET_ALERT
;
; Inputs      :	None
;
; Opt. Inputs :	None
;
; Outputs     :	The movies are written to the directory specified by the
;               environment variable KCOR_CME_DETECTION.
;
; Opt. Outputs:	None
;
; Keywords    :	None
;
; Env. Vars.  : KCOR_MOVIE_DIR = Directory to write movies to.  If not defined,
;                                then the movies are written to the current
;                                directory.
;
; Calls       :	READFITS, AVERAGE, BOOST_ARRAY, CONCAT_DIR
;
; Common      :	KCOR_CME_DETECTION defined in kcor_cme_detection.pro
;
; Restrictions:	The current implementation of this routine always writes to a
;               file called kcor_latest_cme_detection.gif or .mp4.  This may be
;               changed in the future to give each event a unique file name.
;
; Side effects:	None
;
; Prev. Hist. :	None
;
; History     :	Version 1, 20-Mar-2017, William Thompson, GSFC
;
; Contact     :	WTHOMPSON
;-
;
pro kcor_cme_det_movie
compile_opt strictarr
;
common kcor_cme_detection
;
;  Look for the last 20 minutes worth of data, plus 5 minutes (and a bit) for
;  generating the running differences.
;
w = where(date_orig.tai_end ge (tairef-1505), count)
;
;  Set up the arrays to store the images and difference frames.
;
images = fltarr(512,512,count)
delvarx, frames
;
;  Step through the images, and read them in.
;
for i=0,count-1 do begin
    ii = w[i]
    image = readfits(date_orig[ii].filename, header, /silent)
;
;  Reduce the image size to 512x512.
;
    images[*,*,i] = reduce(image,2,/average)
;
;  Form the running differences in the same way as the polar maps.
;
    dtime = date_orig[ii].tai_end - date_orig[w].tai_end
    w1 = where((dtime ge 0) and (dtime le 33), count1)
    w2 = where((dtime ge 297) and (dtime le 333), count2)
    if (count1 gt 0) and (count2 gt 0) then begin
        if count1 eq 1 then image1 = images[*,*,w1] else $
          image1 = average(images[*,*,w1], 3)
        if count2 eq 1 then image2 = images[*,*,w2] else $
          image2 = average(images[*,*,w2], 3)
        boost_array, frames, image1 - image2
    endif
endfor
;
;  Rescale the image frames into a byte array for generating movies.
;
frames = bytscl(sigrange(frames))
sz = size(frames)
;
;  Define the name of the output file.  The file extension is added later.
;
moviedir = getenv('KCOR_MOVIE_DIR')
moviefile = concat_dir(moviedir, 'kcor_latest_cme_detection')
;
;  Create an animated GIF version of the movie.
;
c = indgen(256)
for i=0,sz[3]-1 do write_gif, moviefile+'.gif', frames[*,*,i], c, c, c, $
                              /multiple, repeat_count=0
write_gif, moviefile, frames[*,*,0], /close
print, 'Wrote file ' + moviefile
;
;  Create an MPEG-4 version of the movie.
;
oVid = IDLffVideoWrite(moviefile+'.mp4')
vidStream = oVid.AddVideoStream(sz[1], sz[2], 10)
for i=0,sz[3]-1 do begin
    iframe = rebin( reform(frames[*,*,i],1,sz[1],sz[2]), 3,sz[1],sz[2])
    dummy = oVid.Put(vidStream, iframe)
endfor
oVid = 0
print, 'Wrote file ' + moviefile
;
end
