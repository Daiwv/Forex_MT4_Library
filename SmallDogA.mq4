//+------------------------------------------------------------------+
//|                                                     SmallDog.mq4 |
//|                                                  Eddie Jun Zhang |
//|                                          http://www.hofox.com.cn |
//+------------------------------------------------------------------+

/*=========================
version           1.1
::˼·˵��:

����г�= 1 Tokey; 2 London; 3 New York �ڿ���֮��һ����,����4��M15����,������ǰһСʱ�Ϳ��к�һСʱ��9����
ȡ��ߵ����͵�,�������ҵ�.�������볡�۸�Ϊһ��ߵ�,ֹ������͵�.
����������г�,���ע�Ļ��Ҷ�Ӧ��USD���,����GBPUSD.
ԭ���߽���,Ŀ�������Լ��30-50��,Ҳ����ͬʱ��׷��15��.��������͵�Ĳ���50-60����,�������һЩ.
Backcount 9 M15 bars, set iHigh and iLow.
-If Ask>iLow and Bid<iHigh, place buystop and sellstop at same time.  @iHigh, S/L=iLow. Expiration= 1.5 hrs.
=Long criteria:
-If Ask+Bid/2>iHigh, place buy order.  S/L =iLow.
=Shot criteria:
-If Ask+Bid/2<iLow, place sell order.  S/L =iHigh.
If price>iHigh and magic long order exist, delete sellstop order.
If price<iLow and magic short order exist, delete buystop order.
=exit criteria:
-If win 50 pips, then close 50% of position and trailing stop 35 pips remainder.
1.1�濼�����·��չ���:
1 �����͵��Ƚϴ�ʱ,ͷ����һЩ.
2 ���һ���ƽ�ֵ�,ƽ��һ���λ.
3 ��ֹӮ��׷��ֹ��.
**����ʱ������:
**���к�һ��Сʱ,ŦԼ����ʱ�� 8:00, Ҫ����Ϊ������ʱ�������ʱ�� 1, �г�ʱ��-5.
**0800-(-5)=1300,  1300+1=1400,  1400=> 1300-1500
===========================*/

#property copyright "Eddie Jun Zhang"
#property link      "http://www.ho-fox.com.cn"
#define OrderStr    "SmallDog USD EA" 
 
extern string Remark1              = "=====Main Setting=====";
extern int    MagicNumber          = 2101229;
extern string sSymbol              = "GBPUSD";
extern string sMarketOpenEndHour   = "15:01"; 

extern string Remark2              = "=====Risk Setting=====";
extern int    iHalfPosHLDist       = 160;  //**�ߵ㵽�͵�Ĳ�,���ڴ˵�,ͷ�����,���ͷ��Ϊ�ʻ���Ϳ�������ͷ��Ϊ0. 140-180? =180
extern int    pipplus              = 2;  //**���ֵ�λ�ӵĵ���
extern int    slippage             = 3;
extern bool   UseFirstTarget       = false;  //��������˵�ʱ,ƽһ���λ
extern int    iFirstTarget         = 90; //** 70-80? =80
extern double Lots                 = 0.1;  //�������ֵΪ��,���ô�ֵ.
extern bool   MoneyManagement      = false;  
extern int    Risk                 = 1;  // rang: 1-100
extern bool   UseTakeProfit        = true;
extern int    TakeProfit           = 90;  //**
extern bool   UseTrailingStop      = false;
extern int    TrailingStop         = 45; //** =45

int           Expriration          = 5400; //1.5hrs
string        TradeLog             = "SmallDog";

