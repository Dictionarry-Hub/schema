import { join } from "@std/path";

// Base path points to the data directory
const BASE_PATH = '/home/sam-chau/code/dictionarry/schema/data';

export const config = {
  basePath: BASE_PATH,

  // Database path
  dbPath: join(BASE_PATH, 'db'),

  // Logs path
  logsPath: join(BASE_PATH, 'logs'),
} as const;
