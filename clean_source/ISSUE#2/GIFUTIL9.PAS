{$G+} {
    I modified  the unit written  by Sean Wenzel in order  to speed
up the  decoding of a picture . I wrote several parts using the ASM
capability of BP 7.0,but I did not change the NextCode procedure at
the beginning.
    As I was interested in any improvement,I decided to use an external
procedure written in assembly language (named ASMGIF3.ASM) : I was
a little bit disappointed:it is  not faster (not noticeable ...).

    You can find :
      - GIFUTIL9.PAS :the new unit ONLY for 256 colors !!!!!!
      - GIFTST.PAS   :an example based on the one written by Sean Wenzel.
      - ASMGIF3.ASM  :the ASM source of NextByte.

  You can use,modified an distribute this source as long as credit is given.


                                      Lionel CORDESSES
                                      from FRANCE.
                                      November 1994
    E-Mail:
      cordesse@opgc.univ-bpclermont.fr



 "The Graphics Interchange Format(c) is the Copyright property of
  CompuServe Incorporated. GIF(sm) is a Service Mark property  of
  CompuServe Incorporated."
}

unit GifUtil9;


{$R-} { range checking off }  { Put them on if you like but it slows down }
{$S-} { stack checking off }  { The decoding  (almost doubles it!) }
{$I-} { i/o checking off }

interface


var status:byte;

procedure general(nom:string);


implementation

uses usvesa, Crt;
type
 TDataSubBlock = record
  Size: byte;     { size of the block -- 0 to 255 }
  Data: array[1..255] of byte; { the data }
 end;

const
 BlockTerminator: byte = 0; { terminates stream of data blocks }

type
 THeader = record
  Signature: array[0..2] of char; { contains 'GIF' }
  Version: array[0..2] of char;   { '87a' or '89a' }
 end;

 TLogicalScreenDescriptor = record
  ScreenWidth: word;              { logical screen width }
  ScreenHeight: word;  { logical screen height }
  PackedFields: byte;     { packed fields - see below }
  BackGroundColorIndex: byte;     { index to global color table }
  AspectRatio: byte;      { actual ratio = (AspectRatio + 15) / 64 }
 end;

const
{ logical screen descriptor packed field masks }
 lsdGlobalColorTable = $80;  { set if global color table follows L.S.D. }
 lsdColorResolution = $70;               { Color resolution - 3 bits }
 lsdSort = $08;
{ set if global color table is sorted - 1 bit }
 lsdColorTableSize = $07;                { size of global color
table - 3 bits }

      { Actual size =
2^value+1    - value is 3 bits }

type
 TColorItem = record     { one item a a color table }
  Red: byte;
  Green: byte;
  Blue: byte;
 end;

 TColorTable = array[0..255] of TColorItem;      { the color table }

const
 ImageSeperator: byte = $2C;

type
 TImageDescriptor = record
  Seperator: byte;                         { fixed value
of ImageSeperator }
  ImageLeftPos: word; {Column in pixels in respect to
left edge of logical screen }
  ImageTopPos: word;{row in pixels in respect to top of
logical screen }
  ImageWidth: word;       { width of image in pixels }
  ImageHeight: word;      { height of image in pixels }
  PackedFields: byte; { see below }
 end;
const
 { image descriptor bit masks }
  idLocalColorTable = $80; { set if a local color table follows }
  idInterlaced = $40;                      { set if image
is interlaced }
  idSort = $20;
 { set if color table is sorted }
  idReserved = $0C;                                {
reserved - must be set to $00 }
  idColorTableSize = $07;  { size of color table as above }

 Trailer: byte = $3B;    { indicates the end of the GIF data stream }

{ other extension blocks not currently supported by this unit
 - Graphic Control extension
 - Comment extension           I'm not sure what will happen if these blocks
 - Plain text extension        are encountered but it'll be interesting
 - application extension }

const
 ExtensionIntroducer: byte = $21;
 MAXSCREENWIDTH = 800;

