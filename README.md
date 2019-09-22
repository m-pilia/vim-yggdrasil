vim-yggdrasil: general purpose tree viewer for vim
===============================================================
[![Travis CI Build Status](https://travis-ci.org/m-pilia/vim-yggdrasil.svg?branch=master)](https://travis-ci.org/m-pilia/vim-yggdrasil)
[![codecov](https://codecov.io/gh/m-pilia/vim-yggdrasil/branch/master/graph/badge.svg)](https://codecov.io/gh/m-pilia/vim-yggdrasil/branch/master)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://github.com/m-pilia/vim-yggdrasil/blob/master/LICENSE)

This plugin implements a general purpose tree viewer library for vim.

WORK IN PROGRESS
================

Beware, this plugin is under construction. The API is not finalised nor
stable. For details, please see [issue #2](https://github.com/m-pilia/vim-yggdrasil/issues/2).

Example
=======

```viml
" Minimal example of tree data generator
let s:tree = {
\     0: [1, 2],
\     1: [3],
\     2: [4, 5],
\     3: [],
\     4: [6],
\     5: [],
\     6: [],
\ }

function! s:get_parent(id) abort
    for [l:parent, l:children] in items(s:tree)
        if index(l:children, a:id) > 0
            return l:parent
        endif
    endfor
endfunction

function! s:command_callback(id) abort
    echom 'Calling object ' . a:id . '!'
endfunction

function! s:number_to_treeitem(id) abort
    return {
    \   'id': a:id,
    \   'command': function('s:command_callback', [a:id]),
    \   'collapsibleState': len(s:tree[a:id]) > 0 ? 'collapsed' : 'none',
    \   'label': 'Label of node ' . a:id,
    \ }
endfunction

function! s:children(Callback, ...) abort
    let l:children = [0]
    if a:0 > 0
        if has_key(s:tree, a:1)
            let l:children = s:tree[a:1]
        else
            call a:Callback('failure')
        endif
    endif
    call a:Callback('success', l:children)
endfunction

" Define the tree data provider
let s:provider = {
\ 'getChildren': function('s:children'),
\ 'getParent': {callback, x -> callback('success', s:get_parent(x))},
\ 'getTreeItem': {callback, x -> callback('success', s:number_to_treeitem(x))},
\ }

call yggdrasil#tree#new(s:provider)
```

Settings
========

The following `<Plug>` mappings are available to interact with a tree buffer:
```
<Plug>(yggdrasil-toggle-node)
<Plug>(yggdrasil-open-node)
<Plug>(yggdrasil-close-node)
<Plug>(yggdrasil-open-subtree)
<Plug>(yggdrasil-close-subtree)
<Plug>(yggdrasil-execute-node)
```

The default key bindings are:
```vim
nmap <silent> <buffer> o    <Plug>(yggdrasil-toggle-node)
nmap <silent> <buffer> O    <Plug>(yggdrasil-open-subtree)
nmap <silent> <buffer> C    <Plug>(yggdrasil-close-subtree)
nmap <silent> <buffer> <cr> <Plug>(yggdrasil-execute-node)
nnoremap <silent> <buffer> q :q<cr>
```

They can be disabled and replaced with custom mappings:
```vim
let g:yggdrasil_no_default_maps = 1
au FileType yggdrasil nmap <silent> <buffer> o <Plug>(yggdrasil-toggle-node)
```

License
=======

This software is distributed under the MIT license. The full text of the license
is available in the [LICENSE
file](https://github.com/m-pilia/vim-yggdrasil/blob/master/LICENSE) distributed
alongside the source code.
