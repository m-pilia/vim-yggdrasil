if exists('g:vim_yggdrasil_plugin_loaded')
    finish
endif
let g:vim_yggdrasil_plugin_loaded = 1

command! -nargs=+ YggdrasilPlant :call yggdrasil#embedder#plant_tree(<f-args>)
