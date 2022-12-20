--
-- 	Pr�bowa�em przet�umaczy� jak najbardziej 1 do 1 modu��w z veriloga, 
--	wi�c wi�kszo�� dzia�ania tu pomin�.	
--

library ieee;										--  ----	Nie mam	poj�cia po co to, ale musi by�.
use ieee.std_logic_1164.all;  						--	   -----Pierwsza linijka to biblioteka z naszymi plikami (albo entity),
use ieee.std_logic_unsigned."+";					--  ----	druga, pozwala na u�ywanie std_logic i std_logic_vector,
													--			trzecia pozwala na dodawanie 1 do wektowa zamiast "0001"

entity multiplier is								
	port(											-- Ka�dy port jest zako�czony �rednikiem za wyj�tkiem ostatniego
	A : in std_logic_vector(3 downto 0);
	B : in std_logic_vector(3 downto 0);
	clk : in std_logic;
	reset : in std_logic; 
	Y : out std_logic_vector(7 downto 0);
	rdy : out std_logic; 
	
	--stan : out ?									 -- Wyj�cia nie mog� mie� typ�w zdefiniowanych przez u�ytkownika chyba,
													 -- �e zrobimy bloczek package gdzie definiuje si�
													 -- funkcje i typy danych dla ca�ego projektu... Ale tego tu nie ma
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

type stan is (load, work, done);					  -- Definiowanie typu danych u�ytkownika. Maszyna stan�w jest bardziej czytelna.
													  -- Sk�adnia: type [nazwa] is ([zdefiniowana_warto��1], [zdefiniowana_warto��2],...);
													  -- Extra: subtype od type r�ni si� tym, �e subtype jest u�ywana do tworzenia typ�w 
													  -- na podstawie ju� istniej�cych typ�w. Np. tablica tablic std_logic_vector
				   
signal result : std_logic_vector(7 downto 0);		  -- Sygna�y raz mo�na por�wna� do verilogowego wire, a raz do reg. zale�y co to ma robi�
signal state : stan;								  
signal counter : std_logic_vector(3 downto 0);		  
signal delay : std_logic_vector(3 downto 0);		  
signal int_A : std_logic_vector(3 downto 0);		  
signal int_B : std_logic_vector(3 downto 0);		  

signal int_rdy : std_logic;							  --W vhdl nie mo�na odczytywa� warto�ci wyj�cia je�li nie jest ono inout'em,
													  --wi�c trzeba zrobi� co� na kszta�t wire.
begin
	
	main : process(clk, reset)
	begin
		if(reset = '0') then
			state <= load;
			result <= (others => '0');				  -- (others => '0') to to samo co "00000000" (ile� zer zer). Mo�na tego u�y� do 2 i wi�cej bit�w.
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
	
	rdy <= int_rdy;															 -- To nie op�nia przypisania o �aden takt zegara, ani o nic
	Y <= result when int_rdy = '1' else (others => '0') when int_rdy = '0';	 -- Y = result je�li flaga rdy b�dzie r�wna 1, je�li nie to zera.
		
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

entity testbench is									 -- Puste entity, tak jak pusty modu�w verilogu - bez port�w
end entity;

architecture testB of testbench is

signal Input_A : std_logic_vector(3 downto 0);
signal Input_B : std_logic_vector(3 downto 0);
signal clk : std_logic := '0';						 -- := '0' to przypisanie 0 na samym pocz�tku symulacji. Takie co� jest niesyntezowalne. Lepiej zrobi� reset.
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

signal period : time := 20 ns;						  -- W vhdl nie ma 'timescale, timeunit itd, wi�c trzeba dopisa� jednostk� czasu
													  
signal clk_enable : std_logic := '1';				  -- Zmieniaj�c to sko�czymy symulacj�.

--	W nowszych wersjach vhdl instnieje polecenie exit do ko�czenia symulacji, ale ono nie zawsze dzia�a.
--	Warto wi�c skorzysta� z tego, �e symulacja b�dzie trwa�a do moemntu w kt�rym w projekcie przestan� si� zmienia�
--	sygna�y. Jako, �e nasz zegar teoretycznie b�dzie si� generowa� w niesko�czono��, trzeba go jako� zatrzyma�. 
--	Do tego pos�u�y clk_enable - gdy jest r�wne 1 to zegar b�dzie generowany, a gdy zmienimy na 0, to przestanie si� 
--	generowa�, a jednocze�nie zako�czy symulacj� (je�li dobierzemy ten czas jako ostatni� planowan� zmian� w symulacji.

component multiplier is								   -- W vhdl opr�cz mapowania port�w trzeba doda� komponent. 
	port(											   -- Tak naprawd� jest to kopiuj-wklej z entity danego modu�u
	A : in std_logic_vector(3 downto 0);			   -- z zamian� s��w entity na component.
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
	
	DUT : multiplier port map(							 -- Mapowanie port�w. Tak jak w verilogu mo�na to zrobi� przez miejsce 
	A => Input_A,										 --	lub przez nazw�. Tutaj mamy przez nazw�, Przy mapowaniu przez 
	B => Input_B,										 -- miejsce - tak jak w verilogu - podajemy tylko nazwy z testbencha 
	clk => clk,											 -- w kolejno�ci port�w z entity - do czego przypisujemy pierwszy
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
	
	process(clk)										  -- Generowanie zegara. Process z list� czu�o�ci, na kt�rej jest tylko clk.
	begin												  -- Jak go nie b�dzie, to b�dzie nieskonczona p�tla i symulacja si� wysypie. 
														  -- Og�lnie to dzia�anie podobne do always@, tylko, �e nie podaje si� tam zboczy.
		if(clk_enable = '1') then						  -- Obsluga zegara i jego za��czenie/wy��czenie 
			clk <= not clk after period/2;
		end if;
	end process;
	
	reset <= '0' after 0 ns, '1' after 20 ns;									   -- Podawanie sygna��w do testowania modu�u. Zawsze nale�y poda� jednostk� 
	Input_A <= "0001" after 0 ns, "0011" after 520 ns, "0111" after 1020 ns;	   -- czasu. Czasy s� takie same jak w verilogowym testbenchu.
	Input_B <= "0001" after 0 ns, "1010" after 520 ns, "1111" after 1020 ns;	   -- 
	clk_enable <= '0' after 1520 ns;											   -- Wy��czanie generowania zegara. 
	
end architecture;