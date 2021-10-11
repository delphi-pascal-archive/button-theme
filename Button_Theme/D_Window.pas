unit D_Window;

interface

uses
  Windows, Messages, F_UxThemes, F_SysUtils, F_Constants;

function MainDlgProc(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): BOOL; stdcall;

implementation


function PrewWndFunc(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
var
  lpPoint: TPoint;
  lpRect : TRect;
begin
  Result := 0;
  case uMsg of
    WM_MOUSEMOVE:
      begin
        GetCursorPos(lpPoint);
        GetWindowRect(hWnd, lpRect);
        if PtInRect(lpRect, lpPoint) then
          begin
            if GetCapture <> hWnd then
              begin
                SetCapture(hWnd);
                IsMouse := TRUE;
              end;
          end
        else
          begin
            ReleaseCapture;
            IsMouse := FALSE;
          end;
        InvalidateRect(hWnd, nil, FALSE);
      end;
  else
    Result := CallWindowProcW(BtnProc, hWnd, uMsg, wParam, lParam);
  end;
end;

procedure OwnerdrawButtonLparam(lpdlParam: LPARAM; hBtnIcon: Integer);
var
  lpdis    : PDrawItemStruct;
  lpBuffer : Array [0..MAX_PATH - 1] of WideChar;
  NewStylte: DWORD;
  OldStylte: DWORD;
  IconInfo : TIconInfo;
begin
  lpdis := PDrawItemStruct(lpdlParam);
  { загружаем изображение из ресурсов }
  hBtnIcon := LoadImageW(hInstance, PWideChar(RC_IMAGE), IMAGE_ICON, 16, 16, LR_DEFAULTSIZE or LR_LOADTRANSPARENT or LR_LOADMAP3DCOLORS);
  { узнаем его размеры - длинну и высоту }
  GetIconInfo(hBtnIcon, IconInfo);
  { копируем текст кнопки во временный буфер }
  SendMessageW(lpdis.hwndItem, WM_GETTEXT, SizeOf(lpBuffer), LPARAM(@lpBuffer));
  { отображаем фоновое изображение кнопки }
  if (lpdis.itemState and ODS_SELECTED) <> 0 then
    begin
      NewStylte := PBS_PRESSED;
      OldStylte := DFCS_BUTTONPUSH or DFCS_PUSHED;
    end
  else
    begin
      NewStylte := PBS_NORMAL;
      OldStylte := DFCS_BUTTONPUSH;
    end;
  if IsMouse and not ((lpdis.itemState and ODS_SELECTED) <> 0) then
    begin
      NewStylte := PBS_HOT;
      OldStylte := DFCS_BUTTONPUSH or DFCS_HOT;
    end;
  if (lpdis.itemState and ODS_DISABLED) <> 0 then
    begin
      NewStylte := PBS_DISABLED;
      OldStylte := DFCS_BUTTONPUSH or DFCS_INACTIVE;
    end;
  if InitThemeLibrary and UseThemes then
    begin
      if IsManXP then
        DrawThemeBackground(BtnTheme, lpdis.hDC, BP_PUSHBUTTON, NewStylte, lpdis.rcItem, nil)
      else
        DrawFrameControl(lpdis.hDC, lpdis.rcItem, DFC_BUTTON, OldStylte);
    end
  else
    DrawFrameControl(lpdis.hDC, lpdis.rcItem, DFC_BUTTON, OldStylte);
  { пересчитываем координаты и отображаем значок }
  lpdis.rcItem.Left  := lpdis.rcItem.Left + IconInfo.xHotspot;
  lpdis.rcItem.Right := lpdis.rcItem.Right - IconInfo.xHotspot;
  DrawIconEx(lpdis.hDC, lpdis.rcItem.Left, lpdis.rcItem.Top + ((lpdis.rcItem.Bottom - lpdis.rcItem.Top) div 2) - (IconInfo.yHotspot), hBtnIcon, IconInfo.xHotspot * 2, IconInfo.yHotspot * 2, 0, 0, DI_NORMAL);
  lpdis.rcItem.Left  := lpdis.rcItem.Left - IconInfo.xHotspot;
  lpdis.rcItem.Right := lpdis.rcItem.Right + IconInfo.xHotspot;
  lpdis.rcItem.Left  := IconInfo.xHotspot + IconInfo.xHotspot * 2;
  lpdis.rcItem.Right := lpdis.rcItem.Right - IconInfo.xHotspot;
  { отображаем текстовую информацию на кнопке }
  if InitThemeLibrary and UseThemes then
    begin
      if IsManXP then
        DrawThemeText(BtnTheme, lpdis.hDC, BP_PUSHBUTTON, NewStylte, lpBuffer, -1, DT_SINGLELINE or DT_NOPREFIX or DT_VCENTER or DT_CENTER, 0, lpdis.rcItem)
      else
        DrawTextW(lpdis.hDC, lpBuffer, -1, lpdis.rcItem, DT_SINGLELINE or DT_NOPREFIX or DT_VCENTER or DT_CENTER);
    end
  else
    DrawTextW(lpdis.hDC, lpBuffer, -1, lpdis.rcItem, DT_SINGLELINE or DT_NOPREFIX or DT_VCENTER or DT_CENTER);
  { удаляем все созданные ранее объекты }
  DeleteObject(hBtnIcon);
end;

function MainDlgProc(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): BOOL; stdcall;
begin
  Result := FALSE;
  case uMsg of

    {}
    WM_INITDIALOG:
      begin
        hApp := hWnd;
        if IsManifestAvailableW(ParamStrW()) then
          IsManXP := TRUE
        else
          IsManXP := FALSE;
        if InitThemeLibrary and UseThemes then
          BtnTheme := OpenThemeData(hApp, 'Button');
        BtnProc := Pointer(SetWindowLongW(GetDlgItem(hApp, ID_BUTTON), GWL_WNDPROC, Integer(@PrewWndFunc)));
        SetForegroundWindow(hApp);
      end;

    {}
    WM_THEMECHANGED:
      begin
        if IsManifestAvailableW(ParamStrW()) then
          IsManXP := TRUE
        else
          IsManXP := FALSE;
        if InitThemeLibrary and UseThemes then
          begin
            CloseThemeData(BtnTheme);
            BtnTheme := OpenThemeData(hApp, 'Button');
          end;
      end;

    {}
    WM_DRAWITEM:
      begin
        case LoWord(wParam) of
          ID_BUTTON:
            OwnerdrawButtonLparam(lParam, RC_IMAGE);
        end;
      end;

    {}
    WM_COMMAND:
      begin
        if HiWord(wParam) = BN_CLICKED then
          case LoWord(wParam) of
            ID_BUTTON:
              SendMessageW(hApp, WM_CLOSE, 0, 0);
          end;
      end;

   {}
    WM_LBUTTONDOWN:
      SendMessageW(hApp, WM_NCLBUTTONDOWN, HTCAPTION, lParam);

    {}
    WM_DESTROY, WM_CLOSE:
      begin
        if InitThemeLibrary and UseThemes then
          CloseThemeData(BtnTheme);
        PostQuitMessage(0);
      end;

  end;
end;

end.