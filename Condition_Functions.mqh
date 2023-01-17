#include "Utility.mqh"

// retrieve MA value
double getMAValue(int ma_period, int ma_shift, ENUM_MA_METHOD ma_method, ENUM_APPLIED_PRICE ma_apply, int shift)
{
    return iMA(NULL, TimeFrame, ma_period, ma_shift, ma_method, ma_apply, shift);
}

// retrieve bollinger band value
double getBBValueOffMA(double &ma_array[], int bb_period, double bb_deviation, int bb_shift, int bb_mode, int shift)
{
    return iBandsOnArray(ma_array, 0, bb_period, bb_deviation, bb_shift, bb_mode, shift);
}

// retrieve PSAR value
double getPSARValue(double p_step, double p_maximum, int shift)
{
    return iSAR(NULL, TimeFrame, p_step, p_maximum, shift);
}

// input set of ma data into array
void setMAdataOnArray(double &ma_array[], int ma_arrSize, int ma_period, int ma_shift, ENUM_MA_METHOD ma_method, ENUM_APPLIED_PRICE ma_apply)
{
    for (int i = 0; i < ma_arrSize; i++)
    {
        ma_array[i] = getMAValue(ma_period, ma_shift, ma_method, ma_apply, i);
    }
}

// input set of bollinger band data into array
void setBBDataOnArrayOffMAData(BBand &bb_array[], double &ma_array[], int bb_arrSize, int bb_period, double bb_deviation, int bb_shift)
{
    double arrCopy[];
    ArrayResize(arrCopy, bb_arrSize);
    for (int i = 0; i < bb_arrSize; i++)
    {
        arrCopy[i] = ma_array[i];
    }
    ArraySetAsSeries(arrCopy, true);
    for (int i = 0; i < bb_arrSize; i++)
    {
        bbData[i].upper = iBandsOnArray(arrCopy, 0, bb_period, bb_deviation, bb_shift, MODE_UPPER, i);
        bbData[i].lower = iBandsOnArray(arrCopy, 0, bb_period, bb_deviation, bb_shift, MODE_LOWER, i);
    }
    // Comment(bbData[checkCandsForConsCount - 1].upper, "\n", bbData[checkCandsForConsCount - 1].lower);
}

// input set of psar data into array
void setPSARDataOnArray(double &pSAR_array[], int pSAR_arrSize, double p_step, double p_maximum)
{
    for (int i = 0; i < pSAR_arrSize; i++)
    {
        pSAR_array[i] = getPSARValue(p_step, p_maximum, i);
    }
}

// trade determinant
ENUM_TRADETYPE getTradeType(double &ma_array[], int ma_arrSize)
{

    bool lookForBuys = true;
    bool lookForSells = true;
    for (int i = BB_Period; i > 0; i--)
    {
        // both are set to false for consolidating markets where ema passes through candle
        if (iLow(NULL, TimeFrame, i) < ma_array[i] && iHigh(NULL, TimeFrame, i) > ma_array[i])
        {
            lookForBuys = false;
            lookForSells = false;
        }
        // if any of the 16 candles to track are below the ema, we're looking for sells, so set the opposite to false
        else if (iHigh(NULL, TimeFrame, i) < ma_array[i])
        {
            lookForBuys = false;
        }
        // if candles are above 200 ema, we're looking for buys,
        else if (iLow(NULL, TimeFrame, i) > ma_array[i])
        {
            lookForSells = false;
        }
    }

    if (lookForBuys)
    {
        return BUYS;
    }
    else if (lookForSells)
    {
        return SELLS;
    }
    else
    {
        return NONE;
    }
}

// the position of the first argument relative to the second
ENUM_RELATIVEPOSITION getRelativePosition(double val1, double val2)
{
    if (val1 > val2)
    {
        return ABOVE;
    }
    else if (val1 < val2)
    {
        return BELOW;
    }
    else
    {
        return EQUAL;
    }
}

