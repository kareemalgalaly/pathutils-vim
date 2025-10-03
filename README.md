# pathutils-vim
A handful of path-related and other utility functions used in my other plugins.

# Installation
Use your preferred plugin manager. I personally like [VimPlug](https://github.com/junegunn/vim-plug)

# Functions

```
pathutils#invert_escape(string, char)
pathutils#reg2vreg(regex)
pathutils#vreg2reg(viregex)
pathutils#matchcount(text, regex)
pathutils#splitpath(path)
pathutils#openpath(flags, ...)
pathutils#resolvepath(path)
pathutils#runbuffer(cmd, reuse)
pathutils#runbufferline(...)
pathutils#matchinternal(text, regex, index)
pathutils#invertcolors()
pathutils#getscriptsid(scriptname)
pathutils#getscriptfunc(scriptname, funcname)
pathutils#callscriptfunc(scriptname, funcname, arglist)
```

# License
Copyright © 2025 Kareem Ahmad

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

