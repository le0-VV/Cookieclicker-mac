const {contextBridge, ipcRenderer, shell} = require('electron');

const noop = () => {};

// Expose the minimal surface the game expects so App checks don't crash.
contextBridge.exposeInMainWorld('App', {
  quit: () => ipcRenderer.send('app-quit'),
  reload: () => ipcRenderer.send('app-reload'),
  registerMod: noop,
  saveMods: () => '',
  onResize: noop,
  restoreBackup: noop,
  grabData: (cb) => { if (cb) cb({playersN: 1}); },
  onImportSave: noop,
  save: noop,
  getMostRecentSave: (cb) => { if (cb) cb(''); },
  setFullscreen: (flag) => ipcRenderer.send('app-set-fullscreen', !!flag),
  justLoadedSave: noop,
  hardReset: noop,
  writeCloudUI: () => '',
  writeModUI: () => '',
  openLink: (href) => { if (href) shell.openExternal(href); },
  gotAchiev: noop,
  logic: noop,
  loadMods: (cb) => { if (cb) cb(); },
  saveData: null
});
