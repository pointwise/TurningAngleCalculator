#############################################################################
#
# (C) 2021 Cadence Design Systems, Inc. All rights reserved worldwide.
#
# This sample script is not supported by Cadence Design Systems, Inc.
# It is provided freely for demonstration purposes only.
# SEE THE WARRANTY DISCLAIMER AT THE BOTTOM OF THIS FILE.
#
#############################################################################

#_____________________________________________________________#
#
#************************ Brief Description ************************* #
# A Pointwise Glyph script which provides turning angle infomation for connectors.
# Operates in two selectable modes: Point mode and Connector mode
# Point Mode: an interactive mode which allows the user to
#               - select a desired connector grid point
#               - returns corresponding turning angle
#               - prompts for next desired point selection and ruturns turning angle each time a point is selected
#               - click "cancel" to exit the "Point Mode"
#
# Connector Mode: an interactive mode which allows the user to
#               - select desired set of connector(s)
#               - returns maximum and minimum turning angle for each connector
#               - rexecute if more connectors need to be examined
#               - click "cancel" to exit the "Connector Mode"
# To exit script, click "Done"
#_____________________________________________________________#

# load Glyph and TK modules
package require PWI_Glyph
pw::Script loadTK


############################################################################
# GUI
############################################################################

proc makeWindow { } {
  global infoMessage

  wm title . "Turning Angle Calculator"
  grid [ttk::frame .f -padding "5 5 5 5"] -sticky nwes
  grid columnconfigure . 1 -weight 1
  grid rowconfigure    . 0 -weight 1

  lappend infoMessages "Select Point: Get turning angle for connector grid points."
  lappend infoMessages "Select Connector(s): Get min/max turning angles for connector(s)."
  set infoMessage [join $infoMessages "\n\n"]

  set buttonWidthSmall 10
  set buttonWidthBig   20

  grid [ttk::button .f.spt -text "Select (P)oint" -width $buttonWidthBig -command GetPtAngle] \
       [ttk::button .f.scb -text "Select (C)onnectors" -width $buttonWidthBig -command GetAngleExtremes]

  bind all <KeyPress-p> {GetPtAngle}
  bind all <KeyPress-P> {GetPtAngle}
  bind all <KeyPress-c> {GetAngleExtremes}
  bind all <KeyPress-C> {GetAngleExtremes}

  grid [tk::message .f.m -textvariable infoMessage -background beige -bd 2 -relief sunken \
      -padx 5 -pady 5 -anchor w -justify left -width 250] -rowspan 4 -columnspan 2 -sticky ew
  .f.m configure -width [font measure [.f.m cget -font] $infoMessage]

  grid [ttk::separator .f.s -orient horizontal] -columnspan 2 -sticky ew

  grid [ttk::button .f.db -text "Done" -width $buttonWidthSmall -command Done ] -column 1 -row 8 -columnspan 2 -sticky e
  bind all <KeyPress-Return> {Done}

  foreach w [winfo children .f] {
      grid configure $w -padx 5 -pady 5
  }

  bind all <Escape> {Done}
  bind all <Return> {Done}

  ::tk::PlaceWindow . widget

  wm resizable . 0 0
}


# PROC: Done
#   Erases connector selection list (not the connetors themselves) and temporary pole connectors
#   Returns none
proc Done { } {
    global PoleCon

    if [info exists PoleCon] {
        pw::Entity delete $PoleCon
    }

    puts "\n --- END-OF-SCRIPT-EXECUTION --- \n"

    exit
}


# Script variables declaration
global rad2deg angTol rad2deg angTol cons PoleCon
set PoleCon [list];             # list of pole connectors created in this script; will be erased upon end of execution
set pi 3.1415926535897931
set rad2deg [expr {180/$pi}];   # radian to degree conversion
set angTol 0.01;                # angle tolerance
set cons [list]


# PROC: GetAngle
#   Get turing angle at a connector grid point
#   Connector break points are identified as grid points
#   Input: an grid point with two neighbouring points
#   Output: turning angle on specified grid point
proc GetAngle { ptList } {
    global rad2deg

    set pBef [lindex $ptList 0]
    set p0   [lindex $ptList 1]
    set pAft [lindex $ptList 2]

    # get conneting vectors
    set vBef [pwu::Vector3 subtract $p0 $pBef]
    set vAft [pwu::Vector3 subtract $pAft $p0]

    # normalize vectors
    set vBef [pwu::Vector3 normalize $vBef]
    set vAft [pwu::Vector3 normalize $vAft]

    #get dot product and angle via arc-cosine
    set dotProd [pwu::Vector3 dot $vBef  $vAft]

    if {$dotProd > 1.0 || $dotProd < -1.0} {
        set dotProd [expr {round($dotProd)}]
    }

    set vecAngle [expr {acos($dotProd)*$rad2deg}]

    return $vecAngle
}


