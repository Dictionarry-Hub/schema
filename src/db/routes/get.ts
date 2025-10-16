import { Hono } from 'hono';
import { getAvailableDatabases, getDb } from '../db.ts';

export const dbRoutes = new Hono();

dbRoutes.get('/databases', (c) => {
  const databases = getAvailableDatabases();

  return c.json({
    databases,
  });
});

dbRoutes.get('/databases/profiles/:db', (c) => {
  const dbName = c.req.param('db');

  try {
    const db = getDb(dbName);
    const profiles = db.prepare('SELECT * FROM profiles').all();

    return c.json({
      database: dbName,
      profiles,
    });
  } catch (error) {
    return c.json({
      error: error instanceof Error ? error.message : 'Unknown error',
    }, 404);
  }
});
