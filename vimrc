""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"         __  ___   _ _ ____   __     _____ __  __           "
"         \ \/ / | | ( ) ___|  \ \   / /_ _|  \/  |          "
"          \  /| | | |/\___ \   \ \ / / | || |\/| |          "
"          /  \| |_| |  ___) |   \ V /  | || |  | |          "
"         /_/\_\\___/  |____/     \_/  |___|_|  |_|          "
"                                                            "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" SCOPED VARIABLES {{{
let s:rg_escape_chars = "^$+*?()[]{}\\"
let s:vim_search_escape_chars = "~^$.*/\\[]"
" }}}

" FUNCTION s:exit_nerdtree {{{
function! s:exit_nerdtree()
    let bufname = expand('%')
    if match(bufname, '^NERD_tree_') != -1 
        wincmd p
    endif
endfunction
" }}}

" FUNCTION s:get_visual_selection, from xolox: {{{
"       https://stackoverflow.com/a/6271254
function! s:get_visual_selection(escape_str)
    let [line_start, column_start] = getpos("'<")[1:2]
    let [line_end, column_end] = getpos("'>")[1:2]
    let lines = getline(line_start, line_end)
    if len(lines) == 0
        return ''
    endif
    let lines[-1] = lines[-1][: column_end - (&selection == 'inclusive' ? 1 : 2)]
    let lines[0] = lines[0][column_start - 1:]
    return escape(lines[0], a:escape_str)
endfunction
" }}}

" FUNCTION s:buffer_cleanup {{{
function! s:buffer_cleanup() abort
    let l:buffers = filter(getbufinfo(), {_, v -> !v.loaded && !v.listed})
    if !empty(l:buffers)
        execute 'bwipeout' join(map(l:buffers, {_, v -> v.bufnr}))
    endif
endfunction
" }}}

" FUNCTION s:get_vim_search_selection {{{
function s:get_vim_search_selection() abort
    return s:get_visual_selection(s:vim_search_escape_chars)
endfunction
" }}}

" FUNCTION s:get_rg_selection {{{
function s:get_rg_selection() abort
    return s:get_visual_selection(s:rg_escape_chars)
endfunction
" }}}

" FUNCTION s:run_rg_command run leaderf rg in visual {{{
function s:run_rg_command(...)
    let l:escape = s:rg_escape_chars
    if count(a:000, '-F')
        let l:escape = ''
    endif
    let l:selected = escape(s:get_visual_selection(l:escape), '\"')
    let l:rg = 'rg ' . join(a:000, ' ') . ' -e "' . l:selected . '"'
    let l:glob = get(s:, "rg_glob", [])
    if len(l:glob) != 0
        let l:rg = join([l:rg] + l:glob, " -g ")
    endif
    let g:rg = l:rg
    call leaderf#Any#start(0, l:rg)
endfunction
" }}}

" FUNCTION s:set_rg_glob set leaderf rg file pattern {{{
function s:set_rg_glob()
    let l:prev = get(s:, "rg_glob_raw", "*")
    let l:glob = input("Setting rg glob filter: ", l:prev)
    if l:glob =~ '^\s*$'
        let s:rg_glob = []
        let s:rg_glob_raw = "*"
        return
    endif
    let s:rg_glob_raw = l:glob
    let s:rg_glob = map(split(glob, '[ ,]\+'), 'v:val =~ ''^".*"$'' ? v:val : ''"''.v:val.''"''')
endfunction
" }}}

" FUNCTION s:run_rg_interactive run leaderf rg interactive {{{
function s:run_rg_interactive(...)
    try
        echohl Question
        let l:pattern = input('Search pattern: ')
        let l:pattern = escape(l:pattern,'"')
        let l:glob = get(s:, 'rg_glob', [])
        let g:glob = l:glob
        let l:rg_cmd = [ 'rg' ] + a:000
        if l:pattern !~ '^\s*$'
            let l:rg_cmd += [ '-e', '"' . l:pattern . '"']
        endif
        if len(l:glob) != 0
            let l:glob_args = map(copy(l:glob), {_, val -> [ '-g', val ]})
            let l:rg_cmd += flatten(l:glob_args)
            let g:rg_cmd = l:rg_cmd
        endif
        call leaderf#Any#start(0, join(l:rg_cmd, ' '))
    finally
        echohl None
    endtry
endfunction
" }}}

" FUNCTION s:reset_filetype {{{
function! s:reset_filetype() abort
    let &filetype = &filetype
endfunction
" }}}

