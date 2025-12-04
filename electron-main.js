const {app, BrowserWindow} = require('electron');
const path = require('path');

let quitting = false;
let mainWindow = null;

const createWindow = () => {
  const win = new BrowserWindow({
    width: 1280,
    height: 800,
    webPreferences: {
      contextIsolation: true,
      nodeIntegration: false
    }
  });
  win.setMenuBarVisibility(false);
  win.loadFile(path.join(__dirname, 'index.html'));

  // Keep window around unless the user explicitly quits (Cmd+Q or Quit menu).
  win.on('close', (e) => {
    if (!quitting) {
      e.preventDefault();
      win.hide();
    }
  });
  win.on('closed', () => {
    if (mainWindow === win) mainWindow = null;
  });

  mainWindow = win;
  return win;
};

app.whenReady().then(() => {
  const win = createWindow();

  app.on('activate', () => {
    const existing = BrowserWindow.getAllWindows()[0];
    if (existing) existing.show();
    else createWindow();
  });
});

app.on('before-quit', () => {
  quitting = true;
});

app.on('window-all-closed', () => {
  if (quitting || process.platform !== 'darwin') app.quit();
});
