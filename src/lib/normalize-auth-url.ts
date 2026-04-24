/**
 * NextAuth / Auth.js uses `new URL(process.env.AUTH_URL)`. A bare hostname
 * (e.g. youtube.groovymark.com) throws ERR_INVALID_URL. Normalize early so
 * deploys that only set the domain still work.
 */
const raw = process.env.AUTH_URL?.trim();
if (raw && !/^https?:\/\//i.test(raw)) {
  const local =
    raw.startsWith("localhost") ||
    raw.startsWith("127.0.0.1") ||
    raw.startsWith("[::1]");
  process.env.AUTH_URL = `${local ? "http" : "https"}://${raw}`;
}