" FUNCTION s:check_back_space for coc completion {{{
function! s:check_back_space() abort
    let col = col('.') - 1
    return !col || getline('.')[col - 1]  =~# '\s'
endfunction
" }}}

" FUNCTION s:nerdtree_focus_or_close {{{
function s:nerdtree_focus_or_close()
    if expand("%") =~# "^NERD_tree_"
        NERDTreeClose
    else
        NERDTreeFocus
    endif
endfunction
" }}}

" FUNCTION s:undotree_focus_or_close {{{
function s:undotree_focus_or_close()
    if expand("%") =~# "^undotree_"
        UndotreeHide
    else
        UndotreeShow
        UndotreeFocus
    endif
endfunction
" }}}

" FUNCTION s:check_large_file {{{
function! s:check_large_file(large_file)
    " Set options:
    "   eventignore+=FileType (no syntax highlighting etc
    "   assumes FileType always on)
    "   noswapfile (save copy of file)
    "   bufhidden=unload (save memory when other file is viewed)
    "   buftype=nowritefile (is read-only)
    "   undolevels=-1 (no undo possible)
    let l:filename=expand("<afile>")
    if getfsize(l:filename) > a:large_file
        set eventignore+=FileType
        setlocal noswapfile bufhidden=unload buftype=nowrite undolevels=-1
        if has('nvim')
            set inccommand=""
        endif
        set noincsearch
    else
        set eventignore-=FileType
    endif
endfunction
" }}}

" FUNCTION s:hijack_and_cd {{{
function s:hijack_and_cd(dir) abort
    if isdirectory(a:dir)
        execute 'cd ' . a:dir
    endif
endfunction
" }}}

" }}} END UTILITY

" FUNCTION s:plugin_load loads vim-plug and plugins {{{
function! s:plugin_load() abort
    let l:vim_plug_home = expand('$VIMHOME/plug')
    let l:vim_plug_path = expand(l:vim_plug_home . '/vim-plug')
    execute 'set rtp+=' . l:vim_plug_path
    " https://github.com/junegunn/vim-plug
    runtime plug.vim

    " vim plugin list {{{
    call plug#begin(l:vim_plug_home)
        Plug 'Yggdroot/LeaderF', { 'do': ':LeaderfInstallCExtension' }
        Plug 'mhinz/vim-signify'
        Plug 'chenxu2048/leaderf-enhanced'
        " Plug 'chenxu2048/coc-leaderf'
        Plug 'junegunn/vim-plug'
        Plug 'mbbill/undotree'
        Plug 'neoclide/coc.nvim', {'branch': 'release'}
        Plug 'octol/vim-cpp-enhanced-highlight', { 'for': ['cpp', 'c'] }
        Plug 'tomasiser/vim-code-dark'
        Plug 'tpope/vim-surround'
        " Plug 'yianwillis/vimcdoc'
        Plug 'voldikss/vim-floaterm'
        " Plug 'voldikss/LeaderF-floaterm'
        Plug 'mg979/vim-visual-multi', {'branch': 'master'}

        " airline <- nerdtree <- nerdtree-git-plugin <- devicons
        Plug 'vim-airline/vim-airline'
        Plug 'preservim/nerdtree'
        Plug 'xuyuanp/nerdtree-git-plugin'
        Plug 'ryanoasis/vim-devicons'

        Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app && yarn install'  }
        Plug 'liuchengxu/graphviz.vim'
        Plug 'udalov/kotlin-vim', { 'for': ['kotlin'] }
        Plug 'skywind3000/asynctasks.vim'
        Plug 'skywind3000/asyncrun.vim'
    call plug#end()
    " }}}
endfunction
" }}}

