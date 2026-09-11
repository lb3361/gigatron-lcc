#!/usr/bin/env python3
#
# This borrows from glink.py and could end up there

import builtins, argparse, sys


def error(s):
    raise RuntimeError(s)

def warning(s):
    print(f"gt1merge: warning: {s}", file=sys.stderr)

def lo(x):
    return x & 0xff

def hi(x):
    return x >> 8 

segments = []
execaddr = None

class Segment:
    '''Represent memory segments to be populated with code/data'''
    __slots__ = ('saddr', 'eaddr', 'buffer')
    def __init__(self, saddr, eaddr, flags=None):
        self.saddr = saddr
        self.eaddr = eaddr
        self.buffer = None
    def __repr__(self):
        return f"Segment({hex(self.saddr)},{hex(self.eaddr)})"

def load_gt1(fname):
    segments = []
    execaddr = None
    with open(fname,"rb") as fd:
        segheader = fd.read(3)
        while len(segheader) == 3:
            length = ((segheader[2]-1)&0xff)+1
            addr = (segheader[0]<<8) | segheader[1]
            segment = Segment(addr,addr+length)
            segment.buffer = fd.read(length)
            if len(segment.buffer) < length:
                raise EOFError(f"reading {fname}")
            segments.append(segment)
            segheader = fd.read(3)
            if not segheader or segheader[0] == 0:
                break
        if len(segheader) == 3 and segheader[0] == 0:
            execaddr = (segheader[1]<<8) | segheader[2]
        elif len(segheader) == 0 or len(segheader) != 1 and segheader[0] != 0:
            raise EOFError(f"reading {fname}")
        if len(fd.read(1)):
            warning(f"garbage after last gt1 record in {fname}")
    return segments,execaddr

def load_raw(fname,addr):
    with open(fname,"rb") as fd:
        d = fd.read()
    s = Segment(addr,addr+len(d))
    s.buffer = d;
    return [ s ]

def poke(addr,val):
    global segments
    for s in segments:
        if addr >= s.saddr and addr < s.eaddr:
            buf = bytearray(s.buffer)
            buf[addr-s.saddr] = val
            s.buffer = bytes(buf)
            return
    s = Segment(addr,addr+1)
    s.buffer = bytes([val])
    segments.append(s)

def doke(addr,val):
    poke(addr, val & 0xff)
    poke((addr&0xff00)|((addr+1)&0xff), val >> 8)

def check_overlaps(segments, message='segments'):
    sl = sorted(segments, key=lambda s: s.saddr)
    for i in range(len(sl)-1):
        if sl[i].eaddr > sl[i+1].saddr:
            error(f"{message} overlap near address {hex(sl[i+1].saddr)}")
    return sl

def collapse_segments(seglist):
    seglist = check_overlaps(seglist)
    cseglist = []
    nseglist = []
    for s in seglist + [ None ]:
        if s and s.buffer:
            if len(cseglist) == 0 or \
               hi(s.saddr) == 0 or \
               s.saddr <= cseglist[-1].saddr + len(cseglist[-1].buffer) + 3:
                cseglist.append(s)
                continue
        if s and hi(s.saddr) == 0:
            continue
        if len(cseglist) == 1:
            nseglist.append(cseglist[0])
        elif len(cseglist) > 1:
            buffer = bytearray(0)
            pc = cseglist[0].saddr
            ns = Segment(pc, cseglist[-1].eaddr, '')
            for cs in cseglist:
                if pc < cs.saddr:
                    buffer += builtins.bytes(cs.saddr - pc)
                    if pc <= 0x80 and cs.saddr > 0x80:
                        buffer[0x80 - cs.saddr] = 0x01
                    pc = cs.saddr
                buffer += cs.buffer
                pc += len(cs.buffer)
            ns.buffer = buffer
            nseglist.append(ns)
        cseglist = []
        if s and s.buffer:
            cseglist.append(s)
    return nseglist

def save_gt1(fname, segments, execaddr):
    segments = collapse_segments(segments)
    with open(fname,"wb") as fd:
        for s in segments:
            assert(s.buffer)
            a0 = s.saddr
            pc = s.saddr + len(s.buffer)
            while a0 < pc:
                a1 = min(s.eaddr, (a0 | 0xff) + 1)
                buffer = s.buffer[(a0-s.saddr):(a1-s.saddr)]
                fd.write(builtins.bytes((hi(a0),lo(a0),len(buffer)&0xff)))
                fd.write(buffer)
                a0 = a1
        fd.write(builtins.bytes((0, hi(execaddr), lo(execaddr))))



def main(argv):
    global segments
    global execaddr
    msg=''
    try:
        parser = argparse.ArgumentParser(
            usage='gt1merge {<gt1files>|<options>} -o <gt1file>',
            description='Merge gt1 data or binary data into a gt1 file')
        parser.add_argument('gt1files', type=str, nargs='*', metavar='<gt1files>',
                            help='non-overlapping gt1 files to merge')
        parser.add_argument('--raw', type=str, action='append', metavar="<fname>@<adr>",
                            help='merge binary files at specified address')
        parser.add_argument('--poke', type=str, action='append', metavar="<val>@<adr>",
                            help='write byte <val> at address <adr>')
        parser.add_argument('--doke', type=str, action='append', metavar="<val>@<adr>",
                            help='write word <val> at address <adr>')
        parser.add_argument('-o', type=str, default=None, metavar='<gt1file>',
                            help='output filename (default: None)')
        args = parser.parse_args(argv)
        # execute
        for gt1file in args.gt1files or []:
            msg = f'(processing {gt1file})'
            s,a = load_gt1(gt1file)
            segments = collapse_segments(segments + s)
            execaddr = execaddr or a
        for s in args.raw or []:
            msg = f'processing option --raw={s}'
            (f,a) = s.split('@')
            a = int(a,0)
            segments = collapse_segments(segments + load_raw(f,a))
        for s in args.poke or []:
            msg = f'processing option --poke={s}'
            v,a = s.split('@')
            v = int(v,0)
            a = int(a,0)
            if v != v & 0xff:
                warning(f'value {v} does not fit in a byte {msg}')
            if a != a & 0xffff:
                warning(f'address {v} is out of range {msg}')
            poke(a,v)
        for s in args.doke or []:
            msg = f'processing option --doke={s}'
            v,a = s.split('@')
            v = int(v,0)
            a = int(a,0)
            if v != v & 0xffff:
                warning(f'value {v} does not fit in a byte {msg}')
            if a != a & 0xffff:
                warning(f'address {v} is out of range {msg}')
            doke(a,v)
        msg = 'writing result'
        if not args.o:
            warning('No output file specified. Not writing anything')
        else:
            save_gt1(args.o, segments, execaddr)
        return 0
    #except FileNotFoundError as err:
    except Exception as err:
        print(f"gt1merge: error: {str(err)}", file=sys.stderr)
        if msg: print(f"  (while {msg}.)", file=sys.stderr)
        return 10

        
if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))



# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
