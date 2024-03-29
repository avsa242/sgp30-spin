{
    --------------------------------------------
    Filename: sensor.iaq.sgp30.spin
    Author: Jesse Burt
    Description: Driver for the Sensirion SGP30
        Indoor Air Quality sensor
    Copyright (c) 2023
    Started Nov 20, 2020
    Updated Jul 15, 2023
    See end of file for terms of use.
    --------------------------------------------
}

CON

    SLAVE_WR    = core#SLAVE_ADDR
    SLAVE_RD    = core#SLAVE_ADDR|1

    DEF_SCL     = 28
    DEF_SDA     = 29
    DEF_HZ      = 100_000
    DEF_ADDR    = 0
    I2C_MAX_FREQ= core#I2C_MAX_FREQ

    { default I/O settings; these can be overridden in the parent object }
    SCL         = DEF_SCL
    SDA         = DEF_SDA
    I2C_FREQ    = DEF_HZ
    I2C_ADDR    = DEF_ADDR

OBJ

{ decide: Bytecode I2C engine, or PASM? Default is PASM if BC isn't specified }
#ifdef SGP30_I2C_BC
    i2c : "com.i2c.nocog"                       ' BC I2C engine
#else
    i2c : "com.i2c"                             ' PASM I2C engine
#endif
    core: "core.con.sgp30"                      ' HW-specific constants
    time: "time"                                ' timekeeping methods
    crc : "math.crc"                            ' CRC routines

PUB null{}
' This is not a top-level object

PUB start{}: status
' Start using default I/O settings
    return startx(SCL, SDA, I2C_FREQ)

PUB startx(SCL_PIN, SDA_PIN, I2C_HZ): status
' Start using custom IO pins and I2C bus frequency
    if ( lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31) )
        if ( status := i2c.init(SCL_PIN, SDA_PIN, I2C_HZ) )
            time.usleep(core#T_POR)             ' wait for device startup
            if ( i2c.present(SLAVE_WR) )        ' test device bus presence
                return
    ' if this point is reached, something above failed
    ' Re-check I/O pin assignments, bus speed, connections, power
    ' Lastly - make sure you have at least one free core/cog
    return FALSE

PUB stop{}
' Stop the driver
    i2c.deinit{}

PUB defaults{}
' Set factory defaults
    reset{}

PUB co2_equiv{}: ppm
' CO2/Carbon Dioxide equivalent concentration, in parts-per-million/ppm
'   Returns:
'       u16: 400..60_000
'       or -1, if data failed CRC check
    ppm := 0
    if (readreg(core#MEAS_IAQ, 2, @ppm) == 0)
        return (ppm & $FFFF)
    else
        return -1

PUB dev_id{}: id
' Read device identification
    readreg(core#GET_FEATURES, 2, @id)

PUB iaq_data{}: adc
' Indoor air-quality data ADC words
'   Returns: [31..16]: TVOC, [15..0]: CO2
    readreg(core#MEAS_RAW, 4, @adc)

PUB reset{}
' Reset the device
' NOTE: There is a delay of approximately 15 seconds after calling this method, during which
'       co2_equiv() will return 400ppm and tvoc() will return 0ppb
    writereg(core#IAQ_INIT, 0, 0)

PUB serial_num(ptr_buff): status
' Read device Serial Number
' NOTE: ptr_buff must be at least 6 bytes in length
' Returns:
'    0: success
'   -1: data failed CRC (data copied to buffer should not be trusted in this case)
    if (readreg(core#GET_SN, 6, ptr_buff) == 0)
        return
    else
        return -1

PUB tvoc{}: ppb
' Total Volatile Organic Compounds concentration, in parts-per-billion/ppb
' Returns:
'   u16 (0..60_000)
'   or -1, if data failed CRC
    ppb := 0
    if (readreg(core#MEAS_IAQ, 2, @ppb) == 0)
        return ((ppb >> 16) & $FFFF)
    else
        return -1

PRI readreg(reg_nr, nr_bytes, ptr_buff): status | cmd_pkt, tmp, crcrd, rdcnt
' Read nr_bytes from the device into ptr_buff
    cmd_pkt.byte[0] := SLAVE_WR                 ' form command packet
    cmd_pkt.byte[1] := reg_nr.byte[1]
    cmd_pkt.byte[2] := reg_nr.byte[0]

    case reg_nr                                 ' validate command
        core#MEAS_IAQ, core#GET_IAQ_BASE, core#MEAS_RAW:
            i2c.start{}
            i2c.wrblock_lsbf(@cmd_pkt, 3)
            i2c.wait(SLAVE_RD)                  ' poll the sensor for readiness

            rdcnt := 0
            status := 0
            repeat 2
                tmp := i2c.rdword_msbf(i2c#ACK)
                crcrd := i2c.rd_byte(rdcnt == 1)' read CRC; NAK if last byte
                if (crcrd == crc.sensirion_crc8(@tmp, 2))
                    word[ptr_buff][rdcnt++] := tmp
                    next
                else
                    status := -1                ' CRC error
                    quit
            i2c.stop{}
            return status
        core#MEAS_TEST, core#GET_FEATURES, core#GET_TVOC_INCBASE:
            i2c.start{}
            i2c.wrblock_lsbf(@cmd_pkt, 3)
            i2c.wait(SLAVE_RD)

            tmp := i2c.rdword_msbf(i2c#ACK)
            crcrd := i2c.rd_byte(i2c#NAK)
            status := 0
            if (crcrd == crc.sensirion_crc8(@tmp, 2))
                word[ptr_buff][0] := tmp
            else
                status := -1
            i2c.stop{}
            return status
        core#GET_SN:
            i2c.start{}
            i2c.wrblock_lsbf(@cmd_pkt, 3)
            time.usleep(core#T_GET_SN)
            i2c.wait(SLAVE_RD)

            rdcnt := 0
            status := 0
            repeat 3
                tmp := i2c.rdword_msbf(i2c#ACK)
                crcrd := i2c.rd_byte(rdcnt == 2)' read CRC; NAK if last byte
                if (crcrd == crc.sensirion_crc8(@tmp, 2))
                    word[ptr_buff][rdcnt++] := tmp
                    next
                else
                    status := -1                ' CRC error
                    quit
            i2c.stop{}
            return status
        other:
            return

PRI writereg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt[2], tmp
' Write nr_bytes to the device from ptr_buff
    case reg_nr
        core#IAQ_INIT:
            cmd_pkt.byte[0] := SLAVE_WR
            cmd_pkt.byte[1] := reg_nr.byte[1]
            cmd_pkt.byte[2] := reg_nr.byte[0]
            i2c.start{}
            i2c.wrblock_lsbf(@cmd_pkt, 3)
            i2c.stop{}
        core#SET_IAQ_BASE, core#SET_ABS_HUM, core#SET_TVOC_BASE:
            cmd_pkt.byte[0] := SLAVE_WR
            cmd_pkt.byte[1] := reg_nr.byte[1]
            cmd_pkt.byte[2] := reg_nr.byte[0]
            i2c.start{}
            i2c.wrblock_lsbf(@cmd_pkt, 3)
            i2c.wrblock_lsbf(ptr_buff, nr_bytes)
            i2c.stop{}
        other:
            return

DAT
{
Copyright 2023 Jesse Burt

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
}

