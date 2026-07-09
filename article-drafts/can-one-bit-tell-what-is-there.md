# Can One Bit Tell What Is There?

## Status

Unpublished measurement protocol and article packet. No calibrated receiver-performance result is claimed here.

Do not turn this packet into public HTML, add it to the sitemap, or give it a publication date until the result tables are populated from preserved captures and the publication gate at the end is satisfied.

## Future Public Metadata

- HTML title: `Can One Bit Tell What Is There? One-Pin RF Receiver Measurements`
- H1: `Can One Bit Tell What Is There?`
- Slug: `can-one-bit-tell-what-is-there.html`
- Canonical URL: `https://greenforest.io/can-one-bit-tell-what-is-there.html`
- Description: `A measurement protocol for testing whether a thresholded one-pin FPGA receiver can distinguish a terminated input, CW, and modulated RF, with calibrated sensitivity, bandwidth, probability of detection, false-alarm rate, and blocker rejection.`
- Publication date: unset
- Result image: unset

## Result To Earn

> From the same thresholded RF pin, the receiver distinguishes no detected signal, CW, and modulated RF at a selected frequency—with stated bandwidth, sensitivity, probability of detection, false-alarm rate, and blocker rejection.

The eventual article must replace every field below with a measured value and confidence interval where applicable:

- Selected frequency: **TBD**
- Measurement bandwidth: **TBD Hz**
- Dwell time: **proposed 100 ms; freeze before test**
- Sensitivity criterion: **proposed 90% probability of detection at the frozen false-alarm threshold**
- False-alarm criterion: **proposed `P_FA = 10^-3`; freeze before test**
- Measured sensitivity: **TBD dBm at the defined reference plane**
- Measured occupied-channel or detector bandwidth: **TBD Hz**
- Adjacent-blocker rejection at each tested offset: **TBD dB**
- Classification accuracy and confusion matrix: **TBD**

The defensible absence statement is:

> No signal of the tested class was detected within **B Hz** of **f** during **T**. At or above **X dBm**, that class was detected with `P_D >= 0.90` at `P_FA = Y` per stated dwell and searched bin.

Never shorten that to “there is no signal at f.”

## Current Proof And Missing Boundary

The published receiver proves that threshold crossings can preserve enough phase and frequency structure to recover FM audio. The selected public source is:

- `one-pin-RF/fm_radio_demo_2026/fm_radio_nov15.sv`

The current public artifact does not yet establish:

- calibrated sensitivity;
- measured selectivity or bandwidth;
- absolute RF amplitude;
- probability of detection;
- false-alarm rate;
- adjacent-channel or out-of-band blocker rejection;
- a terminal decision among no detected signal, CW, and modulated RF.

This second article is about that missing receiver boundary, not another explanation of how FM audio was recovered.

## Why The Audio Output Is Ambiguous

Let the signed post-filter complex sample be:

```text
z[n] = I[n] + j Q[n]
```

The selected source computes the successive-vector cross product in this operand order:

```text
X[n] = I[n-1] Q[n] - Q[n-1] I[n]
     = |z[n]| |z[n-1]| sin(phi[n] - phi[n-1])
```

Reversing the operands changes only the output polarity.

For a centered CW, the baseband phase step is approximately zero, so `X[n]` is approximately zero. For no-signal zero-mean noise, the mean cross product is also approximately zero. An offset CW appears approximately as DC. FM produces a varying discriminator output.

The present terminal output is therefore useful for FM demodulation but insufficient for a calibrated carrier-present or signal-class decision. Different noise variance may remain audible, but no frozen detector statistic or threshold is exposed.

## Parallel Measurement Statistics

Add a measurement branch before the discriminator. For an `N`-sample window, compute or export enough data to compute:

```text
E = sum_n (I[n]^2 + Q[n]^2)
```

for channel energy, and:

```text
C(f) = | sum_n z[n] exp(-j 2 pi f n / F_s) |^2
```

