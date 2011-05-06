function! s:AlternateFile()
  let fn = substitute(expand('%'), "^".getcwd()."/", "", "")
  let head = fnamemodify(fn, ':h')
  let tail = fnamemodify(fn, ':t')

  if match(head, '^lib/coupler/extensions') >= 0
    return substitute(head, '^lib/coupler', 'test/integration', '').'/test_'.tail
  elseif match(head, '^lib') >= 0
    return substitute(head, '^lib/coupler', 'test/unit', '').'/test_'.tail
  elseif match(head, '^test/integration/extensions') >= 0
    return substitute(head, '^test/integration', 'lib/coupler', '').'/'.substitute(tail, '^test_', '', '')
  elseif match(head, '^test') >= 0
    return substitute(head, '^test/unit', 'lib/coupler', '').'/'.substitute(tail, '^test_', '', '')
  endif
  return ''
endfunction

function! s:Alternate(cmd)
  let file = s:AlternateFile()
  "if file != '' && filereadable(file)
    if a:cmd == 'T'
      let cmd = 'tabe'
    elseif a:cmd == 'S'
      let cmd = 'sp'
    else
      let cmd = 'e'
    endif
    exe ':'.cmd.' '.file
  "else
    "echomsg 'No alternate file is defined: '.file
  "endif
endfunction

command! A  :call s:Alternate('')
command! AE :call s:Alternate('E')
command! AS :call s:Alternate('S')
command! AV :call s:Alternate('V')
command! AT :call s:Alternate('T')
