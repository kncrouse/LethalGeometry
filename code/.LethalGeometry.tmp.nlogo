extensions [ csv ]

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
  total-mortality-rate
  war-mortality-rate
  base-mortality-rate
  birth-rate
]

individuals-own [
  age
  energy
  my-group
  num-children
  dying?
  birthing?
  purple-heart?
]

patches-own [
  cell-energy
  cell-group
]

;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;::: Set Up Procedures ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

to setup
  clear-all
  setup-patches
  setup-groups
  ask patches [ update-territories ]
  reset-ticks
end

to setup-patches
  ask patches [
    set cell-group nobody
    ifelse random 100 / 100 <= cell-growth-rate [set cell-energy random 100] [set cell-energy 0]
    if cell-energy > 0 [set plabel "#"]
    set plabel-color green
  ]
end

to setup-groups
  repeat initial-number-of-groups [ add-group ]
end

to add-group
  create-groups 1 [
    let me-group self
    set color one-of base-colors + random 2 - random 2
    move-to one-of patches
    set hidden? true
    hatch-individuals initial-group-size [ initialize-individual me-group ]
  ]
end

to initialize-individual [ grp ]
  set age 0
  set shape "default"
  set my-group grp
  set energy birth-cost
  set color [color] of my-group - 3
  set xcor [xcor] of my-group + random 5 - random 5
  set ycor [ycor] of my-group + random 5 - random 5
  set hidden? false
  set purple-heart? false
  set dying? false
  set birthing? false
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
  update-energy cell-energy
  ask patch-here [ set cell-energy 0 set plabel "" ]
end

to check-dying
  if dying? [ die ]
end

to check-birthing
  if birthing? [
    hatch 1 [
      initialize-individual [my-group] of myself
      set shape "default"
      move-to [patch-here] of myself ]
    set num-children num-children + 1
    update-energy ( - birth-cost )
  ]
end

to update-energy [ update ]
  set energy energy + update
  if energy < 0 [ set dying? true ]
end

;::: CELLS :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

to update-patches
  if count individuals-here > 0 [
    set cell-group [my-group] of one-of individuals-here ]
end

to update-territories
  ifelse cell-group = nobody
    [ set pcolor white ]
  [ set pcolor [color] of cell-group ]
end

to regrow-grass
  set cell-energy cell-energy + cell-growth-rate
  set plabel "#"
end

;::: GROUPS :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

to collect-data
  let me self
  set periphery-count count patches with [ cell-group = myself and count neighbors with [ cell-group = [cell-group] of myself ] < 8 ]
  set territory-size count patches with [ cell-group = myself ]
  set population-size count individuals with [ my-group = myself ]
  set food-availability sum [cell-energy] of patches with [ cell-group = myself ]
  set total-death-count count individuals with [ my-group = myself and dying?]
  set war-death-count count individuals with [ my-group = myself and dying? and purple-heart?]
  set base-death-count count individuals with [ my-group = myself and dying? and not purple-heart?]
  set total-mortality-rate ifelse-value ( population-size = 0 ) [ 0 ] [ total-death-count / population-size ]
  set war-mortality-rate ifelse-value ( population-size = 0 ) [ 0 ] [ war-death-count / population-size ]
  set base-mortality-rate ifelse-value ( population-size = 0 ) [ 0 ] [ base-death-count / population-size ]
  set num-births count individuals with [ my-group = myself and birthing?]
  set birth-rate ifelse-value ( population-size = 0 ) [ 0 ] [ num-births / population-size ]
  if population-size > 0 [
    set mean-age mean [age] of individuals with [ my-group = myself ]
    set median-fertility median [num-children] of individuals with [ my-group = myself ]]
end


;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;::: DATA :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

