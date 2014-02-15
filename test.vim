" Title: Test suite for CRDispatcher, EnchantedVim
" Author: Marcin Szamotulski
"
" the replace string has to end with a '/' to recognize |:
let g:VeryMagic = 1
let g:VeryMagicSubstitute = 1
let g:VeryMagicGlobal = 1
let g:VeryMagicVimGrep = 1
let g:VeryMagicRange = 1
let g:VeryMagicSearchArg = 1
let g:VeryMagicEscapeBackslashesInSearchArg = 1

let s:test_id = 0
let s:failed = 0
fun! s:Test(cmd, res, type, ...)
    let s:test_id += 1
    let f = 'dispatch'
    if a:0 >= 1 && a:1 == 1
	let tres = vimlparsers#ParseCommandLine(a:cmd, a:type)
	let f = 'ParseCommandLine'
    else
	let tres = g:CRDispatcher.dispatch(0, a:cmd, a:type)
	let f = 'dispatch'
    endif
    let failed = 0
    if f ==# 'dispatch'
	if tres != a:res
	    let failed = 1
	endif
    elseif f ==# 'ParseCommandLine'
	if len(a:res) != len(tres)
	    let failed = 1
	else
	    for idx in range(0, len(a:res)-1)
		let _cmd=a:res[idx]
		let _tcmd=tres[idx]
		for f in ['decorator', 'range', 'cmd', 'pattern', 'args']
		    if _cmd[f] != _tcmd[f]
			let failed = 1
			break
		    endif
		endfor
		if failed
		    break
		endif
	    endfor
	endif
    endif
    if failed
	let s:failed += 1
	echohl WarningMsg
	echom 'test '.s:test_id.' failed'
	echohl Normal
	echom string(a:res)
	echohl ErrorMsg
	echom string(tres)
	echohl Normal
    endif
endfun

let cmd="ls"
let res=cmd
call s:Test(cmd, res, ':')

let cmd="ls|ls"
let res=cmd
call s:Test(cmd, res, ':')

let cmd="set path=this\\|is\\ a\\ strange\\ path|ls"
let res="set path=this\\|is\\ a\\ strange\\ path|ls"
call s:Test(cmd, res, ':')
let _res=[ {'cmd': 'set path=this\|is\ a\ strange\ path', 'range': '', 'pattern': '', 'global': 0, 'decorator': '', 'args': '' }, {'cmd': 'ls', 'range': '', 'pattern': '', 'global': 0, 'decorator': '', 'args': '' }]
call s:Test(cmd, _res, ':', 1)

let cmd="! ls|grep -v 'vim'"
let res="echo system(\"ls|grep -v 'vim'\")|call histdel(':', -1)"
let _res=[{'cmd': '! ls|grep -v ''vim''', 'range': '', 'pattern': '', 'global': 0, 'decorator': '', 'args': ''}]
call s:Test(cmd, res, ':')
call s:Test(cmd, _res, ':', 1)

let cmd="ls|! ls|grep -v 'vim'"
let res="ls|echo system(\"ls|grep -v 'vim'\")|call histdel(':', -1)"
let _res=[{'cmd': 'ls', 'range': '', 'pattern': '', 'global': 0, 'decorator': '', 'args': ''}, {'cmd': '! ls|grep -v ''vim''', 'range': '', 'pattern': '', 'global': 0, 'decorator': '', 'args': ''}]
call s:Test(cmd, res, ':')
call s:Test(cmd, _res, ':', 1)

let cmd=" :: % s #<x>#\\u\\&|/(a|b)/;$normal 10|D"
" There is no # before # so the s command should consume till the end of the
" line.
let res=" :: % s #\\v<x>#\\u\\&|/(a|b)/;$normal 10|D"
let _res=[{'cmd': 's ', 'range': '% ', 'pattern': '#<x>#', 'global': 0, 'decorator': ' :: ', 'args': '\u\&|/(a|b)/;$normal 10|D'}]
call s:Test(cmd, res, ':')
call s:Test(cmd, _res, ':', 1)

