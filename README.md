# Introduction

I recently bought the [Human Resource Machine game](https://tomorrowcorporation.com/humanresourcemachine) from a Humble Bundle sale.

Then I was challenged by my mentor to write an interpreter for the instructions in the game, so I did.

# Data Files

To run the interpreter, 3 files are required.

## Initialize VM

The format of the file for initializing VM is:

```
memspace
init_constants_separated_by_space
```

For example:

```
25
A B C D E
```

will initialize the memory space with size `25`, and the constants `A` ... `E` will occupy memory address `24` ... `19`.

Visually, it will look like this:

```
[None, None, None, None, None, None, None, None, None, None, None, None, None, None, None, None, None, None, None, None, 'E', 'D', 'C', 'B', 'A']
```

## Commands

The game itself allows copying the instructions into plain text, which can be pasted into any text editor.

Remove the `-- HUMAN RESOURCE MACHINE PROGRAM --` comment and all `DEFINE COMMENT` and `DEFINE LABEL` instructions. Also, add `END` to the last line of the instructions.

For example:

```
a:
    INBOX   
    OUTBOX  
    JUMP     a
    END
```

is a valid format.

Possibly in the future, I will try to ignore `--` comments and `DEFINE` instructions. However, the interpreter won't run correctly without the `END` instruction, so it has to be there for now.

## Inputs

The inputs will be just a line of strings or numbers separated by space.

For example:

```
U N S E T 0 U N I T S 0
```

is a valid format.

# Running the Interpreter

To run, you must provide all 3 files as arguments to the program.

For example:

```
./interpreter.py --init init_vm.txt --cmd commands.txt --input inputs.txt
```

To print the memory allocation and instructions being run in the process, set the `-v` flag:

```
./interpreter.py --init init_vm.txt --cmd commands.txt --input inputs.txt -v
```

Otherwise, the interpreter will just print the input and output.

# Known Issues

~~1. I still can't quite get character conversion to work properly.~~ (*See [commit 5512deb71251682f312bbff5d30940e9a69ef2c6](https://github.com/gohkhoonhiang/humanresourcemachine/commit/5512deb71251682f312bbff5d30940e9a69ef2c6)*)
2. I need to find out how to terminate the program properly without having the `END` instruction.


Have fun with the interpreter! Feel free to file issues to suggest improvements to the interpreter as well.