for coherent energy at candidate baseband frequency `f`.

Also calculate:

- the peak coherent frequency estimate;
- normalized spectral concentration, for example `rho = max_f C(f) / (N E)` with the exact normalization frozen in the analysis code;
- fitted phase slope;
- residual phase variance after removing the fitted slope;
- sideband or residual spectral energy outside the fitted CW bin;
- raw input one-density;
- raw input transition count;
- discriminator mean, variance, and spectrum.

Candidate classification logic, to be calibrated and frozen rather than tuned on the final test set:

- **No detected signal:** energy and coherent statistics remain below their calibrated thresholds.
- **CW:** significant energy, high spectral concentration, and a stable phase slope with low residual phase variation.
- **Tested modulated RF class:** significant energy plus residual phase variation, sidebands, or a time-varying instantaneous-frequency estimate beyond the calibrated CW residual.

The final classifier may differ, but its features, thresholds, tie-breaking rules, searched bins, multiple-comparison correction, and unknown/reject state must be fixed before the held-out evaluation. A finite dwell cannot guarantee separation of arbitrary modulation from every possible CW; name each tested modulation class.

### Retune Test For Internal Spurs

Repeat each candidate carrier observation after retuning by `+delta` and `-delta`.

A genuine RF carrier must move in baseband by the corresponding signed amount, within frequency-estimation error. An internal DC spur stays at DC. A clock-related spur may follow a different, repeatable mapping. Record the mapping rather than deleting inconvenient responses.

## Predicted Digital Filter Response

These numbers are derived from the selected source. They are not measured receiver selectivity.

The processing clock is 21 MHz. `DECIMATOR_INIT` is 48; the accumulator runs through counter states 48 through 127, giving 80 integration clocks, followed by one transfer/reset clock at state 128.

```text
I/Q update rate = 21 MHz / 81 = 259.259259 kS/s
```

For the 80-sample rectangular integrate-and-dump window alone:

| Quantity | Predicted value |
| --- | ---: |
| One-sided -3 dB frequency | 116.28 kHz |
| First null | 262.5 kHz |
| Response at 200 kHz offset | -10.93 dB |
| First sidelobe | -13.26 dB |

The 259.259 kS/s output Nyquist frequency is 129.630 kHz. The rectangular window is already approximately -3.816 dB there, and responses outside that band alias into the output. The measured response must therefore include output-rate aliases.

Each window nominally combines 80 groups of 16 DDR threshold samples, or 1,280 threshold samples, with one 16-sample-group transfer/reset gap between windows.

Thresholding occurs before this filter. A strong off-channel signal can dominate and severely corrupt the input crossings before the digital filter sees the wanted signal. A one-tone sweep is therefore necessary but not sufficient; wanted-signal-plus-blocker testing is the decisive selectivity result.

## FPGA Capture Branch

Capture complete, signed measurement windows into on-chip BRAM or another quiet local store, then stop the acquisition before reading data out. Interface toggling must not occur during the RF observation window unless a control experiment proves that it does not contaminate the exposed input.

Capture at least:

- signed post-filter `I`;
- signed post-filter `Q`;
- raw input one count per window;
- raw input transition count per window;
- discriminator output;
- tune word and all clock/rate identifiers;
- acquisition start/stop markers;
- overflow and saturation flags.

The capture format needs a versioned header containing the bit widths, signedness, sample rate, window length, firmware commit, build identifier, tuned frequency, and board identifier. Preserve raw binary captures plus a documented decoder; CSV alone is not the source of truth.

Run a contamination control:

1. acquire with all external interfaces quiet and read out afterward;
2. acquire while the proposed interface is active;
3. compare raw density, transitions, `E`, `C(f)`, and spur spectra with a 50 ohm termination selected;
4. use the quiet post-acquisition readout unless the active-interface result is demonstrably equivalent.

## Conducted Fixture And Calibration

Build a conducted, shielded fixture with a documented 50 ohm reference plane. Use an RF switch to select either the calibrated generator path or a 50 ohm termination without moving cables.

