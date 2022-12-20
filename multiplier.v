/*
* Przyk�adowy modu� uk�adu mno��cego i testbencha do testowania tego modu�u.
* Jest tu ca�kiem sporo r�nych sygna��w, bo chwil� mi zaje�o doprowadzenie
* tego do dzia�ania, ale pomy�la�em, �e nie b�d� tego usuwa�. Mo�e komu� to
* pomo�e w jaki� spos�b.
*/
module multiplier (
	A,				//	- Mno�na - co b�dziemy mno�y�	   
	B,				//  - Mno�nik - przez co b�dziemy mno�y�	   
	clk,			//	
	reset,			//
	Y,				//	- Iloczyn
	rdy,			//	- flaga gotowo�ci wyniku do odebrania
	
	stan,			//----
	in_clk,			//	 -
	in_counter,		//	 -		 
	in_result,		//	 ----Wyj�cia rejestr�w do debugowania
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
	output [1:0] stan; 		  //   -   Wa�ne, �eby pami�ta�, �e wire od rejestru,	
	output in_clk;			  //   ----kt�rego chcemy sprawdzi� mia� tak� sam� liczb�
	output [3:0] in_counter;  //   -   bit�w jak rejestr ;)
	output [7:0] in_result;	  //   -
	output [3:0] in_delay; 	  //   -
	output [3:0] in_A;		  //   -
	output [3:0] in_B;		  //   -
	output debug;			  //----
	
	/*
	*	1. Uk�ad dzia�a na zasadzie dodawania. 
	* 	Np.: 2*4 = 2+2+2+2 = 8
	*	2. Automat sekwencyjny powinien by� zrobiony nieco inaczej:
	* 	W jednym stanie powinny znale�� si� przypisania kolejnego stanu do
	*	zmiennej stanu, a w osobnym bloku always powinno znale�� si� 
	*	przypisanie nast�pnego stanu do obecnego. W tym uk�adzie nie ma
	*	to znaczenia, ale je�li by�aby potrzebna synchronizacja innych
	*	urz�dze� zboczem opadaj�cym, to by�by tu problem.
	*/
	
	reg [7:0] result;	// Rejestr przechowuj�cy wynik dodawania
	reg [1:0] state;	// 00 - pobierz dane; 01 - liczy; 10 - koniec 
	reg [3:0] counter;	// Licznik licz�cy ilo�� dodawa� - zliczaj�cy od 0 do mno�nej - rejestru B
	reg [3:0] delay;	// Licznik op�niaj�cy, �eby zapewni� wygenerowanie si� poprawnego wyniku wyniku
	reg [3:0] int_A;	// Mno�na zatrza�ni�ta, �eby unikn�� b��d�w przy zmianie danych na wej�ciu
	reg [3:0] int_B;	// Mno�nik; patrz wy�ej
	
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
	assign Y = (rdy) ? result : 1'd0;   	   //	----Wyprowadzenia rejestr�w do testbencha
	assign in_delay = delay;				   //	-
	assign in_A = int_A;					   //	-
	assign in_B = int_B;					   //	-
	assign debug = (counter[2]) ? 1 : 0;	   //----
	
	/*
	* 	aassign Y = (rdy) ? result : 1'd0; oznacza:
	*   je�eli rejestr rdy b�dzie mia� warto�� 1, to przypisz
	*	sygna�owi Y warto�� rejestru result, a je�li rdy = 0,
	*	to przypisz Y = 0.
	*/
	
endmodule	



module testbench;
						   // Dwie linijki SystemVeriloga. Prawdopodobnie mo�na je zast�pi� `timescale 1ns / 100ps nad nazw� modu�u,
						   // ale nie jestem pewien jakby to dzia�a�o w przypadku kilku modu��w w jednym pliku.
	timeunit 1ns;		   // Ustawia podstawow� jednostk� czasu wykorzystywan� w poleceniu wait(CZAS), #[CZAS] czy parametrze do generacji zegara
	timeprecision 100ps;   // Dok�adno�� symulacji.Symulacja dzia�a na zasadzie "tick�w". Jeden tick to w tym przypadku 100ps
						   // Je�eli przewidujemy, �e co� ma si� zmienia� szybciej - trzeba ustawi� precyzj� na mniejszy okres czasu.
	reg [3:0] Input_A;	   //----
	reg [3:0] Input_B;	   //	-
	reg clk;			   //	----Wej�cia i wyj�cia testowanego modu�u
	reg reset;			   //	-
	reg [7:0] Output;	   //	-
	reg Ready;			   //----
	
	reg [1:0] state;	   //----
	reg clk_tb;			   //	-
	reg [3:0] counter_tb;  //	-
	reg [7:0] result_tb;   //	----Rejestry, w kt�rych zapisywane b�d� dane z rejestr�w, kt�re chcemy debugowa�.
	reg [3:0] delay_tb;	   //	-	Do czego� trzeba je podpi��, �eby sprawdzi� co w nich jest.
	reg [3:0] A_tb;		   //	-
	reg [3:0] B_tb;		   //	-
	reg debug_tb;		   //----
	
					
	parameter period = 10; // Po�owa okresu generowanego sygna�u zegarowego wyra�ona jako liczba rzeczywista dodatnia.
						   // Ujemna nie mia�aby sensu w zegarze, wi�c symulacja si� zepsuje
	
	multiplier DUT(.A(Input_A), .B(Input_B), .clk(clk), .reset(reset), .Y(Output), .rdy(Ready), .stan(state),
	.in_clk(clk_tb), .in_counter(counter_tb), .in_result(result_tb), .in_delay(delay_tb), .in_A(A_tb),
	.in_B(B_tb), .debug(debug_tb));
	
	/*
	* 	Pod��czanie testowanego modu�u, portmapa, zwa� jak zwa�. Mo�na przypisywa� sygna�y
	*	przez miejsce, a mo�na przez nazw�. Przez nazw� wydaje si�by�na d�u�sz� met� bardziej czytelnie
	*	Mapowanie przez miejsce polega na tym, �e podaje si� tylko nazwy sygna��w, do kt�rych chcemy
	*	przypisa� wyj�cia z testowanego modu�u. W tym przypadku by�oby to tak:
	*
	*	multiplier DUT(Input_A, Input_B, clk, reset, Output, Ready, state,
	*	clk_tb, counter_tb, result_tb, delay_tb, A_tb,
	*	B_tb, debug_tb); 
	*
	*   Czyli: 	[nazwa-modu�u] [nazwa_instancji] ([port1], [port2], ...);
	*
	*	Nad komentarzem jest przyk�ad mapowania przez nazw�, czyli:
	*	[nazwa_modu�u] [nazwa_instancji] (.[nazwa_portu_w_testowanym_module_1]([port1]), .[nazwa_portu_w_testowanym_module_2]([port2]), ...);
	*/
	
	always #period clk = ~clk;	 // Generowanie zegara. Za ka�dym razem, gdy minie czas okre�lony w parametrze period zaneguje si� zegar
		
	initial 
	begin 							 //----
		clk = 0;	   				 //	  -
		reset = 0;					 //	  -
		Input_A = 4'b0001;			 //	  -
		Input_B = 4'b0001;			 //	  -
		$display("0 do 20 ns");		 //	  -
		#20							 //	  -
		reset = 1;					 //	  -
		#500						 //	  ----Sekwencja podawania danych do testowania uk�adu. Zmieniamy wej�cia, podajemy jakie� dane,
		Input_A = 4'b0011;			 //	  -   a wyj�cia zapisywane s� w wewn�trznych rejestrach testbencha. 
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
	*	Og�lnie blok initial wykonuje si� tylko raz, zaczyna w chwili 0 i PODOBNO nie jest syntezowalny.
	*	Na pocz�tku trzeba wyzerowa� zegar. W ko�cu trzeba mie� co zanegowa�...
	*   Warto te� pomy�le� o sygnale reset. O ile symulacja pewnie bez niego sobie poradzi
	*	(je�li w og�le go nie napiszemy), to zaprogramowane (skonfigurowane ;) ) FPGA ju� 
	*	niekoniecznie. Reset pozwala zacz��od dok�adnie takich stan�w rejestr�w jakie by�my 
	*	chcieli i eliminuje ryzyko, �e co� przypadkowo ustawi si� w warto��, kt�rej nie przewidzieli�my w kodzie.
	*	$display("tekst" [liczba]) 	-	wy�wietla tekst w konsoli. Mo�e by� przydatne je�eli gdzie� 
	*	by by� jaki� blok if else... Chyba...
	*	#[liczba]	-	przeskakuje o okre�lony czas w symulacji (te� w podstawowych jednostkach czasu)
	*	$finish		-	ko�czy symulacje
	*	EXTRAS
	*	$stop		- 	przerywa symulacj� i mo�na j� wznowi�, ale nie znalaz�em jak
	*	Jak nie ma si� GUI (czyli np. w Modelsim chyba) to komenta exit te� ko�czy symulacj�
	*/
	
endmodule
	