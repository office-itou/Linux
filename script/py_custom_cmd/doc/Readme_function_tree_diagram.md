# Function tree diagram

```bash
$ tree -a --charset C common/ -I __pycache__
common/
|-- __init__.py
|-- __main__.py
|-- common_import.txt
|-- common_var.text
|-- shared
|   |-- __init__.py
|   |-- __main__.py
|   |-- my_common_cfg.py
|   |-- my_distribution_dat.py
|   |-- my_media_dat.py
|   `-- my_shared.py
`-- utils
    |-- __init__.py
    |-- __main__.py
    |-- _my_infodata.py
    |-- my_argument.py
    |-- my_colors.py
    |-- my_config.py
    |-- my_debug.py
    |-- my_fileio.py
    |-- my_infofile.py
    |-- my_infoweb.py
    |-- my_json.py
    |-- my_markdown.py
    |-- my_message.py
    |-- my_process.py
    `-- my_string.py
```