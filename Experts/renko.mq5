//+----------------------------------------------------------------------------+
//|                                                          Renko2offline.mq5 |
//|                                          Copyright 2018, Guilherme Santos. |
//|                                                         fishguil@gmail.com |
//|                                                          Renko 2.0 Offline |
//|                                                                            |
//|2018-03-28:                                                                 |
//| Fixed events and time from renko rates                                     |
//|2018-04-02:                                                                 |
//| Fixed renko open time on renko rates                                       |
//|2018-04-10:                                                                 |
//| Add tick event and remove timer event for tester                           |
//|2018-04-30:                                                                 |
//| Correct volume on renko bars, wicks, performance, and parameters           |
//|2018-05-10:                                                                 |
//| Now with timer event                                                       |
//|2018-05-16:                                                                 |
//| New methods and MiniChart display by Marcelo Hoepfner                      |
//|2018-06-21:                                                                 |
//| New library with custom tick, performance and other improvements           |
//|2018-09-27:                                                                 |
//| Asymetric reversals, corrections on wick size and initialization           |
//+----------------------------------------------------------------------------+
#property copyright "Copyright 2018, Guilherme Santos."
#property link      "fishguil@gmail.com"
#property version   "2.0"
#property description "Renko 2.0 Offline"
#include <RenkoCharts.mqh>
//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
input string            RenkoSymbol    = "";                   // Symbol (Default = current)
input ENUM_RENKO_TYPE   RenkoType      = RENKO_TYPE_TICKS;     // Type
input double            RenkoSize      = 20;                   // Brick Size (Ticks, Pips or Points)
input bool              RenkoWicks     = true;                 // Show Wicks
input bool              RenkoTime      = true;                 // Brick Open Time
input bool              RenkoAsymetricReversal = false;        // Asymetric Reversals
input ENUM_RENKO_WINDOW RenkoWindow    = RENKO_CURRENT_WINDOW; // Chart Mode
input int               RenkoTimer     = 1000;                 // Timer in milliseconds (0 = Off)
input bool              RenkoBook      = true;                 // Watch Market Book
//+------------------------------------------------------------------+
//| Internal variables and objects                                   |
//+------------------------------------------------------------------+
RenkoCharts *RenkoOffline;
string original_symbol;
string custom_symbol;
bool _DebugMode = (MQL5InfoInteger(MQL5_TESTER) || MQL5InfoInteger(MQL5_DEBUG) || MQL5InfoInteger(MQL5_DEBUGGING) || MQL5InfoInteger(MQL5_OPTIMIZATION) || MQL5InfoInteger(MQL5_VISUAL_MODE) || MQL5InfoInteger(MQL5_PROFILER));
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   //Check Symbol
   original_symbol = StringAt(_Symbol, "_");
   if(RenkoSymbol != "")
      original_symbol = RenkoSymbol;
   //Check Period
   if(RenkoWindow == RENKO_CURRENT_WINDOW && ChartPeriod(0) != PERIOD_M1)
     {
      Print("Renko must be M1 period!", __FILE__, MB_OK);
      ChartSetSymbolPeriod(0, original_symbol, PERIOD_M1);
      return(INIT_SUCCEEDED);
     }
   //Setup Renko
   if (RenkoOffline == NULL) 
      if ((RenkoOffline = new RenkoCharts()) == NULL)
        {
         MessageBox("Renko create class error. Check error log!", __FILE__, MB_OK);
         return(INIT_FAILED);
        }
   if (!RenkoOffline.Setup(original_symbol, RenkoType, RenkoSize, RenkoWicks, RenkoTime, RenkoAsymetricReversal))
     {
      MessageBox("Renko setup error. Check error log!", __FILE__, MB_OK);
      return(INIT_FAILED);
     }
   //Create Custom Symbol
   RenkoOffline.CreateCustomSymbol();
   RenkoOffline.ClearCustomSymbol();
   custom_symbol = RenkoOffline.GetSymbolName();
   //Load History
   RenkoOffline.UpdateRates();
   RenkoOffline.ReplaceCustomSymbol();  
   //Start
   if(_DebugMode) 
      RenkoOffline.Start(RENKO_CURRENT_WINDOW, RenkoTimer, RenkoBook);
   else 
      RenkoOffline.Start(RenkoWindow, RenkoTimer, RenkoBook);
   //Refresh
   RenkoOffline.Refresh();
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(RenkoOffline!=NULL)
     {
      RenkoOffline.Stop();
      delete RenkoOffline;
      RenkoOffline=NULL;
     }  
  }
//+------------------------------------------------------------------+
//| Tick Event                                                       |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(!IsStopped()) 
      if(RenkoOffline!=NULL)
         RenkoOffline.Refresh();
  }
//+------------------------------------------------------------------+
//| Book Event                                                       |
//+------------------------------------------------------------------+
void OnBookEvent(const string& symbol)
  {
   if(RenkoBook)
      OnTick();
  }
//+------------------------------------------------------------------+
//| Timer Event                                                      |
//+------------------------------------------------------------------+
void OnTimer()
  {
   if(RenkoTimer>0)
      if(!MQL5InfoInteger(MQL5_TESTER) && !MQL5InfoInteger(MQL5_OPTIMIZATION))
         OnTick();
  }
//+------------------------------------------------------------------+