to output-data

  let file-path ( word "../results/" file-name ".csv" )

  if ( not file-exists? file-path )

  [ file-open file-path
    file-print csv:to-string (list (list

      "simulation_no"
      "group_no"
      "p_number_of_groups"
      "p_cell_growth_rate"
      "p_movement_cost"
      "p_aggression_cost"
      "p_birth_cost"
      "p_stop_at"
      "world_cell_count"
      "world_group_count"
      "world_individual_count"
      "group_periphery_count"
      "group_territory_size"
      "group_population_size"
      "group_death_count"
      "group_war_death_count"
      "group_base_death_count"
      "group_birth_no"
      "group_mean_age"
      "group_median_fertility"

  )) ]

  file-open file-path
  let random-number random 9999999

  ask groups [

    file-print csv:to-string ( list ( list

      random-number
      who
      initial-number-of-groups
      cell-growth-rate
      movement-cost
      aggression-cost
      birth-cost
      ticks
      count patches
      count groups
      count individuals
      periphery-count
      territory-size
      population-size
      total-death-count
      war-death-count
      base-death-count
      num-births
      mean-age
      median-fertility

  ))]

  file-close

end

;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;::: VERIFICATION :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

to verify-code

  let trial-number 1
  let number-of-trials 100
  let simulation-duration 1000
  let boolean-list []

  let file-path ( word "../results/" file-name )

  if is-string? file-path and file-exists? file-path [ file-delete file-path ]

  file-open file-path

  file-print ( word "VERIFICATION TEST of LethalGeometry - " date-and-time )
  file-print ""
  file-print ( word "Number of trials: " number-of-trials )
  file-print ( word "Simulation duration: " simulation-duration " ticks" )
  file-print ""
  file-print ""

  repeat number-of-trials [

    clear-all

    set initial-number-of-groups 1 + random 10
    set initial-group-size 1 + random 10
    set cell-growth-rate precision random-float 1.0 2
    set movement-cost 1 + random 10
    set aggression-cost 1 + random 10
    set birth-cost 1 + random 10

    setup-patches
    setup-groups
    ask patches [ update-territories ]
    reset-ticks

    repeat simulation-duration [ go ]

    file-print ( word "SIMULATION TRIAL " trial-number )
    file-print ( word "initial-number-of-groups: " initial-number-of-groups )
    file-print ( word "initial-group-size: " initial-group-size )
    file-print ( word "patch-growth-rate: " cell-growth-rate )
    file-print ( word "movement-cost: " movement-cost )
    file-print ( word "aggression-cost: " aggression-cost )
    file-print ( word "birth-cost: " birth-cost )
    file-print ""

    file-print ( word "number of groups: " count groups )
    file-print ( word "number of individuals: " count individuals )

    let boolean-result ( not any? individuals with [ birthing? and energy < birth-cost ] )
    file-print ( word boolean-result " There are not any agents that are set to give birth but do not have sufficient energy?" )
    set boolean-list lput boolean-result boolean-list

    set boolean-result ( not any? individuals with [ dying? and energy > 0 ] )
    file-print ( word boolean-result " There are not any agents that are set to die but have energy greater than zero?")
    set boolean-list lput boolean-result boolean-list

    set boolean-result ( not any? individuals with [ purple-heart? and not any? other individuals-here ] )
    file-print ( word boolean-result " There are not any agents marked as injured with no other agents in the same cell?" )
    set boolean-list lput boolean-result boolean-list

    set boolean-result ( sum [ base-death-count ] of groups + sum [ war-death-count ] of groups = sum [ total-death-count ] of groups )
    file-print ( word boolean-result " The number of agents who died from aggression and those who died from starvation equal total dead agents?" )
    set boolean-list lput boolean-result boolean-list

    let core-no count patches with [ cell-group != nobody and not any? neighbors with [ cell-group != [cell-group] of myself ]]
    let periphery-no sum [ periphery-count ] of groups
    let territory-no sum [ territory-size ] of groups
    set boolean-result ( core-no + periphery-no = territory-no )
    file-print ( word boolean-result " The number of periphery cells and the number of core cells equals the total number of cells present?" )
    set boolean-list lput boolean-result boolean-list

    set boolean-result ( not any? individuals with [ my-group = nobody ] )
    file-print ( word boolean-result " There are not any individuals who are not associated with a group?" )
    set boolean-list lput boolean-result boolean-list

    set boolean-result ( not any? groups with [ hidden? = false ] )
    file-print ( word boolean-result " There are not any groups that are visible to the user?" )
    set boolean-list lput boolean-result boolean-list

    set boolean-result ( not any? patches with [ cell-energy < 0 ] )
    file-print ( word boolean-result " There are not any cells with negative energy?" )
    set boolean-list lput boolean-result boolean-list

    set boolean-result ( not any? patches with [ not member? cell-group (lput nobody [my-group] of individuals) ] )
    file-print ( word boolean-result " There are not any cells who are associated with a group that no longer exists?" )
    set boolean-list lput boolean-result boolean-list

    set boolean-result ( not any? patches with [ not member? cell-group (lput nobody [my-group] of individuals) ] )
    file-print ( word boolean-result " There are not any cells with agent occupants that does not associate with the group of one of the occupying agents?")
    set boolean-list lput boolean-result boolean-list


    file-print ""
    file-print ""

    set trial-number trial-number + 1
  ]

  file-print ( word "PERCENT SUCCESS: " ( 100 * precision (length filter [ i -> i = true ] boolean-list / length boolean-list ) 2 ) "%" )

  file-close

