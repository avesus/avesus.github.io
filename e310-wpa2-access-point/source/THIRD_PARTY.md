# Source boundaries

The Greenforest AP protocol, host waveform generator, packet transport,
receiver, serial arithmetic and fast-response logic are original source
released under the accompanying MIT license. The source layout preserves
relative includes from the running implementation; `wifi_pluto_link` is an
historical directory name, not a Pluto hardware dependency of the Windows build.

The E310 reference adapter also includes:

* `vendor_uhd_4_9/fpga/usrp3/lib/control/synchronizer*.v` and
  `vendor_uhd_4_9/fpga/usrp3/top/e31x/spi_slave.v`: Ettus UHD 4.9 FPGA source,
  LGPL-3.0-or-later. The upstream FPGA license is retained next to these files.
* `wifi_e310_link/vendor/uhd_3_10_ad9361`: six unmodified Ettus AD9361 calibration
  files from `release_003_010_001_001`, GPL-3.0-or-later. SOURCE.md gives the
  upstream location. These compile into the separate radio-setup program,
  not the Windows Wi-Fi protocol executable or the FPGA's waveform generator.
* Radio setup dynamically links the installed legacy UHD and Boost libraries.
  Distributing a linked radio-setup executable must satisfy their licenses,
  including the GPL requirements of the AD9361 driver. The source release does
  not include those executables, SDK runtime libraries or an SD-card image.
* The Windows protocol executable uses the Windows BCrypt API. The alternative
  non-Windows branch in `tools/wifi_protocol.cpp` uses OpenSSL; obtain OpenSSL
  under its own license when porting that branch.
* The E310 shell instantiates Xilinx 7-series/PS7 device primitives. Vivado and
  its simulation/device libraries are separate tools, not MIT source in this
  archive. Other FPGA families require their own I/O/clock/processor adapters.

Full GPLv3 and LGPLv3 texts accompany this release in `licenses/`. Retain
upstream notices. The MIT core is independent of the vendor calibration
adapter; another SDR can use its own RF setup path with the same core.
