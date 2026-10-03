export const handler = async (event) => ({
  statusCode: 200,
  headers: { "content-type": "application/json" },
  body: JSON.stringify({
    lang: "node",
    path: event.rawPath ?? "/",
    db_host: process.env.DB_HOST,
    assets_bucket: process.env.ASSETS_BUCKET,
  }),
});
