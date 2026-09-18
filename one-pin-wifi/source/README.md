# Wi-Fi through one FPGA input

Brian Greenforest, September 17, 2026.

A physical 1 Mb/s 802.11b beacon was received through a moRFeus downconverter
and one pico-ice iCE40UP5K differential input, with autonomous FPGA bias and
no external LNA. The 129-byte frame passes FCS32; all 512 known test bits match.
The PHY header CRC16 also passed during demodulation.

## Reproduce the public packet checks and PNG

From the extracted package directory:

```sh
python -m pip install -r source/requirements.txt
python source/verify_packet.py
python source/plot.py
```

`data/received-beacon.bin` is the exact MAC frame, including FCS and the
operator's own ESP8266 addresses, published with explicit permission.
`received-plcp.bin` holds the exact six-byte PHY header, including CRC16.
`received-beacon.txt` annotates its fields. The PCAP contains identical bytes
with a nine-byte radiotap wrapper that marks FCS-present. Its timestamp is
zero, a container convention, not the physical reception time.

The plotted test field is neutral deterministic transmitter data, compared
with actual received bits. The plot does not use fitted or repaired bits.
`spectrum.csv` contains 4,096 frequency groups derived from the original
Hann-windowed full-record FFT, preserving both mean and peak power per group.
`barker.csv` contains actual despread magnitudes. Neither is synthetic RF.
Levels are comparator-relative; the clock and frequencies are nominal.

## Replay a raw acquisition

```sh
python source/receive.py your-capture.bin --if-mhz 67 --output decoded
```

The published decoder was executed against the unchanged original R1 record
and recovered frame SHA-256
`a95cc5cb3ecdb9b97f1168708d2981d12f04185c02ca8077f583582e80f25a63`.
The raw wideband R1 input is not included in this package; the complete
decoded packet, public plot data and original input hash are included.
No expected SSID or test bytes participate in demodulation decisions.
`--write-private-frame` additionally writes the recovered frame to disk;
the legacy option name does not alter or redact its bytes.

R1 format: 131,090 bytes; 16-byte header with `R1` at offsets 2–3;
131,072 data bytes interpreted as little-endian 16-bit words, each unpacked
most-significant bit first; final two-byte little-endian sum of all prior
bytes modulo 65,536. This is 1,048,576 decisions at nominal 408 Mdecision/s.

Host processing: 24 MHz complex IF extraction with cosine skirts; 2 us edge
guards; 44 MS/s numerical resampling; eleven-chip Barker despreading;
symbol timing search; squared-symbol coherent BPSK carrier recovery;
differential decisions; self-synchronizing descrambling; SFD, PLCP CRC16,
length and two independent CRC32 checks. There is no bit repair.

## Hardware and existing FPGA source

- Wi-Fi channel 6: 2,437 MHz. moRFeus LO: 2,370 MHz. IF: 67 MHz.
- Mixer current setting: 1; bias tee off. Receive antenna about 5 cm from ESP.
- Nominal 204 MHz DDR acquisition: 408 Mdecision/s, DC–204 MHz first zone.
- RF pad: package pin 3, AC-coupled and biased via 100 kOhm from 1.240 V.
- Reference pad: package pin 4 and 47 uF capacitor; FPGA density feedback.
- Target ones fraction: 0.64990234375. Actual record: 0.6440954208374023.
- Generator off; audio output high impedance; no external LNA; no ADC feedback.

The exact already-published FPGA image, Verilog, controller and build scripts:
https://greenforest.io/one-pin-sdr/one-pin-sdr-2026-09-17.zip

Hardware and current-limited actuator considerations:
https://greenforest.io/one-pin-sdr/source/docs/HARDWARE.md

The existing E310 Wi-Fi implementation:
https://greenforest.io/e310-wpa2-access-point/

This result used a new host physical decoder and reused the established
MAC parser; it did not replace the E310 PHY with the complete one-pin chain.
One intact frame came from four separate 2.570 ms records at this setting.
Three successful carrier-window replays of the same frame are one reception.

The new source is under `LICENSE` (MIT). Packet data, diagrams and measurement
arrays are supplied for inspection and reproduction. `SHA256SUMS` at the
package root identifies every included file except that manifest itself.
