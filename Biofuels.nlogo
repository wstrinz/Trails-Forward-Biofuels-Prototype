extensions[table]

globals[
  corn-energy switchgrass-energy corn-futures-price switchgrass-futures-price corn-spot-price switchgrass-spot-price corn-cons-price
  corn-input switchgrass-input
  s-weights
  field-list
  role-list
  colors-list
  is-started
  next-event
  price-of-energy
  energy-price ;per gJ
  corn-food-price ;per bushel
  corn-bushels-per-acre
  corn-tons-per-acre
  allow-perspective-change
  switchgrass-tons-per-acre
  switchgrass-harvest-cost
  producer-costs ;fixed cost per year
  available-corn-energy
  available-switchgrass-energy
  available-corn
  available-switchgrass
  is-waiting
  corn-supply
  corn-demand
  switchgrass-supply
  switchgrass-demand
  market-elasticity-corn
  market-elasticity-switchgrass
  expected-readies
  ready-list
  emissions-rate
  last-corn-amt
  last-switchgrass-amt
  cost-per-ton-corn
  cost-per-ton-switchgrass
  cost-per-acre-corn
  cost-per-acre-switchgrass
  log-view
  log-world
  total-emissions
  sustainability-index
  total-corn-grown
  total-switchgrass-grown
  corn-bought
  switchgrass-bought
  sustainability-components
  year
  capital
  data-list
  farmer-color-list
  farmer-list
  corn-contract
  switchgrass-contract
  corn-contract-field
  switchgrass-contract-field
  corn-bought-spot
  switchgrass-bought-spot
  corn-range
  switchgrass-range
  max-switchgrass-yield
  switchgrass-growth-constant
  log-players
  hubnet
  weather
  weather-table
  cost-per-acre-fertilizer
  last-year-grown
  last-year-contract
  last-year-spot
  last-year-secondary
  corn-bought-contract
  switchgrass-bought-contract
  corn-bought-secondary
  field-color-vals
  variable-cost-switchgrass
  variable-cost-corn
  switchgrass-bought-secondary
  noisy-prices
  inequality-social-score
]
patches-own[land-type switchgrass corn soil-health isOwned emissions fallowed last-corn last-switchgrass fertilizer last-corn-yield last-grass-yield]
;turtles-own[user-id role score rank agent score-components tri-score-components is-human]


breed [farmers farmer]
breed [en-producers en-producer]
breed [govs gov]
breed [controllers controller]

farmers-own[land earnings patches-owned plant-ratio fields-to-plant farmer-id destination current-field manage-individual corn-grown switchgrass-grown yearly-earnings 
  corn-sold switchgrass-sold corn-sold-spot switchgrass-sold-spot corn-sold-cons switchgrass-sold-secondary accepted-corn-contract accepted-switchgrass-contract contracted-corn contracted-switchgrass
   production contract-sales spot-sales planted corn-short switchgrass-short corn-stover economy-string environment-string ranking-string] 
;government-own[subsidy]

controllers-own[user-id role score rank agent score-components tri-score-components is-human info-view behavior-pattern earnings-rank environment-rank social-rank]

en-producers-own [switchgrass-to-buy corn-to-buy proj-revenue corn-price-plan switchgrass-price-plan 
  offered-switchgrass-contract offered-corn-contract buy-more-corn buy-more-grass]
govs-own [opinions] 

;;
;;Initializes the default values and creates the farmers
;;
to setup
  ;; (for this model to work with NetLogo's new plotting features,
  ;; __clear-all-and-reset-ticks should be replaced with clear-all at
  ;; the beginning of your setup procedure and reset-ticks at the end
  ;; of the procedure.)
  __clear-all-and-reset-ticks
  file-close
  reset-ticks
  
  set max-switchgrass-yield 1.5
  set switchgrass-growth-constant 1.1
  set farmer-color-list [black cyan magenta grey green red]
  set switchgrass-energy 111.255 ;gJ/acre
  set switchgrass-input 21.714 ;measure of C02
  set corn-energy 71.685 ;gJ/acre
  set corn-input 56 ;measure of C02
  set corn-food-price 4.8 
  set corn-bushels-per-acre 158
  set corn-tons-per-acre 4.5
  set switchgrass-tons-per-acre 4.5
  set corn-futures-price initial-corn-price
  set market-elasticity-switchgrass .15
  set market-elasticity-corn .1
  set variable-cost-switchgrass 4
  set variable-cost-corn 1
  set energy-price 4.3 ;rough 1/10 the price per gJ/ethanol
  set switchgrass-futures-price initial-grass-price
  set switchgrass-bought-secondary 0
  set producer-costs 45000 * (initial-farmers * fields-per-farmer)
  set is-started false
  set emissions-rate .05
  set is-waiting false
  set allow-perspective-change false
  set cost-per-acre-corn 788
  set cost-per-ton-corn 175
  set cost-per-ton-switchgrass 250
  set cost-per-acre-switchgrass 1125
  set cost-per-acre-fertilizer 100
  set switchgrass-harvest-cost 25 * 4.5
  set log-players true
  set year 0
  set last-year-grown ""
  set last-year-contract ""
  set last-year-spot ""
  set last-year-secondary ""
  set s-weights [1 1 1]
  set noisy-prices true
  set inequality-social-score true
  set log-view true
  set log-world true
  
  set hubnet true  
  set field-list [ ]
  set role-list [1]
  set sustainability-components [0 0 0 0]
  set ready-list []
  set farmer-list []
  
  set weather-table table:make
  table:put weather-table "Very Bad" -2
  table:put weather-table "Bad" -1
  table:put weather-table "Normal" 0
  table:put weather-table "Good" 1
  table:put weather-table "Very Good" 2
  if verbose [
    print weather-table
  ]
  
  if not file-exists? "logs" [
    user-message "Warning: no logs folder exists. either create one and restart the model or click OK to continue without logging"
    set log-players false
    set log-world false
    set log-view false
  ]

  if hubnet [
    hubnet-set-client-interface "COMPUTER" []
    hubnet-reset
    create-farmers initial-farmers [set land nobody set planted "" set production "" set contract-sales "" set spot-sales ""]
    generate-world
    recompute-field-colors
    recolor-background
  ]  
end

;;
;;Starts the game
;;
to start
  set is-started true
  let extra-farmers initial-farmers - count controllers with [role = "farmer"]
  ;  print extra-farmers
  if(extra-farmers > 0)[
   repeat extra-farmers [add-ai-player]
  ]
  if(hubnet)
  [
    foreach(n-values (count controllers with [role = "farmer"]) [?]) 
    [
      ask item ? farmer-list [
        set farmer-id ?
      ]
    ]
    ask farmers [
     set patches-owned land with [land-type = 1] 
     set earnings 50000
    ]
  ]
  
  recompute-field-colors
  setup-earnings-plot
end

to reset-world
  ;; (for this model to work with NetLogo's new plotting features,
  ;; __clear-all-and-reset-ticks should be replaced with clear-all at
  ;; the beginning of your setup procedure and reset-ticks at the end
  ;; of the procedure.)
  __clear-all-and-reset-ticks
  set is-started false
  
  set switchgrass-energy 1
  set corn-energy 1
  set corn-futures-price initial-corn-price
  set switchgrass-futures-price initial-grass-price
  
  set field-list [ ]
  set role-list [1]
  generate-world
  recolor-background
end

;;
;;Runs through the events per year
;;
to go
  let thismod ticks mod 365
  listen-clients

  if(is-started)[
    if(ticks > 0) [ais-think]
    move-farmers

    if (ticks mod 365 = 0)[
      set year year + 1
      market-adjust
      compute-price-ranges
      reset-yearlies
      log-yearlies
      control-prices
      set-weather
      set next-event "Energy Producer Offers Contracts"
      if wait-tick [set is-waiting true]
      ]
    if (ticks mod 365 = 25)[
      offer-contracts
      ask controllers with [is-human = false] [
        ai-decide-contracts
      ]
      ai-reset-fields-to-plant
      set next-event "Farmers Accept/Decline Contracts"
      if (wait-tick) [set is-waiting true]
      if (not contracts) [set is-waiting false]
      ]
    if (ticks mod 365 = 50)[
      accept-contracts

      set next-event "Farmers Choose What to Plant"
      if wait-tick [set is-waiting true]
      ]      
    if (ticks mod 365 = 100)[
      reset-info-strings
      farmers-choose-crops
      recompute-field-colors
      recolor-background

      set next-event "Farmers Grow and Harvest Crops"
      if wait-tick [set is-waiting true]
      ]
    if (ticks mod 365 = 150)[
      harvest-crops
      recompute-field-colors
      set next-event "Farmers Sell Crops"
      if wait-tick [set is-waiting true]
      ]     
    if (ticks mod 365 = 250) [
      environment-change
      farmers-sell-crops-complicated
      ask farmers [
        if corn-grown > corn-sold [
          print "didnt sell all corn"
        ]
        if switchgrass-grown > switchgrass-sold [
         print "didnt sell all grass" 
        ]
        
      ]
      recolor-background
      set next-event "Government Acts"
      if wait-tick [set is-waiting true]
      ]
    if (ticks mod 365 = 300) [
      econ-change
      compute-s-index
      ask controllers [
         compute-individual-s-index
         compute-individual-s-triangle
       ]
      rank-scores
      gov-intervene
      print-summary
      if verbose [
        show (word "Gini coefficient " gini-coefficient ([earnings] of farmers))
      ]
      set ready-list []
      set next-event "Futures Price Determined"
      if wait-tick [set is-waiting true]
      ]
    
    ;update-plot
    if(hubnet)[
      update-clients
    ]
    ifelse wait-tick 
    [
      ifelse(thismod = 364 or thismod = 24 or thismod = 49 or thismod = 99 or thismod = 149 or thismod = 249 or thismod = 299)
      [
        if(not is-waiting or not farmers-turn or (all-farmers-ready and farmers-turn and not wait-for-teacher))
        [
          set ready-list []
          tick-and-do-stuff
          ;tick 
        ]
      ]
      [
        ;tick
        tick-and-do-stuff
      ]
    ]
    [
      ;tick 
      tick-and-do-stuff
    ]
  ]
end

to tick-and-do-stuff
  
 update-plot  
  tick

end

