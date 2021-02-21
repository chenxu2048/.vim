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

" UTILITY FUNCTIONS {{{
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
    let l:selected = s:get_visual_selection(l:escape)->escape('\"')
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
            let l:glob_args = l:glob->copy()->map({_, val -> [ '-g', val ]})
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
    let l:vim_plug_home = expand('~/.vim/plug')
    let l:vim_plug_path = expand(l:vim_plug_home . '/vim-plug')
    execute 'set rtp+=' . l:vim_plug_path
    " https://github.com/junegunn/vim-plug
    runtime plug.vim

    " vim plugin list {{{
    call plug#begin(l:vim_plug_home)
        Plug 'Yggdroot/LeaderF', { 'do': ':LeaderfInstallCExtension' }
        Plug 'airblade/vim-gitgutter'
        Plug 'chenxu2048/leaderf-enhanced'
        Plug 'junegunn/fzf.vim'
        Plug 'junegunn/vim-plug'
        Plug 'mbbill/undotree'
        Plug 'neoclide/coc.nvim', {'branch': 'release'}
        Plug 'octol/vim-cpp-enhanced-highlight', { 'for': ['cpp', 'c'] }
        Plug 'tomasiser/vim-code-dark'
        Plug 'tpope/vim-surround'
        Plug 'yianwillis/vimcdoc'

        " airline <- nerdtree <- nerdtree-git-plugin <- devicons
        Plug 'vim-airline/vim-airline'
        Plug 'preservim/nerdtree'
        Plug 'xuyuanp/nerdtree-git-plugin'
        Plug 'ryanoasis/vim-devicons'
    call plug#end()
    " }}}
endfunction
" }}}

" FUNCTION s:gui_config loads configuration for gvim {{{
function! s:gui_config()
    set guifont=Noto\ Sans\ Mono\ 12
    set guifontwide=Noto\ Sans\ CJK\ SC\ 11 " 测试
    set guioptions=acdiMk
    set guiheadroom=0
endfunction
" }}}

" FUNCTION s:editor_config loads configuration for vim editor {{{
function! s:editor_config()
    set encoding=utf-8
    set t_Co=256
    set t_ut=

    " we disable mouse
    set mouse=

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
    set showcmd
    set hidden

    set foldmethod=syntax
    set foldlevel=99
    set undodir=~/.vim/.cache/undo//
    set backupdir=~/.vim/.cache/backup//
    set directory=~/.vim/.cache/swap//
    set undofile
    set undolevels=200

    " left right arrow cross line
    set whichwrap=b,s,<,>,[,]
    " cursor can move over insert position
    set backspace=indent,eol,nostop
    " set pair of %
    set matchpairs+=<:>
    " set cursor
    set cursorcolumn
    set cursorline
    " sync register ", reister + with register 0
    set clipboard^=unnamedplus
    augroup HijackNetrw
        autocmd BufEnter,VimEnter * call <SID>hijack_and_cd(expand('<amatch>'))
    augroup END

    let g:large_file = 10 * 1024 * 1024 " 10MB
    augroup LargeFile
        au BufReadPre * call <SID>check_large_file(g:large_file)
    augroup END
    autocmd TerminalOpen * setlocal nonumber norelativenumber
endfunction
" }}}

