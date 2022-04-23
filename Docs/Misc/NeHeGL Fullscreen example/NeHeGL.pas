unit NeHeGL;

interface

uses windows, messages, opengl, ARB_multisample;

type
  Keys = record
    keyDown: array [0..255] of boolean;
    end;

  PKeys = ^Keys;

  Application = record
    hInstance: HINST;
    className: string;
    end;

  GL_WindowInit = record
    application: ^Application;
    title: string;
    width: integer;
    height: integer;
    bitsPerPixel: integer;
    isFullScreen: boolean;
    end;

  GL_Window = record
    keys: PKeys;
    hWnd: HWND;                      // Obsahuje Handle na�eho okna
    hDc: HDC;                        // Priv�tn� GDI Device Context
    hRc: HGLRC;		                  // Trval� Rendering Context
    init: GL_WindowInit;
    isVisible: boolean;
    lastTickCount: DWORD;
    end;

  PGL_Window = ^GL_Window;

procedure TerminateApplication(window: GL_Window);
procedure ToggleFullscreen(window: GL_Window);
procedure ReshapeGL(Width, Height: GLsizei);
function CreateWindowGL(var window: GL_Window): boolean;
function DestroyWindowGL(var window: GL_Window): boolean;  

const
  WM_TOGGLEFULLSCREEN = WM_USER + 1;

var
  g_isProgramLooping: boolean;
  g_createFullScreen: boolean;

implementation

procedure TerminateApplication(window: GL_Window);
begin
  PostMessage(window.hWnd,WM_QUIT,0,0);
  g_isProgramLooping := false;
end;

procedure ToggleFullscreen(window: GL_Window);
begin
  PostMessage(window.hWnd,WM_TOGGLEFULLSCREEN,0,0);
end;

procedure ReshapeGL(Width, Height: GLsizei); // Zm�na velikosti a inicializace OpenGL okna
begin
  if Height = 0 then		                                  // Zabezpe�en� proti d�len� nulou
     Height := 1;                                           // Nastav� v��ku na jedna
  glViewport(0,0,Width,Height);                        // Resetuje aktu�ln� nastaven�
  glMatrixMode(GL_PROJECTION);                            // Zvol� projek�n� matici
  glLoadIdentity;                                       // Reset matice
  gluPerspective(50.0,Width/Height,5.0,2000.0);            // V�po�et perspektivy
  glMatrixMode(GL_MODELVIEW);                             // Zvol� matici Modelview
  glLoadIdentity;                                         // Reset matice
end;

function ChangeScreenResolution(width, height, bitsPerPixel: integer): boolean;
var
  dmScreenSettings: DEVMODE;      // M�d za��zen�
begin
  ZeroMemory(@dmScreenSettings,sizeof(dmScreenSettings));  // Vynulov�n� pam�ti
  with dmScreensettings do
    begin
    dmSize := sizeof(dmScreenSettings);         // Velikost struktury Devmode
    dmPelsWidth := width;	                    // ���ka okna
    dmPelsHeight := height;                     // V��ka okna
    dmBitsPerPel := bitsPerPixel;                       // Barevn� hloubka
    dmFields := DM_BITSPERPEL or DM_PELSWIDTH or DM_PELSHEIGHT;
    end;
  // Pokus� se pou��t pr�v� definovan� nastaven�
  if ChangeDisplaySettings(dmScreenSettings,CDS_FULLSCREEN) <> DISP_CHANGE_SUCCESSFUL then
    begin
    Result := false;
    exit;
    end;
  Result := true;
end;

function CreateWindowGL(var window: GL_Window): boolean;
var
  windowStyle: DWORD;                  // Styl okna
  windowExtendedStyle: DWORD;                // Roz���en� styl okna
  pfd: PIXELFORMATDESCRIPTOR;     // Nastaven� form�tu pixel�
  WindowRect: TRect;              // Obd�ln�k okna
  Pixelformat: GLuint;            // Ukl�d� form�t pixel�
