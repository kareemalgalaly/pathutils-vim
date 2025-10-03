scriptencoding utf-8

" ------------------------------------------------------------------------------
" REGEX CONVERSION

function! pathutils#invert_escape(string, char)
    let string = substitute(a:string, a:char, '\\' . a:char, 'g')
    let string = substitute(string, '\\\\'.a:char, a:char, 'g')
    return string
    "return substitute(string, '\\' . a:char, a:char, 'g')
endfunction

function! pathutils#reg2vreg(regex)
    let viregex = pathutils#invert_escape(a:regex, '+')
    let viregex = pathutils#invert_escape(viregex, '?')
    let viregex = pathutils#invert_escape(viregex, '(')
    let viregex = pathutils#invert_escape(viregex, '|')
    let viregex = pathutils#invert_escape(viregex, ')')
    let viregex = substitute(viregex, '\b', '(\<|\>)', 'g')
    "let viregex = pathutils#invert_escape(viregex, '[')
    "let viregex = pathutils#invert_escape(viregex, ']')
    return viregex
endfunction

function! pathutils#vreg2reg(viregex)
    let regex = pathutils#invert_escape(a:viregex, '+')
    let regex = pathutils#invert_escape(regex, '?')
    let regex = pathutils#invert_escape(regex, '(')
    let regex = pathutils#invert_escape(regex, '|')
    let regex = pathutils#invert_escape(regex, ')')
    let regex = substitute(regex, '\>', '\b', 'g')
    let regex = substitute(regex, '\<', '\b', 'g')
    "let viregex = pathutils#invert_escape(viregex, '[')
    "let viregex = pathutils#invert_escape(viregex, ']')
    return regex
endfunction

function! pathutils#matchcount(text, regex)
    return len(split(a:text, a:regex, 1)) - 1
endfunction

" ------------------------------------------------------------------------------
" FILE DESCRIPTIONS
" Note: '*' only allowed in non-perforce paths with unique shell (glob) expansion

let s:fchar = '[*a-zA-Z_=.\-0-9+]' 
let s:fopen = pathutils#reg2vreg('(\~|/|\.\.?|'.s:fchar.'+)')
let s:fbody = pathutils#reg2vreg('(/'.s:fchar.'+)+')
let s:flino = pathutils#reg2vreg('(\s*(,|:|(;|,)? line (= )?|\()([1-9][0-9]*)\)?)')
let s:fpath = '\(' . s:fopen . '\?' . s:fbody . '\)'
let s:ffull = s:fpath . s:flino . '\?'

let g:pathutils_full = s:ffull
let g:pathutils_path = s:fpath 
let g:pathutils_lino = s:flino

" ------------------------------------------------------------------------------
" MAIN UTILITIES

function! pathutils#splitpath(path)
    " return [path, lineno] or [path] or [] depending on what is found
    let _match = matchlist(a:path, s:ffull)

    if _match == []
        return []
    endif

    "let _path = _match[1]
    "let _lino = _match[8]

    return [_match[1], _match[8]]
endfunction

" tests
"echo pathutils#splitpath("~/.vimrc:10")
"echo pathutils#splitpath("~/.vimrc; line = 10")

function! pathutils#openpath(flags, ...)
    let _line = getline(line('.'))

    let _relative = and(a:flags, 1) " open relative to current file
    let _vsplit   = and(a:flags, 2) " open in a vertical split
    let _hsplit   = and(a:flags, 4) " open in a horizontal split 
    let _rsplit   = and(a:flags, 8) " flip side of the split

    let split_size = get(a:, 1, "")

    let _line = pathutils#matchinternal(_line, s:ffull, col('.')-1)
    let _match = pathutils#splitpath(_line)

    if _match != []

        " Resolve Path
        let _path = _match[0]
        if (_relative && _path[0] != "~" && _path[0] != "/" && expand("%:h") != "")
            let _path = pathutils#resolvepath(expand("%:h") . "/" . _path)
        else
            let _path = pathutils#resolvepath(_path)
        endif

        " Get Line number
        let _num   = _match[1]

        " New window command
        if (_vsplit)
            if (split_size != "")
                let split_size = float2nr(winwidth("%") * split_size)
            endif
            let _cmd   = split_size . "vnew "

        elseif (_hsplit)
            if (split_size != "")
                let split_size = float2nr(winheight("%") * split_size)
            endif
            let _cmd   = split_size."new "

        else
            let _cmd   = "tabnew "
        endif
    
        if _num != ""
            let _cmd = _cmd . " +" . _num . " "
        endif

        execute _cmd . _path 
        if (_rsplit)
            wincmd r
        endif
    else
        echo "Nothing to open"
    endif
