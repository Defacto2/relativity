(* Txt converted using txt2unit V 1.0 *)
(* J.J. Arenzon (c)1994               *)

UNIT helpdoc;

INTERFACE

uses crt,dos,printer;

const lines =   56;

type string12 = string[12];

var linha    : integer;

function PrinterOnLine : boolean;
procedure cursoron;
procedure cursoroff;
procedure linhas(writeline : integer);
procedure scroll;

 IMPLEMENTATION

{----------------------------------------------------------------
 ---                    Printer Online                        ---
 ---   By: Jeff Palen (SWAG package)                          ---
 ----------------------------------------------------------------}
 Function PrinterOnLine : Boolean;
 Const   PrnStatusInt  : Byte = $17;    (*  Dos interrupt *)
         StatusRequest : Byte = $02;    (*  Interrupt Function Call *)
         PrinterNum    : Word = 0;  { 0 for LPT1, 1 for LPT2, etc. }
 Var     Regs : Registers ;         { Type is defined in Dos Unit }
 Begin
 Regs.AH := StatusRequest;
 Regs.DX := PrinterNum;
 Intr(PrnStatusInt, Regs);
 PrinterOnLine := (Regs.AH and $80) = $80;
 End;

{------------------------------------------------------------------
 ---             Cursor ON/OFF (Mike Normand, SWAG)             ---
 ------------------------------------------------------------------}
Procedure CursorOff; Assembler;
Asm
    xor  ax, ax
    mov  es, ax
    mov  bh, Byte ptr es:[462h]  { get active page }
    mov  ah, 3
    int  10h           { get cursor Characteristics }
    or   ch, 00100000b
    mov  ah, 1
    int  10h           { set cursor Characteristics }
end;

Procedure CursorOn; Assembler;
Asm
    xor  ax, ax
    mov  es, ax
    mov  bh, Byte ptr es:[462h]  { get active page }
    mov  ah, 3
    int  10h           { get cursor Characteristics }
    and  ch, 00011111b
    mov  ah, 1
    int  10h           { set cursor Characteristics }
end;

procedure linhas(writeline : integer);

begin
case writeline of
    1 : writeln('北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北�');
    2 : writeln('北北北北北北北北壁屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯涂北北北北北北北北�');
    3 : writeln('北北北壁屯屯勘北背  苘苘苘苘�      苘�     �     苘苘苘苘�   嘲氨壁屯屯勘北北北');
    4 : writeln('北北北背1   嘲氨背  圹�  �  �      圹�  �  �     圹�         嘲氨背1   嘲北北北');
    5 : writeln('北北北背 9  嘲氨背  圹�     �      圹�  �  �     哌哌哌哌�   嘲氨背 9  嘲北北北');
    6 : writeln('北北北背  9 嘲氨背  哌�     �      哌哌哌哌�     哌哌哌哌�   嘲氨背  9 嘲北北北');
    7 : writeln('北北北背   7嘲氨背 哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪� 嘲氨背   7嘲北北北');
    8 : writeln('北北北崩屯屯侔氨背  M U A D D I B '' S  W O R M S  S C R P T  嘲氨崩屯屯侔北北北');
    9 : writeln('北北北北卑鞍鞍氨崩屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯唾鞍北北鞍鞍氨北北�');
   10 : writeln('北北北北北北北北北卑鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍北北北北北北北�');
   11 : writeln('');
   12 : writeln('');
   13 : writeln('Hi..');
   14 : writeln('');
   15 : writeln('After a long time in the coding scene.. and after many many tries to do');
   16 : writeln('someting usefull for diffrent groups i finally found something that will be');
   17 : writeln('a hit !!');
   18 : writeln('i decided to write A GAME...');
   19 : writeln('although it has been made like... 1000 times, i decided to do it again in');
   20 : writeln('a diffrent angle...');
   21 : writeln('u can make ur own levels and the best ones will be released in the next deadkrew');
   22 : writeln('pack ... UNDER UR NAME AND EMAIL !!!!');
   23 : writeln('so .. make and send some..');
   24 : writeln('have fun, MuadDib@usa.net !!');
   25 : writeln('');
   26 : writeln('HOW TO MAKE THE LEVELS :>');
   27 : writeln('write how much levels u have in the script... aka LASTLEVEL=?');
   28 : writeln('After... ur level has a limit of 24 lines..');
   29 : writeln('L means the limit of the level if u touch u die...');
   30 : writeln('H means Head of worm');
   31 : writeln('T means Tail of worm');
   32 : writeln('A-E means ... also the tail ...');
   33 : writeln('1-9 Means the Food U eat...');
   34 : writeln('for more info look in worms.lvl');
   35 : writeln('S means secret passage');
   36 : writeln('space means nothing...');
   37 : writeln('if u want space or S in the border.. be sure to put one in other same side');
   38 : writeln('of the screen.. if u write it in (5,1) so do it also in (5,24)...');
   39 : writeln('');
   40 : writeln('cheats: ofcourse i did those,,,,.... Doom II has them... :)');
   41 : writeln('L skip level');
   42 : writeln('F skip Food');
   43 : writeln('S Skip score');
   44 : writeln('W copy up');
   45 : writeln('A copy left');
   46 : writeln('D copy right');
   47 : writeln('X copy down');
   48 : writeln('[] lives');
   49 : writeln('+- speed');
   50 : writeln('');
   51 : writeln('** and tell me what u think...');
   52 : writeln('--------------------------------------------------------------------------------');
   53 : writeln('');
   54 : writeln('MuadDib,....');
   55 : writeln(' ');
   56 : writeln(' ');
   end;
