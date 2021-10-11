unit F_Constants;

interface

uses
  Windows, Messages, F_UxThemes;

const
  RC_DIALOG = 101;
  RC_IMAGE  = 101;
  ID_BUTTON = 101;

var
  hApp    : THandle;
  BtnTheme: hTheme;
  IsMouse : Boolean;
  BtnProc : Pointer;
  IsManXP : Boolean;

implementation

end.