# PROC: AngleBet2Cons
#   Get turing angle at a connector "End-point (node)"
#   Input: neighbouring point offset of parent connector (float)
#          and list connectors which shares the node (list)
#   Output: print out turning angle on the "End-point"
proc AngleBet2Cons {consInNode} {
    # recall global variables
    global conParent ptIndex xyz rad2deg

    set nodePos [list ];  # puts [$node getXYZ]
    lappend nodePos $xyz; # puts $nodePos record the node coordinate location

    set con1 [lindex $consInNode 0]
    set con2 [lindex $consInNode 1]

    set dim1 [$con1 getDimension]
    set dim2 [$con2 getDimension]

    lappend nodePos  [$con1 getXYZ 1]; # start point location of 1st connector
    lappend nodePos  [$con2 getXYZ 1]; # start point location of 2nd connector

    set nodeTol [pw::Grid getNodeTolerance]

    # determine node position (whether Begin or End) for con1 ; # 1 for Begin pt match; 0 for End pt Match
    set nodeMatch1 [pwu::Vector3 equal -tolerance $nodeTol [lindex $nodePos 0] [lindex $nodePos 1]]

    # determine node position (whether Begin or End) for con2;  # 1 for Begin pt match; 0 for End pt Match
    set nodeMatch2 [pwu::Vector3 equal -tolerance $nodeTol [lindex $nodePos 0] [lindex $nodePos 2]]

    # the point list for node and 2 adjacent points
    set ptList [list ]

    # 1st element: adjacent point from the 1st connector
    if {$nodeMatch1} {
        lappend ptList [$con1 getXYZ 2]
    } else {
        lappend ptList [$con1 getXYZ [expr {$dim1-1}]]
    }

    # 2nd element: the node location
    lappend ptList $xyz

    # 3rd element: adjacent point from the 2nd connector
    if {$nodeMatch2} {
        lappend ptList [$con2 getXYZ 2]
    } else {
        lappend ptList [$con2 getXYZ [expr {$dim2-1}]]
    }

    puts " Turning angle: [format "%5.2f" [GetAngle $ptList]] \n\n"
    unset ptList

}


# PROC: SelectConPair
#  Select a pair of connectors for deriving turning angle
#  Child proc: AngleBet2Cons
proc SelectConPair { } {
    # recall global variables
    global conParent ptIndex  xyz

    # check for position of the connector end point (node): Begin or End
    if { $ptIndex == 1 } {
        set loc Begin
    } else {
        set loc End
    }

    set node [$conParent getNode $loc];   # get the node
    set consInNode [$node getConnectors]; # list the connectors which shares the same node

    # check connector count at the node
    if { [llength $consInNode] == 1 } {
        # Free node
        puts "Free End-point: Can not derive Tuning Angle \n\n"
    } elseif { [llength $consInNode] == 2 } {
        # 2 connectorS share the node
        AngleBet2Cons $consInNode
    } else {
        # 2+ cons share the node, select a conPair
        puts "More than 2 connectors at the node. Select a connector pair.\n\n"

        set mask [pw::Display createSelectionMask -requireConnector {}]
        set text1 "Select 2 connectors:"

        while { [pw::Display selectEntities -description $text1 -selectionmask $mask -pool $consInNode curSelection] } {
            set consTemp $curSelection(Connectors)
            if { [llength $consTemp] != 2 } {
                puts "Select exactly 2 connectors.\n\n"
                continue;
            }
            AngleBet2Cons $consTemp
        }
    }
}


# PROC: CreatePoleCon
#   Create pole connector at a given point and set the desired color (optional)
#   Return none
proc CreatePoleCon {Pt {color}} {
   set segment [pw::SegmentSpline create]
       $segment addPoint $Pt
   set PoleCon [pw::Connector create]
       $PoleCon addSegment $segment
       $PoleCon setRenderAttribute ColorMode Entity
       $PoleCon setColor $color
       $PoleCon setRenderAttribute LineWidth 2
   unset segment

   return $PoleCon
}


# PROC: GetPtAngle
#   Get turning angle at a connector interior point
#   Receives a Connector point
#   Returns turning angle
proc GetPtAngle { } {
    if { [catch { \
        puts " ---- Select Point mode ----- "

        wm withdraw .
        while {1} {
            # declare global variables
            global conParent ptIndex  xyz
            set ptList [list ]

            # get a Connector point XYZ value and associated details
            set xyz [pw::Display selectPoint -description "Select a Connector point (opt cancel to abort)" \
                -connector {} -details detailsArrVar]
            set conParent $detailsArrVar(Entity)
            set ptIndex   $detailsArrVar(Index)

            # check for interior index
            if [$conParent isInteriorIndex $ptIndex] {
                # build a list of the selected interior point and two neighbouring points
                set ptList [list [$conParent getXYZ [expr {$ptIndex-1}]] $xyz \
                                 [$conParent getXYZ [expr {$ptIndex+1}]]]
                # derive turning angle
                puts " Turning angle: [format "%5.2f" [GetAngle $ptList]]\n\n"
                unset ptList
            } else {
                puts "Connector end-point (node) selected."
                # call proc for connector pair selection and derive corresponding turning angle
                SelectConPair
            }

            unset detailsArrVar conParent ptIndex xyz

            # update pointwise and script display
            pw::Display update
        }
    } errmsg] } {
        puts "\n---- Select Point: Script Aborted! -----\n$errmsg\n\n"
        # update pointwise and script display
        pw::Display update
    }

    # Focus the TK GUI for mode selection
    wm deiconify .
    focus -force .
}


