# 
# This sample script is not supported by Pointwise, Inc.
# It is provided freely for demonstration purposes only.  
# SEE THE WARRANTY DISCLAIMER AT THE BOTTOM OF THIS FILE.
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
wm title . "Turning Angle Calculator"
grid [ttk::frame .f -padding "5 5 5 5"] -column 1 -row 0 -sticky nwes
grid columnconfigure . 1 -weight 1
grid rowconfigure    . 0 -weight 1

lappend infoMessages "Select Point: Get turning angle for connector grid points.\n\n"
lappend infoMessages "Select Connector(s): Get min/max turning angles for connector(s)."
set infoMessage [join $infoMessages ""]

set buttonWidthSmall 10
set buttonWidthBig   20

grid [ttk::button .f.spt -text "Select (P)oint" -width $buttonWidthBig -command GetPtAngle] -column 0 -row 0 -columnspan 1
bind all <KeyPress-p> {GetPtAngle}; bind all <KeyPress-P> {GetPtAngle};

grid [ttk::button .f.scb -text "Select (C)onnectors" -width $buttonWidthBig -command GetAngleExtremes] -column 1 -row 0 -columnspan 1
bind all <KeyPress-c> {GetAngleExtremes}; bind all <KeyPress-C> {GetAngleExtremes};

grid [tk::message .f.m -textvariable infoMessage -background beige -bd 2 -relief sunken -padx 5 -pady 5 -anchor w -justify left -width 250] -column 0 -row 6 -columnspan 2 -sticky ew

grid [ttk::separator .f.s -orient horizontal] -column 0 -row 7 -columnspan 2 -sticky ew

grid [ttk::button .f.db -text "Done"   -width $buttonWidthSmall -command Done ] -column 1 -row 8 -columnspan 2 -sticky e
bind all <KeyPress-Return> {Done};

foreach w [winfo children .f] {grid configure $w -padx 5 -pady 5}

::tk::PlaceWindow . widget
wm resizable . 0 0


# PROC: UpdateDisplay
#   Updates Pointwise display and brings the scipt GUI to active mode 
#   Receives none 
#   Returns none
proc UpdateDisplay {} {

    pw::Display update
    wm state . normal

}


# PROC: Done
#   Erases connector selection list (not the connetors themselves) and temporary pole connectors
#   Returns none
proc Done {} {

    global cons PoleCon

    if [info exists cons] { 

        foreach con $cons {
            $con setRenderAttribute PointMode None 
        }

    }

    if [info exists PoleCon] {pw::Entity delete  $PoleCon}

    puts "";  puts " --- END-OF-SCRIPT-EXECUTION --- "; puts ""

    exit

}


# Script variables declaration
global rad2deg angTol rad2deg angTol cons PoleCon
set PoleCon [list ];            # list of pole connectors created in this script; will be erased upon end of execution             
set pi 3.1415926535897931
set rad2deg [expr {180/$pi}];   # radian to degree conversion
set angTol 0.01;                # angle tolerance


# PROC: SelectCon
#   Prompt user to select connectors
#   Returns selected connectors
#   If none provided, pull back to TK GUI
proc SelectCon {} {

    set mask [pw::Display createSelectionMask -requireConnector {}]
    set text1 "Please select connector(s)."  
    set boolCon [pw::Display selectEntities -description $text1 -selectionmask $mask curSelection]
    
    # Connector presence check 
    if { $boolCon==0 } {
        puts "No connector selected."
    }

    return $curSelection(Connectors)

}


# PROC: GetAngle
#   Get turing angle at a connector grid point
#   Connector break points are identified as grid points
#   Input: an grid point with two neighbouring points
#   Output: turning angle on specified grid point
proc GetAngle {ptList} {

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
    
    puts " Turning angle: [ format "%5.2f" [GetAngle $ptList]] \n\n" 
    unset ptList 
    
}


