#!/usr/bin/python3

import re
import argparse
import os.path


verbose = False

def init_vm(memspace, consts):
    print_log("init vm...")
    print_log("memspace: %d" % memspace)
    mem = [None] * memspace
    index = memspace - 1
    while consts:
        const = consts.pop(0)
        mem[index] = const
        index = index - 1
    print_log("mem: %s" % mem)
    print_log("init done...")
    return mem

def init_labels(commands):
    labels = {}
    p = re.compile("(?P<label>\w+):")
    for index,cmd in enumerate(commands):
        m = p.match(cmd)
        if m:
            lbl = m.group("label")
            labels[lbl] = index
    print_log("labels: %s" % labels)
    print_log("init labels done...")
    return labels
        
def run_commands(mem, commands, inputs):
    print_log("start running commands...")
    labels = init_labels(commands)
    outputs = interpret(mem, labels, commands, inputs)
    print_log("end running commands...")
    return outputs

def interpret(mem, labels, commands, inputs):
    outputs = []
    steps = 0
    print_log("interpreting...")
    p = re.compile("\[(?P<addr>\w+)\]")
    sub = re.compile("(\s)*SUB(\s)+\[(?P<addr>\w+)\]|(\s)*SUB(\s)+((?P<index>\w+))")
    add = re.compile("(\s)*ADD(\s)+\[(?P<addr>\w+)\]|(\s)*ADD(\s)+((?P<index>\w+))")
    jpz = re.compile("(\s)*JUMPZ(\s)+(?P<label>\w+)")
    jpn = re.compile("(\s)*JUMPN(\s)+(?P<label>\w+)")
    jmp = re.compile("(\s)*JUMP(\s)+(?P<label>\w+)")
    bup = re.compile("(\s)*BUMPUP(\s)+\[(?P<addr>\w+)\]|(\s)*BUMPUP(\s)+(?P<index>\w+)")
    bdn = re.compile("(\s)*BUMPDN(\s)+\[(?P<addr>\w+)\]|(\s)*BUMPDN(\s)+(?P<index>\w+)")
    cpt = re.compile("(\s)*COPYTO(\s)+\[(?P<addr>\w+)\]|(\s)*COPYTO(\s)+(?P<index>\w+)")
    cpf = re.compile("(\s)*COPYFROM(\s)+\[(?P<addr>\w+)\]|(\s)*COPYFROM(\s)+(?P<index>\w+)")
    ptr = 0
    x = None
    while True:
        print_log("mem: %s" % mem)
        cmd = commands[ptr]
        print_log("interpreting command: %s" % cmd)
        if "INBOX" in cmd:
            if not inputs:
                break
            x = inputs.pop(0)
        elif "OUTBOX" in cmd:
            outputs.append(x)
            x = None
        elif "ADD" in cmd:
            m = add.match(cmd)
            if m.group("addr"):
                i = get_addr(m)
                addr = get_val_from_mem(mem, i)
                x = x + mem[addr]
            else:
                i = get_index(m)
                x = x + mem[i]
        elif "SUB" in cmd:
            m = sub.match(cmd)
            if m.group("addr"):
                i = get_addr(m)
                addr = get_val_from_mem(mem, i)
                x = x - mem[addr]
            else:
                i = get_index(m)
                x = x - mem[i]
        elif "JUMPZ" in cmd:
            if x == 0:
                m = jpz.match(cmd)
                lbl = m.group("label")
                ptr = labels[lbl]
        elif "JUMPN" in cmd:
            if x < 0:
                m = jpn.match(cmd)
                lbl = m.group("label")
                ptr = labels[lbl]
        elif "JUMP" in cmd:
            m = jmp.match(cmd)
            lbl = m.group("label")
            ptr = labels[lbl]
        elif "BUMPUP" in cmd:
            m = bup.match(cmd)
            if m.group("addr"):
                i = get_addr(m)
                addr = get_val_from_mem(mem, i)
                mem[addr] = mem[addr] + 1
                x = mem[addr]
            else:
                i = get_index(m)
                mem[i] = mem[i] + 1
                x = get_val_from_mem(mem, i)
        elif "BUMPDN" in cmd:
            m = bdn.match(cmd)
            if m.group("addr"):
                i = get_addr(m)
                addr = get_val_from_mem(mem, i)
                mem[addr] = mem[addr] - 1
                x = mem[addr]
            else:
                i = get_index(m)
                mem[i] = mem[i] - 1
                x = get_val_from_mem(mem, i)
        elif "COPYTO" in cmd:
            m = cpt.match(cmd)
            if m.group("addr"):
                i = get_addr(m)
                addr = get_val_from_mem(mem, i)
                mem[addr] = x
            else:
                i = get_index(m)
                mem[i] = x
        elif "COPYFROM" in cmd:
            m = cpf.match(cmd)
            if m.group("addr"):
                i = get_addr(m)
                addr = get_val_from_mem(mem, i)
                x = mem[addr]
            else:
                i = get_index(m)
                x = get_val_from_mem(mem, i)
        elif "END" in cmd:
            break
        ptr = ptr + 1
        steps = steps + 1
    print_log("interpreted in %d steps with %d commands" % (steps, len(commands)))
    return outputs