double iH, iL; //����ǰ�����ߵ����͵�
double dP, dSL, dTP;  //�¹ҵ��ļ۸�,ֹ���ֹӮ
double Lots1, Ilo;
string filename;
int cnt;
int iStatus = 0;
//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
//----
   
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
  {
//----
   
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {
//----
   int i;
   if(!IsDemo()){return;}
   
   RefreshRates();
   int ticket;
   filename=Symbol() + TradeLog + "-" + Month() + "-" + Day() + ".log";
   int CheckTime=StrToTime(TimeToStr(TimeCurrent(), TIME_DATE)+" "+sMarketOpenEndHour );
   iH=Ask*0.7;
   iL=Ask*1.5;
   Lots1=Lots;
   
   if ((CntOrd(OP_BUY,MagicNumber) + CntOrd(OP_SELL,MagicNumber)+ CntOrd(OP_BUYSTOP,MagicNumber)+ 
   CntOrd(OP_SELLSTOP,MagicNumber)) == 0
   && TimeCurrent() > CheckTime && TimeCurrent() < CheckTime + 300)
      {
      //----------Compute High/Low Price
      /*for(i=1; i<=4; i++)
         {
         if(High[i]>iH) iH=High[i];
         if(Low[i]<iL) iL=Low[i];
         }*/
         
      iH=High[iHighest(NULL,15,MODE_HIGH,4,1)];
      iL=Low[iLowest(NULL,15,MODE_LOW,4,1)];
      dSL=0;
      dTP=0;
      dP=0;
      SetComment("t1","High="+DoubleToStr(iH,Digits)+" Low="+DoubleToStr(iL,Digits),C'255,255,0',5,30);
      SetComment("t2","Distance="+DoubleToStr((iH-iL)/Point,0),C'255,200,0',5,45);
         
      //----------set lot
      LotOptimized();
      Ilo=Lots1;
     
      Write("TimeCurrent = "+TimeToStr(TimeCurrent(),TIME_DATE|TIME_MINUTES) + ", Current Bid = "+DoubleToStr(Bid,4));
      Write("AccountBalance = " + DoubleToStr(AccountBalance(),0) +", Lot = "+ DoubleToStr(Ilo,2) + ", iH = "+DoubleToStr(iH,4)+", iL = "+ DoubleToStr(iL,4) +", Diff = "+ DoubleToStr((iH-iL)/Point,0));
      Write(Ask+"   "+MarketInfo(sSymbol,MODE_STOPLEVEL)+ "  "  + DoubleToStr(Ask-iL,4));
      
      //-----------�����ǰ�������¼�֮��,������STOP��
      if(Bid>iL && Ask<iH) //place buystop and sellstop at same time.  @iHigh, S/L=iLow. Expiration= 1.5 hrs.
         {
         //-----place buy stop order
         if ((iH-Ask) < MarketInfo(sSymbol,MODE_STOPLEVEL)*Point) dP=iH+(MarketInfo(sSymbol,MODE_STOPLEVEL)+pipplus)*Point;
         else dP=iH+pipplus*Point;
         if ((Ask-iL) < MarketInfo(sSymbol,MODE_STOPLEVEL)*Point) dSL=iL-MarketInfo(sSymbol,MODE_STOPLEVEL)*Point;
         else dSL=iL; 
         if (UseTakeProfit && TakeProfit>0) dTP = iH + TakeProfit*Point;
         ticket = OrderSend(sSymbol,OP_BUYSTOP,Ilo,NormalizeDouble(dP,Digits),slippage,
         NormalizeDouble(dSL,Digits),NormalizeDouble(dTP,Digits),OrderStr,MagicNumber, TimeCurrent()+Expriration,Green);
         if(ticket<=0) 
            {
            Write("Error Occured : "+ErrorDescription(GetLastError()));
            Write(Symbol()+" Buy Stop @ "+DoubleToStr(dP,4)+" SL @ "+DoubleToStr(dSL,4)+" TP @"+DoubleToStr(dTP,4)+" ticket ="+ticket);
            } 
         else 
            {
            Print (iH," " ,iL);
            Write("Order opened : "+Symbol()+" Buy Stop@ "+DoubleToStr(iH,4)+" SL @ "+DoubleToStr(iL,4)+" TP @"+DoubleToStr(dTP,4)+" ticket ="+ticket);
            }
            
         //-----place sell stop order
         if ((Bid-iL) < MarketInfo(sSymbol,MODE_STOPLEVEL)*Point) dP=iL-(MarketInfo(sSymbol,MODE_STOPLEVEL)+pipplus)*Point;
         else dP=iL-(pipplus+MarketInfo(sSymbol,MODE_SPREAD))*Point;
         if ((iH-Bid) < MarketInfo(sSymbol,MODE_STOPLEVEL)*Point) dSL=iH+MarketInfo(sSymbol,MODE_STOPLEVEL)*Point;
         else dSL=iH;
         if (UseTakeProfit && TakeProfit>0) dTP = iL - TakeProfit*Point;
         ticket = OrderSend(sSymbol,OP_SELLSTOP,Ilo,NormalizeDouble(dP,Digits),slippage,
         NormalizeDouble(dSL,Digits),NormalizeDouble(dTP,Digits),OrderStr,MagicNumber, TimeCurrent() + Expriration,Red);
         if(ticket<=0) 
            {
            Write("Error Occured : "+ErrorDescription(GetLastError()));
            Write(Symbol()+" Sell Stop @ "+DoubleToStr(dP,4)+" SL @ "+DoubleToStr(dSL,4)+" TP @"+DoubleToStr(dTP,4)+" ticket ="+ticket);
            } 
         else 
            {
            Write("Order opened : "+Symbol()+" Sell Stop@ "+DoubleToStr(dP,4)+" SL @ "+DoubleToStr(dSL,4)+" TP @"+DoubleToStr(dTP,4)+" ticket ="+ticket);
            }
         iStatus=1;
         }
      //----------�����ǰ�۸����ϼ�֮��,���³���
      if(Ask>=iH && Ilo>0)
         {
         //-----place buy Order
         if (UseTakeProfit && TakeProfit>0) dTP = iH + TakeProfit*Point;
         ticket = OrderSend(sSymbol,OP_BUY,Ilo,Ask,slippage,NormalizeDouble(iL,Digits),
         NormalizeDouble(dTP,Digits),OrderStr,MagicNumber,0,Green);
         if(ticket<=0) 
            {
            Write("Error Occured : "+ErrorDescription(GetLastError()));
            Write(Symbol()+" Buy @ "+Ask+" SL @ "+DoubleToStr(iL,4)+" TP @"+DoubleToStr(dTP,4)+" ticket ="+ticket);
            } 
         else 
            {
            Write("Order opened : "+Symbol()+" Buy @ "+Ask+" SL @ "+DoubleToStr(iL,4)+" TP @"+DoubleToStr(dTP,4)+" ticket ="+ticket);
            }
         iStatus=5;
         }      
      //----------�����ǰ�۸����ϼ�֮��,���¶̵�
      if(Bid<=iL && Ilo>0)
         {
         //-----place short Order
         if (UseTakeProfit && TakeProfit>0) dTP = iL - TakeProfit*Point;
         ticket = OrderSend(sSymbol,OP_SELL,Ilo,Bid,slippage,NormalizeDouble(iH,Digits),
         NormalizeDouble(dTP,Digits),OrderStr,MagicNumber,0,Red);
         if(ticket<=0) 
            {
            Write("Error Occured : "+ErrorDescription(GetLastError()));
            Write(Symbol()+" Sell @ "+Bid+" SL @ "+DoubleToStr(iH,4)+" TP @"+DoubleToStr(dTP,4)+" ticket ="+ticket);
            } 
         else 
            {
            Write("Order opened : "+Symbol()+" Sell @ "+Bid+" SL @ "+DoubleToStr(iH,4)+" TP @"+DoubleToStr(dTP,4)+" ticket ="+ticket);
            }
         iStatus=5;
         }
      }
      
   //----------First Target Close 
   for(cnt=0; cnt<OrdersTotal(); cnt++) 
      {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if (OrderType()==OP_BUY && OrderSymbol()==Symbol() && 
      (OrderMagicNumber () == MagicNumber) && (Bid-OrderOpenPrice())>=iFirstTarget*Point && iStatus!=10) 
         {
         if(UseFirstTarget){
            OrderClose(OrderTicket(),OrderLots()/2,Bid,slippage,Red);
            iStatus=10;}
         else iStatus=10;
         }
      if (OrderType()==OP_SELL && OrderSymbol()==Symbol() && 
      (OrderMagicNumber () == MagicNumber) && (OrderOpenPrice()-Ask)>=iFirstTarget*Point && iStatus!=10) 
         {
         if(UseFirstTarget){
            OrderClose(OrderTicket(),OrderLots()/2,Ask,slippage,Green);
            iStatus=10;}
         else iStatus=10;   
         }
      }
      
   //----------Modify
   for (i=0; i<OrdersTotal(); i++) 
      {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) 
         {
         if (OrderSymbol()==Symbol() && (OrderMagicNumber () == MagicNumber) && iStatus==10 ) 
            {
            TrailingPositions();  
                   
            }
         }
      }
   //----------Delete��һ���������Ժ�,��һ��ɾ��.   
   if (CntOrd(OP_BUY,MagicNumber)>0) {
      for (i=0; i<OrdersTotal(); i++) {
         if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            if (OrderSymbol()==Symbol() && (OrderMagicNumber () == MagicNumber) && OrderType()==OP_SELLSTOP) {
               OrderDelete(OrderTicket());                     
               }
            }
         }
      } 
   if (CntOrd(OP_SELL,MagicNumber)>0) {
      for (i=0; i<OrdersTotal(); i++) {
         if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            if (OrderSymbol()==Symbol() && (OrderMagicNumber () == MagicNumber) && OrderType()==OP_BUYSTOP) {
               OrderDelete(OrderTicket());                     
               }
            }
         }
      }
