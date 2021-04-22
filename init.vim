let $VIMHOME=expand('<sfile>:p:h')
source $VIMHOME/vimrc
if exists("g:neovide_refresh_rate")
    source $VIMHOME/gvimrc
endif
