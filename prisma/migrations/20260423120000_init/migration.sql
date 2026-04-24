-- CreateEnum
CREATE TYPE "UserRole" AS ENUM ('ADMIN', 'VIEWER');

-- CreateEnum
CREATE TYPE "Platform" AS ENUM ('YOUTUBE', 'LINKEDIN');

-- CreateEnum
CREATE TYPE "SyncStatus" AS ENUM ('IDLE', 'SYNCING', 'SUCCESS', 'ERROR');

-- CreateEnum
CREATE TYPE "ReportStatus" AS ENUM ('PENDING', 'SENT', 'FAILED');

-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "name" TEXT,
    "passwordHash" TEXT,
    "emailVerified" TIMESTAMP(3),
    "image" TEXT,
    "role" "UserRole" NOT NULL DEFAULT 'ADMIN',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Account" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "provider" TEXT NOT NULL,
    "providerAccountId" TEXT NOT NULL,
    "refresh_token" TEXT,
    "access_token" TEXT,
    "expires_at" INTEGER,
    "token_type" TEXT,
    "scope" TEXT,
    "id_token" TEXT,
    "session_state" TEXT,

    CONSTRAINT "Account_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Session" (
    "id" TEXT NOT NULL,
    "sessionToken" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "expires" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Session_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "VerificationToken" (
    "identifier" TEXT NOT NULL,
    "token" TEXT NOT NULL,
    "expires" TIMESTAMP(3) NOT NULL
);

-- CreateTable
CREATE TABLE "Client" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "description" TEXT,
    "contactName" TEXT,
    "contactEmail" TEXT,
    "industry" TEXT,
    "notes" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Client_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PendingYouTubeConnection" (
    "id" TEXT NOT NULL,
    "clientId" TEXT NOT NULL,
    "accessToken" TEXT NOT NULL,
    "refreshToken" TEXT,
    "tokenExpiresAt" TIMESTAMP(3) NOT NULL,
    "scope" TEXT,
    "discoveredChannels" JSONB NOT NULL,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "PendingYouTubeConnection_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Channel" (
    "id" TEXT NOT NULL,
    "clientId" TEXT NOT NULL,
    "platform" "Platform" NOT NULL,
    "displayName" TEXT NOT NULL,
    "externalId" TEXT,
    "handle" TEXT,
    "url" TEXT,
    "avatarUrl" TEXT,
    "accessToken" TEXT,
    "refreshToken" TEXT,
    "tokenExpiresAt" TIMESTAMP(3),
    "scope" TEXT,
    "connected" BOOLEAN NOT NULL DEFAULT false,
    "connectedAt" TIMESTAMP(3),
    "lastSyncedAt" TIMESTAMP(3),
    "syncStatus" "SyncStatus" NOT NULL DEFAULT 'IDLE',
    "syncError" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Channel_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "YouTubeChannelSnapshot" (
    "id" TEXT NOT NULL,
    "channelId" TEXT NOT NULL,
    "date" DATE NOT NULL,
    "subscribers" BIGINT,
    "viewCount" BIGINT,
    "videoCount" INTEGER,
    "views" BIGINT,
    "watchTimeMinutes" DOUBLE PRECISION,
    "averageViewDuration" DOUBLE PRECISION,
    "averageViewPercentage" DOUBLE PRECISION,
    "likes" BIGINT,
    "dislikes" BIGINT,
    "comments" BIGINT,
    "shares" BIGINT,
    "subscribersGained" BIGINT,
    "subscribersLost" BIGINT,
    "estimatedRevenue" DOUBLE PRECISION,
    "impressions" BIGINT,
    "impressionsCtr" DOUBLE PRECISION,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "YouTubeChannelSnapshot_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "YouTubeVideo" (
    "id" TEXT NOT NULL,
    "channelId" TEXT NOT NULL,
    "videoId" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "publishedAt" TIMESTAMP(3) NOT NULL,
    "duration" INTEGER,
    "thumbnailUrl" TEXT,
    "tags" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "categoryId" TEXT,
    "defaultLanguage" TEXT,
    "viewCount" BIGINT,
    "likeCount" BIGINT,
    "commentCount" BIGINT,
    "favoriteCount" BIGINT,
    "isShort" BOOLEAN NOT NULL DEFAULT false,
    "isLive" BOOLEAN NOT NULL DEFAULT false,
    "firstSeenAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "lastUpdatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "YouTubeVideo_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "YouTubeVideoMetric" (
    "id" TEXT NOT NULL,
    "videoId" TEXT NOT NULL,
    "channelId" TEXT NOT NULL,
    "date" DATE NOT NULL,
    "views" BIGINT,
    "watchTimeMinutes" DOUBLE PRECISION,
    "averageViewDuration" DOUBLE PRECISION,
    "averageViewPercentage" DOUBLE PRECISION,
    "likes" BIGINT,
    "comments" BIGINT,
    "shares" BIGINT,
    "subscribersGained" BIGINT,
    "subscribersLost" BIGINT,
    "estimatedRevenue" DOUBLE PRECISION,
    "impressions" BIGINT,
    "impressionsCtr" DOUBLE PRECISION,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "YouTubeVideoMetric_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "YouTubeAudienceSnapshot" (
    "id" TEXT NOT NULL,
    "channelId" TEXT NOT NULL,
    "periodEnd" DATE NOT NULL,
    "ageGroup" TEXT NOT NULL,
    "gender" TEXT NOT NULL,
    "viewerPercentage" DOUBLE PRECISION NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "YouTubeAudienceSnapshot_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "YouTubeGeographySnapshot" (
    "id" TEXT NOT NULL,
    "channelId" TEXT NOT NULL,
    "periodEnd" DATE NOT NULL,
    "country" TEXT NOT NULL,
    "views" BIGINT NOT NULL,
    "watchTimeMinutes" DOUBLE PRECISION,
    "averageViewDuration" DOUBLE PRECISION,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "YouTubeGeographySnapshot_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "YouTubeTrafficSourceSnapshot" (
    "id" TEXT NOT NULL,
    "channelId" TEXT NOT NULL,
    "periodEnd" DATE NOT NULL,
    "insightTrafficSourceType" TEXT NOT NULL,
    "views" BIGINT NOT NULL,
    "watchTimeMinutes" DOUBLE PRECISION,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "YouTubeTrafficSourceSnapshot_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "YouTubeDeviceSnapshot" (
    "id" TEXT NOT NULL,
    "channelId" TEXT NOT NULL,
    "periodEnd" DATE NOT NULL,
    "deviceType" TEXT NOT NULL,
    "views" BIGINT NOT NULL,
    "watchTimeMinutes" DOUBLE PRECISION,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "YouTubeDeviceSnapshot_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SyncLog" (
    "id" TEXT NOT NULL,
    "channelId" TEXT NOT NULL,
    "kind" TEXT NOT NULL,
    "status" "SyncStatus" NOT NULL,
    "startedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "finishedAt" TIMESTAMP(3),
    "rowsWritten" INTEGER NOT NULL DEFAULT 0,
    "errorMessage" TEXT,
    "detail" JSONB,

    CONSTRAINT "SyncLog_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AppSetting" (
    "key" TEXT NOT NULL,
    "value" TEXT NOT NULL,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "AppSetting_pkey" PRIMARY KEY ("key")
);

-- CreateTable
CREATE TABLE "ReportLog" (
    "id" TEXT NOT NULL,
    "clientId" TEXT NOT NULL,
    "reportMonth" DATE NOT NULL,
    "channelCount" INTEGER NOT NULL DEFAULT 0,
    "recipients" TEXT NOT NULL,
    "status" "ReportStatus" NOT NULL DEFAULT 'PENDING',
    "deliveredAt" TIMESTAMP(3),
    "errorMessage" TEXT,
    "messageId" TEXT,
    "triggeredBy" TEXT NOT NULL DEFAULT 'manual',
    "pdfBytes" INTEGER,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ReportLog_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- CreateIndex
CREATE UNIQUE INDEX "Account_provider_providerAccountId_key" ON "Account"("provider", "providerAccountId");

-- CreateIndex
CREATE UNIQUE INDEX "Session_sessionToken_key" ON "Session"("sessionToken");

-- CreateIndex
CREATE UNIQUE INDEX "VerificationToken_token_key" ON "VerificationToken"("token");

-- CreateIndex
CREATE UNIQUE INDEX "VerificationToken_identifier_token_key" ON "VerificationToken"("identifier", "token");

-- CreateIndex
CREATE UNIQUE INDEX "Client_slug_key" ON "Client"("slug");

-- CreateIndex
CREATE INDEX "PendingYouTubeConnection_clientId_idx" ON "PendingYouTubeConnection"("clientId");

-- CreateIndex
CREATE INDEX "PendingYouTubeConnection_expiresAt_idx" ON "PendingYouTubeConnection"("expiresAt");

-- CreateIndex
CREATE INDEX "Channel_clientId_idx" ON "Channel"("clientId");

-- CreateIndex
CREATE INDEX "Channel_platform_idx" ON "Channel"("platform");

-- CreateIndex
CREATE INDEX "YouTubeChannelSnapshot_channelId_date_idx" ON "YouTubeChannelSnapshot"("channelId", "date");

-- CreateIndex
CREATE UNIQUE INDEX "YouTubeChannelSnapshot_channelId_date_key" ON "YouTubeChannelSnapshot"("channelId", "date");

-- CreateIndex
CREATE INDEX "YouTubeVideo_channelId_idx" ON "YouTubeVideo"("channelId");

-- CreateIndex
CREATE INDEX "YouTubeVideo_publishedAt_idx" ON "YouTubeVideo"("publishedAt");

-- CreateIndex
CREATE UNIQUE INDEX "YouTubeVideo_channelId_videoId_key" ON "YouTubeVideo"("channelId", "videoId");

-- CreateIndex
CREATE INDEX "YouTubeVideoMetric_channelId_date_idx" ON "YouTubeVideoMetric"("channelId", "date");

-- CreateIndex
CREATE INDEX "YouTubeVideoMetric_videoId_date_idx" ON "YouTubeVideoMetric"("videoId", "date");

-- CreateIndex
CREATE UNIQUE INDEX "YouTubeVideoMetric_videoId_date_key" ON "YouTubeVideoMetric"("videoId", "date");

-- CreateIndex
CREATE INDEX "YouTubeAudienceSnapshot_channelId_periodEnd_idx" ON "YouTubeAudienceSnapshot"("channelId", "periodEnd");

-- CreateIndex
CREATE UNIQUE INDEX "YouTubeAudienceSnapshot_channelId_periodEnd_ageGroup_gender_key" ON "YouTubeAudienceSnapshot"("channelId", "periodEnd", "ageGroup", "gender");

-- CreateIndex
CREATE INDEX "YouTubeGeographySnapshot_channelId_periodEnd_idx" ON "YouTubeGeographySnapshot"("channelId", "periodEnd");

-- CreateIndex
CREATE UNIQUE INDEX "YouTubeGeographySnapshot_channelId_periodEnd_country_key" ON "YouTubeGeographySnapshot"("channelId", "periodEnd", "country");

-- CreateIndex
CREATE INDEX "YouTubeTrafficSourceSnapshot_channelId_periodEnd_idx" ON "YouTubeTrafficSourceSnapshot"("channelId", "periodEnd");

-- CreateIndex
CREATE UNIQUE INDEX "YouTubeTrafficSourceSnapshot_channelId_periodEnd_insightTra_key" ON "YouTubeTrafficSourceSnapshot"("channelId", "periodEnd", "insightTrafficSourceType");

-- CreateIndex
CREATE INDEX "YouTubeDeviceSnapshot_channelId_periodEnd_idx" ON "YouTubeDeviceSnapshot"("channelId", "periodEnd");

-- CreateIndex
CREATE UNIQUE INDEX "YouTubeDeviceSnapshot_channelId_periodEnd_deviceType_key" ON "YouTubeDeviceSnapshot"("channelId", "periodEnd", "deviceType");

-- CreateIndex
CREATE INDEX "SyncLog_channelId_startedAt_idx" ON "SyncLog"("channelId", "startedAt");

-- CreateIndex
CREATE INDEX "ReportLog_clientId_reportMonth_idx" ON "ReportLog"("clientId", "reportMonth");

-- CreateIndex
CREATE INDEX "ReportLog_status_idx" ON "ReportLog"("status");

-- AddForeignKey
ALTER TABLE "Account" ADD CONSTRAINT "Account_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Session" ADD CONSTRAINT "Session_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PendingYouTubeConnection" ADD CONSTRAINT "PendingYouTubeConnection_clientId_fkey" FOREIGN KEY ("clientId") REFERENCES "Client"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Channel" ADD CONSTRAINT "Channel_clientId_fkey" FOREIGN KEY ("clientId") REFERENCES "Client"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "YouTubeChannelSnapshot" ADD CONSTRAINT "YouTubeChannelSnapshot_channelId_fkey" FOREIGN KEY ("channelId") REFERENCES "Channel"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "YouTubeVideo" ADD CONSTRAINT "YouTubeVideo_channelId_fkey" FOREIGN KEY ("channelId") REFERENCES "Channel"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "YouTubeVideoMetric" ADD CONSTRAINT "YouTubeVideoMetric_videoId_fkey" FOREIGN KEY ("videoId") REFERENCES "YouTubeVideo"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "YouTubeAudienceSnapshot" ADD CONSTRAINT "YouTubeAudienceSnapshot_channelId_fkey" FOREIGN KEY ("channelId") REFERENCES "Channel"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "YouTubeGeographySnapshot" ADD CONSTRAINT "YouTubeGeographySnapshot_channelId_fkey" FOREIGN KEY ("channelId") REFERENCES "Channel"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "YouTubeTrafficSourceSnapshot" ADD CONSTRAINT "YouTubeTrafficSourceSnapshot_channelId_fkey" FOREIGN KEY ("channelId") REFERENCES "Channel"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "YouTubeDeviceSnapshot" ADD CONSTRAINT "YouTubeDeviceSnapshot_channelId_fkey" FOREIGN KEY ("channelId") REFERENCES "Channel"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SyncLog" ADD CONSTRAINT "SyncLog_channelId_fkey" FOREIGN KEY ("channelId") REFERENCES "Channel"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ReportLog" ADD CONSTRAINT "ReportLog_clientId_fkey" FOREIGN KEY ("clientId") REFERENCES "Client"("id") ON DELETE CASCADE ON UPDATE CASCADE;