;;
;;Listens to the clients and updates when they make decisions
;;
to listen-clients
  while [hubnet-message-waiting?]
  [
    hubnet-fetch-message
    ifelse hubnet-enter-message?
    [ 
      if(is-started)[
        hubnet-kick-client hubnet-message-source
      ]
      ifelse (not any? controllers with [user-id = hubnet-message-source])[
        add-player 
      ]
      [
        hubnet-send-message hubnet-message-source "Sorry, your username is not available. Please restart hubnet and try another"
      ]
    ]
    [
      ifelse hubnet-exit-message?
      [
        show word "source " hubnet-message-source
       ; ask controllers with [user-id = hubnet-message-source] [ die ]
        
        ;set expected-readies expected-readies - 1

      ]
      [
        if log-players [
          log-player-action hubnet-message-tag hubnet-message hubnet-message-source
        ]
        if hubnet-message-tag = "View"
        [
          ask controllers with [user-id = hubnet-message-source and role = "farmer"]
          [
            ask agent [
              let dest one-of patches with [ pxcor = (round item 0 hubnet-message) and pycor = (round item 1 hubnet-message) ]
              if member? dest land [
                set destination dest
              ]
            ]
          ]
        ]
        if hubnet-message-tag = "Perspective" [
          if allow-perspective-change [
            change-perspective
          ]
        ]
        if hubnet-message-tag = "Information" [
          ask controllers with [user-id = hubnet-message-source] [
            set info-view hubnet-message
          ]
        ]
        if hubnet-message-tag = "Get Information"[
          ask controllers with [user-id = hubnet-message-source] [
            update-info-area
          ]
        ]
        ifelse ticks mod 365 > 24 and ticks mod 365 < 50 [
          if hubnet-message-tag = "Accept Corn Contract"
          [
           ifelse(contracts) [
             change-corn-contract 
           ]
           [
             ;hubnet-send hubnet-message-source "Accept Corn Contract" false
           ]
          ]
          if hubnet-message-tag = "Accept Switchgrass Contract"
          [
            ifelse(contracts) [
              change-switchgrass-contract 
            ]
            [
              ;hubnet-send hubnet-message-source "Accept Switchgrass Contract" false
            ]
          ]
          if hubnet-message-tag = "Finished Choosing Contracts" [
            if(not member? hubnet-message-source ready-list) [
              set ready-list lput hubnet-message-source ready-list
            ]
          ]
        ]
        [
          if hubnet-message-tag = "Accept Corn Contract" or hubnet-message-tag = "Accept Switchgrass Contract" or hubnet-message-tag = "Finished Choosing Contracts" [
             hubnet-send-message hubnet-message-source "This is not the time to be doing that!"
          ]
        ]
        
         
        ifelse ticks mod 365 > 49 and ticks mod 365 < 100 [
          if hubnet-message-tag = "Plant Corn" [
            ;log-player-action hubnet-message-tag hubnet-message hubnet-message-source
            ask controllers with [hubnet-message-source = user-id][
              plant-corn
            ]
          ]
          if hubnet-message-tag = "Plant All Corn" [
            foreach field-list [
              ask controllers with [user-id = hubnet-message-source] [
                if (member? (one-of ?) [land] of agent) [
                  ask agent[
                    set current-field ?
                  ]
                  plant-corn
                ]
              ]
              
            ]
          ]
          if hubnet-message-tag = "Plant Switchgrass" [
            ask controllers with [user-id = hubnet-message-source] [
              plant-switchgrass
            ]
          ]
;          if hubnet-message-tag = "Plant All Switchgrass" [
;            foreach field-list [
;              ask controllers with [user-id = hubnet-message-source] [
;                if (member? (one-of ?) [land] of agent) [
;                  ask agent[
;                    set current-field ?
;                  ]
;                  plant-switchgrass
;                ]
;              ]
;              
;            ]
;          ]
          if hubnet-message-tag = "Leave Fallow" [
            leave-fallow
          ]
          if hubnet-message-tag = "Leave All Fallow" [
            foreach field-list [
              ask controllers with [user-id = hubnet-message-source] [
                if (member? (one-of ?) [land] of agent) [
                  ask agent[
                    set current-field ?
                  ]
                  leave-fallow
                ]
              ]
              
            ]
          ]
          if hubnet-message-tag = "Plant Last" [
            foreach field-list [
              ask controllers with [user-id = hubnet-message-source] [
                if (member? (one-of ?) [land] of agent) [
                  ask agent[
                    set current-field ?
                  ]
                  if([last-corn] of (one-of ?) = 1)[
                    plant-corn
                  ]
                  if([last-switchgrass] of (one-of ?) = 1)[
                    plant-switchgrass
                  ]
                  
                ]
              ]
              
            ]
          ]
          if hubnet-message-tag = "Use Fertilizer" [
            use-fertilizer
          ]
          if hubnet-message-tag = "Use Fertilizer on All" [
            foreach field-list [
              ask controllers with [user-id = hubnet-message-source] [
                if (member? (one-of ?) [land] of agent) [
                  ask agent[
                    set current-field ?
                  ]
                  use-fertilizer
                ]
              ]
              
            ]
          ]
          
          
          if hubnet-message-tag = "Finished Planting" [
            if(not member? hubnet-message-source ready-list) [
              set ready-list lput hubnet-message-source ready-list
            ]
          ]
        ]
        [
          if hubnet-message-tag = "Plant Corn" or hubnet-message-tag = "Plant All Corn" or hubnet-message-tag = "Plant Switchgrass" or hubnet-message-tag = "Plant All Switchgrass" or hubnet-message-tag = "Leave Fallow" or hubnet-message-tag = "Leave All Fallow" or hubnet-message-tag = "Plant Last" or hubnet-message-tag = "Finished Planting" or hubnet-message-tag = "Use Fertilizer for All" or hubnet-message-tag = "Use Fertilizer" [
            hubnet-send-message hubnet-message-source "This is not the time to be doing that!"
          ]
        ]
        
      ]
    ]
  ]
end

to reset-yearlies
  ask farmers [
    set corn-sold 0
    set switchgrass-sold 0
    
  ]
end

;
;Initializes an additional player
;
to add-player
  if (count controllers with [role = "farmer"] < initial-farmers) [
    set expected-readies expected-readies + 1
    create-controllers 1 [ 
      set user-id hubnet-message-source
      set is-human true
      set label user-id
      set role "farmer"
      set info-view "Environment"
      set score-components [0 0 0 0]
      set tri-score-components [0 0 0]
      set agent one-of farmers with [not any? controllers with [agent = myself]]
     
      let not-my-land nobody
      ask agent [
       set fields-to-plant [ ]
       set plant-ratio .5 
       set destination nobody
       set current-field nobody
       set manage-individual true
        set accepted-corn-contract false
      set accepted-switchgrass-contract false
       if (count farmers <= 6) [
         set color item (length farmer-list) farmer-color-list
       ]
       move-to one-of land
       let landlist [self] of land
       set not-my-land patches with [not member? self landlist]
      ]
      hubnet-send-follow user-id agent 20
      hubnet-send-override user-id not-my-land "pcolor" [grey]
      set farmer-list lput agent farmer-list
      ht
    ]
  ]
end

to add-ai-player
  if (count controllers with [role = "farmer"] < initial-farmers) [
    set expected-readies expected-readies + 1
    create-controllers 1 [ 

      
      set is-human false
      set label user-id
      set role "farmer"
      set behavior-pattern "default"
      set score-components [0 0 0 0]
      set tri-score-components [0 0 0]
     ; print tri-score-components
      set agent one-of farmers with [not any? controllers with [agent = myself]]
      set user-id (word "ai " agent)
      let not-my-land nobody
      ask agent [
       set fields-to-plant [ ]
       set plant-ratio .5 
       set destination nobody
       set current-field nobody
       set manage-individual true
       if (count farmers <= 6) [
         ;set color item (length farmer-list) farmer-color-list
       ]
       move-to one-of land
       let landlist [self] of land
       set not-my-land patches with [not member? self landlist]
      ]
      set farmer-list lput agent farmer-list
      ht
    ]
  ]
end

to change-switchgrass-contract
  ask controllers with [user-id = hubnet-message-source] [
    if(role = "farmer")[
      ask agent [
        set accepted-switchgrass-contract hubnet-message
      ]
    ] 
  ]
end

to change-corn-contract
  ask controllers with [user-id = hubnet-message-source] [
    if(role = "farmer")[
      ask agent [
        ; print(agent)
        set accepted-corn-contract hubnet-message
      ]
    ] 
  ]
end

to log-yearlies
  if log-view [
    export-view (word "logs/" ticks ".png")
  ]

  if log-world [
    export-world (word "logs/" ticks ".csv")
  ]
end

