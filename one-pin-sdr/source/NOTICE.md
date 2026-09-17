# Source notices

Receiver RTL, controller and host code: Brian Greenforest, MIT.
`bridge/ice_usb_buffered.c` derives from tinyVision.ai's MIT-licensed
`ice_usb.c`; its original copyright and license notice are preserved.
The bridge build fetches pico-ice-sdk at commit
`f3ddedcdabdbb929939720df0856f2f6b39962fc`, with its pinned SDK submodules.
Those dependencies retain their own licenses. Yosys, nextpnr, IceStorm,
NumPy, SciPy, Matplotlib, pyserial and dfu-util are external build/runtime tools.

The published WAV is byte-identical to the operator-reviewed recording.
Source packaging extracts the low-level USBIP class and tracking function;
it does not alter either algorithm. Build scripts use relative paths and run
the recorded pad-configuration patch after place and route. The two RTL tops,
UART RTL, constraints and included bitstreams are the actual bench versions.
The portable capture entry point is new release integration; the retained
recording replay is checked against the original audio bytes. It does not
claim a new physical capture with the release wrapper.

Packaging omits the unused host-overflow diagnostic and local installation-record
hooks. The portable wrapper checks device identity and line coding directly.
Wire encoding, stream cancellation, capture, decoding and DSP are unchanged.

Trailing spaces on blank RTL lines and in a bridge license-comment block
were removed for publication; logic and license text are unchanged.
