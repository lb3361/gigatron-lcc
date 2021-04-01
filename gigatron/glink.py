#!/usr/bin/env python
import argparse, os, sys



def main(argv):
    parser = argparse.ArgumentParser(
        usage='glink [options] file.{s,o,a} -l{library} -o {outputfile}',
        description='''Collects gigatron .{s,o,a} files into a .gt1 file
        ''')
    parser.add_argument('-o', type=str, default='a.gt1', metavar='file.gt1',
                        help='select the output filename (default: a.gt1)')
    parser.add_argument('files', type=str, nargs='+')
    parser.add_argument('-l', type=str, action='append')
    args = parser.parse_args(argv)

    print(args)
    
    print("glink does not work yet")
    
if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
    
# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
