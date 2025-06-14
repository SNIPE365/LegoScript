#include <windows.h>
#define IDM_FILE 1000
LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam){
    switch (msg)
    {
        case WM_CREATE:
            HMENU hMenu = CreateMenu();
            HMENU hFileMenu = CreateMenu();
            AppendMenu(hFileMenu, MF_STRING, IDM_FILE, "&Open");
            AppendMenu(hMenu, MF_POPUP, (UINT_PTR)hFileMenu, "&File");
            SetMenu(hwnd, hMenu);
            break;
        case WM_COMMAND:
            switch (LOWORD(wParam)){
                case IDM_FILE:
                    MessageBox(hwnd, "Testing", "Menu Event", MB_OK);
                    break;
            }
            break;
        case WM_DESTROY:
            PostQuitMessage(0);
            break;
        default:
            return DefWindowProc(hwnd, msg, wParam, lParam);
    }
    return 0;
}
int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance,
    LPSTR lpCmdLine, int nCmdShow){
    STARTUPINFO si = {0};
    si.cb = sizeof(si);
    si.dwFlags = STARTF_USESHOWWINDOW;
    si.wShowWindow = SW_HIDE;
    WNDCLASS wc = {0};
    wc.lpfnWndProc = WndProc;
    wc.hInstance = hInstance;
    wc.hCursor = LoadCursor(NULL, IDC_ARROW);
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW+1);
    wc.lpszClassName = "MyWin32WindowClass";
    RegisterClass(&wc);
    HWND hwnd = CreateWindow("MyWin32WindowClass", "My Win32 Window",
        WS_OVERLAPPEDWINDOW | WS_MAXIMIZE, CW_USEDEFAULT, CW_USEDEFAULT,
        640, 480, NULL, NULL, hInstance, NULL);
    ShowWindow(hwnd, SW_SHOWMAXIMIZED);
    UpdateWindow(hwnd);
    MSG msg;
    while (GetMessage(&msg, NULL, 0, 0)){
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }
    return (int)msg.wParam;
}