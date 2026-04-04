#!/usr/bin/env python3

#   Copyright (c) 2021, LB3361
#
#    Redistribution and use in source and binary forms, with or
#    without modification, are permitted provided that the following
#    conditions are met:
#
#    1.  Redistributions of source code must retain the above copyright
#        notice, this list of conditions and the following disclaimer.
#
#    2. Redistributions in binary form must reproduce the above
#       copyright notice, this list of conditions and the following
#       disclaimer in the documentation and/or other materials
#       provided with the distribution.
#
#    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
#    CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
#    INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
#    MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#    DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
#    BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
#    EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
#    TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
#    DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
#    ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
#    OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
#    OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
#    POSSIBILITY OF SUCH DAMAGE.


import os, sys, json, tempfile, subprocess, re, argparse
import os.path as path
from glink import glink


# Utilities

def warning(s):
    print(f"glcc: warning: {s}", file=sys.stderr)

def error(s):
    print(f"glcc: {s}", file=sys.stderr)
    sys.exit(1)

# Locate progdir and lccdir
progname = os.path.realpath(__file__)
progdir = os.path.dirname(progname)
lccdir = os.getenv("LCCDIR")
if not lccdir:
    for dir in [ progdir, path.join(progdir, "../lib/gigatron-lcc") ]:
        if os.access(path.join(progdir, "rcc"), os.X_OK):
            lccdir = dir
            break
if not lccdir:
    error('cannot find glcc installation')
cppname = path.join(lccdir,"cpp")
rccname = path.join(lccdir,"rcc")
lnkname = path.join(lccdir,"glink")
os.putenv("LCCDIR", lccdir)


# Compute vernum from glccver (exactly as in old glcc.backup)
import glccver
vernum = None
if re.match('^GLCC_RELEASE_[0-9]*', glccver.ver):
    vlist = re.findall('([0-9]+)', glccver.ver)
    if len(vlist) >= 2:
        vernum = 100000 * int(vlist[0]) + 1000 * int(vlist[1])
    if len(vlist) >= 3:
        vernum += int(vlist[2])
           
# Program arguments
cpp_args = []
rcc_args = []
glink_args = []
hasv = 0                        # verbosity
haso = None                     # filename
hasc = None                     # None -E -S or -c
cntcomp = 0                     # counts compiled files
cntlink = 0                     # counts link inputs