//----
   return(0);
  }
//+------------------------------------------------------------------+

int CntOrd(int Type, int Magic) 
   {
//return number of orders with specific parameters
   int _CntOrd;
   _CntOrd=0;
   for(int i=0;i<OrdersTotal();i++)
      {
      OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
      if (OrderSymbol()==Symbol()) 
         {
         if ( (OrderType()==Type && (OrderMagicNumber()==Magic) || Magic==0)) _CntOrd++;
         }
      }
   return(_CntOrd);
   }

int Write(string str)
   {
//Write log file
   int handle; 
   handle = FileOpen(filename,FILE_READ|FILE_WRITE|FILE_CSV,"/t");
   FileSeek(handle, 0, SEEK_END);      
   FileWrite(handle," Time " + TimeToStr(CurTime(),TIME_DATE|TIME_SECONDS) + ": " + str);
   FileClose(handle);
   Print(str);
   }

void TrailingPositions() 
   {
   double pBid, pAsk, pp;
 
   pp = MarketInfo(OrderSymbol(), MODE_POINT);
   if (OrderType()==OP_BUY) 
      {
      pBid = MarketInfo(OrderSymbol(), MODE_BID);
 
      if (UseTrailingStop && TrailingStop>0) 
         {
         if ((pBid-OrderOpenPrice())>TrailingStop*pp) 
            {
            if (OrderStopLoss()<pBid-(TrailingStop)*pp) 
               {
               ModifyStopLoss(pBid-TrailingStop*pp);
               return;
               }
            }
         }
      }
      
   if (OrderType()==OP_SELL) 
      {
      pAsk = MarketInfo(OrderSymbol(), MODE_ASK);
 
      if (UseTrailingStop && TrailingStop>0) 
         {
         if (OrderOpenPrice()-pAsk>TrailingStop*pp) 
            {
            if (OrderStopLoss()>pAsk+(TrailingStop)*pp || OrderStopLoss()==0) 
               {
               ModifyStopLoss(pAsk+TrailingStop*pp);
               return;
               }
            }
         }
      }
   }
 
