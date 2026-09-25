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