# Main entry point    
def glcc(argv) -> int:

    global lccdir
    global cpp_args, rcc_args, glink_args
    global hasv, haso, hasc
    global cntcomp, cntlink

    try:

        # collect arguments minus -cpu, -rom, -map
        hascpu = False
        hasrom = False
        hasmap = False
        hasver = False
        hasinfo = False
        haskeep = False
        hashelp = False
        usage = False
        duplicate = None
        nargv = []

        # Initial argument lists
        glink_args = []
        rcc_args = [f"-target=gigatron"]
        cpp_args = [f"-D_GLCC_VER={vernum}",
                    f"-D__gigatron", f"-D__gigatron__",
                    f"-D__CHAR_UNSIGNED__"]
        cpp_args.append("-I" + path.join(lccdir, "include"))
        lccinputs = os.environ.get("LCCINPUTS")
        if lccinputs:
            for incdir in lccinputs.split(os.pathsep):
                if incdir and os.path.exists(incdir):
                    cpp_args.extend(["-I" + incdir])


        # Argument parsing helpers
        arg = None
        argi = None
        optarg = None

        def optz(a, dup=False):
            nonlocal arg, argi, optarg
            if not arg.startswith(a):
                return False
            elif dup:
                error(f"Option {arg} conflicts with option: {dup}")
            elif arg != a:
                error(f"Unrecognized option: {arg}")
            optarg = None
            return True

        def opt1(a, dup=False, styles="-+"):
            nonlocal arg, argi, optarg
            if not arg.startswith(a):
                return False
            elif arg == a and argi < len(argv) and '+' in styles:
                optarg = argv[argi]
                arg = f"{arg} {optarg}"
                argi += 1
            elif len(arg)-len(a)>1 and arg[len(a)]=='=' and '=' in styles:
                optarg = arg[len(a)+1:]
            elif len(arg)-len(a)>0 and '-' in styles:
                optarg = arg[len(a):]
            else:
                error(f"Unrecognized option: {arg}")
            return True

        # First process arguments whose meaning is not order dependent
        # This includes arguments for glcc, cpp, and rcc
        argi = 0;
        while argi < len(argv):
            arg = oarg = argv[argi]
            argi += 1
            if arg.startswith('--'):
                arg = arg[1:]
            if opt1("-cpu", dup=hascpu, styles='=+'):
                hascpu = optarg
            elif opt1("-map", dup=hasmap, styles='=+'):
                hasmap = optarg
            elif opt1("-rom", dup=hasrom, styles='=+'):
                hasrom = optarg
            elif optz("-info"):
                hasinfo = True
            elif optz("-keep"):
                haskeep = True
            elif optz("-help"):
                hashelp = True
            else:
                arg = oarg      # no longer accept double dashes
                if optz("-v"):
                    hasv += 1
                elif optz("-V"):
                    hasver = True
                elif optz("-E", dup=hasc):
                    hasc = arg
                elif optz("-S", dup=hasc):
                    hasc = arg
                elif optz("-c", dup=hasc):
                    hasc = arg
                elif opt1("-o", dup=haso, styles="+"):
                    haso = optarg
                elif opt1("-D"):
                    cpp_args.append("-D" + optarg);
                elif opt1("-U"):
                    cpp_args.append("-U" + optarg);
                elif opt1("-I"):
                    cpp_args.append("-I" + optarg);
                elif optz("-N"):
                    cpp_args.append(arg);
                elif optz("-b"):
                    rcc_args.append(arg)
                elif optz("-A"):
                    rcc_args.append(arg)
                elif arg.startswith("-g"):
                    rcc_args.append(arg)
                elif arg.startswith("-n"):
                    rcc_args.append(arg)
                elif optz("-O"):
                    rcc_args.append("-g0")
                elif opt1("-Wp"):
                    cpp_args.append(optarg)
                elif opt1("-Wf"):
                    rcc_args.append(optarg)
                    if optarg == "-unsigned-char=0":
                        cpp_args.append("-U__CHAR_UNSIGNED__")
                    elif optarg == "-unsigned-char=1":
                        cpp_args.append("-D__CHAR_UNSIGNED__")
                else:
                    nargv.append(arg)
        argv = nargv
        if hasver:
            print(glccver.ver)
            return 0
        if lccdir:
            os.environ["LCCDIR"] = lccdir

        # set defaults cpu according to rom
        roms = {}
        rominfo = {}
        romfile = path.join(lccdir, 'roms.json')
        if os.access(romfile, os.R_OK):
            with open(romfile) as file:
                roms = json.load(file)
        else:
            warning(f"glcc: cannot access rom file {s}")
        if hasrom and hasrom in roms:
            rominfo = roms[hasrom]
            if not hascpu:
                hascpu = rominfo['cpu']
        if hascpu:
            rcc_args.append(f"-cpu={hascpu}")
            glink_args.append(f"-cpu={hascpu}")
        if hasrom:
            glink_args.append(f"-rom={hasrom}")
        if hasmap:
            glink_args.append(f"-map={hasmap}")

        # Help and usage
        if len(argv) < 1:
            usage = True
        if hasinfo:
            glink_args.append("--info")
            return glink(glink_args)
        if hashelp:
            print_help()
            return 1
        if usage:
            print("Usage: glcc {...options_or_files...}", file=sys.stderr)
            print("Type glcc --help for more information", file=sys.stderr)
            return 1

        # Create temporary directory for intermediate files
        with tempfile.TemporaryDirectory(delete=not haskeep) as tmpdirname:

            # Now process arguments whose meaning is order dependent
            # This includes all files to be compiled and all arguments
            # to be passed to the linker.
            argi = 0
            while argi < len(argv):
                arg = argv[argi]
                argi += 1
                # options
                if opt1("-l"):
                    glink_args.append("-l" + optarg)
                elif opt1("-L"):
                    glink_args.append("-L" + optarg)
                elif opt1("-Wl"):
                    glink_args.append(optarg)
                elif opt1("-Wa"):
                    glink_args.append(optarg)
                elif arg.startswith("-"):
                    glink_args.append(arg)
                # input files
                elif arg.endswith(".c"):
                    glink_args.append(compile_c(arg, tmpdirname))
                    cntcomp += 1
                elif arg.endswith(".i"):
                    glink_args.append(compile_i(arg, tmpdirname))
                    cntcomp += 1
                elif arg.endswith(".s"):
                    glink_args.append(arg)
                    cntlink += 1
                elif arg.endswith(".o"):
                    glink_args.append(arg)
                    cntlink += 1
                elif arg.endswith(".a"):
                    glink_args.append(arg)
                else:
                    error(f"unrecognized file suffix {arg}")

            # stop?
            if hasc:
                if cntcomp == 0:
                    error("no input files")
                if cntlink != 0:
                    warning(f"ignoring linker inputs because of option '{hasc}'")
                return 0
            else:
                if cntcomp + cntlink == 0:
                    error("no input files")
                glink_args.extend(["-lc", "-o", haso] if haso else ["-lc"])
                if hasv: print(" ".join([ lnkname ] + glink_args))
                return glink(glink_args)
            
    except FileNotFoundError as err:
        error(str(err))
    except KeyboardInterrupt as err:
        error('keyboard interrupt')
    except Exception as err:
        error(repr(err))

