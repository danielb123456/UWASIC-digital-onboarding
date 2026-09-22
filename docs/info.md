<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

This project implements an SPI-controlled PWM peripheral, receiving SCLK, COPI, and nCS signals from an SPI controller.

Each SPI transaction contains 16 bits:
- 1 read/write bit (only write transactions are supported, read ones are ignored)
- 7 address bits (the register address to write to)
- 8 data bits (the value to write to the register)

The bits are received through COPI using a shift register and are then decoded to update the right register.

Also, the following register map controls the output and PWM behavior:
- `0x00` = Enable outputs `uo_out[7:0]`
- `0x01` = Enable outputs `uio_out[7:0]`
- `0x02` = Enable PWM on `uo_out[7:0]`
- `0x03` = Enable PWM on `uio_out[7:0]`
- `0x04` = Set PWM duty cycle

## How to test

This project uses Cocotb tests. They can be executed by running the following command in the `test/` directory:

```bash
make -B
```

The actual tests are defined in test.py.

## External hardware

No external hardware is required.
