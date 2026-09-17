<details>
<summary>📦 <b>my_common_cfg.py</b> の構造ツリーを表示</summary>

```text
common/shared/my_common_cfg.py:
+-- class: ConfigurationData # common.cfg data class
+-- class: InfoConfiguration # common.cfg interface class
|   +-- func: __init__() # Method for initializing the ConfigurationData class.
|   |   +-- arg : self
|   |   `-- ret : [None]
|   +-- func: __getattr__() # Special methods
|   |   +-- arg : self
|   |   +-- arg : [name: str [Attribute name]]
|   |   `-- ret : [Any]
|   +-- func: load() # Load file
|   |   +-- arg : self
|   |   `-- ret : [None]
|   +-- func: findregexp() # Search for the data class within self.data. (Supports regular expressions)
|   |   +-- arg : self
|   |   +-- arg : [queries: list[dict[str, str]] [Query]]
|   |   `-- ret : [list[ConfigurationData]]
|   +-- func: finds() # Search for the data class within self.data.
|   |   +-- arg : self
|   |   +-- arg : [**kwargs]
|   |   `-- ret : [list[ConfigurationData]]
|   +-- func: find() # Search for the data class within self.data. (The first one)
|   |   +-- arg : self
|   |   +-- arg : [**kwargs]
|   |   `-- ret : [ConfigurationData]
|   +-- func: markdown() # Generating Markdown
|   |   +-- arg : self
|   |   +-- arg : [dest_path: str [Destination path]]
|   |   +-- arg : [md_title: str [Markdown title]]
|   |   `-- ret : [None]
|   +-- func: dump() # Data dump output
|   |   +-- arg : self
|   |   +-- arg : [wrap: bool = False [Toggle text wrapping. Defaults to False.]]
|   |   `-- ret : [None]
|   +-- func: conv2data() # Convert actual data to variable names
|   |   +-- arg : self
|   |   +-- arg : [src_data: list[MediaData] [Source data]]
|   |   `-- ret : [list[MediaData]]
|   +-- func: conv2variable() # Convert variable names to actual data
|   |   +-- arg : self
|   |   +-- arg : [src_data: list[MediaData] [Source data]]
|   |   `-- ret : [list[MediaData]]
|   `-- func: get_path() # Gets the key path.
|       +-- arg : self
|       +-- arg : [key: str [Key]]
|       `-- ret : [Path]
+-- func: load() # load data in common.cfg
|   `-- ret : [list[ConfigurationData]]
+-- func: conv2data() # convert to data format
|   +-- arg : [list_conf: list[ConfigurationData] [list_orig]]
|   +-- arg : [list_orig: list [list_orig]]
|   `-- ret : [list]
`-- func: conv2variable() # convert to variable format
    +-- arg : [list_conf: list[ConfigurationData] [list_conf]]
    +-- arg : [list_orig: list [list_orig]]
    `-- ret : [list]
```

</details>

<details>
<summary>📦 <b>my_convert.py</b> の構造ツリーを表示</summary>

```text
common/shared/my_convert.py:
+-- func: spc_encode() # Encoding whitespace characters on a per-list basis
|   +-- arg : [src_datas: list [Source data]]
|   `-- ret : [list]
+-- func: spc_decode() # Decoding whitespace characters on a per-list basis
|   +-- arg : [src_datas: list]
|   `-- ret : [list]
+-- func: get_text2list() # Text file to list
|   +-- arg : [src_path: str [Source path]]
|   `-- ret : [list[dict[str, str]]]
`-- func: put_list2text() # list to text file
    +-- arg : [dst_path: str [Destination path]]
    +-- arg : [src_datas: list]
    +-- arg : [format_str: str [Output format]]
    `-- ret : [None]
