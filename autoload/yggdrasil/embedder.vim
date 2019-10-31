let s:yggdrasil_autoload_root = expand('<sfile>:p:h:h')

" Autoload files to be installed
let s:yggdrasil_autoload_files = [
\   'yggdrasil/tree.vim',
\ ]

" Install an autoload file in the given destination folder
function! s:install_autoload_file(file, destination_folder) abort
    let l:source_file = simplify(s:yggdrasil_autoload_root . '/' . a:file)
    let l:destination_file = simplify(a:destination_folder . '/' . a:file)
    let l:prefix = fnamemodify(a:destination_folder, ':t')

    " Read source file
    let l:lines = readfile(l:source_file)

    " Replace the autoload prefix
    let l:lines = map(
    \   l:lines,
    \   {_, l -> substitute(l, '\V\<yggdrasil#', l:prefix . '#yggdrasil#', 'g')}
    \ )

    " Write destination file
    call mkdir(fnamemodify(l:destination_file, ':h'), 'p')
    call writefile(l:lines, l:destination_file)
endfunction

" Embed Yggdrasil in another plugin's file structure.
"
" A plugin name, to be used as a namespace, can be optionally specified.
" The folder name will be used if missing.
function! yggdrasil#embedder#plant_tree(plugin_dir, ...) abort
    if !isdirectory(a:plugin_dir)
        throw 'Yggdrasil: cannot read target plugin directory'
    endif

    let l:plugin_name = a:0 > 0 ? a:1 : fnamemodify(a:plugin_dir, ':t')

    let l:destination_folder = simplify(a:plugin_dir . '/autoload/' . l:plugin_name)

    for l:file in s:yggdrasil_autoload_files
        call s:install_autoload_file(l:file, l:destination_folder)
    endfor
endfunction
