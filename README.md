# AXI4-Lite Subordinate Verification (UVM)

A UVM-based verification environment for an AXI4-Lite subordinate (slave) device with a 256-word memory-mapped register file. Built to verify both functional correctness and AXI4-Lite protocol compliance, with a deliberate fault-injection methodology used to validate the checkers themselves.

## DUT

`rtl/axi4lite_subordinate.sv` implements an AXI4-Lite subordinate with:
- 256 x 32-bit memory array, word-addressed
- Independent write FSM (`w_req -> w_dat -> w_res`) and read handshake logic
- Byte-strobe support (WSTRB) for partial-word writes

**Known limitation:** the write FSM only services a read request when it is idle (`write_state == w_req`). Reads and writes cannot be issued concurrently — this DUT does not support simultaneous outstanding read/write transactions, unlike a fully pipelined AXI4-Lite subordinate. This is a structural property of the design, not a bug, and is reflected in the FSM/condition coverage results below.

## Verification Environment

Standard UVM agent/env structure (`tb/`), driving and monitoring `axi4lite_if` per the AXI4-Lite protocol:

- **Sequence** (`axi4lite_sequence.sv`): generates 1000 transactions per run. ~50% are fresh word-aligned writes with random data and a weighted random strobe pattern (full word / upper half / lower half / single byte / fully random); ~50% are reads that reuse a previously-written address (tracked in a queue) to exercise read-after-write correctness. Random per-transaction handshake delays (`aw_w_delay`, `ar_r_delay`, `w_b_delay`) stress handshake timing.
- **Scoreboard** (`axi4lite_scoreboard.sv`): a shadow-memory reference model. Writes are checked against `BRESP`; reads are checked against the shadow model's expected data, updated with the same strobe-masking logic as the DUT.
- **Functional coverage** (`axi4lite_coverage.sv`): a `uvm_subscriber`-based model tracking 10 bins — write/read address range (low/mid/high) and write-strobe pattern (full word, upper half, lower half, single byte, other) — plus separate tracking of BRESP/RRESP response codes.
- **SVA protocol assertions** (`tb/assertions/axi4lite_assertions.sv`): 16 assertions bound non-intrusively to the DUT via `bind`, checking handshake ordering (VALID after its dependency), address alignment, signal stability (VALID must not drop before READY), per-channel handshake timeout (20-cycle bound), and WSTRB validity.

**Note on randomization:** without a full Questa constrained-random license, `rand`/`constraint` are not used (visible as commented-out in `axi4lite_seq_item.sv`). Randomization is done manually via `$urandom_range` inside the sequence body, with weighted `case` statements standing in for constraint-solver distributions.

## Results

**Baseline run** (1000 transactions, no faults injected): 0 `UVM_ERROR`, 0 `UVM_FATAL`.

| Metric | Result |
|---|---|
| Statement coverage | 100% (37/37) |
| Branch coverage | 100% (16/16) |
| FSM state coverage | 100% (3/3 states) |
| FSM transition coverage | 80% (4/5) |
| Assertion coverage | 81.25% (13/16) |
| Functional coverage (custom bins) | 100% (10/10) |
| Condition coverage | 46.15% (6/13) |
| Toggle coverage | 28.35% (19/67) |

**Fault-injection validation:** to confirm the scoreboard and assertions actually detect protocol/data violations rather than passively passing, the DUT and driver support `` `ifdef``-gated fault injection, each verified independently:

| Fault | Injection point | Result |
|---|---|---|
| `BUG_DATA_CORRUPTION` | DUT write path XORs stored data | 491/491 corrupted reads flagged as scoreboard MISMATCH, 0 false negatives |
| `BUG_PREMATURE_BVALID` | DUT asserts BVALID before AW/W complete | caught by `bvalid_needs_aw_w` assertion |
| `BUG_DISABLE_WDAT` | DUT skips the write-data memory update | caught by scoreboard read mismatch |
| `BUG_RVALID_UNSTABLE` | DUT drops RVALID before RREADY | caught by `r_valid_stable` assertion |
| `BUG_ADDR_NOT_ALIGNED` | sequence forces unaligned address | caught by `write_addr_aligned` / `read_addr_aligned` |
| `BUG_B_HANDSHAKE_TIMEOUT` / `BUG_R_HANDSHAKE_TIMEOUT` | driver withholds BREADY/RREADY indefinitely | caught by handshake timeout assertions |
| `RESET_TEST` | mid-simulation reset at randomized delay (10-40 cycles) | verifies FSM recovers cleanly from reset during an in-flight transaction |

Example from the `BUG_DATA_CORRUPTION` run — a corrupted read caught by the scoreboard:
```
UVM_ERROR .../axi4lite_scoreboard.sv(43) [SCOREBOARD] Read MISMATCH at addr=0x2c:
expected=0xc91929c8 got=0xc81828c9
```
(difference is exactly the injected `32'h01010101` XOR pattern, confirming the fault model behaved as intended)

## Known Limitations

- **No concurrent read/write**: as noted above, the DUT's FSM only accepts a read while idle on the write side. Verified behavior, not a gap.
- **Condition and toggle coverage are not 100%, and this is largely structural**: several uncovered condition terms correspond to FSM states the design cannot reach in certain combinations (e.g., `write_state == w_req` while also mid-handshake on another channel), and uncovered address-bit toggles (`write_addr[0:1]`, `write_addr[10:31]`) are architecturally always zero — the design only ever indexes a 10-bit range within a word-aligned 256-word memory, so these bits never toggle by construction.
- **The 3 uncovered assertions** (`aw_valid_stable`, `w_valid_stable`, `ar_valid_stable`) show 0 pass / 0 fail rather than a failure — their triggering precondition (VALID held high for a cycle while READY is still low) rarely occurs because the DUT's READY signals are asserted by default in the idle state, so handshakes typically complete same-cycle.
- **FSM transition `w_dat -> w_req`** is uncovered; every write observed in this run correctly passed through `w_res` before returning to `w_req`, so this transition may be structurally unreachable given the current FSM.
- Manual `$urandom_range`-based randomization (see note above) instead of constrained-random, due to license constraints.

## Repository Structure

```
rtl/            - DUT (axi4lite_subordinate.sv)
tb/
  agent/        - UVM agent
  assertions/   - SVA protocol checkers (bound to DUT)
  coverage/     - functional coverage subscriber
  driver/       - UVM driver
  env/          - UVM environment
  interface/    - axi4lite_if
  monitor/      - UVM monitor
  scoreboard/   - shadow-memory reference model checker
  seq_item/     - transaction item
  sequence/     - stimulus generation
  sequencer/    - UVM sequencer
  tests/        - test class(es)
  tb_uvm.sv     - UVM testbench top
  tb_direct.sv  - non-UVM direct testbench (early-stage)
sim/
  run.do        - Questa compile/sim/coverage script
```