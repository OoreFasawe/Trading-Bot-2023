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

string SoundModify="tick.wav";
string ExpertName;
string EASymbol;
string OperInfo;
string SymbolExtension="";

double DigitPoints;
int MultiplierPoint;
double StopLevel;
double Spreads;
double Spread;
string display = "";

void OnInit(){
   //"||======== Getting candlesticks ========||";
   ArrayResize(trendCandles, checkCandsForConsCount);
   
   //"||======== Indicator Initializations ========||";
   //determine if we in for buys or sells
   //by getting ema values over last 16 candles(4 hours- subjective)
   ArrayResize(ema200Data, checkCandsForConsCount);
   setMAdataOnArray(ema200Data, checkCandsForConsCount, EMA_Period, EMA_Shift, EMA_Method, EMA_Apply);
   //get ma 10 values from chart
   ArrayResize(ma10Data, checkCandsForConsCount);
   setMAdataOnArray(ma10Data, checkCandsForConsCount, MA10_Period, MA10_Shift, MA10_Method, MA10_Apply);
   //get bollinger bands values from chart. 2d array to store upper and lower band values
   ArrayResize(bbData, checkCandsForConsCount);
   setBBDataOnArrayOffMAData(bbData, ma10Data, checkCandsForConsCount, BB_Period, BB_Deviation, BB_Shift);
   //get psar dot values from chart
   ArrayResize(pSarData, checkCandsForConsCount);
   setPSARDataOnArray(pSarData, checkCandsForConsCount, PS_Step, PS_Maximum);


   //Started information
   ExpertName=MQLInfoString(MQL_PROGRAM_NAME);
   EASymbol=_Symbol;
   if(StringLen(EASymbol)>6)
      SymbolExtension=StringSubstr(EASymbol,6,0);

   //------------------------------------------------------
   //Broker 4 or 5 digits
   DigitPoints=MarketInfo(EASymbol,MODE_POINT);
   MultiplierPoint=1;
   if((MarketInfo(EASymbol,MODE_DIGITS)==3) || (MarketInfo(EASymbol,MODE_DIGITS)==5))
   {
      MultiplierPoint=10;
      DigitPoints*=MultiplierPoint;
   }

   Print("multi: "+MultiplierPoint);
   Print("DigitPoints: "+DigitPoints);
   //------------------------------------------------------
   //Minimum trailing, take profit and stop loss
   StopLevel=MathMax(MarketInfo(EASymbol,MODE_FREEZELEVEL)/MultiplierPoint,MarketInfo(EASymbol,MODE_STOPLEVEL)/MultiplierPoint);
   
   //Operation ifno
   OperInfo=ExpertName+"   Working well....";
}

void OnTick(){
   //"||======== Initialize indicators ========||"
   int min15_candles = CopyRates(NULL, TimeFrame, 0, checkCandsForConsCount, trendCandles);
   setMAdataOnArray(ema200Data, checkCandsForConsCount, EMA_Period, EMA_Shift, EMA_Method, EMA_Apply);
   setMAdataOnArray(ma10Data, checkCandsForConsCount, MA10_Period, MA10_Shift, MA10_Method, MA10_Apply);
   setBBDataOnArrayOffMAData(bbData, ma10Data, checkCandsForConsCount, BB_Period, BB_Deviation, BB_Shift);
   setPSARDataOnArray(pSarData, checkCandsForConsCount, PS_Step, PS_Maximum);
   //"||======== Determine trade direction interest ========||"
   marketScanType = getTradeType(ema200Data, checkCandsForConsCount, trendCandles);

   //"||======== Trade ========||"toDo: add max trades to be whatever;
   if(tradeCoolDownPeriod == false){
      trade();
   } 
   else{
      MqlDateTime temp;
      TimeToStruct(TimeCurrent()-startTime, temp);
      if(temp.min == 45){
         tradeCoolDownPeriod = false;
      }
   }

   //"||======== Check trades currently running and update if necessary ========||";
   if(OrdersTotal() > 0){
      monitorOpenTrades();
   }
}