For blocker tests, use two phase-independent generators or otherwise justify the source arrangement, with appropriate isolation, combining, attenuation, and protection. Measure the combined path rather than adding generator display levels arithmetically.

Record:

- generator make, model, serial number, reference status, and calibration date;
- attenuator, cable, switch, combiner, DC block, bias tee, and adapter identifiers;
- measured insertion loss versus frequency from each source to the reference plane;
- uncertainty of the delivered power;
- board, FPGA, bitstream, supply, enclosure, and temperature;
- termination return loss or its relevant specification;
- photographs and a fixture schematic showing the reference plane.

The RTL configures `SB_LVDS_INPUT` on the pin-4/pin-3 pair. Publish the actual voltage and bias network on both the RF-bearing pin and its companion input, including component values, measured common-mode voltage, differential RF voltage, protection, and the FPGA bank voltage.

The current iCE40 UltraPlus data sheet's differential-comparator table, at 2.5 V VCCIO, specifies a guaranteed HIGH region for `V_INP - V_INM >= +250 mV`, a guaranteed LOW region for `V_INP - V_INM <= -250 mV`, and a `V_INM` reference range from 0.25 V to `VCCIO - 0.25 V`. It does not specify an RF receiver sensitivity. Stay within all recommended operating and absolute-maximum conditions; do not reinterpret the digital comparator guarantee as a radio noise figure.

## Frozen Decision Criterion

Proposed starting criterion, to be confirmed before data collection:

- dwell: 100 ms;
- target false-alarm probability: `10^-3` per dwell and searched bin, with a declared correction if multiple bins are searched;
- sensitivity: lowest calibrated input power where the lower confidence bound for detection probability meets the chosen 90% criterion;
- held-out evaluation windows: disjoint from all windows used to choose thresholds, bins, normalizations, or classifier rules.

Threshold calibration and final evaluation must use separate captures. State the confidence-interval method, such as exact binomial Clopper-Pearson intervals, before testing.

For a `10^-3` false-alarm claim, use enough terminated-input windows to make the confidence interval meaningful. Three thousand zero-false-alarm trials only place the familiar approximate 95% “rule of three” upper bound near `10^-3`; substantially more trials are preferable for estimating rather than merely bounding the rate.

## Terminated-Input Calibration

With the RF switch on the 50 ohm termination:

1. collect windows across all intended dwell lengths;
2. repeat across board temperature, supply range, time, and relevant tune words;
3. record raw one-density and transition-count distributions;
4. record `E`, peak `C(f)`, concentration, phase-fit residual, and discriminator distributions;
5. locate persistent DC, clock, PLL, interface, and board-related spurs;
6. choose thresholds using calibration windows only;
7. lock the analysis version and threshold file;
8. evaluate false alarms on held-out terminated windows.

Do not silently notch a spur after observing the final test data. Any excluded bins must be justified and frozen during calibration.

## CW Frequency And Power Sweep

At each selected RF frequency and calibrated input power, run independent repeated dwells and record:

- trial count;
- detections;
- detection probability and confidence interval;
- false classifications;
- `E`, coherent peak, concentration, and saturation statistics;
- estimated baseband and RF frequency;
- frequency-estimation error;
- retune-test response;
- raw one-density and transition count.

Publish:

- detection probability versus dBm;
- every detector statistic versus dBm, including its floor and saturation region;
- the measured detector passband and sidelobes;
- a comparison with the predicted rectangular-window response;
- images, aliases, clock-related responses, and internal spurs;
- frequency-estimation error across frequency and input power.

Sensitivity is not a single floating number. It must be tied to RF frequency, bandwidth, dwell, detector rule, `P_D`, `P_FA`, fixture reference plane, and confidence interval.

## Wanted-Signal Plus Blocker Sweep

Hold the wanted signal near the measured sensitivity region and raise a second generator at both signs of at least these offsets:

