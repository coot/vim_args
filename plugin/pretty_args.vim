" Pretty :Args [filename-modifier]
" Author: Marcin Szamotulski

if exists("g:Args_fnamemodifier")
    let s:current_mod = g:Args_fnamemodifier
else
    let s:current_mod = ':t'
endif
if !exists("g:Args_fnamemodifier")
    let g:Args_fnamemodifier = ':t'
endif
if !exists("g:Args_vertical")
    let g:Args_vertical = 0
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
    let mod = (a:0 ? a:1 : g:Args_fnamemodifier)
    let newlines = (a:0 >= 2 ?
		\ (g:Args_vertical == 0 ? "\n" : ' ') :
		\ (g:Args_vertical == 0 ? ' ' : "\n")
		\ )
    let bang = a:bang
    if mod[0] != ':'
	let newlines = (g:Args_vertical == 0 ? "\n" : ' ')
	let bang = "!"
	let mod = g:Args_fnamemodifier
    endif
    if bang != '!'
	let g:Args_fnamemodifier = mod
    endif
    let argidx = argidx()
    let argv = argv()
    let idx = 0
    for arg_ in argv
	if idx
	    echon newlines
	endif
	let pname = Fnamemodify(arg_, mod) 
	if newlines == "\n"
	    " Show similar info as :ls does
	    let bufnr = bufnr(arg_)
	    let buflisted = (buflisted(bufnr) ? ' ' : 'u')
	    let curent = (bufnr == bufnr('%') ? '%' : ( bufnr == bufnr('#') ? '#' : ' '))
	    let active = (bufwinnr(bufnr) != -1 ? 'a' : 'h')  " might not be what :ls does
	    let modifiable = (getbufvar(bufnr, '&modifiable') == 0 ? '-' :
			\ (getbufvar(bufnr, '&readonly') == 1 ? '=' : ' ')
			\ )
	    let modified = (getbufvar(bufnr, '&modified') == 1 ? '+' : ' ')  " does not show that the buffer has read errors

	    " let pname = printf('%-31s', '"'.pname.'"')
	    let pname = '"'.pname.'"'
	    echon printf("%3d%s%s%s%s%s ", bufnr, buflisted, curent, active, modifiable, modified)
	endif
	if idx == argidx
	    echohl Directory
	    echon pname
	    echohl Normal
	else
	    echon pname
	endif
	let idx += 1
    endfor
endfun

fun! <SID>Arga(count, ...)
    " Add to arg list or move
    " without arguments acts like :arga% (add the current file just after the
    " current argument)
    let files = ( a:0 > 0 ? a:000 : ['%'])
    for file in files
	" just add the file to args
	let fpath = simplify(resolve(fnamemodify(expand(file), ":p")))
	let argv = map(argv(), 'resolve(fnamemodify(v:val, ":p"))')
	if index(argv, fpath) == -1
	    if a:count >= 0
		exe a:count "arga" fnameescape(fpath)
	    else
		exe "arga" fnameescape(fpath)
	    endif
	else
	    " move the file in args
	    let argname = argv()[index(argv, fpath)]
	    exe "argd" fnameescape(argname)
	    exe a:count "arga" fnameescape(fpath)
	endif
    endfor
endfun
if !exists("g:Args_nocommands")
endif
    com! -nargs=* -range=-1 Arga :call <SID>Arga(<count>, <f-args>)
