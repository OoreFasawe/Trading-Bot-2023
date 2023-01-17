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
static int id = 1;

string SoundModify = "tick.wav";
string ExpertName;
string EASymbol;
string OperInfo;
string SymbolExtension = "";

double spread;
string display = "";

void OnInit()
{
   // candlesticks
   ArrayResize(trendCandles, checkCandsForConsCount);

   // indicator arrays
   ArrayResize(ema200Data, checkCandsForConsCount);

   ArrayResize(ma10Data, checkCandsForConsCount);

   ArrayResize(bbData, checkCandsForConsCount);

   ArrayResize(pSarData, checkCandsForConsCount);

   // started information
   ExpertName = MQLInfoString(MQL_PROGRAM_NAME);
   EASymbol = _Symbol;
   if (StringLen(EASymbol) > 6)
      SymbolExtension = StringSubstr(EASymbol, 6, 0);

   // Minimum trailing, take profit and stop loss
   // StopLevel=MathMax(MarketInfo(EASymbol,MODE_FREEZELEVEL)/MultiplierPoint,MarketInfo(EASymbol,MODE_STOPLEVEL)/MultiplierPoint);

   // Operation info
   OperInfo = ExpertName + ": Working well....";
}

void OnTick()
{
   CheckSpread = true;
   //"||======== Initialize indicators ========||"
   int min15_candles = CopyRates(NULL, TimeFrame, 0, checkCandsForConsCount, trendCandles);
   setMAdataOnArray(ema200Data, checkCandsForConsCount, EMA_Period, EMA_Shift, EMA_Method, EMA_Apply);
   setMAdataOnArray(ma10Data, checkCandsForConsCount, MA10_Period, MA10_Shift, MA10_Method, MA10_Apply);
   setBBDataOnArrayOffMAData(bbData, ma10Data, checkCandsForConsCount, BB_Period, BB_Deviation, BB_Shift);
   setPSARDataOnArray(pSarData, checkCandsForConsCount, PS_Step, PS_Maximum);
   Comment("ema: ", ema200Data[0], "\nma: ", ma10Data[0], "\nbbupper: ", bbData[0].upper, "\nbblower: ", bbData[0].lower, "\npsar: ", pSarData[0]);

   //"||======== Determine trade direction interest ========||"
   marketScanType = getTradeType(ema200Data, checkCandsForConsCount);
   Comment("ema: ", ema200Data[0], "\nma: ", ma10Data[0], "\nbbupper: ", bbData[0].upper, "\nbblower: ", bbData[0].lower, "\npsar: ", pSarData[0], "\ntrade type: ", marketScanType);

   //"||======== Trade ========||"
   if (tradeCoolDownPeriod == false && GoodTime())
   {
      if (eaImplementation == MINE)
         trade1();
      else if (eaImplementation == PREVIOUS)
         trade2();
   }
   else
   {
      MqlDateTime temp;
      TimeToStruct(TimeCurrent() - startTime, temp);
      if (temp.min == 15)
      {
         tradeCoolDownPeriod = false;
      }
   }

   // "||======== Check trades currently running and update if necessary ========||";
   if (OrdersTotal() > 0 && !UseTakeProfit)
   {
      monitorOpenTrades();
   }

   // toDo: Add minimum distance for trailing and move amount as seperate variables and add that bars are checks for a preceding cross and not that the ema is just above
}

void OnDeinit(const int reason)
{
   //------------------------------------------------------
   ObjectDelete(0, "Background");
   Comment("");
   //------------------------------------------------------
}