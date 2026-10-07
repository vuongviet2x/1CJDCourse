"""Minimal unpacker for 1C:Enterprise 8 container files (.cf/.cfe/.epf).
Usage: python v8unpack.py <file> <outdir>"""
import os, struct, sys, zlib

def read_doc(buf, addr):
    out = bytearray(); size = None
    while addr != 0x7FFFFFFF:
        h = buf[addr:addr + 31]
        doc_size = int(h[2:10], 16); blk = int(h[11:19], 16); nxt = int(h[20:28], 16)
        if size is None: size = doc_size
        take = min(blk, size - len(out))
        out += buf[addr + 31: addr + 31 + take]
        if len(out) >= size: break
        addr = nxt
    return bytes(out)

def is_container(b):
    return len(b) >= 47 and b[:4] == b'\xff\xff\xff\x7f'

def unpack(buf, outdir):
    os.makedirs(outdir, exist_ok=True)
    toc = read_doc(buf, 16)
    for i in range(0, len(toc) - 11, 12):
        ha, da, _ = struct.unpack('<III', toc[i:i + 12])
        hdr = read_doc(buf, ha)
        name = hdr[20:].decode('utf-16-le', 'ignore').split('\x00')[0]
        data = read_doc(buf, da) if da != 0x7FFFFFFF else b''
        try:
            data = zlib.decompress(data, -15)
        except zlib.error:
            pass
        path = os.path.join(outdir, name)
        if is_container(data):
            unpack(data, path)
        else:
            with open(path, 'wb') as f: f.write(data)

if __name__ == '__main__':
    unpack(open(sys.argv[1], 'rb').read(), sys.argv[2])