void trade2()
{
    Print("Previous guy's");
    // Comment(bbData[checkCandsForConsCount - 3].upper, "\n", bbData[checkCandsForConsCount - 3].lower, "\n",bbData[checkCandsForConsCount - 4].upper, "\n", bbData[checkCandsForConsCount - 4].lower);

    if (iTime(NULL, 0, 0) != LastTimeBarOP2 || TradeOnNewBar == false)
    {
        if (CountSell() + CountBuy() == 0 && (SelectDirection == LongOnly || SelectDirection == Both))
            if ((ma10Data[2] <= bbData[2].upper || ma10Data[3] <= bbData[3].upper) && ma10Data[1] > bbData[1].upper && iClose(NULL, 0, 1) > ema200Data[1] && iClose(NULL, 0, 1) > pSarData[1] && iClose(NULL, 0, 2) < pSarData[2] && CheckSpread == true)
            {

                double SL = 0, TP = 0;
                double OrderTP = NormalizeDouble(takeProfitInPoints * Point, _Digits);
                double OrderSL = NormalizeDouble(stopLossInPoints * Point, _Digits);

                if ((stopLossInPoints > 0) && (UseStopLoss == true))
                    SL = NormalizeDouble(Bid - OrderSL, _Digits);

                if ((takeProfitInPoints > 0) && (UseTakeProfit == true))
                    TP = NormalizeDouble(Ask + OrderTP, _Digits);

                for (int i = 0; i < BuyTotal; i++)
                    if (!OrderSend(Symbol(), OP_BUY, NormalizeDouble(getLotSize(), 2), Ask, Slippage, SL, TP, "Buy", id, 0, clrBlue))
                    {
                    }
                    else
                    {
                        if (UseTradeCooldown)
                        {
                            tradeCoolDownPeriod = true;
                            startTime = TimeCurrent();
                        }
                        id++;
                    }
            }

        if (CountSell() + CountBuy() == 0 && (SelectDirection == ShortOnly || SelectDirection == Both))
        {
            if ((ma10Data[2] >= bbData[2].lower || ma10Data[3] >= bbData[3].lower) && ma10Data[1] < bbData[1].lower && iClose(NULL, 0, 1) < ema200Data[1] && iClose(NULL, 0, 1) < pSarData[1] && iClose(NULL, 0, 2) > pSarData[2] && CheckSpread == true)
            {
                double SL = 0, TP = 0;
                double OrderTP = NormalizeDouble(takeProfitInPoints * Point, _Digits);
                double OrderSL = NormalizeDouble(stopLossInPoints * Point, _Digits);

                if ((stopLossInPoints > 0) && (UseStopLoss == true))
                    SL = NormalizeDouble(Ask + OrderSL, _Digits);

                if ((takeProfitInPoints > 0) && (UseTakeProfit == true))
                    TP = NormalizeDouble(Bid - OrderTP, _Digits);

                for (int i = 0; i < SellTotal; i++)
                {
                    if (!OrderSend(Symbol(), OP_SELL, NormalizeDouble(getLotSize(), 2), Bid, Slippage, SL, TP, "Sell", id, 0, clrRed))
                    {
                    }
                    else
                    {
                        if (UseTradeCooldown)
                        {
                            tradeCoolDownPeriod = true;
                            startTime = TimeCurrent();
                        }
                        id++;
                    }
                }
                LastTimeBarOP2 = iTime(NULL, 0, 0);
            }
        }
    }
}

