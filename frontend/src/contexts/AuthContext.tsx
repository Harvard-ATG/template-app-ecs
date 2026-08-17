'use client';

import React, { createContext, useState, useEffect, useCallback } from 'react';
import type { AuthContextType, User } from '@/lib/types';
import { api } from '@/lib/api-client';
import { useSessionCookie } from '@/hooks/useSessionCookie';

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [sessionId, setSessionId] = useState<string | null>(null);
  const [sessionExpiry, setSessionExpiry] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  
  const { getSessionId, setSessionId: saveSessionCookie, removeSessionId } = useSessionCookie();

  // Check for existing session on mount
  useEffect(() => {
    const existingSessionId = getSessionId();
    if (existingSessionId) {
      setSessionId(existingSessionId);
      // In a real app, you'd validate the session here
      // For now, we trust the cookie exists
    }
  }, [getSessionId]);

  const login = useCallback(async (email: string, password: string) => {
    setIsLoading(true);
    setError(null);
    
    try {
      const data = await api.auth.login({ email, password });
      
      // Save to cookie
      saveSessionCookie(data.session_id, data.expires_at);
      
      // Update context
      setUser(data.user);
      setSessionId(data.session_id);
      setSessionExpiry(data.expires_at);
    } catch (err: any) {
      console.error('Login error:', err);
      const message = err.status === 401 
        ? 'Invalid email or password'
        : err.message || 'Unable to login. Please try again.';
      setError(message);
      throw err;
    } finally {
      setIsLoading(false);
    }
  }, [saveSessionCookie]);

  const register = useCallback(async (email: string, password: string, fullName?: string) => {
    setIsLoading(true);
    setError(null);
    
    try {
      await api.auth.register({ email, password, full_name: fullName });
      
      // After successful registration, log in
      await login(email, password);
    } catch (err: any) {
      console.error('Registration error:', err);
      const message = err.status === 400
        ? 'Email already registered'
        : err.message || 'Unable to register. Please try again.';
      setError(message);
      throw err;
    } finally {
      setIsLoading(false);
    }
  }, [login]);

  const logout = useCallback(async () => {
    if (!sessionId) return;
    
    setIsLoading(true);
    
    try {
      await api.auth.logout(sessionId);
    } catch (err) {
      // Even if API call fails, clear local state
      console.error('Logout error:', err);
    } finally {
      // Clear everything
      removeSessionId();
      setUser(null);
      setSessionId(null);
      setSessionExpiry(null);
      setIsLoading(false);
    }
  }, [sessionId, removeSessionId]);

  const clearError = useCallback(() => {
    setError(null);
  }, []);

  const value: AuthContextType = {
    user,
    sessionId,
    sessionExpiry,
    isLoading,
    error,
    login,
    register,
    logout,
    clearError,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export { AuthContext };
