scriptencoding utf-8

function! s:get_tree_item_cb(node, object, status, tree_item) abort
    if a:status ==? 'success'
        let l:new_node = yggdrasil#node#new(a:node.tree, a:object, a:tree_item, a:node.id)
        call add(a:node.children, l:new_node)
        call l:new_node.tree.render()
    endif
endfunction

function! s:get_children_cb(node, status, childObjectList) abort
    for l:childObject in a:childObjectList
        let l:Callback = function('s:get_tree_item_cb', [a:node, l:childObject])
        call a:node.tree.provider.getTreeItem(l:Callback, l:childObject)
    endfor
endfunction

function! yggdrasil#node#set_collapsed(value, recursive) dict abort
    if a:value < 1 && l:self.lazy_open != v:false
        call l:self.tree.provider.getChildren(function('s:get_children_cb', [l:self]), l:self.object)
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

function! yggdrasil#node#find(id) dict abort
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

function! yggdrasil#node#level() dict abort
    if l:self.parent == {}
        return 0
    endif
    return 1 + l:self.parent.level()
endf

function! yggdrasil#node#render(level) dict abort
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

function! yggdrasil#node#new(tree, object, tree_item, parent) abort
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
    \ 'level': function('yggdrasil#node#level'),
    \ 'find': function('yggdrasil#node#find'),
    \ 'exec': has_key(a:tree_item, 'command') ? a:tree_item.command : {-> 0},
    \ 'set_collapsed': function('yggdrasil#node#set_collapsed'),
    \ 'render': function('yggdrasil#node#render'),
    \ }
endfunction
