// Auto-updater setup code
// import electronUpdater from 'electron-updater';
// const { autoUpdater } = electronUpdater;
// import * as log from 'electron-log';
// import type { UpdateInfo, ProgressInfo } from 'electron-updater';

private setupAutoUpdater(): void {
	try {
		// Configure electron-log for auto-updater
		log.transports.file.level = 'info';
		autoUpdater.logger = log;
		
		// Bypass SSL certificate validation for development/testing
		process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';
		log.info('SSL certificate validation disabled for auto-updater');

		app.on('certificate-error', (event, webContents, url, error, certificate, callback) => {
            if (url.startsWith('UPDATE_SERVER_URL_PLACEHOLDER')) {
                event.preventDefault();
                callback(true); // Ignore certificate error for this URL
                log.warn(`Ignored certificate error for URL: ${url}`);
            } else {
                callback(false);
            }
        });
		
		
		// Set update server URL with error handling
		try {
			autoUpdater.setFeedURL({
				provider: 'generic',
				url: 'UPDATE_SERVER_URL_PLACEHOLDER'
			});
			log.info('Auto-updater feed URL set to: UPDATE_SERVER_URL_PLACEHOLDER');
		} catch (feedError) {
			log.error('Failed to set feed URL:', feedError);
			return; // Exit early if feed URL setup fails
		}
		
		autoUpdater.on('checking-for-update', () => {
			log.info('Checking for updates...');
		});
		
		autoUpdater.on('update-available', (info: UpdateInfo) => {
			log.info('Update available:', info.version);
		});
		
		autoUpdater.on('update-not-available', (info: UpdateInfo) => {
			log.info('Update not available, current version:', info.version);
		});
		
		autoUpdater.on('error', (err: Error) => {
			log.error('Auto updater error:', err);
			// Don't let updater errors crash the app
		});
		
		autoUpdater.on('download-progress', (progressObj: ProgressInfo) => {
			let logMessage = `Download speed: ${progressObj.bytesPerSecond}`;
			logMessage += ` - Downloaded ${progressObj.percent}%`;
			logMessage += ` (${progressObj.transferred}/${progressObj.total})`;
			log.info(logMessage);
		});
		
		autoUpdater.on('update-downloaded', (info: UpdateInfo) => {
			log.info('Update downloaded, ready to install:', info.version);
			// You can show notification or dialog here
			// autoUpdater.quitAndInstall();
		});
		
		// Check for updates on startup (delayed to ensure app is fully loaded)
		setTimeout(async () => {
			try {
				log.info('Starting update check...');
				await autoUpdater.checkForUpdatesAndNotify();
			} catch (updateError) {
				log.error('Failed to check for updates:', updateError);
				// Continue app execution even if update check fails
			}
		}, 5000); // Delay 5 seconds to ensure app is fully started
		
	} catch (setupError) {
		log.error('Failed to setup auto-updater:', setupError);
		// Continue app execution even if auto-updater setup fails
	}
}