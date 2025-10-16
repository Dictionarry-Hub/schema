import { Hono, Context } from 'hono'
import { logger } from '@/utils/logger'
import { initDb } from './db/db.ts'
import { dbRoutes } from './db/routes/get.ts'

const app = new Hono()

// Logging middleware
app.use('*', async (c, next) => {
  logger.info(`${c.req.method} ${c.req.path}`)
  await next()
})

app.get('/', (c: Context) => {
  return c.text('Hello Hono!')
})

app.route('/', dbRoutes)

// Initialize database before starting server
await initDb()

Deno.serve({
  port: 8001,
  onListen: ({ hostname, port }) => {
    logger.info(`Server listening on http://${hostname}:${port}`)
  }
}, app.fetch)
