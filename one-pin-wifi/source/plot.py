"""Rebuild the public measured-data figure. Copyright 2026 Brian Greenforest, MIT."""
from pathlib import Path
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

ROOT = Path(__file__).resolve().parent.parent
s = np.loadtxt(ROOT/'data/spectrum.csv', delimiter=',', skiprows=1)
b = np.loadtxt(ROOT/'data/barker.csv', delimiter=',', skiprows=1)
p = np.loadtxt(ROOT/'data/test-bits.csv', delimiter=',', skiprows=1).astype(int)
fig, axes = plt.subplots(4, 1, figsize=(21, 14), layout='constrained',
                         gridspec_kw={'height_ratios': [1.3, 1, 1, .65]})
blue, gold = '#146b83', '#d77b0a'
a = axes[0]
a.plot(s[:,0]/1e6, 10*np.log10(np.maximum(s[:,2], 1e-30)), lw=.65, color=blue, label='Peak retained in each display group')
a.plot(s[:,0]/1e6, 10*np.log10(np.maximum(s[:,1], 1e-30)), lw=.65, color='#73aabc', alpha=.7, label='Group mean power')
a.axvspan(55, 79, color='#28a06d', alpha=.18, label='24 MHz host selection around 67 MHz IF')
a.set(xlim=(0,204), xlabel='FPGA input frequency (MHz)', ylabel='Comparator-relative dB/Hz',
      title='One physical capture retains the full nominal DC–204 MHz zone')
a.legend(loc='upper right', fontsize=10)
a = axes[1]
a.plot(b[:,0], b[:,1], color=blue, lw=.9)
a.axvspan(.789,1.885,color='#28a06d',alpha=.18,label='Received delimiter, PHY header and complete MAC frame')
a.set(xlabel='Despread symbol position (ms, nominal)', ylabel='Barker magnitude\n(receiver-relative)',
      title='Actual despreader output from the same capture')
a.legend(loc='upper right', fontsize=10)
a = axes[2]
a.step(p[:128,0],p[:128,1],where='post',lw=3,color=blue,label='Transmitted test bits')
a.step(p[:128,0],p[:128,2],where='post',lw=1.5,ls='--',color=gold,label='Received bits, uncorrected')
a.set(xlim=(0,127),ylim=(-.15,1.4),yticks=[0,1],xlabel='Test-payload bit index',
      title='Transmitted and received: zero mismatches across all 512 test bits')
a.legend(loc='upper right',ncol=2,fontsize=10)
a = axes[3]
a.imshow(np.stack([p[:,1],p[:,2],p[:,1]!=p[:,2]]),aspect='auto',interpolation='nearest',cmap='Greys',vmin=0,vmax=1)
a.set(yticks=[0,1,2],yticklabels=['Transmitted','Received','Mismatch'],xlabel='All 512 test-payload bits',title='Every received test bit · white = 0, black = 1')
for a in axes[:3]:a.grid(alpha=.17)
fig.suptitle('Wi-Fi through one FPGA input\n2,437 MHz → moRFeus → 67 MHz IF · no external LNA',fontsize=24)
fig.supxlabel('129-byte beacon · PHY CRC16 and full-frame FCS32 passed · zero repaired bits\n1,048,576 physical decisions · 2.570 ms · 408 Mdecision/s nominal · Brian Greenforest',fontsize=14)
fig.savefig(ROOT/'received-data.png',dpi=200,metadata={'Software':'Brian Greenforest open-source plot.py'})
plt.close(fig)
print(ROOT/'received-data.png')
