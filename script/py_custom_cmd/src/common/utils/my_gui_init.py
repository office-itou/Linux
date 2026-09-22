
        # --- GUIモードへの切り替えとコールバック登録 -------------------------
        infosystem.is_gui = True
        infosystem.gui_error_callback = messagebox.showerror
        infosystem.gui_info_callback = messagebox.showinfo
        infosystem.debugout = True
        infosystem.log_window_active = True
        infosystem.columns = 120
        infosystem.rows = 40
        # ---------------------------------------------------------------------
        lang = detect_language()
        self.current_lang_strvar: tk.StringVar = tk.StringVar(value=lang)