def run(cmd):
    if hasv:
        print(' '.join(cmd), file=sys.stderr)
    result = subprocess.run(cmd)
    if result.returncode != 0:
        sys.exit(result.returncode)

mktempnum = 0
def mktempname(filename, tmpdirname, suffix):
    global mktempnum
    mktempnum += 1
    filename = path.splitext(path.basename(filename))[0]
    return path.join(tmpdirname,f"{filename}-{mktempnum:05d}{suffix}")

def compile_c(filename, tmpdirname, origname=None):
    outputname = None
    origname = origname or filename
    if hasc == '-E':
        if haso and cntcomp > 0:
            error(f"Cannot compile multiple files with options '{hasc}' and '-o'")
        outputname = haso
    else:
        outputname = mktempname(origname, tmpdirname, ".i")
    xtra = [ filename, outputname ] if outputname else [ filename ]
    run([ cppname ] + cpp_args + xtra)
    return hasc == '-E' or compile_i(outputname, tmpdirname, origname=filename)

def compile_i(filename, tmpdirname, origname=None):
    outputname = None
    origname = origname or filename
    if hasc and haso and cntcomp > 0:
        error(f"Cannot compile multiple files with options '{hasc}' and '-o'")
    if hasc and haso:
        outputname = haso
    elif hasc == '-S':
        outputname = path.splitext(path.basename(origname))[0] + ".s"
    elif hasc == '-c':
        outputname = path.splitext(path.basename(origname))[0] + ".o"
    else:
        outputname = mktempname(origname, tmpdirname, ".o")
    xtra = [ filename, "-o", outputname ]
    run([ rccname ] + rcc_args + xtra)
    return hasc or outputname


