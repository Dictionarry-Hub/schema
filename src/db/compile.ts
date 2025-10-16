import { Database } from "@db/sqlite";
import { join } from "@std/path";
import { logger } from "@/utils/logger";
import { config } from "@/utils/config";

interface Metadata {
  version: string;
  dependencies?: Record<string, string>;
}

/**
 * Resolve dependencies for a database and return execution order
 * @param dbName - The database name to resolve dependencies for
 * @param schemaRoot - Root directory containing schema folders
 * @returns Array of database names in execution order (dependencies first)
 */
async function resolveDependencies(
  dbName: string,
  dbRoot: string,
  visited = new Set<string>()
): Promise<string[]> {
  // Avoid circular dependencies
  if (visited.has(dbName)) {
    return [];
  }
  visited.add(dbName);

  const metadataPath = join(dbRoot, dbName, 'metadata.json');

  let metadata: Metadata;
  try {
    const content = await Deno.readTextFile(metadataPath);
    metadata = JSON.parse(content);
  } catch (error) {
    // Base has no metadata, or metadata doesn't exist
    if (dbName === 'base') {
      return ['base'];
    }
    throw new Error(`Failed to read metadata for ${dbName}: ${error}`);
  }

  const order: string[] = [];

  // Recursively resolve dependencies
  if (metadata.dependencies) {
    for (const depName of Object.keys(metadata.dependencies)) {
      const depOrder = await resolveDependencies(depName, dbRoot, visited);
      order.push(...depOrder);
    }
  }

  // Add current database after its dependencies
  order.push(dbName);

  // Remove duplicates while preserving order
  return Array.from(new Set(order));
}

/**
 * Compile databases into an in-memory SQLite database
 * @param databases - List of database names to compile
 * @returns In-memory SQLite database instance
 */
export async function compile(databases: string[]): Promise<Database> {
  const db = new Database(":memory:");

  // Databases live in data/db/
  const dbRoot = config.dbPath;

  // Build complete execution order for all databases
  const executionOrder: string[] = [];
  for (const dbName of databases) {
    const order = await resolveDependencies(dbName, dbRoot);
    executionOrder.push(...order);
  }

  // Remove duplicates while preserving order
  const uniqueOrder = Array.from(new Set(executionOrder));

  logger.debug('Database execution order:', uniqueOrder);

  // Execute operations.sql for each database in order
  for (const dbName of uniqueOrder) {
    const operationsPath = join(dbRoot, dbName, 'operations.sql');

    try {
      const sql = await Deno.readTextFile(operationsPath);
      logger.debug(`Executing operations for: ${dbName}`);
      db.exec(sql);
    } catch (error) {
      logger.error(`Failed to execute operations for ${dbName}:`, error);
      throw error;
    }
  }

  return db;
}
