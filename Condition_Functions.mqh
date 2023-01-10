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
    //initialize entire array first time
    if(ma_array[0] == 0){
        for(int i = 0; i < ma_arrSize; i++){
            ma_array[ma_arrSize-1-i] = getMAValue(ma_period, ma_shift, ma_method, ma_apply, i);
        }
    }
    else{
        //only get the most recent and add to the array
        for(int i = 0; i < ma_arrSize-1; i++){    
            ma_array[i] = ma_array[i+1];
        }
        ma_array[(ma_arrSize-1)] = getMAValue(ma_period, ma_shift, ma_method, ma_apply, 0);
    }
}

//input set of bollinger band data into array
void setBBDataOnArrayOffMAData(double& BB_array[][], double& ma_array[], int BB_arrSize, int bb_period, double bb_deviation, int bb_shift){
    if(BB_array[0][0] == 0 || BB_array[0][1] == 0){
        for(int i = 0; i < BB_arrSize; i++){
            BB_array[BB_arrSize-1-i][0] = getBBValueOffMA(ma_array, bb_period, bb_deviation, bb_shift, MODE_UPPER, i);
            BB_array[BB_arrSize-1-i][1] = getBBValueOffMA(ma_array, bb_period, bb_deviation, bb_shift, MODE_LOWER, i);
        }
    }
    else{
        //only get the most recent and add to the array
        for(int i = 0; i < BB_arrSize-1; i++){    
            BB_array[i][0] = BB_array[i+1][0];
            BB_array[i][1] = BB_array[i+1][1];
        }
        BB_array[(BB_arrSize-1)][0] = getBBValueOffMA(ma_array, bb_period, bb_deviation, bb_shift, MODE_UPPER, 0);
        BB_array[(BB_arrSize-1)][1] = getBBValueOffMA(ma_array, bb_period, bb_deviation, bb_shift, MODE_LOWER, 0); 
    }
}

//input set of psar data into array
void setPSARDataOnArray(double& pSAR_array[], int pSAR_arrSize, double p_step, double p_maximum){
   if(pSAR_array[0] == 0){
        for(int i = 0; i < pSAR_arrSize; i++){
            pSAR_array[pSAR_arrSize-1-i] = getPSARValue(p_step, p_maximum, i);
        }
    }
    else{
        //only get the most recent and add to the array
        for(int i = 0; i < pSAR_arrSize-1; i++){    
            pSAR_array[i] = pSAR_array[i+1];
        }
        pSAR_array[(pSAR_arrSize-1)] = getPSARValue(p_step, p_maximum, 0);
    }  
}

//trade determinant
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