to plant-corn
;  ask controllers with [user-id = hubnet-message-source] [
    let uid user-id
    let is-hu is-human
    ask agent [
      ifelse (current-field != nobody) [
        ask current-field [
          if is-hu[
            hubnet-send-override hubnet-message-source self "plabel-color" [white]
            hubnet-send-override hubnet-message-source self "plabel" ["C"]
          ]
          set emissions emissions-rate * corn-input
          set corn 1
          set switchgrass 0
          set fallowed 0
          set fertilizer 0
        ]
      ]
      [
        ifelse (([is-human] of controllers with [agent = myself]) = true)[
        hubnet-send-message uid "You need to select a field to plant!"
        ]
        [
          print "not there yet"
        ]
      ]]
end

to plant-switchgrass
  ;ask controllers with [user-id = hubnet-message-source] [
  let uid user-id
  let is-hu is-human
  ask agent [
    ifelse (current-field != nobody) [ ; and (not any? current-field with [switchgrass > 0])) [
      ask current-field [
        if is-hu = true[
          hubnet-send-override hubnet-message-source self "plabel-color" [white]
          hubnet-send-override hubnet-message-source self "plabel" ["S"]
        ]
        set emissions emissions-rate * switchgrass-input
        if(last-switchgrass < 1) [
          set switchgrass 1
        ]
        set corn 0
        set fallowed 0
        set fertilizer 0
      ]
    ]
    [
      if(is-hu = true) [
        hubnet-send-message uid "You need to select a field to plant!"
      ]
    ]]
  ;]
end

to leave-fallow
  ask controllers with [user-id = hubnet-message-source] [
    let uid user-id
    let is-hu is-human
    ask agent [
      ifelse (current-field != nobody) [
        ask current-field [
          if is-hu = true [
            hubnet-send-override hubnet-message-source self "plabel-color" [white]
            hubnet-send-override hubnet-message-source self "plabel" ["_"]
          ]
          set emissions 0
          set fallowed 1
          set corn 0
          set switchgrass 0
          set fertilizer 0
        ]
      ]
      [
        hubnet-send-message uid "You need to select a field to leave fallow!"
      ]]]
end

to use-fertilizer
  ask controllers with [user-id = hubnet-message-source] [
    let uid user-id
    let is-hu is-human
    ask agent [
      ifelse (current-field != nobody) [
        ask current-field [
          if is-hu [
            hubnet-send-override hubnet-message-source self "plabel-color" [green]
          ]
          set fertilizer 1
          set emissions emissions + 1
        ]
      ]
      [
        hubnet-send-message uid "You need to select a field to use fertilizer on!"
      ]]]
end

to initialize-farmers
  create-farmers initial-farmers
  ask farmers [
    set patches-owned nobody 
  ]
  foreach field-list [
    ask one-of farmers[
      let newpatches ?
      set patches-owned (patch-set patches-owned newpatches)
    ]
  ]
end

to initialize-govs
  ;create-govs 1 [ht]
end

to ai-decide-contracts
  if (behavior-pattern = "default") [
    ask agent [
      set accepted-corn-contract false
      set accepted-switchgrass-contract false
    ]
  ]
   set ready-list lput user-id ready-list
end

to update-info-area 
    hubnet-send-clear-output user-id
    ifelse (info-view = "Economy") [
      hubnet-send-message user-id Economy-info-string self
    ]
    [
      ifelse (info-view = "Environment" )[
          hubnet-send-message user-id Environment-info-string self
      ]
      [
       ifelse (info-view = "Sustainability") [
         hubnet-send-message user-id Sustainability-info-string self
       ]
       [
         ifelse (info-view = "Ranking") [
           hubnet-send-message user-id Ranking-info-string self
         ]
         [
           
         ]]]]
    
end

to ai-reset-fields-to-plant
;  ask controllers with [is-human = false][
;    ask agent [
;      
;      ;set fields-to-plant 
;    ]
;  ]
  
  ask one-of farmers [
    foreach n-values (length field-list) [?] [
        ask farmers with [member? (one-of item ? ([field-list] of myself)) land][
            set fields-to-plant lput (item ? field-list) fields-to-plant
        ]
    ]
  ]
  
;  ask controllers with [is-human = false][
;    ask agent [
;      set fields-to-plant []
;      foreach n-values (length field-list) [?] [
;        if(member? (one-of item ? field-list) land) [
;          set fields-to-plant lput (item ? field-list) fields-to-plant
;        ]
;      ]
;    ]
;  ]
end

to ais-think
  if(ticks mod 365 >= 50 and ticks mod 365 <= 100) [
    let is-done false
    ask controllers with [role = "farmer" and not is-human] [
      ask agent [
        if (length fields-to-plant > 0) [
          ifelse(destination = nobody) [
            set destination one-of item 0 fields-to-plant
          ]
          [
            if(destination = patch-here)[
              ;move-farmers
              ask controllers with [agent = myself] [
                ifelse(behavior-pattern = "default") [
                  ifelse(random-float 1 < .5) [
                    plant-switchgrass
                  ]
                  [
                    plant-corn
                  ]
                ]
                [
                  ifelse(behavior-pattern = "corn") [
                    plant-corn 
                  ]
                  [
                    ifelse(behavior-pattern = "grass" or behavior-pattern = "switchgrass") [
                      plant-switchgrass
                    ]
                    [
                      
                    ]]
                  ]
              ]
                
              ;ask current-field [set pcolor blue]
              set fields-to-plant butfirst fields-to-plant
              ifelse (length fields-to-plant = 0) [
                set destination nobody
                set is-done true
              ]
              [
                set destination one-of item 0 fields-to-plant
              ]
              
            ]
          ]
        ]
      ]
      if (is-done and not member? user-id ready-list) [
         set ready-list lput user-id ready-list
      ]
    ]
  ]
end

;
;Adjusts the weather either through a scenario or by teacher control
;
to set-weather
  file-open weather-file
  ifelse ((file-exists? weather-file) and (not file-at-end?))[
    print weather-table
    set weather table:get weather-table file-read-line
  ]
  [
    set weather 0
  ]
  if verbose [
    show word "Weather: " weather
  ]
end

to teacher-set-weather
  if ticks mod 365 > 24 or ticks mod 365 < 100 [
    set weather table:get weather-table weather-type
  ]
  show word "Teacher set Weather: " weather
end

;;
;;Computes the range of potential spot prices
;;
to compute-price-ranges
  let corn-range-low corn-futures-price - (.1645 * corn-futures-price)
  let corn-range-high corn-futures-price + (.1645 * corn-futures-price)
  let grass-range-low switchgrass-futures-price - (.1645 * switchgrass-futures-price)
  let grass-range-high switchgrass-futures-price + (.1645 * switchgrass-futures-price)
  set corn-range (word round corn-range-low " - " round corn-range-high)
  set switchgrass-range (word round grass-range-low " - " round grass-range-high)
end

;;
;;Energy Producer determines how many contracts to offer
;;
to offer-contracts
  set corn-contract round (corn-demand / count farmers)
  set switchgrass-contract round (switchgrass-demand / count farmers)
  set corn-contract-field round (corn-contract / field-size / field-size / corn-tons-per-acre)
  set switchgrass-contract-field round (switchgrass-contract / field-size / field-size / switchgrass-tons-per-acre)
end

;;
;;Farmers accept or decline futures contracts
;;
to accept-contracts
  ask farmers [
    ifelse accepted-corn-contract = true [
      set contracted-corn corn-contract
    ]
    [
      set contracted-corn 0
    ]
    ifelse accepted-switchgrass-contract = true [
      set contracted-switchgrass switchgrass-contract
    ]
    [
      set contracted-switchgrass 0
    ]
  ]
  ask patches with [land-type = 1][
    set corn 0
  ]
end


to farmers-choose-crops
  ask farmers [
    set planted "" set production "" set contract-sales "" set spot-sales ""
    set planted (word count land with [corn = 1] " Acres Corn and " count land with [switchgrass = 1] " Acres Switchgrass")
  ]
end

;;
;;Include randomness in the growing process and also natural effects
;;
to harvest-crops
  set total-corn-grown 0
  set total-switchgrass-grown 0
  ask farmers [
    set corn-grown 0
    set switchgrass-grown 0
    foreach sort [self] of land [
      if [corn] of ? = 1 [
        ;corn grown is compounded!!!!
        ask ? [
          set last-corn-yield ((random-normal (1 + fertilizer + ([soil-health] of ? / 10) + (weather / 10)) .05) * [corn] of ? * corn-tons-per-acre)
        ]
        set corn-grown corn-grown + [last-corn-yield] of ?
      ]
      if [switchgrass] of ? >= 1 [
        ask ? [
          set last-grass-yield ((random-normal (1 + fertilizer + ([soil-health] of ? / 10) + (weather / 10)) .05) * [switchgrass] of ? * switchgrass-tons-per-acre)
        ]
        set switchgrass-grown switchgrass-grown + [last-grass-yield] of ?
      ]
    ]
    ifelse corn-grown > 0 [
      set corn-grown round corn-grown
    ]
    [
      set corn-grown 0
    ]
    ifelse switchgrass-grown > 0 [
      set switchgrass-grown round switchgrass-grown
    ]
    [
      set switchgrass-grown 0
    ]
    if verbose [
      show word "Corn Grown: " corn-grown
      show word "Grass Grown: " switchgrass-grown
    ]
    set economy-string (word economy-string "\nCorn Grown(Tons): " corn-grown "\nGrass Grown(Tons): " switchgrass-grown)
    set total-corn-grown total-corn-grown + corn-grown
    set total-switchgrass-grown total-switchgrass-grown + switchgrass-grown
    set production (word corn-grown " Tons Corn and " switchgrass-grown " Tons Switchgrass")
  ]
end

to farmers-sell-crops-complicated

  farmers-sell-for-contract
  compute-spot-prices
  control-prices
  farmers-sell-for-spot
  farmers-sell-excess-grass
  farmers-sell-excess-corn
end

to farmers-sell-for-contract
  set corn-bought 0
  set switchgrass-bought 0
  ask farmers [
    set corn-sold 0
    set switchgrass-sold 0
    set corn-short 0
    set switchgrass-short 0
  ]
  ask farmers with [accepted-corn-contract = true] [
   ; set corn-sold 0
    set corn-short 0
    set corn-bought corn-bought + corn-grown
    set corn-sold corn-contract
    if contracted-corn > corn-grown [
      set corn-short contracted-corn - corn-grown
    ]
  ]
  ask farmers with [accepted-switchgrass-contract = true] [ 
   ; set switchgrass-sold 0
    set switchgrass-short 0
    set switchgrass-bought switchgrass-bought + switchgrass-grown
    set switchgrass-sold switchgrass-contract
    if contracted-switchgrass > switchgrass-grown [
      set switchgrass-short contracted-switchgrass - switchgrass-grown
    ]
    set yearly-earnings (corn-grown * (corn-subsidy + corn-futures-price)) + (switchgrass-grown * (grass-subsidy + switchgrass-futures-price))
    if verbose [
      show (word "Sold " corn-sold " corn for " corn-futures-price " (Contract)")
      show (word "Sold " switchgrass-sold " switchgrass for " switchgrass-futures-price " (Contract)")
      show word "Earned: " yearly-earnings
    ]
    set economy-string (word economy-string "\nSold " corn-sold " corn for " corn-futures-price " (Contract) and "
      switchgrass-sold " switchgrass for " switchgrass-futures-price " (Contract)\nand Earned: " yearly-earnings)
  ]
  ask farmers [
    set contract-sales (word corn-sold " Tons Corn at $" ((round (corn-futures-price * 100)) / 100) " and " switchgrass-sold " Tons Grass at $" switchgrass-futures-price)
    set yearly-earnings yearly-earnings + (corn-sold * corn-futures-price) + (switchgrass-sold * switchgrass-futures-price)
  ]
  set corn-bought-contract corn-bought
  set switchgrass-bought-contract switchgrass-bought
  let paid-to-farmers (corn-bought * corn-futures-price) + (switchgrass-bought * switchgrass-futures-price)
  set capital (capital + (corn-bought * corn-energy * energy-price) + (switchgrass-bought * switchgrass-energy * energy-price) - producer-costs - paid-to-farmers)
end

to compute-spot-prices
  let excess-corn 0
  let excess-grass 0
  ifelse total-corn-grown > 0 and count patches with [corn = 1] > 0 [
    set excess-corn total-corn-grown / ((count patches with [corn = 1]) * corn-tons-per-acre)
    set corn-spot-price round (corn-futures-price / excess-corn)
  ]
  [
    set excess-corn 0
    set corn-spot-price corn-futures-price
  ]
  set corn-cons-price corn-spot-price
  
  ifelse total-switchgrass-grown > 0 and count patches with [switchgrass >= 1] > 0 [
    set excess-grass total-switchgrass-grown / (sum [switchgrass] of patches * switchgrass-tons-per-acre)
    set switchgrass-spot-price round (switchgrass-futures-price / excess-grass)
  ]
  [
    set excess-grass 0
    set switchgrass-spot-price switchgrass-futures-price
  ]
  if verbose [
    show word "Available Corn: " total-corn-grown
    show word "Available Grass " total-switchgrass-grown
    show word "Excess Corn: " excess-corn
    show word "Excess Grass: " excess-grass
  ]
end

to farmers-sell-for-spot
  set corn-bought-spot 0
  set switchgrass-bought-spot 0
  let corn-stover-per-acre 2
  
  ask farmers [set corn-sold-spot 0 
    set switchgrass-sold-spot 0
    set corn-stover (corn-grown / corn-tons-per-acre) * 2
    
    ]
  while [corn-bought < corn-demand and any? farmers with [corn-sold < corn-grown]] [
    ask one-of farmers with [corn-sold < corn-grown] [
      set corn-sold corn-sold + 1
      set corn-bought corn-bought + 1
      set corn-bought-spot corn-bought-spot + 1
      set corn-sold-spot corn-sold-spot + 1
    ]
  ]
  while [switchgrass-bought < switchgrass-demand and any? farmers with [switchgrass-sold < switchgrass-grown]] [
    ask one-of farmers with [ switchgrass-sold < switchgrass-grown][
        set switchgrass-sold switchgrass-sold + 1
        set switchgrass-bought switchgrass-bought + 1
        set switchgrass-bought-spot switchgrass-bought-spot + 1
        set switchgrass-sold-spot switchgrass-sold-spot + 1
    ]
  ]
  if any? farmers with [switchgrass-sold < switchgrass-grown] [
    ask farmers with [switchgrass-sold < switchgrass-grown] [
      ;print (word "sell for spot has leftover grass; grown " switchgrass-grown " sold " switchgrass-sold " spot " switchgrass-sold-spot)
    ]
  ]
  ask farmers [
    set yearly-earnings yearly-earnings + (corn-sold-spot * (corn-subsidy + corn-spot-price)) + (switchgrass-sold-spot * (grass-subsidy + switchgrass-spot-price)
      + switchgrass-spot-price * corn-stover)

    if verbose [
    show (word "Sold " corn-sold-spot " corn for " corn-spot-price " (Spot)")
    show (word "Sold " switchgrass-sold-spot " switchgrass for " switchgrass-spot-price " (Spot)")
    show (word "Sold " corn-stover " corn stover for " switchgrass-spot-price " (Spot)")
    ]
    set economy-string (word economy-string "\nSold " corn-sold-spot " corn for " corn-spot-price " (Spot)"
    "\nSold " switchgrass-sold-spot " switchgrass for " switchgrass-spot-price " (Spot)"
    "\nSold " corn-stover " corn stover for " switchgrass-spot-price " (Spot)")
    
  ]
  let paid-to-farmers (corn-bought-spot * corn-spot-price) + (switchgrass-bought-spot * switchgrass-spot-price)
  set capital (capital + (corn-bought-spot * corn-energy * energy-price) + (switchgrass-bought-spot * switchgrass-energy * energy-price) - producer-costs - paid-to-farmers)
end


;
;The Market for Corn clears through consumption
;
to farmers-sell-excess-corn
  set corn-bought-secondary 0
  ask farmers [set corn-sold-cons 0]
  ask farmers with [corn-sold < corn-grown] [
      let extra-corn corn-grown - corn-sold
      set corn-bought corn-bought + extra-corn
      set corn-sold-cons corn-sold-cons + extra-corn
      set corn-bought-secondary corn-bought-secondary + extra-corn
      set corn-sold corn-grown 
  ]
  ask farmers [
    let new-switchgrass-amt (count land with [(land-type = 1) and (switchgrass > 0) and (last-switchgrass = 0)])
    let old-switchgrass-amt (count land with [(land-type = 1) and (switchgrass > 0) and (last-switchgrass != 0)])
    set yearly-earnings yearly-earnings + (corn-sold-cons * (corn-subsidy + corn-cons-price))
   if verbose [
    show (word "total revenue this year: " yearly-earnings)
    ;calculate from tons
    show (word "planted " count land with [land-type = 1 and corn = 1] " acres corn at " cost-per-acre-corn ", " new-switchgrass-amt " new switchgrass for " cost-per-acre-switchgrass " and " old-switchgrass-amt " old switchgrass for " switchgrass-harvest-cost " totaling " (-(count land with [land-type = 1 and corn = 1] * cost-per-acre-corn) - (new-switchgrass-amt * cost-per-acre-switchgrass)  - (old-switchgrass-amt * switchgrass-harvest-cost) - (count land with [fertilizer = 1] * cost-per-acre-fertilizer)) " incl fertilizer ")
    show (word "aka " (count land with [land-type = 1 and corn = 1] * corn-tons-per-acre) " tons corn at " (cost-per-acre-corn / corn-tons-per-acre) " and " (new-switchgrass-amt * switchgrass-tons-per-acre) " switchgrass for " (cost-per-acre-switchgrass / switchgrass-tons-per-acre) " totaling " (-(count land with [land-type = 1 and corn = 1] * cost-per-acre-corn) - (new-switchgrass-amt * cost-per-acre-switchgrass) - (count land with [fertilizer = 1] * cost-per-acre-fertilizer)) " incl fertilizer ")
   ]
   
   set economy-string (word economy-string "\ntotal revenue this year: " yearly-earnings
     "\nplanted " count land with [land-type = 1 and corn = 1] " acres corn at " cost-per-acre-corn ", " new-switchgrass-amt " new switchgrass for " cost-per-acre-switchgrass " and " old-switchgrass-amt " old switchgrass for " switchgrass-harvest-cost " totaling " (-(count land with [land-type = 1 and corn = 1] * cost-per-acre-corn) - (new-switchgrass-amt * cost-per-acre-switchgrass)  - (old-switchgrass-amt * switchgrass-harvest-cost) - (count land with [fertilizer = 1] * cost-per-acre-fertilizer)) " incl fertilizer "
    "\naka " (count land with [land-type = 1 and corn = 1] * corn-tons-per-acre) " tons corn at " (cost-per-acre-corn / corn-tons-per-acre) " and " (new-switchgrass-amt * switchgrass-tons-per-acre) " switchgrass for " (cost-per-acre-switchgrass / switchgrass-tons-per-acre) " totaling " (-(count land with [land-type = 1 and corn = 1] * cost-per-acre-corn) - (new-switchgrass-amt * cost-per-acre-switchgrass) - (count land with [fertilizer = 1] * cost-per-acre-fertilizer)) " incl fertilizer ")
   
    set yearly-earnings yearly-earnings - (count land with [land-type = 1 and corn = 1] * cost-per-acre-corn) - (new-switchgrass-amt * cost-per-acre-switchgrass) - (old-switchgrass-amt * switchgrass-harvest-cost)
        - (count land with [fertilizer = 1] * cost-per-acre-fertilizer)
    if verbose [
      show (word "also paid for " corn-short " corn at " (corn-spot-price - corn-futures-price) " and " switchgrass-short " grass at " (switchgrass-spot-price - switchgrass-futures-price))
      show (word "Sold " corn-sold-cons " corn for consumption")
    ]
    set economy-string (word economy-string "\nalso paid for " corn-short " corn at " (corn-spot-price - corn-futures-price) " and " switchgrass-short " grass at " (switchgrass-spot-price - switchgrass-futures-price)
    "\nSold " corn-sold-cons " corn for consumption and " switchgrass-sold-secondary " switchgrass on the secondary market")
    set yearly-earnings round (yearly-earnings - (corn-short * (corn-spot-price - corn-futures-price)) - (switchgrass-short * (switchgrass-spot-price - switchgrass-futures-price)))
    if verbose [
      show (word "profit this year: " yearly-earnings)
    ]
    set economy-string (word economy-string "\nprofit this year: " yearly-earnings)
    set earnings earnings + yearly-earnings
    
    set spot-sales (word (corn-sold-spot + corn-sold-cons) " Tons Corn at $" ((round (corn-spot-price * 100)) / 100)" and " (switchgrass-sold-spot + switchgrass-sold-secondary) " Tons Switchgrass at $" switchgrass-spot-price)
    set last-year-grown (word total-corn-grown " Tons of Corn grown and " total-switchgrass-grown " Tons of Switchgrass grown")
    set last-year-contract (word corn-bought-contract " Tons of Corn and " switchgrass-bought-contract " Tons of Switchgrass sold for contract")
    set last-year-spot (word corn-bought-spot " Tons of Corn and " switchgrass-bought-spot " Tons of Switchgrass sold for spot")
    set last-year-secondary (word corn-bought-secondary " Tons of Corn and " switchgrass-bought-secondary " Tons of Switchgrass sold on Secondary market ")

  ]
end

;;
;;Update the environment based on growing decisions
;;
to environment-change
  ask patches with [land-type = 1] [
    if corn = 1 [set soil-health (soil-health - 2)]
    if switchgrass >= 1 [set soil-health (soil-health + 1)]
    if fallowed = 1 [set soil-health (soil-health + 2)]
    if fertilizer = 1 [set soil-health (soil-health - 1)]
  ]
  diffuse soil-health .75
  set total-emissions sum [emissions] of patches
end

;;
;;Randomly adjust energy and food prices
;;
to econ-change
  set energy-price energy-price + (random 4) - 2 ;rough price per gJ/ethanol
  if energy-price > 60 [
   set energy-price 60 
  ]
  if energy-price < 30 [
   set energy-price 30 
  ]  
  set corn-food-price (corn-food-price + ((random-float 1) - .5))
  if (corn-food-price > 6.25)[
    set corn-food-price 6.25 
  ]
  if (corn-food-price < 2) [
    set corn-food-price 2
  ]
end

;;
;; This will allow the government to change the subsidies for crops. It can be controlled by the teacher or be automatic
;;
to gov-intervene ; set subsidies to make corn/switchgrass amounts equal
  control-prices
  
;  if auto-government[
;    let total-corn sum [corn] of patches
;    let total-switchgrass sum [switchgrass] of patches
;    if total-corn > total-switchgrass [
;      ; print switchgrass-subsidy
;      set switchgrass-subsidy (switchgrass-subsidy + ((total-corn - total-switchgrass)) / 100)
;    ]
;    if total-switchgrass > total-corn [
;      ;print corn-subsidy
;      set corn-subsidy ((corn-subsidy + (total-switchgrass - total-corn)) / 100)
;    ]
;    set corn-subsidy (corn-subsidy + random(20) - 10)
;    if corn-subsidy < 0 [set corn-subsidy 0]
;    set switchgrass-subsidy (switchgrass-subsidy + random(20) - 10)
;    if switchgrass-subsidy < 0 [set switchgrass-subsidy 0]
;  ]
end

to change-perspective
  if hubnet-message = "My Land" [
    let not-my-land nobody
    ask controllers with [user-id = hubnet-message-source] [
      ask agent [
        let landlist [self] of land
        set not-my-land patches with [not member? self landlist]
      ]
      hubnet-send-follow hubnet-message-source agent 20
      hubnet-send-override hubnet-message-source not-my-land "pcolor" [grey] 
    ]
  ]
  if hubnet-message = "World" [
    hubnet-clear-overrides hubnet-message-source
    hubnet-reset-perspective hubnet-message-source
  ]
end

to control-prices
  if(price-controls) [
    if(switchgrass-futures-price > max-grass-price) [
      set switchgrass-futures-price max-grass-price
    ]
    if(switchgrass-futures-price < min-grass-price) [
      set switchgrass-futures-price min-grass-price
    ]
    if(switchgrass-spot-price > max-grass-price) [
      set switchgrass-spot-price max-grass-price
    ]
    if(switchgrass-spot-price < min-grass-price) [
      set switchgrass-spot-price min-grass-price
    ]
    if(corn-futures-price > max-corn-price) [
      set corn-futures-price max-corn-price
    ]
    if(corn-futures-price < min-corn-price) [
      set corn-futures-price min-corn-price
    ]
    if(corn-spot-price > max-corn-price) [
      set corn-spot-price max-corn-price
    ]
    if(corn-spot-price < min-corn-price) [
      set corn-spot-price min-corn-price
    ]
  ]
end

;;
;;Update what is displayed on the teacher's screen
;;
to update-plot
  let total-fields sum ([patches-owned] of farmers)
  set-current-plot "prices"
  set-current-plot-pen "perennial grass"
  plotxy (year - 1) switchgrass-futures-price + grass-subsidy
  set-current-plot-pen "corn"
  plotxy (year - 1) corn-futures-price + corn-subsidy
  
  set-current-plot "farmer earnings"
  foreach sort controllers [
    ask ? [
    if(is-human)[
      set-current-plot-pen user-id
      plotxy (year - 1) [earnings] of agent
    ]
    ]
  ]
;  set-current-plot-pen "f1"
;  plotxy (year - 1) [earnings] of item 0 farmer-list
;  if(count controllers with [role = "farmer"] > 1)[
;    set-current-plot-pen "f2"
;    plotxy (year - 1) [earnings] of item 1 farmer-list
;    
;    if(count controllers with [role = "farmer"] > 2)[
;      set-current-plot-pen "f3"
;      plotxy (year - 1) [earnings] of item 2 farmer-list
;      
;      if(count controllers with [role = "farmer"] > 3)[
;        set-current-plot-pen "f4"
;        plotxy (year - 1) [earnings] of item 3 farmer-list
;        
;        if(count controllers with [role = "farmer"] > 4)[
;          set-current-plot-pen "f5"
;          plotxy (year - 1) [earnings] of item 4 farmer-list
;          
;          if(count controllers with [role = "farmer"] > 5)[
;            set-current-plot-pen "f6"
;            plotxy (year - 1) [earnings] of item 5 farmer-list
;          ]
;        ]
;      ]
;    ]
;  ]
  ;set-current-plot "Emissions"
  ;plotxy (year - 1) total-emissions

  set-current-plot "sustainability"
  if (sustainability-index > 0)[
    plotxy (year - 1) sustainability-index
    
    ]
  
  set-current-plot "sustainability components"
  radar-chart sustainability-components
  
  set-current-plot "individual sustainability"
  set data-list []
  set colors-list []
  ask controllers with [role = "farmer"] [
    set data-list lput tri-score-components data-list
    set colors-list lput [color] of agent colors-list
  ]
  if(length data-list > 0 and length colors-list > 0) [ multi-radar-chart data-list colors-list ]
end

to recompute-field-colors 
  set field-color-vals (n-values (length field-list) [0])
  foreach n-values (length field-list) [?] [
    let this-field (item ? field-list)
    ask one-of this-field [
      if (corn > switchgrass) [
        set field-color-vals replace-item ? field-color-vals corn-color-for (sum([last-corn-yield] of this-field) / count this-field)
      ]
      if (switchgrass > corn) [
        set field-color-vals replace-item ? field-color-vals switchgrass-color-for last-grass-yield
      ]
      if (switchgrass = corn) [
        set field-color-vals replace-item ? field-color-vals brown
      ]
    ]
  ]
  
end

;;
;;Redraw the farm map
;;
to recolor-background
  ask controllers with [role = "farmer"] [hubnet-clear-override user-id patches "plabel"]
  if(coloring = "land use")[
;    ask patches [
;      ifelse (land-type = 0)[
;        set pcolor green
;      ]
;      [ifelse (land-type = 1)[
;        if(corn > switchgrass)[
;          let fiel field-of-patch self
;          let avg-health sum([last-corn-yield] of fiel) / (count fiel)
;          ifelse(last-corn-yield > 0 ) [
;            set pcolor scale-color yellow avg-health (1.2 * corn-tons-per-acre) 3
;            print avg-health
;          ]
;          [
;           set pcolor yellow 
;          ]
;        ]
;        if(switchgrass > corn)[
;          ifelse(last-grass-yield > 0) [
;            let fiel field-of-patch self
;            let avg-health sum([last-grass-yield] of fiel) / (count fiel)
;            set pcolor scale-color red avg-health (1.2 * switchgrass-tons-per-acre) 3.5
;          ]
;          [
;           set pcolor red 
;          ]
;        ]
;        if (switchgrass = corn)[
;          ifelse(switchgrass = 0 and corn = 0)[
;            set pcolor brown
;            set fallowed 1
;          ]
;          [
;            ifelse(random-float(1) < .5)[
;              set pcolor red
;            ]
;            [
;              set pcolor yellow
;            ]
;          ]
;        ]
;      ]
;      [set pcolor blue]]
;    ]

    ask patches with [land-type = 0] [
      set pcolor green
    ]
    foreach n-values length field-list [?] [
      ask item ? field-list [
        set pcolor item ? field-color-vals
      ]
    ]
  ]
  
  if(coloring = "soil health") [
    let max-health ([soil-health] of max-one-of (patches with [land-type = 1]) [soil-health])
    let min-health ([soil-health] of min-one-of (patches with [land-type = 1]) [soil-health])
    if(min-health = 0 and max-health = 0) [
      set max-health 1
    ]
    ask patches [
      set pcolor scale-color brown soil-health min-health max-health
    ]
  ]
  
  if(coloring = "land ownership") [
   ask farmers [
    ask land [
     set pcolor [color] of myself 
    ] 
   ] 
  ]
end

to farmers-sell-excess-grass
  set switchgrass-bought-secondary 0
  ask farmers [
    set switchgrass-sold-secondary 0
    if (switchgrass-grown > (switchgrass-sold)) [
      ;print (word "sell for spot has leftover grass(xs); grown " switchgrass-grown " sold " switchgrass-sold " spot " switchgrass-sold-spot)
      set switchgrass-sold-secondary switchgrass-grown - switchgrass-sold
      set switchgrass-sold switchgrass-sold + switchgrass-sold-secondary
      set switchgrass-bought-secondary switchgrass-bought-secondary + switchgrass-sold-secondary
      if verbose [
        show(word "Sold " switchgrass-sold-secondary " Grass on secondary market, at spot price ")
      ]
      set yearly-earnings yearly-earnings + (switchgrass-sold-secondary * switchgrass-spot-price)
    ]
  ]
end

to generate-world
  assign-land
  ask farmers [
    fill-with-grid-fields land 
  ]
;  let maxTime 2
;  let time 0
;  while [length field-list < (initial-farmers * fields-per-farmer) and time < maxTime] [
;    ask farmers [
;      fill-with-fields land 
;    ]
;    set time time + 1
;  ]
;  if time >= maxTime [
;    setup
;  ]
end

to assign-land
  let facto closest-factors initial-farmers
  let xDiv (item 0 facto) - 1
  let yDiv (item 1 facto) - 1
  
  let xStep max-pxcor / ( xDiv + 1)
  let yStep max-pycor / ( yDiv + 1)
  
  foreach n-values (yDiv + 1) [?] [
    let counter ?
    foreach n-values (xDiv + 1) [?] [
      let pStart patch (min-pxcor + (? * xStep * 2)) (max-pycor - (counter * yStep * 2))
      ask pStart [set pcolor red]
      
      let pEnd patch (min-pxcor + ((? + 1) * xStep * 2)) (max-pycor - ((counter + 1) * yStep * 2))
      ask pEnd [set pcolor blue]
      
      ask one-of farmers with [land = nobody] [
        set land patches-in-range pStart pEnd
        ;      print patches-in-range pStart pEnd
      ]
    ] 
  ]
end

to fill-with-grid-fields [area]
  
  let minXWidth 999999999
  let minYWidth 999999999
  
  ask farmers [
    if (area-width land) < minXWidth [set minXWidth (area-width land)]
    if (area-height land) < minYWidth [set minYWidth (area-height land)]
  ]
  
 ; ask farmers [
  let xFields floor(minXWidth / field-size)
  let yFields floor(minyWidth / field-size)
  let totalFields 0
  foreach n-values yFields [?] [
    let i ?
    foreach n-values xFields [?] [
      if(totalFields < fields-per-farmer) [
        ; show (word "(" ? ", " i ")" (area-width land) ","  (area-height land))
        let startP get-item-xy land (? + (? * field-size)) (i + (i * field-size)) (area-width land) (area-height land) 0
        let endP nobody
        ask startP [
          ;          set pcolor green
          set endP patch-at (field-size - 1) (-1 * field-size + 1)
          let endColor nobody
          if(endP != nobody and member? endP [land] of myself) [
            ask endP [
              ;set pcolor yellow
              set endcolor patch-at -1 1
            ]
            let tempfield (patches-in-range-inclusive startP endP)
            set field-list lput tempfield field-list
            let col one-of base-colors
            ask tempfield [
              set land-type 1
              set pcolor col
            ]
          ]
        ]
        set totalFields totalFields + 1
      ]
    ]
  ]
end

to recolor-button
  recompute-field-colors
  recolor-background
end

to fill-with-fields [area]
  let arrangementFound false
  let arrangementTimeout 0
  let maxArrange 100
  let maxIndividual 100
  while [not arrangementFound and arrangementTimeout < maxArrange] [
    let validArrangement true 
    foreach n-values fields-per-farmer [?][
      if(validArrangement) [
        let validLoc false
        let timeout 0
        while[not validLoc and timeout < maxIndividual] [
          let start-p one-of land with [land-type = 0]
          let end-p nobody
          ask start-p [
            set end-p patch-at (field-size + 1) (-1 * (field-size + 1))
            if (end-p != nobody) [
              let tempfield patches-in-range start-p end-p
              if((patch-set tempfield area) = area) [
                let ol1 nobody
                let ol2 nobody
                ask start-p [set ol1 patch-at -1 1]
                ask end-p [set ol2 patch-at 1 -1]
                if (ol1 != nobody and ol2 != nobody) [
                  if(not any? (patches-in-range ol1 ol2) with [land-type != 0]) [
                    set validLoc true
                    ask tempfield [set land-type 1]
                    set field-list lput tempfield field-list
                  ]
                ]
              ]
            ] 
          ]
          set timeout timeout + 1
        ]
        if timeout >= maxIndividual 
        [
          set validArrangement false
          set field-list []
        ]
      ]
    ]
    ifelse(not validArrangement)
    [
      ask area [set land-type 0 ]
      set arrangementTimeout arrangementTimeout + 1
      set field-list []
    ]
    [
     set arrangementFound true 
    ]
    
  ]
  if(arrangementTimeout >= maxArrange)[
   print "failed to pack fields" 
  ]
end

to show-fields 
  foreach field-list [
    ask ?[
      set pcolor orange
    ]
    wait 1
    ask ?[
      set pcolor brown 
    ]
    wait .5
  ]
end

;;
;;Update the information on the Clients' display
;;
to update-clients
  compute-available-energy
  compute-proj-revenue
  
  ask controllers with [role = "farmer" and is-human = true] [
    hubnet-send user-id "Earnings" [earnings] of agent
    hubnet-send user-id "players ready" (word length ready-list " / " expected-readies)
    hubnet-send user-id "Price of Corn (Ton)" corn-futures-price
    hubnet-send user-id "Price of Grass (Ton)" switchgrass-futures-price
    hubnet-send user-id "Cost of Corn (Ton)" round (cost-per-acre-corn / corn-tons-per-acre)
    hubnet-send user-id "Corn Tons per Acre (base)" corn-tons-per-acre
    hubnet-send user-id "Grass Tons per Acre (base)" switchgrass-tons-per-acre
    hubnet-send user-id "Accept Corn Contract" [accepted-corn-contract] of agent
    hubnet-send user-id "Accept Switchgrass Contract" [accepted-switchgrass-contract] of agent
    hubnet-send user-id "Initial Cost of Grass (Ton)" round (cost-per-acre-switchgrass / switchgrass-tons-per-acre)
    hubnet-send user-id "Offered Corn Contract Amount (Tons)" corn-contract
    hubnet-send user-id "Offered Grass Contract Amount (Tons)" switchgrass-contract
;    hubnet-send user-id "Range of Possible Corn Prices" corn-range
;    hubnet-send user-id "Range of Possible Switchgrass Prices" switchgrass-range
    hubnet-send user-id "ready" (member? user-id ready-list)
    hubnet-send user-id "Production" [production] of agent
    hubnet-send user-id "Contract Sales" [contract-sales] of agent
    hubnet-send user-id "Spot Sales" [spot-sales] of agent
    hubnet-send user-id "Planted" [planted] of agent
    hubnet-send user-id "Sustainability Score" score
    hubnet-send user-id "Sustainability Rank" rank
    hubnet-send user-id "Next Event" next-event
    ;update-info-area
  ]
end

to compute-available-energy
  set available-corn 0
  set available-switchgrass 0
  ask farmers[

     set available-corn (available-corn + count land with [land-type = 1 and corn = 1]) 
     set available-switchgrass (available-switchgrass + sum [switchgrass] of land with [land-type = 1])

  ]
  set available-corn-energy (available-corn * corn-energy)
  set available-switchgrass-energy (available-switchgrass * switchgrass-energy)
end

to compute-proj-revenue
  ask en-producers[

    let buy-corn ((corn-to-buy / 100) * available-corn)
    let buy-switchgrass ((switchgrass-to-buy / 100) * available-switchgrass)
    if(buy-corn > available-corn) [
      set buy-corn available-corn 
    ]
    if(buy-switchgrass > available-switchgrass) [
      set buy-switchgrass available-switchgrass
    ]
    let paid-to-farmers (buy-corn * corn-futures-price) + (buy-switchgrass * switchgrass-futures-price)
    set proj-revenue ((buy-corn * corn-energy * energy-price) + (buy-switchgrass * switchgrass-energy * energy-price) - producer-costs - paid-to-farmers)
  ]
end

to reset-info-strings
  ask farmers [
   set economy-string ""
   set environment-string ""
   set ranking-string "" 
  ]
end

to continue
  set is-waiting false
end

to market-adjust
  let cornp 0
  let grassp 0
  compute-demand
  compute-supply
    
  ifelse (corn-demand = corn-supply)
  [
    
  ]
  [
    ifelse (corn-demand > corn-supply) 
    [ 
      let undersupp 0
      ifelse(corn-supply > 0)[
        set undersupp ((corn-demand - corn-supply) / corn-supply)
      ]
      [
        set undersupp 1
      ]
      let adj-percent (undersupp * market-elasticity-corn)
      if(price-controls) [
       ; set adj-percent adj-percent * ((1 - ((corn-futures-price - initial-corn-price) / (max-corn-price - initial-corn-price) / 4)) ^ 2)
      ]
      ;print adj-percent
      set corn-futures-price round (corn-futures-price + (adj-percent * corn-futures-price) + random-normal 0 5)
    ]
    [
      let oversupp 0
      if (corn-supply > 0) [set oversupp ((corn-supply - corn-demand) / corn-supply)]
      let adj-percent (oversupp * market-elasticity-corn)
      set corn-futures-price round (corn-futures-price - (adj-percent * corn-futures-price))
      if corn-futures-price < 1 [ set corn-futures-price 1]
      
      ;print oversupp
    ]
  ]
  
  
  ifelse (switchgrass-demand = switchgrass-supply)
  [
    
  ]
  [
    ifelse (switchgrass-demand > switchgrass-supply) 
    [ 
      let undersupp 0
      ifelse(switchgrass-supply > 0)[
        set undersupp ((switchgrass-demand - switchgrass-supply) / switchgrass-supply)
      ]
      [
        set undersupp 1 
      ]
      let adj-percent (undersupp * market-elasticity-switchgrass)
      if(price-controls) [
       ; set adj-percent adj-percent * ((1 - ((switchgrass-futures-price - initial-grass-price) / (max-grass-price - initial-grass-price) / 4)) ^ 2)
      ]
      set switchgrass-futures-price round (switchgrass-futures-price + (adj-percent * switchgrass-futures-price))
    ]
    [
      let oversupp ((switchgrass-supply - switchgrass-demand) / switchgrass-supply)
      let adj-percent (oversupp * market-elasticity-switchgrass)
      set switchgrass-futures-price round (switchgrass-futures-price - (adj-percent * switchgrass-futures-price))
      if switchgrass-futures-price < 1 [set switchgrass-futures-price 1]
    ]
  ]
  
  
  if noisy-prices [
   let grass-noise random-normal 0 (10)
   let corn-noise random-normal 0 (10) ;corn-futures-price * .05
   if verbose[
     show (word "grass noise: " grass-noise "corn noise: " corn-noise)
   ]
   set corn-futures-price round (corn-futures-price + corn-noise) 
   set switchgrass-futures-price round (switchgrass-futures-price + grass-noise)
  ]
end

to compute-demand
  let corn-profit ((corn-energy * energy-price) - (corn-futures-price * variable-cost-corn))
  let grass-profit ((switchgrass-energy * energy-price) - (switchgrass-futures-price * variable-cost-switchgrass ))
  let profit-ratio grass-profit / corn-profit
;  if profit-ratio < 1 [
;    set profit-ratio corn-profit / grass-profit
;  ]
  if verbose [
     show (word "Corn profit: " corn-profit)
    show (word "Grass profit: " grass-profit)
  ]
  ifelse grass-profit <= 0 
  [
;    set corn-demand (count patches with [land-type = 1]) * ((count controllers with [user-id != 0]) / count controllers)
    set corn-demand count patches with [land-type = 1]
;    set corn-demand count ([land] of farmers)
    set switchgrass-demand 0
  ]
  [
    ;set corn-demand round ((count patches with [land-type = 1])* ((count controllers with [user-id != 0]) / count controllers) / 2 * corn-profit / grass-profit) 
    ifelse (corn-profit > grass-profit) [
      ;set corn-demand round ((count patches with [land-type = 1]) * (1 / (corn-profit / grass-profit))) 
      set corn-demand round ((count patches with [land-type = 1] / 2) + ((count patches with [land-type = 1] / 2) * (1 - (1 / (corn-profit / grass-profit))) * 1))
    ][ifelse corn-profit < grass-profit [
      ;set corn-demand round ((count patches with [land-type = 1]) * (1 - (1 / (grass-profit / corn-profit))))
      set corn-demand round ((count patches with [land-type = 1] / 2) - ((count patches with [land-type = 1] / 2) * (1 - (1 / (grass-profit / corn-profit))) * 1))
    ][ set corn-demand round (count patches with [land-type = 1] / 2 )]
    ]]
    
   
  ifelse corn-profit <= 0 
  [
    set switchgrass-demand count patches with [land-type = 1] * 1.15

;    set switchgrass-demand round (count patches with [land-type = 1] / 2 * grass-profit / corn-profit) 
    set corn-demand 0
  ]
  [
    ;set switchgrass-demand round (count patches with [land-type = 1] * ((count controllers with [user-id != 0]) / count controllers) / 2 * grass-profit / corn-profit) 
    ;set switchgrass-demand 1.1 * ((count patches with [land-type = 1]) * (grass-profit / corn-profit))
     ifelse (corn-profit > grass-profit) [
      set switchgrass-demand round ((count patches with [land-type = 1] / 2) - ((count patches with [land-type = 1] / 2) * ((1 / (corn-profit / grass-profit)) * 1)))
    ][ifelse corn-profit < grass-profit [
      set switchgrass-demand round ((count patches with [land-type = 1] / 2) + ((count patches with [land-type = 1] / 2) * (1 - (1 / (grass-profit / corn-profit)) * 1)))
    ][ set switchgrass-demand round (count patches with [land-type = 1] / 2 ) * 1]
    ]]
  
  
  set corn-demand corn-demand * corn-tons-per-acre
  set switchgrass-demand switchgrass-demand * switchgrass-tons-per-acre
  
  if verbose[
    show word "Corn Demand: " corn-demand
    show word "Grass Demand: " switchgrass-demand
 ]
end

to compute-supply
  set corn-supply total-corn-grown
  set switchgrass-supply total-switchgrass-grown
  if verbose [
    show word "Corn Supply: " corn-supply
    show word "Grass Supply: " switchgrass-supply
  ]
  set last-corn-amt (count patches with [corn = 1])
  set last-switchgrass-amt (sum [switchgrass] of patches)
  ask farmers [
    ask land with [land-type = 1][
      set last-corn corn ;set corn 0 
      set last-switchgrass switchgrass
      if switchgrass < max-switchgrass-yield and switchgrass > 0 [
        set switchgrass switchgrass * switchgrass-growth-constant
        if switchgrass > max-switchgrass-yield [set switchgrass max-switchgrass-yield]
      ]
    ]
  ]
end


to-report consumer-demand  
  let d (1000 * (.95)^(corn-futures-price / 10))
  set d d - 10 - random(10)
  ifelse (d < 0) [report 0]
  [report round d]
end

;;
;;Produce the summary output on the teacher's display
;;
to print-summary
  output-type (word "\n\n\nAt the end of year " year ":\n\n")
  output-type (word "The Energy Producer bought:\n")
  output-type (word corn-bought " Corn and " switchgrass-bought " Switchgrass\n\n")
  foreach sort farmers [
    ask ? [
      output-type (word "Farmer " (farmer-id + 1) ":\n")
      output-type (word "Planted " (count land with [corn = 1]) " Acres of Corn and " (count land with [switchgrass = 1]) " Acres of Switchgrass\n")
      output-type (word "Produced " corn-grown " Tons of Corn and " switchgrass-grown " Tons of Switchgrass\n")
      output-type (word "Sold " corn-sold " Tons of Corn and " switchgrass-sold " Tons of Switchgrass\n")
      output-type (word "Earned " yearly-earnings "\n\n")
    ]
  ]
end

to whos-not-ready
  print filter [member? ? ready-list] [user-id] of controllers
end

to move-farmers
  ask farmers[
   if (destination != nobody and destination != 0) [
     if patch-here != destination [
       face destination
       fd 1
     ]
     
     if (patch-here = destination)[
      if [land-type] of patch-here = 1 [
        set current-field field-of-patch patch-here
        if(manage-individual) [
          let client-id [user-id] of owner-of self
          if(current-field != nobody) [
;            hubnet-send client-id "switchgrass to corn ratio" [corn-percent] of one-of current-field
;            hubnet-send client-id "fields to plant" [100 - fallow-percent] of one-of current-field
          ]
        ]
      ]
      ;set destination nobody
     ] 
   ] 
  ]
end

to blink-area [client-turtle area]
  hubnet-send-override ([user-id] of client-turtle) area "pcolor" [cyan]
  hubnet-clear-override ([user-id] of client-turtle) area "pcolor"
end

to allocate-fields
  ask farmers [set patches-owned nobody]

  let curr-item 0
  foreach field-list [
   ifelse (any? farmers with [patches-owned = nobody]) [ ask one-of farmers with [patches-owned = nobody] [set patches-owned (patch-set patches-owned ?) ] ]
   [ask (min-one-of farmers [count patches-owned]) [set patches-owned (patch-set patches-owned ?) ] ]
  ]
end

to compute-s-index
  set sustainability-components replace-item 0 sustainability-components ((1 * (sum [soil-health] of patches with [land-type = 1]/ count patches with [land-type = 1]) + 5))
  set sustainability-components replace-item 1 sustainability-components ((1 * (total-emissions / (50 * initial-farmers))))
  set sustainability-components replace-item 2 sustainability-components ((1 * (crops-en-amt / (10000 * initial-farmers))))
  set sustainability-components replace-item 3 sustainability-components ((1 * (crops-econ-val / (20000 * initial-farmers))))
  set sustainability-index sum sustainability-components
end

to compute-individual-s-index
  if role = "farmer" [
    let all-fields ([land] of agent) with [land-type = 1]
    set score-components replace-item 0 score-components (1 * (sum [soil-health] of all-fields  / count all-fields) + 5 )
    set score-components replace-item 1 score-components (1 * 10 - (sum [emissions] of all-fields / max-emissions agent * 10)) 
    set score-components replace-item 2 score-components (1 * crops-individual-en agent / max-energy-prod agent * 10)
    set score-components replace-item 3 score-components (1 * crops-individual-val agent / max-econ-prod agent * 10)
    foreach n-values (length score-components) [?] [
      if item ? score-components < 0 [
        set score-components replace-item ? score-components -.001
      ]
    ]
    set score sum score-components
    set score round (score * 10)
  ]
end

to compute-individual-s-triangle
  ;0 = social
  ;1 = environmental;
  ;2 = economic
  
;  if role = "farmer" [
;    set tri-score-components replace-item 0 tri-score-components (item 2 score-components)
;    set tri-score-components replace-item 1 tri-score-components ((item 0 score-components + item 1 score-components) / 2)
;    set tri-score-components replace-item 2 tri-score-components (item 3 score-components)
;  ]
  if role = "farmer" [
    let profits-per-acre ( [yearly-earnings] of agent / count ([land] of agent) with [land-type = 1])
    if verbose [
      show (word self " profits-per-acre " profits-per-acre) 
    ]
    ifelse (profits-per-acre < 100) [
      set tri-score-components replace-item 2 tri-score-components 1
    ]
    [
      ifelse (profits-per-acre < 250) [
        set tri-score-components replace-item 2 tri-score-components 3
      ]
      [ 
        ifelse (profits-per-acre < 350) [
          set tri-score-components replace-item 2 tri-score-components 5
        ]
        [   
          ifelse (profits-per-acre < 500) [
            set tri-score-components replace-item 2 tri-score-components 7
          ]
          [
            set tri-score-components replace-item 2 tri-score-components 9
          ]]]]
    
    let corn-field-count count ([land] of agent) with [corn > 0]
    ;let switch-count (count land with [switchgrass > 0])
    let non-corn-count (count ([land] of agent) with [land-type = 1] - corn-field-count)
    let env-score (corn-field-count * 1 + non-corn-count * 4) / count ([land] of agent) with [land-type = 1]
    set tri-score-components replace-item 1 tri-score-components env-score
    
    let social-score 0
    let gini gini-coefficient [earnings] of farmers
    ifelse gini < .5 [
      set social-score 11 - 20 * gini
    ]
    [
      set social-score 1
    ]
    ifelse (inequality-social-score) [
      set tri-score-components replace-item 0 tri-score-components (round social-score)
    ]
    [
     set tri-score-components replace-item 0 tri-score-components (item 2 score-components) 
    ]
    
  ]
  set score 0
  foreach n-values (length tri-score-components) [?] [
    set score score + item ? s-weights * item ? tri-score-components
  ]
end

to rank-scores
  let i 1
  foreach sort-on [(- score)] controllers with [role = "farmer"] [
    ask ? [
      ;show score
      set rank i
      set i i + 1
    ]
  ]
  set i 1
  foreach sort-on [-1 * [earnings] of agent] controllers with [role = "farmer"] [
    ask ? [
      ;show score
      set earnings-rank i
      set i i + 1
    ]
  ]
  set i 1
  foreach sort-on [-1 * (item 1 tri-score-components)] controllers with [role = "farmer"] [
    ask ? [
      ;show score
      set environment-rank i
      set i i + 1
    ]
  ]
  set i 1
  foreach sort-on [-1 * (item 0 tri-score-components)] controllers with [role = "farmer"] [
    ask ? [
      ;show score
      set social-rank i
      set i i + 1
    ]
  ]
end

to show-hide-labels 
  ifelse ([label] of one-of farmers = "")[
    ask controllers [ask agent [set label [user-id] of myself]]
  ]
  [
    ask farmers [set label ""]
  ]
end

to radar-chart [data]
  let num-vars length data
  clear-plot
  create-temporary-plot-pen "axes"
  create-temporary-plot-pen "line-pen"
  set-current-plot-pen "line-pen"
  set-plot-pen-color red
  plot-pen-up
  let midx plot-x-max / 2
  let midy plot-y-max / 2
  plotxy midx midy
  let angle-delta 360 / num-vars
  let axis-length max data + 1
  foreach n-values num-vars [?] [

    let cartesian-coord polar-to-rectangular (item ? data) (? * angle-delta)
    let axis-polar polar-to-rectangular (axis-length) (? * angle-delta)
    set-current-plot-pen "axes"
    let rect-x item 0 cartesian-coord
    let rect-y item 1 cartesian-coord
    plot-line midx (item 0 axis-polar + midx) midy (item 1 axis-polar +  midy)
    set-current-plot-pen "line-pen"
    plotxy (rect-x + midx) (rect-y + midy)
    plot-pen-down
  ]
  let cartesian-coord polar-to-rectangular (item 0 data) (0 * angle-delta)
  plotxy (item 0 cartesian-coord + midx) (item 1 cartesian-coord + midy)
end

to multi-radar-chart [data colors]
  let num-vars length (item 0 data)
  clear-plot
  create-temporary-plot-pen "axes"
  create-temporary-plot-pen "line-pen"
  foreach n-values length data [?] [
    set-plot-pen-color item ? colors
    do-radar-chart item ? data
  ]
  set-current-plot-pen "line-pen"
  set-plot-pen-color red
end

to do-radar-chart [data]
  let num-vars length data
  plot-pen-up
  let midx plot-x-max / 2
  let midy plot-y-max / 2
  plotxy midx midy
  let angle-delta 360 / num-vars
  let axis-length max data + 1
  foreach n-values num-vars [?] [
    let cartesian-coord polar-to-rectangular (item ? data) (? * angle-delta - 29.5)
    let axis-polar polar-to-rectangular (axis-length) (? * angle-delta - 29.5)
    set-current-plot-pen "axes"
    let rect-x item 0 cartesian-coord
    let rect-y item 1 cartesian-coord
    plot-line midx (item 0 axis-polar + midx) midy (item 1 axis-polar +  midy)
    set-current-plot-pen "line-pen"
    plotxy (rect-x + midx) (rect-y + midy)
    plot-pen-down
  ]
  let cartesian-coord polar-to-rectangular (item 0 data) (0 * angle-delta - 29.5)
  plotxy (item 0 cartesian-coord + midx) (item 1 cartesian-coord + midy)
end

to-report crops-individual-en [farma]
  let all-fields ([land] of farma) with [land-type = 1]
  report (sum [corn] of all-fields * corn-energy) + (sum [switchgrass] of all-fields * switchgrass-energy)
end

to-report crops-individual-val [farma]
 let all-fields ([land] of farma) with [land-type = 1]
  report (sum [corn] of all-fields * corn-futures-price) + (sum [switchgrass] of all-fields * switchgrass-futures-price)
end

to-report polar-to-rectangular [r theta]
  let x-ret r * cos(theta)
  let y-ret r * sin(theta)
  let ret-list [0 0]
  set ret-list replace-item 0 ret-list x-ret
  set ret-list replace-item 1 ret-list y-ret
  report ret-list
end

to plot-line [x1 x2 y1 y2]
  plot-pen-up
  plotxy x1 y1
  plot-pen-down
  plotxy x2 y2
end

to setup-earnings-plot
  set-current-plot "farmer earnings"
  foreach n-values count farmers [?] [
    if([is-human] of owner-of farmer ? = true)[
      create-temporary-plot-pen [user-id] of owner-of farmer ?
      set-plot-pen-color [color] of farmer ?
    ]
  ]
  
  

end

to viewview
  
end

to log-player-action [tag action player]
  file-open "logs/log.txt"
  let contro one-of controllers with [user-id = player]
  ifelse (tag = "Mouse Up" or contro = nobody or [agent] of contro = nobody)[
   ;redundant log or dont need to 
  ]
  [

   let farme [agent] of contro
   let clickstr "none,none,none"
   let plantstr "none,none"
   if(tag = "View")[
     let pat patch (item 0 action) (item 1 action)
     set clickstr (word pat "," [corn] of pat "," [switchgrass] of pat)
   ]
   if(tag = "Finished Planting") [
     ;decided to include this always, but leaving conditional as a placeholder in case of bugs
   ]
   set plantstr (word (count ([land] of farme) with [corn >= 1] / field-size ^ 2) "," (count ([land] of farme) with [switchgrass >= 1]  / field-size ^ 2))
   let pathere [patch-here] of farme
   let locstr (word pathere "," [land-type] of pathere "," [corn] of pathere "," [switchgrass] of pathere "," [soil-health] of pathere)
   ;time,player,message tag, message,accepted corn contract?,accepted switchgrass contract?,corn-contract amt,grass contract amt, corn price(futures),corn price(spot). grass price(futures), grass price(spot), clicked patch, corn at clicked patch
   ;switchgrass of clicked patch, corn planted (fields), switchgrass planted (fields),selected info view, earnings, corn grown, corn sold (overall), corn sold (spot), grass grown, grass sold (all), grass sold (spot)
   ;sustainability score, sustainability rank
   file-print (word ticks "," player "," tag "," action "," [accepted-corn-contract] of farme "," [accepted-switchgrass-contract] of farme  
      "," corn-contract "," switchgrass-contract "," corn-futures-price "," corn-spot-price "," switchgrass-futures-price "," switchgrass-spot-price "," clickstr "," plantstr ","[info-view] of contro ","[earnings] of farme ","
       [corn-grown] of farme "," [corn-sold] of farme "," [corn-sold-spot] of farme "," [switchgrass-grown] of farme "," [switchgrass-sold] of farme "," [switchgrass-sold-spot] of farme "," 
       [score] of contro "," [rank] of contro "," locstr) 
  ]
;  ifelse (tag = "Finished Choosing Contracts") [
;    let farme [agent] of one-of controllers with [user-id = player]
;    file-print (word ticks ": " player " - " tag "(corn: " [accepted-corn-contract] of farme ", switchgrass: " [accepted-switchgrass-contract] of farme  
;      " offered: " corn-contract " corn " switchgrass-contract " switchgrass , price: " corn-futures-price " corn " switchgrass-futures-price " switchgrass "  ")")
;  ]
;  [
;    ifelse (tag = "View") [
;      let pat patch (item 0 action) (item 1 action)
;      file-print (word ticks ": " player " - " tag "(" pat ", corn: " [corn] of pat ", grass: " [switchgrass] of pat ")")
;    ]
;    [
;      ifelse (tag = "Finished Planting") [
;        let farme [agent] of one-of controllers with [user-id = player]
;        file-print (word ticks ": " player " - " tag "( Planted corn: " (count ([land] of farme) with [corn >= 1] / field-size ^ 2)
;          " switchgrass: " (count ([land] of farme) with [switchgrass >= 1]  / field-size ^ 2)
;          " Contracts corn: " [accepted-corn-contract] of farme ", switchgrass: " [accepted-switchgrass-contract] of farme  
;      " offered: " corn-contract " corn " switchgrass-contract " switchgrass )")
;      ]
;      [
;        ifelse (tag = "Mouse Up") [
;          ;already logged with View
;        ]
;        [
;          file-print (word ticks ": " player " - " tag "(" action")")
;        ]
;      ]
;    ]
;  ]
  
  file-close
end

to-report crops-en-amt
 report (total-corn-grown * corn-energy) + (total-switchgrass-grown * switchgrass-energy)
end

to-report crops-econ-val
 report (total-corn-grown * corn-futures-price) + (total-switchgrass-grown * switchgrass-futures-price)
end

to-report patches-in-range-old [pstart pend]
 report patches with [((pxcor > ([pxcor] of pstart)) and (pycor > ([pycor] of pstart)) and (pxcor < ([pxcor] of pend)) and (pycor < ([pycor] of pend)))]
end  

to-report patches-in-range [pstart pend]
  report patches with [((pxcor > ([pxcor] of pstart)) and (pycor < ([pycor] of pstart)) and (pxcor < ([pxcor] of pend)) and (pycor > ([pycor] of pend)))]
end

to-report closest-factors [n]
  let best1 0
  let best2 0
  let bestDist 999999
  let last-val 0
  foreach n-values n [?] [
    let val ? + 1
    let this-dividend n / val
    if(this-dividend = round(this-dividend) and abs(val - this-dividend) < bestDist)[
      ifelse(this-dividend > val) [
        set best1 this-dividend
        set best2 val 
      ]
      [
        set best1 val
        set best2 this-dividend 
      ]
      set bestDist abs(val - this-dividend)
    ]
  ]
  let repor [0 0]
  set repor replace-item 0 repor best1
  set repor replace-item 1 repor best2
  report repor
end

to-report field-of-patch [p]
  foreach field-list [
   if member? p ? [
     report ?
   ] 
  ]
  report nobody
end

to-report owner-of [ag]
  report one-of controllers with [agent = ag]
end

to-report all-farmers-ready
;  report (length ready-list >= count controllers with [role = "farmer"]) 
    report (length ready-list >= expected-readies) 
end

to-report farmers-turn
  report (ticks mod 365 >= 25 and ticks mod 365 <= 99)
end

to-report merge-list-of-patchsets [li]
  if(length li = 0) [
    report nobody
  ]
  let retset item 0 li
  foreach n-values (length li - 1) [?] [
    set retset (patch-set retset item (? + 1) li)
  ]
  report retset
end

to-report max-energy-prod [farme]
  let max-grass-yield max-switchgrass-yield
  if (floor (ticks / 365) * switchgrass-growth-constant < max-grass-yield)[
    set max-grass-yield floor (ticks / 365) * switchgrass-growth-constant 
  ]
  if floor (ticks / 365) = 0 [
    set max-grass-yield 1
  ]
  let max-grass-en switchgrass-energy * max-grass-yield
  let maxen corn-energy
  if max-grass-en > corn-energy [
    set maxen max-grass-en
  ]
  report count ([land] of farme) with [land-type = 1] * maxen
end

to-report max-econ-prod [farme]
  let max-grass-yield max-switchgrass-yield
  if (floor (ticks / 365) * switchgrass-growth-constant < max-grass-yield)[
    set max-grass-yield floor (ticks / 365) * switchgrass-growth-constant
  ]
  if floor (ticks / 365) = 0 [
    set max-grass-yield 1
  ]
  let max-grass-revenue switchgrass-futures-price * max-grass-yield
  let maxecon corn-futures-price
  if max-grass-revenue > corn-futures-price [
    set maxecon max-grass-revenue
  ]
  report count ([land] of farme) with [land-type = 1] * maxecon
end

to-report corn-color-for [yield]
  ifelse (yield > corn-tons-per-acre - .5) [report yellow - .25][
    ifelse (yield > corn-tons-per-acre - 1) [report yellow] [
      ifelse (yield > corn-tons-per-acre - 2) [report yellow + 1] [
        report yellow + 2
      ]]]
  
end

to-report switchgrass-color-for [yield]
  ifelse (yield > switchgrass-tons-per-acre * 2) [report red - 1][
 ifelse (yield > switchgrass-tons-per-acre * 1.7) [report red - .75] [
  ifelse (yield > switchgrass-tons-per-acre * 1.4) [report red - .5] [
    ifelse (yield > switchgrass-tons-per-acre * 1.1) [report red - .25][
      ifelse (yield > switchgrass-tons-per-acre - 1) [report red] [
        ifelse (yield > switchgrass-tons-per-acre - 2) [report red + 1] [
          report red + 1.5
        ]]]]]]
  
end

to-report Economy-info-string [controlla]
  report ([economy-string] of agent)
end

to-report Environment-info-string [controlla]
  let currfield nobody
  let currfieldhealth ""
  let currCrop ""
  let currYield ""
  ask controlla [ask agent [
    set currfield field-of-patch patch-here
  ]]
  if(currfield != nobody) [
    set currfieldhealth (sum [soil-health] of currfield / count currfield)
    ;print [last-corn] of one-of currfield
    ;print [last-switchgrass] of one-of currfield
    if([last-corn] of one-of currfield > 0) [
      set currCrop "Corn"
      set currYield (sum [last-corn-yield] of currfield / count currfield)
    ]
    if([last-switchgrass] of one-of currfield > 0) [
      set currCrop "Grass"
      set currYield (sum [last-grass-yield] of currfield / count currfield)      
    ]
  ]
  report (word
    "Avg soil health: " (sum [soil-health] of ([land] of ([agent] of controlla))  / count ([land] of ([agent] of controlla))) "\n"
    "Health of current field: " currfieldhealth "\n"
    "Last grew " currCrop " here, which yielded " currYield " Tons per Acre\n" 
    "Emissions: " (sum [emissions] of (([land] of ([agent] of controlla)) with [land-type = 1]) / count (([land] of ([agent] of controlla)) with [land-type = 1])) "\n"
    )
end

to-report Sustainability-info-string [controlla]
  report (word
    "Environmental score: " item 1 tri-score-components
    "\nSocial score: " item 0 tri-score-components
    "\nEconomic score: " item 2 tri-score-components
    "\nOverall score: " score
    )
end

to-report Ranking-info-string [controlla]

  report (word
    "Economic rank (Earnings): " [earnings-rank] of controlla
    "\nEnvironmental rank: " [environment-rank] of controlla
    "\nSocial rank: " [social-rank] of controlla
    "\nOverall Sustanability rank: " [rank] of controlla
    )
end

to-report max-emissions[farme]
  let maxperpatch corn-input
  if switchgrass-input > corn-input [
    set maxperpatch switchgrass-input
  ]
  report count ([land] of farme) with [land-type = 1] * maxperpatch
end

to-report patches-in-range-inclusive [pstart pend]
   report patches with [((pxcor >= ([pxcor] of pstart)) and (pycor <= ([pycor] of pstart)) and (pxcor <= ([pxcor] of pend)) and (pycor >= ([pycor] of pend)))]
end

to-report area-width [area]
  report [pxcor] of max-one-of area [pxcor] - [pxcor] of min-one-of area [pxcor]
end

to-report area-height [area]
  report [pycor] of max-one-of area [pycor] - [pycor] of min-one-of area [pycor]
end

to-report get-item-xy [agentset x y width height shift]
  let minX [pxcor] of min-one-of agentset [pxcor] + shift
  let maxY [pycor] of max-one-of agentset [pycor] - shift
  ;show(word "patch ( " (minX + (x mod width)) ", " (maxY - (floor(y / height) * width)) ")")
  ;report patch (minX + (x mod width)) (maxY - (floor(height / y) * width))
  let repPat nobody
  ask patch minX maxY [ set repPat patch-at x (-1 * y)]
  report repPat

;  let retItem floor(y / height) * width + (x mod width)
;  
;  report item retItem agentList
end

to-report not-ready-list
  report [user-id] of controllers with [not member? user-id ready-list]
end

to-report gini-coefficient [data]
  ;algorithm from http://mathworld.wolfram.com/GiniCoefficient.html
  if min data < 0 [
    let mindata abs (min data)
    foreach data [
      set ? ? + mindata
    ]
  ]
  let n length data
  let mu mean data
  let outersum 0
  foreach n-values n [?] [
    let innersum 0
    let i ?
    foreach n-values n [?] [
      set innersum innersum + (abs ((item i data) - (item ? data)))
    ]
    set outersum outersum + innersum
  ]
  report outersum / (2 * (n ^ 2) * mu)
end
@#$#@#$#@
GRAPHICS-WINDOW
372
13
790
452
25
25
8.0
1
10
1
1
1
0
0
0
1
-25
25
-25
25
0
0
1
ticks
30.0

BUTTON
32
419
95
452
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
124
419
187
452
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
1

PLOT
801
232
1189
477
prices
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"perennial grass" 1.0 0 -2674135 true "" ""
"corn" 1.0 0 -4079321 true "" ""

PLOT
1193
234
1626
477
farmer earnings
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS

SLIDER
194
108
312
141
field-size
field-size
3
20
3
1
1
NIL
HORIZONTAL

SLIDER
193
36
313
69
initial-farmers
initial-farmers
1
50
4
1
1
NIL
HORIZONTAL

SLIDER
183
165
355
198
initial-corn-price
initial-corn-price
100
900
200
1
1
NIL
HORIZONTAL

SLIDER
183
205
361
238
initial-grass-price
initial-grass-price
1
800
100
1
1
NIL
HORIZONTAL

BUTTON
223
420
286
453
NIL
start
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
185
261
357
294
corn-subsidy
corn-subsidy
0
50
0
1
1
NIL
HORIZONTAL

SLIDER
186
297
358
330
grass-subsidy
grass-subsidy
0
50
0
1
1
NIL
HORIZONTAL

MONITOR
930
10
1163
55
phase
next-event
17
1
11

SWITCH
153
646
266
679
wait-tick
wait-tick
0
1
-1000

BUTTON
272
646
351
679
NIL
continue
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
69
531
219
576
coloring
coloring
"land use" "soil health" "land ownership"
0

PLOT
489
477
682
662
sustainability
NIL
NIL
0.0
1.0
0.0
1.0
true
false
"" ""
PENS
"nitrogen" 1.0 0 -16777216 true "" ""

MONITOR
379
473
484
534
sustainability
round (sustainability-index)
17
1
15

SLIDER
193
71
314
104
fields-per-farmer
fields-per-farmer
01
20
4
1
1
NIL
HORIZONTAL

PLOT
889
477
1178
732
sustainability components
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"pen-0" 1.0 0 -7500403 true "" ""

OUTPUT
991
734
1413
1013
12

BUTTON
232
537
305
570
Recolor
recolor-button
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
1206
479
1555
735
individual sustainability
NIL
NIL
0.0
15.0
0.0
15.0
false
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" ""

SWITCH
4
646
151
679
wait-for-teacher
wait-for-teacher
1
1
-1000

PLOT
687
478
887
663
Energy Produced (Gj)
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "if ticks > 365 [plot crops-en-amt]"

TEXTBOX
16
45
171
77
Set to the number of students
11
0.0
1

TEXTBOX
24
177
174
195
Set the initial Corn Price
11
0.0
1

TEXTBOX
13
216
179
234
Set the initial Switchgrass Price
11
0.0
1

TEXTBOX
17
271
167
289
Set the Corn Subsidy
11
0.0
1

TEXTBOX
4
306
187
324
Set Switchgrass Subsidy
11
0.0
1

TEXTBOX
8
79
182
107
Set the number of fields per farmer\n
11
0.0
1

TEXTBOX
27
117
162
135
Set the size of the fields
11
0.0
1

TEXTBOX
106
10
227
28
Set Initial Values
15
0.0
1

TEXTBOX
24
339
354
364
----------------------------------------------
20
0.0
1

TEXTBOX
119
372
269
392
Start the Game
16
0.0
1

TEXTBOX
62
402
212
420
First
11
0.0
1

TEXTBOX
140
401
290
419
Second
11
0.0
1

TEXTBOX
244
401
394
419
Third
11
0.0
1

TEXTBOX
24
463
380
506
---------------------------------------------\n
20
0.0
1

TEXTBOX
62
495
331
533
Change the Coloring of the Map
15
0.0
1

TEXTBOX
24
584
359
608
----------------------------------------------
20
0.0
1

TEXTBOX
68
609
311
633
Change how the Year Progresses
15
0.0
1

TEXTBOX
1044
505
1112
533
Emissions
11
0.0
1

TEXTBOX
1109
585
1259
603
Soil Health
11
0.0
1

TEXTBOX
1047
698
1197
716
Economic Value
11
0.0
1

TEXTBOX
909
573
1059
591
Energy Potential
11
0.0
1

TEXTBOX
1348
495
1498
513
Environmental
11
0.0
1

TEXTBOX
1508
663
1658
681
Social
11
0.0
1

TEXTBOX
1229
660
1379
678
Economic
11
0.0
1

INPUTBOX
424
689
665
749
weather-file
weather.txt
1
0
String

CHOOSER
154
695
292
740
weather-type
weather-type
"Very Bad" "Bad" "Normal" "Good" "Very Good"
2

BUTTON
303
704
405
737
Set Weather
teacher-set-weather
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
801
56
1332
101
Grown
last-year-grown
17
1
11

MONITOR
801
101
1331
146
Contracts
last-year-contract
17
1
11

MONITOR
801
145
1332
190
Spot
last-year-spot
17
1
11

MONITOR
801
188
1333
233
Secondary
last-year-secondary
17
1
11

SWITCH
28
699
136
732
contracts
contracts
0
1
-1000

MONITOR
801
10
858
55
year
floor (ticks / 365)
17
1
11

MONITOR
863
10
920
55
day
ticks mod 365
17
1
11

INPUTBOX
153
757
308
817
max-grass-price
800
1
0
Number

INPUTBOX
317
757
472
817
max-corn-price
600
1
0
Number

INPUTBOX
153
824
308
884
min-corn-price
0
1
0
Number

INPUTBOX
317
825
472
885
min-grass-price
0
1
0
Number

SWITCH
16
757
147
790
price-controls
price-controls
0
1
-1000

SWITCH
492
772
595
805
verbose
verbose
1
1
-1000

MONITOR
1168
10
1574
55
Not Ready
sort [user-id] of controllers with [not member? user-id ready-list]
17
1
11

BUTTON
385
560
467
593
NIL
viewview
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
490
839
602
872
Show/Hide IDs
show-hide-labels
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
## WHAT IS IT?

This section could give a general understanding of what the model is trying to show or explain.

## HOW IT WORKS

This section could explain what rules the agents use to create the overall behavior of the model.

## HOW TO USE IT

This section could explain how to use the model, including a description of each of the items in the interface tab.

## THINGS TO NOTICE

This section could give some ideas of things for the user to notice while running the model.

## THINGS TO TRY

This section could give some ideas of things for the user to try to do (move sliders, switches, etc.) with the model.

## EXTENDING THE MODEL

This section could give some ideas of things to add or change in the procedures tab to make the model more complicated, detailed, accurate, etc.

## NETLOGO FEATURES

This section could point out any especially interesting or unusual features of NetLogo that the model makes use of, particularly in the Procedures tab.  It might also point out places where workarounds were needed because of missing features.

## RELATED MODELS

This section could give the names of models in the NetLogo Models Library or elsewhere which are of related interest.

## CREDITS AND REFERENCES

This section could contain a reference to the model's URL on the web if it has one, as well as any other necessary credits or references.
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
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

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

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.0.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
TEXTBOX
92
10
234
47
Farmer
30
52.0
1

MONITOR
742
490
887
539
Earnings
NIL
3
1

MONITOR
277
33
366
82
players ready
NIL
3
1

VIEW
6
141
348
548
0
0
0
1
1
1
1
1
0
1
1
1
-25
25
-25
25

MONITOR
919
41
1025
90
Price of Corn (Ton)
NIL
3
1

MONITOR
918
96
1026
145
Price of Grass (Ton)
NIL
3
1

BUTTON
362
325
458
358
Plant Corn
NIL
NIL
1
T
OBSERVER
NIL
NIL

BUTTON
359
373
465
406
Plant Switchgrass
NIL
NIL
1
T
OBSERVER
NIL
NIL

BUTTON
361
423
462
456
Leave Fallow
NIL
NIL
1
T
OBSERVER
NIL
NIL

BUTTON
365
500
489
533
Finished Planting
NIL
NIL
1
T
OBSERVER
NIL
NIL

SWITCH
376
57
568
90
Accept Corn Contract
Accept Corn Contract
1
1
-1000

SWITCH
375
102
594
135
Accept Switchgrass Contract
Accept Switchgrass Contract
1
1
-1000

MONITOR
1028
41
1170
90
Cost of Corn (Ton)
NIL
3
1

MONITOR
1029
95
1170
144
Initial Cost of Grass (Ton)
NIL
3
1

MONITOR
580
40
775
89
Offered Corn Contract Amount (Tons)
NIL
3
1

MONITOR
581
95
777
144
Offered Grass Contract Amount (Tons)
NIL
3
1

BUTTON
395
156
583
189
Finished Choosing Contracts
NIL
NIL
1
T
OBSERVER
NIL
NIL

MONITOR
309
85
366
134
ready
NIL
3
1

MONITOR
104
85
305
134
Next Event
NIL
3
1

MONITOR
802
261
1122
310
Planted
NIL
3
1

MONITOR
802
316
1124
365
Production
NIL
3
1

MONITOR
803
371
1149
420
Contract Sales
NIL
3
1

MONITOR
897
490
1017
539
Sustainability Score
NIL
3
1

MONITOR
1025
491
1142
540
Sustainability Rank
NIL
3
1

TEXTBOX
395
10
707
40
Farmers Accept/Decline Contracts
18
0.0
1

TEXTBOX
355
189
1010
215
________________________________________________________________________
18
0.0
1

TEXTBOX
364
260
636
286
Farmers Choose What to Plant
18
0.0
1

TEXTBOX
788
227
938
249
Information
18
0.0
1

TEXTBOX
646
230
661
538
I\nI\nI\nI\nI\nI\nI\nI\nI\nI\nI\nI\nI\nI\n
18
0.0
1

BUTTON
487
325
590
358
Use Fertilizer
NIL
NIL
1
T
OBSERVER
NIL
NIL

MONITOR
803
424
1149
473
Spot Sales
NIL
3
1

CHOOSER
658
370
796
415
Information
Information
"Environment" "Economy" "Sustainability" "Ranking"
0

BUTTON
658
421
777
454
Get Information
NIL
NIL
1
T
OBSERVER
NIL
NIL

CHOOSER
4
86
101
131
Perspective
Perspective
"My Land" "World"
0

MONITOR
778
96
916
145
Grass Tons per Acre (base)
NIL
3
1

MONITOR
777
41
918
90
Corn Tons per Acre (base)
NIL
3
1

@#$#@#$#@
default
0.0
-0.2 0 1.0 0.0
0.0 1 1.0 0.0
0.2 0 1.0 0.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
