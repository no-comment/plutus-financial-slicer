# Plutus Financial Report Slicer

> [!NOTE]
> This package was inspired by fedoco's [apple-slicer](https://github.com/fedoco/apple-slicer/tree/master) and is basically a modified version of it written in Swift instead of Python.

## What does this do?
This package parses App Store Connect's *Financial Reports* and splits all sales by their responsible Apple Subsidiaries. This can then be used to easily create invoices like in our app [Plutus](https://apps.apple.com/app/id6499082870).

## Disclaimer
There is absolutely **no warranty**.
While we believe everything is calculated correctly and have tested everything with some reports, there can always be exceptions because Apple's reports aren't fully documented or could change.
In such cases, the calculations should fail rather than provide false information.

*Please verify for yourself that the numbers this package computes are reasonable.*

If you encounter a bug in the calculation, please let us know on by opening an issue.
