#property copyright "Copyright 2023, Ooreoluwa Fasawe"
#property link ""
#property version "1.00"
#property strict

#include "Condition_Functions.mqh"

static datetime timeday = 0;
static bool checkAgain = true;

void OnStart()
  {
    double EMA_200data[10];

    set200MAdata(&EMA_200data);
    for(int i = 0; i < sizeof(EMA_200data); i++){
            Alert(EMA_200data[i]);
        }
   
  }