- 200 kHz;
- 400 kHz;
- 1 MHz;
- wider offsets selected to expose images, aliases, PLL/clock relationships, and front-end responses.

At each point, report the calibrated wanted and blocker powers at the common reference plane and the path uncertainty.

Freeze the failure criterion before testing. Depending on the mode, failure may mean:

- wanted-signal detection probability falls below the criterion;
- classification changes from modulated RF to CW or no detected signal;
- estimated wanted frequency leaves tolerance;
- FM SINAD falls below the chosen threshold;
- the blocker captures the crossing stream or causes saturation.

Report the blocker level at failure and the wanted-to-blocker ratio. A clean one-tone response does not substitute for this result.

## FM SINAD, Distortion, And Deviation Linearity

Use a specified audio modulation frequency, pre-emphasis/de-emphasis condition, RF carrier frequency, and measurement bandwidth. Sweep input power and peak deviation. Publish recovered audio level, SINAD, THD or THD+N, and frequency error.

At the current I/Q update rate:

```text
F_s = 259.259259 kS/s
phase step at 75 kHz deviation = 2 pi 75 kHz / F_s = 1.8176 rad
```

The unnormalized cross product follows `sin(delta_phi)`. Its peak occurs at `delta_phi = pi/2`, corresponding here to approximately:

```text
F_s / 4 = 64.815 kHz
```

The current discriminator therefore compresses before 75 kHz peak deviation. The completed result needs one of:

- a higher post-filter I/Q rate;
- cross-plus-dot phase recovery, for example `atan2(cross, dot)` with defined wrap behavior;
- or an explicit measured deviation-linearity limit that keeps the current discriminator.

Do not infer linear FM output from intelligible audio alone.

## Absolute-Amplitude Boundary

For an ideal fixed midpoint threshold:

```text
sign(A cos(omega t)) = sign(cos(omega t)), A > 0
```

Absolute scale is absent. No later DSP can distinguish two noise-free sinusoids that differ only in amplitude.

Amplitude-related statistics become observable only when a known analog reference breaks the scale ambiguity: noise or dither, a nonzero threshold offset, hysteresis, or a swept threshold. Calibrated front-end gain can then refer that result back to the 50 ohm input plane. That can support calibrated detection sensitivity and relative-strength estimates; it does not make the fixed-threshold input an absolute RF voltmeter.

The eventual article may discuss published one-bit spectrum sensing, but it must preserve the assumptions. In one specific multi-antenna blind spectrum-sensing model with independent, zero-mean circular complex Gaussian signal and noise and sufficiently large sample counts, a one-bit Rao detector approaches roughly 2 dB low-SNR loss relative to its infinite-resolution counterpart. That supports low-SNR detectability under that model, not absolute RF metrology or a measured penalty for this FPGA receiver. Absolute volts or dBm here require the conducted calibration above or a deliberate threshold-sweep measurement mode.

## Empty Results Tables

### False-Alarm Calibration

| Tune frequency | Dwell | Calibration windows | Held-out windows | False alarms | `P_FA` estimate | Confidence interval | Threshold-set hash |
| --- | ---: | ---: | ---: | ---: | ---: | --- | --- |
| TBD | TBD | TBD | TBD | TBD | TBD | TBD | TBD |

### CW Detection And Sensitivity

| RF frequency | Input dBm | Trials | Detections | `P_D` | Confidence interval | Median `E` | Median peak `C` | Saturation rate |
| --- | ---: | ---: | ---: | ---: | --- | ---: | ---: | ---: |
| TBD | TBD | TBD | TBD | TBD | TBD | TBD | TBD | TBD |

### Classification Confusion Matrix

| Actual / reported | No detected signal | CW | Modulated RF | Unknown/reject |
| --- | ---: | ---: | ---: | ---: |
| 50 ohm termination | TBD | TBD | TBD | TBD |
| CW | TBD | TBD | TBD | TBD |
| Modulated RF | TBD | TBD | TBD | TBD |

### Frequency Response

