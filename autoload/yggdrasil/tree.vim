scriptencoding utf-8

" Callback to retrieve the tree item representation of an object.
function! s:node_get_tree_item_cb(node, object, status, tree_item) abort
    if a:status ==? 'success'
        let l:new_node = s:node_new(a:node.tree, a:object, a:tree_item, a:node.id)
        call add(a:node.children, l:new_node)
        call s:tree_render(l:new_node.tree)
    endif
endfunction

" Callback to retrieve the children objects of a node.
function! s:node_get_children_cb(node, status, childObjectList) abort
    for l:childObject in a:childObjectList
        let l:Callback = function('s:node_get_tree_item_cb', [a:node, l:childObject])
        call a:node.tree.provider.getTreeItem(l:Callback, l:childObject)
    endfor
endfunction

" Set the node to be collapsed or expanded.
"
" When {collapsed} evaluates to 0 the node is expanded, when it is 1 the node is
" collapsed, when it is equal to -1 the node is toggled (it is expanded if it
" was collapsed, and vice versa).
"
" If {recursive} evaluates to true, the change is propagated recursively to all
" the nodes in the sub-tree rooted in this node. If it evaluates to false, only
" this node is changed.
function! s:node_set_collapsed(collapsed, recursive) dict abort
    if a:collapsed < 1 && l:self.lazy_open != v:false
        let l:Callback = function('s:node_get_children_cb', [l:self])
        call l:self.tree.provider.getChildren(l:Callback, l:self.object)
        let l:self.lazy_open = v:false
        let l:self.collapsed = v:false
    else
        let l:self.collapsed = a:collapsed < 0 ? !l:self.collapsed : !!a:collapsed
    endif
    if a:recursive
        for l:child in l:self.children
            call l:child.set_collapsed(a:collapsed, a:recursive)
        endfor
    endif
endfunction

" Return the node object whose id is equal to {id}. Note that this uses the
" internal integer id representing the node, not the string id from the
" provider.
function! s:node_find(id) dict abort
    if l:self.id == a:id
        return l:self
    endif
    if len(l:self.children) < 1
        return v:null
    endif
    for l:child in l:self.children
        let l:result = l:child.find(a:id)
        if type(l:result) == type({})
            return l:result
        endif
    endfor
endfunction

" Return the depth level of the node in the tree. The level is defined
" recursively: the root has depth 0, and each node has depth equal to the depth
" of its parent increased by 1.
function! s:node_level() dict abort
    if l:self.parent == {}
        return 0
    endif
    return 1 + l:self.parent.level()
endf

" Return the string representation of the node. The {level} argument represents
" the depth level of the node in the tree and it is passed for convenience, to
" simplify the implementation and to avoid re-computing the depth.
function! s:node_render(level) dict abort
    let l:indent = repeat(' ', 2 * a:level)
    let l:mark = '  '

    if len(l:self.children) > 0 || l:self.lazy_open != v:false
        let l:mark = l:self.collapsed ? '▸ ' : '▾ '
    endif

    let l:repr = l:indent . l:mark . l:self.tree_item.label . ' [' . l:self.id . ']'

    let l:lines = [l:repr]
    if !l:self.collapsed
        for l:child in l:self.children
            cal add(l:lines, l:child.render(a:level + 1))
        endfor
    endif

    return join(l:lines, "\n")
endfunction

" Insert a new node in the tree, internally represented by a unique progressive
" integer identifier {id}. The node represents a certain {object} (children of
" {parent}) belonging to a given {tree}, having an associated action to be
" triggered on execution defined by the function object {exec}. If {collapsed}
" is true the node will be rendered as collapsed in the view. If {lazy_open} is
" true, the children of the node will be fetched when the node is expanded by
" the user.
function! s:node_new(tree, object, tree_item, parent) abort
    let l:collapsibleState = a:tree_item.collapsibleState
    let a:tree.maxid += 1
    return {
    \ 'id': a:tree.maxid,
    \ 'tree': a:tree,
    \ 'object': a:object,
    \ 'tree_item': a:tree_item,
    \ 'parent': a:parent,
    \ 'collapsed': l:collapsibleState ==? 'collapsed',
    \ 'lazy_open': l:collapsibleState ==? 'collapsed' || l:collapsibleState ==? 'expanded',
    \ 'children': [],
    \ 'level': function('s:node_level'),
    \ 'find': function('s:node_find'),
    \ 'exec': has_key(a:tree_item, 'command') ? a:tree_item.command : {-> 0},
    \ 'set_collapsed': function('s:node_set_collapsed'),
    \ 'render': function('s:node_render'),
    \ }
endfunction

" Callback that sets the root node of a given {tree}, creating a new node
" with a {tree_item} representation for the given {object}. If {status} is
" equal to 'success', the root node is set and the tree view is updated
" accordingly, otherwise nothing happens.
function! s:tree_set_root_cb(tree, object, status, tree_item) abort
    if a:status ==? 'success'
        let a:tree.maxid = -1
        let a:tree.root = s:node_new(a:tree, a:object, a:tree_item, {})
        call s:tree_render(a:tree)
    endif
endfunction

" Return the id of the node currently under the cursor from the given {tree}.
" The id is embedded in the view as a number within square brackets, hidden
" with |conceal|.
function! s:get_id_under_cursor(tree) abort
    let l:id = str2nr(matchstr(getline('.'), '\v\[@<=\d+(\]$)@='))
    return a:tree.root.find(l:id)
endfunction

" Expand or collapse the node under cursor, and render the tree.
" Please refer to *s:node_set_collapsed()* for details about the
" arguments and behaviour.
function! s:tree_set_collapsed_under_cursor(collapsed, recursive) dict abort
    let l:node = s:get_id_under_cursor(l:self)
    call l:node.set_collapsed(a:collapsed, a:recursive)
    call s:tree_render(l:self)
endfunction

" Run the action associated to the node currently under the cursor.
function! s:tree_exec_node_under_cursor() dict abort
    call s:get_id_under_cursor(l:self).exec()
endfunction

" Render the {tree}. This will replace the content of the buffer with the
" tree view.
function! s:tree_render(tree) abort
    let l:cursor = getpos('.')
    let l:text = a:tree.root.render(0)

    setlocal modifiable
    silent 1,$delete _
    silent 0put=l:text
    setlocal nomodifiable

    call setpos('.', l:cursor)
endfunction

" Update the tree, e.g. if nodes have changed.
function! s:tree_update() dict abort
    call l:self.provider.getChildren({status, obj ->
    \   l:self.provider.getTreeItem(function('s:tree_set_root_cb', [l:self, obj[0]]), obj[0])})
endfunction

" Turns the current buffer into an Yggdrasil tree view. Tree data is retrieved
" from the given {provider}, and the state of the tree is stored in a
" buffer-local variable called b:yggdrasil_tree.
"
" The {bufnr} stores the buffer number of the view, {maxid} is the highest
" known internal identifier of the nodes.
function! yggdrasil#tree#new(provider) abort
    let b:yggdrasil_tree = {
    \ 'bufnr': bufnr('.'),
    \ 'maxid': -1,
    \ 'root': {},
    \ 'provider': a:provider,
    \ 'set_collapsed_under_cursor': function('s:tree_set_collapsed_under_cursor'),
    \ 'exec_node_under_cursor': function('s:tree_exec_node_under_cursor'),
    \ 'update': function('s:tree_update'),
    \ }

    setlocal filetype=yggdrasil

    call yggdrasil#filetype#syntax()
    call yggdrasil#filetype#settings()

    call b:yggdrasil_tree.update()
endfunction