type
 TExtensionBlock = record
  Introducer: byte;                               { fixed
value of ExtensionIntroducer }
  ExtensionLabel: byte;
  BlockSize: byte;
 end;

 PCodeItem = ^TCodeItem;
 TCodeItem = record
  Code1, Code2: byte;
 end;

const
 MAXCODES = 4095;        { the maximum number of different codes
0 inclusive }



const
{ error constants }
 geNoError = 0;                          { no errors found }
 geNoFile = 1;         { gif file not found }
 geNotGIF = 2;         { file is not a gif file }
 geNoGlobalColor = 3;  { no Global Color table found }
 geImagePreceded = 4;  { image descriptor preceeded by other unknown data }
 geEmptyBlock = 5;                       { Block has no data }
 geUnExpectedEOF = 6;  { unexpected EOF }
 geBadCodeSize = 7;    { bad code size }
 geBadCode = 8;                          { Bad code was found }
 geBitSizeOverflow = 9; { bit size went beyond 12 bits }

type
  stream_ptr=^stream_type;
  stream_type=record
  Header: THeader;
                                        { gif file header }
  LogicalScreen: TLogicalScreenDescriptor;  { gif screen descriptor }
              end;


var fichier:file;
    stream:stream_type;
    TableSize: word;   { number of entrys in the color table }
    GlobalColorTable: TColorTable;            { global color table }
    LocalColorTable: TColorTable;             { local color table }
    ImageDescriptor: TImageDescriptor;        { image descriptor }
    UseLocalColors: boolean;                  { true if local colors in use }
    Interlaced: boolean;                      { true if image is interlaced }
    InterlacePass: byte;                      { interlace pass number }
    LZWCodeSize: byte;                        { minimum size of the LZW
codes in bits }
    BitsLeft,BytesLeft: integer;{ bits left in byte - bytes left in block }
    BadCodeCount: word;          { bad code counter }
    CurrCodeSize: integer;       { Current size of code in bits }
    ClearCode: integer;          { Clear code value }
    EndingCode: integer;         { ending code value }
    Slot: word;                  { position that the next new code is to be
added }
    TopSlot: word;               { highest slot position for the
current code size }
    HighCode: word;              { highest code that does not require decoding
}
    NextByte: integer;           { the index to the next byte in the
datablock array }
    CurrByte: byte;              { the current byte }
    CurrentX, CurrentY: integer; { current screen locations }
    ImageData: TDataSubBlock;    { variable to store incoming gif data }
    DecodeStack: array[0..MAXCODES] of byte; { stack for the decoded codes }
    Prefix: array[0..MAXCODES] of word; { array for code prefixes }
    Suffix: array[0..MAXCODES] of byte; { array for code suffixes }
    LineBuffer: array[0..MAXSCREENWIDTH] of byte; { array for buffer line
output }
    table:array[0..767] of byte;
    indice_sp:integer;           { index to the decode stack }
    indice:word;
    Retour: longint;             { temporary return value }

{$L asmgif3}

function Power(A, N: integer): integer;       { returns A raised to the
power of N }
begin
 Power := 1 shl n;
end;

procedure TGif_Error(What: integer);
begin
 Status := What;
        if What=geNoFile then halt(1);
end;


{ TGif }
procedure TGif_Init(AGIFName: string);
  begin
 if Pos('.',AGifName) = 0 then     { if the filename has no
extension add one }

  AGifName := AGifName + '.gif';
{ New(stream,  2048);}
        assign(fichier,agifname);
        {$i-}
        reset(fichier,1);
        if ioresult<>0 then tgif_Error(geNoFile);
        blockRead(fichier,stream, sizeof(Theader));   { read the header }
 if stream.Header.Signature <> 'GIF' then tgif_Error(geNotGIF);
                            { is vaild signature }
 blockRead(fichier,stream.LogicalScreen, sizeof(TLogicalScreenDescriptor));
 if stream.LogicalScreen.PackedFields and lsdGlobalColorTable =