// void ModifyOrders(int magic)
//   {
// //------------------------------------------------------
//    double PriceComad=0;
//    double LocalStopLoss=0;
//    bool WasOrderModified;
//    string CommentModify;
// //------------------------------------------------------
// //Select order
//    for(int i=0; i<OrdersTotal(); i++)
//      {
//       if(OrderSelect(i,SELECT_BY_POS)==true)
//         {
//          if((OrderSymbol()==EASymbol) && (OrderMagicNumber()==magic))
//            {
//             //------------------------------------------------------
//             //Modify buy
//             if(OrderType()==OP_BUY)
//               {
//                LocalStopLoss=0.0;
//                WasOrderModified=false;
//                while(true)
//                  {
//                   //------------------------------------------------------
//                   //Break even
//                   if((LocalStopLoss==0) && (BreakEven>0) && (UseBreakEven==true) && (Bid-OrderOpenPrice()>=(BreakEven+BreakEvenAfter)*DigitPoints) && (NormalizeDouble(OrderOpenPrice()+BreakEven*DigitPoints,_Digits)<=Bid-(StopLevel*DigitPoints)) && (OrderStopLoss()==0 || OrderStopLoss()<=OrderOpenPrice())) //&&(OrderStopLoss()<OrderOpenPrice()))
//                     {
//                      Print("Buy Break");
//                      PriceComad=NormalizeDouble(OrderOpenPrice()+BreakEven*DigitPoints,_Digits);
//                      LocalStopLoss=BreakEven;
//                      CommentModify="break even";
//                     }
//                   //------------------------------------------------------
//                   //Trailing stop
//                   //    Print(NormalizeDouble(Bid-((TrailingStop+TrailingStep)*DigitPoints),_Digits)+"   >   "+OrderStopLoss());
//                   if((LocalStopLoss==0) && (TrailingStop>0) && (UseTrailingStop==true) && ((NormalizeDouble(Bid-((TrailingStop+TrailingStep)*DigitPoints),_Digits)>OrderStopLoss() || OrderStopLoss()==0))   && (OrderOpenPrice()<=NormalizeDouble(Bid-TrailingStop*DigitPoints,_Digits)))
//                     {
//                      Print("Buy Trail");
//                      PriceComad=NormalizeDouble(Bid-TrailingStop*DigitPoints,_Digits);
//                      LocalStopLoss=TrailingStop;
//                      CommentModify="trailing stop";
//                     }
//                   //------------------------------------------------------
//                   //Modify
//                   if((LocalStopLoss>0) && (PriceComad!=NormalizeDouble(OrderStopLoss(),_Digits)))
//                      WasOrderModified=OrderModify(OrderTicket(),0,PriceComad,NormalizeDouble(OrderTakeProfit(),_Digits),0,clrBlue);
//                   else
//                      break;
//                   //---
//                   if(WasOrderModified>0)
//                     {
//                      if(SoundAlert==true)
//                         PlaySound(SoundModify);
//                      Print(ExpertName+": modify buy by "+CommentModify+", ticket: "+DoubleToString(OrderTicket(),0));
//                      break;
//                     }
//                   else
//                     {
//                      Print("Error: ",DoubleToString(GetLastError(),0)+" || "+ExpertName+": receives new data and try again modify order");

//                     }
//                   //---Errors
//                   if((GetLastError()==1) || (GetLastError()==132) || (GetLastError()==133) || (GetLastError()==137) || (GetLastError()==4108) || (GetLastError()==4109))
//                      break;
//                   //---
//                  }//End while(true)
//               }//End if(OrderType()
//             //------------------------------------------------------
//             //Modify sell
//             if(OrderType()==OP_SELL)
//               {
//                WasOrderModified=false;
//                LocalStopLoss=0.0;
//                while(true)
//                  {
//                   //------------------------------------------------------
//                   //Break even
//                   if((LocalStopLoss==0) && (BreakEven>0) && (UseBreakEven==true) && (OrderOpenPrice()-Ask>=(BreakEven+BreakEvenAfter)*DigitPoints) && (NormalizeDouble(OrderOpenPrice()-BreakEven*DigitPoints,_Digits)>=Ask+(StopLevel*DigitPoints)) && (OrderStopLoss()==0 || OrderStopLoss()>=OrderOpenPrice()))  //&&(OrderStopLoss()>OrderOpenPrice()))
//                     {
//                      Print("Sell Break");
//                      PriceComad=NormalizeDouble(OrderOpenPrice()-BreakEven*DigitPoints,_Digits);
//                      LocalStopLoss=BreakEven;
//                      CommentModify="break even";
//                     }
//                   //------------------------------------------------------
//                   //Trailing stop
//                   //   Print(NormalizeDouble(Ask+((TrailingStop+TrailingStep)*DigitPoints),_Digits)+"   <   "+OrderStopLoss());

