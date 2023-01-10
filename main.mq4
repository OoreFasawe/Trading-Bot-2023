#include "Condition_Functions.mqh"

void OnInit(){
   //determine if we in for buys or sells
   //by getting ema values over last 16 candles(4 hours- subjective)
   double ema200Data[];
   ArrayResize(ema200Data, trendMinCandleCount);
   setMAdataOnArray(ema200Data, trendMinCandleCount, EMA_Period, EMA_Shift, EMA_Method, EMA_Apply);
   TRADETYPE marketScanType = tradeTypeToLookFor(ema200Data, trendMinCandleCount);
   Alert(marketScanType); //toDo: remove Alert

   //get ma 10 values from chart
   double ma10Data[];
   ArrayResize(ma10Data, checkCandsForConsCount);
   setMAdataOnArray(ma10Data, checkCandsForConsCount, MA10_Period, MA10_Shift, MA10_Method, MA10_Apply);

   //get bollinger bands values from chart. 2d array to store upper and lower band values
   double bbData[][2];
   ArrayResize(bbData, checkCandsForConsCount);
   setBBDataOnArrayOffMAData(bbData, ma10Data, checkCandsForConsCount, BB_Period, BB_Deviation, BB_Shift);
   
   //get psar dot values from chart
   double pSarData[];
   ArrayResize(pSarData, checkCandsForConsCount);
   setPSARDataOnArray(pSarData, checkCandsForConsCount, PS_Step, PS_Maximum);
}