# PROC: SelectConPair
#  Select a pair of connectors for deriving turning angle
#  Child proc: AngleBet2Cons
proc SelectConPair {} {

    # recall global variables
    global conParent ptIndex  xyz
    
    # check for position of the connector end point (node): Begin or End
    if {$ptIndex == 1} { 
        set loc Begin
    } else {             
        set loc End
    }
       
    set node [$conParent getNode $loc];   # get the node    
    set consInNode [$node getConnectors]; # list the connectors which shares the same node
    
    # check connector count at the node
    if {[llength $consInNode] ==1} {; # Free node 
        puts "Free End-point: Can not derive Tuning Angle \n\n"
    } elseif {[llength $consInNode] ==2} { ; # 2 connectorS share the node
        AngleBet2Cons $consInNode
    } else {                               ; # 2+ cons share the node, select a conPair
        
        puts "More than 2 connectors at the node  \n\n Select a connector pair \n\n"
        
        set boolCon 1; set iLoop 1
        while {$boolCon} {

            set mask [pw::Display createSelectionMask -requireConnector {}]
            set text1 "Select 2 connectors:"
            set boolCon [pw::Display selectEntities -description $text1 -selectionmask $mask -pool $consInNode curSelection]
            
            set consTemp $curSelection(Connectors); # curSelection is an array of list; # grabed the connector list only 
            
            # connector pair check
            if {[llength $consTemp] ==2 } {
                set consInNode $consTemp; unset consTemp; # reassign to consInNode and unset consTemp
                
                # call proc to derive angles
                AngleBet2Cons $consInNode
                
                set boolCon 0; # set boolean to 0 to terminate the connector pair selection loop
            } else {
                puts "Connector count != 2: Select 2 connectors only \n\n"
            }
             
            # Recursive loop count
            incr iLoop
            
            # Force terminate current loop, if 2 coonectors are not selected within 3 attempts
            if {$iLoop > 3} {
                set boolCon 0
                puts "Failed to select 2 connectos."
            }
            
        }        
    
    }

}


# PROC: MaxVal
#   Procedure to get maximum value from a list and its' index
#   input: a tcl list
#   output: maximum value and its' index
proc MaxVal {aList} {

    set L [llength $aList] 
    set index 0
    set res [lindex $aList 0]

    for {set i 1} {$i < $L} {incr i} {

        set element [lindex $aList $i]

        if {$element > $res} {

            set res $element; 
            set index $i

        }

    }
   
    return [list $res $index]

}


