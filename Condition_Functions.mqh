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
    int pSarIdx = -1;
    bool seenPSARDot = false;
    Comment("ma10: ", ma10Data[checkCandsForConsCount-1], "\n", "bb3Up: ", bbData[checkCandsForConsCount-1].upper, "\n", "bb3Down: ", bbData[checkCandsForConsCount-1].lower, "\n", "pSARData: ", pSarData[checkCandsForConsCount-1]);
    if(marketScanType == BUYS){
        beforeIdx = -1;
        afterIdx = -1;
        pSarIdx = -1;
        for(int i = 0; i < BB_Period; i++){
            int idx = checkCandsForConsCount-BB_Period + i;
            if(ma10Data[idx] > ema200Data[idx] && bbData[idx].lower > ema200Data[idx]){
                if(getRelativePosition(ma10Data[idx], bbData[idx].lower) == BELOW && getRelativePosition(ma10Data[idx-1], bbData[idx-1].lower) == BELOW){
                    beforeIdx = i+1;
                }
                else if(getRelativePosition(ma10Data[idx], bbData[idx].upper) == ABOVE){
                    afterIdx = i+1;
                }
                if(getRelativePosition(pSarData[idx], trendCandles[idx].low) == BELOW){
                    pSarIdx = i+1;
                }
            }
        }

        if(pSarIdx > 0){
            if(beforeIdx > 0 && afterIdx > 0){
                if(beforeIdx <= afterIdx){
                    //trade: drawing lines for now for testing in strategy tester
                    tradeCoolDownPeriod = true;
                    startTime = TimeCurrent();
                    string name = "buy trade" + string(id);
                    double stoploss=NormalizeDouble(Bid-stopLossInPoints*Point,Digits);
                    double takeprofit=NormalizeDouble(Bid+takeProfitInPoints*Point,Digits);

                    Print(OrderSend(NULL, OP_BUY, getLotSize(), Ask, 10, stoploss, takeprofit, NULL, id));

                    ObjectCreate(
                        NULL,
                        name,
                        OBJ_TREND,
                        0,
                        TimeCurrent(),
                        (MarketInfo(NULL, MODE_BID) + MarketInfo(NULL, MODE_BID))/2, 
                        TimeCurrent() + 5400,
                        (MarketInfo(NULL, MODE_BID) + MarketInfo(NULL, MODE_BID))/2);
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
            //Comment("NO DOT BELOW YET")
        }
   }
   else if(marketScanType == SELLS){
        beforeIdx = -1;
        afterIdx = -1;
        pSarIdx = -1;
        for(int i = 0; i < BB_Period; i++){
            int idx = checkCandsForConsCount-BB_Period + i;
            if(ma10Data[idx] < ema200Data[idx] && bbData[idx].upper < ema200Data[idx]){
                if(getRelativePosition(ma10Data[idx], bbData[idx].upper) == ABOVE && getRelativePosition(ma10Data[idx-1], bbData[idx-1].upper) == ABOVE){
                    beforeIdx = i+1;
                }
                else if(getRelativePosition(ma10Data[idx], bbData[idx].lower) == BELOW){
                    afterIdx = i+1;
                }
                if(getRelativePosition(pSarData[idx], trendCandles[idx].high) == ABOVE){
                    pSarIdx = i+1;
                }
            }
        }   

        if(pSarIdx > 0){
            if(beforeIdx > 0 && afterIdx > 0){
                if(beforeIdx <= afterIdx){
                    //trade: drawing lines for now for testing in strategy tester
                    tradeCoolDownPeriod = true;
                    startTime = TimeCurrent();
                    double stoploss=NormalizeDouble(Ask+stopLossInPoints*Point,Digits);
                    double takeprofit=NormalizeDouble(Ask-takeProfitInPoints*Point,Digits);

                    Print(OrderSend(NULL, OP_SELL, getLotSize(), Bid, 10, stoploss, takeprofit, NULL, id));
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
            //Comment("NO DOT ABOVE YET")
        }
   }
   else{
    Print("Consd");
   }
}

double getLotSize(){
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    if (balance < 200){
        return 0.1;
    }
    else if(balance < 300){
        return 0.2;
    }
    else if(balance < 500){
        return 0.3;
    }
    else if(balance < 1000){
        return 0.5;
    }
    else{
        return 1;
    }
}

double MarketInfoCustom(string symbol, int type){
   switch(type)
     {
      case MODE_LOW:
         return(SymbolInfoDouble(symbol,SYMBOL_LASTLOW));
      case MODE_HIGH:
         return(SymbolInfoDouble(symbol,SYMBOL_LASTHIGH));
      case MODE_TIME:
         return(SymbolInfoInteger(symbol,SYMBOL_TIME));
      case MODE_BID:
         return(Bid);
      case MODE_ASK:
         return(Ask);
      case MODE_POINT:
         return(SymbolInfoDouble(symbol,SYMBOL_POINT));
      case MODE_DIGITS:
         return(SymbolInfoInteger(symbol,SYMBOL_DIGITS));
      case MODE_SPREAD:
         return(SymbolInfoInteger(symbol,SYMBOL_SPREAD));
      case MODE_STOPLEVEL:
         return(SymbolInfoInteger(symbol,SYMBOL_TRADE_STOPS_LEVEL));
      case MODE_LOTSIZE:
         return(SymbolInfoDouble(symbol,SYMBOL_TRADE_CONTRACT_SIZE));
      case MODE_TICKVALUE:
         return(SymbolInfoDouble(symbol,SYMBOL_TRADE_TICK_VALUE));
      case MODE_TICKSIZE:
         return(SymbolInfoDouble(symbol,SYMBOL_TRADE_TICK_SIZE));
      case MODE_SWAPLONG:
         return(SymbolInfoDouble(symbol,SYMBOL_SWAP_LONG));
      case MODE_SWAPSHORT:
         return(SymbolInfoDouble(symbol,SYMBOL_SWAP_SHORT));
      case MODE_STARTING:
         return(0);
      case MODE_EXPIRATION:
         return(0);
      case MODE_TRADEALLOWED:
         return(0);
      case MODE_MINLOT:
         return(SymbolInfoDouble(symbol,SYMBOL_VOLUME_MIN));
      case MODE_LOTSTEP:
         return(SymbolInfoDouble(symbol,SYMBOL_VOLUME_STEP));
      case MODE_MAXLOT:
         return(SymbolInfoDouble(symbol,SYMBOL_VOLUME_MAX));
      case MODE_SWAPTYPE:
         return(SymbolInfoInteger(symbol,SYMBOL_SWAP_MODE));
      case MODE_PROFITCALCMODE:
         return(SymbolInfoInteger(symbol,SYMBOL_TRADE_CALC_MODE));
      case MODE_MARGINCALCMODE:
         return(0);
      case MODE_MARGININIT:
         return(0);
      case MODE_MARGINMAINTENANCE:
         return(0);
      case MODE_MARGINHEDGED:
         return(0);
      case MODE_MARGINREQUIRED:
         return(0);
      case MODE_FREEZELEVEL:
         return(SymbolInfoInteger(symbol,SYMBOL_TRADE_FREEZE_LEVEL));

      default:
         return(0);
     }
   return(0);
}

// bool GoodTime()
//   {

//    if(TimeToString(TimeCurrent(),TIME_MINUTES)>=Time_Start && TimeToString(TimeCurrent(),TIME_MINUTES)<=Time_End)
//       return(true);

//    return(false);
//   }

// double ProfitCheck()
//   {
//    double profit=0;
//    int total  = OrdersTotal();
//    for(int cnt = total-1 ; cnt >=0 ; cnt--)
//      {
//       OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
//       if(OrderSymbol()==Symbol())
//          profit+=OrderProfit()+OrderCommission()+OrderSwap();
//      }
//    return(profit);
//   }

// int CountBuy(int magic)
//   {
//    int open=0;
//    for(int i=0; i<OrdersTotal(); i++)
//      {
//       OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
//       if(OrderSymbol()==Symbol() && OrderMagicNumber()==magic && OrderType()==OP_BUY)
//         {
//          open++;
//         }
//      }

//    return(open);

//   }

// int CountSell(int magic)
//   {
//    int open=0;
//    for(int i=0; i<OrdersTotal(); i++)
//      {
//       OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
//       if(OrderSymbol()==Symbol() && OrderMagicNumber()==magic && OrderType()==OP_SELL)
//         {
//          open++;
//         }
//      }

//    return(open);

//   }


// double point(string symbol=NULL)
//   {
//    string sym=symbol;
//    if(symbol==NULL)
//       sym=Symbol();
//    double bid=MarketInfo(sym,MODE_BID);
//    int digits=(int)MarketInfo(sym,MODE_DIGITS);

//    if(digits<=1)
//       return(1); //CFD & Indexes
//    if(StringFind(sym,"XAU")>-1 || StringFind(sym,"xau")>-1 || StringFind(sym,"GOLD")>-1)
//       return(0.01);//Gold
//    if(StringFind(sym,"BTC")>-1 || StringFind(sym,"btc")>-1 || StringFind(sym,"BCH")>-1 || StringFind(sym,"bch")>-1  || StringFind(sym,"DSH")>-1 || StringFind(sym,"dsh")>-1 || StringFind(sym,"ETH")>-1 || StringFind(sym,"eth")>-1 || StringFind(sym,"LTC")>-1 || StringFind(sym,"ltc")>-1)
//       return(1);//Bitcoin
//    if(digits==4 || digits==5)
//       return(0.00001);
//    if((digits==2 || digits==3) && bid>1000)
//       return(0.01);
//    if((digits==2 || digits==3) && bid<1000)
//       return(0.001);

//    return(0);
//   }

// bool CheckMoneyForTrade(string symb,double lots,ENUM_ORDER_TYPE type)
//   {
// //--- Getting the opening price
//    MqlTick mqltick;
//    SymbolInfoTick(symb,mqltick);
//    double price=mqltick.ask;
//    if(type==ORDER_TYPE_SELL)
//       price=mqltick.bid;
// //--- values of the required and free margin
//    double margin,free_margin=AccountInfoDouble(ACCOUNT_MARGIN_FREE);
// //--- call of the checking function
//    if(!OrderCalcMargin(type,symb,lots,price,margin))
//      {
//       //--- something went wrong, report and return false
//       Print("Error in ",__FUNCTION__," code=",GetLastError());
//       return(false);
//      }
// //--- if there are insufficient funds to perform the operation
//    if(margin>free_margin)
//      {
//       //--- report the error and return false
//       Print("Not enough money for ",EnumToString(type)," ",lots," ",symb," Error code=",GetLastError());
//       return(false);
//      }
// //--- checking successful
//    return(true);
//   }


// int TimeHour(datetime date)
//   {
//    MqlDateTime tm;
//    TimeToStruct(date,tm);
//    return(tm.hour);
//   }
   


// extern double PERCENTAGE_RISK_PER_TRADE = 0.01;
// double BALANCE = AccountInfoDouble(ACCOUNT_BALANCE);
// double calculateLotSize(double stopLossInPips)
// {
//   double maxMonetaryRisk = BALANCE * PERCENTAGE_RISK_PER_TRADE;
//   double lotSizeVolume = maxMonetaryRisk / ((stopLossInPips + calculatePipDifference(SymbolInfoDouble(NULL, SYMBOL_BID), SymbolInfoDouble(NULL, SYMBOL_ASK) /*_SPREAD*/)) * SymbolInfoDouble(NULL, SYMBOL_TRADE_TICK_VALUE));

//   return NormalizeDouble(lotSizeVolume, 2);
// }
