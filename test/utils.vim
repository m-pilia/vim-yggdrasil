" Get a list of mappings
function! s:get_mapping(mode, mapping) abort
    redir => l:out
    silent execute a:mode . ' ' . a:mapping
    redir END
    return split(l:out, '\n')
endfunction

" Check whether a mapping is defined
function! s:assert_mapping(mode, mapping, command) abort
    for l:line in s:get_mapping(a:mode, a:mapping)
        if l:line =~# '\V' . escape(a:command, '/\')
            Assert 1, a:mode . ' "' . a:mapping . '" set to "' . a:command . '"'
            return
        endif
    endfor
    Assert 0, a:mode . ' "' . a:mapping . '" not set to "' . a:command . '"'
endfunction

" Check whether a mapping is not defined
function! s:assert_no_mapping(mode, mapping) abort
    if s:get_mapping(a:mode, a:mapping)[0] !~# 'No mapping found'
        Assert 0, a:mode . ' "' . a:mapping . '" is set while it should not'
        return
    endif
    Assert 1, a:mode . ' "' . a:mapping . '" is not set'
endfunction

command! -nargs=+ AssertMapping :call s:assert_mapping(<args>)
command! -nargs=+ AssertNoMapping :call s:assert_no_mapping(<args>)

" Get the names of currently sourced scripts
function! s:get_scripts() abort
    redir => l:out
    silent execute 'scriptnames'
    redir END
    return split(l:out, '\n')
endfunction

" Get a (possibly local) function from a script
function! GetFunction(script, name) abort
    if match(s:get_scripts(), a:script) < 0
        exec 'source ' . a:script
    endif
    for l:line in s:get_scripts()
        if match(l:line, a:script) >= 0
            let l:sid = str2nr(split(l:line, ': ')[0])
            return function('<SNR>' . l:sid . '_' . a:name)
        endif
    endfor
endfunction

" Get a list of echoed messages
function! s:get_messages() abort
    redir => l:out
    silent execute 'messages'
    redir END
    return split(l:out, '\n')
endfunction

" Assert that a certain message was emitted
function! s:assert_message(message) abort
    let l:messages = s:get_messages()
    Assert
    \   index(l:messages, a:message) > -1,
    \   'Message "' . a:message . '" not emitted'
endfunction

command! -nargs=1 AssertMessage :call s:assert_message(<args>)

function! s:increment_count(mock, ...) abort
    let a:mock.count += 1
endfunction

" Get a function mock object
function! GetFunctionMock() abort
    let l:mock = {
    \   'count': 0,
    \ }
    let l:mock.function = function('s:increment_count', [l:mock])
    return l:mock
endfunction
