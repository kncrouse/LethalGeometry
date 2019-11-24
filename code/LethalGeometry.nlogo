globals [
  initial-group-size
  initial-individual-energy ]

breed [ groups group ]
breed [ individuals individual ]

groups-own [
  periphery-count
  territory-size
  population-size
  food-availability
  total-death-count
  war-death-count
  base-death-count
  num-births
  mean-age
  median-fertility
  ; FOR GRAPHS
  total-mortality-rate
  war-mortality-rate
  base-mortality-rate
  birth-rate
]

individuals-own [
  age
  energy
  my-group
  num_children
  birth_territory
  death_territory
  dying?
  birthing?
  purple-heart?
]

patches-own [
  penergy
  pgroup
]

;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;::: Set Up Procedures ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

to setup
  clear-all
  setup-parameters
  setup-patches
  setup-groups
  ask patches [ update-territories ]
  reset-ticks
end

to setup-parameters
  set initial-group-size 5
  set initial-individual-energy birth-cost
end

to setup-patches
  ask patches [
    set pgroup nobody
    ifelse random 100 / 100 <= patch-growth-rate [set penergy random 100] [set penergy 0]
    if penergy > 0 [set plabel "#"]
    set plabel-color green
  ]
end

to setup-groups
  repeat number-of-groups [ add-group ]
end

to add-group
  create-groups 1 [
    let me-group self
    set color one-of base-colors
    move-to one-of patches
    set hidden? true
    hatch-individuals initial-group-size [ initialize-individual me-group ]
  ]
end

to initialize-individual [ grp ]
  set age 0
  set my-group grp
  set energy initial-individual-energy
  set color [color] of my-group - 3
  set xcor [xcor] of my-group + random 5 - random 5
  set ycor [ycor] of my-group + random 5 - random 5
  set hidden? false
  set purple-heart? false
  set dying? false
  set birthing? false
  set birth_territory [territory-size] of grp
end

;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;::: Go Procedures ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

to go

  ask individuals [ check-dying ]
  ask individuals [ check-birthing ]
  ask individuals [
    set purple-heart? false
    set birthing? false
    set dying? false ]

  if count groups = 1 or ticks >= stop-at [ stop ]
  if ticks > 0 [ ask groups with [ population-size < 1 ] [ die ]]

  ask patches [ update-patches ]
  ask patches [ update-territories ]
  ask patches [ regrow-grass ]

  ask individuals [ set age age + 1]
  ask individuals [ move ]
  ask individuals with [not dying?] [ fight ]
  ask individuals with [not dying?] [ reproduce ]
  ask individuals with [not dying?] [ eat ]

  ask groups [ collect-data ]

  tick
end

;::: INDIVIDUALS :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

to move
  face one-of neighbors
  forward 1
  update-energy ( - movement-cost )
end

to fight
  let enemy one-of individuals-here with [ my-group != [my-group] of myself and not dying? ]
  if enemy != nobody [ ask enemy [
    update-energy ( - aggression-cost )
    set purple-heart? true
  ]]
end

to reproduce
  if energy > birth-cost [ set birthing? true ]
end

to eat
    update-energy penergy
    ask patch-here [ set penergy 0 set plabel "" ]
end

to check-dying
  if dying? [ die ]
end

to check-birthing
  if birthing? [
    hatch 1 [
      initialize-individual [my-group] of myself
      move-to [patch-here] of myself ]
    set num_children num_children + 1
    update-energy ( - birth-cost )
  ]
end

to update-energy [ update ]
  set energy energy + update
  if energy < 0 [ set dying? true ]
end

;::: PATCHES :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

to update-patches
  if count individuals-here > 0 [
    set pgroup [my-group] of one-of individuals-here ]
end

to update-territories
  ifelse pgroup = nobody
    [ set pcolor white ]
    [ set pcolor [color] of pgroup ]
end

to regrow-grass
  set penergy penergy + patch-growth-rate
  set plabel "#"
end

;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;::: DATA :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

; GROUPS call this function:
to collect-data
  let me self
  set periphery-count count patches with [ pgroup = myself and count neighbors with [ pgroup = [pgroup] of myself ] < 8 ]
  set territory-size count patches with [ pgroup = myself ]
  set population-size count individuals with [ my-group = myself ]
  set food-availability sum [penergy] of patches with [ pgroup = myself ] ;;
  set total-death-count count individuals with [ my-group = myself and dying?]
  set war-death-count count individuals with [ my-group = myself and dying? and purple-heart?]
  set base-death-count count individuals with [ my-group = myself and dying? and not purple-heart?]
  set total-mortality-rate total-death-count / (population-size + 0.00000001)
  set war-mortality-rate war-death-count / (population-size + 0.00000001)
  set base-mortality-rate base-death-count / (population-size + 0.00000001)
  set num-births count individuals with [ my-group = myself and birthing?]
  set birth-rate num-births / (population-size + 0.00000001)
  if population-size > 0 [
    set mean-age mean [age] of individuals with [ my-group = myself ]
    set median-fertility median [num_children] of individuals with [ my-group = myself ]]