" FUNCTION s:keymap_config defines keymaps {{{
function! s:keymap_config()
    " KEYMAP EXTENSION {{{
    " vim-plug
    noremap <Leader>xi :PlugInstall<CR>
    noremap <Leader>xu :PlugUpdate<CR>
    noremap <Leader>xd :PlugClean<CR>

    " undotree
    noremap <silent> <Leader>u :<C-U>call <SID>undotree_focus_or_close()<CR>

    " airline
    nmap <leader>1 <Plug>AirlineSelectTab1
    nmap <leader>2 <Plug>AirlineSelectTab2
    nmap <leader>3 <Plug>AirlineSelectTab3
    nmap <leader>4 <Plug>AirlineSelectTab4
    nmap <leader>5 <Plug>AirlineSelectTab5
    nmap <leader>6 <Plug>AirlineSelectTab6
    nmap <leader>7 <Plug>AirlineSelectTab7
    nmap <leader>8 <Plug>AirlineSelectTab8
    nmap <leader>9 <Plug>AirlineSelectTab9

    " NERDTree
    noremap <silent> <Leader>e :call <SID>nerdtree_focus_or_close()<CR>
    noremap <silent> <Leader><Leader>e :NERDTreeFind<CR>
    noremap <silent> <Leader>E :NERDTreeClose<CR>
    " reset NERDTree
    noremap <silent> <Leader><Leader>E <C-w>31\|

    " coc
    nmap <Leader>cr <Plug>(coc-rename)
    nmap <Leader>cf <Plug>(coc-format)
    xmap <Leader>cf <Plug>(coc-format-selected)
    nmap <Leader>co :call CocAction('runCommand', 'editor.action.organizeImport')<CR>
    nmap <Leader>gt <Plug>(coc-type-definiction)
    nmap <Leader>gr <Plug>(coc-references)
    nmap <Leader>gd <Plug>(coc-definition)
    nmap <Leader>gi <Plug>(coc-implementation)
    noremap ]w :<C-U>call CocActionAsync('diagnosticNext', 'warning')<CR>
    noremap [w :<C-U>call CocActionAsync('diagnosticPrevious', 'warning')<CR>
    nmap ]e <Plug>(coc-diagnostic-next-error)
    nmap [e <Plug>(coc-diagnostic-prev-error)

    nmap <C-Return> <Plug>(coc-implementation)
    nmap <Return> <Plug>(coc-hover)

    nnoremap <Leader>cc :CocList<CR>

    inoremap <silent><expr> <TAB>
        \ pumvisible() ? "\<C-n>" :
        \ <SID>check_back_space() ? "\<TAB>" :
        \ coc#refresh()
    inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"
    inoremap <expr> <CR> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"

    " LeaderF
    nnoremap <silent> <Leader><Leader>f :<C-U>call <SID>set_rg_glob()<CR>
    nnoremap <silent> <Leader>f         :<C-U>call <SID>run_rg_interactive()<CR>
    nnoremap <silent> <Leader>F         :<C-U>call <SID>run_rg_interactive('-w')<CR>
    nnoremap <silent> <Leader>lb        :<C-U>LeaderfBuffer<CR>
    nnoremap <silent> <Leader>lc        :<C-U>LeaderfCommand<CR>
    nnoremap <silent> <Leader>lw        :<C-U>LeaderfWindow<CR>
    nnoremap <silent> <leader>lh        :<C-U>LeaderfHelp<CR>
    nnoremap <silent> <Leader>p         :<C-U>LeaderfFile<CR>
    nnoremap <silent> <leader>/         :<C-U>LeaderfLine<CR>

    xnoremap <silent> <Leader>F         :<C-U>call <SID>run_rg_command("-w", "-F")<CR>
    xnoremap <silent> <Leader>R         :<C-U>call <SID>run_rg_command("-w")<CR>
    xnoremap <silent> <Leader>f         :<C-U>call <SID>run_rg_command("-F")<CR>
    xnoremap <silent> <Leader>r         :<C-U>call <SID>run_rg_command()<CR>
    xnoremap <silent> <Leader>/         :<C-U>Leaderf line --input "<C-R>=<SID>get_visual_selection('"')<CR>"<CR>
    xnoremap <silent> <Leader>p         :<C-U>Leaderf file --input "<C-R>=<SID>get_visual_selection('"')<CR>"<CR>

    noremap <silent> <Leader>lm        :<C-U>Leaderf map<CR>
    " KEMAP EXTENSION END }}}

    " KEYMAP EDITOR {{{
    " paste using ctrl-p
    inoremap <C-p> <Esc>"+pa
    cnoremap <C-p> <C-r>+
    " paste using ctrl-v
    inoremap <C-v> <Esc>"+pa
    cnoremap <C-v> <C-r>+

    tnoremap <C-S-v> <C-W>"+
    tnoremap <C-Esc> <C-W>N

    " sort
    vnoremap <C-s> :sort<CR>
    vnoremap <C-r> :sort!<CR>

    " search
    vnoremap <C-/> <Esc>/<C-R>=<SID>get_vim_search_selection()<CR>
    vnoremap <C-?> <Esc>?<C-R>=<SID>get_vim_search_selection()<CR>

    " unbind navigation keys
    noremap <Up> <Nop>
    noremap <Down> <Nop>
    noremap <Left> <Nop>
    noremap <Right> <Nop>
    noremap <C-Left> <Nop>
    noremap <C-Right> <Nop>
    noremap <S-Left> <Nop>
    noremap <S-Right> <Nop>
    noremap <PageUp> <Nop>
    noremap <PageDown> <Nop>

    nnoremap <C-P> gT
    nnoremap <C-N> gt

    nnoremap <C-Right> <C-w>l
    nnoremap <C-Left> <C-w>h
    nnoremap <C-Up> <C-w>k
    nnoremap <C-Down> <C-w>j

    " I hate Q to Ex mode :-\
    nnoremap <Leader><Leader>Q Q
    nnoremap Q <Nop>

    " I hate q@recording, too :-\
    nnoremap <Leader><Leader>q q
    nnoremap q <Nop>

    " reload vimrc
    noremap <silent> <Leader><Leader>v :<C-U>source ~/.vim/vimrc<CR>:call <SID>reset_filetype()<CR>
    noremap <silent> <Leader>v :<C-U>tabedit ~/.vim/vimrc<CR>
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
    tnoremap <silent> <C-W>1 <C-W>:tabnext 1<CR>
    tnoremap <silent> <C-W>2 <C-W>:tabnext 2<CR>
    tnoremap <silent> <C-W>3 <C-W>:tabnext 3<CR>
    tnoremap <silent> <C-W>4 <C-W>:tabnext 4<CR>
    tnoremap <silent> <C-W>5 <C-W>:tabnext 5<CR>
    tnoremap <silent> <C-W>6 <C-W>:tabnext 6<CR>
    tnoremap <silent> <C-W>7 <C-W>:tabnext 7<CR>
    tnoremap <silent> <C-W>8 <C-W>:tabnext 8<CR>
    tnoremap <silent> <C-W>9 <C-W>:tabnext 9<CR>

    " KEYMAP EDITOR END }}}
endfunction
" }}}

" FUNCTION s:extionsion_config loads configuration for extensions {{{1
function! s:extionsion_config()
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
    let g:NERDTreeIgnore = ['\.git/$', '__pycache__']
    let g:NERDTreeDirArrowExpandable = "🢒"
    let g:NERDTreeDirArrowCollapsible = "▾"
    " prevent opening other in nerdtree buffer
    " autocmd BufEnter * if bufname('#') =~# "^NERD_tree_" && winnr('$') > 1 | b# | endif
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

    " vim-gitgutter {{{2
    let g:gitgutter_sign_added              = '+'
    let g:gitgutter_sign_modified           = '~'
    let g:gitgutter_sign_removed            = '_'
    let g:gitgutter_sign_removed_first_line = '‾'
    let g:gitgutter_sign_removed_above_and_below = '‾_'
    let g:gitgutter_sign_modified_removed   = '~_'

    " airline {{{2
    let g:airline_powerline_fonts = 1
    let g:airline#extensions#tabline#enabled = 1
    let g:airline#extensions#tabline#show_buffers = 0

    " coc {{{2
    " autocmd BufWritePre *.go :call CocAction('runCommand', 'editor.action.organizeImport')
    " }}}2
    " leaderf {{{2
    let g:Lf_StlColorscheme = 'codedark'
    let g:Lf_PopupColorscheme = 'codedark'
    let g:Lf_WindowPosition = 'bottom'
    let g:Lf_DefaultMode = 'FullPath'
    let g:Lf_ReverseOrder = 1
    let g:Lf_AutoResize = 0
    let g:Lf_ShowHidden = 1
    let g:Lf_ShortcutF = '<leader>p'
    let g:Lf_ShortcutB = '<leader>lb'
    let g:Lf_PopupHeight = 0.5
    let g:Lf_StlSeparator = { 'left': '', 'right': '' }
    let g:Lf_SpinSymbols = [ '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇','⠏' ]

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

    " }}}2
endfunction
" }}}1

" FUNCTION s:init {{{
function! s:init() abort
    set nocompatible
    call s:extionsion_config()
    call s:plugin_load()
    call s:keymap_config()
    call s:gui_config()
    call s:editor_config()
endfunction
" }}}

" SECTION INITIALIZATION {{{
source $VIMRUNTIME/delmenu.vim
let mapleader = ' '
call s:init()
" SECTION INITIALIZATION END }}
" vim: set shiftwidth=4 softtabstop=4 expandtab foldmethod=marker foldlevel=1:
