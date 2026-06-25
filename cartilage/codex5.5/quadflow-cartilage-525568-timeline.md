# Cartilage/QuadFlow 525,568-Cycle Timeline

This video is a 20-frame timeline sampled from a successful lockstep browser-fabric run of the reconfigurable ripple-adder QFG proof.

Files:

- `quadflow-cartilage-525568-timeline.mp4` - 10-second H.264 video at 2 sampled states per second.
- `quadflow-cartilage-525568-timeline.gif` - small looping web preview from the same frames.
- `quadflow-cartilage-525568-timeline-contact.png` - all 20 sampled states on one sheet.

What it shows:

- A 64x64 Cartilage GLSL fabric driven by external lockstep edge I/O.
- 20 committed visual states sampled evenly from cycle 0 through cycle 525,568.
- The same run streamed 7,956 parsed QFG frame declarations and finished with 704 browser-side expectations passing.
- The final visible state is the committed result after the 2-bit -> 3-bit -> 2-bit reversible ripple-adder reconfiguration proof.

Important limitation:

The renderer-visible frames expose committed cell/body state, not every hidden in-flight configuration shift-register bit. Most intermediate samples therefore look identical even though the lockstep driver advanced through every fabric update and the boundary checks passed.
