#!/usr/bin/env awk -f

BEGIN{
  srand(); EventString="Peaceful night." # default no-event message
  split("Food,Workers,Soldiers,Fortifications",U,",")
  split("8,5,2,0",P,","); for (i in U) Resources[U[i]]=P[i]
}

function Abs(Val){ if (Val>=0) return Val; return 0-Val }

function Min(X,Y){ if (X<=Y) return X; return Y }

function Max(X,Y){ if(X>=Y) return X; return Y }

function Lion(){
  EventString="Lion attack!"
  Survival=int(rand()*100%20+1)+Resources["Soldiers"]
  if (Resources["Fortifications"]>=1) # fortifications always stop lions
    EventString=EventString" But it couldn\'t jump the walls."
  else if (Resources["Soldiers"]>0 && Survival>15) # soldiers can too
    EventString=EventString" Your soldiers prevent harm."
  if (EventString~/[^!]$/) return # catch event string without lion effect
  Resources["Soldiers"]-=2
  if (Resources["Soldiers"]<0){ # lose workers after soldiers
    Resources["Workers"]-=(Abs(Resources["Soldiers"])*2)
    Resources["Soldiers"]=0
  }
}

function Raid(){
  EventString="You were raided!"; FortReduced="0"
  if (Resources["Fortifications"]>=1){
    Breach=int(rand()*100%10) # no damage if not breached
    if(Breach-Resources["Fortifications"]<=3)
      ESPost="But they couldn\'t breach the walls."
    else { # walls reduced, but helps defend soldiers
      ESPost="They broke down part of the walls."
      Resources["Fortifications"]--; FortReduced="1"
    }
    EventString=EventString" "ESPost
    if (FortReduced=="0") return
  }
  Soldiers=Min(Resources["Soldiers"],\
    Resources["Soldiers"]-5+\
      int(Resources["Soldiers"]/5)+FortReduced*2)
  if (Soldiers<=0){ # lose workers and food after soldiers
    Resources["Workers"]-=(Abs(Soldiers)*2)
    Resources["Soldiers"]=0
    Resources["Food"]-=(20-Abs(Soldiers)*2)
  }
  else Resources["Soldiers"]=Soldiers
}

function Berries(){
  EventString="Found some berries! +2 Food."
  Resources["Food"]+=2
}

function Spoilage(){
  EventString="Some food spoiled! -8 Food."
  Resources["Food"]-=8
}

function Migrants(){
  EventString="Some migrants have arrived! +2 Workers."
  Resources["Workers"]+=2
}

function GoodEvent(){
  GRand=int(rand()*100%2)
  if (GRand==0 && Resources["Food"]<80) Berries()
  else if (GRand==1 && Resources["Food"]>=50) Migrants()
}

function BadEvent(){
  BRand=int(rand()*100%3)
  if (BRand==0 && Resources["Soldiers"]<=10) Lion()
  else if (BRand==1 && Resources["Food"]>=80) Spoilage()
  else if (BRand==2 && Resources["Food"]+Resources["Workers"]*5>=100) Raid()
}

function StrangeEvent(){ # flavor text, no effect
  STRand=int(rand()*100%6)
  if (STRand==0) EventString="You hear howling in the distance."
  else if (STRand==1) EventString="Is that a rustling in the trees?"
  else if (STRand==2) EventString="Full moon tonight."
  else if (STRand==3) EventString="Smells like manure."
  else if (STRand==4) EventString="Something jumps! Just a rabbit.."
  else if (STRand==5) EventString="An owl hoots. Hoooooot!"
}

function Event(){
  ERand=int(rand()*100%9)
  if (ERand<=1) GoodEvent()
  else if (ERand<=4) BadEvent()
  else if (ERand<=5) StrangeEvent()
}

function PrintStatus(){ # runs regardless of (in)valid input
  Stockpile=sprintf("%-5s | %-5s | %-5s | %-5s",\
    Resources["Food"],Resources["Workers"],\
    Resources["Soldiers"],Resources["Fortifications"])
  printf("%s\n%-5s | %-5s | %-5s | %-5s\n",Stockpile,"F","W","S","O")
}

function GetCount(Val){ # split input to unit count
  gsub(/[^0-9]/,"",Val); return Max(1,Val)
}

function Hire(Unit,Count,Price){ # hire workers or soldiers
  if (Resources["Food"]<=Count*Price) return 0 # can't afford, do nothing
  Resources["Food"]-=Count*Price
  return (Resources[Unit]+=Count)>0 # hire successful
}

function Score(Msg){ # print score and exit
  for (i in U) Resources[U[i]]=Max(0,Resources[U[i]])
  S=sprintf("Score: %d\n",Resources["Food"]+Resources["Workers"]*2+\
    Resources["Soldiers"]*4+Resources["Fortifications"]*10)
  printf("%s\n%s\n",Msg,S); exit
}

(Resources["Workers"]+Resources["Soldiers"]<=0){
  Score("Everone died! You lose.")
}

(Resources["Food"]<=0){
  Score("Everyone starved! You lose.")
}

(Resources["Fortifications"]>=5 && \
  Resources["Soldiers"]>=15 && Resources["Food"]>=100){
  Resources["Food"]+=100 # to increase points by 100
  Score("Your people are safe and well fed. You win!")
}

{ tolower($0) }

/^(([^fwscmoq].*)|( *))$/{ PrintStatus(); next } # invalid input

/^q/{ Score("Coward!") } # quit

/^f/{ Resources["Food"]+=3 } # collect food

/^w[0-9]*/{ # hire worker(s)
  if (!Hire("Workers",GetCount($0),5)){ PrintStatus(); next }
}

/^s[0-9]*/{ # hire soldier(s)
  if (!Hire("Soldiers",GetCount($0),10)){ PrintStatus(); next }
}

/^c/{ # change soldier to worker
  if (Resources["Soldiers"]<=0){ PrintStatus(); next }
  Resources["Soldiers"]--; Resources["Workers"]++
}

/^m/{ # hire 10 soldiers (mercenaries) for 100 food
  if (Resources["Food"]<=100){ PrintStatus(); next }
  Resources["Soldiers"]+=10; Resources["Food"]-=100
}

/^o/{ # buy fortifications for 20 workers
  if (Resources["Workers"]<20){ PrintStatus(); next }
  Resources["Workers"]-=20; Resources["Fortifications"]++
}

{
  Event() # random event each turn
  Resources["Food"]+=int(Resources["Workers"]/2)+1 # workers collect food
  Resources["Food"]-=Resources["Soldiers"] # pay soldiers in food
  PrintStatus(); print EventString
  EventString="Peaceful night."
}
