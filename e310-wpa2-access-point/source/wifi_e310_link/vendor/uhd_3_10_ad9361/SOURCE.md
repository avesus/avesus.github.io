# Legacy AD9361 calibration driver

Unmodified files from Ettus UHD tag `release_003_010_001_001`, matching the
installed E310 library. Source directory:
https://github.com/EttusResearch/uhd/tree/release_003_010_001_001/host/lib/usrp/common/ad9361_driver

The six source/header files retain their upstream GPL-3.0-or-later notices.
They are used only by the separate native radio-setup executable. The AP
protocol implementation does not link this driver. No FPGA waveform tables
are generated from these RFIC calibration/filter tables.
