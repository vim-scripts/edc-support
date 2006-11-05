function! edccomplete#Complete(findstart, base)
  if a:findstart
    " locate the start of the word
    let line = getline('.')
    let start = col('.') - 1
    let compl_begin = col('.') - 2
    if line =~ ':'
      while start > 0 && (line[start - 1] =~ '\k' || line[start - 1] =~ '"')
	let start -= 1
      endwhile
    else
      while start > 0 && line[start - 1] =~ '\k'
	let start -= 1
      endwhile
    endif
    let b:compl_context = getline('.')[0:compl_begin]

    let startpos = searchpair('{', '', '}', 'bnW')
    let lnum = startpos
    let line = getline(lnum)

    if line !~ '\a\+'
      let line = getline(prevnonblank(lnum))
    endif

    let b:scontext = matchstr(line, '\a\+')

    return start
  else
    " find months matching with "a:base"
    let res = []
    if exists("b:compl_context")
      let line = b:compl_context
      unlet! b:compl_context
    else
      let line = a:base
    endif

    if b:scontext == 'part'
      call edccomplete#AddLabel(res, line, a:base, s:partLabel)
      call edccomplete#AddStatement(res, line, a:base, s:partStatement)
      if line =~ 'type:\s*'
	call edccomplete#AddKeyword(res, a:base, s:partTypes)
      elseif line =~ 'effect:\s*'
	call edccomplete#AddKeyword(res, a:base, s:partEffects)
      endif

    elseif b:scontext == 'dragable'
      call edccomplete#AddLabel(res, line, a:base, s:dragableLabel)

    elseif b:scontext == 'description'
      call edccomplete#AddLabel(res, line, a:base, s:descriptionLabel)
      call edccomplete#AddStatement(res, line, a:base, s:descriptionStatement)
      if line =~ 'aspect_preference:\s*'
	call edccomplete#AddKeyword(res, a:base, s:aspectPrefTypes)
      elseif line =~ 'inherit:\s*"'
	call edccomplete#FindStates(res, a:base, 1)
      endif

    elseif b:scontext == 'rel'
      call edccomplete#AddLabel(res, line, a:base, s:relLabel)

    elseif b:scontext == 'image'
      call edccomplete#AddLabel(res, line, a:base, s:imageLabel)

    elseif b:scontext == 'fill'
      call edccomplete#AddLabel(res, line, a:base, s:fillLabel)
      call edccomplete#AddStatement(res, line, a:base, s:fillStatement)

    elseif b:scontext == 'origin' || b:scontext == 'size'
      call edccomplete#AddLabel(res, line, a:base, s:fillInnerStatement)

    elseif b:scontext == 'text'
      call edccomplete#AddLabel(res, line, a:base, s:textLabel)

    elseif b:scontext == 'program'
      call edccomplete#AddLabel(res, line, a:base, s:programLabel)
      call edccomplete#AddStatement(res, line, a:base, s:programStatement)
      if line =~ 'transition:\s*'
	call edccomplete#AddKeyword(res, a:base, s:transitionTypes)
      elseif line =~ 'STATE_SET \s*"'
	call edccomplete#FindStates(res, a:base, 0)
      elseif line =~ 'action:\s*'
	call edccomplete#AddKeyword(res, a:base, s:actionTypes)
      elseif line =~ 'target:\s*"'
	call edccomplete#FindNamesIn(res, a:base, 'parts')
      elseif line =~ 'after:\s*"'
	call edccomplete#FindNamesIn(res, a:base, 'programs')
      endif

    elseif b:scontext == 'programs'
      call edccomplete#AddStatement(res, line, a:base, s:programsStatement)

    elseif b:scontext == 'group'
      call edccomplete#AddLabel(res, line, a:base, s:groupLabel)
      call edccomplete#AddStatement(res, line, a:base, s:groupStatement)

    elseif b:scontext == 'parts'
      call edccomplete#AddStatement(res, line, a:base, s:partsStatement)

    elseif b:scontext == 'data'
      call edccomplete#AddLabel(res, line, a:base, s:dataLabel)

    elseif b:scontext == 'fonts'
      call edccomplete#AddLabel(res, line, a:base, s:fontsLabel)

    elseif b:scontext == 'spectra'
      call edccomplete#AddStatement(res, line, a:base, s:spectraStatement)

    elseif b:scontext == 'spectrum'
      call edccomplete#AddLabel(res, line, a:base, s:spectrumLabel)

    elseif b:scontext == 'gradient'
      call edccomplete#AddLabel(res, line, a:base, s:gradientLabel)
      call edccomplete#AddStatement(res, line, a:base, s:gradientStatement)

    elseif b:scontext == 'images'
      call edccomplete#AddLabel(res, line, a:base, s:imagesLabel)
      if line =~ 'image:\s*".\{-}"'
	call edccomplete#AddKeyword(res, a:base, s:imageStorageMethod)
      endif

    elseif b:scontext == 'collections'
      call edccomplete#AddStatement(res, line, a:base, s:collectionsStatement)

    elseif strlen(b:scontext) == 0
      call edccomplete#AddStatement(res, line, a:base, s:topStatement)
    endif

    unlet! b:scontext

    return res
  endif
endfunction

function! edccomplete#AddLabel(res, line, base, label)
  if a:line =~ ':'
    return
  endif

  for m in sort(keys(a:label))
    if m =~ '^' . a:base
      call add(a:res, {'word': m . ':', 'menu': a:label[m]})
    endif
  endfor
endfunction

function! edccomplete#AddKeyword(res, base, label)
  for m in sort(keys(a:label))
    if m =~ '^' . a:base
      call add(a:res, {'word': m, 'menu': a:label[m]})
    endif
  endfor
endfunction

function! edccomplete#AddStatement(res, line, base, statement)
  if a:line =~ ':'
    return
  endif

  for m in sort(a:statement)
    if m =~ '^' . a:base
      call add(a:res, m . ' {')
    endif
  endfor
endfunction

function! edccomplete#FindStates(res, base, in_part)
  let curpos = getpos('.')
  call remove(curpos, 0, 0)

  let states_list = []
  if a:in_part == 1 	" in the current part only
    let part_start = search('^[ \t}]*\<part\>[ \t{]*$', 'bnW')
    if part_start != 0  " found it
      let line = getline(part_start)
      if line !~ '{'
	let part_start = nextnonblank(part_start)
      endif
      call cursor(part_start, 0)
      let part_end = searchpair('{', '', '}', 'nW')
    endif
  else 			" in the current parts group
    let part_start = search('^[ \t}]*\<parts\>[ \t{]*$', 'bnW')
    if part_start != 0  " found it
      let line = getline(part_start)
      if line !~ '{'
	let part_start = nextnonblank(part_start)
      endif
      call cursor(part_start, 0)
      let part_end = searchpair('{', '', '}', 'nW')
    endif
  endif

  let state_num = search('\%(state:\s*\)"\w\+"', 'W', part_end)
  while state_num
    let state = matchstr(getline(state_num), '\%(state:\s*\)\@<="\w\+"')
    call extend(states_list, [state])
    let state_num = search('\%(state:\s*\)"\w\+"', 'W', part_end)
  endwhile
  call cursor(curpos)

  for m in sort(states_list)
    if m =~ '^' . a:base
      call add(a:res, m)
    endif
  endfor
endfunction

function! edccomplete#FindNamesIn(res, base, str)
  let curpos = getpos('.')
  call remove(curpos, 0, 0)

  let names_list = []
  let part_start = search('^[ \t}]*\<' . a:str . '\>[ \t{]*$', 'bnW')
  if part_start != 0  " found it
    let line = getline(part_start)
    if line !~ '{'
      let part_start = nextnonblank(part_start)
    endif
    call cursor(part_start, 0)
    let part_end = searchpair('{', '', '}', 'nW')
  endif

  let name_num = search('\%(name:\s*\)"\w\+"', 'W', part_end)
  while name_num
    let name = matchstr(getline(name_num), '\%(name:\s*\)\@<="\w\+"')
    call extend(names_list, [name])
    let name_num = search('\%(name:\s*\)"\w\+"', 'W', part_end)
  endwhile
  call cursor(curpos)

  for m in sort(names_list)
    if m =~ '^' . a:base
      call add(a:res, m)
    endif
  endfor
endfunction

function! Sdebug(str)
  echo a:str
  sleep 1
endfunction

" part
let s:partLabel = {
      \ 'name': 		'"string"',
      \ 'clip_to':		'"string"',
      \ 'color_class':		'"string"',
      \ 'text_class':		'"string"',
      \ 'type':			'"keyword"',
      \ 'effect':		'"keyword"',
      \ 'mouse_events':		'"bool"',
      \ 'repeat_events':	'"bool"',
      \ }

let s:partStatement = [
      \ 'dragable',
      \ 'description',
      \ ]

" dragable
let s:dragableLabel = {
      \ 'x':		'"bool" "int" "int"',
      \ 'y':		'"bool" "int" "int"',
      \ 'confine':	'"string"',
      \ }

" description
let s:descriptionLabel = {
      \ 'state':		'"string" "float"',
      \ 'inherit':		'"string" "float"',
      \ 'visible':		'"bool"',
      \ 'align':		'"float" "float"',
      \ 'min':			'"int" "int"',
      \ 'max':			'"int" "int"',
      \ 'step':			'"int" "int"',
      \ 'aspect':		'"float" "float"',
      \ 'aspect_preference':	'"keyword"',
      \ 'color':		'"int" "int" "int" "int"',
      \ 'color2':		'"int" "int" "int" "int"',
      \ 'color3':		'"int" "int" "int" "int"',
      \ }
