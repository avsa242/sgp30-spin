# sgp30-spin 
------------

This is a P8X32A/Propeller, P2X8C4M64P/Propeller 2 driver object for the SGP30 Indoor Air Quality sensor.

**IMPORTANT**: This software is meant to be used with the [spin-standard-library](https://github.com/avsa242/spin-standard-library) (P8X32A) or [p2-spin-standard-library](https://github.com/avsa242/p2-spin-standard-library) (P2X8C4M64P). Please install the applicable library first before attempting to use this code, otherwise you will be missing several files required to build the project.

## Salient Features

* I2C connection at up to 400kHz (P1 PASM I2C engine, P2), ~28kHz (P1 bytecode I2C engine)
* Read TVOC (ppb) and CO2-eq (ppm)
* Read sensor serial number
* CRC performed on all data read from sensor

## Requirements

P1/SPIN1:
* spin-standard-library
* 1 extra core/cog for the PASM I2C engine (none if the bytecode I2C engine is used)

P2/SPIN2:
* p2-spin-standard-library

## Compiler Compatibility

| Processor | Language | Compiler               | Backend      | Status                |
|-----------|----------|------------------------|--------------|-----------------------|
| P1        | SPIN1    | FlexSpin (6.2.1)       | Bytecode     | OK                    |
| P1        | SPIN1    | FlexSpin (6.2.1)       | Native/PASM  | OK                    |
| P2        | SPIN2    | FlexSpin (6.2.1)       | NuCode       | Not yet implemented   |
| P2        | SPIN2    | FlexSpin (6.2.1)       | Native/PASM2 | Not yet implemented   |

(other versions or toolchains not listed are __not supported__, and _may or may not_ work)

## Limitations

* TBD

