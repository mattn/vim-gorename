function! s:bytes_offset(line, col) abort
  if &encoding !=# 'utf-8'
    let l:sep = "\n"
    if &fileformat ==# 'dos'
      let l:sep = "\r\n"
    elseif &fileformat ==# 'mac'
      let l:sep = "\r"
    endif
    let l:buf = a:line ==# 1 ? '' : (join(getline(1, a:line-1), l:sep) . l:sep)
    let l:buf .= a:col ==# 1 ? '' : getline('.')[:a:col-2]
    return len(iconv(l:buf, &encoding, 'utf-8'))
  endif
  return line2byte(a:line) + (a:col-2)
endfunction

function! s:handle_errors(content) abort
  let l:lines = split(a:content, '\n')
  let l:errors = []
  for l:line in l:lines
    let l:tokens = matchlist(l:line, '^\(.\{-}\):\(\d\+\):\(\d\+\)\s*\(.*\)')
    if empty(l:tokens)
      continue
    endif
    call add(l:errors,{
          \'filename': l:tokens[1],
          \'lnum':     l:tokens[2],
          \'col':      l:tokens[3],
          \'text':     l:tokens[4],
          \ })
  endfor

  if len(l:errors)
    call setloclist(0, l:errors, 'r')
    call setloclist(0, [], 'a', {'title': 'Format'})
    lopen
  else
    echomsg join(l:lines, "\n")
  endif
endfunction

function! s:gorename() abort
  let l:word = expand('<cword>')
  let l:to = input(printf("gorename: rename '%s' to: ", l:word), l:word)
  if empty(l:to)
    return
  endif
  redraw
  let l:cmd = printf('gorename -offset %s:#%d -to %s', shellescape(expand('%:p')), s:bytes_offset(line('.'), col('.')), shellescape(l:to))
  let l:out = system(l:cmd)
  if v:shell_error != 0
    call s:handle_errors(l:out)
  endif
endfunction

command! -nargs=0 -buffer GoRename call s:gorename()
