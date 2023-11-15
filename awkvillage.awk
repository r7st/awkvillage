#!/usr/bin/env awk -f

BEGIN{ 
  srand() 
  Resources["Food"]=8
  Resources["Workers"]=5
  Resources["Soldiers"]=2
  Resources["Fortifications"]=0
  EventString="Peaceful night."
}
function Abs(Val){
  if (Val>=0) return Val
  return (0-Val)
}
function Min(X,Y){
  if (X<=Y) return X
  return Y
}
function Lion(){
  if (Resources["Fortifications"]>=1){
    EventString="Lion attack! But it couldn\'t jump the walls."
    return
  }
  Soldiers=Resources["Soldiers"]
  Survival=int(rand()*100%20+1)+Soldiers
  if (Survival>15){
    EventString="Lion attack! Your soldiers prevent harm."
    return
  }
  EventString="Lion attack! -2 Soldiers."
  if (Soldiers>=2) Resources["Soldiers"]-=2
  else if (Soldiers>=1){
    EventString="Lion attack! -1 Soldier, -2 Workers."
    Resources["Soldiers"]--
    Resources["Workers"]-=2
  }
  else {
    EventString="Lion attack! -4 Workers."
    Resources["Workers"]-=4
  }
}
function Raid(){
  EventString="You were raided!"
  FortReduced="0"
  if (Resources["Fortifications"]>=1){
    Breach=int(rand()*100%10)
    if(Breach-Resources["Fortifications"]<=3)
      ESPost="But they couldn\'t breach the walls."
    else {
      ESPost="They broke down part of the walls."
      Resources["Fortifications"]--
      FortReduced="1"
    }
    EventString=EventString" "ESPost
    if (FortReduced=="0") return
  }
  Soldiers=Min(Resources["Soldiers"],\
    Resources["Soldiers"]-5+\
      int(Resources["Soldiers"]/5)+FortReduced*2)
  if (Soldiers<=0){
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
function StrangeEvent(){
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
function PrintStatus(){
  Stockpile=sprintf("%-5s | %-5s | %-5s | %-5s",\
    Resources["Food"],Resources["Workers"],\
    Resources["Soldiers"],Resources["Fortifications"])
  print Stockpile
  printf("%-5s | %-5s | %-5s | %-5s\n","F","W","S","O")
}
function HireWorkers(Inp){
  gsub(/[^0-9]/,"",Inp)
  if (length(Inp)<=0) Inp=1
  Workers=Inp
  Cost=Inp*5
  if (Resources["Food"]<=Cost) return
  Resources["Workers"]+=Workers
  Resources["Food"]-=Cost
}
function HireSoldiers(Inp){
  gsub(/[^0-9]/,"",Inp)
  if (length(Inp)<=0) Inp=1
  Soldiers=Inp
  Cost=Inp*10
  if (Resources["Food"]<=Cost) return
  Resources["Soldiers"]+=Soldiers
  Resources["Food"]-=Cost
}
(Resources["Workers"]+Resources["Soldiers"]<=0){
  print "Everone died! You lose."
  exit
}
(Resources["Food"]<=0){
  print "Everyone starved! You lose."
  exit
}
(Resources["Fortifications"]>=5 && Resources["Soldiers"]>=15 && Resources["Food"]>=100){
  print "Your people are safe and well fed. You win!"
  exit
}
{ tolower($0) }
/^f/{ Resources["Food"]+=3 }
/^w[0-9]*/{ HireWorkers($0) }
/^s[0-9]*/{ HireSoldiers($0) }
/^c/{ Resources["Soldiers"]--; Resources["Workers"]++ }
/^m/{ if (Resources["Food"]>100) { Resources["Soldiers"]+=10; Resources["Food"]-=100 }}
/^o/{ 
  if (Resources["Workers"]>=20){ 
    Resources["Workers"]-=20; 
    Resources["Fortifications"]++; 
  }
}
{
  Event()
  Resources["Food"]+=int(Resources["Workers"]/2)+1
  Resources["Food"]-=Resources["Soldiers"]
  PrintStatus() 
  print EventString
  EventString="Peaceful night."
}