```

</details>

<details>
<summary>📦 <b>my_distribution_dat.py</b> の構造ツリーを表示</summary>

```text
common/shared/my_distribution_dat.py:
+-- class: DistributionData # distribution.dat data class
+-- class: InfoDistribution # distribution.dat interface class
|   +-- func: __init__() # Method for initializing the DistributionData class.
|   |   +-- arg : self
|   |   +-- arg : [src_path: Path [Source path. Defaults to None.]]
|   |   `-- ret : [None]
|   +-- func: __getattr__() # Special methods
|   |   +-- arg : self
|   |   +-- arg : [name: str [Attribute name]]
|   |   `-- ret : [Any]
|   +-- func: load() # Load file
|   |   +-- arg : self
|   |   +-- arg : [src_path: Path [Source path]]
|   |   `-- ret : [None]
|   +-- func: save() # Save file
|   |   +-- arg : self
|   |   +-- arg : [dest_path: Path [Destination path]]
|   |   `-- ret : [None]
|   +-- func: findregexp() # Search for the data class within self.data. (Supports regular expressions)
|   |   +-- arg : self
|   |   +-- arg : [queries: list[dict[str, str]] [Query]]
|   |   `-- ret : [list[DistributionData]]
|   +-- func: finds() # Search for the data class within self.data.
|   |   +-- arg : self
|   |   +-- arg : [**kwargs]
|   |   `-- ret : [list[DistributionData]]
|   +-- func: find() # Search for the data class within self.data. (The first one)
|   |   +-- arg : self
|   |   +-- arg : [**kwargs]
|   |   `-- ret : [list[DistributionData]]
|   +-- func: markdown() # Generating Markdown
|   |   +-- arg : self
|   |   +-- arg : [dest_path: str [Destination path]]
|   |   +-- arg : [md_title: str [Markdown title]]
|   |   `-- ret : [None]
|   +-- func: dump() # Data dump output
|   |   +-- arg : self
|   |   +-- arg : [wrap: bool = False [Toggle text wrapping. Defaults to False.]]
|   |   `-- ret : [None]
|   +-- func: get_text2list() # Text file to list
|   |   +-- arg : self
|   |   +-- arg : [src_path: Path [Source path]]
|   |   `-- ret : [None]
|   +-- func: put_list2text() # list to text file
|   |   +-- arg : self
|   |   +-- arg : [dest_path: Path [Destination path]]
|   |   +-- arg : [format_str: str [Output format]]
|   |   `-- ret : [None]
|   +-- func: sort() # A wrapper that sorts and outputs the DistributionData class.
|   |   +-- arg : self
|   |   +-- arg : [distribution: str = "" [Target distribution. Defaults to "".]]
|   |   +-- arg : [reverse: bool = False [Reverse off/on. Defaults to False.]]
|   |   `-- ret : [list[DistributionData]]
+-- func: sort_distribution_data() # Sort and output the DistributionData class.
|   +-- arg : [data: DistributionData [Source data]]
|   +-- arg : [distribution: str = "" [Target distribution. Defaults to "".]]
|   +-- arg : [reverse: bool = False [Reverse off/on. Defaults to False.]]
|   `-- ret : [list[DistributionData]]
|   +-- func: make_universal_sort_key()
|   |   `-- arg : [item]
`-- func: sort_distribution_name() # Sort and output the DistributionData class.
    +-- arg : [data: list [Source data]]
    `-- ret : [list]
    `-- func: get_sort_key()
        `-- arg : [key]