end
@#$#@#$#@
GRAPHICS-WINDOW
228
10
903
686
-1
-1
6.67
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
12
93
108
126
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
113
93
215
126
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
12
295
215
340
Individual Count
count turtles
17
1
11

SLIDER
12
245
215
278
birth-cost
birth-cost
0
100
9.0
1
1
NIL
HORIZONTAL

MONITOR
11
400
215
445
Group Count
count groups
17
1
11

SLIDER
12
209
215
242
aggression-cost
aggression-cost
0
100
7.0
1
1
NIL
HORIZONTAL

SLIDER
12
136
215
169
cell-growth-rate
cell-growth-rate
0
1
0.68
.01
1
NIL
HORIZONTAL

SLIDER
12
173
215
206
movement-cost
movement-cost
0
100
4.0
1
1
NIL
HORIZONTAL

PLOT
919
10
1304
328
Geometric Relationship
Territory size
Mortality Rate
0.0
500.0
0.0
1.0
true
false
"" "if (count patches with [ cell-group = nobody ] < 1) [\n  ask groups [\n    plotxy territory-size total-mortality-rate\n    plot-pen-down\n    plot-pen-up\n  ]\n]"
PENS
"default" 1.0 2 -16777216 true "" ""

MONITOR
12
347
215
392
Population Density
count individuals / count patches
5
1
11

PLOT
919
339
1304
657
World Aggression Level
Number of Groups
Population Density
0.0
10.0
0.0
1.0
false
false
"" "if (count patches with [ cell-group = nobody ] < 1) [\n  plotxy count groups count individuals / count patches \n  plot-pen-down\n  plot-pen-up\n]"
PENS
"default" 1.0 2 -16777216 true "" ""

INPUTBOX
11
462
216
522
file-name
S6_LethalGeometry_verification
1
0
String

SLIDER
12
10
215
43
initial-number-of-groups
initial-number-of-groups
0
10
7.0
1
1
NIL
HORIZONTAL

BUTTON
111
530
216
563
NIL
verify-code
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
12
49
215
82
initial-group-size
initial-group-size
0
100
4.0
1
1
NIL
HORIZONTAL

BUTTON
11
530
108
563
NIL
output-data
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
# LETHAL GEOMETRY 1.1.0

## WHAT IS IT?

LethalGeometry was developed to examine whether territory size influences the mortality risk for individuals within that territory. For animals who live in territoral groups and are lethally aggressive, we can expect that most aggression occurs along the periphery (or border) between two adjacent territories. For territories that are relatively large, the periphery makes up a proportionately small amount of the of the total territory size, suggesting that individuals in these territories might be less likely to die from these territorial skirmishes. LethalGeometry examines this geometric relationship between territory size and mortality risk under realistic assumptions of variable territory size and shape, variable border width, and stochastic interactions and movement.

## HOW IT WORKS

The individuals (agents) are programmed to walk randomly about their environment, search for and eat food to obtain energy, reproduce if they can, and act aggressively toward individuals of other groups. During each simulation step, individuals analyze their environment and internal state to determine which actions to take. The actions available to individuals include moving, fighting, and giving birth. Each action is associated with a predetermined energetic cost that is set by the user in the interface settings: MOVEMENT-COST, AGGRESSION-COST, BIRTH-COST. An individual enters into combat with one of the non-group members that it senses within its cell and its victim incurs an energy cost equal to the AGGRESSION-COST setting. An individual also eats any cell-energy that exists at its current location.

