# Removing stuff:
# conda remove m2-mingw-w64-bzip2 m2-mingw-w64-gcc-libs m2-mingw-w64-gmp m2-mingw-w64-libwinpthread-git m2-msys2-bash m2-msys2-catgets m2-msys2-coreutils m2-msys2-dash m2-msys2-filesystem m2-msys2-findutils m2-msys2-gawk m2-msys2-gcc-libs m2-msys2-gmp m2-msys2-grep m2-msys2-gzip m2-msys2-inetutils m2-msys2-info m2-msys2-less m2-msys2-libcatgets m2-msys2-libcrypt m2-msys2-libiconv m2-msys2-libintl m2-msys2-libpcre m2-msys2-libreadline m2-msys2-libutil-linux m2-msys2-mintty m2-msys2-mpfr m2-msys2-msys2-runtime m2-msys2-ncurses m2-msys2-rebase m2-msys2-sed m2-msys2-tftp-hpa m2-msys2-time m2-msys2-tzcode m2-msys2-util-linux m2-msys2-which
# conda clean --all
# rm -rf ~/mc3/conda-bld/win-64/m2-*

import os
from conda_build import source
from conda_build.metadata import MetaData
import requests, hashlib
import tarfile
import tempfile
from glob import glob
from shutil import move, copy
from os.path import join, isdir, exists, normpath, dirname
from os import makedirs, getenv
import patch
import re

def get_tar_xz(url, md5):
    tmpdir = tempfile.mkdtemp()
    urlparts = requests.packages.urllib3.util.url.parse_url(url)
    fname = urlparts.path.split('/')[-1]
    sig = hashlib.md5()
    tmp_tar_xz = join(tmpdir, fname)
    if urlparts.scheme == 'file':
        path = re.compile('^file://').sub('',url).replace('/',os.sep)
        print('copying %s to %s' % (path, tmp_tar_xz))
        copy(path, tmp_tar_xz)
        with open(tmp_tar_xz, "rb") as tar_xz:
            for block in iter(lambda: tar_xz.read(1024), b""):
                sig.update(block)
        if sig.hexdigest() != md5:
            print('ERROR: md5 sum mismatch expected %s, got %s' % (md5, sig.hexdigest()))
        print(tmp_tar_xz)
        return tmp_tar_xz

    with open(tmp_tar_xz, 'wb') as tar_xz:
        response = requests.get(url, stream=True)
        for block in response.iter_content(1024):
            sig.update(block)
            tar_xz.write(block)
    if sig.hexdigest() != md5:
        print('ERROR: md5 sum mismatch expected %s, got %s' % (md5, sig.hexdigest()))
    return tmp_tar_xz

def main():
    recipe_dir = os.environ["RECIPE_DIR"]
    src_dir = os.environ["SRC_DIR"]
    conda_platform = 'win-32' if os.environ["ARCH"] == 'i686' else 'win-64'
    prefix = os.environ['PREFIX']
    print('prefix is %s, recipe_dir is %s' % (prefix, recipe_dir))
    main_work_dir = source.WORK_DIR
    
    metadata = MetaData(recipe_dir)
    msys2_tar_xz_url = metadata.get_section('extra')['msys2-binaries'][conda_platform]['url']
    msys2_md5 = metadata.get_section('extra')['msys2-binaries'][conda_platform]['md5']
    mv_src = metadata.get_section('extra')['msys2-binaries'][conda_platform]['mv-src']
    mv_dst = metadata.get_section('extra')['msys2-binaries'][conda_platform]['mv-dst']
    msys2_tar_xz = get_tar_xz(msys2_tar_xz_url, msys2_md5)
    tar = tarfile.open(msys2_tar_xz, 'r|xz')
    tar.extractall(path=prefix)

    try:
        patches = metadata.get_section('extra')['msys2-binaries'][conda_platform]['patches']
    except:
        patches = []
    if len(patches):
        for patchname in patches:
            patchset = patch.fromfile(join(getenv('RECIPE_DIR'),patchname))
            patchset.apply(1, root=prefix)

    # shutil is a bit funny (like mv) with regards to how it treats the destination
    # depending on whether it is an existing directory or not (i.e. moving into that
    # versus moving as that). Therefore, the rules employed are:
    # 1. If mv_dst ends with a '/' it is a directory that you want mv_src moved into.
    # 2. If mv_src has a wildcard, mv_dst is a directory that you want mv_src moved into.
    # In this case we makedirs(mv_dst) and then call move(mv_src, mv_dst)
    # .. otherwise we makedirs(dirname(mv_dst)) and then call move(mv_src, mv_dst)
    # ^ But .. in both cases, if no mv_srcs exist we don't makedirs at all.

    mv_dst_definitely_dir = False
    mv_srcs = glob(join(prefix, normpath(mv_src)))
    if '*' in mv_src or mv_dst.endswith('/') or len(mv_srcs) > 1:
        mv_dst_definitely_dir = True
    if len(mv_srcs):
        mv_dst = join(prefix, normpath(mv_dst))
        mv_dst_mkdir = mv_dst
        if not mv_dst_definitely_dir:
            mv_dst_mkdir = dirname(mv_dst_mkdir)
        try:
            makedirs(mv_dst_mkdir)
        except:
            pass
        for mv_src in mv_srcs:
            move(mv_src, mv_dst)
    tar.close()
    
if __name__ == "__main__":
    main()
