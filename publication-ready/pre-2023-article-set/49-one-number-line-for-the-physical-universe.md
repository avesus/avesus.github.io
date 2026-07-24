---
title: "One Number Line for the Physical Universe"
slug: "one-number-line-for-the-physical-universe"
date: "2022-10-28T00:07:36.495Z"
original_dates:
  - "2022-10-28T00:07:36.495Z"
description: "How to compute across enormous physical scales without confusing floating-point range, precision, dimensions, and the choice of units."
status: "publication-ready"
---

# One Number Line for the Physical Universe

*October 28, 2022*

I wanted one numerical representation that could hold a Planck-scale time and an ordinary macroscopic density without treating either as a special case.

Take two quantities:

- Planck time, approximately \(5.39 \times 10^{-44}\) seconds;
- the Loschmidt number, approximately \(2.69 \times 10^{25}\) particles per cubic meter under its defined conditions.

The exponents are separated by about 69 decimal orders of magnitude. A binary32 floating-point number—commonly called `float32`—has a normal positive range beginning around \(10^{-38}\) and extending to around \(10^{38}\). Subnormal values reach lower, at sharply reduced precision.

My first instinct was to shift the entire range by a factor of \(10^{-9}\). If one ordinary unit became one nano-unit, perhaps the useful window would slide down far enough to contain the smallest value while retaining the largest.

That instinct exposes the right problem and the wrong solution.

## Range is not precision

A floating-point number has three conceptual pieces:

- a sign;
- an exponent that chooses scale;
- a significand that carries a limited number of meaningful bits.

Multiplying every value by \(10^9\) or choosing a nano-unit shifts the exponent window occupied by the data. It does not increase the number of meaningful bits. It also does not enlarge the ratio between the largest and smallest simultaneously representable normal values.

Scaling can prevent underflow or overflow for a particular calculation. It cannot make one format more precise than it is.

Binary32 carries about seven decimal digits of precision. Near \(10^{25}\), the gap between adjacent representable numbers is enormous in absolute terms. Near \(10^{-44}\), a value may live in the subnormal region, where leading precision is lost and some hardware or software modes may flush it to zero.

Both numbers can sometimes be stored as approximate binary32 values. That does not mean a calculation combining them is meaningful.

## Units are part of the model

The Planck time and a number density do not belong on one arithmetic number line merely because both can be written in scientific notation.

One has units of time. The other has units of inverse volume.

Adding them is meaningless. Comparing their magnitudes without choosing a physical relationship is meaningless. A global exponent offset cannot repair dimensional inconsistency.

The right move is usually nondimensionalization.

Choose a characteristic scale for each physical quantity:

\[
\tau = \frac{t}{t_0}
\]

\[
\nu = \frac{n}{n_0}
\]

Now \(\tau\) and \(\nu\) are dimensionless ratios. If the characteristic scales are chosen near the values encountered in the problem, the ratios remain near one, where floating-point precision is easiest to reason about.

This does not hide the units. The units live in \(t_0\) and \(n_0\), and the program’s type or data model should retain them.

## One offset is rarely enough

Suppose a simulation contains microscopic time steps, astronomical distances, particle counts, and small probabilities. A single global scale forces unrelated quantities into one compromise.

A better representation uses a scale per dimension or per subsystem:

- time in characteristic periods;
- length in characteristic radii or grid spacing;
- mass in a chosen reference mass;
- density relative to a baseline;
- energy relative to a system-specific unit.

Equations are then rewritten in those units. Constants change numerically, but the dimensionless behavior remains.

For values that genuinely span extreme dynamic ranges within one quantity, other options exist:

- binary64 for more exponent range and precision;
- logarithmic representation for multiplicative processes;
- a mantissa plus a separately managed base-ten exponent;
- arbitrary-precision arithmetic;
- interval or uncertainty-aware values;
- separate coarse and fine components;
- exact integers for counts.

The representation should follow the operations. A log value is excellent for products and terrible for ordinary signed addition. Arbitrary precision helps only if input uncertainty and model error justify the extra digits.

## Make error travel with the value

Physical constants and measurements are not exact decimal tokens.

A useful numerical value should carry:

- unit;
- nominal value;
- uncertainty or error bound;
- representation;
- scale used for computation;
- provenance of any conversion.

Then each operation can answer two questions:

1. Is the operation dimensionally valid?
2. Does the result retain enough precision for the question being asked?

For example, subtracting two nearly equal large binary32 values can destroy most meaningful digits even though neither value overflows. Multiplying a long sequence can accumulate relative error. Integrating tiny steps can lose increments when they fall below the spacing around a large state value.

The range check is only the first gate.

## A scale-aware calculator

The tool I want would make these effects visible.

Enter a value such as Planck time. The calculator shows its binary32 encoding, whether it is normal or subnormal, the adjacent representable values, and relative error. Enter the Loschmidt number and see the absolute spacing at that magnitude. Choose a new unit and watch the exponent move without pretending that the significand grew.

Then combine quantities in an equation. The tool should reject incompatible units, show the dimensionless form, and estimate how rounding and input uncertainty propagate.

One number line for the physical universe should not mean forcing everything into one naked float.

It should mean one coherent interface where scale, units, representation, and error remain visible together.

The universe spans absurd magnitudes. Our numbers can follow—but only if we stop asking the exponent to do the work of a physical model.