//                   if((LocalStopLoss==0) && (TrailingStop>0) && (UseTrailingStop==true) && ((NormalizeDouble(Ask+((TrailingStop+TrailingStep)*DigitPoints),_Digits)<OrderStopLoss() || OrderStopLoss()==0))  && (OrderOpenPrice()>=NormalizeDouble(Ask+TrailingStop*DigitPoints,_Digits)))
//                     {
//                      Print("Sell Trail");
//                      PriceComad=NormalizeDouble(Ask+TrailingStop*DigitPoints,_Digits);
//                      LocalStopLoss=TrailingStop;
//                      CommentModify="trailing stop";

//                     }
//                   //------------------------------------------------------
//                   //Modify

//                   if((LocalStopLoss>0) && (PriceComad!=NormalizeDouble(OrderStopLoss(),_Digits)))
//                      WasOrderModified=OrderModify(OrderTicket(),0,PriceComad,NormalizeDouble(OrderTakeProfit(),_Digits),0,clrRed);
//                   else
//                      break;
//                   //---
//                   if(WasOrderModified>0)
//                     {
//                      if(SoundAlert==true)
//                         PlaySound(SoundModify);
//                      Print(ExpertName+": modify sell by "+CommentModify+", ticket: "+DoubleToString(OrderTicket(),0));
//                      break;
//                     }
//                   else
//                     {
//                      Print("Error: ",DoubleToString(GetLastError(),0)+" || "+ExpertName+": receives new data and try again modify order");

//                     }
//                   //---Errors
//                   if((GetLastError()==1) || (GetLastError()==132) || (GetLastError()==133) || (GetLastError()==137) || (GetLastError()==4108) || (GetLastError()==4109))
//                      break;
//                   //---
//                  }//End while(true)
//               }//End if(OrderType()
//             //------------------------------------------------------
//            }//End if((OrderSymbol()...
//         }//End OrderSelect(...
//      }//End for(...
// //------------------------------------------------------
//   }

