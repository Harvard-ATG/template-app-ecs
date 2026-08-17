'use client';

import Cookies from 'js-cookie';

const COOKIE_NAME = 'session_id';

export function useSessionCookie() {
  const getSessionId = (): string | null => {
    return Cookies.get(COOKIE_NAME) || null;
  };

  const setSessionId = (sessionId: string, expiresAt: string): void => {
    // Calculate expiry from ISO timestamp
    const expiryDate = new Date(expiresAt);
    const now = new Date();
    const daysUntilExpiry = (expiryDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24);
    
    Cookies.set(COOKIE_NAME, sessionId, {
      expires: daysUntilExpiry,
      sameSite: 'strict',
      secure: false, // Set to true in production with HTTPS
    });
  };

  const removeSessionId = (): void => {
    Cookies.remove(COOKIE_NAME);
  };

  return {
    getSessionId,
    setSessionId,
    removeSessionId,
  };
}
