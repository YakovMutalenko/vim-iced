let s:save_cpo = &cpo
set cpo&vim

let g:iced#paredit#slurp_max_depth = get(g:, 'iced#paredit#slurp_max_depth', 5)

function! s:slurp(current_view, depth) abort
  if a:depth > g:iced#paredit#slurp_max_depth
    echom iced#message#get('too_deep_to_slurp')
  else
    let before = getcurpos()
    call sexp#stackop('n', 1, 1)
    let after = getcurpos()

    if before == after
      call sexp#move_to_nearest_bracket('n', 0)
      call s:slurp(a:current_view, a:depth + 1)
    else
      call iced#format#minimal()
      call winrestview(a:current_view)
    endif
  endif
endfunction

function! iced#paredit#deep_slurp() abort
  call s:slurp(winsaveview(), 1)
endfunction

function! iced#paredit#barf() abort
  let view = winsaveview()
  call sexp#stackop('n', 1, 0)
  call winrestview(view)
endfunction

function! iced#paredit#move_to_prev_top_element() abort
  call sexp#move_to_adjacent_element('n', 0, 0, 0, 1)
endfunction

function! iced#paredit#move_to_current_element_head() abort
  if iced#util#char() ==# '('
    return col('.')
  else
    let pos = getcurpos()
    silent normal! va(o
    silent exe "normal! \<Esc>"
    return (pos == getcurpos() ? 0 : col('.'))
  endif
endfunction

function! iced#paredit#move_to_parent_element() abort
  let view = winsaveview()
  let ret = iced#paredit#move_to_current_element_head()
  if ret == 0 || col('.') == 1
    call winrestview(view)
    return 0
  endif

  " move to parent form head
  silent normal! hva(o
  silent exe "normal! \<Esc>"
  return col('.')
endfunction

function! iced#paredit#get_current_top_list_raw() abort
  let code = v:none
  let pos = v:none

  try
    while v:true
      " move to start position of current outer list
      let @@ = ''
      silent exe 'normal! vaby'
      " no matched parenthesis
      if empty(@@)
        break
      endif

      if col('.') == 1 || stridx(getline('.'), '#') == 0
        silent normal! vabo0y
        let code = @@
        let pos = getcurpos()
        break
      else
        silent normal! h
      endif
    endwhile
  finally
    silent exe "normal! \<Esc>"
  endtry

  return {'code': code, 'curpos': pos}
endfunction

function! iced#paredit#get_current_top_list() abort
  let view = winsaveview()
  let reg_save = @@
  let res = v:none

  try
    let res = iced#paredit#get_current_top_list_raw()
  finally
    let @@ = reg_save
    call winrestview(view)
  endtry

  return res
endfunction

function! iced#paredit#get_outer_list_raw() abort
  try
    silent normal! va(y
  finally
    silent exe "normal! \<Esc>"
  endtry
  return @@
endfunction

function! iced#paredit#get_outer_list() abort
  let view = winsaveview()
  let reg_save = @@
  let code = v:none

  try
    let code = iced#paredit#get_outer_list_raw()
  finally
    let @@ = reg_save
    call winrestview(view)
  endtry

  return code
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
