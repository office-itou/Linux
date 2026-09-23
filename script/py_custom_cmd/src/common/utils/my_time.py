"""time wrapper (For both CUI/GUI)"""

# --- Python library ----------------------------------------------------------
import time

# --- my library --------------------------------------------------------------


class TimeElapsed:
    def __init__(self) -> None:
        self.start_time: float = time.perf_counter()
        self.end_time: float = 0.0
        self.elapsed_time: float = 0.0

    def elapsed(self) -> float:
        self.end_time = time.perf_counter()
        self.elapsed_time = self.end_time - self.start_time
        return self.elapsed_time


# -----------------------------------------------------------------------------