# PROC: GetAngleExtremes
#   Script for get maximum and minimum turning angles in selected connector(s)
proc GetAngleExtremes { { interactive true } } {
    global rad2deg angTol cons PoleCon

    if $interactive {
      wm withdraw .
      set mask [pw::Display createSelectionMask -requireConnector {}]
      set text1 "Please select connector(s)."  
    
      # Connector presence check 
      if { [pw::Display selectEntities -description $text1 -selectionmask $mask curSelection] } {
          puts "No connector selected."
          set cons [list]
      }

      set cons $curSelection(Connectors)
    }

    # execute the script, while at least 1 connector is selected
    if { [llength $cons] > 0 } {
        if { [catch {
            # --- Script Introduction --- #
            if $interactive {
              puts "------- Maximum & mimimum turning angles (marked by pole domains) --------"
              puts " Red color for maximum turning angle & Blue color for minimum turning angle\n"
            }

            # Loop over each connector (from selected connectors)
            foreach con $cons {
                # Declare lists in use
                set pts [list ]
                set turnAngle [list ]

                # get connector dimension
                set dim [$con getDimensions]
                puts "[$con getName] dimension: $dim "

                # check for two point connector
                if {$dim < 3} {
                    if $interactive {
                      puts [format "%s is an undimensioned connector. Use \"Select Point\" mode." [$con getName]
                    } else {
                      puts [format "%s is an undimensioned connector." [$con getName]
                    }
                    continue
                }

                # get connector points coordinate/location
                for {set i 1} {$i <= $dim} {incr i} {
                    lappend pts [$con getXYZ $i]
                }

                # iterate thorugh each interior points and get the maximum and minimum turning angle
                # and corresponding point
                set maxAngle 0.0
                set maxAnglePt [list]
                set minAngle 180.0
                set minAnglePt [list]
                for {set i 1} {$i < [expr {$dim-1}] } {incr i} {
                    set angle [GetAngle [lrange $pts [expr {$i-1}] [expr {$i+1}]]]
                    if { $angle > $maxAngle || $i == 1 } {
                        set maxAngle $angle
                        set maxAnglePt [lindex $pts $i]
                    }
                    if { $angle < $minAngle || $i == 1 } {
                        set minAngle $angle
                        set minAnglePt [lindex $pts $i]
                    }
                }

                puts "Maximum turning angle: [ format "%5.2f" [lindex $maxAngle 0]]"
                puts "Minimum turning angle: [ format "%5.2f" [lindex $minAngle 0]]"

                # check if the connector has an equal turning angle;
                # if yes, don't mark max and min angle with pole connectors
                if { ($maxAngle - $minAngle) > $angTol && $minAngle < $angTol } {
                    # create pole at maximum turning angle point of the connector and mark red color
                    lappend PoleCon [CreatePoleCon $maxAnPt 0x00ff0000]; # red color code

                    # create pole at minimum turning angle point of the connector and mark green color
                    lappend PoleCon [CreatePoleCon $minAnPt 0x000000ff] ;# blue color code
                    #0x0000ff00]; # green color code ; #0x00ff00ff]; # magenta color code
                } else {
                    puts "Equal turning angle on connector found"
                }

                # add one more blank line
                puts ""
            }
        } errmsg] } {
            puts "\n   Script Aborted!    \n$errmsg\n"
            Done
        }
    }

    # Focus the scipt GUI for mode selection
    if $interactive {
      pw::Display update
      wm deiconify .
      focus -force .
    } else {
      Done
    }
}

pw::Display getSelectedEntities ents
set cons $ents(Connectors)

if { [llength $cons] > 0 } {
    GetAngleExtremes false
} else {
    makeWindow
    tkwait window .
}

# END_OF_SCRIPT

#############################################################################
#
# This file is licensed under the Cadence Public License Version 1.0 (the
# "License"), a copy of which is found in the included file named "LICENSE",
# and is distributed "AS IS." TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE
# LAW, CADENCE DISCLAIMS ALL WARRANTIES AND IN NO EVENT SHALL BE LIABLE TO
# ANY PARTY FOR ANY DAMAGES ARISING OUT OF OR RELATING TO USE OF THIS FILE.
# Please see the License for the full text of applicable terms.
#
#############################################################################
