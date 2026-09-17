"""Exact host tracking-FM function from the recorded receiver."""
import numpy as np

def tracking_fm(iq, fs, natural_hz=15000., zeta=.7071067811865476):
    """Second-order phase tracker; output is the measured phase correction.

    No source knowledge, spectral peak fit, held audio, or generated message.
    Integrator and proportional terms both contribute to the next phase step.
    """
    w = 2*np.pi*natural_hz/fs
    den = 1 + 2*zeta*w + w*w
    alpha = 4*zeta*w/den; beta = 4*w*w/den
    phases = np.angle(iq)
    estimate = float(phases[0]); omega = 0.
    out = np.empty(len(iq)-1); errors = np.empty(len(iq)-1)
    for k in range(len(iq)-1):
        e = (float(phases[k])-estimate+np.pi) % (2*np.pi)-np.pi
        omega += beta*e
        step = omega + alpha*e
        out[k] = step*fs/(2*np.pi)
        errors[k] = e
        estimate = (estimate+step+np.pi) % (2*np.pi)-np.pi
    return out, errors
