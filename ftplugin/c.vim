function! s:set_linux_source() abort
    setlocal noexpandtab
    setlocal tabstop=8
    setlocal softtabstop=8
    setlocal shiftwidth=8
    setlocal listchars=tab:\ \ ,trail:•,extends:…,nbsp:.
endfunction
function! s:set_if_linux_source() abort
    let cwd = getcwd()
    let path = '%:p:h'
    while v:true
        let dir = expand(path)
        if dir ==? '/' || dir ==? cwd
            break
        endif
        let kbuild = dir. '/Kbuild'
        if filereadable(kbuild)
            call s:set_linux_source()
            break
        endif
        let path = path . ':h'
    endwhile
endfunction

call s:set_if_linux_source()