void trade1()
{
    Print("Mine");
    //"||======== MA crossing BB check ========||";
    int beforeIdx = -1;
    int afterIdx = -1;
    int pSarIdx = -1;
    bool seenPSARDot = false;
    ENUM_TRADETYPE condOne = NONE;
    bool condTwo = false;
    bool condThree = false;
    // Comment("ma10: ", ma10Data[checkCandsForConsCount-1], "\n", "bb3Up: ", bbData[checkCandsForConsCount-1].upper, "\n", "bb3Down: ", bbData[checkCandsForConsCount-1].lower, "\n", "pSARData: ", pSarData[checkCandsForConsCount-1]);
    if (marketScanType == BUYS && CountSell() + CountBuy() == 0 && (SelectDirection == ShortOnly || SelectDirection == Both))
    {
        condOne = BUYS;
        beforeIdx = -1;
        afterIdx = -1;
        pSarIdx = -1;
        for (int i = BB_Period; i > 0; i--)
        {

            if (ma10Data[i] > ema200Data[i] && bbData[i].lower > ema200Data[i])
            {
                if (getRelativePosition(ma10Data[i], bbData[i].lower) == BELOW && getRelativePosition(ma10Data[i + 1], bbData[i + 1].lower) == BELOW)
                {
                    beforeIdx = i;
                }
                else if (getRelativePosition(ma10Data[i], bbData[i].upper) == ABOVE)
                {
                    afterIdx = i;
                }
                if (getRelativePosition(pSarData[i], iLow(NULL, TimeFrame, i)) == BELOW && !seenPSARDot)
                {
                    pSarIdx = i;
                    seenPSARDot = true;
                }
            }
        }

        if (pSarIdx > 0)
        {
            condTwo = true;
            if (beforeIdx > 0 && afterIdx > 0)
            {
                if (beforeIdx >= afterIdx && pSarIdx >= afterIdx)
                {
                    // trade: drawing lines for now for testing in strategy tester
                    condThree = true;
                    if (UseTradeCooldown)
                    {
                        tradeCoolDownPeriod = true;
                        startTime = TimeCurrent();
                    }
                    double TP = 0;
                    double stoploss = NormalizeDouble(Ask - stopLossInPoints * Point, Digits);
                    if(UseTakeProfit){
                        TP = NormalizeDouble(Ask + takeProfitInPoints * Point, Digits);
                    }
                    OrderSend(NULL, OP_BUY, getLotSize(), Ask, 5, stoploss, TP, NULL, id, 0, Green);
                    id++;
                }
                else
                {
                    // Comment("CROSSOVER IN REVERSE ORDER");
                }
            }
            else
            {
                // Comment("NO VALID CROSSOVER");
            }
        }
        else
        {
            // Comment("NO DOT BELOW YET")
        }
    }
    else if (marketScanType == SELLS && CountSell() + CountBuy() == 0 && (SelectDirection == ShortOnly || SelectDirection == Both))
    {
        condOne = SELLS;
        beforeIdx = -1;
        afterIdx = -1;
        pSarIdx = -1;
        for (int i = BB_Period; i > 0; i--)
        {
            if (ma10Data[i] < ema200Data[i] && bbData[i].upper < ema200Data[i])
            {
                if (getRelativePosition(ma10Data[i], bbData[i].upper) == ABOVE && getRelativePosition(ma10Data[i + 1], bbData[i + 1].upper) == ABOVE)
                {
                    beforeIdx = i;
                }
                else if (getRelativePosition(ma10Data[i], bbData[i].lower) == BELOW)
                {
                    afterIdx = i;
                }
                if (getRelativePosition(pSarData[i], iHigh(NULL, TimeFrame, i)) == ABOVE && !seenPSARDot)
                {
                    pSarIdx = i;
                    seenPSARDot = true;
                }
            }
        }

        if (pSarIdx > 0)
        {
            condTwo = true;
            if (beforeIdx > 0 && afterIdx > 0)
            {
                if (beforeIdx >= afterIdx && pSarIdx >= afterIdx)
                {
                    // trade: drawing lines for now for testing in strategy tester
                    condThree = true;
                    if (UseTradeCooldown)
                    {
                        tradeCoolDownPeriod = true;
                        startTime = TimeCurrent();
                    }
                    double TP = 0;
                    double stoploss = NormalizeDouble(Bid + stopLossInPoints * Point, Digits);

                    if(UseTakeProfit){
                        TP = NormalizeDouble(Bid - takeProfitInPoints * Point, Digits);
                    }
                    OrderSend(NULL, OP_SELL, getLotSize(), Bid, 10, stoploss, TP, NULL, id, 0, Red);
                    id++;
                }
                else
                {
                    // Comment("CROSSOVER IN REVERSE ORDER");
                }
            }
            else
            {
                // Comment("NO VALID CROSSOVER");
            }
        }
        else
        {
            // Comment("NO DOT ABOVE YET")
        }
    }
    printConditions(display, condOne, condTwo, condThree);
}

