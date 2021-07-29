program FileLister;

{$APPTYPE CONSOLE}

uses
  Windows, SysUtils, StrUtils;

var
  outfile: textfile;
  datafile: file;
  dataarray: array of byte;
  i: integer;
  xpos, ypos, id, subtype, extra: string;

label endnow;

  { Functions. }

function GetWord(a: integer): word; // Get word from file array.
begin
  result := (dataarray[a] shl 8)+dataarray[a+1];
end;


  { Program start. }
begin

  if ParamStr(1) = '' then goto endnow; // End program if run without parameters.

  AssignFile(datafile,ParamStr(1)); // Get file.
  FileMode := fmOpenRead; // Read only.
  Reset(datafile,1);
  SetLength(dataarray,FileSize(datafile));
  BlockRead(datafile,dataarray[0],FileSize(datafile)); // Copy file to memory.
  CloseFile(datafile); // Close file.

  AssignFile(outfile,ParamStr(2));
  ReWrite(outfile); // Open output file (read/write).

  i := 0; // Start address.
  WriteLn(outfile,'; ---------------------------------------------------------------------------');
  WriteLn(outfile,'; '+AnsiUpperCase(ReplaceStr(ParamStr(1),'.bin',''))+' object placement');
  WriteLn(outfile,'; ---------------------------------------------------------------------------');

  while i < Length(dataarray) do
    begin
    xpos := InttoHex(Getword(i)); // Get xpos.
    ypos := InttoHex(Getword(i+2) and $fff); // Get ypos.
    id := InttoHex(dataarray[i+4] and $7f); // Get object id.
    subtype := InttoHex(dataarray[i+5]); // Get object subtype.
    if (dataarray[i+2] and $40) > 0 then extra := ',xflip' // Check for xflip flag.
      else extra := '';
    if (dataarray[i+2] and $80) > 0 then extra := extra+',yflip'; // Check for yflip flag.
    if (dataarray[i+4] and $80) > 0 then extra := extra+',rem'; // Check for rem flag.
    if Getword(i) = $ffff then WriteLn(outfile,#9+#9+'endobj') // End of file.
      else WriteLn(outfile,#9+#9+'objpos $'+xpos+',$'+ypos+',$'+id+',$'+subtype+extra);
    i := i+6; // Next object.
    end;

  CloseFile(outfile);
  endnow:
end.