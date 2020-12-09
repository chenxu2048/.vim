""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"         __  ___   _ _ ____   __     _____ __  __           "
"         \ \/ / | | ( ) ___|  \ \   / /_ _|  \/  |          "
"          \  /| | | |/\___ \   \ \ / / | || |\/| |          "
"          /  \| |_| |  ___) |   \ V /  | || |  | |          "
"         /_/\_\\___/  |____/     \_/  |___|_|  |_|          "
"                                                            "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" UTILITY FUNCTIONS {{{
" FUNCTION s:get_visual_selection, from xolox: {{{
"       https://stackoverflow.com/a/6271254
function! s:get_visual_selection()
    " Why is this not a built-in Vim script function?!
    let [line_start, column_start] = getpos("'<")[1:2]
    let [line_end, column_end] = getpos("'>")[1:2]
    let lines = getline(line_start, line_end)
    if len(lines) == 0
        return ''
    endif
    let lines[-1] = lines[-1][: column_end - (&selection == 'inclusive' ? 1 : 2)]
    let lines[0] = lines[0][column_start - 1:]
    return join(lines, "\n")
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
        Plug 'airblade/vim-gitgutter'
        Plug 'junegunn/fzf.vim'
        Plug 'junegunn/vim-plug'
        Plug 'mbbill/undotree'
        Plug 'octol/vim-cpp-enhanced-highlight', { 'for': ['cpp', 'c'] }
        Plug 'tomasiser/vim-code-dark'
        Plug 'tpope/vim-surround'
        Plug 'yianwillis/vimcdoc'

        " airline <- nerdtree <- nerdtree-git-plugin <- devicons
        Plug 'vim-airline/vim-airline'
        Plug 'preservim/nerdtree'
        Plug 'xuyuanp/nerdtree-git-plugin'
        Plug 'ryanoasis/vim-devicons'

        " coc <- coc-fzf
        Plug 'neoclide/coc.nvim', {'branch': 'release'}
        Plug 'antoinemadec/coc-fzf', {'branch': 'release'}

        " vim-misc <- vim-session
        " Plug 'xolox/vim-misc'
        " Plug 'xolox/vim-session'
    call plug#end()
    " }}}
endfunction
" }}}

" FUNCTION s:gui_config loads configuration for gvim {{{
function! s:gui_config()
    set guifont=NotoMono\ Nerd\ Font\ Mono\ Patched\ 12,NotoMono\ Nerd\ Font\ \Mono\ Regular\ 12,Noto\ Mono\ for\ Powerline\ 12
    set guifont=NotoMono\ Nerd\ Font\ \Mono\ Regular\ 12,Noto\ Mono\ for\ Powerline\ 12
    set guifontwide=Noto\ Sans\ CJK\ SC\ 12
    set guioptions-=T
    set guioptions-=L
    set guioptions-=r
    set guioptions-=m
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
    set relativenumber

    " set tab and space
    set smarttab
    set expandtab
    set tabstop=4
    set softtabstop=4
    set shiftwidth=4

    set incsearch
    set showcmd
    set hidden

    " set cursor
    set cursorcolumn
    set cursorline
    highlight CursorLine   cterm=NONE ctermbg=black ctermfg=NONE guibg=black guifg=NONE
    highlight CursorColumn cterm=NONE ctermbg=black ctermfg=NONE guibg=black guifg=NONE

    " sync register ", reister + with register 0
    set clipboard^=unnamed
    augroup HijackNetrw
        autocmd BufEnter,VimEnter * call <SID>hijack_and_cd(expand('<amatch>'))
    augroup END
endfunction
" }}}

