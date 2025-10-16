import { logger } from "@/utils/logger";

type WatchCallback = (path: string, kind: Deno.FsEvent["kind"]) => void | Promise<void>;

interface Watcher {
  path: string;
  callback: WatchCallback;
  abortController: AbortController;
}

class Cache {
  private watchers: Map<string, Watcher> = new Map();

  /**
   * Watch a folder and execute a callback when changes occur
   * @param folderPath - The path to watch
   * @param callback - Function to execute on file changes
   * @returns A function to stop watching
   */
  watch(folderPath: string, callback: WatchCallback): () => void {
    // If already watching this path, stop the previous watcher
    if (this.watchers.has(folderPath)) {
      this.unwatch(folderPath);
    }

    const abortController = new AbortController();

    this.watchers.set(folderPath, {
      path: folderPath,
      callback,
      abortController,
    });

    logger.debug(`Watching folder: ${folderPath}`);

    // Start watching in the background
    this.startWatching(folderPath, callback, abortController.signal);

    // Return unwatch function
    return () => this.unwatch(folderPath);
  }

  private async startWatching(
    folderPath: string,
    callback: WatchCallback,
    signal: AbortSignal
  ) {
    try {
      const watcher = Deno.watchFs(folderPath, { recursive: true });
      const debounceMap = new Map<string, number>();
      const DEBOUNCE_MS = 100;

      for await (const event of watcher) {
        if (signal.aborted) {
          break;
        }

        // Execute callback for each changed path with debouncing
        for (const path of event.paths) {
          // Clear existing timeout for this path
          const existingTimeout = debounceMap.get(path);
          if (existingTimeout) {
            clearTimeout(existingTimeout);
          }

          // Set new timeout
          const timeoutId = setTimeout(async () => {
            debounceMap.delete(path);
            try {
              await callback(path, event.kind);
            } catch (error) {
              logger.error(`Error in watch callback for ${path}:`, error);
            }
          }, DEBOUNCE_MS);

          debounceMap.set(path, timeoutId);
        }
      }
    } catch (error) {
      if (!signal.aborted) {
        logger.error(`Error watching ${folderPath}:`, error);
      }
    }
  }

  /**
   * Stop watching a specific folder
   */
  unwatch(folderPath: string): void {
    const watcher = this.watchers.get(folderPath);
    if (watcher) {
      watcher.abortController.abort();
      this.watchers.delete(folderPath);
      logger.debug(`Stopped watching folder: ${folderPath}`);
    }
  }

  /**
   * Stop watching all folders
   */
  unwatchAll(): void {
    for (const [path] of this.watchers) {
      this.unwatch(path);
    }
  }
}

// Export as singleton
export const cache = new Cache();
