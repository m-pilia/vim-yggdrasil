vim-yggdrasil: general purpose tree viewer for vim/neovim
===============================================================
[![Travis CI Build Status](https://travis-ci.org/m-pilia/vim-yggdrasil.svg?branch=master)](https://travis-ci.org/m-pilia/vim-yggdrasil)
[![codecov](https://codecov.io/gh/m-pilia/vim-yggdrasil/branch/master/graph/badge.svg)](https://codecov.io/gh/m-pilia/vim-yggdrasil/branch/master)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://github.com/m-pilia/vim-yggdrasil/blob/master/LICENSE)

<p align="center">
<img src="https://upload.wikimedia.org/wikipedia/commons/4/44/Pasaules_koks_Igdrasils.jpg" />
<br />
(Image: <a href="https://commons.wikimedia.org/wiki/File:Pasaules_koks_Igdrasils.jpg">WikiMedia Commons</a>)
</p>

This plugin implements a general purpose tree viewer library for vim/neovim. It
uses an interface similar to VSCode's
[TreeDataProvider](https://code.visualstudio.com/api/references/vscode-api#TreeDataProvider)
to retrieve the data to be displayed by the view.

Among the features:
* Nodes are expanded lazily, allowing to efficiently explore deep trees with a
  large number of nested nodes.
* A callback mechanism allows asynchronous execution. The data provider can
  generate data asynchronously, and send it to the view through a callback.
* Pure VimScript implementation, self-contained library.
* Easy to embed in other plugins without external dependencies.

For a concrete example of usage, you can check the source of
[vim-ccls](https://github.com/m-pilia/vim-ccls), that makes use of
Yggdrasil to show symbol hierarchies.

![Example](https://user-images.githubusercontent.com/8300317/68967865-d923d500-07e9-11ea-8312-5e4636c2b7b7.png)

Install
=======

Yggdrasil can be either installed as an external dependency (as a regular vim
plugin) or it can be embedded within another plugin's file structure. The
latter solution allows to have an own copy of Yggdrasil, avoiding to rely on an
external dependency with its potential issues.

To embed Yggdrasil in your plugin, run the `YggdrasilPlant` command, specifying
the root directory of your vim plugin, and optionally a name to be used as a
namespace (by default, the name of the root directory). For instance, if your
plugin's root folder (containing the `autoload`, `plugin`, `doc` folders etc.)
is `/foo/myplugin`, by calling:
```
:YggdrasilPlant -plugin_dir=/foo/my/plugin
```
a copy of Yggdrasil will be installed in
`/foo/myplugin/autoload/my/plugin`, and it can be used as
```viml
" Call an Yggdrasil function in your plugin code
call my#plugin#tree#new(provider)
```
Please note that the path passed to the `YggdrasilPlant` command shall not be
enclosed within quotes, and white-space characters within the path need to be
escaped with backslash.

If for some reason you want to use a different namespace than the name of the
root folder of your plugin, pass an optional argument to specify it. For
instance, a call to
```
:YggdrasilPlant -plugin_dir=/foo/myplugin -namespace=my/namespace
```
will install a copy of Yggdrasil in `/foo/myplugin/autoload/my/namespace`,
and it can be used as
```viml
" Call an Yggdrasil function in your plugin code
call my#namespace#tree#new(provider)
```

Example
=======

The following is a minimal working example of usage. This example uses
synchronous execution, but the methods of the data provider could be
asynchronous (e.g. launching an external job), using the provided callback
mechanism.

After installing Yggdrasil, you can run this example by pasting the following
script in a new file, open it within vim and executing `:source %`.

```viml
" Minimal example of tree data. The objects are integer numbers.
" Here the tree structure is implemented with a dictionary mapping parents to
" children.
let s:tree = {
\     0: [1, 2],
\     1: [3],
\     2: [4, 5],
\     3: [],
\     4: [6],
\     5: [],
\     6: [],
\ }

" Action to be performed when executing an object in the tree.
function! s:command_callback(id) abort
    echom 'Calling object ' . a:id . '!'
endfunction

" Auxiliary function to map each object to its parent in the tree.
function! s:number_to_parent(id) abort
    for [l:parent, l:children] in items(s:tree)
        if index(l:children, a:id) > 0
            return l:parent
        endif
    endfor
endfunction

" Auxiliary function to produce a minimal tree item representation for a given
" object (i.e. a given integer number).
"
" The four mandatory fields for the tree item representation are:
"  * id: unique string identifier for the node in the tree
"  * collapsibleState: string value, equal to:
"     + 'collapsed' for an inner node initially collapsed
"     + 'expanded' for an inner node initially expanded
"     + 'none' for a leaf node that cannot be expanded nor collapsed
"  * command: function object that takes no arguments, it runs when a node is
"    executed by the user
"  * label: string representing the node in the view
function! s:number_to_treeitem(id) abort
    return {
    \   'id': string(a:id),
    \   'command': function('s:command_callback', [a:id]),
    \   'collapsibleState': len(s:tree[a:id]) > 0 ? 'collapsed' : 'none',
    \   'label': 'Label of node ' . a:id,
    \ }
endfunction

" The getChildren method can be called with no object argument, in that case it
" returns the root of the tree, or with one object as second argument, in that
" case it returns a list of objects that are children to the given object.
function! s:GetChildren(Callback, ...) abort
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

" The getParent method returns the parent of a given object.
function! s:GetParent(Callback, object) abort
    call a:Callback('success', s:number_to_parent(a:object))
endfunction

" The getTreeItem returns the tree item representation of a given object.
function! s:GetTreeItem(Callback, object) abort
    call a:Callback('success', s:number_to_treeitem(a:object))
endfunction

" Define the tree data provider.
"
" The data provider exposes three methods that, given an object as input,
" produce the list of children, the parent object, and the tree item
" representation for the object respectively.
"
" Each method takes as first argument a callback, that is called by the provider
" to return the result asynchronously. The callback takes two arguments, the
" first is a status parameter, the second is the result of the call.
let s:provider = {
\ 'getChildren': function('s:GetChildren'),
\ 'getParent': function('s:GetParent'),
\ 'getTreeItem': function('s:GetTreeItem'),
\ }

" Create a new buffer and a new window for the tree view
if exists('*nvim_open_win')
    let s:buffer_options = {
    \ 'anchor': 'NW',
    \ 'style': 'minimal',
    \ 'relative': 'cursor',
    \ 'width': 50,
    \ 'height': 10,
    \ 'row': 1,
    \ 'col': 0,
    \ }
    call win_gotoid(nvim_open_win(nvim_create_buf(v:false, v:true), 0, s:buffer_options))
else
    topleft vnew
endif


" Create a tree view with the given provider
"
" This function turns the current buffer into a tree view using data from the
" given provider. Any pre-existing content of the buffer will be deleted
" without warning. It is recommended to call this function within a newly
" created buffer (usually in a new split window, floating window, or tab).
call yggdrasil#tree#new(s:provider)
```

To notify the view of a change in the structure or representation of the tree
nodes, because of a change inside the provider, the `update()` method can be
used:
```viml
" Update the whole tree. Allows, for instance, to change the root.
" The whole tree is collapsed, and all nodes will be queried again from the
" provider when the user expands them again.
call b:yggdrasil_tree.update()

" Update only the node representing the integer number "2" in the above
" example, and its subtree. Preserve the collapsing structure of the view.
" Only the node representing "2" and its subtree will be queried again from
" the provider.
call b:yggdrasil_tree.update(2)
```

To destroy the tree view, call the `wipe()` method. This will
[`wipe out`](http://vimdoc.sourceforge.net/htmldoc/windows.html#:bwipeout) the
buffer containing the tree:
```viml
call b:yggdrasil_tree.wipe()
```

For a more extensive example of usage, you can check the implementation of
[vim-ccls](https://github.com/m-pilia/vim-ccls), that makes use of
Yggdrasil to display symbol hierarchy trees.

Settings
========

The following `<Plug>` mappings are available to interact with a tree buffer:
```
<Plug>(yggdrasil-toggle-node)
<Plug>(yggdrasil-open-node)
<Plug>(yggdrasil-close-node)
<Plug>(yggdrasil-execute-node)
<Plug>(yggdrasil-wipe-tree)
```

The default key bindings are:
```vim
nmap <silent> <buffer> o    <Plug>(yggdrasil-toggle-node)
nmap <silent> <buffer> <cr> <Plug>(yggdrasil-execute-node)
nmap <silent> <buffer> q    <Plug>(yggdrasil-wipe-tree)
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
