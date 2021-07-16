--vhdl代码由3个部分组成
--参数部分库library
--接口部分entity
--描述部分architecture

LIBRARY ieee; --库名
USE ieee.std_logic_1164.ALL; --定义标准逻辑数据类型及其逻辑运算函数

ENTITY Duangg IS --Duangg是实体名，需要和文件名称一致。
    PORT (

        SWB : IN STD_LOGIC;
        SWA : IN STD_LOGIC;
        SWC : IN STD_LOGIC; --操作台控制命令SWC SWB SWA
        clr : IN STD_LOGIC; --清零信号，低电平有效
        C : IN STD_LOGIC;
        Z : IN STD_LOGIC; --C和Z分别是有进位信号和结果为0的标志信号
        IRH : IN STD_LOGIC_VECTOR(3 DOWNTO 0); --TEC-8指令的高四位信号，是操作控制信号
        T3 : IN STD_LOGIC; --时钟沿
        W1 : IN STD_LOGIC;
        W2 : IN STD_LOGIC; 
        W3 : IN STD_LOGIC; --W1，W2，W3位节拍信号
        --W1,W2为节拍信号，一个节拍内可进行多个控制信号的有效置位，C和Z分别是有进位信号和结果为0的标志信号，CLR为清0信号，且为低电平有效，当CLR为0 的时候，除SW和IR外所有信号都置为0

        SELCTL : OUT STD_LOGIC;
        ABUS : OUT STD_LOGIC;
        M : OUT STD_LOGIC;
        S : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        SEL0 : OUT STD_LOGIC;
        SEL1 : OUT STD_LOGIC;
        SEL2 : OUT STD_LOGIC;
        SEL3 : OUT STD_LOGIC;
        DRW : OUT STD_LOGIC;
        SBUS : OUT STD_LOGIC;
        LIR : OUT STD_LOGIC;
        MBUS : OUT STD_LOGIC;
        MEMW : OUT STD_LOGIC;
        LAR : OUT STD_LOGIC;
        ARINC : OUT STD_LOGIC;
        LPC : OUT STD_LOGIC;
        PCINC : OUT STD_LOGIC;
        PCADD : OUT STD_LOGIC; --PC端指针的偏移量，可以实现PC指针的移动
        CIN : OUT STD_LOGIC;
        LONG : OUT STD_LOGIC;
        SHORT : OUT STD_LOGIC;

        QD : IN STD_LOGIC;
        STOP : OUT STD_LOGIC;
        LDC : OUT STD_LOGIC;
        LDZ : OUT STD_LOGIC --以上全是cpu内组成部分，如pc寄存器、IR寄存器、AR数据寄存器等的内部控制信号
    );
END Duangg;

ARCHITECTURE art OF Duangg IS

    SIGNAL ST0_reg : STD_LOGIC; --赋值给ST0
    --写寄存器   STO为0的时候写R0、R1,ST0为1的时候，写R2、R3，
    --写储存器   STO为0的时候将数据开关处的数据打入AR寄存器,ST0为1的时候进行存储器的读或写操作和ARINC，
    SIGNAL SST0 : STD_LOGIC; --SSTO在T3下降沿的时候将STO设置为1，进行写R0、R1到写R2、R3的转化

    SIGNAL SWCBA : STD_LOGIC_VECTOR(2 DOWNTO 0); --操作台控制命令SWC SWB SWA,更加方便表示
    SIGNAL ST0 : STD_LOGIC; --用户不可见的信号，控制寄存器的写操作或者存储器的读写操作

    SIGNAL STOP_reg_reg : STD_LOGIC;
    SIGNAL STOP_reg : STD_LOGIC; --判断CPU运行结束条件