| RF offset | Input dBm | `P_D` | Detector response dB | Estimated offset | Error | Image/alias/spur note |
| ---: | ---: | ---: | ---: | ---: | ---: | --- |
| TBD | TBD | TBD | TBD | TBD | TBD | TBD |

### Blocker Rejection

| Wanted dBm | Blocker offset | Blocker dBm at failure | Wanted/blocker ratio | Failure criterion | `P_D` or SINAD before | `P_D` or SINAD after |
| ---: | ---: | ---: | ---: | --- | ---: | ---: |
| TBD | TBD | TBD | TBD | TBD | TBD | TBD |

### FM Linearity

| RF input dBm | Audio frequency | Peak deviation | Recovered level | SINAD | THD/THD+N | Frequency error | Compression note |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| TBD | TBD | TBD | TBD | TBD | TBD | TBD | TBD |

## Reproduction Artifacts

The public result packet must contain or link:

- fixture schematic and photographs;
- calibration records and loss/uncertainty tables;
- FPGA source and exact commit;
- synthesis and place-and-route logs;
- capture-format specification and decoder;
- raw terminated, CW, modulated, and blocker captures;
- immutable calibration and held-out trial manifests;
- analysis source and locked dependencies;
- detector thresholds and hashes;
- generated tables and plots;
- a machine-readable result summary;
- known failures, excluded bins, saturation cases, and deviations from protocol.

## Primary References To Verify At Publication

- Lattice Semiconductor, [iCE40 UltraPlus Family Data Sheet v2.4](https://www.latticesemi.com/-/media/LatticeSemi/Documents/DataSheets/iCE/FPGA-DS-02008-2-4-iCE40-UltraPlus-Family-Data-Sheet.ashx?document_id=51968), especially the differential comparator electrical characteristics.
- Lattice Semiconductor, [FAQ 6161: iCE40 UltraPlus differential input pairs](https://www.latticesemi.com/en/Support/AnswerDatabase/6/1/6/6161), for automatic complementary-pin assignment and the qualification warning.
- P.-W. Wu, L. Huang, D. Ramirez, Y.-H. Xiao, and H. C. So, [One-Bit Spectrum Sensing for Cognitive Radio](https://doi.org/10.1109/TSP.2023.3343569), IEEE Transactions on Signal Processing 72, 549-564 (2024). Use its approximately 2 dB low-SNR result only with the paper's assumptions.
- U. S. Kamilov, A. Bourquard, A. Amini, and M. Unser, [One-Bit Measurements With Adaptive Thresholds](https://infoscience.epfl.ch/entities/publication/8beb7707-c8c7-4323-8b89-f8bcd4b05318), IEEE Signal Processing Letters 19(10), 607-610 (2012), DOI `10.1109/LSP.2012.2209640`.

## Publication Gate

Publish only after all of the following are true:

- [ ] The two-pin physical input and bias network are documented.
- [ ] The 50 ohm reference plane and path loss/uncertainty are calibrated.
- [ ] The FPGA capture branch is versioned and verified not to contaminate acquisition.
- [ ] The unresolved `n` identifier in the archived sample-shift ranges is corrected or defined, and a fresh clean build log is preserved.
- [ ] Raw captures and the decoder are preserved.
- [ ] Calibration and held-out evaluation data are separated.
- [ ] The detector and classifier rules are frozen and hashed.
- [ ] `P_FA`, `P_D`, dwell, bandwidth, and confidence intervals are populated.
- [ ] Sensitivity versus frequency is populated.
- [ ] Measured passband, sidelobes, images, aliases, and clock responses are populated.
- [ ] Wanted-plus-blocker results are populated at both positive and negative offsets.
- [ ] FM SINAD, distortion, and deviation linearity are populated.
- [ ] Every table above contains measured values or is explicitly removed with a stated reason.
- [ ] The final article distinguishes source-derived predictions from fixture measurements.
- [ ] The exact absence statement is supported by the reported data.
