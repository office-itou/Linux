#!/usr/bin/env python3
# encoding: utf-8

import asyncio
import concurrent.futures

def func1():
    print("func1() started")
    s = sum(i for i in range(10 ** 7))
    print("func1() finished")
    return s

def func2():
    print("func2() started")
    s = sum(i * i for i in range(10 ** 7))
    print("func2() finished")
    return s

async def main():
    loop = asyncio.get_running_loop()
    with concurrent.futures.ProcessPoolExecutor() as pool:
        task1 = loop.run_in_executor(pool, func1)
        task2 = loop.run_in_executor(pool, func2)
        result1 = await task1
        result2 = await task2
        print('result:', result1, result2)

asyncio.run(main())