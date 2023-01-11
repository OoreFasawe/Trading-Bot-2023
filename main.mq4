#include "Condition_Functions.mqh"

MqlRates trendCandles[];
double ema200Data[];
double ma10Data[];
BBand bbData[];
double pSarData[];
ENUM_TRADETYPE marketScanType;
bool tradeCoolDownPeriod = false;
datetime startTime = TimeCurrent();
int timeElapsed;
int id = 1;

void OnInit(){
   //"||======== Getting candlesticks ========||";
   ArrayResize(trendCandles, trendMinCandleCount);
   
   //"||======== Indicator Initializations ========||";
   //determine if we in for buys or sells
   //by getting ema values over last 16 candles(4 hours- subjective)
   ArrayResize(ema200Data, trendMinCandleCount);
   setMAdataOnArray(ema200Data, trendMinCandleCount, EMA_Period, EMA_Shift, EMA_Method, EMA_Apply);
   //get ma 10 values from chart
   ArrayResize(ma10Data, checkCandsForConsCount);
   setMAdataOnArray(ma10Data, checkCandsForConsCount, MA10_Period, MA10_Shift, MA10_Method, MA10_Apply);
   //get bollinger bands values from chart. 2d array to store upper and lower band values
   ArrayResize(bbData, checkCandsForConsCount);
   setBBDataOnArrayOffMAData(bbData, ma10Data, checkCandsForConsCount, BB_Period, BB_Deviation, BB_Shift);
   //get psar dot values from chart
   ArrayResize(pSarData, checkCandsForConsCount);
   setPSARDataOnArray(pSarData, checkCandsForConsCount, PS_Step, PS_Maximum);
   
}

void OnTick(){
   int min15_candles = CopyRates(NULL, TimeFrame, 0, trendMinCandleCount, trendCandles);
   setMAdataOnArray(ema200Data, trendMinCandleCount, EMA_Period, EMA_Shift, EMA_Method, EMA_Apply);
   setMAdataOnArray(ma10Data, checkCandsForConsCount, MA10_Period, MA10_Shift, MA10_Method, MA10_Apply);
   setBBDataOnArrayOffMAData(bbData, ma10Data, checkCandsForConsCount, BB_Period, BB_Deviation, BB_Shift);
   setPSARDataOnArray(pSarData, checkCandsForConsCount, PS_Step, PS_Maximum);
   //"||======== Determine trade direction interest ========||";
   marketScanType = getTradeType(ema200Data, trendMinCandleCount, trendCandles);

   //"||======== PSAR DOT BELOW Check========||";
   // for(int i = 5; i > 0; i--){
   //    if(pSarData[checkCandsForConsCount-i] < trendCandles[trendMinCandleCount-i].low){
   //       Alert("Lower");
   //    }
   //    else if(pSarData[checkCandsForConsCount-i] > trendCandles[trendMinCandleCount-i].high){
   //       Alert("Higher");
   //    }
   //    Alert(i, ": ");
   // }

   if(tradeCoolDownPeriod == false){
      checkConditions();
   } 
   else{
      MqlDateTime temp;
      TimeToStruct(TimeCurrent()-startTime, temp);
      if(temp.min == 30){
         tradeCoolDownPeriod = false;
      }
   }
}