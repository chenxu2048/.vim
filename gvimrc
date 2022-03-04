if has("win32")
    let g:guifont = ['Consolas NF', 14]
    let g:guifontwide = ['Microsoft YaHei', 14] " 测试中文
elseif has("macunix")
    let g:guifont = ['FiraCode NF', 14]
    let g:guifontwide = ['Heiti SC', 14]
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
            GuiRenderLigatures 1
            map <D-f> :<C-U>call g:GuiWindowFullScreen(!g:GuiWindowFullScreen)<CR>
        endif
    else
        set guioptions=acdiMk
        set guiheadroom=0
    endif
    set title
endfunction
" }}}

" FUNCTION s:gui_running set g:has_gui_running while GUIEnter. has('gui_running')
"   cannot be used in nvim.
function! s:gui_running()
    autocmd GUIEnter * let g:has_gui_running = 1
endfunction

function! s:ginit() abort
    source $VIMRUNTIME/delmenu.vim
    call s:gui_running()
    call s:gui_config()
    call s:gui_font()
endfunction

call s:ginit()
