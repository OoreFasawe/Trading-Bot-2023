#property copyright "Copyright 2023, Ooreoluwa Fasawe"
#property link ""
#property version "1.00"
#property strict

//GENERAL
int CHART_SYMBOL = NULL;
input ENUM_TIMEFRAMES TimeFrame = PERIOD_M15;
input int trendMinCandleCount = 16;
enum TRADETYPE {NONE, BUYS, SELLS};

// MAIN CHART INDICATORS
input string S1 = "||======== EMA 200 Settings ========||";
input int EMA_Period = 200;
input int EMA_Shift  = 0;
input ENUM_MA_METHOD EMA_Method = MODE_EMA;
input ENUM_APPLIED_PRICE EMA_Apply = PRICE_CLOSE;
//toDO: add 3px any color style, no levels

input string S2 = "||======== MA 10 Settings ========||";
input int MA10_Period = 10;
input int MA10_Shift  = 0;
input ENUM_MA_METHOD MA10_Method = MODE_LWMA;
input ENUM_APPLIED_PRICE MA10_Apply = PRICE_WEIGHTED;
//toDO: add 3px black color style, no levels

input string S3 = "||======== Bollinger Bands Settings ========||";
input int    BB_Period = 5;
input double BB_Deviation = 0.500;
input int    BB_Shift  = 0;
input ENUM_APPLIED_PRICE Apply = PRICE_CLOSE;
//toDo: add 3px gold color style, no levels

input string S4 = "||======== Parabolic SAR Settings ========||";
input double PS_Step = 0.02;
input double PS_Maximum  = 0.2;
//toDo: add 3px green color style, no levels

//WINDOW 1 INDICATORS- RSI WINDOW
input string S5 = "||======== RSI Settings ========||";
input int RSI_Period = 1;
input ENUM_APPLIED_PRICE RSI_Apply = PRICE_CLOSE;
input int    RSI_Shift  = 0;
//toDo: add3px blue color and levels 10 & 90

//same MA 10

input string S6 = "||======== MA 2 Settings ========||";
input int MA2_Period = 2;
input int MA2_Shift  = 0;
input ENUM_MA_METHOD MA2_Method = MODE_SMMA;
input ENUM_APPLIED_PRICE MA2_Apply = PRICE_CLOSE;
//toDO: add 3px yellow color

struct MT4_ORDER
  {
   long              Ticket;
   int               Type;

   long              TicketOpen;
   long              TicketID;

   double            Lots;

   string            Symbol;
   string            Comment;

   double            OpenPriceRequest;
   double            OpenPrice;

   long              OpenTimeMsc;
   datetime          OpenTime;

   //ENUM_DEAL_REASON  OpenReason;

   double            StopLoss;
   double            TakeProfit;

   double            ClosePriceRequest;
   double            ClosePrice;

   long              CloseTimeMsc;
   datetime          CloseTime;

   //ENUM_DEAL_REASON  CloseReason;

   //ENUM_ORDER_STATE  State;

   datetime          Expiration;

   long              MagicNumber;

   double            Profit;

   double            Commission;
   double            Swap;

  };