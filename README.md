# TurningAngleCalculator
Copyright 2021 Cadence Design Systems, Inc. All rights reserved worldwide.

A Pointwise Glyph script which computes the turning angle for connector grid points.

![CreateTurningAngleCalculatorGUI](https://raw.github.com/pointwise/TurningAngleCalculator/master/TurningAngleCalcImage.png)

## Get Turning Angle 
This script operates in two selectable modes: Point mode and Connector mode

### Point Mode: an interactive mode which allows the user to
               - select a desired connector grid point
               - returns corresponding turning angle
               - prompts for next desired point selection and ruturns turning angle each time a point is selected
               - click "cancel" to exit the "Point Mode"
             
### Connector Mode: an interactive mode which allows the user to
               - to select desired set of connector(s)
               - returns maximum and minimum turning angle for each connector
               - rexecute if more connectors need to examine
               - click "cancel" to exit the "Connector Mode"

To exit script, click "Done"

## Disclaimer
This file is licensed under the Cadence Public License Version 1.0 (the "License"), a copy of which is found in the LICENSE file, and is distributed "AS IS." 
TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, CADENCE DISCLAIMS ALL WARRANTIES AND IN NO EVENT SHALL BE LIABLE TO ANY PARTY FOR ANY DAMAGES ARISING OUT OF OR RELATING TO USE OF THIS FILE. 
Please see the License for the full text of applicable terms.