end

to write-to-file
  let file data-file-name
  if is-string? file [ file-open file]
  let random-number random 9999999
  ask groups [
    file-print ( word random-number " " who " "
      number-of-groups " " patch-growth-rate " " movement-cost " " aggression-cost " " birth-cost " " stop-at " " count patches " "
      count groups " " count individuals " "
      periphery-count " " territory-size " " population-size " " food-availability " "
      total-death-count " " war-death-count " " base-death-count " " num-births " " mean-age " " median-fertility )
  ]
  file-close
end
@#$#@#$#@
GRAPHICS-WINDOW
221
10
692
482
-1
-1
4.63
1
10
1
1
1
0
1
1
1
0
99
0
99
1
1
1
ticks
30.0

BUTTON
31
86
107
119
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
112
86
189
119
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

MONITOR
716
10
862
55
Turtle Count
count turtles
17
1
11

SLIDER
10
277
212
310
birth-cost
birth-cost
0
10000
1.0
1
1
NIL
HORIZONTAL

MONITOR
1019
10
1165
55
Group Count
count groups
17
1
11

SLIDER
10
241
212
274
aggression-cost
aggression-cost
0
100000
1.0
1
1
NIL
HORIZONTAL

SLIDER
10
168
213
201
patch-growth-rate
patch-growth-rate
0
1
0.3
.01
1
NIL
HORIZONTAL

SLIDER
10
205
213
238
movement-cost
movement-cost
0
100
1.0
1
1
NIL
HORIZONTAL

PLOT
704
61
928
189
Territory Size vs. Total Mortality
Territory
Mtot
0.0
500.0
0.0
1.0
true
false
"" "if (count patches with [ pgroup = nobody ] < 1) [\n  ask groups [\n    plotxy territory-size total-mortality-rate\n    plot-pen-down\n    plot-pen-up\n  ]\n]"
PENS
"default" 1.0 2 -16777216 true "" ""

PLOT
934
61
1172
189
Periphery Ratio vs. Total Mortality
p/T
Mtot
0.0
1.0
0.0
1.0
true
false
"" "if (count patches with [ pgroup = nobody ] < 1) [\n  ask groups [\n    plotxy periphery-count / ( territory-size + 0.0000000001 ) total-mortality-rate\n    plot-pen-down\n    plot-pen-up\n  ]\n]"
PENS
"default" 1.0 2 -16777216 true "" ""

PLOT
935
196
1172
329
Periphery Ratio vs. War Mortality
p/T
Mwar
0.0
1.0
0.0
1.0
true
false
"" "if (count patches with [ pgroup = nobody ] < 1) [\n  ask groups [\n    plotxy periphery-count / ( territory-size + 0.0000000001 ) war-mortality-rate\n    plot-pen-down\n    plot-pen-up\n  ]\n]"
PENS
"default" 1.0 2 -16777216 true "" ""

PLOT
704
196
928
328
Territory Size vs. War Mortality
Territory
Mwar
0.0
500.0
0.0
1.0
true
false
"" "if (count patches with [ pgroup = nobody ] < 1) [\n  ask groups [\n    plotxy territory-size war-mortality-rate\n    plot-pen-down\n    plot-pen-up\n  ]\n]"
PENS
"default" 1.0 2 -16777216 true "" ""

MONITOR
867
10
1013
55
Population Density
count individuals / count patches
5
1
11

PLOT
704
334
928
475
Territory Size vs. Base Mortality
Territory
Mbase
0.0
500.0
0.0
1.0
true
false
"" "if (count patches with [ pgroup = nobody ] < 1) [\n  ask groups [\n    plotxy territory-size base-mortality-rate\n    plot-pen-down\n    plot-pen-up\n  ]\n]"
PENS
"default" 1.0 2 -16777216 true "" ""

PLOT
935
334
1173
475
Periphery Ratio vs. Base Mortality
p/T
Mbase
0.0
1.0
0.0
1.0
true
false
"" "if (count patches with [ pgroup = nobody ] < 1) [\n  ask groups [\n    plotxy periphery-count / ( territory-size + 0.0000000001 ) base-mortality-rate\n    plot-pen-down\n    plot-pen-up\n  ]\n]"
PENS
"default" 1.0 2 -16777216 true "" ""

PLOT
1183
10
1352
162
GroupsVDensity
GrpCount
TotPopDensity
0.0
10.0
0.0
1.0
false
false
"" "if (count patches with [ pgroup = nobody ] < 1) [\n  plotxy count groups count individuals / count patches \n  plot-pen-down\n  plot-pen-up\n]"
PENS
"default" 1.0 2 -16777216 true "" ""