lsdGlobalColorTable then
 begin
  TableSize :=
trunc(Power(2,(stream.LogicalScreen.PackedFields and lsdColorTableSize)+1));
  blockread(fichier,GlobalColorTable,
TableSize*sizeof(TColorItem)); { read Global Color Table }
 end
 else
  tgif_Error(geNoGlobalColor);
 blockread(fichier,ImageDescriptor, sizeof(ImageDescriptor)); {
read image descriptor }
 if ImageDescriptor.Seperator <> ImageSeperator then
        { verify that it is the descriptor }
  tgif_Error(geImagePreceded);
 if ImageDescriptor.PackedFields and idLocalColorTable =
idLocalColorTable then
 begin
          { if local color table }
  TableSize :=
trunc(Power(2,(ImageDescriptor.PackedFields and idColorTableSize)+1));
  blockread(fichier,LocalColorTable,
TableSize*sizeof(TColorItem)); { read Local Color Table }
  UseLocalColors := True;
 end
 else
  UseLocalColors := false;
 if ImageDescriptor.PackedFields and idInterlaced = idInterlaced then
 begin
  Interlaced := true;
  InterlacePass := 0;
 end;
 Status := 0;
        writeln('nb coul: ',tablesize);
  end;

procedure TGif_Done;
  begin
        close(fichier);
  end;


procedure InitCompressionStream;
var
 I: integer;
        n:byte;
begin
                            { Initialize the graphics display }
 blockread(fichier,LZWCodeSize, sizeof(byte));{ get minimum code size }
 if not (LZWCodeSize in [2..9]) then     { valid code sizes 2-9 bits }
  tgif_Error(geBadCodeSize);

 CurrCodeSize := succ(LZWCodeSize); { set the initial code size }
 ClearCode := 1 shl LZWCodeSize;    { set the clear code }
 EndingCode := succ(ClearCode);     { set the ending code }
 HighCode := pred(ClearCode);                     { set the
highest code not needing decoding }
 BytesLeft := 0;                    { clear other variables }
 BitsLeft := 0;
 CurrentX := 0;
 CurrentY := 0;
end;
{$f-}
procedure TGif_ReadSubBlock;
begin
 blockread(fichier,ImageData.Size, sizeof(ImageData.Size)); {
get the data block size }
 if ImageData.Size = 0 then tgif_Error(geEmptyBlock); { check
for empty block }
 blockread(fichier,ImageData.Data, ImageData.Size);   { read in the block }
 NextByte := 1;                                  { reset next byte }
 BytesLeft := ImageData.Size;
                                        { reset bytes left }
end;

const
 CodeMask: array[0..12] of longint = (  { bit masks for use with Next code }
  0,
  $0001, $0003,
  $0007, $000F,
  $001F, $003F,
  $007F, $00FF,
  $01FF, $03FF,
  $07FF, $0FFF);

{$f-}
function NextCode: word;external; { returns a code of the proper bit size }

procedure write_pal(var pal;start,quant:word);
  begin
    asm
      push ds
      lds si,pal
      mov dx,3c8h
      cld
      mov cx,quant
      mov bx,start
      @deb1:
        mov al,bl
        out dx,al
        inc dx
        lodsb
        out dx,al
        lodsb
        out dx,al
        lodsb
        out dx,al
        dec dx
        inc bl
      loop @deb1
      pop ds
    end;
  end;


procedure InitGraphics;
var
        n:byte;
        x,y,i:word;
