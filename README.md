# Traffic Light Controller — VHDL

A simple traffic light controller written in VHDL, built as a learning project
while studying digital design and FPGA development. The design combines a
**finite state machine (FSM)** with a **tick counter**, and is verified with a
simulation testbench.

## Overview

The light cycles through three colors, each lasting a different number of
clock ticks:

| Color  | Duration |
|--------|----------|
| Red    | 5 ticks  |
| Green  | 4 ticks  |
| Yellow | 2 ticks  |

Sequence: **Red → Green → Yellow → Red → ...**

An asynchronous, active-high reset returns the light to **red** and restarts
the timing at any moment.

## Interface

| Port  | Direction | Description                              |
|-------|-----------|------------------------------------------|
| `CLK` | in        | System clock                             |
| `RST` | in        | Asynchronous reset, active high → red    |
| `R`   | out       | Red lamp (1 = on)                        |
| `G`   | out       | Green lamp (1 = on)                      |
| `Y`   | out       | Yellow lamp (1 = on)                     |

## Design

The circuit is split into two cooperating parts:

```
        ┌─────────────┐   TM (tick count)   ┌──────────────┐
        │     FSM     │◄────────────────────│ Tick counter │
        │  (colors)   │                     │   0 → 10     │
        └─────────────┘                     └──────────────┘
               │
               ▼
            R, G, Y
```

### 1. State machine (Moore)

Three states, one per color. Outputs depend only on the current state,
so this is a **Moore** machine.

| State | Color  | Next state | R | G | Y |
|-------|--------|------------|---|---|---|
| ST0   | Red    | ST1        | 1 | 0 | 0 |
| ST1   | Green  | ST2        | 0 | 1 | 0 |
| ST2   | Yellow | ST0        | 0 | 0 | 1 |

![State diagram](v2/diagram.png)
Note: the outputs inside the bubbles are written in **R, Y, G** order
(e.g. `001` = green, `010` = yellow).

On each arrow, `1` means "time is up, move to the next color" and `0` means
"stay in the current color".

### 2. Shared tick counter

Instead of restarting a counter for every color, a single counter `TM` runs
from 0 to 10 and wraps around. Each color owns a fixed range of counter values:

| TM value | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|----------|---|---|---|---|---|---|---|---|---|---|----|
| Color    | R | R | R | R | R | G | G | G | G | Y | Y  |

The FSM leaves a state when `TM` reaches the **last tick** of that color
(`TM = 4`, `8`, `10`). Because the state register and the counter update on
the **same clock edge**, the FSM and the counter always stay in sync: when
yellow ends, the counter wraps to 0 at the same moment the light turns red.

**Why the last tick and not the next one?** The next-state logic only
*plans* the transition; the state actually changes on the following clock
edge. Using `TM = 5` instead of `TM = 4` would make red last 6 ticks.

### Code structure

The architecture uses three processes, and each signal is driven by exactly
one of them:

| Process        | Type          | Drives   | Role                          |
|----------------|---------------|----------|-------------------------------|
| `sync_proc`    | Clocked       | `PS`     | State register                |
| `counter_proc` | Clocked       | `TM`     | Tick counter (0 → 10)         |
| `comb_proc`    | Combinational | `NS`, `R`, `G`, `Y` | Next state and outputs |

Both clocked processes follow the same pattern: asynchronous reset is checked
first, outside the clock edge, and all normal operation happens inside
`rising_edge(CLK)`.

## Simulation

The testbench:

1. Applies an initial reset
2. Lets the light run for more than one full cycle (11 ticks = 110 ns)
3. Asserts reset **while green is on** to check that the asynchronous reset
   immediately returns the light to red and the counter to 0
4. Runs another full cycle to confirm red lasts exactly 5 ticks after reset

![Waveform](v2/waveform.png)

The cursor at 95 ns shows a rising clock edge where `TM` goes from 8 to 9 and
the light switches from green to yellow in the same edge.

### Self-checking testbench

`traffic_light_tb_selfcheck.vhd` checks the light automatically with
`assert` statements instead of inspecting the waveform by eye. In the
middle of every clock tick it verifies that exactly one lamp is on and
that it is the expected color. Three full cycles are checked
(33 checks in total).

Passing run:

    tb.vhd:47:9:@340ns:(report note): Test finished

Running the same testbench against the buggy version (the leftover
`NS <= ST0;` line) catches the bug automatically, on every cycle:

    @110ns:(assertion error): Yellow should be on, TM = 10
    @220ns:(assertion error): Yellow should be on, TM = 10
    @330ns:(assertion error): Yellow should be on, TM = 10

### Run it yourself

**EDA Playground:** paste the design and testbench, select VHDL with GHDL,
set the top entity to `my_t_lmb_tb`, and enable *Open EPWave after run*.

**GHDL (locally):**

```bash
ghdl -a v2/traffic_light.vhd v2/traffic_light_tb.vhd
ghdl -e my_t_lmb_tb
ghdl -r my_t_lmb_tb --vcd=wave.vcd
gtkwave wave.vcd
```

## What I learned

- **Designing an FSM from a problem description**, not just translating a
  given state diagram into code.
- **FSM + datapath:** combining a state machine with a counter, where the
  counter provides the condition for state transitions.
- **One driver per signal:** a signal must be assigned by exactly one process.
- **Planning vs. happening:** `NS` is decided immediately, but `PS` only
  changes on the next clock edge.
- **Asynchronous vs. synchronous behavior:** reset acts immediately; counting
  and state changes wait for the clock edge.
- **Self-checking testbenches:** using `assert` so the testbench reports
  errors with the exact time and tick, instead of checking waveforms by eye.
### A bug I found through the waveform

In an earlier version, a leftover line from the previous design stayed in the
yellow state:

```vhdl
when ST2 =>
    if (TM = 10) then NS <= ST0;
    else              NS <= ST2;
    end if;
    NS <= ST0;   -- leftover line: always overrides the if above
```

In VHDL, the **last assignment** to a signal inside a process wins, so yellow
always lasted only 1 tick. The code compiled without any errors. The bug was
only visible in the waveform: yellow lasted 1 tick and the next red lasted
6 ticks, because the FSM and the counter fell out of sync. Removing the line
fixed both problems.

## Roadmap

- [x] **v1** — Basic three-state FSM, one color per clock tick
- [x] **v2** — Different duration per color using a tick counter
- [x] **v3** — Pedestrian button: request a pedestrian light on the next red
- [ ] **v4** — Self-checking testbench using `assert`
              (basic version done for v2; reference model and
              pedestrian safety check still to do)
- [ ] **v5** — Real-time seconds with a clock enable, countdown on a
              7-segment display, and deployment on an FPGA board

## Tools

- VHDL
- [EDA Playground](https://www.edaplayground.com/) with GHDL and EPWave