```

</details>

<details>
<summary>📦 <b>my_media_dat.py</b> の構造ツリーを表示</summary>

```text
common/shared/my_media_dat.py:
+-- class: MediaData # media.dat data class
`-- class: InfoMedia # media.dat interface class
    +-- func: __init__() # Method for initializing the MediaData class.
    |   +-- arg : self
    |   +-- arg : [src_path: Path [Source path. Defaults to None.]]
    |   +-- arg : [info_conf: InfoConfiguration [common.cfg interface class. Defaults to None.]]
    |   `-- ret : [None]
    +-- func: __getattr__() # Special methods
    |   +-- arg : self
    |   +-- arg : [name: str [Attribute name]]
    |   `-- ret : [Any]
    +-- func: load() # Load file
    |   +-- arg : self
    |   +-- arg : [src_path: Path [Source path]]
    |   `-- ret : [None]
    +-- func: save() # Save file
    |   +-- arg : self
    |   +-- arg : [dest_path: Path [Destination path]]
    |   `-- ret : [None]
    +-- func: findregexp() # Search for the data class within self.data. (Supports regular expressions)
    |   +-- arg : self
    |   +-- arg : [queries: list[dict[str, str]] [Query]]
    |   `-- ret : [list[MediaData]]
    +-- func: finds() # Search for the data class within self.data.Data search in common.cfg
    |   +-- arg : self
    |   +-- arg : [**kwargs]
    |   `-- ret : [list[MediaData]]
    +-- func: find() # Search for the data class within self.data. (The first one)
    |   +-- arg : self
    |   +-- arg : [**kwargs]
    |   `-- ret : [list[MediaData]]
    +-- func: markdown() # Generating Markdown
    |   +-- arg : self
    |   +-- arg : [dest_path: str [Destination path]]
    |   +-- arg : [md_title: str [Markdown title]]
    |   `-- ret : [None]
    +-- func: dump() # Data dump output
    |   +-- arg : self
    |   +-- arg : [wrap: bool = False [Toggle text wrapping. Defaults to False.]]
    |   `-- ret : [None]
    +-- func: get_text2list() # Text file to list
    |   +-- arg : self
    |   +-- arg : [src_path: Path [Source path]]
    |   `-- ret : [None]
    +-- func: put_list2text() # list to text file
    |   +-- arg : self
    |   +-- arg : [dest_path: Path [Destination path]]
    |   +-- arg : [format_str: str [Output format]]
    |   `-- ret : [None]
    +-- func: conv2data() # Convert actual data to variable names
    |   +-- arg : self
    |   `-- ret : [None]
    `-- func: conv2variable() # Convert variable names to actual data
        +-- arg : self
        `-- ret : [list[dict[str, Any]]]
```

</details>

<details>
<summary>📦 <b>my_shared.py</b> の構造ツリーを表示</summary>

```text
common/shared/my_shared.py:
+-- class: Text_fmat # Text data output format
+-- class: ConfData
+-- class: DistData
+-- class: MdiaData
+-- class: CommonData
`-- class: InfoCommon # InfoCommon interface class
    `-- func: __init__() # Method for initializing the data class.
        +-- arg : self
        `-- ret : [None]
```

</details>

<details>
<summary>📦 <b>my_argument.py</b> の構造ツリーを表示</summary>

```text
common/utils/my_argument.py:
`-- class: Argument # argparse wrapper class.
    +-- class: DefaultListAction
    |   `-- base: argparse.Action
    |   `-- func: __call__()
    |       +-- arg : self
    |       +-- arg : [parser]
    |       +-- arg : [namespace]
    |       +-- arg : [values]
    |       `-- arg : [option_string=None]
    +-- func: __init__() # Method for initializing the Argument class.
    |   +-- arg : self
    |   `-- arg : [description: str = ""]
    +-- func: add() # Method for adding command-line arguments.
    |   +-- arg : self
    |   +-- arg : [*args]
    |   `-- arg : [**kwargs]
    `-- func: parse() # Method for returning the analysis results.
        `-- arg : self
```

</details>

<details>
<summary>📦 <b>my_colors.py</b> の構造ツリーを表示</summary>

```text
common/utils/my_colors.py:
+-- class: Code # Control code class
+-- class: Color # Color code class
|   `-- base: Code
`-- class: Emoji # Emoji code class
    `-- base: Code
```

</details>

<details>
<summary>📦 <b>my_config.py</b> の構造ツリーを表示</summary>

```text
common/utils/my_config.py:
+-- class: SystemData # System data class
`-- class: InfoSystem # System information class
    +-- func: __init__()
    |   `-- arg : self
    +-- func: __getattr__()
    |   +-- arg : self
    |   +-- arg : [name: str]
    |   `-- ret : [Any]
    +-- func: __setattr__()
    |   +-- arg : self
    |   +-- arg : [name: str]
    |   +-- arg : [value: Any]
    |   `-- ret : [None]
    `-- func: to_dict()
        +-- arg : self
        `-- ret : [dict[str, Any]]
```

