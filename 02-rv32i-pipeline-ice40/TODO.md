# Integrating with RV32I Compliance Test

## Test halting

A test halt happens after an ecall instruction, jumping to the exception handler. 
To distinguish with ecall test, a0 (function argument) writes 0xbaad900d when halting

## Architecture modifications

Reset handler only
Exception handler must be modifiable via mtvec

