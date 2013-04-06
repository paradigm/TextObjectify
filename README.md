TextObjectify
=============

Description
-----------

Vim's text-objects are an extremely powerful tool.  However, there are some
peculiar lackings in how they operate out-of-the-box.  The TextObjectify plugin
attempts to rectify these peculiarities as well as add the ability to allow the
user to create custom text-objects or even create text-objects on-the-fly
if a object is provided that does not already exist.

The peculiarities that TextObjectify attempts to resolve have to do with the
mutually-exclusive functionality of the parenthesis-like text-objects and the
quote-like text-objects.  The parenthesis-like text-objects are all able to
operate on objects that cover multiple lines; however, the cursor must be
on/within the object for it to work.  The quote-like text-objects only work
on a single line.  However, with the quote-like text-objects, the cursor will
seek ahead and jump to a text object if the cursor is not already within one.

For example, consider a buffer that contains nothing but the following:

    """
    some example code.
    section is multiple lines
    """

    if (getinput() == "yes") {
        print "this is an example"
        counter += 1
    }

If the cursor is on the `p` in `print` and the user types

    vi{

The area between the { and } characters will be selected.  However, if the
cursor is on the `s` in `some` and the user types

    vi"

nothing will happen, because quote-like text-objects do not work on multiple
lines.  With TextObjectify, the two lines between the triple quote sets will be
selected - the parenthesis-style text-object functionality will apply.

If the cursor is on the `p` in `print` and the user types

    vi"

the string `this is an example` will be selected, because quote-style
text-objects seek forward on the same line when looking for an object.
However, if the cursor is on the `i` in `if` and the user types

    vi(

nothing will happen, because parenthesis-like text-objects do not seek if
they are not in already within a text-object.  With TextObjectify, the region
between the parenthesis will be selected.

In addition to improving how existing text-objects function, TextObjectify
allows user to create custom text-objects.  To serve as examples,
TextObjectify comes with two custom text objects: `<cr>` will operate over the
entire buffer and `V` will operate over a block of viml.  With default
TextObjectify, if a user types

    "+ya<cr>

the entire buffer will be stored within the quoteplus register.

Consider a buffer that contains the following:

    if nr2char(getchar()) == g:quitmap
        echo "Quitting example"
        return 0
    endif

If the cursor is on any of the lines shown and the user enters `viV`, the
`echo` and `return` lines will be selected.

Moreover, TextObjectify has the ability to create text-objects on-the-fly if
an object is requested that is not provided by Vim out of the box and is not
one of TextObjectify's custom text objects.  Whatever character is provided
becomes the delimiter for either side.  For example, if the buffer contains the
following:


    LaTeX documents can show colors such as red, blue, green, and yellow.
    Additionally, they can show pretty mathematics such as $\int x^2dx$.

If the user would like to select an area between commas, there is no need to
plan ahead and create such a custom text-object.  The user can simply enter
"vi," and TextObjectify will create a text-object with commas as delimiters
on either side.  Similarly, the user could type "ci$" to change the area
between the dollar signs without having to create a custom text-object ahead
of time.

Setup
-----

TextObjectify can be installed like most other Vim plugins.  On a Unixy system
without a plugin manager, the textobjectify.vim file should be located at:

    ~/.vim/plugin/textobjectify.vim

On a Unixy system with pathogen, the textobjectify.vim file should be located at:

    ~/.vim/bundle/textobjectify/plugin/textobjectify.vim

On a Windows system without a plugin manager, the textobjectify.vim file should be located at:

    %USERPROFILE%\vimfiles\plugin\textobjectify.vim

On a Windows system with pathogen, the textobjectify.vim file should be located at:

    %USERPROFILE%\vimfiles\bundle\textobjectify\plugin\textobjectify.vim

If you are using a plugin manager other than pathogen, see its documentation
for how to install TextObjectify - it should be comparable to other plugins.

If you would like the documentation to also be installed, include textobjectify.txt
into the relevant directory described above, replacing `plugin` with `doc`.

TextObjectify should have same defaults and be useful without any additional
configuration.  However, to get the most out of TextObjectify, it is
recommended that you configure it to your own tastes.

Configuration
-------------

There are a handful of global variables which can be set to tweak how
TextObjectify operates.  The main one is g:textobjectify which contains
information on how to treat all custom text-objects or modifications of
existing text-objects.  The others tweak how on-the-fly text-objects
function.

All TextObjectify objects have the following attributes:

- 'left':  Regex for the left delimiter
- 'right': Regex for the right delimiter
- 'same':  Set to 1 to have object prioritize same-line objects over multi-line
  objects.  That is, if the situation is ambiguous, act like quote-like
  text-objects normally do.  Otherwise, set to 0 to have the object act like
  parenthesis-like text-objects normally do.
- 'seek': Sets whether or not to search for a text-object if the cursor is
  not already within one.  if 'seek' is 0, no seeking is done, i.e., if the
  cursor is not already within the text-object abort.  if 'seek' is 1, search
  forward for a text-object if the cursor is not already in one.  If 'seek'
  is 2, search backward for a text-object if the cursor is not already in
  one.  The parenthesis-style text-objects come in pairs - TextObjectify
  defaults to having the left item of the pairs search forward and the right
  item search backwards.
- 'line': If set to '1', it will force the object to act as though it is
  selected linewise.  The `V` text-object which TextObjectify comes with acts
  this way.

g:textobjectify is a Dictionary.  Each key is the character which is used
to select the object.  The values are Dictionaries with the above five
attributes.  For example, the default g:textobjectify is:

    let g:textobjectify = {
                \'(': {'left': '(', 'right': ')', 'same': 0, 'seek': 1, 'line': 0},
                \')': {'left': '(', 'right': ')', 'same': 0, 'seek': 2, 'line': 0},
                \'{': {'left': '{', 'right': '}', 'same': 0, 'seek': 1, 'line': 0},
                \'}': {'left': '{', 'right': '}', 'same': 0, 'seek': 2, 'line': 0},
                \'[': {'left': '[', 'right': ']', 'same': 0, 'seek': 1, 'line': 0},
                \']': {'left': '[', 'right': ']', 'same': 0, 'seek': 2, 'line': 0},
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

This sets how the parenthesis-like text-objects, the quote-like
text-objects, and the two new text-objects operate.  This is a good
reference if you want to make your own.

To create modify or create a new text-object, copy the above lines into your
vimrc and adjust accordingly.  Note that if you create a g:textobjectify in
your vimrc it overwrites all of TextObjectify's default values.  Thus if you
create an empty g:textobjectify all objects default will act as they would
without TextObjectify installed - quote-like text-objects will not act on
multiple lines, etc.

By default, TextObjectify will create new text-objects on-the-fly if a
mapping is called that does not correspond to an existing text-object (either
one of Vim's defaults or one provided by TextObjectify).  To disable this, set
g:textobjectify_onthefly to 0.

The 'same', 'seek' and 'line' attributes of on-the-fly text-objects can be
customized by setting the g:textobjectify_onthefly_same,
g:textobjectify_onthefly_seek, and g:textobjectify_onthefly_line variables
to the desired value.  Otherwise, they default to 0, 1, and 0, respectively.

Changelog
---------

0.1 (2013-04-06):
 - initial release