</details>

<details>
<summary>📦 <b>my_debug.py</b> の構造ツリーを表示</summary>

```text
common/utils/my_debug.py:
+-- func: debug_logger() # Debug output decorator
|   `-- arg : [func: Callable]
|   `-- func: _wrapper()
|       +-- arg : [*args]
|       `-- arg : [**kwargs]
+-- func: debugout_scale() # Debug output for scale
|   `-- arg : [size: int [Scale value]]
`-- func: debugout() # Debug output
    +-- arg : [function_name: str [Function name]]
    +-- arg : [mode: str [Mode ("Start", "Complete", ....)]]
    +-- arg : [message_color: str [Color (`color.br_green`)]]
    `-- arg : [message: str [Message]]
```

</details>

<details>
<summary>📦 <b>my_error.py</b> の構造ツリーを表示</summary>

```text
common/utils/my_error.py:
`-- func: handle_fatal_error() # Fatal error handler
    +-- arg : [caller: str [Function name]]
    +-- arg : [e: Exception [Error information]]
    `-- ret : [None]
```

</details>

<details>
<summary>📦 <b>my_file_api.py</b> の構造ツリーを表示</summary>

```text
common/utils/my_file_api.py:
+-- func: file_read() # File read (line break codes in text files are standardized to "\n")
|   +-- arg : [src_path: Path [Source path]]
|   +-- arg : [text: bool = True [Read mode. Defaults to True.]]
|   `-- ret : [str | bytes]
+-- func: file_write() # File write (line break codes in text files are standardized to "\n")
|   +-- arg : [dest_path: Path [Destination path]]
|   +-- arg : [data: str | bytes | None = None [Output data. Defaults to None.]]
|   +-- arg : [text: bool = True [Write mode. Defaults to True.]]
|   +-- arg : [backup: bool = False [Backup mode. Defaults to False.]]
|   `-- ret : [None]
+-- func: file_copy() # File copy
|   +-- arg : [src_path: Path [Source path]]
|   +-- arg : [dest_path: Path [Destination path]]
|   +-- arg : [backup: bool = False [Backup. Defaults to False.]]
|   `-- ret : [None]
`-- func: file_backup() # File backup
    +-- arg : [src_path: Path [Source path]]
    `-- ret : [None]
```

</details>

<details>
<summary>📦 <b>my_infofile.py</b> の構造ツリーを表示</summary>

```text
common/utils/my_infofile.py:
+-- class: FileData # File data class
+-- class: InfoFile # File information class
|   +-- func: __init__()
|   |   +-- arg : self
|   |   `-- arg : [data: FileData = None]
|   +-- func: get_data()
|   |   +-- arg : self
|   |   `-- ret : [FileData]
|   +-- func: get_info()
|   |   +-- arg : self
|   |   +-- arg : [target_path: str]
|   |   `-- ret : [FileData]
|   +-- func: get_volume_uuid()
|   |   +-- arg : [device: str]
|   |   `-- ret : [str]
|   `-- func: get_volume_label()
|       +-- arg : [device: str]
|       `-- ret : [str]
+-- func: get_volume_uuid() # Get volume uuid
|   +-- arg : [device: str [Device name]]
|   `-- ret : [str]
+-- func: get_volume_label() # Get volume label
|   +-- arg : [device: str [Device name]]
|   `-- ret : [str]
`-- func: get_info() # Get file information data
    +-- arg : [target_path: str [Target path]]
    `-- ret : [FileData]