begin
  windowStyle := WS_OVERLAPPEDWINDOW;
  windowExtendedStyle := WS_EX_APPWINDOW;
  with pfd do                                         // Ozn�m�me Windows jak chceme v�e nastavit
    begin
    nSize := SizeOf(PIXELFORMATDESCRIPTOR);        // Velikost struktury
    nVersion := 1;                                   // ��slo verze
    dwFlags := PFD_DRAW_TO_WINDOW                    // Podpora okna
            or PFD_SUPPORT_OPENGL                         // Podpora OpenGL
            or PFD_DOUBLEBUFFER;                          // Podpora Double Bufferingu
    iPixelType := PFD_TYPE_RGBA;                     // RGBA Format
    cColorBits := window.init.bitsPerPixel;                              // Zvol� barevnou hloubku
    cRedBits := 0;                                   // Bity barev ignorov�ny
    cRedShift := 0;
    cGreenBits := 0;
    cGreenShift := 0;
    cBlueBits := 0;
    cBlueShift := 0;
    cAlphaBits := 0;                                 // ��dn� alpha buffer
    cAlphaShift := 0;                                // Ignorov�n Shift bit
    cAccumBits := 0;                                 // ��dn� akumula�n� buffer
    cAccumRedBits := 0;                              // Akumula�n� bity ignorov�ny
    cAccumGreenBits := 0;
    cAccumBlueBits := 0;
    cAccumAlphaBits := 0;
    cDepthBits := 16;                                // 16-bitov� hloubkov� buffer (Z-Buffer)
    cStencilBits := 0;                               // ��dn� Stencil Buffer
    cAuxBuffers := 0;                                // ��dn� Auxiliary Buffer
    iLayerType := PFD_MAIN_PLANE;                    // Hlavn� vykreslovac� vrstva
    bReserved := 0;                                  // Rezervov�no
    dwLayerMask := 0;                                // Maska vrstvy ignorov�na
    dwVisibleMask := 0;
    dwDamageMask := 0;
    end;
  WindowRect.Left := 0;                               // Nastav� lev� okraj na nulu
  WindowRect.Top := 0;                                // Nastav� horn� okraj na nulu
  WindowRect.Right := window.init.width;                          // Nastav� prav� okraj na zadanou hodnotu
  WindowRect.Bottom := window.init.height;                        // Nastav� spodn� okraj na zadanou hodnotu
  if window.init.isFullScreen then
    if not ChangeScreenResolution(window.init.width,window.init.height,window.init.bitsPerPixel) then
      begin
      MessageBox(HWND_DESKTOP,'Mode Switch Failed.\nRunning In Windowed Mode.','Error',MB_OK or MB_ICONEXCLAMATION);
			window.init.isFullScreen := false;
      end
      else
      begin
      ShowCursor(false);
      windowStyle := WS_POPUP;
      windowExtendedStyle := windowExtendedStyle or WS_EX_TOPMOST;
      end
    else
    AdjustWindowRectEx(WindowRect,windowStyle,false,windowExtendedStyle); // P�izp�soben� velikosti okna
  // Vytvo�en� okna
  window.hWnd := CreateWindowEx(windowExtendedStyle,                    // Roz���en� styl
                               PChar(window.init.application^.className),              // Jm�no t��dy
                               PChar(window.init.title),                 // Titulek
                               windowStyle,               // Definovan� styl
                               0,0,                   // Pozice
                               WindowRect.Right-WindowRect.Left,  // V�po�et ���ky
                               WindowRect.Bottom-WindowRect.Top,  // V�po�et v��ky
                               HWND_DESKTOP,                     // Rodi�ovsk� okno
                               0,                     // Bez menu
                               window.init.application^.hInstance,             // Instance
                               @window);                  // Do WM_CREATE
  if window.hWnd = 0 then                                     // Pokud se okno nepoda�ilo vytvo�it
    begin
      Result := false;                                  // Vr�t� chybu
      exit;
    end;
  window.hDc := GetDC(window.hWnd);                               // Zkus� p�ipojit kontext za��zen�
  if window.hDc = 0 then                                      // Poda�ilo se p�ipojit kontext za��zen�?
    begin
      DestroyWindow(window.hWnd);                                 // Zav�e okno
      window.hWnd := 0;
      Result := false;                                  // Ukon�� program
      exit;
    end;
  if not arbMultisampleSupported then                       // Multisampling nen� podporov�n
    begin
    // Vytvo�en� norm�ln�ho okna
    PixelFormat := ChoosePixelFormat(window.hDC,@pfd);      // Z�sk� kompatibiln� pixel form�t
    if PixelFormat = 0 then                                 // Poda�ilo se ho z�skat?
      begin
      ReleaseDC(window.hWnd,window.hDC);                    // Uvoln�n� kontextu za��zen�
      window.hDC := 0;                                      // Nulov�n� prom�nn�
      DestroyWindow(window.hWnd);                           // Zru�en� okna
      window.hWnd := 0;                                     // Nulov�n� handle
      Result := false;                                      // Ne�sp�ch
      exit;
      end;
    end
    else                                                    // Multisampling je podporov�n
    PixelFormat := arbMultisampleFormat;
  if not SetPixelFormat(window.hDc,PixelFormat,@pfd) then  // Poda�ilo se nastavit Pixel Format?
    begin
      ReleaseDC(window.hWnd,window.hDc);
      window.hDc := 0;
      DestroyWindow(window.hWnd);                               // Zav�e okno
      window.hWnd := 0;
      Result := false;                                  // Ukon�� program
      exit;
    end;
  window.hRc := wglCreateContext(window.hDc);                     // Poda�ilo se vytvo�it Rendering Context?
  if window.hRc = 0 then
    begin
      ReleaseDC(window.hWnd,window.hDc);
      window.hDc := 0;
      DestroyWindow(window.hWnd);                               // Zav�e okno
      window.hWnd := 0;
      Result := false;                                  // Ukon�� program
      exit;
    end;
  if not wglMakeCurrent(window.hDc,window.hRc) then            // Poda�ilo se aktivovat Rendering Context?
    begin
      wglDeleteContext(window.hRc);
      window.hRc := 0;
      ReleaseDC(window.hWnd,window.hDc);
      window.hDc := 0;
      DestroyWindow(window.hWnd);                               // Zav�e okno
      window.hWnd := 0;
      Result := false;                                  // Ukon�� program
      exit;
    end;
  if (not arbMultisampleSupported) and CHECK_FOR_MULTISAMPLE then   // Je multisampling dostupn�?
    if InitMultisample(window.init.application.hInstance,window.hWnd,pfd) then // Inicializace multisamplingu
      begin
      DestroyWindowGL(window);
      Result := CreateWindowGL(window);
      end;
  ShowWindow(window.hWnd,SW_NORMAL);                          // Zobrazen� okna
  window.isVisible := true;
  ReshapeGL(window.init.width,window.init.height);                        // Nastaven� perspektivy OpenGL sc�ny
  ZeroMemory(window.keys,Sizeof(Keys));
  window.lastTickCount := GetTickCount;
  Result := true;                                       // V�e prob�hlo v po��dku
end;

function DestroyWindowGL(var window: GL_Window): boolean;                                 // Zav�r�n� okna
begin
  if window.hWnd <> 0 then
    begin
    if window.hDc <> 0 then
      begin
      wglMakeCurrent(window.hDc,0);
      if window.hRc <> 0 then
        begin
        wglDeleteContext(window.hRc);
        window.hRc := 0;
        end;
      ReleaseDC(window.hWnd,window.hDc);
      window.hDc := 0;
      end;
    DestroyWindow(window.hWnd);
    window.hWnd := 0;
    end;
  if window.init.isFullScreen then                                    // Jsme ve fullscreenu?
    ChangeDisplaySettings(DEVMODE(nil^),0);           // P�epnut� do syst�mu
  ShowCursor(true);
  Result := true;
end;

end.
