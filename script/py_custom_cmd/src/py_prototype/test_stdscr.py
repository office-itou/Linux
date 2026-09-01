import curses
from curses import wrapper

async def counter_task(stdscr):
    while True:
        infosystem.stdscr = stdscr
        infosystem.row, infosystem.columns = stdscr.getmaxyx()
        stdscr.refresh()
        await asyncio.sleep(1)

async def async_main(stdscr):
#   curses.curs_set(0)
#   stdscr.nodelay(True)
    stdscr.scrollok(True)
    stdscr.clear()
    stdscr.refresh()
    task = asyncio.create_task(counter_task(stdscr))
    try:
            stdscr.refresh()

def main(stdscr):
    asyncio.run(async_main(stdscr))

if __name__ == "__main__":
    curses.wrapper(main)
