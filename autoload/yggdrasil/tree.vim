scriptencoding utf-8

function! s:node_get_tree_item_cb(node, object, status, tree_item) abort
    if a:status ==? 'success'
        let l:new_node = s:node_new(a:node.tree, a:object, a:tree_item, a:node.id)
        call add(a:node.children, l:new_node)
        call s:tree_render(l:new_node.tree)
    endif
endfunction

function! s:node_get_children_cb(node, status, childObjectList) abort
    for l:childObject in a:childObjectList
        let l:Callback = function('s:node_get_tree_item_cb', [a:node, l:childObject])
        call a:node.tree.provider.getTreeItem(l:Callback, l:childObject)
    endfor
endfunction

function! s:node_set_collapsed(value, recursive) dict abort
    if a:value < 1 && l:self.lazy_open != v:false
        let l:Callback = function('s:node_get_children_cb', [l:self])
        call l:self.tree.provider.getChildren(l:Callback, l:self.object)
        let l:self.lazy_open = v:false
        let l:self.collapsed = v:false
    else
        let l:self.collapsed = a:value < 0 ? !l:self.collapsed : !!a:value
    endif
    if a:recursive
        for l:child in l:self.children
            call l:child.set_collapsed(a:value, a:recursive)
        endfor
    endif
endfunction

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

function! s:node_level() dict abort
    if l:self.parent == {}
        return 0
    endif
    return 1 + l:self.parent.level()
endf

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

function! s:tree_set_root_cb(tree, object, status, tree_item) abort
    if a:status ==? 'success'
        let a:tree.maxid = -1
        let a:tree.root = s:node_new(a:tree, a:object, a:tree_item, {})
        call s:tree_render(a:tree)
    endif
endfunction

function! s:get_id_under_cursor(tree) abort
    let l:id = str2nr(matchstr(getline('.'), '\v\[@<=\d+(\]$)@='))
    return a:tree.root.find(l:id)
endfunction

function! s:tree_set_collapsed_under_cursor(collapsed, recursive) dict abort
    let l:node = s:get_id_under_cursor(l:self)
    call l:node.set_collapsed(a:collapsed, a:recursive)
    call s:tree_render(l:self)
endfunction

function! s:tree_exec_node_under_cursor() dict abort
    call s:get_id_under_cursor(l:self).exec()
endfunction

function! s:tree_render(tree) abort
    let l:cursor = getpos('.')
    let l:text = a:tree.root.render(0)

    setlocal modifiable
    silent 1,$delete _
    silent 0put=l:text
    setlocal nomodifiable

    call setpos('.', l:cursor)
endfunction

function! s:tree_update() dict abort
    call l:self.provider.getChildren({status, obj ->
    \   l:self.provider.getTreeItem(function('s:tree_set_root_cb', [l:self, obj[0]]), obj[0])})
endfunction

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
