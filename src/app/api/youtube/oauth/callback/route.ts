import { NextRequest, NextResponse } from "next/server";
import { auth } from "@/lib/auth";
import { prisma } from "@/lib/prisma";
import { encryptString } from "@/lib/crypto";
import { exchangeCodeForTokens } from "@/lib/youtube/oauth";
import { listMyChannels } from "@/lib/youtube/client";

/**
 * Resolve the public base URL the browser is actually using. Behind a reverse
 * proxy (Dokploy/Traefik) Next.js sees the request as coming to 0.0.0.0:3000
 * because the proxy forwards it to the container bind address. Trust the
 * `AUTH_URL` env var first — it's what the admin set for the public domain —
 * then fall back to forwarded headers, and finally to the raw request URL.
 */
function publicBaseUrl(req: NextRequest): URL {
  const fromEnv = process.env.AUTH_URL ?? process.env.NEXTAUTH_URL;
  if (fromEnv) {
    try {
      return new URL(fromEnv);
    } catch {
      /* fall through */
    }
  }
  const proto =
    req.headers.get("x-forwarded-proto") ?? req.nextUrl.protocol.replace(":", "");
  const host = req.headers.get("x-forwarded-host") ?? req.headers.get("host");
  if (host) {
    try {
      return new URL(`${proto}://${host}`);
    } catch {
      /* fall through */
    }
  }
  return new URL(req.nextUrl.origin);
}

function redirectWithError(baseUrl: URL, slug: string | null, error: string) {
  const url = slug
    ? new URL(`/clients/${slug}`, baseUrl)
    : new URL("/channels", baseUrl);
  url.searchParams.set("yt_error", error);
  return NextResponse.redirect(url);
}

type ParsedState =
  | { mode: "channel"; channelId: string; csrf: string }
  | { mode: "client"; clientId: string; csrf: string }
  // legacy state written by an older build — treat channelId-only payloads as mode=channel
  | { mode?: undefined; channelId: string; csrf: string };

export async function GET(req: NextRequest) {
  const base = publicBaseUrl(req);

  const session = await auth();
  if (!session?.user) {
    return NextResponse.redirect(new URL("/login", base));
  }

  const code = req.nextUrl.searchParams.get("code");
  const rawState = req.nextUrl.searchParams.get("state");
  const err = req.nextUrl.searchParams.get("error");

  if (err) {
    return redirectWithError(base, null, `Google denied the request (${err})`);
  }

  if (!code || !rawState) {
    return redirectWithError(base, null, "Missing code or state");
  }

  let state: ParsedState;
  try {
    state = JSON.parse(
      Buffer.from(rawState, "base64url").toString("utf8")
    ) as ParsedState;
  } catch {
    return redirectWithError(base, null, "Invalid state");
  }

  const cookieCsrf = req.cookies.get("yt_oauth_csrf")?.value;
  if (!cookieCsrf || cookieCsrf !== state.csrf) {
    return redirectWithError(base, null, "CSRF check failed");
  }

  // Normalize legacy state
  const mode: "channel" | "client" =
    state.mode === "client" ? "client" : "channel";

  if (mode === "channel") {
    return handleReconnect(req, base, code, (state as { channelId: string }).channelId);
  } else {
    return handleClientPicker(req, base, code, (state as { clientId: string }).clientId);
  }
}

// ---------------------------------------------------------------------------
// Mode 1: re-connect / refresh tokens for an existing Channel record
// ---------------------------------------------------------------------------
async function handleReconnect(
  req: NextRequest,
  base: URL,
  code: string,
  channelId: string
) {
  const channel = await prisma.channel.findUnique({
    where: { id: channelId },
    include: { client: true },
  });
  if (!channel || channel.platform !== "YOUTUBE") {
    return redirectWithError(base, null, "Channel not found");
  }

  let tokens;
  try {
    tokens = await exchangeCodeForTokens(code);
  } catch (e) {
    const msg = e instanceof Error ? e.message : "Token exchange failed";
    return redirectWithError(base, channel.client.slug, msg);
  }

  // Look up the authorized channel to capture externalId and metadata
  let ytChannelExternalId: string | null = null;
  let ytChannelTitle: string | null = null;
  let ytChannelAvatar: string | null = null;
  try {
    const channels = await listMyChannels(tokens.access_token);
    // Prefer the channel whose id matches our stored externalId; otherwise use the first.
    const match =
      (channel.externalId &&
        channels.find((c) => c.id === channel.externalId)) ||
      channels[0];
    if (match) {
      ytChannelExternalId = match.id;
      ytChannelTitle = match.snippet?.title ?? null;
      ytChannelAvatar =
        match.snippet?.thumbnails?.medium?.url ??
        match.snippet?.thumbnails?.default?.url ??
        null;
    }
  } catch {
    // non-fatal — we can still store tokens and sync later
  }

  await prisma.channel.update({
    where: { id: channelId },
    data: {
      accessToken: encryptString(tokens.access_token),
      refreshToken: tokens.refresh_token
        ? encryptString(tokens.refresh_token)
        : undefined,
      tokenExpiresAt: new Date(Date.now() + tokens.expires_in * 1000),
      scope: tokens.scope ?? null,
      connected: true,
      connectedAt: new Date(),
      syncStatus: "IDLE",
      syncError: null,
      ...(ytChannelExternalId && !channel.externalId
        ? { externalId: ytChannelExternalId }
        : {}),
      ...(ytChannelAvatar ? { avatarUrl: ytChannelAvatar } : {}),
      ...(ytChannelTitle && !channel.externalId
        ? { displayName: ytChannelTitle }
        : {}),
    },
  });

  const redirect = new URL(`/clients/${channel.client.slug}`, base);
  redirect.searchParams.set("yt_connected", channel.id);

  const res = NextResponse.redirect(redirect);
  res.cookies.delete("yt_oauth_csrf");
  return res;
}

