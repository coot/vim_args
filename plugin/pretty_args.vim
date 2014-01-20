" Pretty :Args [filename-modifier]
" :Argu
" :Arga
" :Argd
" Author: Marcin Szamotulski

if exists("g:did_prettyargs")
    finish
endif
let g:did_prettyargs = 1

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

fun! <SID>ArgIsGlobal()
    if exists('*argisglobal')
	return argisglobal()
    else
	return exists('w:Args_fnamemodifier')
    endif
endfun

fun! <SID>Args(bang, ...)
    if !<SID>ArgIsGlobal() && exists('w:Args_fnamemodifier')
	let fnamemodifier = w:Args_fnamemodifier
    else
	let fnamemodifier = g:Args_fnamemodifier
    endif
    if !<SID>ArgIsGlobal() && exists('w:Args_vertical')
	let Args_vertical = w:Args_vertical
    else
	let Args_vertical = g:Args_vertical
    endif
    let mod = (a:0 ? a:1 : fnamemodifier)
    let newlines = (a:0 >= 2 ?
		\ (Args_vertical == 0 ? "\n" : ' ') :
		\ (Args_vertical == 0 ? ' ' : "\n")
		\ )
    let bang = a:bang
    if mod[0] != ':'
	let newlines = (Args_vertical == 0 ? "\n" : ' ')
	let bang = "!"
	let mod = fnamemodifier
    endif
    if bang != '!'
	if !<SID>ArgIsGlobal()
	    let w:Args_fnamemodifier = mod
	else
	    let g:Args_fnamemodifier = mod
	endif
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
	    let argnr = idx + 1
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
	    echon printf("%-2d%3d%s%s%s%s%s ", argnr, bufnr, buflisted, curent, active, modifiable, modified)
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

fun! <SID>Arga(bang, count, silent, ...)
    " Add to arg list or move when used with a bang.
    " without arguments acts like :arga% (add the current file just after the
    " current argument)
    let files = ( a:0 > 0 ? a:000 : ['%'])
    let argv = map(argv(), 'resolve(fnamemodify(v:val, ":p"))')
    for file in files
	" just add the file to args
	if expand(file) != ''
	    let fpath = fnamemodify(expand(file), ":p")
	else
	    echohl ErrorMsg
	    echom "E499, Empty file name for '%' or '#'"
	    echohl Normal
	    continue
	endif
	if index(argv, fpath) == -1
	    if (a:count) != 987654321098
		exe (a:count) "arga" fnameescape(fpath)
	    else
		exe "arga" fnameescape(fpath)
	    endif
	    if !a:silent
		echom '"'.expand(file).'" added to the arglist'
	    endif
	elseif a:bang == "!"
	    " move the file in args
	    let argname = argv()[index(argv, fpath)]
	    exe "argd" escape(argname, '.*')
	    exe (a:count) "arga" fnameescape(fpath)
	    if !a:silent
		echom '"'.expand(file).'" moved in the arglist'
	    endif
	endif
    endfor
endfun

fun! <SID>Argm(bang, ...)
    " Move a:file to the end of arglist
    " if bang is used the index (a:1) is relative to the current position
    " Argm [file] idx
    " if [file] is ommited argidx() is used
    if a:0 == 0
	echohl ErrorMsg
	echo ':Argm [argfile] ind, at least ind is required'
	echohl Normal
	return
    endif
    let file = (a:0>=2 ? a:1 : "%")
    if a:0 >= 2
	let ind = a:2
    else
	let ind = a:1
    endif
    let argv = argv()
    let _argv = map(argv(), 'Fnamemodify(v:val, g:Args_fnamemodifier)')
    if file != '%'
	let aind = index(_argv, file)
    else
	let aind = argidx()
    endif
    if aind == -1
	let aind = index(argv, file)
    endif
    if aind == -1
	echohl ErrorMsg
	echom 'File did not match any files in the arg list'
	echohl Normal
	return
    endif
    let argf = argv[aind]
    call remove(argv, aind)
    if a:bang == ""
	if ind < 0
	    let ind = len(argv) + ind + 1
	elseif ind == '$'
	    let ind = len(argv)
	elseif ind == '^'
	    let ind = 0
	else
	    let ind = ind
	endif
    else
	" relative index
	let ind = aind + ind
    endif
    if ind > len(argv)
	let ind = len(argv)
    elseif ind < 0
	let ind = 0
    endif
    call insert(argv, argf, ind)
    " We do not use :args since it also opens the first file
    for f in argv()
	exe 'argd' fnameescape(f)
    endfor
    for f in argv
	exe 'arga' fnameescape(f)
    endfor
