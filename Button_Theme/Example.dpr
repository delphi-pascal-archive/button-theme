program Example;

{$R Example.res}

uses
  Windows, F_Constants, D_Window;

begin
  DialogBoxW(hInstance, PWideChar(RC_DIALOG), 0, @MainDlgProc);
end.