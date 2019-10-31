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
    \   'id': string(a:id),
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

let s:provider = {
\ 'getChildren': function('s:children'),
\ 'getParent': {callback, x -> callback('success', s:get_parent(x))},
\ 'getTreeItem': {callback, x -> callback('success', s:number_to_treeitem(x))},
\ }

function! GetProvider() abort
    return s:provider
endfunction
