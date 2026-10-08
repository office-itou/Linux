# --- ACL ---------------------------------------------------------------------
sudo setfacl -R -m u:master:rwX /srv/user/share/conf/_data/
sudo setfacl -R -d -m u:master:rwX /srv/user/share/conf/_data/
getfacl /srv/user/share/conf/_data/


sudo bash -c 'for DIR in /srv/user/share/{conf,isos,imgs,rmak} /srv/tftp/ipxe
do
setfacl -R -m u:master:rwX "${DIR:?}"
setfacl -R -d -m u:master:rwX "${DIR:?}"
getfacl "${DIR:?}"
done'
# -----------------------------------------------------------------------------

python3 -m site --user-site

python3 -c "import site; print(site.getsitepackages())"


sudo apt-get install python3-venv
python3 -m venv ~/myenv
source ~/myenv/bin/activate


deactivate
rm -rf ~/myenv
python3 -m venv --system-site-packages ~/myenv
source ~/myenv/bin/activate


pip install  aiofiles aiohttp bs4 command-runner natsort pandas puremagic tk

make install
make clean
make build

