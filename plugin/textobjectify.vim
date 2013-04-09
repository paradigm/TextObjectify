" Vim plugin to improve text objects
" Maintainer: Daniel Thau (paradigm@bedrocklinux.org)
" Version: 0.1
" Description: TextObjectify is a Vim plugin which improves text objects
" Last Change: 2013-04-04
" Location: plugin/textobjectify.vim
" Website: https://github.com/paradigm/textobjectfy
"
" See textobjectify.txt for documentation.

if exists('g:loaded_textobjectify') || &cp
	finish
endif
let g:loaded_textobjectify = 1

" if the user did not configure textobjectify, use the following as a default
if !exists("g:textobjectify")
	let g:textobjectify = {
				\'(': {'left': '(', 'right': ')', 'same': 0, 'seek': 1, 'line': 0},
				\')': {'left': '(', 'right': ')', 'same': 0, 'seek': 2, 'line': 0},
				\'{': {'left': '{', 'right': '}', 'same': 0, 'seek': 1, 'line': 0},
				\'}': {'left': '{', 'right': '}', 'same': 0, 'seek': 2, 'line': 0},
				\'[': {'left': '\[', 'right': '\]', 'same': 0, 'seek': 1, 'line': 0},
				\']': {'left': '\[', 'right': '\]', 'same': 0, 'seek': 2, 'line': 0},
				\'<': {'left': '<', 'right': '>', 'same': 0, 'seek': 1, 'line': 0},
				\'>': {'left': '<', 'right': '>', 'same': 0, 'seek': 2, 'line': 0},
				\'"': {'left': '"', 'right': '"', 'same': 1, 'seek': 1, 'line': 0},
				\"'": {'left': "'", 'right': "'", 'same': 1, 'seek': 1, 'line': 0},
				\'`': {'left': '`', 'right': '`', 'same': 1, 'seek': 1, 'line': 0},
				\'V': {'left': '^\s*\(if\|for\|function\|try\|while\)\>',
					\'right': '^\s*end', 'same': 0, 'seek': 1, 'line': 1},
				\"\<cr>": {'left': '\%^', 'right': '\%$', 'same': 0, 'seek': 0, 
				\'line': 0},
				\}
endif

" default text objects
let s:defaults = ["w","W","s","p","[","]","(",")","b","<",">","t","}","{","B",'"',"'"]

" mappings to call plugin rather than vim text objects
onoremap <silent> i      :<c-u>call TextObjectify(v:operator,'i')<cr>
onoremap <silent> a      :<c-u>call TextObjectify(v:operator,'a')<cr>
xnoremap <silent> i <esc>:<c-u>call TextObjectify(visualmode(),'i')<cr>
xnoremap <silent> a <esc>:<c-u>call TextObjectify(visualmode(),'a')<cr>


