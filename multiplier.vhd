--
-- 	Próbowa³em przet³umaczyæ jak najbardziej 1 do 1 modu³ów z veriloga, 
--	wiêc wiêkszoœæ dzia³ania tu pominê.	
--

library ieee;										--  ----	Nie mam	pojêcia po co to, ale musi byæ.
use ieee.std_logic_1164.all;  						--	   -----Pierwsza linijka to biblioteka z naszymi plikami (albo entity),
use ieee.std_logic_unsigned."+";					--  ----	druga, pozwala na u¿ywanie std_logic i std_logic_vector,
													--			trzecia pozwala na dodawanie 1 do wektowa zamiast "0001"

entity multiplier is								
	port(											-- Ka¿dy port jest zakoñczony œrednikiem za wyj¹tkiem ostatniego
	A : in std_logic_vector(3 downto 0);
	B : in std_logic_vector(3 downto 0);
	clk : in std_logic;
	reset : in std_logic; 
	Y : out std_logic_vector(7 downto 0);
	rdy : out std_logic; 
	
	--stan : out ?									 -- Wyjœcia nie mog¹ mieæ typów zdefiniowanych przez u¿ytkownika chyba,
													 -- ¿e zrobimy bloczek package gdzie definiuje siê
													 -- funkcje i typy danych dla ca³ego projektu... Ale tego tu nie ma
	in_clk : out std_logic;
	in_counter : out std_logic_vector(3 downto 0);
	in_result : out std_logic_vector(7 downto 0);
	in_delay : out std_logic_vector(3 downto 0);
	in_A : out std_logic_vector(3 downto 0);
	in_B : out std_logic_vector(3 downto 0);
	debug : out std_logic
	);
end entity;

architecture rtl of multiplier is

type stan is (load, work, done);					  -- Definiowanie typu danych u¿ytkownika. Maszyna stanów jest bardziej czytelna.
													  -- Sk³adnia: type [nazwa] is ([zdefiniowana_wartoœæ1], [zdefiniowana_wartoœæ2],...);
													  -- Extra: subtype od type ró¿ni siê tym, ¿e subtype jest u¿ywana do tworzenia typów 
													  -- na podstawie ju¿ istniej¹cych typów. Np. tablica tablic std_logic_vector
				   
signal result : std_logic_vector(7 downto 0);		  -- Sygna³y raz mo¿na porównaæ do verilogowego wire, a raz do reg. zale¿y co to ma robiæ
signal state : stan;								  
signal counter : std_logic_vector(3 downto 0);		  
signal delay : std_logic_vector(3 downto 0);		  
signal int_A : std_logic_vector(3 downto 0);		  
signal int_B : std_logic_vector(3 downto 0);		  

signal int_rdy : std_logic;							  --W vhdl nie mo¿na odczytywaæ wartoœci wyjœcia jeœli nie jest ono inout'em,
													  --wiêc trzeba zrobiæ coœ na kszta³t wire.
begin
	
	main : process(clk, reset)
	begin
		if(reset = '0') then
			state <= load;
			result <= (others => '0');				  -- (others => '0') to to samo co "00000000" (ileœ zer zer). Mo¿na tego u¿yæ do 2 i wiêcej bitów.
			counter <= "0000";
			delay <= "0000";
			int_A <= "0000";
			int_B <= "0000"; 
			int_rdy <= '0';
		else
			if(state = load) then
				int_A <= A;
				int_B <= B;
				delay <= "0000";
				state <= work;
				result <=  (others => '0');
			elsif(state = work) then
				if(delay < "1111") then
					delay <= delay + 1;
					if(counter < int_B) then
						result <= result + int_A;
						counter <= counter + 1;
					end if;
				else
					state <= done;
					int_rdy <= '1';
				end if;
			else
				int_rdy <= '0';
				state <= load;
				counter <= "0000";
				result <= (others => '0');
			end if;
		end if;
	end process;
	
	rdy <= int_rdy;															 -- To nie opóŸnia przypisania o ¿aden takt zegara, ani o nic
	Y <= result when int_rdy = '1' else (others => '0') when int_rdy = '0';	 -- Y = result jeœli flaga rdy bêdzie równa 1, jeœli nie to zera.
		
	in_clk <= clk;
	in_counter <= counter;
	in_result <= result;
	in_delay <= delay;
	in_A <= int_A;
	in_B <= int_B;
	debug <= '1' when counter(2) = '1' else '0' when counter(0) = '0';
	
end architecture;

library ieee;
use ieee.std_logic_1164.all;

entity testbench is									 -- Puste entity, tak jak pusty modu³w verilogu - bez portów
end entity;

architecture testB of testbench is

