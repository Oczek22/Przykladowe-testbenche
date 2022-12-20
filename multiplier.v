/*
* Przyk³adowy modu³ uk³adu mno¿¹cego i testbencha do testowania tego modu³u.
* Jest tu ca³kiem sporo ró¿nych sygna³ów, bo chwilê mi zaje³o doprowadzenie
* tego do dzia³ania, ale pomyœla³em, ¿e nie bêdê tego usuwa³. Mo¿e komuœ to
* pomo¿e w jakiœ sposób.
*/
module multiplier (
	A,				//	- Mno¿na - co bêdziemy mno¿yæ	   
	B,				//  - Mno¿nik - przez co bêdziemy mno¿yæ	   
	clk,			//	
	reset,			//
	Y,				//	- Iloczyn
	rdy,			//	- flaga gotowoœci wyniku do odebrania
	
	stan,			//----
	in_clk,			//	 -
	in_counter,		//	 -		 
	in_result,		//	 ----Wyjœcia rejestrów do debugowania
	in_delay,		//	 -
	in_A,			//	 -
	in_B,			//	 -
	debug			//----
	);
	
	input reg [3:0] A;		  //----
	input reg [3:0] B;		  //   -
	input clk;				  //   -
	input reset;		  	  //   -
	output [7:0] Y;			  //   -
	output reg rdy;			  //   -
							  //   -	
	output [1:0] stan; 		  //   -   Wa¿ne, ¿eby pamiêtaæ, ¿e wire od rejestru,	
	output in_clk;			  //   ----którego chcemy sprawdziæ mia³ tak¹ sam¹ liczbê
	output [3:0] in_counter;  //   -   bitów jak rejestr ;)
	output [7:0] in_result;	  //   -
	output [3:0] in_delay; 	  //   -
	output [3:0] in_A;		  //   -
	output [3:0] in_B;		  //   -
	output debug;			  //----
	
	/*
	*	1. Uk³ad dzia³a na zasadzie dodawania. 
	* 	Np.: 2*4 = 2+2+2+2 = 8
	*	2. Automat sekwencyjny powinien byæ zrobiony nieco inaczej:
	* 	W jednym stanie powinny znaleŸæ siê przypisania kolejnego stanu do
	*	zmiennej stanu, a w osobnym bloku always powinno znaleŸæ siê 
	*	przypisanie nastêpnego stanu do obecnego. W tym uk³adzie nie ma
	*	to znaczenia, ale jeœli by³aby potrzebna synchronizacja innych
	*	urz¹dzeñ zboczem opadaj¹cym, to by³by tu problem.
	*/
	
	reg [7:0] result;	// Rejestr przechowuj¹cy wynik dodawania
	reg [1:0] state;	// 00 - pobierz dane; 01 - liczy; 10 - koniec 
	reg [3:0] counter;	// Licznik licz¹cy iloœæ dodawañ - zliczaj¹cy od 0 do mno¿nej - rejestru B
	reg [3:0] delay;	// Licznik opóŸniaj¹cy, ¿eby zapewniæ wygenerowanie siê poprawnego wyniku wyniku
	reg [3:0] int_A;	// Mno¿na zatrzaœniêta, ¿eby unikn¹æ b³êdów przy zmianie danych na wejœciu
	reg [3:0] int_B;	// Mno¿nik; patrz wy¿ej
	
	always @(posedge clk)
	begin
		if(reset == 0)
		begin
			state = 2'b00;
			result = 8'b00000000;	
			counter = 4'b0000; 
			delay = 4'b0000;
			rdy = 1'b0;
		end
		else
		begin
			if(state == 2'b00)
			begin
				int_A = A;
				int_B = B;
				delay = 4'b0000;
				state = 2'b01;
				result = 8'b00000000;
			end	
			else if(state == 2'b01)
			begin
				if(delay < 4'b1111)
				begin
					delay = delay + 1;
					if(counter < int_B)
					begin
						result = result + int_A;
						counter = counter + 1;
					end
				end
				else 
				begin
					state = 2'b10;	
					rdy = 1;
				end
			end
			else
			begin							   
				rdy = 0;  					   
				state = 2'b00;
				counter = 4'b0000;
				result = 8'b00000000;
			end
		end
	end   
								  
	assign stan = state;					   //----
	assign in_clk = clk; 					   //	-
	assign in_counter = counter;			   //	-
	assign in_result = result;				   //	-
	assign Y = (rdy) ? result : 1'd0;   	   //	----Wyprowadzenia rejestrów do testbencha
	assign in_delay = delay;				   //	-
	assign in_A = int_A;					   //	-
	assign in_B = int_B;					   //	-
	assign debug = (counter[2]) ? 1 : 0;	   //----
	
	/*
	* 	aassign Y = (rdy) ? result : 1'd0; oznacza:
	*   je¿eli rejestr rdy bêdzie mia³ wartoœæ 1, to przypisz
	*	sygna³owi Y wartoœæ rejestru result, a jeœli rdy = 0,
	*	to przypisz Y = 0.
	*/
	
endmodule	



module testbench;
						   // Dwie linijki SystemVeriloga. Prawdopodobnie mo¿na je zast¹piæ `timescale 1ns / 100ps nad nazw¹ modu³u,
						   // ale nie jestem pewien jakby to dzia³a³o w przypadku kilku modu³ów w jednym pliku.
	timeunit 1ns;		   // Ustawia podstawow¹ jednostkê czasu wykorzystywan¹ w poleceniu wait(CZAS), #[CZAS] czy parametrze do generacji zegara
	timeprecision 100ps;   // Dok³adnoœæ symulacji.Symulacja dzia³a na zasadzie "ticków". Jeden tick to w tym przypadku 100ps
						   // Je¿eli przewidujemy, ¿e coœ ma siê zmieniaæ szybciej - trzeba ustawiæ precyzjê na mniejszy okres czasu.
	reg [3:0] Input_A;	   //----
	reg [3:0] Input_B;	   //	-
	reg clk;			   //	----Wejœcia i wyjœcia testowanego modu³u
	reg reset;			   //	-
	reg [7:0] Output;	   //	-
	reg Ready;			   //----
	
	reg [1:0] state;	   //----
	reg clk_tb;			   //	-
	reg [3:0] counter_tb;  //	-
	reg [7:0] result_tb;   //	----Rejestry, w których zapisywane bêd¹ dane z rejestrów, które chcemy debugowaæ.
	reg [3:0] delay_tb;	   //	-	Do czegoœ trzeba je podpi¹æ, ¿eby sprawdziæ co w nich jest.
	reg [3:0] A_tb;		   //	-
	reg [3:0] B_tb;		   //	-
	reg debug_tb;		   //----
	
					
	parameter period = 10; // Po³owa okresu generowanego sygna³u zegarowego wyra¿ona jako liczba rzeczywista dodatnia.
						   // Ujemna nie mia³aby sensu w zegarze, wiêc symulacja siê zepsuje
	
	multiplier DUT(.A(Input_A), .B(Input_B), .clk(clk), .reset(reset), .Y(Output), .rdy(Ready), .stan(state),
	.in_clk(clk_tb), .in_counter(counter_tb), .in_result(result_tb), .in_delay(delay_tb), .in_A(A_tb),
	.in_B(B_tb), .debug(debug_tb));
	
	/*
	* 	Pod³¹czanie testowanego modu³u, portmapa, zwa³ jak zwa³. Mo¿na przypisywaæ sygna³y
	*	przez miejsce, a mo¿na przez nazwê. Przez nazwê wydaje siêbyæna d³u¿sz¹ metê bardziej czytelnie
	*	Mapowanie przez miejsce polega na tym, ¿e podaje siê tylko nazwy sygna³ów, do których chcemy
	*	przypisaæ wyjœcia z testowanego modu³u. W tym przypadku by³oby to tak:
	*
	*	multiplier DUT(Input_A, Input_B, clk, reset, Output, Ready, state,
	*	clk_tb, counter_tb, result_tb, delay_tb, A_tb,
	*	B_tb, debug_tb); 
	*
	*   Czyli: 	[nazwa-modu³u] [nazwa_instancji] ([port1], [port2], ...);
	*
	*	Nad komentarzem jest przyk³ad mapowania przez nazwê, czyli:
	*	[nazwa_modu³u] [nazwa_instancji] (.[nazwa_portu_w_testowanym_module_1]([port1]), .[nazwa_portu_w_testowanym_module_2]([port2]), ...);
	*/
	
	always #period clk = ~clk;	 // Generowanie zegara. Za ka¿dym razem, gdy minie czas okreœlony w parametrze period zaneguje siê zegar
		
	initial 
	begin 							 //----
		clk = 0;	   				 //	  -
		reset = 0;					 //	  -
		Input_A = 4'b0001;			 //	  -
		Input_B = 4'b0001;			 //	  -
		$display("0 do 20 ns");		 //	  -
		#20							 //	  -
		reset = 1;					 //	  -
		#500						 //	  ----Sekwencja podawania danych do testowania uk³adu. Zmieniamy wejœcia, podajemy jakieœ dane,
		Input_A = 4'b0011;			 //	  -   a wyjœcia zapisywane s¹ w wewnêtrznych rejestrach testbencha. 
		Input_B = 4'b1010;		 	 //	  -
		$display("520 do 1020 ns");	 //	  -
		#500						 //	  -
		Input_A = 4'b0111;			 //	  -
		Input_B = 4'b1111;			 //	  -
		$display("1020 do 2020");	 //	  -
		#500						 //----
		$finish;
	end
	
	/* 
	*	Ogólnie blok initial wykonuje siê tylko raz, zaczyna w chwili 0 i PODOBNO nie jest syntezowalny.
	*	Na pocz¹tku trzeba wyzerowaæ zegar. W koñcu trzeba mieæ co zanegowaæ...
	*   Warto te¿ pomyœleæ o sygnale reset. O ile symulacja pewnie bez niego sobie poradzi
	*	(jeœli w ogóle go nie napiszemy), to zaprogramowane (skonfigurowane ;) ) FPGA ju¿ 
	*	niekoniecznie. Reset pozwala zacz¹æod dok³adnie takich stanów rejestrów jakie byœmy 
	*	chcieli i eliminuje ryzyko, ¿e coœ przypadkowo ustawi siê w wartoœæ, której nie przewidzieliœmy w kodzie.
	*	$display("tekst" [liczba]) 	-	wyœwietla tekst w konsoli. Mo¿e byæ przydatne je¿eli gdzieœ 
	*	by by³ jakiœ blok if else... Chyba...
	*	#[liczba]	-	przeskakuje o okreœlony czas w symulacji (te¿ w podstawowych jednostkach czasu)
	*	$finish		-	koñczy symulacje
	*	EXTRAS
	*	$stop		- 	przerywa symulacjê i mo¿na j¹ wznowiæ, ale nie znalaz³em jak
	*	Jak nie ma siê GUI (czyli np. w Modelsim chyba) to komenta exit te¿ koñczy symulacjê
	*/
	
endmodule
	