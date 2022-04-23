unit ARB_multisample;

interface

uses windows, OpenGL;

const
  CHECK_FOR_MULTISAMPLE = true;                                                 // Testovat podporu multisamplingu?
  WGL_SAMPLE_BUFFERS_ARB = $2041;                                               // Symbolick� konstanty pro multisampling
  WGL_SAMPLES_ARB	= $2042;
  WGL_DRAW_TO_WINDOW_ARB = $2001;
  WGL_SUPPORT_OPENGL_ARB = $2010;
  WGL_ACCELERATION_ARB = $2003;
  WGL_FULL_ACCELERATION_ARB = $2027;
  WGL_COLOR_BITS_ARB = $2014;
  WGL_ALPHA_BITS_ARB = $201B;
  WGL_DEPTH_BITS_ARB = $2022;
  WGL_STENCIL_BITS_ARB = $2023;
  WGL_DOUBLE_BUFFER_ARB = $2011;

var
  arbMultisampleSupported: boolean = false;                                     // Je multisampling dostupn�?
  arbMultisampleFormat: integer = 0;                                            // Form�t multisamplingu


function InitMultisample(hInstance: HINST; hWnd: HWND; pfd: PIXELFORMATDESCRIPTOR): boolean;


implementation

function WGLisExtensionSupported(const extension: string): boolean;             // Je roz���en� podporov�no?
var
  wglGetExtString: function(hdc: HDC): Pchar; stdcall;
  supported: PChar;
begin
  wglGetExtString := nil;
  supported := nil;
  wglGetExtString := wglGetProcAddress('wglGetExtensionsStringARB');            // Pokud je to mo�n�, pokus� se wglGetExtensionStringARB pou��t na aktu�ln� DC
  if Assigned(wglGetExtString) then                                             // WGL OpenGL roz���en�
    supported := wglGetExtString(wglGetCurrentDC);
  if supported = nil then                                                       // Zkus� je�t� standardn� OpenGL �et�zec s roz���en�mi
    supported := glGetString(GL_EXTENSIONS);
  if supported = nil then                                                       // Pokud sel�e i toto, nen� �et�zec dostupn�
    begin
    Result := false;
    exit;
    end;
  if Pos(extension,supported) = 0 then                                          // Testov�n� obsahu �et�zce
    begin
    Result := false;                                                            // Pod�et�zec nen� v �et�zci
    exit;                                                                       // Roz���en� nebylo nalezeno
    end;
  Result := true;                                                               // Roz���en� bylo nalezeno
end;

function InitMultisample(hInstance: HINST; hWnd: HWND; pfd: PIXELFORMATDESCRIPTOR): boolean;  // Inicializace multisamplingu
var
  wglChoosePixelFormatARB: function(hdc: HDC; const piAttribIList: PGLint; const pfAttribFList: PGLfloat; nMaxFormats: GLuint; piFormats: PGLint; nNumFormats: PGLuint): BOOL; stdcall;
  h_dc: HDC;
  pixelFormat: integer;
  valid: boolean;
  numFormats: UINT;
  fAttributes: array of GLfloat;
  iAttributes: array of integer;
begin
  if not WGLisExtensionSupported('WGL_ARB_multisample') then                    // Existuje �et�zec ve WGL
    begin
    arbMultisampleSupported := false;
    Result := false;
    exit;
    end;
  wglChoosePixelFormatARB := wglGetProcAddress('wglChoosePixelFormatARB');      // Z�sk�n� pixel form�tu
  if not Assigned(wglChoosePixelFormatARB) then                                           // Dan� pixel form�t nen� dostupn�
    begin
    arbMultisampleSupported := false;
    Result := false;
    exit;
    end;
  h_dc := GetDC(hWnd);                                                          // Z�sk�n� kontextu za��zen�
  SetLength(fAttributes,2);
  fAttributes[0] := 0;
  fAttributes[1] := 0;
  SetLength(iAttributes,22);
  iAttributes[0] := WGL_DRAW_TO_WINDOW_ARB;
  iAttributes[1] := 1;
  iAttributes[2] := WGL_SUPPORT_OPENGL_ARB;
  iAttributes[3] := 1;
  iAttributes[4] := WGL_ACCELERATION_ARB;
  iAttributes[5] := WGL_FULL_ACCELERATION_ARB;
  iAttributes[6] := WGL_COLOR_BITS_ARB;
  iAttributes[7] := 24;
  iAttributes[8] := WGL_ALPHA_BITS_ARB;
  iAttributes[9] := 8;
  iAttributes[10] := WGL_DEPTH_BITS_ARB;
  iAttributes[11] := 16;
  iAttributes[12] := WGL_STENCIL_BITS_ARB;
  iAttributes[13] := 0;
  iAttributes[14] := WGL_DOUBLE_BUFFER_ARB;
  iAttributes[15] := 1;
  iAttributes[16] := WGL_SAMPLE_BUFFERS_ARB;
  iAttributes[17] := 1;
  iAttributes[18] := WGL_SAMPLES_ARB;
  iAttributes[19] := 4;
  iAttributes[20] := 0;
  iAttributes[21] := 0;
  valid := wglChoosePixelFormatARB(h_dc,@iattributes,@fattributes,1,@pixelFormat,@numFormats);
  if valid and (numFormats >= 1) then                                           // Vr�ceno true a po�et form�t� je v�t�� ne� jedna
    begin
    arbMultisampleSupported := true;
    arbMultisampleFormat := pixelFormat;
    Result := arbMultisampleSupported;
    SetLength(fAttributes,0);
    SetLength(iAttributes,0);
    exit;
    end;
  iAttributes[19] := 2;                                                         // �ty�i vzorkov�n� nejsou dostupn�, test dvou
  valid := wglChoosePixelFormatARB(h_dc,@iAttributes,@fAttributes,1,@pixelFormat,@numFormats);
  if valid and (numFormats >= 1) then
    begin
    arbMultisampleSupported := true;
    arbMultisampleFormat := pixelFormat;
    Result := arbMultisampleSupported;
    SetLength(fAttributes,0);
    SetLength(iAttributes,0);
    exit;
    end;
  Result :=  arbMultisampleSupported;                                           // Vr�cen� validn�ho form�tu
  SetLength(fAttributes,0);
  SetLength(iAttributes,0);
end;

end.
