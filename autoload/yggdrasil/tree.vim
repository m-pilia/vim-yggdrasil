function! s:set_root_cb(tree, object, status, tree_item) abort
    if a:status ==? 'success'
        let a:tree.maxid = -1
        let a:tree.root = yggdrasil#node#new(a:tree, a:object, a:tree_item, {})
        call a:tree.render()
    endif
endfunction

function! s:set_root(tree) abort
    let l:GetChildrenCallback = {status, obj -> a:tree.provider.getTreeItem(function('s:set_root_cb', [a:tree, obj[0]]), obj[0])}
    call a:tree.provider.getChildren(l:GetChildrenCallback)
endfunction

function! s:get_node_id_under_cursor() dict abort
    let l:id = str2nr(matchstr(getline('.'), '\v\[@<=\d+(\]$)@='))
    return l:self.root.find(l:id)
endfunction

function! s:set_collapsed_under_cursor(collapsed, recursive) dict abort
    let l:node = l:self.get_node_id_under_cursor()
    call l:node.set_collapsed(a:collapsed, a:recursive)
    call l:self.render()
endfunction

function! s:render() dict abort
    let l:cursor = getpos('.')
    let l:text = l:self.root.render(0)

    setlocal modifiable
    silent 1,$delete _
    silent 0put=l:text
    setlocal nomodifiable

    call setpos('.', l:cursor)
endfunction

function! s:update() dict abort
    call s:set_root(l:self)
endfunction

""""""""""""""""""""
"
"    Public API
"
""""""""""""""""""""

function! yggdrasil#tree#new(provider) abort
    let b:yggdrasil_tree = {
    \ 'bufnr': bufnr('.'),
    \ 'maxid': -1,
    \ 'root': {},
    \ 'provider': a:provider,
    \ 'set_collapsed_under_cursor': function('s:set_collapsed_under_cursor'),
    \ 'get_node_id_under_cursor': function('s:get_node_id_under_cursor'),
    \ 'render': function('s:render'),
    \ 'update': function('s:update'),
    \ }

    setlocal filetype=yggdrasil

    call yggdrasil#filetype#syntax()
    call yggdrasil#filetype#settings()

    call s:set_root(b:yggdrasil_tree)
endfunction
