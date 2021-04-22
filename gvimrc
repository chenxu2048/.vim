if has("win32")
    let g:guifont = ['Consolas NF', 14]
    let g:guifontwide = ['Microsoft YaHei', 14] " 测试中文
else
    let g:guifont = ['Consolas NF', 14]
    let g:guifontwide = ['Noto Sans CJK SC', 13]
endif

function! s:format_font(font, size) abort
    if has("win32") || has("nvim")
        return substitute(a:font . ":h" . a:size, " ", "\\\\ ", "g")
    endif
    return substitute(a:font . " " . a:size, " ", "\\\\ ", "g")
endfunction

function! s:gui_font() abort
    let [font, size] = g:guifont
    execute "set guifont+=" . s:format_font(font, size)
    let [font, size] = g:guifontwide
    execute "set guifontwide+=" . s:format_font(font, size)
endfunction

" FUNCTION s:gui_config loads configuration for gvim or nvim-qt {{{
function! s:gui_config()
    if has('nvim')
        " for nvim-qt
        if exists(":GuiFont")
            GuiTabline 0
            GuiPopupmenu 0
            GuiScrollBar 0
        endif
    else
        set guioptions=acdiMk
        set guiheadroom=0
    endif
endfunction
" }}}

function! s:neovide_init() abort
endif

function! s:ginit() abort
    source $VIMRUNTIME/delmenu.vim
    call s:gui_config()
    call s:gui_font()
    if exists("g:neovide_refresh_rate")
        call s:neovide_init()
    endif
endfunction

call s:ginit()
