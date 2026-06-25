# Cartilage Fabric Lockstep Demo

- cycles: 525568
- drive mode: `qfg:logs/tmp-reconfigurable-ripple-2to3to2-preserveguard-d64.qfg`
- initial layout: `qfg-seed`
- source: `cartilage-grid-rs/examples/reconfigurable-ripple-2to3to2-preserveguard-d64-callouts.surface.qfg`
- annotation: `callouts`
- changed readouts after first tick: 525568
- input meaning: Streamed 7956 parsed QFG frame declarations from tmp-reconfigurable-ripple-2to3to2-preserveguard-d64.qfg through sparse boundary-metal transport. The selected host layout supplies 4096 explicit seed cell declaration before the stream begins.
- first output meaning: All observed boundary outputs were inactive.
- last output meaning: Observed active boundary output at right edge position 16, right edge position 34.
- proof scope: 704 browser expectations checked at QFG frame boundaries; all passed.
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
      "summary": "frame 1 edge right.sl[34] expected 0 observed 0"
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
      "summary": "frame 2 edge right.sl[34] expected 0 observed 0"
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
      "summary": "frame 3 edge right.sl[34] expected 0 observed 0"
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
      "summary": "frame 4 edge right.sl[34] expected 0 observed 0"
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
      "summary": "frame 5 edge right.sl[34] expected 0 observed 0"
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
      "summary": "frame 6 edge right.sl[34] expected 0 observed 0"
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
      "summary": "frame 7 edge right.sl[34] expected 0 observed 0"
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
      "summary": "frame 8 edge right.sl[34] expected 1 observed 1"
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
      "summary": "frame 9 edge right.sl[34] expected 0 observed 0"
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
      "summary": "frame 10 edge right.sl[34] expected 0 observed 0"
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
      "summary": "frame 11 edge right.sl[34] expected 1 observed 1"
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
      "summary": "frame 12 edge right.sl[34] expected 1 observed 1"
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
      "summary": "frame 13 edge right.sl[34] expected 0 observed 0"
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
      "summary": "frame 14 edge right.sl[34] expected 1 observed 1"
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
      "summary": "frame 15 edge right.sl[34] expected 1 observed 1"
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
      "summary": "frame 16 edge right.sl[34] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3947 cell 5,8 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3947 cell 15,12 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3947 cell 25,30 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3947 cell 25,44 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3947 edge left[8] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3947 edge right.sl[16] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3947 edge right.sl[34] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3947 edge right.sl[48] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3948 cell 5,8 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3948 cell 15,12 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3948 cell 25,30 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3948 cell 25,44 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3948 edge left[8] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3948 edge right.sl[16] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3948 edge right.sl[34] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3948 edge right.sl[48] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3949 cell 5,8 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3949 cell 15,12 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3949 cell 25,30 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3949 cell 25,44 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3949 edge left[8] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3949 edge right.sl[16] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3949 edge right.sl[34] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3949 edge right.sl[48] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3950 cell 5,8 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3950 cell 15,12 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3950 cell 25,30 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3950 cell 25,44 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3950 edge left[8] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3950 edge right.sl[16] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3950 edge right.sl[34] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3950 edge right.sl[48] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3951 cell 5,8 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3951 cell 15,12 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3951 cell 25,30 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3951 cell 25,44 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3951 edge left[8] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3951 edge right.sl[16] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3951 edge right.sl[34] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3951 edge right.sl[48] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3952 cell 5,8 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3952 cell 15,12 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3952 cell 25,30 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3952 cell 25,44 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3952 edge left[8] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3952 edge right.sl[16] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3952 edge right.sl[34] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3952 edge right.sl[48] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3953 cell 5,8 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3953 cell 15,12 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3953 cell 25,30 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3953 cell 25,44 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3953 edge left[8] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3953 edge right.sl[16] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3953 edge right.sl[34] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3953 edge right.sl[48] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3954 cell 5,8 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3954 cell 15,12 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3954 cell 25,30 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3954 cell 25,44 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3954 edge left[8] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3954 edge right.sl[16] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3954 edge right.sl[34] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3954 edge right.sl[48] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3955 cell 5,8 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3955 cell 15,12 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3955 cell 25,30 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3955 cell 25,44 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3955 edge left[8] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3955 edge right.sl[16] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3955 edge right.sl[34] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3955 edge right.sl[48] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3956 cell 5,8 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3956 cell 15,12 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3956 cell 25,30 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3956 cell 25,44 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3956 edge left[8] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3956 edge right.sl[16] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3956 edge right.sl[34] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3956 edge right.sl[48] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3957 cell 5,8 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3957 cell 15,12 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3957 cell 25,30 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3957 cell 25,44 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3957 edge left[8] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3957 edge right.sl[16] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3957 edge right.sl[34] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3957 edge right.sl[48] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3958 cell 5,8 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3958 cell 15,12 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3958 cell 25,30 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3958 cell 25,44 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3958 edge left[8] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3958 edge right.sl[16] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3958 edge right.sl[34] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3958 edge right.sl[48] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3959 cell 5,8 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3959 cell 15,12 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3959 cell 25,30 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3959 cell 25,44 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3959 edge left[8] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3959 edge right.sl[16] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3959 edge right.sl[34] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3959 edge right.sl[48] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3960 cell 5,8 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3960 cell 15,12 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3960 cell 25,30 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3960 cell 25,44 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3960 edge left[8] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3960 edge right.sl[16] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3960 edge right.sl[34] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3960 edge right.sl[48] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3961 cell 5,8 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3961 cell 15,12 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3961 cell 25,30 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3961 cell 25,44 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3961 edge left[8] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3961 edge right.sl[16] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3961 edge right.sl[34] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3961 edge right.sl[48] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3962 cell 5,8 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3962 cell 15,12 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3962 cell 25,30 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3962 cell 25,44 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3962 edge left[8] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3962 edge right.sl[16] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3962 edge right.sl[34] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3962 edge right.sl[48] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3963 cell 5,8 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3963 cell 15,12 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3963 cell 25,30 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3963 cell 25,44 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3963 edge left[8] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3963 edge right.sl[16] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3963 edge right.sl[34] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3963 edge right.sl[48] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3964 cell 5,8 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3964 cell 15,12 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3964 cell 25,30 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3964 cell 25,44 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3964 edge left[8] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3964 edge right.sl[16] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3964 edge right.sl[34] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3964 edge right.sl[48] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3965 cell 5,8 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3965 cell 15,12 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3965 cell 25,30 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3965 cell 25,44 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3965 edge left[8] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3965 edge right.sl[16] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3965 edge right.sl[34] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3965 edge right.sl[48] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3966 cell 5,8 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3966 cell 15,12 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3966 cell 25,30 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3966 cell 25,44 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3966 edge left[8] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3966 edge right.sl[16] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3966 edge right.sl[34] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3966 edge right.sl[48] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3967 cell 5,8 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3967 cell 15,12 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3967 cell 25,30 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3967 cell 25,44 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3967 edge left[8] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3967 edge right.sl[16] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3967 edge right.sl[34] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3967 edge right.sl[48] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3968 cell 5,8 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3968 cell 15,12 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3968 cell 25,30 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3968 cell 25,44 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3968 edge left[8] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3968 edge right.sl[16] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3968 edge right.sl[34] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3968 edge right.sl[48] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3969 cell 5,8 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3969 cell 15,12 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3969 cell 25,30 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3969 cell 25,44 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3969 edge left[8] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3969 edge right.sl[16] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3969 edge right.sl[34] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3969 edge right.sl[48] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3970 cell 5,8 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3970 cell 15,12 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3970 cell 25,30 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3970 cell 25,44 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3970 edge left[8] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3970 edge right.sl[16] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3970 edge right.sl[34] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3970 edge right.sl[48] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3971 cell 5,8 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3971 cell 15,12 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3971 cell 25,30 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3971 cell 25,44 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3971 edge left[8] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3971 edge right.sl[16] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3971 edge right.sl[34] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3971 edge right.sl[48] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3972 cell 5,8 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3972 cell 15,12 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3972 cell 25,30 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3972 cell 25,44 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3972 edge left[8] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3972 edge right.sl[16] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3972 edge right.sl[34] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3972 edge right.sl[48] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3973 cell 5,8 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3973 cell 15,12 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3973 cell 25,30 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3973 cell 25,44 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3973 edge left[8] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3973 edge right.sl[16] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3973 edge right.sl[34] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3973 edge right.sl[48] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3974 cell 5,8 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3974 cell 15,12 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3974 cell 25,30 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3974 cell 25,44 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3974 edge left[8] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3974 edge right.sl[16] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3974 edge right.sl[34] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3974 edge right.sl[48] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3975 cell 5,8 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3975 cell 15,12 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3975 cell 25,30 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3975 cell 25,44 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3975 edge left[8] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3975 edge right.sl[16] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3975 edge right.sl[34] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3975 edge right.sl[48] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3976 cell 5,8 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3976 cell 15,12 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3976 cell 25,30 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3976 cell 25,44 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3976 edge left[8] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3976 edge right.sl[16] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3976 edge right.sl[34] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3976 edge right.sl[48] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3977 cell 5,8 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3977 cell 15,12 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3977 cell 25,30 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3977 cell 25,44 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3977 edge left[8] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3977 edge right.sl[16] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3977 edge right.sl[34] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3977 edge right.sl[48] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3978 cell 5,8 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3978 cell 15,12 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3978 cell 25,30 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3978 cell 25,44 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3978 edge left[8] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3978 edge right.sl[16] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3978 edge right.sl[34] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3978 edge right.sl[48] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3979 cell 5,8 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3979 cell 15,12 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3979 cell 25,30 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3979 cell 25,44 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3979 edge left[8] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3979 edge right.sl[16] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3979 edge right.sl[34] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3979 edge right.sl[48] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3980 cell 5,8 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3980 cell 15,12 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3980 cell 25,30 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3980 cell 25,44 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3980 edge left[8] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3980 edge right.sl[16] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3980 edge right.sl[34] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3980 edge right.sl[48] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3981 cell 5,8 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3981 cell 15,12 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3981 cell 25,30 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3981 cell 25,44 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3981 edge left[8] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3981 edge right.sl[16] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3981 edge right.sl[34] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3981 edge right.sl[48] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3982 cell 5,8 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3982 cell 15,12 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3982 cell 25,30 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3982 cell 25,44 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3982 edge left[8] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3982 edge right.sl[16] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3982 edge right.sl[34] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3982 edge right.sl[48] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3983 cell 5,8 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3983 cell 15,12 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3983 cell 25,30 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3983 cell 25,44 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3983 edge left[8] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3983 edge right.sl[16] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3983 edge right.sl[34] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3983 edge right.sl[48] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3984 cell 5,8 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3984 cell 15,12 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3984 cell 25,30 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3984 cell 25,44 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3984 edge left[8] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3984 edge right.sl[16] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3984 edge right.sl[34] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3984 edge right.sl[48] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3985 cell 5,8 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3985 cell 15,12 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3985 cell 25,30 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3985 cell 25,44 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3985 edge left[8] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3985 edge right.sl[16] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3985 edge right.sl[34] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3985 edge right.sl[48] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3986 cell 5,8 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3986 cell 15,12 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3986 cell 25,30 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3986 cell 25,44 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3986 edge left[8] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3986 edge right.sl[16] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3986 edge right.sl[34] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3986 edge right.sl[48] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3987 cell 5,8 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3987 cell 15,12 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3987 cell 25,30 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3987 cell 25,44 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3987 edge left[8] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3987 edge right.sl[16] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3987 edge right.sl[34] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3987 edge right.sl[48] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3988 cell 5,8 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3988 cell 15,12 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3988 cell 25,30 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3988 cell 25,44 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3988 edge left[8] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3988 edge right.sl[16] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3988 edge right.sl[34] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3988 edge right.sl[48] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3989 cell 5,8 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3989 cell 15,12 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3989 cell 25,30 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3989 cell 25,44 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3989 edge left[8] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3989 edge right.sl[16] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3989 edge right.sl[34] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3989 edge right.sl[48] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3990 cell 5,8 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3990 cell 15,12 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3990 cell 25,30 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3990 cell 25,44 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3990 edge left[8] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3990 edge right.sl[16] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3990 edge right.sl[34] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3990 edge right.sl[48] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3991 cell 5,8 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3991 cell 15,12 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3991 cell 25,30 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3991 cell 25,44 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3991 edge left[8] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3991 edge right.sl[16] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3991 edge right.sl[34] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3991 edge right.sl[48] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3992 cell 5,8 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3992 cell 15,12 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3992 cell 25,30 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3992 cell 25,44 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3992 edge left[8] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3992 edge right.sl[16] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3992 edge right.sl[34] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3992 edge right.sl[48] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3993 cell 5,8 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3993 cell 15,12 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3993 cell 25,30 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3993 cell 25,44 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3993 edge left[8] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3993 edge right.sl[16] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3993 edge right.sl[34] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3993 edge right.sl[48] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3994 cell 5,8 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3994 cell 15,12 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3994 cell 25,30 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3994 cell 25,44 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3994 edge left[8] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3994 edge right.sl[16] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3994 edge right.sl[34] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3994 edge right.sl[48] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3995 cell 5,8 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3995 cell 15,12 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3995 cell 25,30 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3995 cell 25,44 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3995 edge left[8] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3995 edge right.sl[16] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3995 edge right.sl[34] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3995 edge right.sl[48] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3996 cell 5,8 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3996 cell 15,12 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3996 cell 25,30 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3996 cell 25,44 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3996 edge left[8] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3996 edge right.sl[16] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3996 edge right.sl[34] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3996 edge right.sl[48] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3997 cell 5,8 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3997 cell 15,12 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3997 cell 25,30 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3997 cell 25,44 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3997 edge left[8] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3997 edge right.sl[16] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3997 edge right.sl[34] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3997 edge right.sl[48] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3998 cell 5,8 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3998 cell 15,12 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3998 cell 25,30 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3998 cell 25,44 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3998 edge left[8] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3998 edge right.sl[16] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3998 edge right.sl[34] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3998 edge right.sl[48] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3999 cell 5,8 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3999 cell 15,12 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3999 cell 25,30 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 3999 cell 25,44 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 3999 edge left[8] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3999 edge right.sl[16] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 3999 edge right.sl[34] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 3999 edge right.sl[48] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 4000 cell 5,8 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 4000 cell 15,12 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 4000 cell 25,30 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 4000 cell 25,44 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 4000 edge left[8] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 4000 edge right.sl[16] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 4000 edge right.sl[34] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 4000 edge right.sl[48] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 4001 cell 5,8 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 4001 cell 15,12 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 4001 cell 25,30 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 4001 cell 25,44 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 4001 edge left[8] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 4001 edge right.sl[16] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 4001 edge right.sl[34] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 4001 edge right.sl[48] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 4002 cell 5,8 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 4002 cell 15,12 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 4002 cell 25,30 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 4002 cell 25,44 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 4002 edge left[8] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 4002 edge right.sl[16] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 4002 edge right.sl[34] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 4002 edge right.sl[48] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 4003 cell 5,8 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 4003 cell 15,12 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 4003 cell 25,30 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 4003 cell 25,44 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 4003 edge left[8] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 4003 edge right.sl[16] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 4003 edge right.sl[34] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 4003 edge right.sl[48] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 4004 cell 5,8 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 4004 cell 15,12 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 4004 cell 25,30 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 4004 cell 25,44 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 4004 edge left[8] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 4004 edge right.sl[16] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 4004 edge right.sl[34] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 4004 edge right.sl[48] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 4005 cell 5,8 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 4005 cell 15,12 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 4005 cell 25,30 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 4005 cell 25,44 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 4005 edge left[8] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 4005 edge right.sl[16] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 4005 edge right.sl[34] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 4005 edge right.sl[48] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 4006 cell 5,8 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 4006 cell 15,12 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 4006 cell 25,30 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 4006 cell 25,44 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 4006 edge left[8] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 4006 edge right.sl[16] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 4006 edge right.sl[34] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 4006 edge right.sl[48] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 4007 cell 5,8 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 4007 cell 15,12 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 4007 cell 25,30 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 4007 cell 25,44 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 4007 edge left[8] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 4007 edge right.sl[16] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 4007 edge right.sl[34] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 4007 edge right.sl[48] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 4008 cell 5,8 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 4008 cell 15,12 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 4008 cell 25,30 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 4008 cell 25,44 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 4008 edge left[8] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 4008 edge right.sl[16] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 4008 edge right.sl[34] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 4008 edge right.sl[48] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 4009 cell 5,8 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 4009 cell 15,12 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 4009 cell 25,30 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 4009 cell 25,44 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 4009 edge left[8] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 4009 edge right.sl[16] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 4009 edge right.sl[34] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 4009 edge right.sl[48] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 4010 cell 5,8 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 4010 cell 15,12 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 4010 cell 25,30 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 4010 cell 25,44 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 4010 edge left[8] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 4010 edge right.sl[16] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 4010 edge right.sl[34] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 4010 edge right.sl[48] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 7941 cell 5,8 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 7941 cell 15,12 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 7941 cell 15,26 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 7941 edge left[8] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 7941 edge right.sl[16] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 7941 edge right.sl[34] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 7942 cell 5,8 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 7942 cell 15,12 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 7942 cell 15,26 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 7942 edge left[8] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 7942 edge right.sl[16] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 7942 edge right.sl[34] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 7943 cell 5,8 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 7943 cell 15,12 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 7943 cell 15,26 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 7943 edge left[8] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 7943 edge right.sl[16] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 7943 edge right.sl[34] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 7944 cell 5,8 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 7944 cell 15,12 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 7944 cell 15,26 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 7944 edge left[8] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 7944 edge right.sl[16] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 7944 edge right.sl[34] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 7945 cell 5,8 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 7945 cell 15,12 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 7945 cell 15,26 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 7945 edge left[8] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 7945 edge right.sl[16] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 7945 edge right.sl[34] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 7946 cell 5,8 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 7946 cell 15,12 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 7946 cell 15,26 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 7946 edge left[8] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 7946 edge right.sl[16] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 7946 edge right.sl[34] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 7947 cell 5,8 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 7947 cell 15,12 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 7947 cell 15,26 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 7947 edge left[8] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 7947 edge right.sl[16] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 7947 edge right.sl[34] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 7948 cell 5,8 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 7948 cell 15,12 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 7948 cell 15,26 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 7948 edge left[8] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 7948 edge right.sl[16] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 7948 edge right.sl[34] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 7949 cell 5,8 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 7949 cell 15,12 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 7949 cell 15,26 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 7949 edge left[8] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 7949 edge right.sl[16] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 7949 edge right.sl[34] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 7950 cell 5,8 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 7950 cell 15,12 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 7950 cell 15,26 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 7950 edge left[8] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 7950 edge right.sl[16] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 7950 edge right.sl[34] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 7951 cell 5,8 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 7951 cell 15,12 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 7951 cell 15,26 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 7951 edge left[8] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 7951 edge right.sl[16] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 7951 edge right.sl[34] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 7952 cell 5,8 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 7952 cell 15,12 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 7952 cell 15,26 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 7952 edge left[8] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 7952 edge right.sl[16] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 7952 edge right.sl[34] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 7953 cell 5,8 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 7953 cell 15,12 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 7953 cell 15,26 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 7953 edge left[8] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 7953 edge right.sl[16] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 7953 edge right.sl[34] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 7954 cell 5,8 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 7954 cell 15,12 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 7954 cell 15,26 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 7954 edge left[8] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 7954 edge right.sl[16] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 7954 edge right.sl[34] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 7955 cell 5,8 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 7955 cell 15,12 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 7955 cell 15,26 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 7955 edge left[8] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 7955 edge right.sl[16] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 7955 edge right.sl[34] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 7956 cell 5,8 fields expected {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"} observed {\"right\":\"0\",\"left\":\"0\",\"top\":\"0\",\"bottom\":\"0\"}"
    },
    {
      "pass": true,
      "summary": "frame 7956 cell 15,12 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 7956 cell 15,26 fields expected {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"} observed {\"right\":\"1\",\"left\":\"1\",\"top\":\"1\",\"bottom\":\"1\"}"
    },
    {
      "pass": true,
      "summary": "frame 7956 edge left[8] expected 0 observed 0"
    },
    {
      "pass": true,
      "summary": "frame 7956 edge right.sl[16] expected 1 observed 1"
    },
    {
      "pass": true,
      "summary": "frame 7956 edge right.sl[34] expected 1 observed 1"
    }
  ],
  "probes": [],
  "captures": [
    {
      "index": 1,
      "cycle": 0,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\codex55-reconfigurable-ripple-exact-cycle-000000.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 4,
          "textureSide": 64,
          "marks": 8
        },
        "debugCells": [],
        "canvasWidth": 256,
        "canvasHeight": 256,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 2,
      "cycle": 27661,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\codex55-reconfigurable-ripple-exact-cycle-027661.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 4,
          "textureSide": 64,
          "marks": 8
        },
        "debugCells": [],
        "canvasWidth": 256,
        "canvasHeight": 256,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 3,
      "cycle": 55323,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\codex55-reconfigurable-ripple-exact-cycle-055323.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 4,
          "textureSide": 64,
          "marks": 8
        },
        "debugCells": [],
        "canvasWidth": 256,
        "canvasHeight": 256,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 4,
      "cycle": 82984,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\codex55-reconfigurable-ripple-exact-cycle-082984.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 4,
          "textureSide": 64,
          "marks": 8
        },
        "debugCells": [],
        "canvasWidth": 256,
        "canvasHeight": 256,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 5,
      "cycle": 110646,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\codex55-reconfigurable-ripple-exact-cycle-110646.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 4,
          "textureSide": 64,
          "marks": 8
        },
        "debugCells": [],
        "canvasWidth": 256,
        "canvasHeight": 256,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 6,
      "cycle": 138307,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\codex55-reconfigurable-ripple-exact-cycle-138307.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 4,
          "textureSide": 64,
          "marks": 8
        },
        "debugCells": [],
        "canvasWidth": 256,
        "canvasHeight": 256,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 7,
      "cycle": 165969,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\codex55-reconfigurable-ripple-exact-cycle-165969.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 4,
          "textureSide": 64,
          "marks": 8
        },
        "debugCells": [],
        "canvasWidth": 256,
        "canvasHeight": 256,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 8,
      "cycle": 193630,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\codex55-reconfigurable-ripple-exact-cycle-193630.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 4,
          "textureSide": 64,
          "marks": 8
        },
        "debugCells": [],
        "canvasWidth": 256,
        "canvasHeight": 256,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 9,
      "cycle": 221292,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\codex55-reconfigurable-ripple-exact-cycle-221292.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 4,
          "textureSide": 64,
          "marks": 8
        },
        "debugCells": [],
        "canvasWidth": 256,
        "canvasHeight": 256,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 10,
      "cycle": 248953,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\codex55-reconfigurable-ripple-exact-cycle-248953.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 4,
          "textureSide": 64,
          "marks": 8
        },
        "debugCells": [],
        "canvasWidth": 256,
        "canvasHeight": 256,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 11,
      "cycle": 276615,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\codex55-reconfigurable-ripple-exact-cycle-276615.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 4,
          "textureSide": 64,
          "marks": 8
        },
        "debugCells": [],
        "canvasWidth": 256,
        "canvasHeight": 256,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 12,
      "cycle": 304276,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\codex55-reconfigurable-ripple-exact-cycle-304276.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 4,
          "textureSide": 64,
          "marks": 8
        },
        "debugCells": [],
        "canvasWidth": 256,
        "canvasHeight": 256,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 13,
      "cycle": 331938,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\codex55-reconfigurable-ripple-exact-cycle-331938.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 4,
          "textureSide": 64,
          "marks": 8
        },
        "debugCells": [],
        "canvasWidth": 256,
        "canvasHeight": 256,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 14,
      "cycle": 359599,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\codex55-reconfigurable-ripple-exact-cycle-359599.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 4,
          "textureSide": 64,
          "marks": 8
        },
        "debugCells": [],
        "canvasWidth": 256,
        "canvasHeight": 256,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 15,
      "cycle": 387261,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\codex55-reconfigurable-ripple-exact-cycle-387261.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 4,
          "textureSide": 64,
          "marks": 8
        },
        "debugCells": [],
        "canvasWidth": 256,
        "canvasHeight": 256,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 16,
      "cycle": 414922,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\codex55-reconfigurable-ripple-exact-cycle-414922.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 4,
          "textureSide": 64,
          "marks": 8
        },
        "debugCells": [],
        "canvasWidth": 256,
        "canvasHeight": 256,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 17,
      "cycle": 442584,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\codex55-reconfigurable-ripple-exact-cycle-442584.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 4,
          "textureSide": 64,
          "marks": 8
        },
        "debugCells": [],
        "canvasWidth": 256,
        "canvasHeight": 256,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 18,
      "cycle": 470245,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\codex55-reconfigurable-ripple-exact-cycle-470245.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 4,
          "textureSide": 64,
          "marks": 8
        },
        "debugCells": [],
        "canvasWidth": 256,
        "canvasHeight": 256,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 19,
      "cycle": 497907,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\codex55-reconfigurable-ripple-exact-cycle-497907.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 4,
          "textureSide": 64,
          "marks": 8
        },
        "debugCells": [],
        "canvasWidth": 256,
        "canvasHeight": 256,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 20,
      "cycle": 525568,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\codex55-reconfigurable-ripple-exact-cycle-525568.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 4,
          "textureSide": 64,
          "marks": 8
        },
        "debugCells": [],
        "canvasWidth": 256,
        "canvasHeight": 256,
        "edgeSurface": "connected"
      }
    }
  ]
}
```
- exact frame recording:

```json
{
  "path": "C:\\Users\\apoll\\greenforest.io\\avesus.github.io\\cartilage\\codex5.5\\reconfigurable-ripple-2to3to2-preserveguard-d64-exact-525568.webm",
  "start": {
    "ok": true,
    "mimeType": "video/webm;codecs=vp9",
    "width": 256,
    "height": 256
  },
  "stop": {
    "ok": true,
    "frames": 525569,
    "mimeType": "video/webm;codecs=vp9",
    "chunks": 8090
  },
  "framePaceMs": 4,
  "bytes": 221326894
}
```
- screenshot: `C:\Users\apoll\2026_class_AI\cartilage-runtime\logs\cartilage-fabric-codex55-full-exact-qfg-tmp-reconfigurable-ripple-2to3to2-preserveguard-d64-reconfigurable-ripple-2to3to2-preserveguard-d64-callouts-callouts-525568.png`
- render metadata: `{"textureSide":64,"profile":"clean-16-explicit-edge-lockstep","annotation":{"enabled":true,"mode":"callouts","cellSize":4,"textureSide":64,"marks":8},"debugCells":[],"canvasWidth":256,"canvasHeight":256,"edgeSurface":"connected"}`

Raw edge readback, kept only for audit:

- first: `o L=0000000000000000000000000000000000000000000000000000000000000000 T=0000000000000000000000000000000000000000000000000000000000000000 R=0000000000000000000000...`
- last: `o L=0000000000000000000000000000000000000000000000000000000000000000 T=0000000000000000000000000000000000000000000000000000000000000000 R=0000000000000000100000...`

Timing used:

```text
for each external transaction:
  read current edge output
  submit exactly one fabric compute update
  next transaction observes the resulting committed state
```