//+------------------------------------------------------------------+
//| Modify StopLoss                                                  |
//| Parameters:                                                      |
//|   ldStopLoss - StopLoss Leve                                     |
//+------------------------------------------------------------------+
void ModifyStopLoss(double ldStopLoss) 
   {
   bool fm;
   PlaySound("alert.wav");
   fm=OrdModify(OrderTicket(),OrderOpenPrice(),ldStopLoss,OrderTakeProfit(),0,CLR_NONE);
   }
//+------------------------------------------------------------------+

int OrdModify(int _ticket, double _price, double _stoploss, double _takeprofit, datetime _expiration, color _color=CLR_NONE) 
   {
//The function modify order with log
   double _priceop=0;
   int ticket,err,tries;
 
   tries = 0;    
   if (!IsTradeContextBusy() && IsTradeAllowed()) 
      {

         RefreshRates();
         ticket = OrderModify(_ticket,NormalizeDouble(_price,Digits),NormalizeDouble(_stoploss,Digits),NormalizeDouble(_takeprofit,Digits),_expiration,_color);
         if(ticket==0) 
            {
            Write("Error Occured : "+ErrorDescription(GetLastError()));
            Write(Symbol()+" Modify @ "+_price+" SL @ "+_stoploss+" TP @"+_takeprofit+" ticket ="+_ticket);
            } 
         else 
            {
            Write("Order modified : "+Symbol()+" Modify @ "+_price+" SL @ "+_stoploss+" TP @"+_takeprofit+" ticket ="+_ticket);
            }

      }
  err=ticket;
  return(err);
   }
  
