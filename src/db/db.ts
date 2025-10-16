import { config } from "@/utils/config";
import { cache } from "@/utils/cache";
import { logger } from "@/utils/logger";
import { compile } from "./compile.ts";
import type { Database } from "@db/sqlite";

// Hardcoded list of databases to compile (we'd get this from config in a more complex app)
const DATABASES = ['dictionarry', 'banana'];

// In-memory SQLite database instances (one per database)
const databases = new Map<string, Database>();

/**
 * Initialize the database system
 * - Compile databases into memory
 * - Watch for changes and recompile
 */
export async function initDb() {
  logger.info('Initializing database system');

  // Compile each database separately
  for (const dbName of DATABASES) {
    const db = await compile([dbName]);
    databases.set(dbName, db);
    logger.info(`Database '${dbName}' compiled successfully`);
  }

  // Watch the db directory for changes
  cache.watch(config.dbPath, async (path, kind) => {
    if (path.endsWith('.sql') || path.endsWith('.json')) {
      logger.info(`Database file changed: ${path} (${kind})`);
      logger.info('Recompiling databases...');

      // Recompile all databases
      for (const dbName of DATABASES) {
        const db = await compile([dbName]);
        databases.set(dbName, db);
      }

      logger.info('All databases recompiled successfully');
    }
  });
}

/**
 * Get a specific database instance
 * @param dbName - The name of the database to retrieve
 */
export function getDb(dbName: string): Database {
  const db = databases.get(dbName);
  if (!db) {
    throw new Error(`Database '${dbName}' not found. Available databases: ${Array.from(databases.keys()).join(', ')}`);
  }
  return db;
}

/**
 * Get all available database names
 */
export function getAvailableDatabases(): string[] {
  return Array.from(databases.keys());
}
