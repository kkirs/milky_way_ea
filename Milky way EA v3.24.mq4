//+------------------------------------------------------------------+
//|                                           Milky way EA v3.24.mq4 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, Silentspec Transcontinental Intergalactic Corp"
#property link      "http://tradelikeapro.ru/"
#property version   "3.24"
//#property strict

string                     ExpertName =                  "Milky way EA v3.24 m06";     // modification 6

extern string              Settings01 =                  "====Настройки входа====";
extern int                 BBPeriod =                    20;                           // Период Bollinger Bands
extern int                 MaxCandle =                   180;                          // Максимально допустимая сигнальная свеча
extern bool                OzymandiasFilter =            true;                         // Включить фильтр Озимандиас
input ENUM_TIMEFRAMES      OzymandiasTF =                1440;                         // Период для фильтра Озимандиас
extern int                 Amplitude =                   18;                           // Амплитуда Озимандиаса
extern bool                DemFilter =                   true;                         // Включить фильтр CCI
extern int                 DemPer =                      14;
extern double              DemB =                        0.1;
extern string              Settings02 =                  "===============================";
extern string              Exits01 =                     "====Настройки выхода====";
extern string              Exits02 =                     "-Стохастик";
extern bool                StochExit =                   true;                         // Включить выход по стоху
extern int                 KPer =                        11;
extern int                 DPer =                        3;
extern int                 SPer =                        3;
extern double              StochB =                      20;
extern string              Exits03 =                     "-MACD";
extern bool                MACDExit =                    true;                         // Включить выход по MACD
extern int                 FPer =                        1;
extern int                 SPEr =                        1;
int                 SIPer =                       1;
extern string              Exits04 =                     "-По волатильности";
extern bool                VolExit =                     true;                         // Включить выход по волатильности
extern int                 ATREPer =                     1;
extern double              BodyCoef =                    0.5;
extern double              ShadowCoef =                  0.5;
extern string              Exits05 =                     "===============================";

extern string              SL001 =                       "====Настройки варианта стопа====";
input ENUM_TIMEFRAMES      ExtrTimeframe =               0;                                 // Таймфрейм поиска экстремума для стоплосса
extern int                 HistorySL =                   10;                                // Поиск экстремума для стоплосса
extern int                 OtstupSL =                    60;                                // Отступ от хая/лоя в пунктах
extern bool                UseMaxSL =                    true;                              // Ставить максимальный стоплосс
extern double              MaxSL =                       100;                               // Максимальный стоплосс
extern double              MinSL =                       15;                                // Минимальный стоплосс
extern string              SL008 =                       "===============================";

extern string				TR001				=		"====Настройки трейлинг стопа====";
int							BEPlus				=		3;									// Уровень прибыли в пунктах к безубытку
int							TrailStep			=		1;									// Шаг трейлинга (минимальное приращение)

extern bool					UseTralOnlyInProfit	=		true;								// Тралить только в профите

extern bool					TralOnPips			=		true;								// Стандартный трейлинг
extern int					TrailingStop		=		20;									// Уровень трейлинга (расстояние от текущей цены)
extern int					TrailingStart		=		30;									// Уровень прибыли для включения трейлинга

extern bool					TralFraktalOn		=		true;								// Трейлинг по фракталам
input ENUM_TIMEFRAMES		FraktalTF			=		240;								// Таймфрейм для поиска фракталов
extern int					FraktalBars			=		5;
extern int					FraktalOtstup		=		3;

extern bool					TralBarsOn			=		true;								// Трейлинг по свечам
input ENUM_TIMEFRAMES		BarsTF				=		240;								// Таймфрейм для поиска свечей 
extern int					BarsUse				=		2;
extern int					BarsOtstup			=		3;
extern string				TR009				=		"===============================";

extern string              MMSet01 =                     "====Манименеджмент====";
extern int                 MaxRisk =                     10;                                 // Максимальный риск в процентах
extern int                 LotVariant =                  1;                                  // Вариант расчета лота (1-фикс, 2-0.01 лота на MoneyForOneLot баксов, 3-фикс риск (в %)
extern double              FixLot =                      0.1;
extern int                 MoneyForOneLot =              100;
extern double              Risk =                        3;
extern string              MMSet02 =                     "===============================";

extern string              Comment01 =                   "====Информация и сервисные настройки====";
extern int                 Slippage =                    1;
extern bool                UsePrint =                    false;
extern int                 Magic =                       0;                                 // Мэджик, если 0, бот генерит его сам.
extern bool                UsePanel =                    false;
extern int                 NumOfTry =                    3;
extern string              Comment02 =                   "===============================";

double MinLot,MaxLot,LotStep,PricePoint,StopLevel;

int PriceDigits,Sell=0,Buy=0,SellExit=0,BuyExit=0,LotDecimal=2;

datetime prevtime=Time[0];

bool NewCandle=false;

string obj_name;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
	MinLot      = MarketInfo( Symbol(), MODE_MINLOT );
	MaxLot      = MarketInfo( Symbol(), MODE_MAXLOT );
	LotStep     = MarketInfo( Symbol(), MODE_LOTSTEP );
	PricePoint  = GetPoint();
	StopLevel   = MarketInfo( Symbol(), MODE_STOPLEVEL );           // Минимально допустимый уровень стоп-лосса/тейк-профита в пунктах
	PriceDigits = Digits();
	if ( Magic == 0 ) Magic = makeMagicNumber(WindowExpertName() + Symbol() + IntegerToString(Period()));   // Генерация мэджика
	if ( PriceDigits == 5 || PriceDigits == 3 )
	{
		MaxCandle      *= 10;
		MaxSL          *= 10;
		MinSL          *= 10;
		BEPlus         *= 10;
		TrailStep      *= 10;
		TrailingStop   *= 10;
		TrailingStart  *= 10;
		Slippage       *= 10;
	}
	if (LotStep==1)    LotDecimal=0;
	if (LotStep==0.1)  LotDecimal=1;
	if (LotStep==0.01) LotDecimal=2;
	EAComment("Эксперт " + ExpertName + " начал работу на паре " + Symbol() + " с мэджиком " + IntegerToString( Magic ) );
	return ( INIT_SUCCEEDED );
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit( const int reason )
{
	DeleteAll();
	switch ( _UninitReason )
	{
	case REASON_ACCOUNT:
		EAComment("Советник остановлен по причине смены аккаунта.");
		break;
	case REASON_CHARTCHANGE:
		EAComment("Советник остановлен по причине смены символа или таймфрейма.");
		break;
	case REASON_CHARTCLOSE:
		EAComment("Советник остановлен по причине закрытия графика.");
		break;
	case REASON_PARAMETERS:
		EAComment("Советник остановлен по причине изменения исходных параметров.");
		break;
	case REASON_RECOMPILE:
		EAComment("Советник остановлен по причине декомпиляции.");
		break;
	case REASON_REMOVE:
		EAComment("Советник остановлен по причине удаления с графика.");
		break;
	case REASON_TEMPLATE:
		EAComment("Советник остановлен по причине загрузки нового шаблона.");
		break;
	default:
		EAComment("Советник остановлен");
	}
}