begin
        { you can change the $101 value for other VESA modes }
        n:=setmode($101);
 if n =0  then
 begin
  Writeln('vesa error ');
  Halt(1);
 end;

 { the following loop sets up the RGB palette }
        x:=0;
 if not UseLocalColors then
          begin
            for I := 0 to TableSize - 1 do
              begin
               table[x]:=GlobalColorTable[I].Red div 4;
               inc(x);
               table[x]:=GlobalColorTable[i].Green div 4;
               inc(x);
               table[x]:=GlobalColorTable[I].Blue div 4;
               inc(x);
             end;
             write_pal(table[0],0,tablesize);
          end
 else
          begin
            x:=0;
            for I := 0 to TableSize - 1 do
              begin
               table[x]:=localColorTable[I].Red div 4;
               inc(x);
               table[x]:=localColorTable[i].Green div 4;
               inc(x);
               table[x]:=localColorTable[I].Blue div 4;
               inc(x);
             end;
             write_pal(table[0],0,tablesize);
           end;
{
       for x:=0 to 255 do
         for y:=0 to 255 do
           setpix(x,y,x);}
end;


procedure DrawLine;
var
 I: integer;

begin
        if not write_fast(0,CurrentY,ImageDescriptor.ImageWidth,
          LineBuffer[0]) then
 for I := 0 to ImageDescriptor.ImageWidth do
  setpix(I, CurrentY, LineBuffer[I]);
 inc(CurrentY);

 if InterLaced then     { Interlace support }
 begin
  case InterlacePass of
   0: CurrentY := CurrentY + 7;
   1: CurrentY := CurrentY + 7;
   2: CurrentY := CurrentY + 3;
   3: CurrentY := CurrentY + 1;
  end;
  if CurrentY >= ImageDescriptor.ImageHeight then
  begin
   inc(InterLacePass);
   case InterLacePass of
    1: CurrentY := 4;
    2: CurrentY := 2;
    3: CurrentY := 1;
   end;
  end;
 end;
end;

{ this procedure initializes the graphics mode and actually decodes the
 GIF image }
procedure Decode(Beep: boolean);