# Print help
def print_help():
    # We only use argparse for help formatting.
    # The idiosyncratic nature of traditional cc options
    # make it difficult to rely on generic mechanisms
    parser = argparse.ArgumentParser(
        usage='glcc [options] {<inputfiles>} [-o <outputfile>]',
        description='''A cross compiler targeting the Gigatron. See
        https://github.com/lb3361/gigatron-lcc for more information.
        The command line driver accepts arguments broadly compatible
        with those of traditional C compiler for Unix.  In addition,
        option `-rom` should be used to target a specific Gigatron
        rom, and option `-map` should be used to specify the memory
        map of interest.''',
        epilog='''Unrecognized options are passed to the linker
          `glink`. Nearly all options starting with double dashes are
          passed verbatim to the linker.  Command `glink --help`
          provides additional documentation about these options.''')
    # Adding options with just enough info to format the help
    parser.add_argument('-o', type=str, metavar='OUTPUTFILE',
                        help='''specify the output file name''')
    parser.add_argument('-rom', type=str,
                        help='''select the target rom version as
                        defined in roms.json, including v4, v5a, v6,
                        dev7 (default v6)''')
    parser.add_argument('-cpu', type=str, action='store',
                        help=''''select the target vCPU: 4, 5, 6, 7,
                        defaulting to a value implied by the -rom
                        option.''')
    parser.add_argument('-map', type=str,
                        help='''select the linker map defined in the
                        map<MAP> directory, including 32k, 64k, and
                        sim (default 32k). Use option --info to get
                        information about the selected map.''')
    parser.add_argument('-info', action='store_true',
                        help='''describe the selected rom, cpu, and
                        map, then exit.''')
    parser.add_argument('-V', action='store_true',
                        help='''print the glcc version string, then
                        exit.''')
    parser.add_argument('-v', action='store_true',
                        help='''increase verbosity and print all
                        subprocess command line arguments.''')
    parser.add_argument('-E', action='store_true',
                        help='''only invoke the preprocessor, writing
                        to the standard output if no output file is
                        specified with option `-o`.''')
    parser.add_argument('-S', action='store_true',
                        help='''only translate C files into
                        assembly files with suffix '.s', either
                        writing to files whose names are derived from
                        the input C file, or to the output file
                        specified with option `-o`.''')
    parser.add_argument('-c', action='store_true',
                        help='''only translates C files into object
                        files with suffix '.o', either writing to
                        files whose names are derived from the input C
                        file, or to the output file specified with
                        option `-o`.''')
    parser.add_argument('-D', type=str, action='append', metavar='SYMB=[VAL]',
                        help='''define a preprocessor symbol to the specified value or 1.''')
    parser.add_argument('-U', type=str, metavar='SYMB',
                        help='''undefine a preprocessor symbol.''')
    parser.add_argument('-I', type=str, metavar='DIR',
                        help='''add directory to the preprocessor include path.''')
    parser.add_argument('-N', action='store_true',
                        help='''clear the preprocessor include path, removing both
                        the directories specified with option `-I` and the default
                        directories.''')
    parser.add_argument('-L', type=str, metavar='DIR',
                        help='''add directory to the library search path.''')
    parser.add_argument('-l', type=str, metavar='LIB',
                        help='''link with the specified library found
                        along the path. For instance, option `-lxxx` searches
                        for a library named `libxxx.a`.''')
    parser.add_argument('-g', action='store_true',
                        help='''enable debugging features. They are
                        not very useful on the Gigatron except for
                        option '-g,###' which emits source code as
                        comments into the generated assembly ''')
    parser.add_argument('-n', action='store_true',
                        help='''insert runtime code that checks for
                        null pointers. The code reports the offending
                        file and line number and calls abort(3).''')
    parser.add_argument('-b', action='store_true',
                        help='''produce code that counts the number of
                        times each expression is executed. This works
                        best with `-map=sim` because it writes a
                        prof.out file when the program terminates. A
                        listing annotated with execution counts can
                        then be generated with bprint(1).''')
    parser.add_argument('-A', action='store_true',
                        help='''Warns about declarations and casts of
                        function types without prototypes, assignments
                        between pointers to ints and pointers to
                        enums, and conversions from pointers to
                        smaller integral types.  A second -A warns
                        about unrecognized control lines, nonANSI
                        language extensions and source characters in
                        literals, unreferenced variables and static
                        functions, declaring arrays of incomplete
                        types, and exceeding some ANSI environmental
                        limits, like more than 257 cases in switches.
                        It also arranges for duplicate global
                        definitions in separately compiled files to
                        cause loader errors.''')
    parser.add_argument('-Wp', type=str, metavar='ARG',
                        help='''pass argument ARG verbatim to the C preprocessor.''')
    parser.add_argument('-Wf', type=str, metavar='ARG',
                        help='''pass argument ARG verbatim to the C compiler.''')
    parser.add_argument('-Wl', type=str, metavar='ARG',
                        help='''pass argument ARG verbatim to the linker.''')
    parser.add_argument('-keep', action='store_true',
                        help='''preserve intermediate files instead of
                        deleting them after the compilation. Use
                        option `-v` to find out their names.''')
    
    # Format
    parser.print_help()
    print()


if __name__ == '__main__':
    sys.exit(glcc(sys.argv[1:]))

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
