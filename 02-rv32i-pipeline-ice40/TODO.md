# Integrating with RV32I Compliance Test

## Test halting

Communication between simulator and program is done through IO port 0x80000000

- 0 -- Initiate memory scan
- 1 -- Test pass
- 2 -- Test fail
- 3 -- Test halt

## Architecture modifications

[X] Reset handler only
[X] Exception handler must be modifiable via mtvec
[X] Writable mstatus register

## Prepare for Zephyr
[ ] Port to Zephyr toolchain
[ ] Port Zephyr OS

