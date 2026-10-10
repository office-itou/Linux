"""main window build tables"""

# --- python library ----------------------------------------------------------
import tkinter as tk
from collections.abc import Callable
from tkinter import ttk
from typing import Any


# --- my library --------------------------------------------------------------
# ruff: isort: off
from common.shared import InfoCommon, InfoWebFile
from common.utils import debug_logger, safe_format


# --- main --------------------------------------------------------------------
class MainWindowTables:
    root: tk.Tk

    current_messages: dict[str, str]

    info_comm: InfoCommon
    info_webfile: InfoWebFile
    datas_map: dict[str, list[Any]]

    append_log: Callable
    refresh_exec_button_text: Callable
    #reload_table_data: Callable
    update_progress: Callable

    _main_frame:ttk.Frame
    ui_def: dict
    def _generate_center_tables(self) -> None:
        if not hasattr(self, "main_center_table_widgets"):
            self.main_center_table_widgets = {}
        # ---------------------------------------------------------------------
        parent_frame: ttk.Frame = self._main_frame
        for _table_data in self.ui_def.get("tables", []):
            _table_id = _table_data.get("table_id", "")
            _grid_info = _table_data.get("grid_layout", {})
            _table_container = ttk.Frame(parent_frame)
            _table_container.grid(
                row=_grid_info.get("row", 0),
                column=_grid_info.get("column", 0),
                rowspan=_grid_info.get("row_span", 1),
                columnspan=_grid_info.get("column_span", 1),
                padx=_grid_info.get("padx", 5),
                pady=_grid_info.get("pady", 5),
                sticky=_grid_info.get("sticky", "nsew"),
            )
            _table_container.columnconfigure(0, weight=1)
            _table_container.rowconfigure(1, weight=1)
            _table_container.rowconfigure(2, weight=0)
            # -----------------------------------------------------------------
            _lbl_key = _table_data.get("label_key", "")
            _lbl_text: float | str | None = self.current_messages.get(
                _lbl_key, _lbl_key
            )
            if _lbl_text:
                _lbl = ttk.Label(_table_container, text=_lbl_text, font=("", 9, "bold"))
                _lbl.grid(row=0, column=0, sticky="w", pady=(0, 5))
            # -----------------------------------------------------------------
            _cols = [_col["field"] for _col in _table_data.get("columns", [])]
            _tree = ttk.Treeview(_table_container, columns=_cols, show="headings")
            _tree.bind("<Button-1>", self._on_tree_click)
            # -----------------------------------------------------------------
            self.main_center_table_widgets[_table_id] = _tree
            # -----------------------------------------------------------------
            _even_bg = _table_data.get("even_bg", "#ffffff")
            _odd_bg = _table_data.get("odd_bg", "#ffffff")
            _updated_bg = _table_data.get("updated_bg", "#e0f2fe")
            _even_tag = f"{_table_id}_even"
            _odd_tag = f"{_table_id}_odd"
            _updated_tag = f"{_table_id}_updated"
            _tree.tag_configure(_even_tag, background=_even_bg)
            _tree.tag_configure(_odd_tag, background=_odd_bg)
            _tree.tag_configure(_updated_tag, background=_updated_bg)
            # -----------------------------------------------------------------
            for _col_info in _table_data.get("columns", []):
                _field = _col_info["field"]
                _width = (
                    _col_info["width"] + 8
                    if _col_info["width"] > 0
                    else _col_info["width"]
                )
                _anchor = _col_info["anchor"]
                _disp_name: str | None = self.current_messages.get(_field, _field)
                if _disp_name:
                    _tree.heading(_field, text=_disp_name)
                if _width > 0:
                    _tree.column(_field, width=_width, anchor=_anchor, stretch=False)
                else:
                    _tree.column(_field, anchor=_anchor, stretch=True)
            _tree.grid(row=1, column=0, sticky="nsew")
            # -----------------------------------------------------------------
            _v_scrollbar = ttk.Scrollbar(
                _table_container, orient=tk.VERTICAL, command=_tree.yview
            )
            _tree.configure(yscrollcommand=_v_scrollbar.set)
            _v_scrollbar.grid(row=1, column=1, sticky="ns")
            # -----------------------------------------------------------------
            _h_scrollbar = ttk.Scrollbar(
                _table_container, orient=tk.HORIZONTAL, command=_tree.xview
            )
            _tree.configure(xscrollcommand=_h_scrollbar.set)
            _h_scrollbar.grid(row=2, column=0, sticky="ew")
        # ---------------------------------------------------------------------
        if not hasattr(self, "datas_map"):
            self.datas_map = {}
        # ---------------------------------------------------------------------
        self.info_webfile = InfoWebFile(self)
        #self.datas_map["active_table"] = self.info_webfile.data
        # for _data in self.datas_map["active_table"]:
        #    _data.target_flag = _data.mdia_data.entry_flag == "o"
        self.datas_map["active_table"] = self.info_comm.mdia.data
        for _data in self.datas_map["active_table"]:
            _data.target_flag = "o" if _data.entry_flag == "o" else "x"
        # ---------------------------------------------------------------------
        self.reload_table_data()
        # --- style -----------------------------------------------------------
        # font.nametofont("TkDefaultFont")
        _style = ttk.Style()
        if _style.theme_use() != "clam":
            _style.theme_use("clam")
        _style.configure(
            "Treeview",
            rowheight=26,
            background="#ffffff",
            fieldbackground="#ffffff",
            borderwidth=1,
            lightcolor="#4b5563",
            darkcolor="#4b5563",
            borderColor="#4b5563",
        )
        _style.configure(
            "Treeview.Heading",
            background="#e5e7eb",
            lightcolor="#4b5563",
            darkcolor="#4b5563",
            relief="flat",
        )

    def _on_tree_click(self, event: tk.Event) -> None:
        _tree = event.widget
        if not isinstance(_tree, ttk.Treeview):
            return
        # ---------------------------------------------------------------------
        region = _tree.identify_region(event.x, event.y)
        if region != "cell":
            return
        # ---------------------------------------------------------------------
        column = _tree.identify_column(event.x)
        item_id = _tree.identify_row(event.y)
        if not item_id:
            return
        # ---------------------------------------------------------------------
        cols = _tree["columns"]
        col_idx = int(column.replace("#", "")) - 1
        col_name = cols[col_idx]
        # ---------------------------------------------------------------------
        if "target_flag" in col_name.lower():
            current_values = list(_tree.item(item_id, "values"))
            next_state = "☑" if current_values[col_idx] == "☐" else "☐"
            current_values[col_idx] = next_state
            _tree.item(item_id, values=current_values)
            # -----------------------------------------------------------------
            try:
                row_idx = int(item_id)
                main_center_table_widgets = getattr(
                    self, "main_center_table_widgets", {}
                )
                datas_map = getattr(self, "datas_map", {})
                for t_id, t_widget in main_center_table_widgets.items():
                    if t_widget == _tree:
                        target_data = datas_map.get(t_id, [])
                        if row_idx < len(target_data):
                            target_data[row_idx].target_flag = (
                                "o" if next_state == "☑" else "x"
                            )
                        break
            except Exception:  # noqa: BLE001, S110
                pass

    # -------------------------------------------------------------------------
    @debug_logger
    def reload_table_data(self) -> None:
        """A method to clear and reload only the table contents from the data model."""
        if not hasattr(self, "main_center_table_widgets"):
            return
        # ---------------------------------------------------------------------
        for _table_data in self.ui_def.get("tables", []):
            _table_id = _table_data.get("table_id", "")
            _tree = self.main_center_table_widgets.get(_table_id)
            if not _tree:
                continue
            # -----------------------------------------------------------------
            for _item in _tree.get_children():
                _tree.delete(_item)
            # -----------------------------------------------------------------
            _formats = {
                _col["field"]: _col.get("format")
                for _col in _table_data.get("columns", [])
            }
            _even_tag = f"{_table_id}_even"
            _odd_tag = f"{_table_id}_odd"
            # -----------------------------------------------------------------
            for _c_idx, _col_info in enumerate(_table_data.get("columns", [])):
                if "target_flag" in _col_info.get("field", "").lower():
                    break
            _visible_row_count = 0
            _target_list = self.datas_map.get(_table_id, [])
            for _row_index, _item_obj in enumerate(_target_list):
                _value = []
                if getattr(_item_obj, "entry_flag", "") == "o":
                    for _col_info in _table_data.get("columns", []):
                        _field = _col_info["field"]
                        _raw_value = getattr(_item_obj, _field, "")
                        # -----------------------------------------------------
                        if _field == "target_flag":
                            _raw_value = (
                                "☑"
                                if getattr(_item_obj, "target_flag", "x") == "o"
                                else "☐"
                            )
                        else:
                            _raw_value = _raw_value if _raw_value else "-"
                        # -----------------------------------------------------
                        _val_str = safe_format(_raw_value, _formats.get(_field))
                        _value.append(_val_str)
                # -------------------------------------------------------------
                if _value:
                    _row_tag = _even_tag if _visible_row_count % 2 == 0 else _odd_tag
                    _tree.insert(
                        "", "end", iid=str(_row_index), values=_value, tags=(_row_tag,)
                    )
                    _visible_row_count += 1
