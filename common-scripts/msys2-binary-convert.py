import os
from conda_build import source
from conda_build.metadata import MetaData
import requests, hashlib
import tarfile
import tempfile
from os.path import join

def get_tar_xz(url, md5):
    tmpdir = tempfile.mkdtemp()
    urlparts = requests.packages.urllib3.util.url.parse_url(url)
    fname = urlparts.path.split('/')[-1]
    sig = hashlib.md5()
    tmp_tar_xz = join(tmpdir, fname)
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
    print('prefix is %s' % prefix)
    main_work_dir = source.WORK_DIR
    
    metadata = MetaData(recipe_dir)
    msys2_tar_xz_url = metadata.get_section('extra')['msys2-binaries'][conda_platform]['url']
    msys2_md5 = metadata.get_section('extra')['msys2-binaries'][conda_platform]['md5']
    msys2_tar_xz = get_tar_xz(msys2_tar_xz_url, msys2_md5)
    tar = tarfile.open(msys2_tar_xz, 'r|xz')
    tar.extractall(path=prefix)
    tar.close()
    
if __name__ == "__main__":
    main()

