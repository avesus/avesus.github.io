# Cartilage Fabric Lockstep Demo

- cycles: 256
- drive mode: `qfg:logs/use-static3-a6-b5.qfg`
- initial layout: `qfg-seed`
- source: `cartilage-grid-rs/examples/use-static3-a6-b5-callouts.surface.qfg`
- annotation: `callouts`
- changed readouts after first tick: 256
- input meaning: Streamed 1 parsed QFG frame declarations from use-static3-a6-b5.qfg through sparse boundary-metal transport. The selected host layout supplies 469 explicit seed cell declaration before the stream begins.
- first output meaning: All observed boundary outputs were inactive.
- last output meaning: Observed active boundary output at left edge position 8, right edge position 16, right edge position 48.
- proof scope: 0 browser expectations checked at QFG frame boundaries; all passed.
- debug trace:

```json
{
  "expectations": [],
  "probes": [],
  "captures": [
    {
      "index": 1,
      "cycle": 0,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000000.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 2,
      "cycle": 1,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000001.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 3,
      "cycle": 2,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000002.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 4,
      "cycle": 3,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000003.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 5,
      "cycle": 4,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000004.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 6,
      "cycle": 5,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000005.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 7,
      "cycle": 6,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000006.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 8,
      "cycle": 7,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000007.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 9,
      "cycle": 8,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000008.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 10,
      "cycle": 9,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000009.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 11,
      "cycle": 10,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000010.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 12,
      "cycle": 11,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000011.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 13,
      "cycle": 12,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000012.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 14,
      "cycle": 13,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000013.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 15,
      "cycle": 14,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000014.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 16,
      "cycle": 15,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000015.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 17,
      "cycle": 16,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000016.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 18,
      "cycle": 17,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000017.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 19,
      "cycle": 18,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000018.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 20,
      "cycle": 19,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000019.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 21,
      "cycle": 20,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000020.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 22,
      "cycle": 21,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000021.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 23,
      "cycle": 22,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000022.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 24,
      "cycle": 23,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000023.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 25,
      "cycle": 24,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000024.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 26,
      "cycle": 25,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000025.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 27,
      "cycle": 26,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000026.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 28,
      "cycle": 27,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000027.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 29,
      "cycle": 28,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000028.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 30,
      "cycle": 29,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000029.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 31,
      "cycle": 30,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000030.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 32,
      "cycle": 31,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000031.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 33,
      "cycle": 32,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000032.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 34,
      "cycle": 33,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000033.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 35,
      "cycle": 34,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000034.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 36,
      "cycle": 35,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000035.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 37,
      "cycle": 36,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000036.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 38,
      "cycle": 37,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000037.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 39,
      "cycle": 38,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000038.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 40,
      "cycle": 39,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000039.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 41,
      "cycle": 40,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000040.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 42,
      "cycle": 41,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000041.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 43,
      "cycle": 42,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000042.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 44,
      "cycle": 43,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000043.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 45,
      "cycle": 44,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000044.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 46,
      "cycle": 45,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000045.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 47,
      "cycle": 46,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000046.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 48,
      "cycle": 47,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000047.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 49,
      "cycle": 48,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000048.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 50,
      "cycle": 49,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000049.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 51,
      "cycle": 50,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000050.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 52,
      "cycle": 51,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000051.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 53,
      "cycle": 52,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000052.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 54,
      "cycle": 53,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000053.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 55,
      "cycle": 54,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000054.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 56,
      "cycle": 55,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000055.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 57,
      "cycle": 56,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000056.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 58,
      "cycle": 57,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000057.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 59,
      "cycle": 58,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000058.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 60,
      "cycle": 59,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000059.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 61,
      "cycle": 60,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000060.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 62,
      "cycle": 61,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000061.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 63,
      "cycle": 62,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000062.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 64,
      "cycle": 63,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000063.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 65,
      "cycle": 64,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000064.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 66,
      "cycle": 65,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000065.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 67,
      "cycle": 66,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000066.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 68,
      "cycle": 67,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000067.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 69,
      "cycle": 68,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000068.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 70,
      "cycle": 69,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000069.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 71,
      "cycle": 70,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000070.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 72,
      "cycle": 71,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000071.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 73,
      "cycle": 72,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000072.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 74,
      "cycle": 73,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000073.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 75,
      "cycle": 74,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000074.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 76,
      "cycle": 75,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000075.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 77,
      "cycle": 76,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000076.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 78,
      "cycle": 77,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000077.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 79,
      "cycle": 78,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000078.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 80,
      "cycle": 79,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000079.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 81,
      "cycle": 80,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000080.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 82,
      "cycle": 81,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000081.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 83,
      "cycle": 82,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000082.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 84,
      "cycle": 83,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000083.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 85,
      "cycle": 84,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000084.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 86,
      "cycle": 85,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000085.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 87,
      "cycle": 86,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000086.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 88,
      "cycle": 87,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000087.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 89,
      "cycle": 88,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000088.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 90,
      "cycle": 89,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000089.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 91,
      "cycle": 90,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000090.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 92,
      "cycle": 91,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000091.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 93,
      "cycle": 92,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000092.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 94,
      "cycle": 93,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000093.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 95,
      "cycle": 94,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000094.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 96,
      "cycle": 95,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000095.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 97,
      "cycle": 96,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000096.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 98,
      "cycle": 97,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000097.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 99,
      "cycle": 98,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000098.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 100,
      "cycle": 99,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000099.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 101,
      "cycle": 100,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000100.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 102,
      "cycle": 101,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000101.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 103,
      "cycle": 102,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000102.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 104,
      "cycle": 103,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000103.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 105,
      "cycle": 104,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000104.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 106,
      "cycle": 105,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000105.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 107,
      "cycle": 106,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000106.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 108,
      "cycle": 107,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000107.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 109,
      "cycle": 108,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000108.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 110,
      "cycle": 109,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000109.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 111,
      "cycle": 110,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000110.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 112,
      "cycle": 111,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000111.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 113,
      "cycle": 112,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000112.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 114,
      "cycle": 113,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000113.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 115,
      "cycle": 114,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000114.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 116,
      "cycle": 115,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000115.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 117,
      "cycle": 116,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000116.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 118,
      "cycle": 117,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000117.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 119,
      "cycle": 118,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000118.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 120,
      "cycle": 119,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000119.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 121,
      "cycle": 120,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000120.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 122,
      "cycle": 121,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000121.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 123,
      "cycle": 122,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000122.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 124,
      "cycle": 123,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000123.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 125,
      "cycle": 124,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000124.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 126,
      "cycle": 125,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000125.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 127,
      "cycle": 126,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000126.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 128,
      "cycle": 127,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000127.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 129,
      "cycle": 128,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000128.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 130,
      "cycle": 129,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000129.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 131,
      "cycle": 130,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000130.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 132,
      "cycle": 131,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000131.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 133,
      "cycle": 132,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000132.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 134,
      "cycle": 133,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000133.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 135,
      "cycle": 134,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000134.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 136,
      "cycle": 135,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000135.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 137,
      "cycle": 136,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000136.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 138,
      "cycle": 137,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000137.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 139,
      "cycle": 138,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000138.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 140,
      "cycle": 139,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000139.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 141,
      "cycle": 140,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000140.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 142,
      "cycle": 141,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000141.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 143,
      "cycle": 142,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000142.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 144,
      "cycle": 143,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000143.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 145,
      "cycle": 144,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000144.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 146,
      "cycle": 145,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000145.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 147,
      "cycle": 146,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000146.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 148,
      "cycle": 147,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000147.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 149,
      "cycle": 148,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000148.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 150,
      "cycle": 149,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000149.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 151,
      "cycle": 150,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000150.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 152,
      "cycle": 151,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000151.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 153,
      "cycle": 152,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000152.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 154,
      "cycle": 153,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000153.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 155,
      "cycle": 154,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000154.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 156,
      "cycle": 155,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000155.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 157,
      "cycle": 156,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000156.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 158,
      "cycle": 157,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000157.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 159,
      "cycle": 158,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000158.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 160,
      "cycle": 159,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000159.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 161,
      "cycle": 160,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000160.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 162,
      "cycle": 161,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000161.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 163,
      "cycle": 162,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000162.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 164,
      "cycle": 163,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000163.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 165,
      "cycle": 164,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000164.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 166,
      "cycle": 165,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000165.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 167,
      "cycle": 166,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000166.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 168,
      "cycle": 167,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000167.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 169,
      "cycle": 168,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000168.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 170,
      "cycle": 169,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000169.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 171,
      "cycle": 170,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000170.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 172,
      "cycle": 171,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000171.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 173,
      "cycle": 172,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000172.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 174,
      "cycle": 173,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000173.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 175,
      "cycle": 174,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000174.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 176,
      "cycle": 175,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000175.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 177,
      "cycle": 176,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000176.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 178,
      "cycle": 177,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000177.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 179,
      "cycle": 178,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000178.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 180,
      "cycle": 179,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000179.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 181,
      "cycle": 180,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000180.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 182,
      "cycle": 181,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000181.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 183,
      "cycle": 182,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000182.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 184,
      "cycle": 183,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000183.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 185,
      "cycle": 184,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000184.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 186,
      "cycle": 185,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000185.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 187,
      "cycle": 186,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000186.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 188,
      "cycle": 187,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000187.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 189,
      "cycle": 188,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000188.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 190,
      "cycle": 189,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000189.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 191,
      "cycle": 190,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000190.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 192,
      "cycle": 191,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000191.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 193,
      "cycle": 192,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000192.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 194,
      "cycle": 193,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000193.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 195,
      "cycle": 194,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000194.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 196,
      "cycle": 195,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000195.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 197,
      "cycle": 196,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000196.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 198,
      "cycle": 197,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000197.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 199,
      "cycle": 198,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000198.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 200,
      "cycle": 199,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000199.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 201,
      "cycle": 200,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000200.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 202,
      "cycle": 201,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000201.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 203,
      "cycle": 202,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000202.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 204,
      "cycle": 203,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000203.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 205,
      "cycle": 204,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000204.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 206,
      "cycle": 205,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000205.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 207,
      "cycle": 206,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000206.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 208,
      "cycle": 207,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000207.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 209,
      "cycle": 208,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000208.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 210,
      "cycle": 209,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000209.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 211,
      "cycle": 210,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000210.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 212,
      "cycle": 211,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000211.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 213,
      "cycle": 212,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000212.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 214,
      "cycle": 213,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000213.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 215,
      "cycle": 214,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000214.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 216,
      "cycle": 215,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000215.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 217,
      "cycle": 216,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000216.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 218,
      "cycle": 217,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000217.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 219,
      "cycle": 218,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000218.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 220,
      "cycle": 219,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000219.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 221,
      "cycle": 220,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000220.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 222,
      "cycle": 221,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000221.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 223,
      "cycle": 222,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000222.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 224,
      "cycle": 223,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000223.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 225,
      "cycle": 224,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000224.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 226,
      "cycle": 225,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000225.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 227,
      "cycle": 226,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000226.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 228,
      "cycle": 227,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000227.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 229,
      "cycle": 228,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000228.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 230,
      "cycle": 229,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000229.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 231,
      "cycle": 230,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000230.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 232,
      "cycle": 231,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000231.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 233,
      "cycle": 232,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000232.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 234,
      "cycle": 233,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000233.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 235,
      "cycle": 234,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000234.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 236,
      "cycle": 235,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000235.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 237,
      "cycle": 236,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000236.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 238,
      "cycle": 237,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000237.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 239,
      "cycle": 238,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000238.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 240,
      "cycle": 239,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000239.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 241,
      "cycle": 240,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000240.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 242,
      "cycle": 241,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000241.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 243,
      "cycle": 242,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000242.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 244,
      "cycle": 243,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000243.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 245,
      "cycle": 244,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000244.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 246,
      "cycle": 245,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000245.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 247,
      "cycle": 246,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000246.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 248,
      "cycle": 247,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000247.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 249,
      "cycle": 248,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000248.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 250,
      "cycle": 249,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000249.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 251,
      "cycle": 250,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000250.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 252,
      "cycle": 251,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000251.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 253,
      "cycle": 252,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000252.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 254,
      "cycle": 253,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000253.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 255,
      "cycle": 254,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000254.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 256,
      "cycle": 255,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000255.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    },
    {
      "index": 257,
      "cycle": 256,
      "path": "C:\\Users\\apoll\\2026_class_AI\\cartilage-runtime\\logs\\use-static3-a6-b5-fullframes-callouts-cycle-000256.png",
      "metadata": {
        "textureSide": 64,
        "profile": "clean-16-explicit-edge-lockstep",
        "annotation": {
          "enabled": true,
          "mode": "callouts",
          "cellSize": 8,
          "textureSide": 64,
          "marks": 9
        },
        "debugCells": [],
        "canvasWidth": 512,
        "canvasHeight": 512,
        "edgeSurface": "connected"
      }
    }
  ]
}
```
- screenshot: `C:\Users\apoll\2026_class_AI\cartilage-runtime\logs\cartilage-fabric-use-static3-a6-b5-fullframes-callouts-qfg-use-static3-a6-b5-use-static3-a6-b5-callouts-callouts-256.png`
- render metadata: `{"textureSide":64,"profile":"clean-16-explicit-edge-lockstep","annotation":{"enabled":true,"mode":"callouts","cellSize":8,"textureSide":64,"marks":9},"debugCells":[],"canvasWidth":512,"canvasHeight":512,"edgeSurface":"connected"}`

Raw edge readback, kept only for audit:

- first: `o L=0000000000000000000000000000000000000000000000000000000000000000 T=0000000000000000000000000000000000000000000000000000000000000000 R=0000000000000000000000...`
- last: `o L=0000000010000000000000000000000000000000000000000000000000000000 T=0000000000000000000000000000000000000000000000000000000000000000 R=0000000000000000100000...`

Timing used:

```text
for each external transaction:
  read current edge output
  submit exactly one fabric compute update
  next transaction observes the resulting committed state
```