```

</details>

<details>
<summary>📦 <b>my_infoweb.py</b> の構造ツリーを表示</summary>

```text
common/utils/my_infoweb.py:
+-- class: InfoWeb # Web information class
|   +-- func: __init__()
|   |   +-- arg : self
|   |   `-- ret : [None]
|   +-- func: __getattr__()
|   |   +-- arg : self
|   |   +-- arg : [name: str]
|   |   `-- ret : [Any]
|   +-- func: get_data()
|   |   +-- arg : self
|   |   `-- ret : [list[WebData]]
|   +-- func: get_header()
|   |   +-- arg : self
|   |   +-- arg : [session: aiohttp.ClientSession]
|   |   +-- arg : [request_url: str]
|   |   `-- ret : [WebData]
|   +-- func: get_text()
|   |   +-- arg : self
|   |   +-- arg : [session: aiohttp.ClientSession]
|   |   +-- arg : [request_url: str]
|   |   `-- ret : [WebData]
|   `-- func: get_info()
|       +-- arg : self
|       +-- arg : [session: aiohttp.ClientSession]
|       +-- arg : [request_urls: str]
|       +-- arg : [local_file: str]
|       +-- arg : [exclude_urls: str = ""]
|       `-- ret : [list[WebData]]
+-- func: _compile_exclude_regex() # Compiling exclusion patterns
|   +-- arg : [exclude_url: str]
|   `-- ret : [re.Pattern | None]
+-- func: _expand_regexp_urls() # Hierarchical expansion of URL regular expressions
|   +-- arg : [info_web: InfoWeb]
|   +-- arg : [session: aiohttp.ClientSession]
|   +-- arg : [search_url: str]
|   +-- arg : [exclude_url: re.Pattern | None]
|   +-- arg : [latest: bool = True]
|   `-- ret : [list[str]]
`-- func: get_infoweb() # get_infoweb main control function
    +-- arg : [session: aiohttp.ClientSession]
    +-- arg : [search_url: str]
    +-- arg : [local_file: str]
    +-- arg : [exclude_url: str = ""]
    `-- ret : [list[WebData]]
```

</details>

<details>
<summary>📦 <b>my_json.py</b> の構造ツリーを表示</summary>

```text
common/utils/my_json.py:
+-- func: json_load() # Load data in json format
|   +-- arg : [src_path: Path [Source path]]
|   `-- ret : [Any]
`-- func: json_save() # Save distridata in json format
    +-- arg : [dest_path: Path [Destination path]]
    +-- arg : [src_data: Any [Source data]]
    `-- ret : [None]
```

</details>

<details>
<summary>📦 <b>my_markdown.py</b> の構造ツリーを表示</summary>

```text
common/utils/my_markdown.py:
+-- func: list2markdown() # Markdown output of list data
|   +-- arg : [dest_path: str [Destination path]]
|   +-- arg : [md_title: str [Markdown title]]
|   +-- arg : [src_datas: list]
|   `-- ret : [None]
|   +-- func: _conversion_url()
|   |   +-- arg : [list_data: list]
|   |   `-- ret : [list]
|   `-- func: _generate()
|       `-- arg : [list_data: list]
`-- func: markdown2list() # List data output of markdown
    +-- arg : [src_path: str [Source path]]
    `-- ret : [list]
```

</details>

<details>
<summary>📦 <b>my_message.py</b> の構造ツリーを表示</summary>

```text
common/utils/my_message.py:
+-- func: message_date() # Message output for datetime
|   +-- arg : [func_name: str [Function name]]
|   +-- arg : [mode: str [Message category]]
|   +-- arg : [message_color: str [Message color]]
|   `-- arg : [date_time: str [Formatted date and time]]
+-- func: message_start() # Message output for startup
|   `-- arg : [func_name: str [Function name]]
+-- func: message_end() # Message output for termination
|   `-- arg : [func_name: str [Function name]]
+-- func: message_elapsed() # Message output for elapsed time
|   +-- arg : [func_name: str [Function name]]
|   `-- arg : [elapsed: str [Elapsed time]]
+-- func: message_debug() # Message output for debug
|   +-- arg : [func_name: str [Function name]]
|   +-- arg : [mode: str [Message category]]
|   +-- arg : [message_color: str [Message color]]
|   `-- arg : [message: str [Message]]
+-- func: message_info() # message output for information
|   +-- arg : [func_name: str [Function name]]
|   +-- arg : [message: str [Message]]
|   `-- arg : [omit: bool = False [Omit. Defaults to False.]]
+-- func: message_warn() # Message output for warning
|   +-- arg : [func_name: str [Function name]]
|   +-- arg : [message: str [Message]]
|   `-- arg : [omit: bool = False [Omit. Defaults to False.]]
+-- func: message_alert() # Message output for alert
|   +-- arg : [func_name: str [Function name]]
|   +-- arg : [message: str [Message]]
|   `-- arg : [omit: bool = False [Omit. Defaults to False.]]
+-- func: get_caller_name() # Get function name
|   +-- arg : [only: bool = True [Function only or including filename. Defaults to True.]]
|   `-- ret : [str]
`-- func: generate_comment() # Omit the intermediate characters.
    +-- arg : [modu_name: str [Module name]]
    +-- arg : [func_name: str [Function name]]
    +-- arg : [para: str = "" [Parameter. Defaults to "".]]
    `-- ret : [str]
```