def get_val_from_mem(mem, i):
    val = mem[i]
    return get_raw_val(val)

def get_index(m):
    return int(m.group("index"))

def get_addr(m):
    return int(m.group("addr"))

def get_raw_val(val):
    if val is not None :
        try:
            return int(val)
        except ValueError:
            if val.isalpha():
                return ord(val)
            return int(val)
    return None

def get_display_val(val):
    if val is not None:
        try:
            if chr(val).isalpha():
                return chr(val)
            else:
                return ord(chr(val))
        except ValueError:
            return val
    return None

def read_commands(file_name):
    commands = []
    with open(file_name, "r") as f:
        commands = f.readlines()

    f.close()

    commands = [cmd.replace("\t", " ") for cmd in commands]
    return commands

def read_inputs(file_name):
    line = ""
    with open(file_name, "r") as f:
        line = f.readline()
    f.close()

    inputs = [get_raw_val(val) for val in line.strip().split(" ")]
    return inputs

def read_init(file_name):
    lines = []
    memspace = None
    constants = []
    with open(file_name, "r") as f:
        lines = f.readlines()

    f.close()

    memspace = int(lines[0].strip())
    memspace = get_raw_val(lines[0].strip())
    if len(lines) == 2:
        constants = [get_raw_val(val) for val in lines[1].strip().split(" ")]
    return memspace, constants

def print_log(line):
    if verbose:
        print(line)

def print_error(line):
    print("Error: %s" % line)

def check_file(filename):
    if not os.path.isfile(filename):
        print_error("%s not found" % filename)
        exit(1)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="HRM Instructions Interpreter")
    parser.add_argument("--init", help="file path to init VM data", default="init_vm.txt", required=True, dest="init_filename")
    parser.add_argument("--cmd", help="file path to commands data", default="commands.txt", required=True, dest="cmd_filename")
    parser.add_argument("--input", help="file path to input data", default="inputs.txt", required=True, dest="in_filename")
    parser.add_argument("--verbose", "-v", help="print log", action="count")
    args = parser.parse_args()
    init_filename = args.init_filename
    check_file(init_filename)
    cmd_filename = args.cmd_filename
    check_file(cmd_filename)
    in_filename = args.in_filename
    check_file(in_filename)
    verbose = True if args.verbose else False
    memspace, constants = read_init(init_filename)
    mem = init_vm(memspace, constants)
    commands = read_commands(cmd_filename)
    inputs = read_inputs(in_filename)
    print("inputs: %s" % [get_display_val(val) for val in inputs])
    outputs = run_commands(mem, commands, inputs)
    print("outputs: %s" % [get_display_val(val) for val in outputs])

