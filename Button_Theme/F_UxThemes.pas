unit F_UxThemes;

interface

uses
  Windows;

procedure FreeThemeLibrary;
function InitThemeLibrary: Boolean;
function UseThemes: Boolean;

type
  HTHEME = THANDLE;

var
  OpenThemeData      : function(hwnd: HWND; pszClassList: LPCWSTR): HTHEME; stdcall;
  CloseThemeData     : function(hTheme: HTHEME): HRESULT; stdcall;
  DrawThemeBackground: function(hTheme: HTHEME; hdc: HDC; iPartId, iStateId: Integer; const pRect: TRect; pClipRect: PRECT): HRESULT; stdcall;
  DrawThemeText      : function(hTheme: HTHEME; hdc: HDC; iPartId, iStateId: Integer; pszText: LPCWSTR; iCharCount: Integer; dwTextFlags, dwTextFlags2: DWORD; const pRect: TRect): HRESULT; stdcall;
  IsThemeActive      : function: BOOL; stdcall;
  IsAppThemed        : function: BOOL; stdcall;
  FSection           : TRTLCriticalSection;
  ThemeLibrary       : THandle;
  ReferenceCount     : Integer;

const
  BP_PUSHBUTTON = 1;
  PBS_NORMAL    = 1;
  PBS_HOT       = 2;
  PBS_PRESSED   = 3;
  PBS_DISABLED  = 4;
  PBS_DEFAULTED = 5;

implementation

procedure FreeThemeLibrary;
begin
  EnterCriticalSection(FSection);
  try
    if ReferenceCount > 0 then
      Dec(ReferenceCount);
    if (ThemeLibrary <> 0) and (ReferenceCount = 0) then
      begin
        FreeLibrary(ThemeLibrary);
        ThemeLibrary := 0;
        OpenThemeData := nil;
        CloseThemeData := nil;
        DrawThemeBackground := nil;
        DrawThemeText := nil;
        IsThemeActive := nil;
        IsAppThemed := nil;
      end;
  finally
    LeaveCriticalSection(FSection);
  end;
end;

function InitThemeLibrary: Boolean;
begin
  EnterCriticalSection(FSection);
  try
    Inc(ReferenceCount);
    if ThemeLibrary = 0 then
      begin
        ThemeLibrary := LoadLibrary('uxtheme.dll');
        if ThemeLibrary > 0 then
          begin
            OpenThemeData := GetProcAddress(ThemeLibrary, 'OpenThemeData');
            CloseThemeData := GetProcAddress(ThemeLibrary, 'CloseThemeData');
            DrawThemeBackground := GetProcAddress(ThemeLibrary, 'DrawThemeBackground');
            DrawThemeText := GetProcAddress(ThemeLibrary, 'DrawThemeText');
            IsThemeActive := GetProcAddress(ThemeLibrary, 'IsThemeActive');
            IsAppThemed := GetProcAddress(ThemeLibrary, 'IsAppThemed');
          end;
      end;
    Result := ThemeLibrary > 0;
  finally
    LeaveCriticalSection(FSection);
  end;
end;

function UseThemes: Boolean;
begin
  if (ThemeLibrary > 0) then
    Result := IsAppThemed and IsThemeActive
  else
    Result := False;
end;

initialization
  InitializeCriticalSection(FSection);

finalization
  while ReferenceCount > 0 do
    FreeThemeLibrary;
  
end.