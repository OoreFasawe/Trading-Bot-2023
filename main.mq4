#include "Condition_Functions.mqh"

void OnInit(){
   //200 EMA
   double ema200Data[];
   ArrayResize(ema200Data, trendMinCandleCount);
   setMAdataOnArray(ema200Data, trendMinCandleCount, EMA_Period, EMA_Shift, EMA_Method, EMA_Apply);
   TRADETYPE marketScanType = tradeTypeToLookFor(ema200Data, trendMinCandleCount);
}