endfunction

function! pathutils#resolvepath(path)
    let _path = a:path

    " Perforce paths
    if (_path[0] == "/" && _path[1] == "/")
        let eval = system("p4 where " . _path)
        let _path = split(eval, " ")[2]
    endif

    " Simplify path > relative path if possible
    if (_path[0] != "." && _path[0] != "~")
        let cwd = "^" . getcwd() . "/"
        let _path = substitute(_path, cwd, "", "")
    endif

    return _path
endfunction

" ------------------------------------------------------------------------------
" BUFFER RUN

let s:runbuffer_cnt = 1
function! pathutils#runbuffer(cmd, reuse)
    let cmd = split(a:cmd, " ")[0]
    if a:reuse == 1
        %d _
    else
        execute "tabnew Run".s:runbuffer_cnt."-".cmd
        let s:runbuffer_cnt = s:runbuffer_cnt + 1
    endif

    let cmd = join(["%", a:cmd, "\n\n"])
    put!=cmd
    execute "normal! G"
    put!=system(a:cmd)
    if a:reuse == 0
        setlocal nobuflisted buftype=nofile bufhidden=wipe noswapfile
        setlocal ft=log
    endif
    execute "normal! gg"
    nnoremap <buffer> <CR> :call pathutils#runbufferline(1)<CR>
endfunction

function! pathutils#runbufferline(...)
    " Optional argument: expected_linenumber - reuse the buffer and only act when the current line is the given number
    if a:0 == 1 && a:1 != line('.') | return | endif 
    let cmd = getline(line('.'))
    if cmd[0] != "%"
        echo "Not a command"
    else
        let cmd = cmd[2:]
        call pathutils#runbuffer(cmd, a:0 == 1) 
    endif
endfunction


" ------------------------------------------------------------------------------
" MISC UTILITIES

function! pathutils#matchinternal(text, regex, index)
    let _m = match(a:text, a:regex)

    while (_m != -1 && _m <= a:index)
        let _match = matchstr(a:text, a:regex, _m)
        let _m = len(_match) + _m + 1
        if (_m > a:index)
            return _match
        endif
        let _m = match(a:text, a:regex, _m)
    endwhile

    return ""
endfunction

let s:background_mode = &background

function! pathutils#invertcolors()
    let color = g:colors_name
    let backg = s:background_mode

    "if &background == "light"
    if backg == "light"
        let s:background_mode = "dark"
        set background=dark
    else
        let s:background_mode = "light"
        set background=light
    endif
    redraw
    execute "colorscheme ".color
endfunction

function! pathutils#getscriptsid(scriptname)
    " {'version': 1, 'name': '/usr/share/vim/vim90/autoload/netrw.vim', 'autoload': v:false, 'sid': 53, 'sourced': 0}
    let scriptinfo = getscriptinfo()
    for info in scriptinfo
        if info['name'] =~ a:scriptname
            return info['sid']
        endif
    endfor
    return "None"
endfunction

function! pathutils#getscriptfunc(scriptname, funcname)
    let sid = pathutils#getscriptsid(a:scriptname)
    let Funcref = function("<SNR>".sid."_".a:funcname)
    return Funcref
endfunction

function! pathutils#callscriptfunc(scriptname, funcname, arglist)
    echo call(pathutils#getscriptfunc(a:scriptname, a:funcname), a:arglist)
endfunction

" ------------------------------------------------------------------------------
" EXAMPLES

" demo  ~/.vimrc things
" demo  /home/kareem/.vimrc things
" demo  /home/kareem/.vimrc:20 things
" demo  ../.vimrc things
" demo  ./.vimrc things
" demo2 ~/.vimrc,20 other things
" demo2 ~/.vimrc:25 other things
" demo2 ~/.vimrc line 40 other things
" demo3 //perforce/path/file things
