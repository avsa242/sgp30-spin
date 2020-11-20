{
    --------------------------------------------
    Filename: sensor.iaq.sgp30.i2c.spin
    Author: Jesse Burt
    Description: Driver for the Sensirion SGP30
        Indoor Air Quality sensor
    Copyright (c) 2020
    Started Nov 20, 2020
    Updated Nov 20, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    SLAVE_WR          = core#SLAVE_ADDR
    SLAVE_RD          = core#SLAVE_ADDR|1

    DEF_SCL           = 28
    DEF_SDA           = 29
    DEF_HZ            = 100_000
    I2C_MAX_FREQ      = core#I2C_MAX_FREQ

VAR


OBJ

    i2c : "com.i2c"                             'PASM I2C Driver
    core: "core.con.sgp30.spin"       'File containing your device's register set
    time: "time"                                'Basic timing functions
    crc : "math.crc"

PUB Null{}
''This is not a top-level object

PUB Start{}: okay
' Start using "standard" Propeller I2C pins and 100kHz
    okay := startx(DEF_SCL, DEF_SDA, DEF_HZ)

PUB Startx(SCL_PIN, SDA_PIN, I2C_HZ): okay
' Start using custom IO pins and I2C bus frequency
    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31)
        if I2C_HZ =< core#I2C_MAX_FREQ
            if okay := i2c.setupx(SCL_PIN, SDA_PIN, I2C_HZ)
                time.usleep(core#T_POR)
                if i2c.present(SLAVE_WR)        ' test device bus presence
                    return

    return FALSE                                ' something above failed

PUB Stop{}
' Put any other housekeeping code here required/recommended by your device before shutting down
    i2c.terminate{}

PUB Defaults{}
' Set factory defaults

PUB CO2Eq{}: ppm
' CO2/Carbon Dioxide equivalent concentration
'   Returns: parts-per-million (400..60_000)
    return iaqdata{} & $FFFF

PUB DeviceID{}: id
' Read device identification
    readreg(core#GET_FEATURES, 2, @id)

PUB IAQData{}: iaq | tmp[2]
' Read indoor air-quality data
'   Returns: TVOC | CO2 (MSW|LSW)
    readreg(core#MEAS_IAQ, 6, @tmp)
    iaq_adc.byte[0] := tmp.byte[4]    ' CO2
    iaq_adc.byte[1] := tmp.byte[5]
    iaq_adc.byte[2] := tmp.byte[1]    ' TVOC
    iaq_adc.byte[3] := tmp.byte[2]

PUB Reset{}
' Reset the device
    writereg(core#IAQ_INIT, 0, 0)

PUB SerialNum(ptr_buff)
' Read device Serial Number
'   NOTE: ptr_buff must be at least 6 bytes in length
    readreg(core#GET_SN, 6, ptr_buff)

PUB TVOC{}: ppb
' Total Volatile Organic Compounds concentration
'   Returns: parts-per-billion (0..60_000)
    return (iaqdata{} >> 16) & $FFFF

PRI readReg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt, tmp, wr_rd_dly
' Read nr_bytes from the device into ptr_buff
    case reg_nr                                 ' Basic register validation
        core#MEAS_IAQ:
        core#GET_IAQ_BASE:
        core#MEAS_TEST:
        core#GET_FEATURES:
        core#MEAS_RAW:
        core#GET_TVOC_INCBASE:
        core#GET_SN:
        other:
            return

    cmd_pkt.byte[0] := SLAVE_WR
    cmd_pkt.byte[1] := reg_nr.byte[1]
    cmd_pkt.byte[2] := reg_nr.byte[0]
    i2c.start{}
    i2c.wr_block(@cmd_pkt, 3)

    i2c.wait(SLAVE_RD)                          ' poll the sensor for readiness
    repeat tmp from nr_bytes-1 to 0
        byte[ptr_buff][tmp] := i2c.read(tmp == 0)
    i2c.stop{}

PRI writeReg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt[2], tmp
' Write nr_bytes to the device from ptr_buff
    case reg_nr                                 ' Basic register validation
        core#IAQ_INIT:
            cmd_pkt.byte[0] := SLAVE_WR
            cmd_pkt.byte[1] := reg_nr.byte[1]
            cmd_pkt.byte[2] := reg_nr.byte[0]
            i2c.start{}
            i2c.wr_block(@cmd_pkt, 3)
            repeat tmp from 0 to nr_bytes-1
                i2c.write(byte[ptr_buff][tmp])
            i2c.stop{}
        core#SET_IAQ_BASE, core#SET_ABS_HUM, core#SET_TVOC_BASE:
            cmd_pkt.byte[0] := SLAVE_WR
            cmd_pkt.byte[1] := reg_nr.byte[1]
            cmd_pkt.byte[2] := reg_nr.byte[0]
            i2c.start{}
            i2c.wr_block(@cmd_pkt, 3)
            repeat tmp from 0 to nr_bytes-1
                i2c.write(byte[ptr_buff][tmp])
            i2c.stop{}
        other:
            return


DAT
{
    --------------------------------------------------------------------------------------------------------
    TERMS OF USE: MIT License

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
    associated documentation files (the "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the
    following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial
    portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
    LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    --------------------------------------------------------------------------------------------------------
}
