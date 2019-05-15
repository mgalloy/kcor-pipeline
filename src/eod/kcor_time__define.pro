; docformat = 'rst'

function kcor_time::type, letter
  compile_opt strictarr

  case strlowcase(letter) of
    'c': return, 'cal'
    'm': return, 'dev'
    't': return, 'sat'
    'b': return, 'bri'
    'd': return, 'dim'
    'o': return, 'cloudy'
    'n': return, 'noisy'
    'e': return, 'eng'
    'g': return, 'good'
    else: return, 'unk'
  endcase
end



function kcor_time::getVariable, name, found=found
  compile_opt strictarr

  found = 1B
  case strlowcase(name) of
    'datetime': return, self.datetime
    'type': begin
        quicklook_href = self->getVariable('quicklook_href', found=found)
        if (~found) then return, 'unk'
        letter = strmid(file_basename(quicklook_href, '.gif'), 0, 1, /reverse_offset)
        return, self->type(letter)
      end
    'quicklook_href': begin
        raw_basedir = self.run->config('processing/raw_basedir')
        quicklooks = file_search(filepath(self.datetime + '*', $
                                          subdir=[self.run.date, 'level0', 'quicklook'], $
                                          root=raw_basedir), $
                                 count=n_quicklooks)
        if (n_quicklooks eq 0L) then return, ''
        quicklook_href = './level0/quicklook/' + file_basename(quicklooks[0])
        return, quicklook_href
      end
    'l15_href': begin
        raw_basedir = self.run->config('processing/raw_basedir')
        l15_gifs = file_search(filepath(self.datetime + '_kcor_l1.5.gif', $
                                        subdir=[self.run.date, 'level1'], $
                                        root=raw_basedir), $
                               count=n_l15_gifs)
        if (n_l15_gifs eq 0L) then return, ''
        l15_href = './level1/' + file_basename(l15_gifs[0])
        return, l15_href
      end
  endcase

  found = 0B
  return, ''
end


function kcor_time::init, datetime, run=run
  compile_opt strictarr

  self.datetime = datetime
  self.run = run

  return, 1
end


pro kcor_time__define
  compile_opt strictarr

  !null = {kcor_time, inherits IDL_Object, $
           datetime: '', $
           run: obj_new()}
end