end;

{-------------------------------------------------------------------
 ---                           SCROLL                            ---
 ---                    L. Sclovsky   6.94                       ---
 ---  Modifications: J.J. Arenzon 94                             ---
 -------------------------------------------------------------------}
 procedure scroll;

 type actions = ( lineup, linedown, pageup, pagedown, gohome, goend,
                 quit, none );

 const topstatusline = 1;
       bottomstatusline = 25;
       firstrow = 2;
       lastrow = 24;
       totrows = 23;

 label 1;

 var fim                                         : boolean;
     y, key                                      : byte;
     i, currline, writeline,
     lastpageline, percent                       : integer;
     c                                           : char;
     action                                      : actions;
     textfile                                    : text;
     textline                                    : string[80];


   procedure statusbars;
   begin
   {top bar}
   textbackground( LIGHTGRAY );
   textcolor( BLACK );
   gotoxy( 1, topstatusline );
   clreol;
   gotoxy( 25, topstatusline );
   write('On-line help for');
   textcolor( RED );
   write(' YOUR PROGRAM');
   {bottom bar}
   textbackground( LIGHTGRAY );
   textcolor( BLACK );
   gotoxy( 1, bottomstatusline );
   clreol;
   gotoxy( 2, bottomstatusline );
   write('Commands: ',char(24),' ',char(25),' PgUp PgDn Home End Esc');
   gotoxy( 79, bottomstatusline );
   Write('%');
   end;

begin
if lines > totrows
then lastpageline := lines - totrows + 1
else lastpageline := 1;

fim := false;
currline := 1;
action := pagedown;

{ clear screen }
textbackground( BLUE );
textcolor( WHITE );
clrscr;

statusbars;


while not fim
do begin

   { refresh screen }
   if action <> none 
   then begin

        textbackground( BLUE );
        textcolor( WHITE );
        writeline := currline;
        for y := firstrow to lastrow
        do begin
           gotoxy( 1, y );
           clreol;
           if writeline <= lines
           then begin
                linhas(writeline);
                writeline := writeline + 1;
                end;
           end;

        textbackground( LIGHTGRAY );
        textcolor( RED );
        percent := trunc( ( currline + totrows - 1 ) / lines * 100 );
        if percent > 100 then percent := 100;
        gotoxy( 75, bottomstatusline );
        Write( percent:3 );
        end;

   { reads keyboard }
   action := none;
   c := readkey;
   key := ord(c);
   if key > 0
   then case key of
             27 : action := quit;
             end
   else begin
        c := readkey;
        key := ord(c);
        case key of
             72 : action := lineup;
             80 : action := linedown;
             73 : action := pageup;
             81 : action := pagedown;
             71 : action := gohome;
             79 : action := goend;
             end;
        end;

   { process action }
   case action of
        lineup : if currline > 1
                 then currline := currline - 1
                 else action := none;
        linedown : if currline < lastpageline
                   then currline := currline + 1
                   else action := none;
        pageup : if currline > totrows
                 then currline := currline - totrows
                 else if currline > 1
                      then currline := 1
                      else action := none;
        pagedown : if currline + totrows < lastpageline
                   then currline := currline + totrows
                   else if currline < lastpageline
                        then currline := lastpageline
                        else action := none;
        gohome : if currline <> 1
                 then currline := 1
                 else action := none;
        goend : if currline <> lastpageline
                then currline := lastpageline
                else action := none;
        quit : fim := true;
        end;

   end;



1 :

textcolor(lightgray);
textbackground(black);
clrscr;
cursoron;

end;
(*  Initialization *)

begin
scroll
end.

