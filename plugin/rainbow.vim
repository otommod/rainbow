"==============================================================================
"Script Title: rainbow parentheses improved
"Script Version: 3.3.4
"Author: luochen1990
"Last Edited: 2015 June 15
"Simple Configuration:
"   first, put "rainbow.vim"(this file) to dir vimfiles/plugin or vim73/plugin
"   second, restart your vim and enjoy coding.
"Advanced Configuration:
"   an advanced configuration allows you to define what parentheses to use
"   for each type of file . you can also determine the colors of your
"   parentheses by this way (read file vim73/rgb.txt for all named colors).
"   READ THE SOURCE FILE FROM LINE 25 TO LINE 50 FOR EXAMPLE.
"User Command:
"   :RainbowToggle      --you can use it to toggle this plugin.
"==============================================================================

if exists("g:loaded_rainbow") || &cp || v:version < 700
    finish
endif
let g:loaded_rainbow = 1


let s:rainbow_conf = {
\   'guifgs': ['royalblue3', 'darkorange3', 'seagreen3', 'firebrick'],
\   'ctermfgs': ['lightblue', 'lightyellow', 'lightcyan', 'lightmagenta'],
\   'operators': '_,_',
\   'parentheses': ['start=/(/ end=/)/ fold', 'start=/\[/ end=/\]/ fold', 'start=/{/ end=/}/ fold'],
\   'separately': {
\       '*': {},
\       'lisp': {
\           'guifgs': ['royalblue3', 'darkorange3', 'seagreen3', 'firebrick', 'darkorchid3'],
\       },
\       'tex': {
\           'parentheses': ['start=/(/ end=/)/', 'start=/\[/ end=/\]/'],
\       },
\       'vim': {
\           'parentheses': ['start=/(/ end=/)/', 'start=/\[/ end=/\]/', 'start=/{/ end=/}/ fold', 'start=/(/ end=/)/ containedin=vimFuncBody', 'start=/\[/ end=/\]/ containedin=vimFuncBody', 'start=/{/ end=/}/ fold containedin=vimFuncBody'],
\       },
\       'xml': {
\           'parentheses': ['start=/\v\<\z([-_:a-zA-Z0-9]+)(\s+[-_:a-zA-Z0-9]+(\=("[^"]*"|'."'".'[^'."'".']*'."'".'))?)*\>/ end=#</\z1># fold'],
\       },
\       'xhtml': {
\           'parentheses': ['start=/\v\<\z([-_:a-zA-Z0-9]+)(\s+[-_:a-zA-Z0-9]+(\=("[^"]*"|'."'".'[^'."'".']*'."'".'))?)*\>/ end=#</\z1># fold'],
\       },
\       'html': {
\           'parentheses': ['start=/\v\<((area|base|br|col|embed|hr|img|input|keygen|link|menuitem|meta|param|source|track|wbr)[ >])@!\z([-_:a-zA-Z0-9]+)(\s+[-_:a-zA-Z0-9]+(\=("[^"]*"|'."'".'[^'."'".']*'."'".'|[^ '."'".'"><=`]*))?)*\>/ end=#</\z1># fold'],
\       },
\       'php': {
\           'parentheses': ['start=/\v\<((area|base|br|col|embed|hr|img|input|keygen|link|menuitem|meta|param|source|track|wbr)[ >])@!\z([-_:a-zA-Z0-9]+)(\s+[-_:a-zA-Z0-9]+(\=("[^"]*"|'."'".'[^'."'".']*'."'".'|[^ '."'".'"><=`]*))?)*\>/ end=#</\z1># fold',
\                           'start=/(/ end=/)/ containedin=@htmlPreproc contains=@phpClTop',
\                           'start=/\[/ end=/\]/ containedin=@htmlPreproc contains=@phpClTop',
\                           'start=/{/ end=/}/ containedin=@htmlPreproc contains=@phpClTop'],
\       },
\       'css': 0,
\   }
\}

function! s:parse(s)
    let confdict = {}
    let args = split(a:s, '\v%(%(start|skip|end)\=(.)%(\1@!.)*\1[^ ]*|\w+%(\=[^ ]*)?) ?\zs', 0)
    for a in args
        let [key; rest] = split(a, "=", 1)
        let val = len(rest) ? join(rest, "=") : 1
        let confdict[key] = val
    endfor
    return confdict
endfunction

function! s:unparse(d)
    let [pattern, containedin, contains] = [[], "", "TOP"]
    for key in keys(a:d)
        let val = a:d[key]
        if key == "containedin"
            let containedin = val
        elseif key == "contains"
            let contains = val

        elseif val is 1
            call add(pattern, key)
        elseif val is 0
            " pass
        else
            call add(pattern, key."=".val)
        endif
    endfor
    return [join(pattern), containedin, contains]
