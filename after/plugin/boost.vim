" DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
"     Version 2, December 2004

" Copyright 2019 Jimmy huang

" Everyone is permitted to copy and distribute verbatim or modified
" copies of this license document, and changing it is allowed as long
" as the name is changed.

" DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
" TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION

" 0. You just DO WHAT THE FUCK YOU WANT TO.

if exists("g:loaded_nerdtree_BosstNERDTree")
  finish
endif
let g:loaded_nerdtree_BosstNERDTree = 1

function! NERDTreePasteFile(dirnode)
  "{{{
  let l:newNodePath = g:NERDTreeDirNode.GetSelected().path.str()
  if l:newNodePath ==# ''
    return
  endif
  let l:CurrenNode = s:NERDTreeBoostCacheNode

  let l:newNodePath = substitute(l:newNodePath, '\/$', '', '')
  echo l:newNodePath
  echo l:CurrenNode.path.str()

  redraw!
  echo "Do you want to copy:"
  echo '  '.l:CurrenNode.path.str()
  echo "to:"
  echo  '  '.l:newNodePath 
  echo "yes or no?"
  let l:choice = nr2char(getchar())
  redraw!
  if l:choice !~ 'y'
    echo 'Aborted'
    return
  endif
  if l:CurrenNode.path.copyingWillOverwrite(l:newNodePath)
    call nerdtree#echo("Warning: copying may overwrite files! Continue? (yN)")
    if nr2char(getchar())!~ 'y'
      echo 'Aborted'
      return
    endif
  endif

  try
    let newNode = l:CurrenNode.copy(l:newNodePath)
    if empty(newNode)
      call b:NERDTree.root.refresh()
      call b:NERDTree.render()
    else
      call NERDTreeRender()
      call newNode.putCursorHere(0, 0)
    endif
  catch /^NERDTree/
    call nerdtree#echoWarning("Could not copy node.")
  endtry

  "}}}
endfunction

function! NERDTreeCopyPathToSystemReg(dirnode)
  "{{{
  let l:CurrenNode = g:NERDTreeFileNode.GetSelected()
  " let s:NERDTreeBoostCacheNode=l:CurrenNode
  let l:path = l:CurrenNode.path.str()
  " let @"=l:path
  let l:path = tr(l:path, '\', '/')
  let @+ = l:path
  echo l:path
  "}}}
endfunction

function! NERDTreeCopyFilePath(dirnode)
  "{{{
  let l:CurrenNode = g:NERDTreeFileNode.GetSelected()
  let s:NERDTreeBoostCacheNode = l:CurrenNode
  let l:path = l:CurrenNode.path.str()
  let l:path = tr(l:path, '\', '/')
  let @" = l:path
  " let @+=l:path
  echo l:path
  "}}}
endfunction

function! NERDTreeMoveFile(dirnode)
  "{{{
  let l:newNodePath = g:NERDTreeDirNode.GetSelected().path.str()
  let curNode = s:NERDTreeBoostCacheNode
  if l:newNodePath ==# ''
    call nerdtree#echo("Node Renaming Aborted.")
    return
  endif
  redraw!
  echo "Do you want to move:"
  echo '  '.curNode.path.str()
  echo "to:"
  echo  '  '.l:newNodePath 
  echo "yes or no?"
  let l:choice = nr2char(getchar())
  redraw!
  if l:choice !~ 'y'
    echo 'Aborted'
    return
  endif

  try
    let bufnum = bufnr("^".curNode.path.str()."$")
    let l:newNodePath = l:newNodePath.'\'.fnamemodify(curNode.path.str(),':t')
    call curNode.rename(l:newNodePath)
    call b:NERDTree.root.refresh()
    call NERDTreeRender()

    "if the node is open in a buffer, ask the user if they want to
    "close that buffer
    if bufnum != -1
      let prompt = "\nNode renamed.\n\nThe old file is open in buffer ". bufnum . (bufwinnr(bufnum) ==# -1 ? " (hidden)" : "") .". Replace this buffer with the new file? (yN)"
      call s:promptToRenameBuffer(bufnum,  prompt, l:newNodePath)
    endif

    call curNode.putCursorHere(1, 0)

    redraw
  catch /^NERDTree/
    call nerdtree#echoWarning("Node Not Renamed.")
  endtry
  "}}}
endfunction

call NERDTreeAddKeyMap({
      \ 'key': 'yp',
      \ 'callback': 'NERDTreePasteFile',
      \ 'quickhelpText': 'Pasteing the absolute file.',
      \ 'scope': 'Node' })
call NERDTreeAddKeyMap({
      \ 'key': 'yy',
      \ 'callback': 'NERDTreeCopyFilePath',
      \ 'quickhelpText': 'Copying the absolute path to reg.',
      \ 'scope': 'Node' })
call NERDTreeAddKeyMap({
      \ 'key': 'ym',
      \ 'callback': 'NERDTreeMoveFile',
      \ 'quickhelpText': 'moving the absolute path to reg.',
      \ 'scope': 'DirNode' })
call NERDTreeAddKeyMap({
      \ 'key': 'yc',
      \ 'callback': 'NERDTreeCopyPathToSystemReg',
      \ 'quickhelpText': 'moving the absolute path to reg.',
      \ 'scope': 'Node' })

function! s:promptToRenameBuffer(bufnum, msg, newFileName)
  echo a:msg
  if g:NERDTreeAutoDeleteBuffer || nr2char(getchar()) ==# 'y'
    let quotedFileName = fnameescape(a:newFileName)
    " 1. ensure that a new buffer is loaded
    exec "badd " . quotedFileName
    " 2. ensure that all windows which display the just deleted filename
    " display a buffer for a new filename.
    let s:originalTabNumber = tabpagenr()
    let s:originalWindowNumber = winnr()
    let editStr = g:NERDTreePath.New(a:newFileName).str({'format': 'Edit'})
    exec "tabdo windo if winbufnr(0) == " . a:bufnum . " | exec ':e! " . editStr . "' | endif"
    exec "tabnext " . s:originalTabNumber
    exec s:originalWindowNumber . "wincmd w"
    " 3. We don't need a previous buffer anymore
    exec "bwipeout! " . a:bufnum
  endif
endfunction
