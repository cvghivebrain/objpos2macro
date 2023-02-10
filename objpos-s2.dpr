program objpos;

{$APPTYPE CONSOLE}

uses
  Windows, SysUtils, StrUtils;

var
  inifile, outfile: textfile;
  datafile: file;
  dataarray: array of byte;
  i: integer;
  id: byte;
  thisfolder, s, xpos, ypos, idstr, subtype, extra, fn: string;
  objname: array[0..255] of string;

label endnow;

  { Functions. }

function GetWord(a: integer): word; // Get word from file array.
begin
  result := (dataarray[a] shl 8)+dataarray[a+1];
end;

function Explode(s, d: string; n: integer): string; // Get substring from string using delimiter.
begin
  if (AnsiPos(d,s) = 0) and ((n = 0) or (n = -1)) then result := s // Output full string if delimiter not found.
  else
    begin
    s := s+d;
    while n > 0 do
      begin
      Delete(s,1,AnsiPos(d,s)+Length(d)-1); // Trim earlier substrings and delimiters.
      dec(n);
      end;
    Delete(s,AnsiPos(d,s),Length(s)-AnsiPos(d,s)+1); // Trim later substrings and delimiters.
    result := s;
    end;
end;


  { Program start. }
begin

  if ParamStr(1) = '' then goto endnow; // End program if run without parameters.

  thisfolder := ExtractFilePath(ParamStr(0)); // Get folder for this program.
  if FileExists(thisfolder+'objpos.ini') then // Check if ini file exists.
    begin
    AssignFile(inifile,thisfolder+'objpos.ini'); // Open ini file.
    Reset(inifile); // Read only.
    while not eof(inifile) do
      begin
      ReadLn(inifile,s);
      if AnsiPos('=',s) <> 0 then
        objname[StrtoInt('$'+Explode(s,'=',0))] := Explode(s,'=',1); // Save object name to array.
      end;
    CloseFile(inifile);
    end;

  AssignFile(datafile,ParamStr(1)); // Get file.
  FileMode := fmOpenRead; // Read only.
  Reset(datafile,1);
  SetLength(dataarray,FileSize(datafile));
  BlockRead(datafile,dataarray[0],FileSize(datafile)); // Copy file to memory.
  CloseFile(datafile); // Close file.

  AssignFile(outfile,ParamStr(2));
  ReWrite(outfile); // Open output file (read/write).

  i := 0; // Start address.
  fn := AnsiUpperCase(ReplaceStr(ExtractFileName(ParamStr(1)),'.bin',''));
  WriteLn(outfile,'; ---------------------------------------------------------------------------');
  WriteLn(outfile,'; '+fn+' object placement');
  WriteLn(outfile,'; ---------------------------------------------------------------------------');
  WriteLn(outfile,'ObjPos_'+fn+':');

  while i < Length(dataarray) do
    begin
    xpos := InttoHex(Getword(i)); // Get xpos.
    ypos := InttoHex(Getword(i+2) and $fff); // Get ypos.
    id := dataarray[i+4]; // Get object id.
    if objname[id] = '' then idstr := '$'+InttoHex(id) // Use byte as id.
      else idstr := objname[id]; // Use object name as id if name exists.
    subtype := InttoHex(dataarray[i+5]); // Get object subtype.
    if (dataarray[i+2] and $20) > 0 then extra := ',xflip' // Check for xflip flag.
      else extra := '';
    if (dataarray[i+2] and $40) > 0 then extra := extra+',yflip'; // Check for yflip flag.
    if (dataarray[i+2] and $80) > 0 then extra := extra+',rem'; // Check for rem flag.
    if (dataarray[i+2] and $10) > 0 then extra := extra+',unkflg'; // Check for unused Buzzer and Flasher flag.
    if Getword(i) = $ffff then WriteLn(outfile,#9+#9+'endobj') // End of file.
      else WriteLn(outfile,#9+#9+'objpos $'+xpos+',$'+ypos+','+idstr+',$'+subtype+extra);
    i := i+6; // Next object.
    end;

  CloseFile(outfile);
  endnow:
end.