INPUTBOX
10
13
212
73
data-file-name
my-data
1
0
String

SLIDER
10
132
213
165
number-of-groups
number-of-groups
0
10
10.0
1
1
NIL
HORIZONTAL

SLIDER
10
314
212
347
stop-at
stop-at
0
10000
1000.0
100
1
ticks
HORIZONTAL

PLOT
1359
167
1532
307
Reproduction
Territory
Fertility
0.0
10000.0
0.0
10.0
true
false
"" "if (count patches with [ pgroup = nobody ] < 1) [\n  ask groups [\n    plotxy territory-size median-fertility\n    plot-pen-down\n    plot-pen-up\n  ]\n]"
PENS
"default" 1.0 2 -16777216 true "" ""

PLOT
1359
10
1533
162
LongVTerritory
Territory
Longevity
0.0
10000.0
0.0
1000.0
true
false
"" "if (count patches with [ pgroup = nobody ] < 1) [\n  ask groups [\n    plotxy territory-size mean-age\n    plot-pen-down\n    plot-pen-up\n  ]\n]"
PENS
"default" 1.0 2 -16777216 true "" ""

PLOT
1183
342
1352
477
DensityVFertility
WithinPopDensity
Fertility
0.0
1.0
0.0
10.0
true
false
"" "if (count patches with [ pgroup = nobody ] < 1) [\n  ask groups [\n    plotxy (population-size / territory-size) median-fertility\n    plot-pen-down\n    plot-pen-up\n  ]\n]"
PENS
"default" 1.0 2 -16777216 true "" ""

PLOT
1360
311
1533
458
TerritoryVIBI
Territory
IBI
0.0
10000.0
0.0
10.0
true
false
"" "if (count patches with [ pgroup = nobody ] < 1) [\n  ask groups [\n    plotxy territory-size ( mean-age / ( median-fertility + 0.0000000001) )\n    plot-pen-down\n    plot-pen-up\n  ]\n]"
PENS
"default" 1.0 2 -16777216 true "" ""

PLOT
1182
169
1352
337
FeedingCompetition
Territory
WithinPopDensity
0.0
10000.0
0.0
1.0
true
false
"" "if (count patches with [ pgroup = nobody ] < 1) [\n  ask groups [\n    plotxy territory-size (population-size / territory-size)\n    plot-pen-down\n    plot-pen-up\n  ]\n]"
PENS
"default" 1.0 2 -16777216 true "" ""

@#$#@#$#@
NetLogo 6.1.1

## WHAT IS IT?

Lethal Geometry examines the relationship between territory size and intergroup mortality risk under realistic assumptions. Furthermore, the model investigates how fertility is affected by this relationship.

## HOW IT WORKS

The agents are programmed to walk randomly about their environment, search for and eat food to obtain energy, reproduce if they can, and act aggressively toward individuals of other groups. During each simulation step, agents analyze their environment and internal state to determine which actions to take. The actions available to agents include moving, fighting, and giving birth. Each action is associated with a predetermined energetic cost.

We expect territory sizes to fluctuate over time in response to individual reproduction, random-walking, and lethal intergroup encounters. In turn, the individuals within these territories are expected to vary in their mortality and fertility rates.

## HOW TO USE IT

data-file-name: location and name of output data file.
number-of-groups: The number of groups initially placed in the environment.
patch-growth-rate: The rate at which each cell or patch increases its resource energy.
movement-cost: The amount that an individual’s energy stores are reduced when it moves to an adjacent cell.
birth-cost: The amount that an individual’s energy stores are reduced when it reproduces.
aggression-cost: The amount that an individual’s energy stores are reduced when it is attacked by another individual.
stop-at: The number of ticks or time steps that occur before the simulation stops.

## CREDITS AND REFERENCES

Copyright 2019 K N Crouse

This model was created at the University of Minnesota.

The model may be freely used, modified and redistributed provided this copyright is included and the resulting models are not used for profit.

Contact K N Crouse at crou0048@umn.edu if you have questions about its use.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Lethal_Experiment" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <final>write-to-file</final>
    <exitCondition>count turtles &gt; 10000</exitCondition>
    <enumeratedValueSet variable="number-of-groups">
      <value value="10"/>
    </enumeratedValueSet>
    <steppedValueSet variable="patch-growth-rate" first="0.1" step="0.1" last="1"/>
    <steppedValueSet variable="movement-cost" first="1" step="1" last="10"/>
    <steppedValueSet variable="aggression-cost" first="1" step="1" last="10"/>
    <steppedValueSet variable="birth-cost" first="1" step="1" last="10"/>
    <enumeratedValueSet variable="stop-at">
      <value value="1000"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