BEGIN

    STOP <= (STOP_reg_reg OR STOP_reg) WHEN (SWCBA /= "000") ELSE
        '0';
    SWCBA（2 DOWNTO 0） <= (SWC & SWB & SWA);
    ST0 <= ST0_reg; --STOP,SWCBA,ST0三者赋值

    PROCESS (clr, T3)
    BEGIN
        IF (clr = '0') THEN
            ST0_reg <= '0';
            STOP_reg_reg <= '1';
        ELSIF (T3'EVENT AND T3 = '0') THEN
            IF (SST0 = '1') THEN
                ST0_reg <= '1';
            END IF;
        END IF;
    END PROCESS; --此过程进行清零操作，并且判断ST0是否要转换成1
    PROCESS (SWCBA, IRH, W1, W2, W3, ST0, C, Z)
    BEGIN
        SHORT <= '0'; --当SHORT为1时，W1后不产生W2
        LONG <= '0'; --当LONG为1时，w2后有W3
        CIN <= '0'; --低位的进位输入信号
        SELCTL <= '0'; --SELCTL为1时，实验系统处于程序控制台状态，SELCTL为0时，实验系统处于程序执行状态
        ABUS <= '0'; --当ABUS为1时，将运算结果送到数据总线，当ABUS为0时，禁止运算结果送到数据总线
        SBUS <= '0';
        MBUS <= '0'; --当SBUS为1时，将总线数据写到双端口储存器中，当SBUS为0时，禁止总线数据写到双端口储存器中
        M <= '0'; --M与S3、S2、S1、S0共同控制算术逻辑运算类型
        S <= "0000"; --即S3、S2、S1、S0
        SEL3 <= '0';
        SEL2 <= '0';
        SEL1 <= '0';
        SEL0 <= '0'; --SEL为寄存器的选择信号
        DRW <= '0'; --为1时对选中的寄存器进行写操作
        SBUS <= '0'; --当SBUS为1时，将开关数据送到数据总线，当ABUS为0时，禁止开关数据送到数据总线
        LIR <= '0';
        MEMW <= '0'; --当MEMW为1时，将数据总线上的数据写入双端口存储器，写入的地址由AR指定
        LAR <= '0'; --当LAR为1时，数据总线上的数据被写入AR寄存器
        ARINC <= '0'; --ARINC为1时，AR寄存器的内容自动加1
        LPC <= '0'; --当LPC为1时，数据总线上的数据被写入pc寄存器
        LDZ <= '0'; --LDZ为1时，当运算结果为0时将1写入Z标志寄存器
        LDC <= '0'; --LDC为1时，当运算结果有进位时将1写入Z标志寄存器
        STOP_reg <= '1'; --当STOP为1时，在T3结束后时序发生器停止输出节拍脉冲
        PCINC <= '0'; --PCINC为1时，PC寄存器的内容自动加1
        SST0 <= '0';
        PCADD <= '0'; --所有变量初始化，给它们赋初值

        CASE SWCBA IS
            WHEN "000" => --SWC SWB SWA 为000时，CPU程序开始运行
                IF (ST0 = '0') THEN
                    LPC <= W1;
                    SBUS <= W1;
                    SST0 <= W1;
                    SHORT <= W1;
                ELSIF (ST0 = '1') THEN --ST0等于1的时候执行操作
                    CASE IRH IS
                        WHEN "0000" =>
                            LIR <= W1;
                            PCINC <= W1;
                            SHORT <= W1;
                        WHEN "0001" => --ADD操作
                            LIR <= W1; --允许指令寄存器的写
                            PCINC <= W1; --PC加1
                            SHORT <= W1; --W1后无W2
                            S <= "1001"; --根据ALU的算术逻辑运算表设置，M=0时加法操作的S=1001
                            CIN <= W1; --低位的进位输入信号有效
                            ABUS <= W1; --允许运算结果输出
                            DRW <= W1; --允许寄存器写操作
                            LDC <= W1; --运算结果有进位的标志寄存器内容写为1
                            LDZ <= W1; --运算结果为0的标志寄存器内容写为1
                        WHEN "0010" => --SUB操作
                            LIR <= W1; --允许指令寄存器的写
                            PCINC <= W1; --PC加1
                            SHORT <= W1; --W1后无W2
                            S <= "0110";
                            ABUS <= W1; --允许运算结果输出
                            DRW <= W1; --允许寄存器写操作
                            LDZ <= W1; --运算结果为0的标志寄存器内容写为1
                            LDC <= W1; --运算结果有进位的标志寄存器内容写为1
                        WHEN "0011" => --AND操作
                            LIR <= W1; --允许指令寄存器的写
                            PCINC <= W1; --PC加1
                            SHORT <= W1; --W1后无W2
                            S <= "1011";
                            M <= W1; --进行逻辑运算
                            ABUS <= W1; --允许运算结果输出
                            DRW <= W1; --允许寄存器写操作
                            LDZ <= W1; --运算结果为0的标志寄存器内容写为1
                        WHEN "0100" => --INC操作
                            LIR <= W1; --允许指令寄存器的写
                            PCINC <= W1; --PC加1
                            SHORT <= W1; --W1后无W2
                            S <= "0000";
                            ABUS <= W1; --允许运算结果输出
                            DRW <= W1; --允许寄存器写操作
                            LDZ <= W1; --运算结果为0的标志寄存器内容写为1
                            LDC <= W1; --运算结果有进位的标志寄存器内容写为1
                        WHEN "0101" => --LD操作
                            LIR <= W2; --允许指令寄存器的写
                            PCINC <= W2; --PC加1
                            S <= "1010";
                            M <= W1; --进行逻辑运算
                            ABUS <= W1; --允许运算结果输出
                            LAR <= W1; --允许AR寄存器的写
                            MBUS <= W2; --允许存储器的读操作
                            DRW <= W2; --允许寄存器写操作
                        WHEN "0110" => --ST操作
                            LIR <= W2; --允许指令寄存器的写
                            PCINC <= W2; --PC加1
                            M <= W1 OR W2; --逻辑运算模式
                            S(3) <= '1';
                            S(2) <= W1;
                            S(1) <= '1';
                            S(0) <= W1;
                            ABUS <= W1 OR W2; --允许运算结果输出
                            LAR <= W1; --允许AR寄存器的写
                            MEMW <= W2; --允许双端口存储器的写
                        WHEN "0111" => --JC操作
                            LIR <= (W1 AND NOT(C)) OR (W2 AND C);
                            PCINC <= (W1 AND NOT(C)) OR (W2 AND C);
                            PCADD <= C AND W1;
                            SHORT <= W1 AND NOT(C);
                        WHEN "1000" => --JZ操作
                            LIR <= (W1 AND NOT(Z)) OR (W2 AND Z);
                            PCINC <= (W1 AND NOT(Z)) OR (W2 AND Z);
                            PCADD <= Z AND W1;
                            SHORT <= W1 AND NOT(Z);
                        WHEN "1001" => --JMP操作
                            LIR <= W2;
                            PCINC <= W2; --在新的PC下取指
                            M <= W1; --逻辑运算
                            S <= "1111";
                            ABUS <= W1; --运算结果写入数据总线
                            LPC <= W1; --总线内容写入PC寄存器，形成新的PC
                        WHEN "1010" => --OUT操作
                            M <= W1; --逻辑运算
                            S <= "1010";
                            ABUS <= W1; --运算结果写入数据总线
                            LIR <= W1; --取指操作
                            PCINC <= W1;
                            SHORT <= W1; --无W2
                        WHEN "1011" => --OR操作（拓展指令）
                            LIR <= W1; --取指操作
                            PCINC <= W1;
                            SHORT <= W1; --无W2
                            M <= W1; --逻辑运算
                            S <= "1110";
                            ABUS <= W1; --运算结果写入数据总线
                            DRW <= W1; --写寄存器有效
                            LDZ <= W1; --运算结果为0时0标志寄存器为1
                        WHEN "1100" => --NOT操作
                            LIR <= W1; --取指操作
                            PCINC <= W1;
                            SHORT <= W1; --无W2
                            M <= W1; --逻辑运算
                            S <= "0000";
                            ABUS <= W1; --运算结果写入数据总线
                            DRW <= W1; --写寄存器有效
                            LDZ <= W1; --运算结果为0时0标志寄存器为1
                        WHEN "1101" => --A*2 +1操作（拓展指令）
                            LIR <= W1; --取指操作
                            PCINC <= W1;
                            SHORT <= W1; --无W2
                            S <= "1100";
                            ABUS <= W1; --运算结果写入数据总线
                            DRW <= W1; --写寄存器有效
                            LDC <= W1; --运算结果有进位时进位标志寄存器为1
                            LDZ <= W1; --运算结果为0时0标志寄存器为1
                        WHEN "1111" => --XOR操作  （拓展指令）
                            LIR <= W1; --取指操作
                            PCINC <= W1;
                            SHORT <= W1; --无W2
                            M <= W1; --逻辑运算
                            S <= "0110";
                            ABUS <= W1; --运算结果写入数据总线
                            DRW <= W1; --写寄存器有效
                            LDZ <= W1; --运算结果为0时0标志寄存器为1
                        WHEN "1110" => --STP操作
                            STOP_reg <= W1;
                        WHEN OTHERS =>
                            LIR <= W1; --取指操作
                            PCINC <= W1;
                    END CASE;
                END IF;

            WHEN "001" => --SWC SWB SWA 为001时，进行存储器的写操作
                SELCTL <= W1;
                SHORT <= W1;
                SBUS <= W1;
                STOP_reg <= W1;
                SST0 <= W1;
                LAR <= W1 AND (NOT(ST0));
                ARINC <= W1 AND ST0;
                MEMW <= W1 AND ST0;
            WHEN "010" => --SWC SWB SWA 为010时，进行存储器的读操作
                SELCTL <= W1;
                SHORT <= W1;
                SBUS <= W1 AND (NOT(ST0));
                MBUS <= W1 AND ST0;
                STOP_reg <= W1;
                SST0 <= W1;
                LAR <= W1 AND (NOT(ST0));
                ARINC <= W1 AND ST0;
            WHEN "011" => ----SWC SWB SWA 为100时，进行寄存器的读操作
                SELCTL <= '1';
                SEL0 <= W1 OR W2;
                STOP_reg <= W1 OR W2;
                SEL3 <= W2;
                SEL1 <= W2;
            WHEN "100" => ----SWC SWB SWA 为100时，进行寄存器的写操作
                SELCTL <= '1';
                SST0 <= W2;
                SBUS <= W1 OR W2;
                STOP_reg <= W1 OR W2;
                DRW <= W1 OR W2;
                SEL3 <= (ST0 AND W1) OR (ST0 AND W2);
                SEL2 <= W2;
                SEL1 <= ((NOT(ST0)) AND W1) OR (ST0 AND W2);
                SEL0 <= W1;
            WHEN OTHERS =>
        END CASE;
    END PROCESS;
END art;