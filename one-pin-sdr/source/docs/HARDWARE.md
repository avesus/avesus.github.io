# Circuit and pin map

The circuit drawing describes the operating receiver used for the included
recording. Package pin numbers refer to the iCE40UP5K SG48, not RP2040 GPIOs or
arbitrary header positions. Follow the pico-ice schematic to locate headers.

| Node | Connection |
|---|---|
| RF input, FPGA pin 3 | Antenna through the existing series coupling capacitor;100kΩ to the measured 1.240V reference |
| V_REF, FPGA pin 4 | Positive terminal of 47µF capacitor; negative terminal to common ground |
| Reference supply |3.3V rail through 470Ω into the 1.240V shunt-reference node; reference returns to ground |
| Differential input | `SB_LVDS_INPUT` on logical port constrained to pin 4; its complementary input uses pin 3 |
| Bias actuator | Pin 4 low-only driver, short pulses; configured weak charging path to its rail |
| Audio pin 2 | High impedance throughout this recording |
| Clock | Board 12 MHz reference; nominal 204 MHz DDR sampler,25.5 MHz processing,102 MHz PSRAM |
| FPGA UART | TX25, RX27; wired to the board RP2040 bridge |
| PSRAM | DQ0/1/2/3=14/17/12/13; clock 15; select 37 |

The 100kΩ resistor biases the RF-bearing input from the fixed reference. It
does **not** join the two differential inputs. The 47µF node is controlled
separately. The reference component was measured at 1.240V; its exact part
number and the coupling-capacitor value were not recorded. Select an
appropriate shunt reference rather than assuming a generic diode is a 1.24V
reference. Nominal current through 470Ω is(3.3−1.24)/470=4.38 mA.

The signal generator is off and isolated. The ADC bus is disconnected from
V_REF for reception. The NodeMCU supplies the reference rail, with Wi-Fi off
and ADC acquisition paused. It is not part of the controller. There is no
external LNA in this recording. Common ground joins the reference, capacitor
and FPGA supply return.

## Charging and sinking

The implemented pin never drives high. Weak charging raises the capacitor;
one 25.5 MHz clock of low drive lowers it, no more frequently than every 128
clocks. The nominal pulse is 39.216 ns and the minimum start-to-start interval
is 5.020µs. The RTL default is disarmed, with output disabled.

Using the operator's approximate 40Ω output-resistance observation:

    I_initial = V/R ≈31 mA at 1.24V
    ΔQ ≈ I_initial ×39.216 ns ≈1.216 nC
    ΔV ≈ ΔQ/47µF ≈25.87µV

These equations estimate a step; they are not a guaranteed GPIO current
rating. The bench circuit directly connects a large capacitor to the pin.
An implementation intended for routine deployment should add a defined
current-limiting actuator path and verify peak current and ringing. That
revision changes the actuation coefficient and needs its own measurement.
Do not turn the illustrated short pulse into sustained output-low or drive
the charged capacitor high. Do not connect a charged external source without
matching voltages and controlling connection current.

`patch.py` reproduces the measured pin 4 weak-charging configuration by changing
two IceStorm tile fields after place/route. It is board/device-specific;
ordinary HDL pull-up assumptions on the complementary pin are insufficient.

Physical-board documentation: https://pico-ice.tinyvision.ai/