void monitorOpenTrades()
{
    // loop through orders
    for (int i = 0; i < OrdersTotal(); i++)
    {
        // select each order
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            // check if symbol is on a chart ea is activated on so not to affect manual trades on charts ea is not on
            if (OrderSymbol() == Symbol())
            {
                // if buy
                if (OrderType() == OP_BUY)
                {
                    // if trade hasn't gone 5 pips in
                    if (OrderStopLoss() < OrderOpenPrice())
                    {
                        if (Ask - OrderOpenPrice() >= takeProfitInPoints * Point)
                        {
                            if (!OrderModify(OrderTicket(), OrderOpenPrice(), OrderOpenPrice(), 0, 0, 0))
                            {
                            }
                        }
                    }
                    else
                    {
                        if (Ask - OrderStopLoss() >= takeProfitInPoints * 2 * Point)
                        {
                            OrderModify(OrderTicket(), OrderOpenPrice(), Ask - (takeProfitInPoints * Point), 0, 0, 0);
                        }
                        // if(Close[1] < bbData[checkCandsForConsCount-2].upper){
                        //     OrderClose(OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_ASK), 5, clrBlue);
                        // }
                    }
                }
                // else if sell
                else if (OrderType() == OP_SELL)
                {
                    if (OrderStopLoss() > OrderOpenPrice())
                    {
                        if (OrderOpenPrice() - Bid >= takeProfitInPoints * Point)
                        {
                            if (!OrderModify(OrderTicket(), OrderOpenPrice(), OrderOpenPrice(), 0, 0, 0))
                            {
                            }
                        }
                    }
                    else
                    {
                        if (OrderStopLoss() - Bid >= takeProfitInPoints * 2 * Point)
                        {
                            OrderModify(OrderTicket(), OrderOpenPrice(), Bid + (takeProfitInPoints * Point), 0, 0, 0);
                        }
                        // if(Close[1] > bbData[checkCandsForConsCount-2].lower){
                        //     OrderClose(OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_BID), 5, clrBlue);
                        // }
                    }
                }
            }
        }
    }
}

double getLotSize()
{
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    if (balance < 200)
    {
        return 0.1;
    }
    else if (balance < 300)
    {
        return 0.2;
    }
    else if (balance < 500)
    {
        return 0.3;
    }
    else if (balance < 1000)
    {
        return 0.5;
    }
    else
    {
        return 1;
    }
}

void printConditions(string display, int one, bool two, bool three)
{
    if (one == BUYS)
    {
        display += "Condition 1(200EMA): LOOKING FOR BUYS\n";
    }
    else if (one == SELLS)
    {
        display += "Condition 1(200EMA): LOOKING FOR SELLS\n";
    }
    else
    {
        display += "Condition 1(200EMA): 200EMA in between FOOL3Bs\n";
    }

    display += two ? "Condition 2(PSAR DOT): YES\n" : "Condition 2(PSAR DOT): NO\n";
    display += three ? "Condition 3(MA/BB CROSSING): YES\n" : "Condition 3(MA/BB CROSSING): NO\n";

    Comment(display);
}

bool GoodTime()
{
    if (UseTimeFilter)
    {
        if (TimeToString(TimeCurrent(), TIME_MINUTES) >= Time_Start && TimeToString(TimeCurrent(), TIME_MINUTES) <= Time_End)
            return (true);
        return (false);
    }
    else
    {
        return true;
    }
}

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

// extern double PERCENTAGE_RISK_PER_TRADE = 0.01;
// double BALANCE = AccountInfoDouble(ACCOUNT_BALANCE);
// double calculateLotSize(double stopLossInPips)
// {
//   double maxMonetaryRisk = BALANCE * PERCENTAGE_RISK_PER_TRADE;
//   double lotSizeVolume = maxMonetaryRisk / ((stopLossInPips + calculatePipDifference(SymbolInfoDouble(NULL, SYMBOL_BID), SymbolInfoDouble(NULL, SYMBOL_ASK) /*_SPREAD*/)) * SymbolInfoDouble(NULL, SYMBOL_TRADE_TICK_VALUE));

//   return NormalizeDouble(lotSizeVolume, 2);
// }