" FUNCTION s:keymap_config defines keymaps {{{
function! s:keymap_config()
    " KEYMAP EXTENSION {{{
    " vim-plug
    noremap <Leader>xi :PlugInstall<CR>
    noremap <Leader>xu :PlugUpdate<CR>
    noremap <Leader>xd :PlugClean<CR>

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
    noremap <Leader>E :NERDTreeClose<CR>
    noremap <Leader>l :NERDTreeFind<CR>
    noremap <Leader>e :call <SID>nerdtree_focus_or_close()<CR>
    " reset NERDTree
    noremap <Leader><Leader>e <C-w>31\|

    " coc
    nmap <Leader>cr <Plug>(coc-rename)
    nmap <Leader>cf <Plug>(coc-format)
    xmap <Leader>cf <Plug>(coc-format-selected)
    nmap <Leader>co :call CocAction('runCommand', 'editor.action.organizeImport')<CR>
    nmap <Leader>gt <Plug>(coc-type-definiction)
    nmap <Leader>gr <Plug>(coc-references)
    nmap <Leader>gd <Plug>(coc-definition)
    nmap <Leader>gi <Plug>(coc-implementation)

    nmap <C-f> <Plug>(coc-format)
    xmap <C-f> <Plug>(coc-format-selected)
    nmap <C-Return> <Plug>(coc-implementation)
    nmap <Return> <Plug>(coc-hover)

    nnoremap <Leader>cc :CocFzfList<CR>

    inoremap <silent><expr> <TAB>
        \ pumvisible() ? "\<C-n>" :
        \ <SID>check_back_space() ? "\<TAB>" :
        \ coc#refresh()
    inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"
    inoremap <expr> <CR> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"

    " fzf
    nnoremap <Leader>p :FZF<CR>
    nnoremap <Leader>f :Rg<CR>
    xnoremap <Leader>f <Esc>:Rg <C-R>=<SID>get_visual_selection()<CR><CR>
    nmap <Leader>zm <Plug>(fzf-maps-n)
    xmap <Leader>zm <Plug>(fzf-maps-x)
    imap <Leader>zm <Plug>(fzf-maps-i)

    nnoremap <Leader>zb :Buffers<CR>
    nnoremap <Leader>zr :Command<CR>
    nnoremap <Leader>zg :GitFiles?<CR>
    " KEMAP EXTENSION END }}}

    " KEYMAP EDITOR {{{
    " paste using ctrl-p
    inoremap <C-p> <Esc>"*pa
    cnoremap <C-p> <C-r>*
    " paste using ctrl-v
    inoremap <C-v> <Esc>"*pa
    cnoremap <C-v> <C-r>*

    " sort
    vnoremap <C-s> :sort<CR>
    vnoremap <C-r> :sort!<CR>

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

    " I hate q@recording :-\
    nnoremap <Leader><Leader>Q q
    nnoremap q <Nop>

    " reload vimrc
    noremap <Leader><Leader>v :source ~/.vim/vimrc<CR>
    " exit all
    noremap <Leader><Leader>q :qa!<CR>
    noremap <Leader>w :w<CR>
    " KEYMAP EDITOR END }}}
endfunction
" }}}

" FUNCTION s:extionsion_config loads configuration for extensions {{{1
function! s:extionsion_config()
    " vim-plug {{{2
    let g:plug_window = 'tabnew'

    " NERDTree {{{2
    let g:NERDTreeStatusline = ''
    let g:NERDTreeShowHidden = 1
    let g:NERDTreeMinimalUI = 1
    let g:NERDTreeHijackNetrw = 1
    let g:NERDTreeChDirMode = 1
    let g:NERDTreeShowHidden = 1
    let g:NERDTreeIgnore = ['\.git/$']
    " prevent opening other in nerdtree buffer
    " autocmd BufEnter * if bufname('#') =~# "^NERD_tree_" && winnr('$') > 1 | b# | endif
    command! -n=0 -bar NERDTreeFocusOrClose call s:nerdtree_focus_or_close()

    " devicons {{{2
    let g:webdevicons_conceal_nerdtree_brackets = 1
    let g:WebDevIconsUincodeDecorateFolderNodes = 0
    let g:WebDevIconsNerdTreeGitPluginForceVAlign = 1
    let g:WebDevIconsUnicodeGlyphDoubleWidth = 0
    let g:WebDevIconsNerdTreeAfterGlyphPadding = ''
    let g:WebDevIconsTabAirLineBeforeGlyphPadding = ' '

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

    " vim-session {{{2
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
