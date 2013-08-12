" Pretty :Args [filename-modifier]
" Author: Marcin Szamotulski

if exists("g:Args_fnamemodifier")
    let s:current_mod = g:Args_fnamemodifier
else
    let s:current_mod = ':t'
endif
fun! Fnamemodify(name, modifier)
    " Ads two modifires:
    " :H  - like :h but cuts what :h:h leaves 
    " :S  - uses pathshorten (can be combined with :H and :p)
    let mods = split(a:modifier, ':')
    let name = a:name
    let H_mods = ':p:h'
    for mod in mods
	if mod == 'H'
	    let H_mods .= ':h'
	    let dir = fnamemodify(a:name, H_mods)
	    let name = fnamemodify(a:name, ':p')
	    let name = name[len(dir)+1:]
	elseif mod == 'S'
	    let name = pathshorten(name)
	else
	    let name = fnamemodify(name, ':'.mod)
	endif
    endfor
    return name
endfun
fun! <SID>Args(bang, ...)
    let mod = (a:0 ? a:1 : s:current_mod)
    let newlines = (a:0 >= 2 ? "\n" : ' ')
    let bang = a:bang
    if mod[0] != ':'
	let newlines = "\n"
	let bang = "!"
	let mod = s:current_mod
    endif
    if bang != '!'
	let s:current_mod = mod
    endif
    let argidx = argidx()
    let argv = argv()
    let idx = 0
    for arg_ in argv
	if idx
	    echon newlines
	endif
	if idx == argidx
	    echohl Directory
	    echon Fnamemodify(arg_, mod)
	    echohl Normal
	else
	    echon Fnamemodify(arg_, mod)
	endif
	let idx += 1
    endfor
endfun
com! -bang -nargs=* Args :call <SID>Args(<q-bang>,<f-args>)
