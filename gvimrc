" FUNCTION s:gui_config loads configuration for gvim or nvim-qt {{{
function! s:gui_config()
    if has('nvim')
        if exists(':GuiFont')
            GuiFont! Consolas\ NF:h12
        endif
        if exists(':GuiTabline')
            GuiTabline 0
        endif
        if exists(':GuiPopupmenu')
            GuiPopupmenu 0
        endif
        if exists(':GuiScrollBar')
            GuiScrollBar 0
        endif
        if exists(':GuiAdaptiveColor')
            GuiAdaptiveColor 1
        endif
        set guifontwide=Noto\ Sans\ CJK\ SC\ 11 " 测试
    else
        " set guifont=Noto\ Sans\ Mono\ 12
        noremap <Leader>` :<C-U>set guifont=Noto\ Sans\ Mono\ 12<CR>
        set guifont=Symbols\ Nerd\ Font\ Vim\ 12
        set guifontwide=Noto\ Sans\ CJK\ SC\ 11 " 测试
        set guioptions=acdiMk
        set guiheadroom=0
    endif
endfunction
" }}}

function! s:ginit() abort
    source $VIMRUNTIME/delmenu.vim
    call s:gui_config()
endfunction

call s:ginit()