{ local procedure that decodes a code and puts it on the decode stack }
procedure DecodeCode(var code:word);assembler;
  asm
      les di,code
      mov bx,word ptr [es:di]
      mov si,indice_sp
      cmp bx,HighCode
      jbe @@fin

    @@boucle:
      mov al,[offset word ptr Suffix+bx]  { al:=suffix[code] }
      mov [Offset word ptr DecodeStack+si],al      { decodestack:=al }
      inc si

      shl bx,1   { array of  word }
      mov bx,[Offset word ptr Prefix+bx]    {code:=prefix[code }
      cmp bx,word ptr HighCode
      ja @@boucle

    @@fin:
      mov [Offset word ptr DecodeStack+si],bx

      inc si
      mov indice_sp,si
      mov word ptr [es:di],bx
  end;


var
 TempOldCode, OldCode: word;
 BufCnt: word;           { line buffer counter }
 Code, C: word;
 CurrBuf: word;  { line buffer index }
begin
 InitGraphics;             { Initialize the graphics mode and RGB palette }
 InitCompressionStream;    { Initialize decoding paramaters }
 OldCode := 0;
 indice_sp := 0;
 BufCnt := ImageDescriptor.ImageWidth; { set the Image Width }
 CurrBuf := 0;

 C := NextCode;                                          { get
the initial code - should be a clear code }
 while C <> EndingCode do  { main loop until ending code is found }
 begin
  if C = ClearCode then   { code is a clear code - so clear }
  begin
   CurrCodeSize := LZWCodeSize + 1;{ reset the code size }
   Slot := EndingCode + 1;
        { set slot for next new code }
   TopSlot := 1 shl CurrCodeSize;  { set max slot number }
   while C = ClearCode do
    C := NextCode;                  { read
until all clear codes gone - shouldn't happen }
   if C = EndingCode then
   begin
    tgif_Error(geBadCode);   { ending code
after a clear code }
    break;
                { this also should never happen }
   end;
   if C >= Slot { if the code is beyond preset
codes then set to zero }
    then c := 0;
   OldCode := C;
   DecodeStack[indice_sp] := C;
               { output code to decoded stack }
   inc(indice_sp);
                         { increment decode stack index }
  end
  else   { the code is not a clear code or an ending code
so it must }
  begin  { be a code code - so decode the code }
   Code := C;
   if Code < Slot then     { is the code in the table? }
   begin
    DecodeCode(Code);
                { decode the code }
    if Slot <= TopSlot then
    begin                             { add
the new code to the table }
                                 Suffix[Slot] := Code;
        { make the suffix }
     PreFix[slot] := OldCode;
{ the previous code - a link to the data }
     inc(Slot);
                                        { increment slot number }
     OldCode := C;
                                { set oldcode }
    end;
    if Slot >= TopSlot then { have reached
the top slot for bit size }
    begin                   { increment code bit size }
     if CurrCodeSize < 12 then { new
bit size not too big? }
     begin
      TopSlot := TopSlot shl
1;       { new top slot }
      inc(CurrCodeSize)
                                { new code size }
     end
     else

tgif_Error(geBitSizeOverflow); { encoder made a boo boo }
    end;
   end
   else
   begin           { the code is not in the table }
    if Code <> Slot then
{ code is not the next available slot }
     tgif_Error(geBadCode);  { so error out }

    { the code does not exist so make a new
entry in the code table
     and then translate the new code }
    TempOldCode := OldCode;  { make a copy
of the old code }
    while OldCode > HighCode do { translate
the old code and place it }
    begin
{ on the decode stack }
     DecodeStack[indice_sp] :=
Suffix[OldCode]; { do the suffix }
     OldCode := Prefix[OldCode];
    { get next prefix }
    end;
    DecodeStack[indice_sp] := OldCode;
{ put the code onto the decode stack }


{ but DO NOT increment stack index }
    { the decode stack is not incremented
because because we are only
     translating the oldcode to get
the first character }
    if Slot <= TopSlot then
    begin                 { make new code entry }
     Suffix[Slot] := OldCode;
         { first char of old code }
     Prefix[Slot] := TempOldCode; {
link to the old code prefix }
     inc(Slot);                   {
increment slot }
    end;
    if Slot >= TopSlot then { slot is too big }
    begin                   { increment code size }
     if CurrCodeSize < 12 then
     begin
      TopSlot := TopSlot shl
1;       { new top slot }
      inc(CurrCodeSize)
                                { new code size }
     end
     else
      tgif_Error(geBitSizeOverFlow);
    end;
    DecodeCode(Code); { now that the table
entry exists decode it }
    OldCode := C;     { set the new old code }
   end;
  end;
  { the decoded string is on the decode stack so pop it
off and put it
   into the line buffer }

                        asm
                          mov cx,BufCnt
                          mov si,CurrBuf
                          mov bx,indice_sp
                          cmp bx,0
                          je @@fin

                        @@boucle:
                          dec bx
                          mov al,[offset byte ptr DecodeStack+bx]
                          mov  [offset byte ptr LineBuffer+si],al
                          inc si
                          dec cx
                          jnz @@suite
                                  pusha
                                  push di
                                  call DrawLine
                                  pop di
                                  popa
                                  mov si,0
                                  mov cx,[offset ImageDescriptor.ImageWidth]
                        @@suite:
                          cmp bx,0
                          ja @@boucle
                        @@fin:
                          mov BufCnt,cx
                          mov indice_sp,bx
                          mov CurrBuf,si
                        end;

 C := NextCode;  { get the next code and go at is some more }
 end;            { now that wasn't all that bad was it? }
 if Beep then
  if Status = 0 then
  begin
   Sound(200);     { Beep if status is ok }
   Delay(0);
   NoSound;
  end
  else
  begin
   Sound(1100); { Boop if status is not ok }
   Delay(0);
   NoSound;
  end;
end;

procedure general(nom:string);
var k:char;
  begin
    tgif_init(nom);
    decode(true);
    tgif_done;
    k:=readkey;
  end;

end.

{
cut here