" FUNCTION s:editor_config loads configuration for vim editor {{{
function! s:editor_config()
    set encoding=utf-8
    set fileencodings=usc-bom,utf-8,euc-cn,cp936,default,latin1
    set t_Co=256
    set t_ut=

    " we disable mouse
    set mouse=

    augroup ColorSchemeHighlight
        autocmd!
        autocmd ColorScheme call <SID>highlight()
    augroup END
    colorscheme codedark

    " set invisible char
    set list
    set listchars=tab:›.,trail:•,extends:…,nbsp:.

    " set line number
    set number
    set norelativenumber

    " set tab and space
    set smarttab
    set expandtab
    set tabstop=4
    set softtabstop=4
    set shiftwidth=4

    set incsearch
    set hlsearch
    set showcmd
    set hidden

    set secure
    set exrc
    augroup CdExrc
        autocmd!
        autocmd DirChanged * set secure exrc
    augroup END

    set foldmethod=syntax
    set foldlevel=99
    set undodir=$VIMHOME/.cache/undo//
    set backupdir=$VIMHOME/.cache/backup//
    " set directory=$VIMHOME/.cache/swap//
    set directory=.,$VIMHOME/.cache/swap
    set undofile
    set undolevels=200

    " left right arrow cross line
    set whichwrap=b,s,<,>,[,]
    " cursor can move over insert position
    set backspace=indent,eol,start
    " set pair of %
    set matchpairs+=<:>
    " set cursor
    if has_key(g:, 'neovide_refresh_rate')
        set nocursorcolumn
    else
        set cursorcolumn
    end
    set cursorline
    " sync register ", reister + with register 0
    set clipboard^=unnamedplus

    augroup HijackNetrw
        autocmd!
        autocmd BufEnter,VimEnter * call <SID>hijack_and_cd(expand('<amatch>'))
    augroup END

    " disable some feature if file was larger than 10MB
    let g:large_file = 10 * 1024 * 1024 " 10MB
    augroup LargeFile
        autocmd!
        au BufReadPre * call <SID>check_large_file(g:large_file)
    augroup END

    " highlighting matched content while searching
    if has('nvim')
        set inccommand=nosplit
    endif

    " config terminal with mouse and nonumber
    if has('nvim')
        augroup TermNoNumber
            autocmd!
            autocmd TermOpen * setlocal nonumber norelativenumber
            " set mouse while term open first time
            autocmd TermOpen * set mouse=a
            " set mouse while term buffer enter
            autocmd TermOpen * autocmd BufWinEnter <buffer> set mouse=a
            " set mouse off while term buffer exit
            autocmd TermOpen * autocmd BufWinLeave <buffer> set mouse=
        augroup END
    else
        augroup TermNoNumber
            autocmd!
            autocmd TerminalOpen * setlocal nonumber norelativenumber
            " set mouse while term open first time
            autocmd TerminalOpen * set mouse=a
            " set mouse while term buffer enter
            autocmd TerminalOpen * autocmd BufWinEnter <buffer> set mouse=a
            " set mouse off while term buffer exit
            autocmd TerminalOpen * autocmd BufWinLeave <buffer> set mouse=
        augroup END
    endif
endfunction
" }}}

