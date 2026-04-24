import "@/lib/normalize-auth-url";
import type { NextAuthConfig } from "next-auth";

/**
 * Edge-safe auth config — no DB adapter, no bcrypt.
 * Used by middleware. The full config in `auth.ts` extends this.
 */
export const authConfig: NextAuthConfig = {
  session: { strategy: "jwt" },
  pages: { signIn: "/login" },
  providers: [],
  callbacks: {
    async jwt({ token, user }) {
      if (user) {
        // Auth.js expects `sub` as the stable user id for JWT sessions.
        token.sub = user.id;
        token.id = user.id;
        // @ts-expect-error role added in authorize
        token.role = user.role ?? "ADMIN";
      }
      return token;
    },
    async session({ session, token }) {
      if (token && session.user) {
        session.user.id = token.id as string;
        session.user.role = (token.role as "ADMIN" | "VIEWER") ?? "ADMIN";
      }
      return session;
    },
  },
  trustHost: true,
};
