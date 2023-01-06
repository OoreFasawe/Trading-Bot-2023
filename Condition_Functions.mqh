#include "Utility.mqh"
//200 MA Trend Determinant


double getMAData(int period, int ma_shift, ENUM_MA_METHOD method, ENUM_APPLIED_PRICE apply, int shift){
    return iMA(NULL, TimeFrame, period, ma_shift, method, apply, shift);
    
  
}


//ema trend
void set200MAdata(double (&EMA_200data)[]){
    //if candel stick data not present, initialize entire array
    if(EMA_200data[0] == NULL){
        for(int i = 0; i < sizeof(EMA_200data); i++){
            EMA_200data[sizeof(EMA_200data)-1-i] = getMAData(EMA_Period, EMA_Shift, EMA_Method, EMA_Apply, i);
        }
    }
    else{
        //only get the most recent and add to the array
        for(int i = 0; i < sizeof(EMA_200data); i++){
            EMA_200data[i] = EMA_200data[i+1];
        }
        EMA_200data[(sizeof(EMA_200data)-1)] = getMAData(EMA_Period, EMA_Shift, EMA_Method, EMA_Apply, 0);
    }
}