// ---------------------------------------------------------------------------
// Mode 2: new connection for a client — discover channels, then either
// auto-create (1 channel) or show the picker (2+ channels).
// ---------------------------------------------------------------------------
async function handleClientPicker(
  req: NextRequest,
  base: URL,
  code: string,
  clientId: string
) {
  // `req` retained so future additions (e.g. reading more headers) don't need
  // another plumbing pass.
  void req;

  const client = await prisma.client.findUnique({ where: { id: clientId } });
  if (!client) {
    return redirectWithError(base, null, "Client not found");
  }

  let tokens;
  try {
    tokens = await exchangeCodeForTokens(code);
  } catch (e) {
    const msg = e instanceof Error ? e.message : "Token exchange failed";
    return redirectWithError(base, client.slug, msg);
  }

  let channels;
  try {
    channels = await listMyChannels(tokens.access_token);
  } catch (e) {
    const msg = e instanceof Error ? e.message : "Failed to list channels";
    return redirectWithError(base, client.slug, msg);
  }

  if (channels.length === 0) {
    return redirectWithError(
      base,
      client.slug,
      "The authorized Google account has no YouTube channels"
    );
  }

  const encryptedAccess = encryptString(tokens.access_token);
  const encryptedRefresh = tokens.refresh_token
    ? encryptString(tokens.refresh_token)
    : null;
  const tokenExpiresAt = new Date(Date.now() + tokens.expires_in * 1000);

  // Which of the discovered externalIds are *already* attached to this client?
  // (so we can skip them in the picker UI and avoid unique-conflict surprises)
  const existing = await prisma.channel.findMany({
    where: {
      clientId: client.id,
      platform: "YOUTUBE",
      externalId: { in: channels.map((c) => c.id) },
    },
    select: { externalId: true },
  });
  const existingIds = new Set(
    existing.map((c) => c.externalId).filter(Boolean) as string[]
  );
  const newChannels = channels.filter((c) => !existingIds.has(c.id));

  // If the Google account manages exactly one new channel, auto-create it and
  // skip the picker entirely.
  if (newChannels.length === 1) {
    const ch = newChannels[0];
    const created = await prisma.channel.create({
      data: {
        clientId: client.id,
        platform: "YOUTUBE",
        displayName: ch.snippet?.title ?? "YouTube channel",
        externalId: ch.id,
        handle: ch.snippet?.customUrl ?? null,
        url: ch.snippet?.customUrl
          ? `https://youtube.com/${ch.snippet.customUrl.replace(/^@?/, "@")}`
          : `https://youtube.com/channel/${ch.id}`,
        avatarUrl:
          ch.snippet?.thumbnails?.medium?.url ??
          ch.snippet?.thumbnails?.default?.url ??
          null,
        accessToken: encryptedAccess,
        refreshToken: encryptedRefresh ?? undefined,
        tokenExpiresAt,
        scope: tokens.scope ?? null,
        connected: true,
        connectedAt: new Date(),
        syncStatus: "IDLE",
      },
    });

    const redirect = new URL(`/clients/${client.slug}`, base);
    redirect.searchParams.set("yt_connected", created.id);
    const res = NextResponse.redirect(redirect);
    res.cookies.delete("yt_oauth_csrf");
    return res;
  }

  // Zero brand-new channels but the account still manages some — send back
  // to the client page with a friendly notice. The existing records are
  // already connected, so just refresh.
  if (newChannels.length === 0) {
    return redirectWithError(
      base,
      client.slug,
      "All channels from that Google account are already connected to this client"
    );
  }

  // 2+ channels → store a pending connection and send the admin to the picker.
  const pending = await prisma.pendingYouTubeConnection.create({
    data: {
      clientId: client.id,
      accessToken: encryptedAccess,
      refreshToken: encryptedRefresh,
      tokenExpiresAt,
      scope: tokens.scope ?? null,
      discoveredChannels: newChannels.map((c) => ({
        id: c.id,
        title: c.snippet?.title ?? "Untitled channel",
        customUrl: c.snippet?.customUrl ?? null,
        description: c.snippet?.description ?? null,
        country: c.snippet?.country ?? null,
        thumbnailUrl:
          c.snippet?.thumbnails?.medium?.url ??
          c.snippet?.thumbnails?.default?.url ??
          null,
        subscriberCount: c.statistics?.subscriberCount ?? null,
        videoCount: c.statistics?.videoCount ?? null,
        viewCount: c.statistics?.viewCount ?? null,
        uploadsPlaylistId: c.contentDetails?.relatedPlaylists?.uploads ?? null,
      })),
      // Pending rows are short-lived; the admin picks within a few minutes.
      expiresAt: new Date(Date.now() + 30 * 60 * 1000),
    },
  });

  const redirect = new URL(
    `/clients/${client.slug}/connect/${pending.id}`,
    base
  );
  const res = NextResponse.redirect(redirect);
  res.cookies.delete("yt_oauth_csrf");
  return res;
}
