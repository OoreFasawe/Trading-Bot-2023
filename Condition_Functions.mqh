#include "Utility.mqh"

//MA Trend Determinant
double getMAData(int ma_period, int ma_shift, ENUM_MA_METHOD ma_method, ENUM_APPLIED_PRICE ma_apply, int shift){
    return iMA(NULL, TimeFrame, ma_period, ma_shift, ma_method, ma_apply, shift);
}

double getPSARData(double p_step, double p_maximum, int shift){
    return iSAR(NULL, TimeFrame, p_step, p_maximum, shift);
}

//ema trend
void setMAdataOnArray(double& ma_array[], int ma_arrSize, int ma_period, int ma_shift, ENUM_MA_METHOD ma_method, ENUM_APPLIED_PRICE ma_apply){
    //initialize entire array first time
    if(ma_array[0] == 0){
        for(int i = 0; i < ma_arrSize; i++){
            ma_array[ma_arrSize-1-i] = getMAData(ma_period, ma_shift, ma_method, ma_apply, i);
        }
    }
    else{
        //only get the most recent and add to the array
        for(int i = 0; i < ma_arrSize-1; i++){    
            ma_array[i] = ma_array[i+1];
        }
        ma_array[(ma_arrSize-1)] = getMAData(ma_period, ma_shift, ma_method, ma_apply, 0);
    }
}

void setPSARDataOnArray(double& pSAR_array[], int ma_arrSize, double p_step, double p_maximum){
   if(pSAR_array[0] == 0){
        for(int i = 0; i < ma_arrSize; i++){
            pSAR_array[ma_arrSize-1-i] = getPSARData(p_step, p_maximum, i);
        }
    }
    else{
        //only get the most recent and add to the array
        for(int i = 0; i < ma_arrSize-1; i++){    
            pSAR_array[i] = pSAR_array[i+1];
        }
        pSAR_array[(ma_arrSize-1)] = getPSARData(p_step, p_maximum, 0);
    }  
}

//for ea to know what trade type to scan for
TRADETYPE tradeTypeToLookFor(double& ma_array[], int ma_arrSize){
    MqlRates trendCandles[];
    ArrayResize(trendCandles, ma_arrSize);
    bool lookForBuys = true;
    bool lookForSells = true;
    int min15_candles = CopyRates(NULL, TimeFrame, 0, ma_arrSize, trendCandles);
    for(int i = 0; i< ma_arrSize; i++){ 
       //both are set to false for consolidating markets where ema passes through candle
       if(trendCandles[i].low < ma_array[i] && trendCandles[i].high > ma_array[i]){
         lookForBuys = false;
         lookForSells = false;
       }
       //if any of the 16 candles to track are below the ema, we're looking for sells, so set the opposite to false
       else if(trendCandles[i].high < ma_array[i]){
         lookForBuys = false;
       }
       //if candles are above 200 ema, we're looking for buys,  
       else if(trendCandles[i].low > ma_array[i]){
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