## HOW TO USE IT

### Simulation

SETUP: initialize the model for a new simulation.
GO: run a simulation.

These settings are used during the initialization process:

INITIAL-NUMBER-OF-GROUPS: the number of groups initially placed in the environment.
INITIAL-GROUP-SIZE: the number of individuals in each group during initialization.

These settings are used while a simulation is running:

CELL-GROWTH-RATE: the rate at which each cell or patch increases its resource energy.
MOVEMENT-COST: the amount that an individual’s energy stores are reduced when it moves to an adjacent cell.
AGGRESSION-COST: the amount that an individual’s energy stores are reduced when it is attacked by another individual.
BIRTH-COST: the amount that an individual’s energy stores are reduced when it reproduces.

### Collect Data

FILE-NAME: name of file chosen by the user to store data.
OUTPUT-DATA: takes demographic measurements on each of the groups currently in the simulation and outputs the results into FILE-NAME
VERIFY-CODE: runs a series of simulations to check the code for errors and outputs the results into FILE-NAME

### Monitors & Plots

INDIVIDUAL COUNT: number of individuals currently in the simulation.
POPULATION DENSITY: the average number of individuals currently in each cell.
GROUP COUNT: the number of groups currently in the simulation.

LethalGeometry was developed to explore the relationship between the size of a territory and the risk of mortality in species with lethal aggression. This geometric relationship is described in more detail above and is visually depicted in the GEOMETRIC RELATIONSHIP plot. The WORLD AGGRESSION LEVEL demonstrates how the total population density is affected by how many groups (competitors) are currently in the simulation.

## THINGS TO NOTICE

Territory sizes will fluctuate over time in response to individual reproduction, random-walking, and lethal intergroup encounters. In turn, the individuals within these territories are expected to vary in their mortality and fertility rates according to food availability and frequency of aggression.

Provided that the individuals do not immediately die due to inhospitable settings, they will wander and reproduce, eventually taking up the entire simulation world. Individuals in smaller territories are expected to be more vulnerable to lethal aggression from indiviudals in larger neighboring territories. Over time, these aggressive interactions cause the smaller territories to go extinct. The GEOMETRIC RELATIONSHIP plot visually show this relationship between territory size and mortality risk. Eventally, only one territorial group remains and we can note in the WORLD AGGRESSION LEVEL plot  the number of groups present is negatively correlated with population density, suggesting that individuals have higher survivability and/or reproduction when there are fewer enemy groups to contend with.

## THINGS TO TRY

Not all settings result in hospitable worlds! Modify the settings for CELL-GROWTH-RATE or the energy costs of activities: MOVEMENT-COST, AGGRESSION-COST, or BIRTH-COST. What settings allow the individuals to thrive? What settings cause them to die? The initial settings can also create inhospitable conditions. What happens if you set the INITIAL-NUMBER-OF-GROUPS and INITIAL-GROUP-SIZE too high?

You can also run a script that observes a series of simulations with random settings to check the code for errors. To perform this "code verification check" yourself, type in a FILE-NAME and click the VERIFY-CODE button. The results of the verification check will be saved in the file that you designate.

## HOW TO CITE

Kristin Crouse (2021). “Lethal Geometry” (Version 1.1.0). CoMSES Computational Model Library. Retrieved from: https://www.comses.net/codebases/0c781d12-f493-42dc-b81b-e7a431f9f1e6/releases/1.1.0/

## COPYRIGHT AND LICENSE

© 2021 K N Crouse

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
Circle -1 true false 60 75 60
Circle -1 true false 180 75 60
Polygon -1 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

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
NetLogo 6.2.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Lethal_Experiment" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <final>output-data</final>
    <timeLimit steps="1000"/>
    <enumeratedValueSet variable="file-name">
      <value value="&quot;lethal-data&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-number-of-groups">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-group-size">
      <value value="5"/>
    </enumeratedValueSet>
    <steppedValueSet variable="cell-growth-rate" first="0.1" step="0.1" last="1"/>
    <steppedValueSet variable="movement-cost" first="1" step="1" last="10"/>
    <steppedValueSet variable="aggression-cost" first="1" step="1" last="10"/>
    <steppedValueSet variable="birth-cost" first="1" step="1" last="10"/>
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
