let s:tree = {
\     0: [1, 2],
\     1: [3],
\     2: [4, 5],
\     3: [],
\     4: [6],
\     5: [],
\     6: [],
\ }

function! s:get_parent(tree, id) abort
    for [l:parent, l:children] in items(a:tree)
        if index(l:children, a:id) > 0
            return l:parent
        endif
    endfor
endfunction

function! s:command_callback(id) abort
    echom 'Calling object ' . a:id . '!'
endfunction

function! s:number_to_treeitem(tree, id) abort
    return {
    \   'id': string(a:id),
    \   'command': function('s:command_callback', [a:id]),
    \   'collapsibleState': len(a:tree[a:id]) > 0 ? 'collapsed' : 'none',
    \   'label': 'Label of node ' . a:id,
    \ }
endfunction

function! s:children(tree, root, Callback, ...) abort
    let l:children = a:root
    if a:0 > 0
        if has_key(a:tree, a:1)
            let l:children = a:tree[a:1]
        else
            call a:Callback('failure')
        endif
    endif
    call a:Callback('success', l:children)
endfunction

function! GetProvider() abort
    let l:tree = deepcopy(s:tree)
    let l:root = [0]
    return {
    \   'tree': l:tree,
    \   'root': l:root,
    \   'getChildren': function('s:children', [l:tree, l:root]),
    \   'getParent': {callback, x -> callback('success', s:get_parent(l:tree, x))},
    \   'getTreeItem': {callback, x -> callback('success', s:number_to_treeitem(l:tree, x))},
    \ }
endfunction