//+------------------------------------------------------------------+
//| ����ͷ��, ��ѡ�����ʽ����                                       |
//+------------------------------------------------------------------+ 
void LotOptimized()
   {
   if (MoneyManagement) {
      if (Risk<1 || Risk>100) {
         Comment("Invalid Risk Value.");
         return(0);
         }
      else {
         Lots1=MathFloor((AccountFreeMargin()*AccountLeverage()*Risk*Point*100)/(Ask*MarketInfo(Symbol(),MODE_LOTSIZE)*
         MarketInfo(Symbol(),MODE_MINLOT)))*MarketInfo(Symbol(),MODE_MINLOT);
         }
      }
   if (iH-iL>iHalfPosHLDist*Point) Lots1=Lots1/2;  //�����ߵ͵��̫��,��ͷ�����
   if (Lots1<MarketInfo(Symbol(),MODE_MINLOT)) Lots1 = 0;  //���ͷ��С���ʻ����ͷ��,ͷ��Ϊ0,��ζ�Ų�����
   }


//+------------------------------------------------------------------+
//| return error description                                         |
//+------------------------------------------------------------------+
string ErrorDescription(int error_code)
   {
   string error_string;
//----
   switch(error_code)
     {
      //---- codes returned from trade server
      case 0:
      case 1:   error_string="no error";                                                  break;
      case 2:   error_string="common error";                                              break;
      case 3:   error_string="invalid trade parameters";                                  break;
      case 4:   error_string="trade server is busy";                                      break;
      case 5:   error_string="old version of the client terminal";                        break;
      case 6:   error_string="no connection with trade server";                           break;
      case 7:   error_string="not enough rights";                                         break;
      case 8:   error_string="too frequent requests";                                     break;
      case 9:   error_string="malfunctional trade operation";                             break;
      case 64:  error_string="account disabled";                                          break;
      case 65:  error_string="invalid account";                                           break;
      case 128: error_string="trade timeout";                                             break;
      case 129: error_string="invalid price";                                             break;
      case 130: error_string="invalid stops";                                             break;
      case 131: error_string="invalid trade volume";                                      break;
      case 132: error_string="market is closed";                                          break;
      case 133: error_string="trade is disabled";                                         break;
      case 134: error_string="not enough money";                                          break;
      case 135: error_string="price changed";                                             break;
      case 136: error_string="off quotes";                                                break;
      case 137: error_string="broker is busy";                                            break;
      case 138: error_string="requote";                                                   break;
      case 139: error_string="order is locked";                                           break;
      case 140: error_string="long positions only allowed";                               break;
      case 141: error_string="too many requests";                                         break;
      case 145: error_string="modification denied because order too close to market";     break;
      case 146: error_string="trade context is busy";                                     break;
      //---- mql4 errors
      case 4000: error_string="no error";                                                 break;
      case 4001: error_string="wrong function pointer";                                   break;
      case 4002: error_string="array index is out of range";                              break;
      case 4003: error_string="no memory for function call stack";                        break;
      case 4004: error_string="recursive stack overflow";                                 break;
      case 4005: error_string="not enough stack for parameter";                           break;
      case 4006: error_string="no memory for parameter string";                           break;
      case 4007: error_string="no memory for temp string";                                break;
      case 4008: error_string="not initialized string";                                   break;
      case 4009: error_string="not initialized string in array";                          break;
      case 4010: error_string="no memory for array\' string";                             break;
      case 4011: error_string="too long string";                                          break;
      case 4012: error_string="remainder from zero divide";                               break;
      case 4013: error_string="zero divide";                                              break;
      case 4014: error_string="unknown command";                                          break;
      case 4015: error_string="wrong jump (never generated error)";                       break;
      case 4016: error_string="not initialized array";                                    break;
      case 4017: error_string="dll calls are not allowed";                                break;
      case 4018: error_string="cannot load library";                                      break;
      case 4019: error_string="cannot call function";                                     break;
      case 4020: error_string="expert function calls are not allowed";                    break;
      case 4021: error_string="not enough memory for temp string returned from function"; break;
      case 4022: error_string="system is busy (never generated error)";                   break;
      case 4050: error_string="invalid function parameters count";                        break;
      case 4051: error_string="invalid function parameter value";                         break;
      case 4052: error_string="string function internal error";                           break;
      case 4053: error_string="some array error";                                         break;
      case 4054: error_string="incorrect series array using";                             break;
      case 4055: error_string="custom indicator error";                                   break;
      case 4056: error_string="arrays are incompatible";                                  break;
      case 4057: error_string="global variables processing error";                        break;
      case 4058: error_string="global variable not found";                                break;
      case 4059: error_string="function is not allowed in testing mode";                  break;
      case 4060: error_string="function is not confirmed";                                break;
      case 4061: error_string="send mail error";                                          break;
      case 4062: error_string="string parameter expected";                                break;
      case 4063: error_string="integer parameter expected";                               break;
      case 4064: error_string="double parameter expected";                                break;
      case 4065: error_string="array as parameter expected";                              break;
      case 4066: error_string="requested history data in update state";                   break;
      case 4099: error_string="end of file";                                              break;
      case 4100: error_string="some file error";                                          break;
      case 4101: error_string="wrong file name";                                          break;
      case 4102: error_string="too many opened files";                                    break;
      case 4103: error_string="cannot open file";                                         break;
      case 4104: error_string="incompatible access to a file";                            break;
      case 4105: error_string="no order selected";                                        break;
      case 4106: error_string="unknown symbol";                                           break;
      case 4107: error_string="invalid price parameter for trade function";               break;
      case 4108: error_string="invalid ticket";                                           break;
      case 4109: error_string="trade is not allowed";                                     break;
      case 4110: error_string="longs are not allowed";                                    break;
      case 4111: error_string="shorts are not allowed";                                   break;
      case 4200: error_string="object is already exist";                                  break;
      case 4201: error_string="unknown object property";                                  break;
      case 4202: error_string="object is not exist";                                      break;
      case 4203: error_string="unknown object type";                                      break;
      case 4204: error_string="no object name";                                           break;
      case 4205: error_string="object coordinates error";                                 break;
      case 4206: error_string="no specified subwindow";                                   break;
      default:   error_string="unknown error";
     }
//----
   return(error_string);
  }  
//+------------------------------------------------------------------+

int SetComment(string text, string Signal, color Dolly_col, int x, int y)
   {
   ObjectDelete(text);
   ObjectCreate(text, OBJ_LABEL, 0, 0, 0);
   ObjectSetText(text, Signal, 10, "Arial Bold", Dolly_col);
   ObjectSet(text, OBJPROP_CORNER, 0);
   ObjectSet(text, OBJPROP_XDISTANCE, x);
   ObjectSet(text, OBJPROP_YDISTANCE, y);
   }