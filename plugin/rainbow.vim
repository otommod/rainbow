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

if exists("g:loaded_rainbow")
    finish
endif
let g:loaded_rainbow = 1


let s:rainbow_conf = {
\   'guifgs': ['royalblue3', 'darkorange3', 'seagreen3', 'firebrick'],
\   'ctermfgs': ['lightblue', 'lightyellow', 'lightcyan', 'lightmagenta'],
\   'operators': '_,_',
\   'parentheses': [{'start': '/(/',  'end': '/)/',  'fold': 1},
\                   {'start': '/\[/', 'end': '/\]/', 'fold': 1},
\                   {'start': '/{/',  'end': '/}/',  'fold': 1}],
\   'separately': {
\       '*': {},
\       'lisp': {
\           'guifgs': ['royalblue3', 'darkorange3', 'seagreen3', 'firebrick', 'darkorchid3'],
\       },
\       'tex': {
\           'parentheses': [['/(/', '/)/'], ['/\[/', '/\]/']],
\       },
\       'vim': {
\           'parentheses': [['/(/', '/)/'], ['/\[/', '/\]/'], {'start': '/{/', 'end': '/}/', 'fold': 1},
\                           {'start':  '/(/', 'end':  '/)/', 'containedin': 'vimFuncBody'},
\                           {'start': '/\[/', 'end': '/\]/', 'containedin': 'vimFuncBody'},
\                           {'start':  '/{/', 'end':  '/}/', 'containedin': 'vimFuncBody', 'fold': 1}],
\       },
\       'xml': {
\           'parentheses': [{'start': '/\v\<\z([-_:a-zA-Z0-9]+)(\s+[-_:a-zA-Z0-9]+(\=("[^"]*"|''[^'']*''))?)*\>/', 'end': '#</\z1>#', 'fold': 1}],
\       },
\       'xhtml': {
\           'parentheses': [{'start': '/\v\<\z([-_:a-zA-Z0-9]+)(\s+[-_:a-zA-Z0-9]+(\=("[^"]*"|''[^'']*''))?)*\>/', 'end': '#</\z1>#', 'fold': 1}],
\       },
\       'html': {
\           'parentheses': [{'start': '/\v\<((area|base|br|col|embed|hr|img|input|keygen|link|menuitem|meta|param|source|track|wbr)[ >])@!\z([-_:a-zA-Z0-9]+)(\s+[-_:a-zA-Z0-9]+(\=("[^"]*"|''[^'']*''|[^ ''"><=`]*))?)*\>/',
\                            'end': '#</\z1>#', 'fold': 1}],
\       },
\       'php': {
\           'parentheses': [{'start': '/\v\<((area|base|br|col|embed|hr|img|input|keygen|link|menuitem|meta|param|source|track|wbr)[ >])@!\z([-_:a-zA-Z0-9]+)(\s+[-_:a-zA-Z0-9]+(\=("[^"]*"|''[^'']*''|[^ ''"><=`]*))?)*\>/',
\                            'end': '#</\z1>#', 'fold': 1},
\                           {'start':  '/(/', 'end':  '/)/', 'containedin': '@htmlPreproc', 'contains': '@phpClTop'},
\                           {'start': '/\[/', 'end': '/\]/', 'containedin': '@htmlPreproc', 'contains': '@phpClTop'},
\                           {'start':  '/{/', 'end':  '/}/', 'containedin': '@htmlPreproc', 'contains': '@phpClTop'}],
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

function! s:normalize_conf(conf)
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

function! s:make_syntax(conf)
    let def_rg = 'syntax region %s matchgroup=%s containedin=%s contains=%s,@NoSpell %s'
    let def_op = 'syntax match %s %s containedin=%s contained'

    let maxlvl = has('gui_running') ? len(a:conf.guifgs) : len(a:conf.ctermfgs)
    for [paren, containedin, contains] in a:conf.parentheses
        if containedin == ''
            execute printf(def_rg, 'rainbow_r0', 'rainbow_p0', 'rainbow_r'.(maxlvl - 1), contains, paren)
        else
            execute printf(def_rg, 'rainbow_r0', 'rainbow_p0 contained', containedin.',rainbow_r'.(maxlvl - 1), contains, paren)
        endif

        if has_key(a:conf, "operators") && a:conf.operators != ''
            for lvl in range(maxlvl)   " [0, 1, ..., maxlvl-1]
                execute printf(def_op, 'rainbow_o'.lvl, a:conf.operators, 'rainbow_r'.lvl)
            endfor
        endif
        for lvl in range(1, maxlvl-1)  " [1, 2, ..., maxlvl-1]
            exe printf(def_rg, 'rainbow_r'.lvl, 'rainbow_p'.lvl.' contained', 'rainbow_r'.((lvl + maxlvl - 1) % maxlvl), contains, paren)
        endfor
    endfor
    return maxlvl
endfunction

function! s:define_colors(levels, ctermfgs, guifgs)
    for lvl in range(a:levels)
        let guifg = a:guifgs[lvl % len(a:guifgs)]
        let ctermfg = a:ctermfgs[lvl % len(a:ctermfgs)]
        execute 'highlight default rainbow_p'.lvl.' ctermfg='.ctermfg.' guifg='.guifg
        execute 'highlight default rainbow_o'.lvl.' ctermfg='.ctermfg.' guifg='.guifg
    endfor
endfunction

function! s:clear_colors(levels)
    for lvl in range(a:levels)
        execute 'highlight clear rainbow_p'.lvl
        execute 'highlight clear rainbow_o'.lvl
    endfor
endfunction

function! rainbow#load()
    let g:rainbow_conf = exists('g:rainbow_conf') ? g:rainbow_conf : {}
    let g:rainbow_conf.separately = exists('g:rainbow_conf.separately') ? g:rainbow_conf.separately : {}

    let g_conf = extend(copy(s:rainbow_conf), g:rainbow_conf)
    unlet g_conf.separately

    " The user's "*" config always takes precedence over any script defined
    " filetype specific setting.
    if has_key(g:rainbow_conf.separately, '*')
        let separately = copy(g:rainbow_conf.separately)
    else
        let separately = extend(copy(s:rainbow_conf.separately), g:rainbow_conf.separately)
    endif

    let b_conf = has_key(separately, &ft) ? separately[&ft] : separately['*']
    if type(b_conf) != type({}) | return | endif

    call rainbow#unload()
    let conf = s:normalize_conf(extend(g_conf, b_conf))
    let b:loaded_rainbow = s:make_syntax(conf)
    call s:define_colors(b:loaded_rainbow, conf.ctermfgs, conf.guifgs)

    augroup rainbow
        autocmd!
        autocmd Syntax * call rainbow#load()
        autocmd ColorScheme * call rainbow#load()
    augroup END
endfunction

function! rainbow#unload()
    if exists('b:loaded_rainbow')
        call s:clear_colors(b:loaded_rainbow)
        for lvl in range(b:loaded_rainbow)
            execute 'syntax clear rainbow_r'.lvl
            execute 'syntax clear rainbow_o'.lvl
        endfor
        unlet b:loaded_rainbow

        augroup rainbow
            autocmd!
        augroup END
    endif
endfunction

function! rainbow#toggle()
    if !exists('b:loaded_rainbow')
        call rainbow#load()
    else
        call rainbow#unload()
    endif
endfunction

command! RainbowToggle call rainbow#toggle()
command! RainbowToggleOn call rainbow#load()
command! RainbowToggleOff call rainbow#unload()

if exists('g:rainbow_active') && g:rainbow_active
    RainbowToggleOn
endif