endfun

fun! <SID>Argd(bang, ...)
    " Delete files based on file names rather than a pattern
    "
    " If bang is used no escaping is done (so a pattern may be used)
    let files = ( a:0 > 0 ? a:000 : ['%'] )
    for file in files
	if file == ''
	    continue
	endif
	if !(a:bang != '!' ||  file != '%')
	    exe "argd" '*'.escape(file, '*{}?\[]')
	else
	    exe "argd" file
	endif
    endfor
endfun

fun! <SID>Arg_comp(ArgLead, CmdLine, CursorPos)
    return join(map(argv(), 'Fnamemodify(v:val, g:Args_fnamemodifier)'), "\n")
endfun

fun! <SID>Argu(...)
    let fname = (a:0 >= 1 ? a:1 : '')
    if match(fname, '^\d\+$') == 0
	" be compatible with :argu
	let ind = fname+0
    else
	let ind = 0
	let match = 0
	for arg in argv()
	    let arg = Fnamemodify(arg, g:Args_fnamemodifier)
	    let ind += 1
	    if match(arg, fname) != -1
		let match = 1
		break
	    endif
	endfor
	if match == 0
	    echohl ErrorMsg
	    echom 'No matching argument for' fname
	    echohl Normal
	    return
	endif
    endif
    if ind != 0
	try
	    exe 'argu' (ind)
	catch /E163/
	    echohl ErrorMsg
	    echom v:errmsg
	    echohl Normal
	catch /E165/
	    echohl ErrorMsg
	    echom v:errmsg
	    echohl Normal
	endtry
    else
	echohl ErrorMsg
	echom 'File "'.fname.'" not in the arg list'
	echohl Normal
    endif
endfun

fun! <SID>Argu_comp(ArgLead, CmdLine, CursorPos)
    let matches = filter(
		\ map(argv(), 'Fnamemodify(v:val, g:Args_fnamemodifier)'),
		\ 'match(v:val, a:ArgLead) != -1')
    return matches
endfun

if !exists("g:Args_nocommands")
    com! -nargs=* -bang Args :call <SID>Args(<q-bang>, <f-args>)
    " the -count=987654321 is a hack for a default value outside of the usual
    " scope, one cannot use -count=-1.  This is needed for compatibility with
    " :arga command
    com! -nargs=* -bang -count=987654321 -complete=file Arga :call <SID>Arga(<q-bang>, <count>, 0, <f-args>)
    com! -nargs=* -complete=custom,<SID>Arg_comp Argd :call <SID>Argd(<q-bang>, <f-args>)
    com! -nargs=? -complete=customlist,<SID>Argu_comp Argu :call <SID>Argu(<f-args>)
    com! -nargs=* -bang -complete=customlist,<SID>Argu_comp Argm :call <SID>Argm(<q-bang>, <f-args>)
    if !exists("g:Args_noaliases") && exists(":CmdAlias") >= 2
	CmdAlias A\%[rgu] Argu
	CmdAlias Ar\%[gs] Args
    endif
    if !exists("g:Args_noshortcuts") 
	com! -nargs=? -complete=customlist,<SID>Argu_comp A :call <SID>Argu(<f-args>)
	com! -bang -nargs=* Ar :call <SID>Args(<q-bang>, <f-args>)
    endif
    if !exists('*argisglobal')
	" vim is not compiled with patch/arg.patch
	com! Argg :silent! unlet w:Args_fnamemodifier<bar>argg
	com! Argl :let w:Args_fnamemodifier = g:Args_fnamemodifier<bar>argl
    endif
    " Todo: Argu should have better completion, like buffer names
endif
if !exists("g:Args_nomaps")
    nm <silent> <Leader>a :call <SID>Arga("", v:count, 1, '%')<cr>
endif
