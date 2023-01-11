#include "Utility.mqh"

//retrieve MA value
double getMAValue(int ma_period, int ma_shift, ENUM_MA_METHOD ma_method, ENUM_APPLIED_PRICE ma_apply, int shift){
    return iMA(NULL, TimeFrame, ma_period, ma_shift, ma_method, ma_apply, shift);
}

//retrieve bollinger band value
double getBBValueOffMA(double& ma_array[], int bb_period, double bb_deviation, int bb_shift, int bb_mode, int shift){
    return iBandsOnArray(ma_array, 0, bb_period, bb_deviation, bb_shift, bb_mode, shift);
}

//retrieve PSAR value
double getPSARValue(double p_step, double p_maximum, int shift){
    return iSAR(NULL, TimeFrame, p_step, p_maximum, shift);
}

//input set of ma data into array
void setMAdataOnArray(double& ma_array[], int ma_arrSize, int ma_period, int ma_shift, ENUM_MA_METHOD ma_method, ENUM_APPLIED_PRICE ma_apply){
    for(int i = 0; i < ma_arrSize; i++){
        ma_array[ma_arrSize-1-i] = getMAValue(ma_period, ma_shift, ma_method, ma_apply, i);
    }
}

//input set of bollinger band data into array
void setBBDataOnArrayOffMAData(BBand& bb_array[], double& ma_array[], int bb_arrSize, int bb_period, double bb_deviation, int bb_shift){
    double arrCopy[];
    ArrayResize(arrCopy, bb_arrSize);
    for(int i = 0; i < bb_arrSize; i++){
        arrCopy[i] = ma_array[i];
    }
    for(int i = 0; i < bb_arrSize; i++){
        bb_array[bb_arrSize-1-i].upper = getBBValueOffMA(arrCopy, bb_period, bb_deviation, bb_shift, MODE_UPPER, i);
        bb_array[bb_arrSize-1-i].lower = getBBValueOffMA(arrCopy, bb_period, bb_deviation, bb_shift, MODE_LOWER, i);
    }
}

//input set of psar data into array
void setPSARDataOnArray(double& pSAR_array[], int pSAR_arrSize, double p_step, double p_maximum){
    for(int i = 0; i < pSAR_arrSize; i++){
        pSAR_array[pSAR_arrSize-1-i] = getPSARValue(p_step, p_maximum, i);
    }
}

//trade determinant
ENUM_TRADETYPE getTradeType(double& ma_array[], int ma_arrSize, MqlRates& candleSticks[]){

    bool lookForBuys = true;
    bool lookForSells = true;
    for(int i = 0; i< ma_arrSize; i++){ 
       //both are set to false for consolidating markets where ema passes through candle
       if(candleSticks[i].low < ma_array[i] && candleSticks[i].high > ma_array[i]){
         lookForBuys = false;
         lookForSells = false;
       }
       //if any of the 16 candles to track are below the ema, we're looking for sells, so set the opposite to false
       else if(candleSticks[i].high < ma_array[i]){
         lookForBuys = false;
       }
       //if candles are above 200 ema, we're looking for buys,  
       else if(candleSticks[i].low > ma_array[i]){
         lookForSells = false;
       }
    }
    
    if(lookForBuys){
      return BUYS;
    }
    else if(lookForSells){
      return SELLS;
    }
    else{
      return NONE;
    }
}

//the position of the first argument relative to the second
ENUM_RELATIVEPOSITION getRelativePosition(double val1, double val2){
    if(val1 > val2){
        return ABOVE;
    }
    else if (val1 < val2){
        return BELOW;
    }
    else{
        return EQUAL;
    }
}

void checkConditions(){
    //"||======== MA crossing BB check ========||";
    int beforeIdx = -1;
    int afterIdx = -1;

    if(marketScanType == BUYS){
      for(int i = 0; i < candlesUsedToMonitoForCrossingAndPSAR; i++){
         int idx = checkCandsForConsCount-candlesUsedToMonitoForCrossingAndPSAR + i;
         if(getRelativePosition(ma10Data[idx], bbData[idx].lower) == BELOW){
            beforeIdx = i+1;
         }
         else if(getRelativePosition(ma10Data[idx], bbData[idx].upper) == ABOVE){
            afterIdx = i+1;
         }
      }

      if(beforeIdx > 2 && afterIdx > 2){
         if(beforeIdx <= afterIdx){
            //trade: drawing lines for now for testing in strategy tester
            tradeCoolDownPeriod = true;
            startTime = TimeCurrent();
            string name = "buy trade" + string(id);
            ObjectCreate(
                NULL,
                name,
                OBJ_TREND,
                0,
                TimeCurrent(),
                (MarketInfo(NULL, MODE_ASK) + MarketInfo(NULL, MODE_ASK))/2, 
                TimeCurrent() + 5400,
                (MarketInfo(NULL, MODE_ASK) + MarketInfo(NULL, MODE_ASK))/2);
            ObjectSetInteger(NULL, name, OBJPROP_COLOR, clrLightSkyBlue);
            ObjectSetInteger(NULL, name, OBJPROP_SELECTABLE, true);
            ObjectSetInteger(NULL, name, OBJPROP_SELECTED, true);
            ObjectSetInteger(NULL, name, OBJPROP_HIDDEN, false);
            ObjectSetInteger(NULL, name, OBJPROP_RAY, false); 
            id++;
         }
         else{
            //Comment("CROSSOVER IN REVERSE ORDER");
         }
      }
      else{
         //Comment("NO VALID CROSSOVER");
      }
   }
   else if(marketScanType == SELLS){
    Comment("ma10: ", ma10Data[checkCandsForConsCount-1], "\n", "bb3Up: ", bbData[checkCandsForConsCount-1].upper, "\n", "bb3Down: ", bbData[checkCandsForConsCount-1].lower);
      for(int i = 0; i < candlesUsedToMonitoForCrossingAndPSAR; i++){
         int idx = checkCandsForConsCount-candlesUsedToMonitoForCrossingAndPSAR + i;
         if(getRelativePosition(ma10Data[idx], bbData[idx].upper) == ABOVE){
            beforeIdx = i+1;
         }
         else if(getRelativePosition(ma10Data[idx], bbData[idx].lower) == BELOW){
            afterIdx = i+1;
         }
      }   

      if(beforeIdx > 2 && afterIdx > 2){
         if(beforeIdx <= afterIdx){
            //trade: drawing lines for now for testing in strategy tester
            tradeCoolDownPeriod = true;
            startTime = TimeCurrent();
            string name = "sell trade" + string(id);
            ObjectCreate(
                NULL,
                name ,
                OBJ_TREND,
                0,
                TimeCurrent(),
                (MarketInfo(NULL, MODE_ASK) + MarketInfo(NULL, MODE_ASK))/2,
                TimeCurrent() + 5400,
                (MarketInfo(NULL, MODE_ASK) + MarketInfo(NULL, MODE_ASK))/2);
            ObjectSetInteger(NULL, name, OBJPROP_COLOR, clrLightSkyBlue);
            ObjectSetInteger(NULL, name, OBJPROP_SELECTABLE, true);
            ObjectSetInteger(NULL, name, OBJPROP_SELECTED, true);
            ObjectSetInteger(NULL, name, OBJPROP_HIDDEN, false);
            ObjectSetInteger(NULL, name, OBJPROP_RAY, false); 
            id++;
         }
         else{
            //Comment("CROSSOVER IN REVERSE ORDER");
         }
      }
      else{
         //Comment("NO VALID CROSSOVER");
      }
   }
   else{
      //Comment("MARKET IN CONSOLIDATION");
   }
}