# PROC: MinVal
#   Procedure to get minimum value from a list and its' index
#   input: a tcl list
#   output: minimum value and its' index
proc MinVal {aList} {

    set L [llength $aList] 
    set index 0
    set res [lindex $aList 0]

    for {set i 1} {$i < $L} {incr i} {

        set element [lindex $aList $i]
        if {$element < $res} {
            set res $element; 
            set index $i
        }

    }
   
    return [list $res $index]

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
proc GetPtAngle {} {

    if {[ catch { \

        puts " ---- Select Point mode ----- "

        while {1} {

            # declare global variables
            global conParent ptIndex  xyz
            set ptList [list ]
            
            # get a Connector point XYZ value and associated details
            set xyz [pw::Display selectPoint -description "Select a Connector point (opt cancel to abort)" -connector {} -details detailsArrVar]
                                        # -connector {} \ ;        # connectors selectable only
                                        # -details detailsArrVar]; # get details associated with the selected point 
            set conParent $detailsArrVar(Entity)
            set ptIndex   $detailsArrVar(Index)
            
            # check for interior index
            if {[$conParent isInteriorIndex $ptIndex]} {

                # build a list of the selected interior point and two neighbouring points
                set ptList [list [$conParent getXYZ [expr {$ptIndex-1}]]\
                                  $xyz\
                                 [$conParent getXYZ [expr {$ptIndex+1}]]]
                # derive turning angle
                puts " Turning angle: [ format "%5.2f" [GetAngle $ptList]] \n\n"
                unset ptList

            } else {

                puts {"Connector end-point (node) selected."}
                # call proc for connector pair selection and derive corresponding turning angle
                SelectConPair

            }  
            
            unset detailsArrVar conParent ptIndex xyz
            
            # update pointwise and script display
            UpdateDisplay
            
            
        } \

    } errmsg] } {

        puts "\n---- Select Point: Script Aborted! -----\n\n" 
        # update pointwise and script display    
        UpdateDisplay

    }

    # Focus the TK GUI for mode selection 
    focus -force .

}


# PROC: GetAngleExtremes
#   Script for get maximum and minimum turning angles in selected connector(s)
proc GetAngleExtremes {} {

    if {[ catch {

        global rad2deg angTol cons PoleCon

        # Connector(s) selection 
        set cons [SelectCon]
        
        # execute the script, while at least 1 connector is selected
        if {[llength $cons] > 0} {

            # --- Script Introduction --- #
            puts "------- Maximum & mimimum turning angles (marked by pole domains) --------"
            puts " Red color for maximum turning angle & Blue color for minimum turning angle"
            puts ""

            # Loop over each connector (from selected connectors)
            foreach con $cons {

                # Declare lists in use
                set pts [list ]
                set turnAngle [list ]

                # get connector dimension
                set dim [$con getDimensions]
                puts "[$con getName] dimension: $dim " 
                
                # check for two point connector
                if {$dim <3} {
                    puts "[$con getName] is a 2 point Connector: Use \"Select Point\" mode \n\n" 
                    continue
                }
                
                # get connector points coordinate/location
                for {set i 1} {$i <= $dim} {incr i} {
                    lappend pts [$con getXYZ $i]
                }
            
                # iterate thorugh each interior points and get turning angle
                for {set i 1} {$i < [expr {$dim-1}] } {incr i} {

                    set ptList  [lrange $pts [expr {$i-1}] [expr {$i+1}]]
                    lappend turnAngle [GetAngle $ptList]
                    unset ptList

                }
                
                # get the maximum and minimum turning angle and corresponding index
                set maxAngle [MaxVal $turnAngle]
                set maxAnPt [lindex $pts [expr {[lindex $maxAngle 1]+1}]];  # Advances by one since connector points count
                                                                            # start from 1 in Glyph whereas 0 in TCL list
                puts "Maximum turning angle: [ format "%5.2f" [lindex $maxAngle 0]]"
                
                set minAngle [MinVal $turnAngle]
                set minAnPt [lindex $pts [expr {[lindex $minAngle 1]+1}]] ; # same as before
                puts "Minimum turning angle: [ format "%5.2f" [lindex $minAngle 0]]"
            

                # check if the connector has an equal turning angle; 
                # if yes, don't mark max and min angle with pole connectors
                
                if {[expr {[lindex $maxAngle 0]-[lindex $minAngle 0]}] > $angTol} {
                    # create pole at maximum turning angle point of the connector and mark red color
                    lappend PoleCon [CreatePoleCon $maxAnPt 0x00ff0000]; # red color code
                
                    # create pole at minimum turning angle point of the connector and mark green color
                    lappend PoleCon [CreatePoleCon $minAnPt 0x000000ff] ;# blue color code
                    #0x0000ff00]; # green color code ; #0x00ff00ff]; # magenta color code 
                    
                } else {
                    puts "Equal turning angle on connector found"
                }
                 
                # unset variables to avoid memory related issues
                unset maxAngle; unset maxAnPt; unset minAngle; unset minAnPt; 
                unset pts; unset turnAngle
            
                puts ""; # add one more blank line  
  
            }; # end of connector turning angle extremes loop
       
        }; # end of valid connector number check/execute loop 
                    
        # update display
        UpdateDisplay 
      
    } errmsg] } {

        #puts "$errmsg"
        puts "\n   Script Aborted!    \n\n" 
        # update display
        UpdateDisplay

    }

    # Focus the scipt GUI for mode selection    
    focus -force .

}

# END_OF_SCRIPT

# DISCLAIMER:
# TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, POINTWISE DISCLAIMS
# ALL WARRANTIES, EITHER EXPRESS OR IMPLIED, INCLUDING, BUT NOT LIMITED
# TO, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE, WITH REGARD TO THIS SCRIPT.  TO THE MAXIMUM EXTENT PERMITTED 
# BY APPLICABLE LAW, IN NO EVENT SHALL POINTWISE BE LIABLE TO ANY PARTY 
# FOR ANY SPECIAL, INCIDENTAL, INDIRECT, OR CONSEQUENTIAL DAMAGES 
# WHATSOEVER (INCLUDING, WITHOUT LIMITATION, DAMAGES FOR LOSS OF 
# BUSINESS INFORMATION, OR ANY OTHER PECUNIARY LOSS) ARISING OUT OF THE 
# USE OF OR INABILITY TO USE THIS SCRIPT EVEN IF POINTWISE HAS BEEN 
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGES AND REGARDLESS OF THE 
# FAULT OR NEGLIGENCE OF POINTWISE.
#
