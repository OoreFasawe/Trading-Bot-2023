#include "Condition_Functions.mqh"

void OnInit(){
   Alert("Working!");
   double ema200Data[10] = {};
   setMAdataOnArray(ema200Data, 10, EMA_Period, EMA_Shift, EMA_Method, EMA_Apply);
   for(int i = 0; i < 10; i++){
      Alert(ema200Data[i]);
   }
}