let s:descriptionStatement = [
      \ 'rel1',
      \ 'rel2',
      \ 'image',
      \ 'fill',
      \ 'text',
      \ 'gradient',
      \ ]

" rel
let s:relLabel = {
      \ 'relative':	'"float" "float"',
      \ 'offset':	'"int" "int"',
      \ 'to':		'"string"',
      \ 'to_x':		'"string"',
      \ 'to_y':		'"string"',
      \ }

" image
let s:imageLabel = {
      \ 'normal':	'"string"',
      \ 'tween':	'"string"',
      \ 'border':	'"int" "int" "int" "int"',
      \ 'middle':	'"bool"',
      \ }

" fill
let s:fillLabel = {
      \ 'smooth':	'"bool"',
      \ }
let s:fillStatement = [
      \ 'origin',
      \ 'size',
      \ ]
" fill origin/size
let s:fillInnerStatement = {
      \ 'relative':	'"float" "float"',
      \ 'offset':	'"int" "int"',
      \ }

" text
let s:textLabel = {
      \ 'text':		'"string"',
      \ 'font':		'"string"',
      \ 'size':		'"int"',
      \ 'fit':		'"bool" "bool"',
      \ 'min':		'"bool" "bool"',
      \ 'align':	'"float" "float"',
      \ 'elipsis':	'"float"',
      \ }

" program
let s:programLabel = {
      \ 'name':		'"string"',
      \ 'signal':	'"string"',
      \ 'source':	'"string"',
      \ 'action':	'"keyword" ...',
      \ 'transition':	'"keyword" "float"',
      \ 'target':	'"string"',
      \ 'after':	'"string"',
      \ }
let s:programStatement = [
      \ 'script',
      \ ]


" programs
let s:programsStatement = [
      \ 'program',
      \ ]

" group
let s:groupLabel = {
      \ 'name':		'"string"',
      \ 'min':		'"int" "int"',
      \ 'max':		'"int" "int"',
      \ }
let s:groupStatement = [
      \ 'data',
      \ 'script',
      \ 'parts',
      \ 'programs',
      \ ]

" parts
let s:partsStatement = [
      \ 'part',
      \ ]

" data
let s:dataLabel = {
      \ 'item':		'"string" "string" ...',
      \ }

" fonts
let s:fontsLabel = {
      \ 'font':		'"string" "string"',
      \ }

"images
let s:imagesLabel = {
      \ 'image':	'"string" "keyword"',
      \ }

"collections
let s:collectionsStatement = [
      \ 'group',
      \ ]

" spectra
let s:spectraStatement = [
      \ 'spectrum',
      \ ]
" spectrum
let s:spectrumLabel = {
      \ 'name':		'"string"',
      \ 'color': 	'"int" "int" "int" "int" "int"',
      \ }
" gradient
let s:gradientLabel = {
      \ 'type':		'"string"',
      \ 'spectrum':	'"string"',
      \ }
let s:gradientStatement = [
      \ 'rel1',
      \ 'rel2',
      \ ]

" toplevel
let s:topStatement = [
      \ 'fonts',
      \ 'images',
      \ 'data',
      \ 'collections',
      \ ]

" images image storage method
let s:imageStorageMethod = {
      \ 'COMP':		'',
      \ 'RAW':		'',
      \ 'LOSSY':	'0-100',
      \ }

" part types
let s:partTypes = {
      \ 'TEXT':		'',
      \ 'IMAGE':	'',
      \ 'RECT':		'',
      \ 'TEXTBLOCK':	'',
      \ 'SWALLOW':	'',
      \ 'GRADIENT':	'',
      \ }
" part effects
let s:partEffects = {
      \ 'NONE':			'',
      \ 'PLAIN':		'',
      \ 'OUTLINE':		'',
      \ 'SOFT_OUTLINE':		'',
      \ 'SHADOW':		'',
      \ 'SOFT_SHADOW':		'',
      \ 'OUTLINE_SHADOW':	'',
      \ 'OUTLINE_SOFT_SHADOW':	'',
      \ }

" aspect_preference types
let s:aspectPrefTypes = {
      \ 'VERTICAL':	'',
      \ 'HORIZONTAL':	'',
      \ 'BOTH':		'',
      \	}

" program transition types
let s:transitionTypes = {
      \ 'LINEAR':	'0.0 - 1.0',
      \ 'SINUSOIDAL':	'0.0 - 1.0',
      \ 'ACCELERATE':	'0.0 - 1.0',
      \ 'DECELERATE':	'0.0 - 1.0',
      \ }
" program action types
let s:actionTypes = {
      \ 'STATE_SET':		'"string" "0.0 - 1.0"',
      \ 'ACTION_STOP':		'',
      \ 'SIGNAL_EMIT':		'"string" "string"',
      \ 'DRAG_VAL_SET':		'"float" "float"',
      \ 'DRAG_VAL_STEP':	'"float" "float"',
      \ 'DRAG_VAL_PAGE':	'"float" "float"',
      \ }
