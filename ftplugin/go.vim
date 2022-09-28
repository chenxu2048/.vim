setlocal noexpandtab
setlocal listchars=tab:\ \ ,trail:•,extends:…,nbsp:.

nmap <buffer> [[ :<C-U>call search('^\(import\\|func\\|type\\|var\\|const\) ', 'bW')<CR>
nmap <buffer> [] :<C-U>call search('^[})]', 'bW')<CR>
nmap <buffer> ]] :<C-U>call search('^\(import\\|func\\|type\\|var\\|const\) ', 'W')<CR>
nmap <buffer> ][ :<C-U>call search('^[})]', 'W')<CR>