let cmd=" :: % s #<x>#\\u\\&#|/(a|b)/;$normal 10|D"
let res=" :: % s #\\v<x>#\\u\\&#|/\\v(a|b)/;$normal 10|D"
let _res=[{'cmd': 's ', 'range': '% ', 'pattern': '#<x>#', 'global': 0, 'decorator': ' :: ', 'args': '\u\&#'}, {'cmd': 'normal 10|D', 'range': '/(a|b)/;$', 'pattern': '', 'global': 0, 'decorator': '', 'args': ''}]
call s:Test(cmd, res, ':')
" FAILS:
call s:Test(cmd, _res, ':', 1)

let cmd="'<,'>s/(ccc|ddd)/\\U&E/"
let res="'<,'>s/\\v(ccc|ddd)/\\U&E/"
let _res=[{'cmd': 's', 'range': '''<,''>', 'pattern': '/(ccc|ddd)/', 'global': 0, 'decorator': '', 'args': '\U&E/'}]
call s:Test(cmd, res, ':')
call s:Test(cmd, _res, ':', 1)

let cmd="'<,'>s/(ccc|ddd)/\\U&E/|ls"
let res = "'<,'>s/\\v(ccc|ddd)/\\U&E/|ls"
let _res=[{'cmd': 's', 'range': '''<,''>', 'pattern': '/(ccc|ddd)/', 'global': 0, 'decorator': '', 'args': '\U&E/'}, {'cmd': 'ls', 'range': '', 'pattern': '', 'global': 0, 'decorator': '', 'args': ''}]
call s:Test(cmd, res, ':')
call s:Test(cmd, _res, ':', 1)

let cmd="'<,'>g/(aaa|bbb)/.-,.+s/(ccc|ddd)/\\U&E/|normal 10|D"
let res = "'<,'>g/\\v(aaa|bbb)/.-,.+s/\\v(ccc|ddd)/\\U&E/|normal 10|D"
let _res=[{'cmd': 'g', 'range': '''<,''>', 'pattern': '/(aaa|bbb)/', 'global': 1, 'decorator': '', 'args': ''}, {'cmd': 's', 'range': '.-,.+', 'pattern': '/(ccc|ddd)/', 'global': 0, 'decorator': '', 'args': '\U&E/'}, {'cmd': 'normal 10|D', 'range': '', 'pattern': '', 'global': 0, 'decorator': '', 'args': ''}]
call s:Test(cmd, res, ':')
call s:Test(cmd, _res, ':', 1)

let cmd=" 't-;/(begin|end)/g//.-,.+#"
let res=" 't-;/\\v(begin|end)/g//.-,.+#"
let _res=[{'cmd': 'g', 'range': '''t-;/(begin|end)/', 'pattern': '//', 'global': 1, 'decorator': ' ', 'args': ''}, {'cmd': '#', 'range': '.-,.+', 'pattern': '', 'global': 0, 'decorator': '', 'args': ''}]
call s:Test(cmd, res, ':')
call s:Test(cmd, _res, ':', 1)

let cmd=""
let res=cmd
call s:Test(cmd, res, '/')

let cmd="(abc|def)/e+;/(begin|end)/b-4;?<secret>?"
let res="\\v(abc|def)/e+;/\\v(begin|end)/b-4;?\\v<secret>?"
call s:Test(cmd, res, '/')

let cmd="write ! aaa|bbb"
let res="write ! aaa|bbb"
let _res=[{'cmd': 'write ! aaa|bbb', 'range': '', 'pattern': '', 'global': 0, 'decorator': '', 'args': ''}]
call s:Test(cmd, res, ':')
call s:Test(cmd, _res, ':', 1)

let cmd="call g:CRDispacther.dispatch(0, cmd, ':')"
let _res = [{'cmd': 'call g:CRDispacther.dispatch(0, cmd, '':'')', 'range': '', 'pattern': '', 'global': 0, 'decorator': '', 'args': ''}]
call s:Test(cmd, _res, ':', 1)

let cmd="silent echo \"ok\"| debug ls"
let _res=[{'cmd': 'echo "ok"', 'range': '', 'pattern': '', 'global': 0, 'decorator': 'silent ', 'args': ''}, {'cmd': 'ls', 'range': '', 'pattern': '', 'global': 0, 'decorator': ' debug ', 'args': ''}]
call s:Test(cmd, _res, ':', 1)

if s:failed == 0
    echohl Title
    echom "All tests passed!"
else
    echohl WarningMsg
    echom s:failed . " test".(s:failed > 1 ? "s" : "") ." failed!"
endif
echohl Normal