function! TextObjectify(mode,ia)
	" general layout of this function:
	" - make arguments available script-scoped so I don't have to repeatedly
	"   pass arguments along
	" - get the object from the user
	" - figure out if we should treat the object as a textobjecitfy-specific
	"   item, a vim default, or use on-the-fly settings (or abort)
	" - store original cursor position so we can reset
	" - possibly move cursor if already visually selected region so user can
	"   re-select a larger region
	" - set seek-directions-specific items.  if seek is disabled, just check
	"   if we're currently in a text object and either select or abort
	" - if same-line setting is set, search for object on same line as cursor.
	"   if we find it, select and quit.  otherwise, continue
	" - search for object irrelevant of line.  if we find it, select and quit.
	"   otherwise, abort

	" make arguments available script-scoped
	let s:ia = a:ia
	let s:mode = a:mode

	" get object
	let l:object = nr2char(getchar())

	" figure out how to treat object.  four possible situations.  use the
	" first we run into.
	" - object is in g:textobjectify
	" - object is vim default
	" - g:textobjectify_onlythefly is set, then
	"   - use the object as delimiters
	" - abort
	
	" object is in g:textobjectify
	if has_key(g:textobjectify, l:object)
		let s:left  = g:textobjectify[l:object]['left']
		let s:right = g:textobjectify[l:object]['right']
		let s:same  = g:textobjectify[l:object]['same']
		let s:seek  = g:textobjectify[l:object]['seek']
		if g:textobjectify[l:object]['line'] == 1
			let s:mode = "V"
		endif
	elseif count(s:defaults, l:object) > 0
		" object is vim default - no need for any more plugin
		execute "normal! v".a:ia. l:object
		return
	elseif !exists("g:textobjectify_onthefly") || g:textobjectify_onthefly == 1
		" create object on-the-fly
		let s:left  = '\V'.l:object
		let s:right = '\V'.l:object
		" use onthefly settings if set; otherwise, try sane defaults
		if exists("g:textobjectify_onthefly_same")
			let s:same = g:textobjectify_onthefly_same
		else
			let s:same = 0
		endif
		if exists("g:textobjectify_onthefly_seek")
			let s:seek = g:textobjectify_onthefly_seek
		else
			let s:seek = 1
		endif
		if exists("g:textobjectify_onthefly_line")
			if g:textobjectify_onthefly_line == 1
				let s:mode = "V"
			endif
		endif
	else
		return
	endif

	" store the original cursor position either to reference or simply so we
	" can restore it if we don't find any text objects to use
	let s:origline = line('.')
	let s:origcol  = col('.')
	" we may tweak s:orig* below.  save the real original values in case we
	" do.
	let s:realorigline = line('.')
	let s:realorigcol  = col('.')

	" note whether or not a region is already visually selected
	if (s:mode ==# "v" || s:mode ==# "V" || s:mode ==# "\<c-v>") &&
				\(col("'<") != col("'>") || line("'<") != line("'>"))
		let s:invisual = 1
		" move cursor out of selected area so a re-select will select a larger
		" area
		if s:seek == 2
			if col(".") < col("$")-1
				execute "normal! \<right>"
			else
				execute "normal! \<down>$"
			endif
		else
			" if seeking backward, expand backward
			if col(".") > col("^")+1
				execute "normal! \<left>"
			else
				execute "normal! \<up>0"
			endif
		endif
		let s:origline = line('.')
		let s:origcol  = col('.')
	else
		let s:invisual = 0
	endif

	" set s:seekdir to use as flags for search() and friends if we're seeking
	if(s:seek == 1) " seek forward
		let s:seekdir = ''
	elseif(s:seek == 2) " seek backward
		let s:seekdir = 'b'
	else
		" otherwise, do not seek.  just check if we're in the region.  if not,
		" abort
		if s:CursorInRange() == 1
			return s:SelectRange()
		else
			" abort
			call cursor(s:realorigline,s:realorigcol)
			" if was in visual, re-select area
			if s:invisual == 1
				normal gv
			endif
			return 0
		endif
	endif

	" if s:same is set, search on same line.  will select range if it finds
	" something
	if s:same == 1 && s:SearchSameLine() == 1
		return 1
	endif

	" if s:same is not set, or s:same is set but didn't find anything on same
	" line, search without line constraint.  will select range if it finds
	" something
	call cursor(s:origline,s:origcol)
	if s:SearchAnyLine()
		return 1
	else
		" did not find any text objects.  really reset cursor and abort
		call cursor(s:realorigline,s:realorigcol)
		" if was in visual, re-select area
		if s:invisual == 1
			normal gv
		endif
		return 0
	endif
endfunction

"" returns whether or not cursor is in range
"" if cursor is in range, also sets s:variables of bound locations
function! s:CursorInRange()
	" find left/right bounds, if they exist.  use a single searchpairpos() if
	" left/right bounds are different; otherwise, use searchpos() in both
	" directions.

	" we have to handle the situation where the cursor is on the left
	" delimiter OR the right delimiter, but we can't check just allow the
	" cursor to be under both delimiter at the same time or it will accept
	" just a single character as a "range".  instead, check if we're in a
	" range where only the left bound is allowed under the cursor, and if that
	" fails, check if we're in a range where the right bound is allowed under
	" the cursor.

	if(s:left != s:right)
		let s:l1 = searchpairpos(s:left,'',s:right,'Wncb')[0]
		let s:c1 = searchpairpos(s:left,'',s:right,'Wncb')[1]
		let s:l2 = searchpairpos(s:left,'',s:right,'Wn')[0]
		let s:c2 = searchpairpos(s:left,'',s:right,'Wn')[1]
	else
		let s:l1 = searchpos(s:left, 'Wncb')[0]
		let s:c1 = searchpos(s:left, 'Wncb')[1]
		let s:l2 = searchpos(s:right,'Wn')[0]
		let s:c2 = searchpos(s:right,'Wn')[1]
	endif

	" if none of the bounds are set to 0, the cursor is in range
	if(s:l1 != 0 && s:c1 != 0 && s:l2 != 0 && s:c2 != 0)
		return 1
	endif

	" check if it is a valid range when cursor is under other delimiter
	if(s:left != s:right)
		let s:l1 = searchpairpos(s:left,'',s:right,'Wnb')[0]
		let s:c1 = searchpairpos(s:left,'',s:right,'Wnb')[1]
		let s:l2 = searchpairpos(s:left,'',s:right,'Wnc')[0]
		let s:c2 = searchpairpos(s:left,'',s:right,'Wnc')[1]
	else
		let s:l1 = searchpos(s:left, 'Wnb')[0]
		let s:c1 = searchpos(s:left, 'Wnb')[1]
		let s:l2 = searchpos(s:right,'Wnc')[0]
		let s:c2 = searchpos(s:right,'Wnc')[1]
	endif

	" if none of the bounds are set to 0, the cursor is in range (and under
	" right delimiter), otherwise, not in range.
	if(s:l1 != 0 && s:c1 != 0 && s:l2 != 0 && s:c2 != 0)
		return 1
	else
		return 0
	endif
endfunction

" selects the range so the operator will apply to it
function! s:SelectRange()
	" modify range if 'i' was used instead of 'a'
	if(s:ia == 'i')
		if s:mode ==# "V"
			" visual-line mode
			" bring bounds in one line each
			let s:l1+=1
			let s:l2-=1
		else
			" move upper/left bound in one
			if(len(getline(s:l1)) > s:c1)
				let s:c1+=1
			else
				let s:l1+=1
				let s:c1=1
			endif
			" move lower/right bound in one
			if(s:c2 > 1)
				let s:c2-=1
			else
				let s:l2-=1
				let s:c2=len(getline(s:l2))
			endif
		endif
	endif

	" using functions like cursor() to set cursor acts funny in this context.
	" Normal mode commands work fine.  I'd like to use |, but this uses
	" virtual-column rather than byte-wise columns.  Change c1/c2 to virtual
	" columns
	call cursor(s:l1,s:c1)
	let s:c1 = virtcol('.')
	call cursor(s:l2,s:c2)
	let s:c2 = virtcol('.')

	" select range
	if s:mode == "v" || s:mode == "V" || s:mode == "\<c-v>"
		" if already in a visual mode, use that same mode
		execute 'normal! '.s:l1.'G'.s:c1.'|'.s:mode.s:l2.'G'.s:c2.'|'
	else
		" visually select range - operator will apply to this range
		execute 'normal! '.s:l1.'G'.s:c1.'|v'.s:l2.'G'.s:c2.'|'
	endif
	return 1
endfunction

" searches for a text object range on the same line as the cursor currently
" is
function! s:SearchSameLine()
	while 1
		" check if cursor is already within a range that is on the same line
		if s:CursorInRange() && s:l1 == s:l2
			return s:SelectRange()
		endif
		" check if we've exhausted the search range.  if so, abort.
		" otherwise, move cursor and try again next loop
		if s:seek == 1
			" seek forward
			if col(".") >= col("$")-1
				return 0
			endif
			execute "normal! \<right>"
		elseif s:seek == 2
			" seek backward
			if col(".") <= col("^")+1
				return 0
			endif
			execute "normal! \<left>"
		else
			" don't seek
			return 0
		endif
	endwhile
endfunction

" searches for the text object in s:seek direction
function! s:SearchAnyLine()
	while 1
		if s:CursorInRange()
			" we found a range - select it and quit
			return s:SelectRange()
		elseif search(s:left.'\|'.s:right,'W'.s:seekdir) == 0
			" we could not find any range - abort
			return 0
		endif
	endwhile
endfunction

" vim: noet sw=8 sts=8