" FUNCTION s:keymap_config defines keymaps {{{
function! s:keymap_config()
    " KEYMAP EXTENSION {{{
    " asyncrun & asynctasks
    noremap <Leader>jl :Leaderf --nowrap task<CR>
    noremap <Leader>je :AsyncTaskEdit<CR>

    " vim-signify
    noremap <Leader>sp :<C-U>SignifyHunkDiff<CR>
    noremap <Leader>su :<C-U>SignifyHunkUndo<CR>
    noremap <Leader>sd :<C-U>SignifyDiff<CR>
    noremap <Leader>ss :<C-U>SignifyToggleHighlight<CR>

    " vim-plug
    noremap <Leader>xi :PlugInstall<CR>
    noremap <Leader>xu :PlugUpdate<CR>
    noremap <Leader>xd :PlugClean<CR>

    " undotree
    noremap <silent> <Leader>u :<C-U>call <SID>undotree_focus_or_close()<CR>

    " airline
    nmap <Leader>1 <Plug>AirlineSelectTab1
    nmap <Leader>2 <Plug>AirlineSelectTab2
    nmap <Leader>3 <Plug>AirlineSelectTab3
    nmap <Leader>4 <Plug>AirlineSelectTab4
    nmap <Leader>5 <Plug>AirlineSelectTab5
    nmap <Leader>6 <Plug>AirlineSelectTab6
    nmap <Leader>7 <Plug>AirlineSelectTab7
    nmap <Leader>8 <Plug>AirlineSelectTab8
    nmap <Leader>9 <Plug>AirlineSelectTab9

    " NERDTree
    noremap <silent> <Leader>e :call <SID>nerdtree_focus_or_close()<CR>
    noremap <silent> <Leader><Leader>e :NERDTreeFind<CR>
    noremap <silent> <Leader>E :NERDTreeClose<CR>
    " reset NERDTree
    noremap <silent> <Leader><Leader>E <C-w>31\|

    " coc
    nmap <Leader>cr <Plug>(coc-rename)
    nmap <Leader>cf <Plug>(coc-format)
    vmap <Leader>cf <Plug>(coc-format-selected)
    vmap <Leader>ca <Plug>(coc-codeaction)
    nmap <Leader>ca <Plug>(coc-codeaction-selected)
    nmap <Leader>co :<C-U>call CocActionAsync('runCommand', 'editor.action.organizeImport')<CR>
    nmap <Leader>cu :<C-U>CocUpdate<CR>
    nmap <Leader>cx :<C-U>CocRestart<CR><CR>
    nmap <Leader>ce :<C-U>CocConfig<CR>
    nmap <Leader>gt <Plug>(coc-type-definiction)
    nmap <Leader>gr <Plug>(coc-references)
    nmap <Leader>gd <Plug>(coc-definition)
    nmap <Leader>gi <Plug>(coc-implementation)
    noremap ]h :<C-U>call CocActionAsync('diagnosticNext', 'hint')<CR>
    noremap [h :<C-U>call CocActionAsync('diagnosticPrevious', 'hint')<CR>
    noremap ]w :<C-U>call CocActionAsync('diagnosticNext', 'warning')<CR>
    noremap [w :<C-U>call CocActionAsync('diagnosticPrevious', 'warning')<CR>
    nmap ]e <Plug>(coc-diagnostic-next-error)
    nmap [e <Plug>(coc-diagnostic-prev-error)

    nmap <Leader>ch :<C-U>:call CocActionAsync('doHover')<CR>
    vmap <Leader>ch :<C-U>:call CocActionAsync('doHover')<CR>

    nnoremap <Leader>cc :CocList<CR>

    inoremap <silent><expr> <TAB>
        \ pumvisible() ? "\<C-n>" :
        \ <SID>check_back_space() ? "\<TAB>" :
        \ coc#refresh()
    inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"
    inoremap <expr> <CR> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"

    if has('nvim-0.4.0') || has('patch-8.2.0750')
        nnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
        nnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
        inoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(1)\<cr>" : "\<Right>"
        inoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(0)\<cr>" : "\<Left>"
        vnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
        vnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
    endif

    " LeaderF
    nnoremap <silent> <Leader><Leader>f :<C-U>call <SID>exit_nerdtree() \| call <SID>set_rg_glob()<CR>
    nnoremap <silent> <Leader>f         :<C-U>call <SID>exit_nerdtree() \| call <SID>run_rg_interactive()<CR>
    nnoremap <silent> <Leader>F         :<C-U>call <SID>exit_nerdtree() \| call <SID>run_rg_interactive('-w')<CR>
    nnoremap <silent> <Leader>lb        :<C-U>call <SID>exit_nerdtree() \| LeaderfBuffer<CR>
    nnoremap <silent> <Leader>lc        :<C-U>call <SID>exit_nerdtree() \| LeaderfCommand<CR>
    nnoremap <silent> <Leader>lw        :<C-U>call <SID>exit_nerdtree() \| LeaderfWindow<CR>
    nnoremap <silent> <Leader>lh        :<C-U>call <SID>exit_nerdtree() \| LeaderfHelp<CR>
    nnoremap <silent> <Leader>lr        :<C-U>call <SID>exit_nerdtree() \| Leaderf register<CR>
    nnoremap <silent> <Leader>p         :<C-U>call <SID>exit_nerdtree() \| LeaderfFile<CR>
    nnoremap <silent> <Leader>/         :<C-U>call <SID>exit_nerdtree() \| LeaderfLine<CR>

    nnoremap <silent> <Leader>[         :<C-U>NERDTreeClose<CR><Plug>LeaderfGtagsDefinition
    nnoremap <silent> <Leader>tr        :<C-U>NERDTreeClose<CR><Plug>LeaderfGtagsReference
    nnoremap <silent> <Leader>td        :<C-U>NERDTreeClose<CR><Plug>LeaderfGtagsReference
    nnoremap <silent> <Leader>ts        :<C-U>NERDTreeClose<CR><Plug>LeaderfGtagsSymbol

    augroup LeaderFGtagReplaceTag
        autocmd!
        autocmd BufEnter * if len(tagfiles()) == 0 | nmap <buffer><silent> <C-]> <Plug>LeaderfGtagsDefinition| endif
    augroup END

    xnoremap <silent> <Leader>F         :<C-U>call <SID>exit_nerdtree() \| call <SID>run_rg_command("-w", "-F")<CR>
    xnoremap <silent> <Leader>R         :<C-U>call <SID>exit_nerdtree() \| call <SID>run_rg_command("-w")<CR>
    xnoremap <silent> <Leader>f         :<C-U>call <SID>exit_nerdtree() \| call <SID>run_rg_command("-F")<CR>
    xnoremap <silent> <Leader>r         :<C-U>call <SID>exit_nerdtree() \| call <SID>run_rg_command()<CR>
    xnoremap <silent> <Leader>/         :<C-U>call <SID>exit_nerdtree() \| Leaderf line --input "<C-R>=<SID>get_visual_selection('"')<CR>"<CR>
    xnoremap <silent> <Leader>p         :<C-U>call <SID>exit_nerdtree() \| Leaderf file --input "<C-R>=<SID>get_visual_selection('"')<CR>"<CR>

    noremap <silent> <Leader>lm        :<C-U>Leaderf map<CR>

    " KEYMAP floaterm {{{
    nnoremap <silent> <Leader>`         :<C-U>FloatermToggle<CR>
    nnoremap <silent> <Leader>~ :<C-U>FloatermNew<CR>
    tmap <silent> <C-X>                 <Plug>TermEsc:<C-U>FloatermHide<CR>
    tmap <silent> <M-Up>                <Plug>TermEsc:<C-U>FloatermPrev<CR>
    tmap <silent> <M-Down>              <Plug>TermEsc:<C-U>FloatermNext<CR>
    " KEYMAP floaterm END }}}

    " KEYMAP EXTENSION END }}}

    " KEYMAP EDITOR {{{
    " paste using ctrl-p
    inoremap <C-p> <Esc>"+pa
    cnoremap <C-p> <C-r>+
    " paste using ctrl-v
    inoremap <C-v> <Esc>"+pa
    cnoremap <C-v> <C-r>+
    noremap <C-W>c :<C-U>ccl<CR>

    tnoremap <C-S-v> <C-W>"+
    tnoremap <C-Esc> <C-W>N

    noremap <D-v> "+P
    vnoremap <D-v> "-d"+P
    inoremap <D-v> <C-r>+
    vnoremap <D-c> "+y
    inoremap <D-x> "+d

    " sort
    vnoremap <C-s> :sort<CR>
    vnoremap <C-r> :sort!<CR>

    " search
    vnoremap <Leader>/ <Esc>/<C-R>=<SID>get_vim_search_selection()<CR>
    vnoremap <Leader>? <Esc>?<C-R>=<SID>get_vim_search_selection()<CR>

    " close search highlight
    noremap <silent> <Leader><Esc> :<C-U>let @/ = ""<CR>
    noremap <silent> <Leader><Leader><Esc> :<C-U>for v in range(char2nr('a'), char2nr('z')) \| execute 'unlet @'. nr2char(v) \| endfor<CR>

    " unbind navigation keys
    noremap <Up>        <Nop>
    noremap <Down>      <Nop>
    noremap <Left>      <Nop>
    noremap <Right>     <Nop>
    noremap <C-Left>    <Nop>
    noremap <C-Right>   <Nop>
    noremap <S-Left>    <Nop>
    noremap <S-Right>   <Nop>
    noremap <PageUp>    <Nop>
    noremap <PageDown>  <Nop>

    " I hate Q to Ex mode :-\
    " nnoremap <Leader><Leader>Q Q
    " nnoremap Q <Nop>

    " I hate q@recording, too :-\
    " nnoremap <Leader><Leader>q q
    " nnoremap q <Nop>

    " reload vimrc
    noremap <silent> <Leader><Leader>v :<C-U>source $VIMHOME/vimrc \| source $VIMHOME/gvimrc \| call <SID>reset_filetype()<CR>
    noremap <silent> <Leader>v :<C-U>tabedit $VIMHOME/vimrc<CR>
    noremap <silent> <Leader><S-v> :<C-U>tabedit $VIMHOME/gvimrc<CR>
    " exit all
    noremap <silent> <Leader><C-q> :<C-U>qa!<CR>
    noremap <silent> <Leader>w :<C-U>w<CR>

    noremap <silent> <Leader>1 :tabnext 1<CR>
    noremap <silent> <Leader>2 :tabnext 2<CR>
    noremap <silent> <Leader>3 :tabnext 3<CR>
    noremap <silent> <Leader>4 :tabnext 4<CR>
    noremap <silent> <Leader>5 :tabnext 5<CR>
    noremap <silent> <Leader>6 :tabnext 6<CR>
    noremap <silent> <Leader>7 :tabnext 7<CR>
    noremap <silent> <Leader>8 :tabnext 8<CR>
    noremap <silent> <Leader>9 :tabnext 9<CR>
    noremap <silent> <C-W>1 :tabnext 1<CR>
    noremap <silent> <C-W>2 :tabnext 2<CR>
    noremap <silent> <C-W>3 :tabnext 3<CR>
    noremap <silent> <C-W>4 :tabnext 4<CR>
    noremap <silent> <C-W>5 :tabnext 5<CR>
    noremap <silent> <C-W>6 :tabnext 6<CR>
    noremap <silent> <C-W>7 :tabnext 7<CR>
    noremap <silent> <C-W>8 :tabnext 8<CR>
    noremap <silent> <C-W>9 :tabnext 9<CR>

    if has('nvim')
        tnoremap <silent> <Plug>TermTab1 <C-\><C-N>:<C-U>tabnext 1<CR>
        tnoremap <silent> <Plug>TermTab2 <C-\><C-N>:<C-U>tabnext 2<CR>
        tnoremap <silent> <Plug>TermTab3 <C-\><C-N>:<C-U>tabnext 3<CR>
        tnoremap <silent> <Plug>TermTab4 <C-\><C-N>:<C-U>tabnext 4<CR>
        tnoremap <silent> <Plug>TermTab5 <C-\><C-N>:<C-U>tabnext 5<CR>
        tnoremap <silent> <Plug>TermTab6 <C-\><C-N>:<C-U>tabnext 6<CR>
        tnoremap <silent> <Plug>TermTab7 <C-\><C-N>:<C-U>tabnext 7<CR>
        tnoremap <silent> <Plug>TermTab8 <C-\><C-N>:<C-U>tabnext 8<CR>
        tnoremap <silent> <Plug>TermTab9 <C-\><C-N>:<C-U>tabnext 9<CR>
        tnoremap <silent> <Plug>TermEsc <C-\><C-N>
        tnoremap <silent> <Plug>TermSlash <C-\><C-\>
        tnoremap <silent> <Plug>TermPrefix <C-\>
    else
        tnoremap <silent> <Plug>TermTab1 <C-W>N:<C-U>tabnext 1<CR>
        tnoremap <silent> <Plug>TermTab2 <C-W>N:<C-U>tabnext 2<CR>
        tnoremap <silent> <Plug>TermTab3 <C-W>N:<C-U>tabnext 3<CR>
        tnoremap <silent> <Plug>TermTab4 <C-W>N:<C-U>tabnext 4<CR>
        tnoremap <silent> <Plug>TermTab5 <C-W>N:<C-U>tabnext 5<CR>
        tnoremap <silent> <Plug>TermTab6 <C-W>N:<C-U>tabnext 6<CR>
        tnoremap <silent> <Plug>TermTab7 <C-W>N:<C-U>tabnext 7<CR>
        tnoremap <silent> <Plug>TermTab8 <C-W>N:<C-U>tabnext 8<CR>
        tnoremap <silent> <Plug>TermTab9 <C-W>N:<C-U>tabnext 9<CR>
        tnoremap <silent> <Plug>TermEsc <C-W>N
        tnoremap <silent> <Plug>TermSlash <C-W><C-\>
        tnoremap <silent> <Plug>TermPrefix <C-W>

        tnoremap <silent> <C-W> <C-W>.
    endif

    tmap <silent> <C-Y>      <Plug>TermEsc
    tmap <silent> <C-\>      <Plug>TermSlash
    tmap <silent> <C-V>      <Plug>TermEsc"+pi

    augroup FloatermHideAtOpen
        autocmd!
        if has('nvim')
            autocmd TermOpen * map <buffer> <C-X> :<C-U>FloatermHide<CR>
            autocmd TermOpen * map <buffer> gt :<C-U>FloatermNext<CR>
            autocmd TermOpen * map <buffer> gT :<C-U>FloatermPrev<CR>
            autocmd TermOpen * map <buffer> <silent> <M-Up> <Plug>TermEsc:<C-U>FloatermPrev<CR>
            autocmd TermOpen * map <buffer> <silent> <M-Down> <Plug>TermEsc:<C-U>FloatermNext<CR>
        else
            autocmd TerminalOpen * map <buffer> <C-X> :<C-U>FloatermHide<CR>
            autocmd TerminalOpen * map <buffer> gt :<C-U>FloatermNext<CR>
            autocmd TerminalOpen * map <buffer> gT :<C-U>FloatermPrev<CR>
            autocmd TerminalOpen * map <buffer> <silent> <M-Up> <Plug>TermEsc:<C-U>FloatermPrev<CR>
            autocmd TerminalOpen * map <buffer> <silent> <M-Down> <Plug>TermEsc:<C-U>FloatermNext<CR>
        endif
    augroup END

    nnoremap <silent> <ScrollWheelLeft> <nop>
    nnoremap <silent> <ScrollWheelRight> <nop>
    nnoremap <silent> <S-ScrollWheelLeft> <nop>
    nnoremap <silent> <S-ScrollWheelRight> <nop>
    nnoremap <silent> <C-ScrollWheelLeft> <nop>
    nnoremap <silent> <C-ScrollWheelRight> <nop>
    inoremap <silent> <ScrollWheelLeft> <nop>
    inoremap <silent> <ScrollWheelRight> <nop>
    inoremap <silent> <S-ScrollWheelLeft> <nop>
    inoremap <silent> <S-ScrollWheelRight> <nop>
    inoremap <silent> <C-ScrollWheelLeft> <nop>
    inoremap <silent> <C-ScrollWheelRight> <nop>
    vnoremap <silent> <ScrollWheelLeft> <nop>
    vnoremap <silent> <ScrollWheelRight> <nop>
    vnoremap <silent> <S-ScrollWheelLeft> <nop>
    vnoremap <silent> <S-ScrollWheelRight> <nop>
    vnoremap <silent> <C-ScrollWheelLeft> <nop>
    vnoremap <silent> <C-ScrollWheelRight> <nop>

    nmap <silent> <Leader>bd :call <SID>buffer_cleanup()<CR>
    " KEYMAP EDITOR END }}}
endfunction
" }}}

" FUNCTION s:extionsion_config loads configuration for extensions {{{1
function! s:extionsion_config()
    " asyncrun
    let g:asyncrun_open = &lines / 3
    let g:asynctasks_confirm = 0
    " vim-plug {{{2
    let g:plug_window = 'tabnew'

    " undotree {{{2
    let g:undotree_WindowLayout = 3

    " NERDTree {{{2
    let g:NERDTreeStatusline = ''
    let g:NERDTreeShowHidden = 1
    let g:NERDTreeMinimalUI = 1
    let g:NERDTreeHijackNetrw = 1
    let g:NERDTreeChDirMode = 1
    let g:NERDTreeShowHidden = 1
    let g:NERDTreeIgnore = get(g:, 'NERDTreeIgnore', [])
    let g:NERDTreeIgnore += ['^\.git$', '__pycache__', '\.s[a-u][a-z]$', '\.sv[a-uw-z]$', '\.sw[a-p]$']
    call sort(g:NERDTreeIgnore)
    call uniq(g:NERDTreeIgnore)
    let g:NERDTreeDirArrowExpandable = '▸'
    let g:NERDTreeDirArrowCollapsible = '▾'
    let g:NERDTreeMapUpdirKeepOpen = '<Nop>'
    let g:NERDTreeMapUpdir = '<Nop>'
    " prevent opening other in nerdtree buffer
    command! -n=0 -bar NERDTreeFocusOrClose call s:nerdtree_focus_or_close()

    " devicons {{{2
    let g:WebDevIconsUincodeDecorateFolderNodes = 0
    let g:WebDevIconsNerdTreeGitPluginForceVAlign = 1
    let g:WebDevIconsUnicodeGlyphDoubleWidth = 0
    if has("gui_running")
        let g:WebDevIconsNerdTreeAfterGlyphPadding = ''
    else
        let g:WebDevIconsNerdTreeAfterGlyphPadding = ' '
    endif
    let g:WebDevIconsTabAirLineBeforeGlyphPadding = ' '
    let g:webdevicons_conceal_nerdtree_brackets = 1

    " nerdtree-git-plugin {{{2
    let g:NERDTreeGitStatusIndicatorMapCustom = {
            \ 'Modified'  :'~',
            \ 'Staged'    :'+',
            \ 'Untracked' :'*',
            \ 'Renamed'   :'»',
            \ 'Unmerged'  :'=',
            \ 'Deleted'   :'-',
            \ 'Dirty'     :'×',
            \ 'Ignored'   :'·',
            \ 'Clean'     :'ø',
            \ 'Unknown'   :'?',
        \ }

    " vim-signify {{{2
    let g:signify_sign_add               = '+'
    let g:signify_sign_delete            = '—'
    let g:signify_sign_delete_first_line = '‾'
    let g:signify_sign_change            = '!'
    let g:signify_sign_change_delete     = g:signify_sign_change . g:signify_sign_delete_first_line

    " airline {{{2
    let g:airline_powerline_fonts = 1
    let g:airline#extensions#tabline#enabled = 1
    let g:airline#extensions#tabline#show_buffers = 0
    let g:airline#extensions#whitespace#enabled = 0

    " coc {{{2
    augroup CocOrganizeImport
        autocmd!
        autocmd BufWritePre *.go :silent call CocAction('runCommand', 'editor.action.organizeImport')
        autocmd BufWritePre *.go :call CocAction('format')
    augroup END

    if !has('macunix')
        let g:coc_borderchars = ["╌", "╎", "╌", "╎", "┌", "┐", "┘", "└"]
    endif
    " }}}2
    " leaderf {{{2
    let g:Lf_StlColorscheme = 'codedark'
    let g:Lf_PopupColorscheme = 'codedark'
    let g:Lf_WindowPosition = 'bottom'
    let g:Lf_DefaultMode = 'FullPath'
    let g:Lf_ReverseOrder = 1
    let g:Lf_AutoResize = 0
    let g:Lf_ShowHidden = 1
    let g:Lf_ShortcutF = '<Leader>p'
    let g:Lf_ShortcutB = '<Leader>lb'
    let g:Lf_PopupHeight = 0.5
    let g:Lf_StlSeparator = { 'left': '', 'right': '' }
    let g:Lf_SpinSymbols = [ '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇','⠏' ]
    let g:Lf_CacheDirectory = expand("$HOME/.cache")

    " <C-C>, <ESC> : quit from LeaderF.
    " <C-R> : switch between fuzzy search mode and regex mode.
    " <C-F> : switch between full path search mode and name only search mode.
    " <Tab> : switch to normal mode.
    " <C-V>, <S-Insert> : paste from clipboard.
    " <C-U> : clear the prompt.
    " <C-W> : delete the word before the cursor in the prompt.
    " <C-J>, <C-K> : navigate the result list.
    " <Up>, <Down> : recall last/next input pattern from history.
    " <2-LeftMouse> or <CR> : open the file under cursor or selected(when multiple files are selected).
    " <C-X> : open in horizontal split window.
    " <C-]> : open in vertical split window.
    " <C-T> : open in new tabpage.
    " <F5>  : refresh the cache.
    " <C-LeftMouse> or <C-S> : select multiple files.
    " <S-LeftMouse> : select consecutive multiple files.
    " <C-A> : select all files.
    " <C-L> : clear all selections.
    " <BS>  : delete the preceding character in the prompt.
    " <Del> : delete the current character in the prompt.
    " <Home>: move the cursor to the begin of the prompt.
    " <End> : move the cursor to the end of the prompt.
    " <Left>: move the cursor one character to the left.
    " <Right> : move the cursor one character to the right.
    " <C-P> : preview the result.
    " <C-Up> : scroll up in the popup preview window.
    " <C-Down> : scroll down in the popup preview window.
    " <C-o> : edit command under cursor. cmdHistory/searchHistory/command only
    " }}}2

    " floaterm {{{2
    let g:floaterm_width = 0.99
    let g:floaterm_height = 0.99
    " }}}2
endfunction
" }}}1

" FUNCTION s:highlight {{{
function! s:highlight() abort
    highlight SignifySignAdd    gui=bold guifg=LightGreen term=bold ctermfg=LightGreen
    highlight SignifySignDelete gui=bold guifg=Red term=bold ctermfg=Red
    highlight SignifySignChange gui=bold guifg=Yellow term=bold ctermfg=Yellow
    highlight SignifyLineAdd    gui=bold guibg=#264F78 term=bold ctermbg=24
    highlight SignifyLineDelete gui=bold guibg=#4B1818 term=bold ctermbg=52
    highlight SignifyLineChange gui=bold guibg=#4B5632 term=bold ctermbg=58
    highlight NonText           ctermfg=240 ctermbg=None guifg=#5A5A5A guibg=None
endfunction
" }}}

" FUNCTION s:init {{{
function! s:init() abort
    set nocompatible
    call s:extionsion_config()
    call s:plugin_load()
    call s:keymap_config()
    call s:editor_config()
    call s:highlight()
endfunction
" }}}

" SECTION INITIALIZATION {{{ 
let mapleader = ' '
let $VIMHOME=expand('<sfile>:p:h')
call s:init()
" SECTION INITIALIZATION END }}

" vim: set shiftwidth=4 softtabstop=4 expandtab foldmethod=marker foldlevel=1:
