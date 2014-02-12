" Author: Marcin Szamotulski
" Email:  mszamot [AT] gmail [DOT] com
" License: vim-license, see :help license

" let vimlparsers#splitargs_pat = '\v%(%(\\@1<!%(\\\\)*)@>)@<=\|'
let s:range_modifier = '(\s*[+-]+\s*\d*)?'
fun! vimlparsers#ParseRange(cmdline) " {{{
    let range = ""
    let cmdline = a:cmdline
    while len(cmdline)
	let cl = cmdline
	if cmdline =~ '^\s*%'
	    let range = matchstr(cmdline, '^\s*%\s*')
	    return [range, cmdline[len(range):], 0]
	elseif &cpoptions !~ '\*' && cmdline =~ '^\s*\*'
	    let range = matchstr(cmdline, '^\s*\*\s*')
	    return [range, cmdline[len(range):], 0]
	elseif cmdline =~ '^\s*\d'
	    let add = matchstr(cmdline, '\v^\s*\d+'.s:range_modifier)
	    let range .= add
	    let cmdline = cmdline[len(add):]
	    echom 1
	    " echom range
	elseif cmdline =~ '^\s*[-+]'
	    let add = matchstr(cmdline, '\v^\s*'.s:range_modifier)
	    let range .= add
	    let cmdline = cmdline[len(add):]
	    echom 2
	elseif cmdline =~ '^\.\s*'
	    let add = matchstr(cmdline, '\v^\s*\.'.s:range_modifier)
	    let range .= add
	    let cmdline = cmdline[len(add):]
	    echom 3
	    " echom range
	elseif cmdline =~ '^\s*\\[&/?]'
	    let add = matchstr(cmdline, '^\v\s*\\[/&?]'.s:range_modifier)
	    let range .= add
	    let cmdline = cmdline[len(add):]
	    echom 4
	    " echom range
	elseif cmdline =~ '^\s*[?/]'
	    let add = matchstr(cmdline, '^\v\s*[?/]@=')
	    let range .= add
	    let cmdline = cmdline[len(add):]
	    let [char, pattern] = vimlparsers#ParsePattern(cmdline)
	    " echom cmdline.":".add.":".char.":".pattern
	    let range .= char . pattern . char
	    let cmdline = cmdline[len(pattern)+2:]
	    let add = matchstr(cmdline, '^\v'.s:range_modifier)
	    let range .= add
	    let cmdline = cmdline[len(add):]
	    echom 5
	    " echom range . "<F>".cmdline."<"
	elseif cmdline =~ '^\s*\$'
	    let add = matchstr(cmdline, '\v^\s*\$'.s:range_modifier)
	    let range .= add
	    let cmdline = cmdline[len(add):]
	    echom 6
	    " echom range
	elseif cmdline =~ '^\v[[:space:];,]+'  " yes you can do :1,^t;;; ,10# and it will work like :1,10#
	    let add = matchstr(cmdline,  '^\v[[:space:];,]+')
	    let range .= add
	    let cmdline = cmdline[len(add):]
	    echom 7
	elseif cmdline =~ '^\v\s*[''`][a-zA-Z<>`'']'
	    let add = matchstr(cmdline, '^\v\s*[''`][a-zA-Z<>`'']') 
	    let range .= add
	    let cmdline = cmdline[len(add):]
	elseif cmdline =~ '^\s*\w'
	    return [range, cmdline, 0]
	endif
	if cl == cmdline
	    " Parser didn't make a step (so it falls into a loop)
	    " for example when there is no range, or for # command
	    return [range, cmdline, 1]
	endif
    endwhile
    return [range, cmdline, 0]
endfun " }}}

fun! vimlparsers#ParsePattern(line, ...) " {{{
    " Parse /pattern/ -> return ['/', 'pattern']
    " this is useful for g/pattern/ type command
    if a:0 >= 1
	let escape_char = a:1
    else
	let escape_char = '\'
    endif
    let char = a:line[0]
    let line = a:line[1:]
    let pattern = ''
    let escapes = 0
    for nchar in split(line, '\zs')
	if nchar == escape_char
	    let escapes += 1
	endif
	if nchar !=# char || (escapes % 2)
	    let pattern .= nchar
	else
	    break
	endif
	if nchar != escape_char
	    let escapes = 0
	endif
    endfor
    return [char, pattern]
endfun " }}}

fun! vimlparsers#ParseString(str)  "{{{
    let i = 0
    while i < len(a:str)
	let i += 1
	let c = a:str[i]
	if c != "'"
	    cont
	else
	    if a:str[i+1] == "'"
		let i += 1
		con
	    else
		break
	    endif
	endif
    endwhile
    return a:str[:i]
endfun  "}}}

let s:s_cmd_pat = '^\v\C\s*('.
	    \ 'g%[lobal]|'.
	    \ 'v%[global]'.
	    \ 'vim%[grep]|'.
	    \ 'lv%[imgrep]'.
	    \ ')\s*'

" s:CmdLineClass {{{
let s:CmdLineClass = {
	    \ 'decorator': '',
	    \ 'range': '',
	    \ 'cmd': '',
	    \ 'pattern': '',
	    \ 'args': '',
	    \ }
fun! s:CmdLineClass.Join() dict
    return self['decorator'].self['range'].self['cmd'].self['pattern'].self['args']
endfun  "}}}

fun! vimlparsers#ParseCommandLine(cmdline, cmdtype)  "{{{
    " returns command line splitted by |
    let cmdlines = []
    let check_range = 1
    let idx = 0
    let cmdl = copy(s:CmdLineClass)
    let global = 0
    if a:cmdtype == '/' || a:cmdtype == '?'
	let cmdl.pattern = a:cmdline
	call add(cmdlines, cmdl)
	return cmdlines
    endif
    let cmdline = a:cmdline
    while !empty(cmdline)
	if check_range == 1
	    let decorator = matchstr(cmdline, '^\s*\(sil\%[ent]!\=\s*\|debug\s*\|\d*verb\%[ose]\s*\)*')
	    let cmdline = cmdline[len(decorator):]
	    if !global
		let cmdl.decorator = decorator
	    else
		let cmdl.args = decorator
	    endif
	    echo "cmdline: " . cmdline
	    let [range, cmdline, error] = vimlparsers#ParseRange(cmdline)
	    echo range.":".cmdline.":".error
	    let check_range = 0
	    if !global
		let cmdl.range = range
	    else
		let cmdl.args .= range
	    endif
	    let idx += len(range) + 1
	    let after_range = 1
	    con
	else
	    let after_range = 0
	endif
	let match = matchstr(cmdline, s:s_cmd_pat)
	if !empty(match)
	    let _global = global
	    if cmdline =~ '^\v\C\s*(g%[lobal]|v%[global])'
		let global = 1
	    endif
	    if !_global
		let cmdl.cmd .= match
	    else
		let cmdl.args .= match
	    endif
	    let idx += len(match)
	    let cmdline = cmdline[len(match):]
	    let [char, pat] = vimlparsers#ParsePattern(cmdline)
	    if !_global
		let cmdl.pattern .= char.pat
	    else
		let cmdl.args .= char.pat
	    endif
	    let d = len(char.pat)
	    let idx += d
	    let cmdline = cmdline[(d):]
	    if cmdline[0] == char
		if !_global
		    let cmdl.pattern .= char
		else
		    let cmdl.args .= char
		endif
		let idx += 1
		let cmdline = cmdline[1:]
	    endif
	    let idx += 1
	    con
	endif
	let match = matchstr(cmdline, '^\v\s*s%[ubstitute]\s*') 
	if !empty(match)
	    if !global
		let cmdl.cmd .= match
	    else
		let check_range = 1
		let cmdl.args .= match
	    endif
	    let d = len(match)
	    let idx += d
	    let cmdline = cmdline[(d):]
	    let [char, pat] = vimlparsers#ParsePattern(cmdline)
	    if !global
		let cmdl.pattern .= char.pat
	    else
		let cmdl.args .= char.pat
	    endif
	    let d = len(char.pat)
	    let idx += d
	    let cmdline = cmdline[(d):]
	    let [char, pat] = vimlparsers#ParsePattern(cmdline)
	    let cmdl.args .= char.pat
	    let d = len(char.pat)
	    let idx += d
	    let cmdline = cmdline[(d):]
	    if cmdline[0] == char
		let idx += 1
		if !global
		    let cmdl.args .= char
		else
		    let cmdl.args .= char
		endif
		let cmdline = cmdline[1:]
		let flags = matchstr(cmdline, '^\C[\&cegiInp#lr[:space:]]*')
		let cmdl.args .= flags
		let cmdline = cmdline[len(flags):]
	    endif
	    let idx += 1
	    con
	endif
	let match = matchstr(cmdline, '^\v\s*norm%[al]!?[[:space:]^a-zA-Z].*')
	if !empty(match)
	    if !global
		let cmdl.cmd .= match
	    else
		let cmdl.args .= match
	    endif
	    break
	endif
	let c = cmdline[0]
	if c ==# '"'
	    let [char, str] = vimlparsers#ParsePattern(cmdline)
	    if !empty(cmdl.pattern)
		let cmdl.args .= char.str.char
	    else
		let cmdl.cmd .= char.str.char
	    endif
	    let d= len(char.str.char)
	    let idx += d + 1
	    let cmdline = cmdline[(d):]
	    con
	elseif c ==# "'"
	    let str = vimlparsers#ParseString(cmdline)
	    if !empty(cmdl.pattern)
		let cmdl.args .= str
	    else
		let cmdl.cmd .= str
	    endif
	    let d = len(str)
	    let idx += d + 1
	    let cmdline = cmdline[(d):]
	    con
	elseif c ==# "|"
	    call add(cmdlines, cmdl)
	    let cmdline = cmdline[1:]
	    let cmdl = copy(s:CmdLineClass)
	    let idx += 1
	    let check_range = 1
	    let global = 0
	    con
	else
	    if !empty(cmdl.pattern)
		let cmdl.args .= c
	    else
		let cmdl.cmd .= c
	    endif
	    let idx += 1
	    let cmdline = cmdline[1:]
	endif
    endwhile
    call add(cmdlines, cmdl) 
    return cmdlines
endfun  "}}}