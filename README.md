# Response files

Response files are files that are used by *some* compilers to allow command line arguments to be passed using a file.
There is **no** standard for response files like other formats like csv, json files.

## Popular compilers using response files

[MSVC](https://learn.microsoft.com/en-us/cpp/build/reference/cl-command-files?view=msvc-170)

[Zig Compiler](https://github.com/ziglang/zig)

[GCC](https://gcc.gnu.org/onlinedocs/gcc-4.6.3/gcc/Overall-Options.html)

## Here are some of the "specs" that this will be based on

**Disclaimer: Microsoft spec will have more weight than all the other specs as they are more intimate with the problem!**

[Intel Response Files](https://www.intel.com/content/www/us/en/docs/dpcpp-cpp-compiler/developer-guide-reference/2024-2/use-response-files.html)

[Dotnet Compiler](https://learn.microsoft.com/en-us/dotnet/visual-basic/reference/command-line-compiler/specify-response-file)

[MSVC](https://learn.microsoft.com/en-us/cpp/build/reference/cl-command-files?view=msvc-170)

Convenient Link:

[Android Review](https://android-review.linaro.org/plugins/gitiles/toolchain/sccache/+/80499f8732f081ebb44dc60a24cb325e220ddd39/docs/ResponseFiles.md)

## Spec that will be implemented

Here is the spec that has been chosen:

1. A line that starts with a `#` will be considered a comment
2. Each line will contain exactly one command line argument.
3. String quotation will not be stripped off the line.
4. Leading and trailing spaces will be stripped off when encountered
5. To have a multi line command (mostly a string), enclose it inside a '{}' block
6. If a file is not available, return the file as a variable

## Implementation specific

This is the implementation specific details that have nothing to do with the spec.

1. Errors will be returned as soon as they are found.
2. `FileNotFound` error will not be returned, instead, the file will be returned as the sole argument

## Examples of valid response file

Simple response file

```rsp
# From Intel:
#   https://www.intel.com/content/www/us/en/docs/dpcpp-cpp-compiler/developer-guide-reference/2024-2/use-response-files.html
# response file: response1.txt
# compile with these options 
  -w0  
# end of response1 file 
```

Response file with block

```rsp
# response file with block
# normal options
    -Wall
    -Werror
# Start of a block

{
This is a block
All this will be considered as one and not split upon
The newline will be kept.
        The indentation wil be kept too.
}

# End of block
#
```
