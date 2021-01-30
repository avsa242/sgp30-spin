# sgp30-spin 
------------

This is a P8X32A/Propeller, ~~P2X8C4M64P/Propeller 2~~ driver object for the SGP30 Indoor Air Quality sensor.

**IMPORTANT**: This software is meant to be used with the [spin-standard-library](https://github.com/avsa242/spin-standard-library) (P8X32A) ~~or [p2-spin-standard-library](https://github.com/avsa242/p2-spin-standard-library) (P2X8C4M64P)~~. Please install the applicable library first before attempting to use this code, otherwise you will be missing several files required to build the project.

## Salient Features

* I2C connection at up to 400kHz
* Read TVOC (ppb) and CO2-eq (ppm)
* Read sensor serial number

## Requirements

P1/SPIN1:
* spin-standard-library

~~P2/SPIN2:~~
* ~~p2-spin-standard-library~~

## Compiler Compatibility

* P1/SPIN1: OpenSpin (tested with 1.00.81)
* ~~P2/SPIN2: FlexSpin (tested with 5.0.0)~~ _(not yet implemented)_
* ~~BST~~ (incompatible - no preprocessor)
* ~~Propeller Tool~~ (incompatible - no preprocessor)
* ~~PNut~~ (incompatible - no preprocessor)

## Limitations

* Very early in development - may malfunction, or outright fail to build
* Doesn't verify data returned from sensor using CRC

## TODO

- [ ] Add support for CRC verification of sensor data
- [ ] Add support for setting abs. humidity value
- [ ] Add support for setting IAQ and TVOC baselines
- [ ] Port to P2/SPIN2
