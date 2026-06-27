# Cartilage Fabric Lockstep Demo

- cycles: 3072
- drive mode: `qfg:cartilage-grid-rs/examples/browser-static-ripple2-adder-edge.qfg`
- initial layout: `qfg-seed`
- annotation: `ripple2-adder-labels`
- changed readouts after first tick: 3072
- input meaning: Streamed 16 parsed QFG frame declarations from browser-static-ripple2-adder-edge.qfg through sparse boundary-metal transport. The selected host layout supplies 207 explicit seed cell declaration before the stream begins.
- first output meaning: All observed boundary outputs were inactive.
- last output meaning: Observed active boundary output at right edge position 16, right edge position 28.
- proof scope: 96 browser expectations checked at QFG frame boundaries; all passed.
- debug trace:

```json
{
  "expectations": [
    {
      "pass": true,
      "summary": "frame 1 cell 5,8 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 1 cell 15,12 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 1 cell 15,26 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 1 edge left[8] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 1 edge right.sl[16] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 1 edge right.sl[28] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 2 cell 5,8 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 2 cell 15,12 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 2 cell 15,26 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 2 edge left[8] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 2 edge right.sl[16] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 2 edge right.sl[28] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3 cell 5,8 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3 cell 15,12 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3 cell 15,26 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3 edge left[8] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3 edge right.sl[16] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3 edge right.sl[28] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 4 cell 5,8 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 4 cell 15,12 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 4 cell 15,26 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 4 edge left[8] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 4 edge right.sl[16] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 4 edge right.sl[28] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 5 cell 5,8 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 5 cell 15,12 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 5 cell 15,26 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 5 edge left[8] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 5 edge right.sl[16] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 5 edge right.sl[28] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 6 cell 5,8 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 6 cell 15,12 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 6 cell 15,26 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 6 edge left[8] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 6 edge right.sl[16] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 6 edge right.sl[28] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 7 cell 5,8 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 7 cell 15,12 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 7 cell 15,26 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 7 edge left[8] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 7 edge right.sl[16] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 7 edge right.sl[28] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 8 cell 5,8 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 8 cell 15,12 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 8 cell 15,26 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 8 edge left[8] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 8 edge right.sl[16] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 8 edge right.sl[28] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 9 cell 5,8 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 9 cell 15,12 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 9 cell 15,26 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 9 edge left[8] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 9 edge right.sl[16] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 9 edge right.sl[28] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 10 cell 5,8 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 10 cell 15,12 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 10 cell 15,26 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 10 edge left[8] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 10 edge right.sl[16] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 10 edge right.sl[28] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 11 cell 5,8 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 11 cell 15,12 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 11 cell 15,26 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 11 edge left[8] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 11 edge right.sl[16] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 11 edge right.sl[28] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 12 cell 5,8 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 12 cell 15,12 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 12 cell 15,26 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 12 edge left[8] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 12 edge right.sl[16] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 12 edge right.sl[28] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 13 cell 5,8 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 13 cell 15,12 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 13 cell 15,26 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 13 edge left[8] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 13 edge right.sl[16] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 13 edge right.sl[28] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 14 cell 5,8 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 14 cell 15,12 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 14 cell 15,26 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 14 edge left[8] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 14 edge right.sl[16] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 14 edge right.sl[28] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 15 cell 5,8 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 15 cell 15,12 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 15 cell 15,26 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 15 edge left[8] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 15 edge right.sl[16] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 15 edge right.sl[28] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 16 cell 5,8 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 16 cell 15,12 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 16 cell 15,26 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 16 edge left[8] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 16 edge right.sl[16] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 16 edge right.sl[28] expected 1 observed 1"
    }
  ],
  "probes": [],
  "captures": []
}
```
- screenshot: `cartilage-verified-ripple2-adder.png`
- render metadata: `{"textureSide":32,"renderZoom":96,"profile":"clean-16-explicit-edge-lockstep","annotation":{"enabled":true,"mode":"ripple2-adder-labels","cellSize":96,"textureSide":32,"labels":14,"labelBox":{"widthCells":1.75,"heightCells":0.9}},"debugCells":[],"canvasWidth":3072,"canvasHeight":3072,"edgeSurface":"connected"}`

Raw edge readback, kept only for audit:

- first: `o L=00000000000000000000000000000000 T=00000000000000000000000000000000 R=00000000000000000000000000000000 B=00000000000000000000000000000000`
- last: `o L=00000000000000000000000000000000 T=00000000000000000000000000000000 R=00000000000000001000000000001000 B=00000000000000000000000000000000`

Timing used:

```text
for each external transaction:
  read current edge output
  submit exactly one fabric compute update
  next transaction observes the resulting committed state
```
