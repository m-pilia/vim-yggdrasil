vim-yggdrasil: general purpose tree viewer for vim
===============================================================
[![Travis CI Build Status](https://travis-ci.org/m-pilia/vim-yggdrasil.svg?branch=master)](https://travis-ci.org/m-pilia/vim-yggdrasil)
[![codecov](https://codecov.io/gh/m-pilia/vim-yggdrasil/branch/master/graph/badge.svg)](https://codecov.io/gh/m-pilia/vim-yggdrasil/branch/master)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://github.com/m-pilia/vim-yggdrasil/blob/master/LICENSE)

This plugin implements a general purpose tree viewer library for vim.

Example
=======

```viml
function! Echo_label(node) abort
    echo 'You clicked ' . a:node.label
endfunction

function! Dynamic_append(node) abort
    echo 'Dynamically adding a children to ' . a:node.label
    call b:yggdrasil_tree.insert('New node!', function('Echo_label'), 0, a:node.id)
endfunction

" Create a split and initialise it as an Yggdrasil tree
call yggdrasil#tree#new(50, 'topright', 'vertical')

" Add a root node to the tree
call b:yggdrasil_tree.insert('Root node!',
\                            function('Echo_label'),
\                            0)

" Add a children to the root node
call b:yggdrasil_tree.insert('Children!',
\                            function('Echo_label'),
\                            function('Dynamic_append'),
\                            b:yggdrasil_tree.root.id)

" Render the tree
call b:yggdrasil_tree.render()
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