</details>

<details>
<summary>📦 <b>my_process.py</b> の構造ツリーを表示</summary>

```text
common/utils/my_process.py:
`-- func: run_subprocess() # Subprocess wrapper
    +-- arg : [*args]
    +-- arg : [**kwargs]
    `-- ret : [str]
```

</details>

<details>
<summary>📦 <b>my_string.py</b> の構造ツリーを表示</summary>

```text
common/utils/my_string.py:
+-- func: count_full_width() # Character count for full-width characters only
|   +-- arg : [src_text: str [Source text]]
|   `-- ret : [int]
+-- func: count_half_width() # Character count for half-width characters only
|   +-- arg : [src_text: str [Source text]]
|   `-- ret : [int]
+-- func: count_width() # Character count for full-width and half-width characters
|   +-- arg : [src_text: str [Source text]]
|   `-- ret : [int]
+-- func: get_char_width() # character count for full-width and half-width characters on the screen
|   +-- arg : [src_char: str]
|   `-- ret : [int]
+-- func: split_by_width() # Character splitting for full-width and half-width characters on the screen
|   +-- arg : [src_text: str [Source text]]
|   +-- arg : [max_width: int [Max width]]
|   +-- arg : [from_back: bool = False [From back. Defaults to False.]]
|   +-- arg : [omit: bool = False [Omit. Defaults to False.]]
|   `-- ret : [list]
+-- func: eprint() # Screen output with character splitting that supports escape characters and full-width/half-width characters.
|   +-- arg : [src_text: str [Source text]]
|   +-- arg : [max_width: int = 0 [Max width. Defaults to 0.]]
|   `-- arg : [wrap: bool = False [Wrap. Defaults to False.]]
`-- func: omit_middle() # Omit the intermediate characters.
    +-- arg : [src_text: str [Source text]]
    +-- arg : [max_len: int = 80 [Max length. Defaults to 80.]]
    +-- arg : [placeholder: str = ".." [Placeholder. Defaults to "..".]]
    `-- ret : [str]
```

</details>

<details>
<summary>📦 <b>my_web_api.py</b> の構造ツリーを表示</summary>

```text
common/utils/my_web_api.py:
+-- class: WebData # Web data class
+-- func: generate_wget_filename()
|   +-- arg : [base_name: str]
|   `-- ret : [Path]
+-- func: get_response() # Get response
|   +-- arg : [request_func: Callable [Request function]]
|   +-- arg : [request_url: str [Request URL]]
|   +-- arg : [local_file: str = ""]
|   +-- arg : [overwrite: bool = False [Overwrite. Defaults to False.]]
|   `-- ret : [dict]
+-- func: get_header() # Get header
|   +-- arg : [session: aiohttp.ClientSession [Session object]]
|   +-- arg : [request_url: str [Request URL]]
|   `-- ret : [dict]
`-- func: get_contents() # Get contents
    +-- arg : [session: aiohttp.ClientSession [Session object]]
    +-- arg : [request_url: str [Request URL]]
    +-- arg : [local_file: str = ""]
    +-- arg : [overwrite: bool = False [Overwrite. Defaults to False.]]
    `-- ret : [dict]
```

</details>

