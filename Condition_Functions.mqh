#include "Utility.mqh"

//200 MA Trend Determinant
double getMAData(int ma_period, int ma_shift, ENUM_MA_METHOD ma_method, ENUM_APPLIED_PRICE ma_apply, int shift){
    return iMA(NULL, TimeFrame, ma_period, ma_shift, ma_method, ma_apply, shift);
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