let s:yggdrasil_autoload_root = expand('<sfile>:p:h:h')
let s:git_dir = simplify(expand('<sfile>:p:h:h:h') . '/.git')

" Autoload files to be installed
let s:yggdrasil_autoload_files = [
\   'tree.vim',
\ ]

" Return a string containing the SHA-1 of the commit used in the
" Yggdrasil installation, or 'UNKNOWN' if it is not possible to
" determine at install time.
function! s:get_git_commit() abort
    if !executable('git') || !isdirectory(s:git_dir)
        return 'UNKNOWN'
    endif

    let l:git = 'git --git-dir=' . shellescape(s:git_dir) . ' '
    let l:commit = system(l:git . 'rev-parse HEAD')
    let l:is_dirty = system(l:git . 'status --porcelain') =~? '\S'

    return l:commit . (l:is_dirty ? ' (dirty)' : '')
endfunction

" Parse command arguments
"
" Return a list of positional argument and a dictionary of key-value
" arguments (in the form -key=value).
function! s:parse_arguments(arglist) abort
    let l:args = []
    let l:kwargs = {}

    for l:arg in a:arglist
        let l:keyval = matchlist(l:arg, '\v\-([^=]+)\=(.+)')
        if l:keyval == []
            call add(l:args, l:arg)
        else
            let l:kwargs[l:keyval[1]] = l:keyval[2]
        endif
    endfor

    return [l:args, l:kwargs]
endfunction

" Install an autoload file in the given destination folder
function! s:install_autoload_file(file, install_options) abort
    let l:source_file = simplify(s:yggdrasil_autoload_root . '/yggdrasil/' . a:file)
    let l:destination_file = simplify(a:install_options.destination_folder . '/' . a:file)

    " Header comment
    let l:lines = [
    \   '" This file is part of an installation of vim-yggdrasil, a vim/neovim tree viewer library.',
    \   '" The source code of vim-yggdrasil is available at https://github.com/m-pilia/vim-yggdrasil',
    \   '"',
    \   '" vim-yggdrasil is free software, distributed under the MIT license.',
    \   '" The full license is available at https://github.com/m-pilia/vim-yggdrasil/blob/master/LICENSE',
    \   '"',
    \   '" Yggdrasil version (git SHA-1): ' . a:install_options.commit,
    \   '"',
    \   '" This installation was generated on ' . a:install_options.datetime . ' with the following vim command:',
    \   '"     ' . a:install_options.cmd,
    \   '',
    \ ]

    " Read source file
    let l:lines += readfile(l:source_file)

    " Replace the autoload prefix
    let l:lines = map(
    \   l:lines,
    \   {_, l -> substitute(l, '\V\C\<yggdrasil#', a:install_options.prefix, 'g')}
    \ )

    " Replace syntax variable names
    if has_key(a:install_options.kwargs, 'syntax_prefix')
        let l:lines = map(
        \   l:lines,
        \   {_, l -> substitute(l, '\V\C\<Yggdrasil', a:install_options.kwargs.syntax_prefix, 'g')}
        \ )
    endif

    " Replace plug names
    if has_key(a:install_options.kwargs, 'plug_prefix')
        let l:lines = map(
        \   l:lines,
        \   {_, l -> substitute(l,
        \                      '\V\C<Plug>(yggdrasil-\(\[^)]\*\))',
        \                      {m -> '<Plug>(' . a:install_options.kwargs.plug_prefix . '-' . m[1] . ')'},
        \                      'g')}
        \ )
    endif

    " Replace buffer variables
    if has_key(a:install_options.kwargs, 'variable_prefix')
        let l:lines = map(
        \   l:lines,
        \   {_, l -> substitute(l, '\V\Cb\:yggdrasil', 'b:' . a:install_options.kwargs.variable_prefix, 'g')}
        \ )
    endif

    " Replace filetype
    if has_key(a:install_options.kwargs, 'filetype')
        let l:lines = map(
        \   l:lines,
        \   {_, l -> substitute(l,
        \                       '\m\C\(filetype[^=]*=[^y]*\)yggdrasil',
        \                       {m -> m[1] . a:install_options.kwargs.filetype},
        \                       'g')}
        \ )
    endif

    " Write destination file
    call mkdir(fnamemodify(l:destination_file, ':h'), 'p')
    call writefile(l:lines, l:destination_file)
endfunction

" Embed Yggdrasil in another plugin's file structure.
"
" A plugin name, to be used as a namespace, can be optionally specified.
" The folder name will be used if missing.
function! yggdrasil#embedder#plant_tree(...) abort
    let [l:args, l:kwargs] = s:parse_arguments(a:000)

    if !has_key(l:kwargs, 'plugin_dir')
        throw 'Yggdrasil: -plugin_dir argument required for YggdrasilPlant'
    endif

    if !isdirectory(l:kwargs.plugin_dir)
        throw 'Yggdrasil: cannot read target plugin directory'
    endif

    let l:namespace = has_key(l:kwargs, 'namespace') ? l:kwargs.namespace : fnamemodify(l:kwargs.plugin_dir, ':t')
    let l:Escape = {str -> substitute(str, '\v(\s)', {m -> '\' . m[1]}, 'g')}

    let l:install_options = {
    \   'args': l:args,
    \   'cmd': ':YggdrasilPlant ' . join(map(copy(a:000), {_, str -> l:Escape(str)})),
    \   'commit': s:get_git_commit(),
    \   'datetime': strftime('%FT%T%z'),
    \   'destination_folder': simplify(l:kwargs.plugin_dir . '/autoload/' . l:namespace),
    \   'kwargs': l:kwargs,
    \   'prefix': substitute(l:namespace, '[/\\]', '#', 'g') . '#',
    \ }

    for l:file in s:yggdrasil_autoload_files
        call s:install_autoload_file(l:file, l:install_options)
    endfor
endfunction