//+------------------------------------------------------------------+
//| Expert start function                                            |
//+------------------------------------------------------------------+
void OnTick()
{
	NewCandle = false;
	if( prevtime != Time[0] )
	{
		NewCandle = true;
		prevtime  = Time[0];
	}
	ChartPrint();
	if( NewCandle )
	{
		int signal = Signal();
		int signalexit = SignalExit();

		if( signal ==  1 ) OpenOrder( OP_BUY );
		if( signal == -1 ) OpenOrder( OP_SELL );

		if( ( signalexit == 1 && OrdExist( OP_BUY ) > 0 ) || (signalexit == -1 && OrdExist( OP_SELL ) > 0 ) )
		{
			CloseOrd();
		}
	}

	if( OrdExist( OP_BUY ) >0 || OrdExist( OP_SELL ) >0 )
	{
		TrailingStairs();
		TrailingByShadows();
		TrailingByFractals();
	}
}

//+------------------------------------------------------------------+
//|  Comments                                                        |
//+------------------------------------------------------------------+
void EAComment(const string st)
{
	if(!UsePrint) return;

	Print( TimeToStr( TimeLocal(), TIME_DATE) + ": " + ExpertName + "-" + Symbol() + ":  " + st );
}

//+------------------------------------------------------------------+
//| Сигнал на установку ордеров                                      |
//+------------------------------------------------------------------+
int Signal()
{
	int signal = 0;

	// Условия для открытия ордеров ( сигнал на установку отложеннх ордеров )
	double Low1          = iLow  ( Symbol(), Period(), 1 );
	double High1         = iHigh ( Symbol(), Period(), 1 );
	double Close1        = iClose( Symbol(), Period(), 1 );

	double Low2          = iLow  ( Symbol(), Period(), 2 );
	double High2         = iHigh ( Symbol(), Period(), 2 );

	double bb1_middle_1  = iBands( Symbol(), Period(), BBPeriod, 1, 0, 0, MODE_MAIN,  1 );
	double bb1_high_1    = iBands( Symbol(), Period(), BBPeriod, 1, 0, 0, MODE_UPPER, 1 );
	double bb1_low_1     = iBands( Symbol(), Period(), BBPeriod, 1, 0, 0, MODE_LOWER, 1 );

	double Dem           = iDeMarker(Symbol(), Period(), DemPer, 1);

	if (OrdExist(OP_BUY) == 0 && OrdExist(OP_BUYSTOP) == 0 && OrdExist(OP_SELL) == 0 && OrdExist(OP_SELLSTOP) == 0) // Если нет никаких ордеров
	{
		if (High1 - Low1 < MaxCandle * Point)			// Если размер сигнальной свечи [1] не больше порога
		{
			if (High2 - Low2 < MaxCandle * Point)		// Если размер свечи перед сигнальной [2] не больше порога
			{
				// Сигнал в покупку
				if (High2 > High1 && Low2 > Low1 && Close1 > Low1 + 0.5 * ( High1 - Low1 ) && Close1 < bb1_high_1 && Close1 > bb1_middle_1 && OzymandiasFilter( 1 ))
				{
					if (!DemFilter || (DemFilter && Dem < DemB))
					{
						EAComment("Buy signal detected.");
						
						Sleep(5000);	// Пауза на 5 секунд перед анализом риска. (Сделано для того, чтобы остальные работающие советники успели модифицировать или закрыть ордера)
						if (!AllRisk())	// Риск приемлем, устанавливаем сигнал
						{
							signal = 1;
							DrawFlag( 1 );
						}
						else EAComment("Buy order cannot be open | MaxRisk achieved"); // Риск превышен
						return(signal);
					}
				}

				// Сигнал в продажу
				if (High2 < High1 && Low2 < Low1 && Close1 < High1 - 0.5 * ( High1 - Low1 ) && Close1 > bb1_low_1 && Close1 < bb1_middle_1 && OzymandiasFilter( -1 ))
				{
					if (!DemFilter || (DemFilter && Dem > 1 - DemB))
					{
						EAComment("Sell signal detected.");
						
						Sleep(5000);	// Пауза на 5 секунд перед анализом риска. (Сделано для того, чтобы остальные работающие советники успели модифицировать или закрыть ордера)
						if (!AllRisk())	// Риск приемлем, устанавливаем сигнал
						{
							signal = -1;
							DrawFlag( -1 );
						}
						else EAComment("Sell order cannot be open | MaxRisk achieved"); // Риск превышен
						return(signal);
					}
				}
			}
		}
	}
	return(signal);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Функция гарантированного получения Point                         |
//+------------------------------------------------------------------+
double GetPoint()
{
	double gpPoint=0;
	gpPoint=MarketInfo(Symbol(),MODE_POINT);
	if (gpPoint==0)
	{
		if (PriceDigits>0) gpPoint=1/MathPow(10,PriceDigits);
		if (PriceDigits==0) gpPoint=0.00001;
	}
	return (gpPoint);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Сигнал на выход из позиции                                       |
//+------------------------------------------------------------------+

int SignalExit()
{
	int signal = 0;

	// Условия закрытия одного ордера ( сигнал на выход из позиции )
	double bb2_high_1 = iBands( Symbol(), Period(), BBPeriod, 2, 0, 0, MODE_UPPER, 1 );
	double bb2_high_2 = iBands( Symbol(), Period(), BBPeriod, 2, 0, 0, MODE_UPPER, 2 );
	double bb2_low_1  = iBands( Symbol(), Period(), BBPeriod, 2, 0, 0, MODE_LOWER, 1 );
	double bb2_low_2  = iBands( Symbol(), Period(), BBPeriod, 2, 0, 0, MODE_LOWER, 2 );
	//double bb2_mid_1  = iBands( Symbol(), Period(), BBPeriod, 2, 0, 0, MODE_MAIN,  1 );
	double Close1     = iClose( Symbol(), Period(), 1 );
	double Close2     = iClose( Symbol(), Period(), 2 );

	if (OrdExist( OP_BUY ) > 0 && Close2 >  bb2_high_2 && Close1 < bb2_high_1)
	{
		signal = 1;
		DrawFlag( 2 );
		EAComment("Signal to close buy order detected | Bollinger Bands signal");
		return(signal);
	}
	
	if (OrdExist( OP_SELL ) > 0 && Close2 < bb2_low_2 && Close1 >  bb2_low_1)
	{
		signal = -1;
		DrawFlag( -2 );
		EAComment("Signal to close sell order detected | Bollinger Bands signal");
		return(signal);
	}
	
	if (StochExit)
	{
		double Stoch1 = iStochastic(Symbol(), Period(), KPer, DPer, SPer, MODE_SMA, 0, MODE_MAIN, 1);
		double Stoch2 = iStochastic(Symbol(), Period(), KPer, DPer, SPer, MODE_SMA, 0, MODE_MAIN, 2);
	
		if (OrdExist( OP_BUY ) > 0 && Stoch2 >  100-StochB && Stoch1 < 100-StochB)
		{
			signal = 1;
			DrawFlag( 2 );
			EAComment("Signal to close buy order detected | Stochastic signal");
			return(signal);
		}
		if (OrdExist( OP_SELL ) > 0 && Stoch2 < StochB && Stoch1 >  StochB)
		{
			signal = -1;
			DrawFlag( -2 );
			EAComment("Signal to close sell order detected | Stochastic signal");
			return(signal);
		}
	}
	
	if (MACDExit)
	{
		double MACD1 = iMACD(Symbol(), Period(), FPer, SPEr, SIPer, PRICE_CLOSE, MODE_MAIN, 1);
		double MACD2 = iMACD(Symbol(), Period(), FPer, SPEr, SIPer, PRICE_CLOSE, MODE_MAIN, 2);
		
		if (OrdExist( OP_BUY ) > 0 && MACD2 >  0 && MACD1 < 0)
		{
			signal = 1;
			DrawFlag( 2 );
			EAComment("Signal to close buy order detected | MACD signal");
			return(signal);
		}
		if (OrdExist( OP_SELL ) > 0 && MACD2 < 0 && MACD1 >  0)
		{
			signal = -1;
			DrawFlag( -2 );
			EAComment("Signal to close sell order detected | MACD signal");
			return(signal);
		}
	}
	
	if (VolExit)
	{
		double ATR = iATR (Symbol(), Period(), ATREPer, 1);
		
		if (OrdExist( OP_BUY ) > 0 && MathAbs(Close[1]-Open[1])<ATR*BodyCoef&&High[1]-Low[1]<ATR*ShadowCoef
				&& MathAbs(Close[2]-Open[2])<ATR*BodyCoef&&High[2]-Low[2]<ATR*ShadowCoef
				&& MathAbs(Close[3]-Open[3])<ATR*BodyCoef&&High[3]-Low[3]<ATR*ShadowCoef)
		{
			signal = 1;
			DrawFlag( 2 );
			EAComment("Signal to close buy order detected | ATR signal");
			return(signal);
		}
		if (OrdExist( OP_SELL ) > 0 && MathAbs(Close[1]-Open[1])<ATR*BodyCoef&&High[1]-Low[1]<ATR*ShadowCoef
				&& MathAbs(Close[2]-Open[2])<ATR*BodyCoef&&High[2]-Low[2]<ATR*ShadowCoef
				&& MathAbs(Close[3]-Open[3])<ATR*BodyCoef&&High[3]-Low[3]<ATR*ShadowCoef)
		{
			signal = -1;
			DrawFlag( -2 );
			EAComment("Signal to close sell order detected | ATR signal");
			return(signal);
		}
	}
	
	return(signal);
}
//+------------------------------------------------------------------+


bool OzymandiasFilter( int dir )
{
	if( !OzymandiasFilter )
	return( true );
	if( OzymandiasFilter )
	{
		double Up = iCustom( Symbol(), OzymandiasTF, "Ozymandias", Amplitude, 0, 1 );
		double Dn = iCustom( Symbol(), OzymandiasTF, "Ozymandias", Amplitude, 1, 1 );
		if( dir ==  1 && Up > 0 ) return( true );
		if( dir == -1 && Dn > 0 ) return( true );
	}
	return( false );
}

//+------------------------------------------------------------------+
//| Draw arrow if signal to enter                                    |
//+------------------------------------------------------------------+
void DrawFlag( int dir )
{
	if( dir == -1 )
	{
		obj_name = "SignalSell_"+IntegerToString(Sell);
		ObjectCreate(obj_name,OBJ_ARROW,0,0,0);
		ObjectSet(obj_name,OBJPROP_ARROWCODE,68);
		ObjectSet(obj_name,OBJPROP_COLOR,Red);
		ObjectSet(obj_name,OBJPROP_PRICE1,High[1]+20*PricePoint);
		ObjectSet(obj_name,OBJPROP_WIDTH,4);
		ObjectSet(obj_name,OBJPROP_TIME1,Time[0]);
		Sell++;
	}
	if( dir == 1 )
	{
		obj_name = "SignalBuy_"+IntegerToString(Buy);
		ObjectCreate(obj_name,OBJ_ARROW,0,0,0);
		ObjectSet(obj_name,OBJPROP_ARROWCODE,67);
		ObjectSet(obj_name,OBJPROP_COLOR,Blue);
		ObjectSet(obj_name,OBJPROP_PRICE1,Low[1]-20*PricePoint);
		ObjectSet(obj_name,OBJPROP_WIDTH,4);
		ObjectSet(obj_name,OBJPROP_TIME1,Time[0]);
		Buy++;
	}
	if( dir == -2 )
	{
		obj_name = "SignalSellExit_"+IntegerToString(SellExit);
		ObjectCreate(obj_name,OBJ_ARROW,0,0,0);
		ObjectSet(obj_name,OBJPROP_ARROWCODE,74);
		ObjectSet(obj_name,OBJPROP_COLOR,Green);
		ObjectSet(obj_name,OBJPROP_PRICE1,High[1]+20*PricePoint);
		ObjectSet(obj_name,OBJPROP_WIDTH,4);
		ObjectSet(obj_name,OBJPROP_TIME1,Time[0]);
		SellExit++;
	}
	if( dir == 2 )
	{
		obj_name = "SignalBuyExit_"+IntegerToString(BuyExit);
		ObjectCreate(obj_name,OBJ_ARROW,0,0,0);
		ObjectSet(obj_name,OBJPROP_ARROWCODE,74);
		ObjectSet(obj_name,OBJPROP_COLOR,Green);
		ObjectSet(obj_name,OBJPROP_PRICE1,Low[1]-20*PricePoint);
		ObjectSet(obj_name,OBJPROP_WIDTH,4);
		ObjectSet(obj_name,OBJPROP_TIME1,Time[0]);
		BuyExit++;
	}
}

//+---------------------------------------------------------------------+
//| Возвращает количество ордеров заданного направления по текущей паре |
//+---------------------------------------------------------------------+
int OrdExist(const int direction)
{
	int OrdCount = 0;
	for (int i = OrdersTotal() - 1; i >= 0; i--)
	{
		if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
		if (OrderMagicNumber() != Magic || OrderSymbol() != Symbol()) continue;
		if (OrderType() == direction) OrdCount++;
	}
	return (OrdCount);
}

//+----------------------------------------+
//| Открытие ордера в заданном направлении |
//+----------------------------------------+
void OpenOrder(const int direction)
{
	double	OpenPrice	= 0, 
			StopLoss	= 0, 
			SL			= 0,
			Lot			= 0;
			
	int n = 0, ticket = -1;

	if (direction == OP_SELL)
	{
		OpenPrice = Bid;
		StopLoss  = StopLoss(OP_SELL, OpenPrice);
		SL        = NormalizeDouble((StopLoss - OpenPrice) / Point, 0);
		if (SL > MaxSL)
		{
			if (!UseMaxSL)
			{
				EAComment("Стоплосс слишком большой!");
				return;
			}
			if (UseMaxSL)
			{
				StopLoss	= NormalizeDouble(OpenPrice + MaxSL * PricePoint, Digits());
				SL			= MaxSL;
				EAComment("Стоплосс слишком большой! Параметр UseMaxSL включен. Используем MaxSL=" + MaxSL + " пунктов.");
			}
		}
		if (SL < MinSL)
		{
			StopLoss	= NormalizeDouble(OpenPrice + MinSL * PricePoint, Digits());
			SL			= MinSL;
		}
		Lot = Lots(SL, OpenPrice);
		for (n = 1; n <= MathMax(1, NumOfTry); n++)
		{
			ticket = OrderSend(Symbol(), OP_SELL, Lot, OpenPrice, Slippage, StopLoss, 0, ExpertName + " Magic:" + IntegerToString(Magic), Magic, 0, Red);
			if (ticket >= 0) break;
			Sleep(1000);
			RefreshRates();
		}
		Sleep(5000);
		if (ticket < 0) EAComment("Error of sending sell order!: " + GetLastError());
		else
		{
			if (OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) EAComment("Sell order opened! Price: " + OrderOpenPrice());
			else EAComment("Sell order opened, but OrderSelect() failed!");
		}
	}

	if (direction == OP_BUY)
	{
		OpenPrice = Ask;
		StopLoss  = StopLoss(OP_BUY, OpenPrice);
		SL        = NormalizeDouble((OpenPrice - StopLoss) / Point, 0);
		if (SL > MaxSL)
		{
			if (!UseMaxSL)
			{
				EAComment("Стоплосс слишком большой!");
				return;
			}
			if (UseMaxSL)
			{
				StopLoss	= NormalizeDouble(OpenPrice - MaxSL * PricePoint, Digits());
				SL			= MaxSL;
				EAComment("Стоплосс слишком большой! Параметр UseMaxSL включен. Используем MaxSL=" + MaxSL + " пунктов.");
			}
		}
		if (SL < MinSL)
		{
			StopLoss	= NormalizeDouble(OpenPrice - MinSL * PricePoint, Digits());
			SL			= MinSL;
		}
		Lot = Lots(SL, OpenPrice);
		for (n = 1; n <= MathMax(1, NumOfTry); n++)
		{
			ticket = OrderSend(Symbol(), OP_BUY, Lot, OpenPrice, Slippage, StopLoss, 0, ExpertName + " Magic:" + IntegerToString( Magic ), Magic, 0, Blue);
			if (ticket >= 0) break;
			Sleep(1000);
			RefreshRates();
		}
		Sleep(5000);
		if (ticket < 0) EAComment("Error of sending buy order!: " + GetLastError());
		else
		{
			if (OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) EAComment("Buy order opened! Price: " + OrderOpenPrice());
			else EAComment("Buy order opened, but OrderSelect() failed!");
		}
	}
}

//+------------------------------------------------------------------+
//| Закрытие ордера / ордеров для текущего символа                   |
//+------------------------------------------------------------------+
void CloseOrd()
{
	for (int i = OrdersTotal() - 1; i >= 0; i--)
	{
		if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
		if (OrderMagicNumber() != Magic || OrderSymbol() != Symbol()) continue;

		int n = 0;
		bool closed = false;

		if (OrderType() == OP_SELL)
		{
			for (n = 1; n <= MathMax(1, NumOfTry); n++)
			{
				closed = OrderClose( OrderTicket(), OrderLots(), Ask, Slippage, Green);
				if (closed) break;
				Sleep(1000);
				RefreshRates();
			}
			Sleep(5000);
			if (closed) EAComment("Sell order closed! Price: " + OrderClosePrice());
			else EAComment("Error of closing sell order!: " + GetLastError());
			continue;
		}
		if (OrderType() == OP_BUY)
		{
			for (n = 1; n <= MathMax(1, NumOfTry); n++)
			{
				closed = OrderClose( OrderTicket(), OrderLots(), Bid, Slippage, Green);
				if (closed) break;
				Sleep(1000);
				RefreshRates();
			}
			Sleep(5000);
			if (closed) EAComment("Buy order closed! Price: " + OrderClosePrice());
			else EAComment("Error of closing buy order!: " + GetLastError());
			continue;
		}
	}
}

//+--------------------------------------------------------------------------------------------+
//| Расчет максимального риска в процентах для ВСЕХ позиций на счете, имеющих уровень StopLoss |
//+--------------------------------------------------------------------------------------------+
bool AllRisk()
{
	double currRiskInPercent   = 0;

	for (int i = OrdersTotal() - 1; i >= 0; i--)
	{
		if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
		if (OrderStopLoss() == 0) continue;

		double distanceInPoints = 0;
		if (OrderType() == OP_SELL && OrderOpenPrice() < OrderStopLoss())
		{
			distanceInPoints  = (OrderStopLoss() - OrderOpenPrice()) / Point;
			currRiskInPercent = currRiskInPercent + (distanceInPoints * OrderLots() / AccountBalance()) * 100;
		}
		if (OrderType() == OP_BUY  && OrderOpenPrice() > OrderStopLoss())
		{
			distanceInPoints  = (OrderOpenPrice() - OrderStopLoss()) / Point;
			currRiskInPercent = currRiskInPercent + (distanceInPoints * OrderLots() / AccountBalance()) * 100;
		}
	}

	currRiskInPercent = NormalizeDouble(currRiskInPercent, 2);	// rounding

	currRiskInPercent = MathMax(currRiskInPercent, 0);			// if currRiskInPercent < 0
	currRiskInPercent = MathMin(currRiskInPercent, 100);		// if currRiskInPercent > 100

	if (currRiskInPercent > MaxRisk)
	{
		EAComment("Achieved the maximum level of risk! (" + currRiskInPercent + " percent | MaxRisk: " + MaxRisk + " percent)");
		return(true);
	}
	return(false);
}

//+------------------------------------------------------------------+
//| Текущий профит по паре                                           |
//+------------------------------------------------------------------+
double TekProfit()
{
	double TekProfit = 0;
	for (int i = OrdersTotal() - 1; i >= 0; i--)
	{
		if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
		if (OrderMagicNumber() != Magic || OrderSymbol() != Symbol()) continue;
		if (OrderType() == OP_SELL)
		{
			TekProfit = TekProfit + (OrderOpenPrice() - Bid);
			continue;
		}
		if (OrderType() == OP_BUY)
		{
			TekProfit = TekProfit + (Ask - OrderOpenPrice());
			continue;
		}
	}
	return(TekProfit);
}

//+------------------------------------------------------------------+
//| Лоты                                                             |
//+------------------------------------------------------------------+
double Lots(double Stop, double OpenPrice)
{
	double Lot=0;
	switch(LotVariant)
	{
	case 1: Lot=fixed_lot(); break;
	case 2: Lot=fix_prop();  break;
	case 3: Lot=Risk_lot(Stop,OpenPrice);  break;
	}
	return(NormalizeLot(Lot));
}

//+------------------------------------------------------------------+
//| Фикс лот                                                         |
//+------------------------------------------------------------------+
double fixed_lot()
{
	double Lot=FixLot;
	return (Lot);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Фикс пропорция                                                   |
//+------------------------------------------------------------------+
double fix_prop()
{
	double Lot;
	if (AccountBalance()<MoneyForOneLot) Lot=MinLot;
	else Lot=(AccountBalance()/MoneyForOneLot)*MinLot;
	return (Lot);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Риск %                                                           |
//+------------------------------------------------------------------+
double Risk_lot(double Stop, double OpenPrice)
{
	double Lot=0;
	Lot=AccountBalance()*(Risk/100)/Stop;
	return (Lot);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Функция генерирует уникальный мэджик                             |
//+------------------------------------------------------------------+
int makeMagicNumber(string key)
{
	int i, n;
	int h = 0;
	if (IsTesting())
	{
		key = "_" + key;
	}

	for (i = 0; i < StringLen(key); i++)
	{
		n = StringGetChar(key, i);
		h = h + n;
		h = bitRotate(h, 5);
	}

	for (i = 0; i < StringLen(key); i++)
	{
		n = StringGetChar(key, i);
		h = h + n;
		h = bitRotate(h, n & 0x0000000F);
	}

	for (i = StringLen(key); i > 0; i--)
	{
		n = StringGetChar(key, i - 1);
		h = h + n;
		h = bitRotate(h, h & 0x0000000F);
	}

	return(h & 0x7fffffff);
}

int bitRotate(int value, int count)
{
	int tmp, mask;
	mask = (0x00000001 << count) - 1;
	tmp = value & mask;
	value = value >> count;
	value = value | (tmp << (32 - count));
	return(value);
}

//+------------------------------------------------------------------+
//| Функция нормализации лота                                        |
//+------------------------------------------------------------------+
double NormalizeLot(double Lot)
{
	double NormLot;
	NormLot=NormalizeDouble(Lot,LotDecimal);
	if (NormLot<MinLot)
	{
		NormLot=MinLot;
		EAComment("Лот меньше минимального. Установлен минимальный.");
	}
	if (NormLot>MaxLot)
	{
		NormLot=MaxLot;
		EAComment("Лот больше максимального. Установлен максимальный.");
	}
	return (NormLot);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|  Стопы                                                           |
//+------------------------------------------------------------------+
double StopLoss(const int direction, const double OpenPrice)
{
	double StopLossPrice = 0;
	
	if (direction == OP_BUY || direction == OP_BUYLIMIT || direction == OP_BUYSTOP)
	{
		StopLossPrice = Extremum(HistorySL, -1, ExtrTimeframe) - OtstupSL * PricePoint;
		if (StopLossPrice > OpenPrice - MinSL * PricePoint)
			StopLossPrice = OpenPrice - MinSL * PricePoint;
		return NormalizeDouble(StopLossPrice, Digits);
	}
	
	if (direction == OP_SELL || direction == OP_SELLLIMIT || direction == OP_SELLSTOP)
	{
		StopLossPrice = Extremum(HistorySL, 1, ExtrTimeframe) + OtstupSL * PricePoint;
		if (StopLossPrice < OpenPrice + MinSL * PricePoint)
			StopLossPrice = OpenPrice + MinSL * PricePoint;
		return NormalizeDouble(StopLossPrice, Digits);
	}

	EAComment("StopLoss() error.");
	return(-1); // means error
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Функция получения экстремума                                     |
//+------------------------------------------------------------------+
double Extremum (int hist, int mode, int Timeframe)
{
	double extremum=0;
	if (mode==-1) extremum=iLow(Symbol(),Timeframe,iLowest(Symbol(),Timeframe,MODE_LOW,hist,1));
	if (mode==1)  extremum=iHigh(Symbol(),Timeframe,iHighest(Symbol(),Timeframe,MODE_HIGH,hist,1));
	return (extremum);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Функция нормализации цены                                        |
//+------------------------------------------------------------------+
// Получает ненормализованную цену, возвращает нормализованную
double NormalizePrice( double Price )
{
	double NormPrice = 0;
	if( Price <= 0 )
	return( -1 );
	else
	{
		NormPrice = NormalizeDouble( Price, PriceDigits );
		return( NormPrice );
	}
	return( 0 );
}

//+------------------------------------------------------------------+
//| Удаляет все объекты с графика                                    |
//+------------------------------------------------------------------+
void DeleteAll()
{
	int total=ObjectsTotal()-1;
	for(int i=total;i>=0;i--)
	{
		string name=ObjectName(i);
		ObjectDelete(name);
	}
}

//+------------------------------------------------------------------+
//| Вывод на график                                                  |
//+------------------------------------------------------------------+
void ChartPrint()
{
	if( UsePanel )
	{
		//DeleteAll();
		MainPanel();
	}
}

//+------------------------------------------------------------------+
//| Функция выводит основную панель                                  |
//+------------------------------------------------------------------+
void MainPanel()
{
	double ChartX=ChartWidthInPixels();
	double ChartY=ChartHighInPixels();
	double Shrift01=MathCeil(0.02*ChartY);
	double Shrift02=MathCeil(0.015*ChartY);
	double Shrift03=MathCeil(0.015*ChartY);
	double Shrift04=MathCeil(0.012*ChartY);
	color      TopMenuColor =       PowderBlue;
	color      TopShriftColor =     Maroon;
	color      BodyMenuColor =      Ivory;
	color      BodyShriftColor =    DodgerBlue;
	color      BoarderColor =       LightSlateGray;
	double     TekProfitPips=0;

	CreateLabel("InfoPanel1",0,0,0.1*ChartY,0.30*ChartX,0.18*ChartY,BodyMenuColor,BoarderColor,0,CORNER_LEFT_UPPER,BORDER_FLAT); // Основная панель
	CreateLabel("InfoPanel2",0,0,0.05*ChartY,0.30*ChartX,0.05*ChartY,TopMenuColor,BoarderColor,0,CORNER_LEFT_UPPER,BORDER_FLAT);// Панель с названием
	CreateText("Expert Name",0,0.11*ChartX,0.06*ChartY,CORNER_LEFT_UPPER,ExpertName,"Arial",Shrift01,TopShriftColor);

	CreateText("Balance",0,0.01*ChartX,0.11*ChartY,CORNER_LEFT_UPPER,"Баланс: "+DoubleToString(AccountBalance(),2)+" "+AccountCurrency(),"Arial",Shrift02,BodyShriftColor);
	CreateText("Equity",0,0.15*ChartX,0.11*ChartY,CORNER_LEFT_UPPER,"Эквити: "+DoubleToString(AccountEquity(),2)+" "+AccountCurrency(),"Arial",Shrift02,BodyShriftColor);
	CreateText("Free",0,0.01*ChartX,0.14*ChartY,CORNER_LEFT_UPPER,"Свободно: "+DoubleToString(AccountInfoDouble(ACCOUNT_FREEMARGIN),2)+" "+AccountCurrency(),"Arial",Shrift02,BodyShriftColor);
	CreateText("Margin",0,0.15*ChartX,0.14*ChartY,CORNER_LEFT_UPPER,"Залог: "+DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN),2)+" "+AccountCurrency(),"Arial",Shrift02,BodyShriftColor);
	CreateText("MarginLevel",0,0.01*ChartX,0.17*ChartY,CORNER_LEFT_UPPER,"Ур. маржи: "+DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN_LEVEL),2)+" %","Arial",Shrift02,BodyShriftColor);
	CreateText("Profit1",0,0.15*ChartX,0.17*ChartY,CORNER_LEFT_UPPER,"Тек. прибыль: "+DoubleToString(AccountInfoDouble(ACCOUNT_PROFIT),2)+" "+AccountCurrency(),"Arial",Shrift02,BodyShriftColor);

	// Текущая прибыль/убыток в пунктах
	if(OrdersTotal()==0) TekProfitPips=0;
	if(OrdersTotal()>0)
	{
		for(int i=0;i<OrdersTotal();i++)
		{
			if (!OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
			{
				EAComment("Ошибка доступа к истории!");
				break;
			}
			if (OrderType()==0) TekProfitPips=(Bid-OrderOpenPrice())/Point;
			if (OrderType()==1) TekProfitPips=(OrderOpenPrice()-Ask)/Point;
			if (OrderType()>1)  TekProfitPips=0;
		}
	}
	CreateText("Profit2",0,0.01*ChartX,0.2*ChartY,CORNER_LEFT_UPPER,"Тек. прибыль: "+DoubleToString((AccountInfoDouble(ACCOUNT_PROFIT)/AccountBalance())*100,2)+" %","Arial",Shrift02,BodyShriftColor);
	CreateText("Profit3",0,0.15*ChartX,0.2*ChartY,CORNER_LEFT_UPPER,"Тек. прибыль: "+DoubleToString(TekProfitPips,0)+" pips","Arial",Shrift02,BodyShriftColor);
	CreateText("Risk1",0,0.01*ChartX,0.24*ChartY,CORNER_LEFT_UPPER,"Тек. риск общий: "+DoubleToString(AllRisk(),2)+" "+"%","Arial",Shrift02,BodyShriftColor);
}

//+------------------------------------------------------------------+
//| Функция получает значение высоты графика в пикселях.             |
//+------------------------------------------------------------------+
int ChartHighInPixels()
{
	//--- подготовим переменную для получения значения свойства
	long result=-1;
	//--- сбросим значение ошибки
	ResetLastError();
	//--- получим значение свойства
	if(!ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS,0,result))
	{
		//--- выведем сообщение об ошибке в журнал "Эксперты"
		Print(__FUNCTION__+", Error Code = ",GetLastError());
	}
	//--- вернем значение свойства графика
	return((int)result);
}

//+------------------------------------------------------------------+
//| Функция получает значение ширины графика в пикселях.             |
//+------------------------------------------------------------------+
int ChartWidthInPixels()
{
	//--- подготовим переменную для получения значения свойства
	long result=-1;
	//--- сбросим значение ошибки
	ResetLastError();
	//--- получим значение свойства
	if(!ChartGetInteger(0,CHART_WIDTH_IN_PIXELS,0,result))
	{
		//--- выведем сообщение об ошибке в журнал "Эксперты"
		Print(__FUNCTION__+", Error Code = ",GetLastError());
	}
	//--- вернем значение свойства графика
	return((int)result);
}

//+------------------------------------------------------------------+
//| Создает надпись                                                  |
//+------------------------------------------------------------------+
void CreateText(string Name,int subwindow,int x,int y,int corner,string text,string font,int font_size,color clr)
{
	ObjectCreate(0,Name,OBJ_LABEL,subwindow,0,0);
	// установим координаты метки
	ObjectSetInteger(0,Name,OBJPROP_XDISTANCE,x);
	ObjectSetInteger(0,Name,OBJPROP_YDISTANCE,y);
	// установим угол графика, относительно которого будут определяться координаты точки
	ObjectSetInteger(0,Name,OBJPROP_CORNER,corner);
	// установим текст
	ObjectSetString(0,Name,OBJPROP_TEXT,text);
	// установим шрифт текста
	ObjectSetString(0,Name,OBJPROP_FONT,font);
	// установим размер шрифта
	ObjectSetInteger(0,Name,OBJPROP_FONTSIZE,font_size);
	// установим угол наклона текста
	ObjectSetDouble(0,Name,OBJPROP_ANGLE,0);
	// установим способ привязки
	ObjectSetInteger(0,Name,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);
	// установим цвет
	ObjectSetInteger(0,Name,OBJPROP_COLOR,clr);
	// отобразим на переднем (false) или заднем (true) плане
	ObjectSetInteger(0,Name,OBJPROP_BACK,false);
	// включим (true) или отключим (false) режим перемещения метки мышью
	ObjectSetInteger(0,Name,OBJPROP_SELECTABLE,false);
	ObjectSetInteger(0,Name,OBJPROP_SELECTED,false);
	// скроем (true) или отобразим (false) имя графического объекта в списке объектов
	ObjectSetInteger(0,Name,OBJPROP_HIDDEN,true);
}

//+------------------------------------------------------------------+
//| Создает панель                                                   |
//+------------------------------------------------------------------+
void CreateLabel(string Name, int subwindow, int x,int y,int xsize, int ysize, color PanelColor, color BorderColor, int BorderWidth, int Privyazka, int BorderType)
{
	// Рисуем панель основных данных
	ObjectCreate(0,Name,OBJ_RECTANGLE_LABEL,subwindow,0,0);
	// установим координаты метки
	ObjectSetInteger(0,Name,OBJPROP_XDISTANCE,x);
	ObjectSetInteger(0,Name,OBJPROP_YDISTANCE,y);
	// установим размеры метки
	ObjectSetInteger(0,Name,OBJPROP_XSIZE,xsize);
	ObjectSetInteger(0,Name,OBJPROP_YSIZE,ysize);
	// установим цвет фона
	ObjectSetInteger(0,Name,OBJPROP_BGCOLOR,PanelColor);
	// установим тип границы
	ObjectSetInteger(0,Name,OBJPROP_BORDER_TYPE,BorderType); //BORDER_FLAT, BORDER_RAISED, BORDER_SUNKEN
	// установим угол графика, относительно которого будут определяться координаты точки
	ObjectSetInteger(0,Name,OBJPROP_CORNER,Privyazka);
	// установим цвет плоской рамки (в режиме Flat)
	ObjectSetInteger(0,Name,OBJPROP_COLOR,BorderColor);
	// установим стиль линии плоской рамки
	ObjectSetInteger(0,Name,OBJPROP_STYLE,STYLE_SOLID); //STYLE_SOLID,STYLE_DASH,STYLE_DOT,STYLE_DASHDOT,STYLE_DASHDOTDOT
	// установим толщину плоской границы
	ObjectSetInteger(0,Name,OBJPROP_WIDTH,BorderWidth);
	// отобразим на переднем (false) или заднем (true) плане
	ObjectSetInteger(0,Name,OBJPROP_BACK,true);
	// включим (true) или отключим (false) режим перемещения метки мышью
	ObjectSetInteger(0,Name,OBJPROP_SELECTABLE,false);
	ObjectSetInteger(0,Name,OBJPROP_SELECTED,false);
	// скроем (true) или отобразим (false) имя графического объекта в списке объектов
	ObjectSetInteger(0,Name,OBJPROP_HIDDEN,true);
}
//+----------------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Возвращает цену открытия последней открытой рыночной позиции     |
//+------------------------------------------------------------------+
double LastPosOpenPrice(int dir)
{
	int j=-1;
	datetime t=0;
	if(OrdExist(OP_BUY)>0||OrdExist(OP_SELL)>0)
	{
		for(int i=OrdersTotal(); i>=0; i--)
		{
			if (!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) continue;
			if (OrderMagicNumber()!=Magic||OrderSymbol()!=Symbol()) continue;
			if (OrderType()==OP_BUY&&OrderType()==dir)
			{
				if (t<OrderOpenTime())
				{
					t=OrderOpenTime();
					j=i;
				}
			}
			if (OrderType()==OP_SELL&&OrderType()==dir)
			{
				if (t<OrderOpenTime())
				{
					t=OrderOpenTime();
					j=i;
				}
			}
		}
		if (OrderSelect(j,SELECT_BY_POS,MODE_TRADES))
		{
			return(OrderOpenPrice());
		}
	}
	return(0);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Возвращает стоплосс последней открытой рыночной позиции          |
//+------------------------------------------------------------------+
double LastPosStopPrice(int dir)
{
	int j=-1;
	datetime t=0;
	if(OrdExist(OP_BUY)>0||OrdExist(OP_SELL)>0)
	{
		for(int i=OrdersTotal(); i>=0; i--)
		{
			if (!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) continue;
			if (OrderMagicNumber()!=Magic||OrderSymbol()!=Symbol()) continue;
			if (OrderType()==OP_BUY&&OrderType()==dir)
			{
				if (t<OrderOpenTime())
				{
					t=OrderOpenTime();
					j=i;
				}
			}
			if (OrderType()==OP_SELL&&OrderType()==dir)
			{
				if (t<OrderOpenTime())
				{
					t=OrderOpenTime();
					j=i;
				}
			}
		}
		if (OrderSelect(j,SELECT_BY_POS,MODE_TRADES))
		{
			return(OrderStopLoss());
		}
	}
	return(0);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Возвращает лот последней открытой рыночной позиции               |
//+------------------------------------------------------------------+
double LastPosLot(int dir)
{
	int j=-1;
	datetime t=0;
	if(OrdExist(OP_BUY)>0||OrdExist(OP_SELL)>0)
	{
		for(int i=OrdersTotal(); i>=0; i--)
		{
			if (!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) continue;
			if (OrderMagicNumber()!=Magic||OrderSymbol()!=Symbol()) continue;
			if (OrderType()==OP_BUY&&OrderType()==dir)
			{
				if (t<OrderOpenTime())
				{
					t=OrderOpenTime();
					j=i;
				}
			}
			if (OrderType()==OP_SELL&&OrderType()==dir)
			{
				if (t<OrderOpenTime())
				{
					t=OrderOpenTime();
					j=i;
				}
			}
		}
		if (OrderSelect(j,SELECT_BY_POS,MODE_TRADES))
		{
			return(OrderLots());
		}
	}
	return(0);
}
//+------------------------------------------------------------------+

//+-------------------------------------------------------------------------------------------------------------+
//| Функция расчитывает цену безубытка ордеров в заданном направлении или для всех ордеров для текущего символа |
//+-------------------------------------------------------------------------------------------------------------+
double PriceBE(const int dir)
{
	double BuyLots    = 0;
	double SellLots   = 0;
	double BuyProfit  = 0;
	double SellProfit = 0;
	double BuyLevel   = 0;
	double SellLevel  = 0;
	double BEPrice    = 0;

	for (int i = OrdersTotal() - 1; i >= 0; i--)
	{
		if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
		if (OrderMagicNumber() != Magic || OrderSymbol() != Symbol()) continue;
		if (OrderType() == OP_BUY)
		{
			BuyLots     =  BuyLots + OrderLots();
			BuyProfit   =  BuyProfit + OrderProfit() + OrderCommission() + OrderSwap();
			continue;
		}
		if (OrderType() == OP_SELL)
		{
			SellLots    =  SellLots + OrderLots();
			SellProfit  =  SellProfit + OrderProfit() + OrderCommission() + OrderSwap();
			continue;
		}
	}

	double TickValue = MarketInfo(Symbol(), MODE_TICKVALUE);	
	
	if (dir == OP_BUY)
	{
		if (BuyLots > 0)
		{
			BuyLevel  = NormalizeDouble(Bid - (BuyProfit / (TickValue * BuyLots) * Point), Digits);
		}
		else BuyLevel = 0;
		return(NormalizeDouble(BuyLevel, Digits));
	}
	
	if (dir == OP_SELL)
	{
		if (SellLots > 0)
		{
			SellLevel = NormalizeDouble(Ask + (SellProfit / (TickValue * SellLots) * Point), Digits);
		}
		else SellLevel = 0;
		return(NormalizeDouble(SellLevel, Digits));
	}
	
	if (dir == -1)
	{
		if ((BuyLots - SellLots) > 0) BEPrice   = NormalizeDouble(Bid - ((BuyProfit + SellProfit) / (TickValue * (BuyLots - SellLots)) * Point), Digits);
		if ((SellLots - BuyLots) > 0) BEPrice   = NormalizeDouble(Ask + ((BuyProfit + SellProfit) / (TickValue * (SellLots - BuyLots)) * Point), Digits);
		return(NormalizeDouble(BEPrice, Digits));
	}

	EAComment("Invalid argumet for PriceBE() passed.");
	return(-1); // means error
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Стандартный трейлинг                                             |
//+------------------------------------------------------------------+
// Трал включается на расстоянии TrailingStart и ведется на расстоянии TrailingStop от цены с шагом TrailStep

void TrailingStairs()
{
	if(!TralOnPips)
	   return;
   
	if (TrailingStart < TrailingStop)
	{
		EAComment("TrailingStart < TrailingStop (" + TrailingStart + "<" + TrailingStop + ")" +
		" | From now TrailingStop = TrailingStart (" + TrailingStart + ")");
		TrailingStop = TrailingStart;
	}
   
	double   PriceBEBuy  = PriceBE(OP_BUY),		// для одного ордера == OrderOpenPrice() (с учетом комиссий и свопа)
	         PriceBESell = PriceBE(OP_SELL);

	for (int i = OrdersTotal() - 1; i >= 0; i--)
	{
		if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
		if (OrderMagicNumber() != Magic || OrderSymbol() != Symbol()) continue;

		double newStopLossPrice = -1;

		if (OrderType() == OP_BUY)
		{
			if (Bid - OrderOpenPrice() > TrailingStart * Point)											// Трал включается на расстоянии TrailingStart от цены открытия ордера
			{
				newStopLossPrice = NormalizeDouble(Bid - TrailingStop * Point, Digits);				 	// и ведется на расстоянии TrailingStop от цены

				if (UseTralOnlyInProfit && newStopLossPrice < PriceBEBuy) continue;						// Тралить только в профите, если UseTralOnlyInProfit == true;
							
				if ((newStopLossPrice > OrderStopLoss() + TrailStep * Point) || OrderStopLoss() == 0) 	// с шагом TrailStep
				{
					if (!OrderModify(OrderTicket(), OrderOpenPrice(), newStopLossPrice, OrderTakeProfit(), OrderExpiration()))
					{
						EAComment("Error TrailingStairs! Error " + GetLastError());
					}
					else EAComment("Order was modified. Standard trailing stop");
				}
			}
			continue;
		}
		if (OrderType() == OP_SELL)
		{
			if (OrderOpenPrice() - Ask > TrailingStart * Point)											// Трал включается на расстоянии TrailingStart от цены открытия ордера
			{
				newStopLossPrice = NormalizeDouble(Ask + TrailingStop * Point, Digits);					// и ведется на расстоянии TrailingStop от цены
				
				if (UseTralOnlyInProfit && newStopLossPrice > PriceBESell) continue;					// Тралить только в профите, если UseTralOnlyInProfit == true;
				
				if ((newStopLossPrice < OrderStopLoss() - TrailStep * Point) || OrderStopLoss() == 0)	// с шагом TrailStep
				{
					if (!OrderModify(OrderTicket(), OrderOpenPrice(), newStopLossPrice, OrderTakeProfit(), OrderExpiration()))
					{
						EAComment("Error TrailingStairs! Error " + GetLastError());
					}
					else EAComment("Order was modified. Standard trailing stop");
				}
			}
			continue;
		}
	}
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
void TrailingByShadows()
{
   if(!TralBarsOn)
      return;
  
	if (BarsUse < 1 || BarsOtstup < 0)
	{
		EAComment("Trailing TrailingByShadows() Error.");
		return;
	}

	double   PriceBEBuy     = PriceBE(OP_BUY),
	         PriceBESell    = PriceBE(OP_SELL),
	         new_extremum   = -1;

	for (int j = OrdersTotal() - 1; j >= 0; j--)
	{
		if (!OrderSelect(j, SELECT_BY_POS, MODE_TRADES)) continue;
		if (OrderMagicNumber() != Magic || OrderSymbol() != Symbol()) continue;

		int i;
		double curr_extremum    = -1;
		double newStopLossPrice = -1;

		if (OrderType() == OP_BUY)
		{
			new_extremum = iLow(Symbol(), BarsTF, 1);
			for(i = 2; i <= BarsUse; i++)
			{
			   curr_extremum = iLow(Symbol(), BarsTF, i);
			   if (new_extremum > curr_extremum) new_extremum = curr_extremum;
			}

			newStopLossPrice  = NormalizeDouble(new_extremum - BarsOtstup * Point, Digits);
			
			if (UseTralOnlyInProfit && newStopLossPrice < PriceBEBuy) continue;		// Тралить только в профите, если UseTralOnlyInProfit == true;

			if (  (newStopLossPrice > OrderStopLoss() || OrderStopLoss() == 0) &&
               (newStopLossPrice < Bid - MarketInfo(Symbol(), MODE_STOPLEVEL) * Point) )
			{
				if (!OrderModify(OrderTicket(), OrderOpenPrice(), newStopLossPrice, OrderTakeProfit(), OrderExpiration()))
				{
					EAComment("Error TrailingByShadows! Error " + GetLastError());
				}
				else EAComment("Order was modified. High/Low trailing stop");
			}
			continue;
		}
		if (OrderType() == OP_SELL)
		{
			new_extremum = iHigh(Symbol(), BarsTF, 1);
			for(i = 2; i <= BarsUse; i++)
			{
			   curr_extremum = iHigh(Symbol(), BarsTF, i);
			   if (new_extremum < curr_extremum) new_extremum = curr_extremum;
			}

			int spread        = MarketInfo(Symbol(), MODE_SPREAD);
			newStopLossPrice  = NormalizeDouble(new_extremum + (BarsOtstup + spread) * Point, Digits);

			if (UseTralOnlyInProfit && newStopLossPrice > PriceBESell) continue;	// Тралить только в профите, если UseTralOnlyInProfit == true;
			
			if (  (newStopLossPrice < OrderStopLoss() || OrderStopLoss() == 0) &&
			      (newStopLossPrice > Ask + MarketInfo(Symbol(), MODE_STOPLEVEL) * Point) )
			{
				if (!OrderModify(OrderTicket(), OrderOpenPrice(), newStopLossPrice, OrderTakeProfit(), OrderExpiration()))
				{
					EAComment("Error TrailingByShadows! Error " + GetLastError());
				}
				else EAComment("Order was modified. High/Low trailing stop");
			}
			continue;
		}
	}
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
void TrailingByFractals()
{
   if(!TralFraktalOn)
      return;
  
	if (FraktalBars <= 3 || FraktalOtstup < 0)
	{
		EAComment("Trailing TrailingByFractals() Error.");
		return;
	}

	int      z,i;
	int      extr_n;

	double   PriceBEBuy  =  PriceBE(OP_BUY),
	         PriceBESell =  PriceBE(OP_SELL),
	         temp        =  -1;

	int      after_x, be4_x;
	int      ok_be4, ok_after;
	int      sell_peak_n, buy_peak_n;

	for (int j = OrdersTotal() - 1; j >= 0; j--)
	{
		if (!OrderSelect(j, SELECT_BY_POS, MODE_TRADES)) continue;
		if (OrderMagicNumber() != Magic || OrderSymbol() != Symbol()) continue;

		temp = FraktalBars;

		if (MathMod(FraktalBars,2)==0)
		extr_n = temp/2;
		else
		extr_n = MathRound(temp/2);
		after_x = FraktalBars - extr_n;
		if (MathMod(FraktalBars,2)!=0)
		be4_x = FraktalBars - extr_n;
		else
		be4_x = FraktalBars - extr_n - 1;

		double newStopLossPrice = -1;

		if (OrderType() == OP_BUY)
		{
			for (i=extr_n;i<iBars(Symbol(),FraktalTF);i++)
			{
				ok_be4 = 0; ok_after = 0;

				for (z=1;z<=be4_x;z++)
				{
					if (iLow(Symbol(),FraktalTF,i)>=iLow(Symbol(),FraktalTF,i-z))
					{
						ok_be4 = 1;
						break;
					}
				}

				for (z=1;z<=after_x;z++)
				{
					if (iLow(Symbol(),FraktalTF,i)>iLow(Symbol(),FraktalTF,i+z))
					{
						ok_after = 1;
						break;
					}
				}

				if ((ok_be4==0) && (ok_after==0))
				{
					sell_peak_n = i;
					break;
				}
			}

			newStopLossPrice = NormalizeDouble(iLow(Symbol(), FraktalTF, sell_peak_n) - FraktalOtstup * Point, Digits);
			
			if (UseTralOnlyInProfit && newStopLossPrice < PriceBEBuy) continue; // Тралить только в профите, если UseTralOnlyInProfit == true;

			if (  (newStopLossPrice > OrderStopLoss() || OrderStopLoss() == 0) &&
			      (newStopLossPrice < Bid - MarketInfo(Symbol(), MODE_STOPLEVEL) * Point) )
			{
				if (!OrderModify(OrderTicket(), OrderOpenPrice(), newStopLossPrice, OrderTakeProfit(), OrderExpiration()))
				{
				   EAComment("Error TrailingByFractals! Error " + GetLastError());
				}
				else EAComment("Order was modified. Fractal trailing stop");
			}
			continue;
		}
		if (OrderType() == OP_SELL)
		{
			for (i=extr_n;i<iBars(Symbol(),FraktalTF);i++)
			{
				ok_be4 = 0; ok_after = 0;

				for (z=1;z<=be4_x;z++)
				{
					if (iHigh(Symbol(),FraktalTF,i)<=iHigh(Symbol(),FraktalTF,i-z))
					{
						ok_be4 = 1;
						break;
					}
				}

				for (z=1;z<=after_x;z++)
				{
					if (iHigh(Symbol(),FraktalTF,i)<iHigh(Symbol(),FraktalTF,i+z))
					{
						ok_after = 1;
						break;
					}
				}

				if ((ok_be4==0) && (ok_after==0))
				{
					buy_peak_n = i;
					break;
				}
			}

			newStopLossPrice = NormalizeDouble(iHigh(Symbol(), FraktalTF, buy_peak_n) + (FraktalOtstup + MarketInfo(Symbol(), MODE_SPREAD)) * Point, Digits);

			if (UseTralOnlyInProfit && newStopLossPrice > PriceBESell) continue; // Тралить только в профите, если UseTralOnlyInProfit == true;
				
			if (  (newStopLossPrice < OrderStopLoss() || OrderStopLoss() == 0) &&
               (newStopLossPrice > Ask + MarketInfo(Symbol(), MODE_STOPLEVEL) * Point) )
			{
				if (!OrderModify(OrderTicket(), OrderOpenPrice(), newStopLossPrice, OrderTakeProfit(), OrderExpiration()))
				{
				   EAComment("Error TrailingByFractals! Error " + GetLastError());
				}
				else EAComment("Order was modified. Fractal trailing stop");
			}
			continue;
		}
	}
}
//+------------------------------------------------------------------+