signal Input_A : std_logic_vector(3 downto 0);
signal Input_B : std_logic_vector(3 downto 0);
signal clk : std_logic := '0';						 -- := '0' to przypisanie 0 na samym pocz¹tku symulacji. Takie coœ jest niesyntezowalne. Lepiej zrobiæ reset.
signal reset : std_logic;
signal Output : std_logic_vector(7 downto 0);
signal Ready : std_logic; 

signal clk_tb : std_logic;
signal counter_tb : std_logic_vector(3 downto 0);
signal result_tb : std_logic_vector(7 downto 0);
signal delay_tb : std_logic_vector(3 downto 0);
signal A_tb : std_logic_vector(3 downto 0);
signal B_tb : std_logic_vector(3 downto 0);
signal debug_tb : std_logic;

signal period : time := 20 ns;						  -- W vhdl nie ma 'timescale, timeunit itd, wiêc trzeba dopisaæ jednostkê czasu
													  
signal clk_enable : std_logic := '1';				  -- Zmieniaj¹c to skoñczymy symulacjê.

--	W nowszych wersjach vhdl instnieje polecenie exit do koñczenia symulacji, ale ono nie zawsze dzia³a.
--	Warto wiêc skorzystaæ z tego, ¿e symulacja bêdzie trwa³a do moemntu w którym w projekcie przestan¹ siê zmieniaæ
--	sygna³y. Jako, ¿e nasz zegar teoretycznie bêdzie siê generowa³ w nieskoñczonoœæ, trzeba go jakoœ zatrzymaæ. 
--	Do tego pos³u¿y clk_enable - gdy jest równe 1 to zegar bêdzie generowany, a gdy zmienimy na 0, to przestanie siê 
--	generowaæ, a jednoczeœnie zakoñczy symulacjê (jeœli dobierzemy ten czas jako ostatni¹ planowan¹ zmianê w symulacji.

component multiplier is								   -- W vhdl oprócz mapowania portów trzeba dodaæ komponent. 
	port(											   -- Tak naprawdê jest to kopiuj-wklej z entity danego modu³u
	A : in std_logic_vector(3 downto 0);			   -- z zamian¹ s³ów entity na component.
	B : in std_logic_vector(3 downto 0);
	clk : in std_logic;
	reset : in std_logic; 
	Y : out std_logic_vector(7 downto 0);
	rdy : out std_logic;
	
	--stan : out ?
	in_clk : out std_logic;
	in_counter : out std_logic_vector(3 downto 0);
	in_result : out std_logic_vector(7 downto 0);
	in_delay : out std_logic_vector(3 downto 0);
	in_A : out std_logic_vector(3 downto 0);
	in_B : out std_logic_vector(3 downto 0);
	debug : out std_logic
	);
end component;

begin	
	
	DUT : multiplier port map(							 -- Mapowanie portów. Tak jak w verilogu mo¿na to zrobiæ przez miejsce 
	A => Input_A,										 --	lub przez nazwê. Tutaj mamy przez nazwê, Przy mapowaniu przez 
	B => Input_B,										 -- miejsce - tak jak w verilogu - podajemy tylko nazwy z testbencha 
	clk => clk,											 -- w kolejnoœci portów z entity - do czego przypisujemy pierwszy
	reset => reset,										 -- port, do czego drugi itd. 
	Y => Output,
	rdy => Ready,
	
	in_clk => clk_tb,
	in_counter => counter_tb,
	in_result => result_tb,
	in_delay => delay_tb,
	in_A => A_tb,
	in_B => B_tb,
	debug => debug_tb);
	
	process(clk)										  -- Generowanie zegara. Process z list¹ czu³oœci, na której jest tylko clk.
	begin												  -- Jak go nie bêdzie, to bêdzie nieskonczona pêtla i symulacja siê wysypie. 
														  -- Ogólnie to dzia³anie podobne do always@, tylko, ¿e nie podaje siê tam zboczy.
		if(clk_enable = '1') then						  -- Obsluga zegara i jego za³¹czenie/wy³¹czenie 
			clk <= not clk after period/2;
		end if;
	end process;
	
	reset <= '0' after 0 ns, '1' after 20 ns;									   -- Podawanie sygna³ów do testowania modu³u. Zawsze nale¿y podaæ jednostkê 
	Input_A <= "0001" after 0 ns, "0011" after 520 ns, "0111" after 1020 ns;	   -- czasu. Czasy s¹ takie same jak w verilogowym testbenchu.
	Input_B <= "0001" after 0 ns, "1010" after 520 ns, "1111" after 1020 ns;	   -- 
	clk_enable <= '0' after 1520 ns;											   -- Wy³¹czanie generowania zegara. 
	
end architecture;