endfunction

function! rainbow#normalize_conf(conf)
    let conf = deepcopy(a:conf)
    let parens = conf.parentheses
    for i in range(len(parens))
        let p = parens[i]

        if type(p) == type("")
            let d = s:parse(p)
        elseif type(p) == type([])
            let d = {"start": printf("|%s|", p[0]),
                   \   "end": printf("|%s|", p[-1])}
        elseif type(p) == type({})
            let d = copy(p)
        endif

        let parens[i] = s:unparse(d)
        unlet p
    endfor
    return conf
endfunction

function! rainbow#load()
    let def_rg = 'syn region %s matchgroup=%s containedin=%s contains=%s,@NoSpell %s'
    let def_op = 'syn match %s %s containedin=%s contained'

    call rainbow#clear()
    let conf = rainbow#normalize_conf(b:rainbow_conf)
    let maxlvl = has('gui_running') ? len(conf.guifgs) : len(conf.ctermfgs)
    let b:rainbow_loaded = maxlvl
    for [paren, containedin, contains] in conf.parentheses
        if containedin == ''
            execute printf(def_rg, 'rainbow_r0', 'rainbow_p0', 'rainbow_r'.(maxlvl - 1), contains, paren)
        else
            execute printf(def_rg, 'rainbow_r0', 'rainbow_p0 contained', containedin.',rainbow_r'.(maxlvl - 1), contains, paren)
        endif

        if has_key(conf, "operators") && conf.operators != ''
            for lvl in range(maxlvl)   " [0, 1, ..., maxlvl-1]
                execute printf(def_op, 'rainbow_o'.lvl, conf.operators, 'rainbow_r'.lvl)
            endfor
        endif
        for lvl in range(1, maxlvl-1)  " [1, 2, ..., maxlvl-1]
            exe printf(def_rg, 'rainbow_r'.lvl, 'rainbow_p'.lvl.' contained', 'rainbow_r'.((lvl + maxlvl - 1) % maxlvl), contains, paren)
        endfor
    endfor
    call rainbow#show()
endfunction

function! rainbow#clear()
    call rainbow#hide()
    if exists('b:rainbow_loaded')
        for each in range(b:rainbow_loaded)
            exe 'syn clear rainbow_r'.each
            exe 'syn clear rainbow_o'.each
        endfor
        unlet b:rainbow_loaded
    endif
endfunction

function! rainbow#show()
    if exists('b:rainbow_loaded')
        let b:rainbow_visible = 1
        for id in range(b:rainbow_loaded)
            let ctermfg = b:rainbow_conf.ctermfgs[id % len(b:rainbow_conf.ctermfgs)]
            let guifg = b:rainbow_conf.guifgs[id % len(b:rainbow_conf.guifgs)]
            exe 'hi default rainbow_p'.id.' ctermfg='.ctermfg.' guifg='.guifg
            exe 'hi default rainbow_o'.id.' ctermfg='.ctermfg.' guifg='.guifg
        endfor
    endif
endfunction

function! rainbow#hide()
    if exists('b:rainbow_visible')
        for each in range(b:rainbow_loaded)
            exe 'hi clear rainbow_p'.each
            exe 'hi clear rainbow_o'.each
        endfor
        unlet b:rainbow_visible
    endif
endfunction

function! rainbow#toggle()
    if exists('b:rainbow_loaded')
        call rainbow#clear()
    elseif exists('b:rainbow_conf')
        call rainbow#load()
    else
        call rainbow#hook()
    endif
endfunction

function! rainbow#hook()
    let g_conf = extend(copy(s:rainbow_conf), exists('g:rainbow_conf') ? g:rainbow_conf : {}) |unlet g_conf.separately
    if exists('g:rainbow_conf.separately') && has_key(g:rainbow_conf.separately, '*')
        let separately = copy(g:rainbow_conf.separately)
    else
        let separately = extend(copy(s:rainbow_conf.separately), exists('g:rainbow_conf.separately') ? g:rainbow_conf.separately : {})
    endif
    let b_conf = has_key(separately, &ft) ? separately[&ft] : separately['*']
    if type(b_conf) == type({})
        let b:rainbow_conf = extend(g_conf, b_conf)
        call rainbow#load()
    endif
endfunction

command! RainbowToggle call rainbow#toggle()
command! RainbowToggleOn call rainbow#load()
command! RainbowToggleOff call rainbow#clear()

if (exists('g:rainbow_active') && g:rainbow_active)
    auto syntax * call rainbow#hook()
    auto colorscheme * call rainbow#show()
endif
